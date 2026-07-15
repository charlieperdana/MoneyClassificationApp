//
//  CountAggregator.swift
//  MoneyClassificationApp
//
//  Menghitung total uang dengan stabilisasi antar-frame agar satu lembar
//  tidak dihitung lebih dari satu kali. Menggunakan IoU tracking sederhana.
//

import Foundation
import CoreGraphics

final class CountAggregator {

    /// Sebuah lembar yang dilacak antar-frame.
    private struct TrackedSheet {
        var nominal: Int
        var boundingBox: CGRect
        var stableFrameCount: Int
        var missedFrameCount: Int
    }

    /// Ambang IoU agar dua bounding box dianggap lembar yang sama.
    private let iouMatchThreshold: CGFloat
    /// Jumlah frame stabil sebelum sebuah lembar dihitung.
    private let framesToConfirm: Int
    /// Jumlah frame hilang sebelum sebuah lembar dilupakan.
    private let framesToForget: Int

    private var trackedSheets: [TrackedSheet] = []

    init(iouMatchThreshold: CGFloat = 0.3,
         framesToConfirm: Int = 3,
         framesToForget: Int = 5) {
        self.iouMatchThreshold = iouMatchThreshold
        self.framesToConfirm = framesToConfirm
        self.framesToForget = framesToForget
    }

    /// Reset semua state pelacakan.
    func reset() {
        trackedSheets.removeAll()
    }

    /// Memperbarui pelacakan dengan deteksi frame terbaru dan mengembalikan
    /// hasil hitung terkini (hanya lembar yang sudah stabil dihitung).
    @discardableResult
    func update(with detections: [DetectedMoney]) -> CountResult {
        // Tandai semua lembar sebagai belum ter-update pada frame ini.
        var matchedIndices = Set<Int>()

        for detection in detections {
            if let index = bestMatchIndex(for: detection, excluding: matchedIndices) {
                // Update lembar yang cocok.
                trackedSheets[index].boundingBox = detection.boundingBox
                trackedSheets[index].nominal = detection.nominal
                trackedSheets[index].stableFrameCount += 1
                trackedSheets[index].missedFrameCount = 0
                matchedIndices.insert(index)
            } else {
                // Lembar baru.
                trackedSheets.append(TrackedSheet(nominal: detection.nominal,
                                                  boundingBox: detection.boundingBox,
                                                  stableFrameCount: 1,
                                                  missedFrameCount: 0))
                matchedIndices.insert(trackedSheets.count - 1)
            }
        }

        // Tandai lembar yang tidak ter-update sebagai hilang.
        for index in trackedSheets.indices where !matchedIndices.contains(index) {
            trackedSheets[index].missedFrameCount += 1
        }

        // Buang lembar yang sudah lama hilang.
        trackedSheets.removeAll { $0.missedFrameCount > framesToForget }

        return currentResult()
    }

    /// Menghitung hasil dari lembar yang sudah stabil (confirmed).
    func currentResult() -> CountResult {
        let confirmed = trackedSheets.filter { $0.stableFrameCount >= framesToConfirm }
        guard !confirmed.isEmpty else { return .empty }

        var breakdown: [Int: Int] = [:]
        var total = 0
        for sheet in confirmed {
            breakdown[sheet.nominal, default: 0] += 1
            total += sheet.nominal
        }

        return CountResult(total: total,
                           breakdown: breakdown,
                           sheetCount: confirmed.count)
    }

    // MARK: - Helpers

    private func bestMatchIndex(for detection: DetectedMoney,
                                excluding used: Set<Int>) -> Int? {
        var bestIndex: Int?
        var bestIoU: CGFloat = iouMatchThreshold

        for index in trackedSheets.indices where !used.contains(index) {
            let iou = CountAggregator.intersectionOverUnion(trackedSheets[index].boundingBox,
                                                            detection.boundingBox)
            if iou >= bestIoU {
                bestIoU = iou
                bestIndex = index
            }
        }
        return bestIndex
    }

    /// Menghitung Intersection over Union dua rectangle.
    static func intersectionOverUnion(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        if intersection.isNull || intersection.isEmpty { return 0 }
        let interArea = intersection.width * intersection.height
        let unionArea = a.width * a.height + b.width * b.height - interArea
        guard unionArea > 0 else { return 0 }
        return interArea / unionArea
    }
}
