//
//  DetectionViewModel.swift
//  MoneyClassificationApp
//
//  Otak mode deteksi real-time: menyambungkan kamera, model, suara, dan haptic.
//

import Foundation
import AVFoundation
import CoreGraphics
import Observation

enum DetectionState: Equatable {
    case idle
    case running
    case noMoney
    case lowLight
    case error(String)
}

@MainActor
@Observable
final class DetectionViewModel {

    // MARK: - Observable State
    private(set) var currentDetections: [DetectedMoney] = []
    private(set) var guidanceMessage: String?
    private(set) var state: DetectionState = .idle
    private(set) var countResult: CountResult = .empty

    /// Mode aktif: true bila mode hitung total.
    var isCountMode: Bool = false

    // MARK: - Dependencies
    private let cameraService: CameraServiceProtocol
    private let detectorFactory: () throws -> MoneyDetectorServiceProtocol
    private let audioService: AudioFeedbackServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let countAggregator: CountAggregator

    private var detector: MoneyDetectorServiceProtocol?

    // MARK: - Debounce
    /// Nominal terakhir yang diucapkan dan waktunya.
    private var lastSpokenNominal: Int?
    private var lastSpokenTime: Date = .distantPast
    private let debounceInterval: TimeInterval

    // Panduan pencahayaan/posisi.
    private let lowLightThreshold: Double
    private var lastGuidanceTime: Date = .distantPast
    private let guidanceInterval: TimeInterval = 3.0

    private var isProcessingFrame = false

    init(cameraService: CameraServiceProtocol = CameraService(),
         detectorFactory: @escaping () throws -> MoneyDetectorServiceProtocol = { try MoneyDetectorService() },
         audioService: AudioFeedbackServiceProtocol = AudioFeedbackService(),
         hapticService: HapticServiceProtocol = HapticService(),
         countAggregator: CountAggregator = CountAggregator(),
         debounceInterval: TimeInterval = 2.0,
         lowLightThreshold: Double = 0.15) {
        self.cameraService = cameraService
        self.detectorFactory = detectorFactory
        self.audioService = audioService
        self.hapticService = hapticService
        self.countAggregator = countAggregator
        self.debounceInterval = debounceInterval
        self.lowLightThreshold = lowLightThreshold
    }

    // MARK: - Lifecycle

    func startDetection() {
        guard state != .running else { return }

        // Muat model bila belum.
        if detector == nil {
            do {
                detector = try detectorFactory()
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                setError(message)
                return
            }
        }

        cameraService.frameHandler = { [weak self] pixelBuffer, orientation in
            self?.handleFrame(pixelBuffer, orientation: orientation)
        }
        cameraService.luminanceHandler = { [weak self] luminance in
            self?.handleLuminance(luminance)
        }

        do {
            try cameraService.start()
            state = .running
            countAggregator.reset()
        } catch let error as CameraError {
            handleCameraError(error)
        } catch {
            setError(error.localizedDescription)
        }
    }

    func stopDetection() {
        cameraService.stop()
        cameraService.frameHandler = nil
        cameraService.luminanceHandler = nil
        state = .idle
    }

    var previewLayer: CALayer? {
        (cameraService as? CameraService)?.displayLayer
    }

    // MARK: - Frame Handling

    private func handleFrame(_ pixelBuffer: CVPixelBuffer,
                             orientation: CGImagePropertyOrientation) {
        guard !isProcessingFrame, let detector else { return }
        isProcessingFrame = true

        Task { [weak self] in
            guard let self else { return }
            defer { Task { @MainActor in self.isProcessingFrame = false } }
            do {
                let detections = try await detector.detect(in: pixelBuffer, orientation: orientation)
                await MainActor.run {
                    self.updateDetections(detections)
                }
            } catch {
                await MainActor.run {
                    let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.setError(message)
                }
            }
        }
    }

    private func updateDetections(_ detections: [DetectedMoney]) {
        currentDetections = detections

        if isCountMode {
            countResult = countAggregator.update(with: detections)
        }

        if detections.isEmpty {
            if state == .running || state == .noMoney {
                state = .noMoney
                maybeGuide("Arahkan kamera ke uang.")
            }
            return
        }

        state = .running
        guidanceMessage = nil

        // Nominal dominan (confidence tertinggi).
        if let top = detections.max(by: { $0.confidence < $1.confidence }) {
            hapticService.detectionPulse()
            speakIfNeeded(nominal: top.nominal)
        }
    }

    /// Debounce ucapan: jangan ulang nominal sama dalam interval, tetapi
    /// selalu ucapkan bila nominal berubah.
    private func speakIfNeeded(nominal: Int) {
        let now = Date()
        let isSameNominal = (nominal == lastSpokenNominal)
        let withinDebounce = now.timeIntervalSince(lastSpokenTime) < debounceInterval

        if isSameNominal && withinDebounce {
            return
        }

        audioService.speak(NominalMapper.spokenText(for: nominal), interrupt: true)
        hapticService.success()
        lastSpokenNominal = nominal
        lastSpokenTime = now
    }

    // MARK: - Luminance / Guidance

    private func handleLuminance(_ luminance: Double) {
        guard state == .running || state == .noMoney || state == .lowLight else { return }

        if luminance < lowLightThreshold {
            if state != .lowLight {
                state = .lowLight
            }
            maybeGuide("Kurang cahaya, cari tempat lebih terang.")
        } else if state == .lowLight {
            state = currentDetections.isEmpty ? .noMoney : .running
        }
    }

    private func maybeGuide(_ message: String) {
        let now = Date()
        guidanceMessage = message
        guard now.timeIntervalSince(lastGuidanceTime) >= guidanceInterval else { return }
        lastGuidanceTime = now
        audioService.speak(message, interrupt: false)
    }

    // MARK: - Count Mode

    /// Meminta pengucapan total (mode hitung).
    func requestTotal() {
        let result = countAggregator.currentResult()
        countResult = result
        audioService.speak(result.spokenSummary(), interrupt: true)
        if result.isEmpty {
            hapticService.error()
        } else {
            hapticService.success()
        }
    }

    func resetCount() {
        countAggregator.reset()
        countResult = .empty
    }

    // MARK: - Errors

    private func handleCameraError(_ error: CameraError) {
        let message = error.errorDescription ?? "Terjadi kesalahan kamera."
        setError(message)
    }

    private func setError(_ message: String) {
        state = .error(message)
        audioService.speak(message, interrupt: true)
        hapticService.error()
    }

    /// Ringkasan untuk accessibilityValue.
    var accessibilitySummary: String {
        switch state {
        case .idle:
            return "Deteksi belum dimulai."
        case .running:
            if let top = currentDetections.max(by: { $0.confidence < $1.confidence }) {
                return "Terdeteksi \(NominalMapper.spokenText(for: top.nominal))."
            }
            return "Kamera aktif, mencari uang."
        case .noMoney:
            return "Belum ada uang terlihat."
        case .lowLight:
            return "Kurang cahaya."
        case .error(let message):
            return message
        }
    }
}
