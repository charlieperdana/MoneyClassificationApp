//
//  CameraService.swift
//  MoneyClassificationApp
//
//  Mengelola sesi kamera dan streaming frame untuk deteksi uang.
//
//  Di perangkat fisik memakai AVCaptureSession.
//  Di iOS Simulator memakai SimulatorCamera (Akylas/SimulatorCamera):
//  frame dialirkan dari companion app macOS lewat localhost:9876.
//

import Foundation
import AVFoundation
import CoreGraphics
import CoreImage
import CoreMedia
import QuartzCore
import UIKit

#if targetEnvironment(simulator)
import SimulatorCameraClient
#endif

enum CameraError: LocalizedError {
    case notAuthorized
    case noCameraAvailable
    case configurationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Izin kamera belum diberikan."
        case .noCameraAvailable:
            return "Kamera tidak tersedia. Fitur ini memerlukan perangkat fisik."
        case .configurationFailed(let detail):
            return "Gagal menyiapkan kamera. \(detail)"
        }
    }
}

protocol CameraServiceProtocol: AnyObject {
    var frameHandler: ((CVPixelBuffer, CGImagePropertyOrientation) -> Void)? { get set }
    var luminanceHandler: ((Double) -> Void)? { get set }
    func requestAuthorization() async -> AVAuthorizationStatus
    func authorizationStatus() -> AVAuthorizationStatus
    func start() throws
    func stop()
}

final class CameraService: NSObject, CameraServiceProtocol {

    var frameHandler: ((CVPixelBuffer, CGImagePropertyOrientation) -> Void)?
    var luminanceHandler: ((Double) -> Void)?

    /// Preview layer untuk ditampilkan di UI (perangkat fisik).
    let previewLayer: AVCaptureVideoPreviewLayer

    /// Layer yang sebaiknya ditampilkan di UI. Di simulator memakai
    /// `AVSampleBufferDisplayLayer` yang menampilkan frame dari SimulatorCamera.
    var displayLayer: CALayer {
        #if targetEnvironment(simulator)
        return sampleBufferLayer
        #else
        return previewLayer
        #endif
    }

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "camera.video.queue")
    private let ciContext = CIContext(options: nil)

    // Throttling: proses ~8 fps.
    private let frameInterval: CFTimeInterval = 0.2
    private var lastFrameTime: CFTimeInterval = 0

    private var isConfigured = false

    #if targetEnvironment(simulator)
    /// Preview layer untuk simulator (menampilkan CVPixelBuffer dari SimulatorCamera).
    let sampleBufferLayer = AVSampleBufferDisplayLayer()
    private var simulatorSession: SimulatorCameraSession?
    #endif

    override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        super.init()

        #if targetEnvironment(simulator)
        sampleBufferLayer.videoGravity = .resizeAspectFill
        #endif
    }

    func authorizationStatus() -> AVAuthorizationStatus {
        #if targetEnvironment(simulator)
        // Simulator: kamera "virtual" dari SimulatorCamera, tidak butuh izin.
        return .authorized
        #else
        return AVCaptureDevice.authorizationStatus(for: .video)
        #endif
    }

    func requestAuthorization() async -> AVAuthorizationStatus {
        #if targetEnvironment(simulator)
        return .authorized
        #else
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        return AVCaptureDevice.authorizationStatus(for: .video)
        #endif
    }

    func start() throws {
        #if targetEnvironment(simulator)
        try startSimulator()
        #else
        try startDevice()
        #endif
    }

    func stop() {
        #if targetEnvironment(simulator)
        simulatorSession?.stop()
        #else
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
        #endif
    }

    // MARK: - Device path

    #if !targetEnvironment(simulator)
    private func startDevice() throws {
        guard authorizationStatus() == .authorized else {
            throw CameraError.notAuthorized
        }

        if !isConfigured {
            try configureSession()
            isConfigured = true
        }

        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }
    #endif

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back) else {
            session.commitConfiguration()
            throw CameraError.noCameraAvailable
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                throw CameraError.configurationFailed("Input kamera tidak dapat ditambahkan.")
            }
            session.addInput(input)
        } catch let error as CameraError {
            session.commitConfiguration()
            throw error
        } catch {
            session.commitConfiguration()
            throw CameraError.configurationFailed(error.localizedDescription)
        }

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            throw CameraError.configurationFailed("Output video tidak dapat ditambahkan.")
        }
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        session.commitConfiguration()
    }

    // MARK: - Simulator path

    #if targetEnvironment(simulator)
    private func startSimulator() throws {
        // Pastikan SimulatorCameraServer (companion app macOS) sudah berjalan
        // dan streaming ke 127.0.0.1:9876.
        if simulatorSession == nil {
            SimulatorCamera.configure(host: "127.0.0.1", port: 9876)
            let session = SimulatorCameraSession(host: "127.0.0.1", port: 9876)
            session.delegate = self
            simulatorSession = session
        }
        simulatorSession?.start()
    }

    /// Membangun CMSampleBuffer dari CVPixelBuffer agar bisa di-enqueue ke
    /// AVSampleBufferDisplayLayer.
    private func makeSampleBuffer(from pixelBuffer: CVPixelBuffer,
                                  at time: CMTime) -> CMSampleBuffer? {
        var formatDescription: CMVideoFormatDescription?
        let status = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        guard status == noErr, let formatDescription else { return nil }

        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: time,
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        let sbStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard sbStatus == noErr else { return nil }
        return sampleBuffer
    }
    #endif

    /// Menghitung rata-rata luminance sebuah pixel buffer (0.0 - 1.0).
    private func averageLuminance(of pixelBuffer: CVPixelBuffer) -> Double {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: ciImage,
                                                 kCIInputExtentKey: CIVector(cgRect: extent)]),
              let outputImage = filter.outputImage else {
            return 1.0
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(outputImage,
                         toBitmap: &bitmap,
                         rowBytes: 4,
                         bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                         format: .RGBA8,
                         colorSpace: CGColorSpaceCreateDeviceRGB())

        // Luminance perceptual (Rec. 601).
        let r = Double(bitmap[0]) / 255.0
        let g = Double(bitmap[1]) / 255.0
        let b = Double(bitmap[2]) / 255.0
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    /// Alur bersama: throttle, luminance, dan teruskan frame ke handler.
    fileprivate func process(pixelBuffer: CVPixelBuffer,
                             orientation: CGImagePropertyOrientation) {
        // Throttling frame.
        let now = CACurrentMediaTime()
        guard now - lastFrameTime >= frameInterval else { return }
        lastFrameTime = now

        let luminance = averageLuminance(of: pixelBuffer)
        luminanceHandler?(luminance)
        frameHandler?(pixelBuffer, orientation)
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        process(pixelBuffer: pixelBuffer, orientation: .up)
    }
}

#if targetEnvironment(simulator)
extension CameraService: FrameSourceDelegate {
    func frameSource(_ source: FrameSource,
                     didOutput pixelBuffer: CVPixelBuffer,
                     at time: CMTime) {
        // Tampilkan frame di preview layer (main thread).
        if let sampleBuffer = makeSampleBuffer(from: pixelBuffer, at: time) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.sampleBufferLayer.status == .failed {
                    self.sampleBufferLayer.flush()
                }
                self.sampleBufferLayer.enqueue(sampleBuffer)
            }
        }

        // Frame dari SimulatorCamera sudah berorientasi benar (.up).
        process(pixelBuffer: pixelBuffer, orientation: .up)
    }

    func frameSource(_ source: FrameSource, didFailWith error: Error) {
        // Biarkan sesi mencoba reconnect otomatis; abaikan di sini.
    }
}
#endif
