//
//  MoneyDetectorService.swift
//  MoneyClassificationApp
//
//  Membungkus model Core ML `MoneyDetector` melalui framework Vision.
//

import Foundation
import Vision
import CoreML
import CoreGraphics

enum MoneyDetectorError: LocalizedError {
    case modelLoadFailed(String)
    case inferenceFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let detail):
            return "Gagal memuat model deteksi uang. \(detail)"
        case .inferenceFailed(let detail):
            return "Terjadi kesalahan saat mendeteksi uang. \(detail)"
        }
    }
}

protocol MoneyDetectorServiceProtocol {
    func detect(in pixelBuffer: CVPixelBuffer,
                orientation: CGImagePropertyOrientation) async throws -> [DetectedMoney]
}

final class MoneyDetectorService: MoneyDetectorServiceProtocol {

    private let visionModel: VNCoreMLModel
    private let confidenceThreshold: Float
    private let iouThreshold: Float

    init(confidenceThreshold: Float = 0.95,
         iouThreshold: Float = 0.45) throws {
        self.confidenceThreshold = confidenceThreshold
        self.iouThreshold = iouThreshold

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let coreMLModel = try IndoMoney(configuration: config).model
            let visionModel = try VNCoreMLModel(for: coreMLModel)
            visionModel.featureProvider = ThresholdProvider(
                confidenceThreshold: confidenceThreshold,
                iouThreshold: iouThreshold
            )
            self.visionModel = visionModel
        } catch {
            throw MoneyDetectorError.modelLoadFailed(error.localizedDescription)
        }
    }

    func detect(in pixelBuffer: CVPixelBuffer,
                orientation: CGImagePropertyOrientation) async throws -> [DetectedMoney] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { [confidenceThreshold] request, error in
                if let error {
                    continuation.resume(throwing: MoneyDetectorError.inferenceFailed(error.localizedDescription))
                    return
                }

                let observations = (request.results as? [VNRecognizedObjectObservation]) ?? []
                let detections = MoneyDetectorService.mapObservations(observations,
                                                                      confidenceThreshold: confidenceThreshold)
                continuation.resume(returning: detections)
            }
            request.imageCropAndScaleOption = .scaleFill

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                orientation: orientation,
                                                options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: MoneyDetectorError.inferenceFailed(error.localizedDescription))
            }
        }
    }

    /// Memetakan observasi Vision -> [DetectedMoney], memfilter berdasarkan confidence.
    /// Dibuat static agar mudah diuji.
    static func mapObservations(_ observations: [VNRecognizedObjectObservation],
                                confidenceThreshold: Float) -> [DetectedMoney] {
        var results: [DetectedMoney] = []
        for observation in observations {
            guard let topLabel = observation.labels.first else { continue }
            guard topLabel.confidence >= confidenceThreshold else { continue }
            guard let nominal = NominalMapper.value(from: topLabel.identifier) else { continue }

            results.append(DetectedMoney(nominal: nominal,
                                         label: topLabel.identifier,
                                         confidence: topLabel.confidence,
                                         boundingBox: observation.boundingBox))
        }
        return results
    }
}
