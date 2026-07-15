//
//  HapticService.swift
//  MoneyClassificationApp
//
//  Umpan balik getaran untuk konfirmasi deteksi (non-suara).
//

import Foundation
import UIKit

protocol HapticServiceProtocol: AnyObject {
    func success()
    func error()
    func detectionPulse()
}

final class HapticService: HapticServiceProtocol {

    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    init() {
        notificationGenerator.prepare()
        impactGenerator.prepare()
    }

    /// Pola getaran saat deteksi sukses.
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Pola getaran saat terjadi error.
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    /// Getaran ringan saat uang terdeteksi.
    func detectionPulse() {
        impactGenerator.impactOccurred()
        impactGenerator.prepare()
    }
}
