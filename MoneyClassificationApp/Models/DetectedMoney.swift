//
//  DetectedMoney.swift
//  MoneyClassificationApp
//
//  Objek transient hasil inferensi Vision/Core ML. Tidak dipersistensi.
//

import Foundation
import CoreGraphics

struct DetectedMoney: Identifiable, Equatable {
    let id = UUID()
    let nominal: Int            // mis. 100000
    let label: String           // raw label dari model
    let confidence: Float
    let boundingBox: CGRect     // koordinat relatif (Vision, origin bawah-kiri)

    static func == (lhs: DetectedMoney, rhs: DetectedMoney) -> Bool {
        lhs.nominal == rhs.nominal &&
        lhs.label == rhs.label &&
        abs(lhs.confidence - rhs.confidence) < 0.0001 &&
        lhs.boundingBox == rhs.boundingBox
    }
}
