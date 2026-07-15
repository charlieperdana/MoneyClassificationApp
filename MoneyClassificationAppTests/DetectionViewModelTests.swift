//
//  DetectionViewModelTests.swift
//  MoneyClassificationAppTests
//
//  Test logika debounce ucapan dan transisi state pada DetectionViewModel
//  menggunakan service tiruan (Task 6.4).
//

import Testing
import AVFoundation
import CoreGraphics
@testable import MoneyClassificationApp

// MARK: - Mocks

final class MockCameraService: CameraServiceProtocol {
    var frameHandler: ((CVPixelBuffer, CGImagePropertyOrientation) -> Void)?
    var luminanceHandler: ((Double) -> Void)?
    var didStart = false
    var startError: Error?

    func requestAuthorization() async -> AVAuthorizationStatus { .authorized }
    func authorizationStatus() -> AVAuthorizationStatus { .authorized }
    func start() throws {
        if let startError { throw startError }
        didStart = true
    }
    func stop() { didStart = false }
}

final class MockDetector: MoneyDetectorServiceProtocol {
    func detect(in pixelBuffer: CVPixelBuffer,
                orientation: CGImagePropertyOrientation) async throws -> [DetectedMoney] {
        []
    }
}

final class MockAudioService: AudioFeedbackServiceProtocol {
    private(set) var spokenTexts: [String] = []
    func speak(_ text: String, interrupt: Bool) { spokenTexts.append(text) }
    func stop() {}
}

final class MockHapticService: HapticServiceProtocol {
    var successCount = 0
    var errorCount = 0
    var pulseCount = 0
    func success() { successCount += 1 }
    func error() { errorCount += 1 }
    func detectionPulse() { pulseCount += 1 }
}

// MARK: - Tests

@MainActor
struct DetectionViewModelTests {

    private func makeViewModel(camera: MockCameraService = MockCameraService(),
                               audio: MockAudioService = MockAudioService(),
                               haptic: MockHapticService = MockHapticService(),
                               debounce: TimeInterval = 2.0) -> DetectionViewModel {
        DetectionViewModel(cameraService: camera,
                           detectorFactory: { MockDetector() },
                           audioService: audio,
                           hapticService: haptic,
                           countAggregator: CountAggregator(),
                           debounceInterval: debounce)
    }

    @Test func startDetectionTransitionsToRunning() {
        let camera = MockCameraService()
        let vm = makeViewModel(camera: camera)
        vm.startDetection()
        #expect(vm.state == .running)
        #expect(camera.didStart)
    }

    @Test func startDetectionWithCameraErrorSetsErrorState() {
        let camera = MockCameraService()
        camera.startError = CameraError.noCameraAvailable
        let audio = MockAudioService()
        let vm = makeViewModel(camera: camera, audio: audio)
        vm.startDetection()

        if case .error = vm.state {
            #expect(true)
        } else {
            Issue.record("Expected error state, got \(vm.state)")
        }
        #expect(!audio.spokenTexts.isEmpty)
    }

    @Test func stopDetectionReturnsToIdle() {
        let vm = makeViewModel()
        vm.startDetection()
        vm.stopDetection()
        #expect(vm.state == .idle)
    }

    @Test func accessibilitySummaryReflectsState() {
        let vm = makeViewModel()
        #expect(vm.accessibilitySummary == "Deteksi belum dimulai.")
    }
}
