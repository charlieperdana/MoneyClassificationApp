//
//  MoneyAppIntents.swift
//  MoneyClassificationApp
//
//  App Intents untuk integrasi Siri: buka mode deteksi / hitung total.
//

import AppIntents
import SwiftUI

/// Membuka aplikasi langsung ke mode deteksi uang.
struct OpenDetectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Deteksi Uang"
    static var description = IntentDescription("Buka mode deteksi nominal uang secara langsung.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.openDetection()
        return .result()
    }
}

/// Membuka aplikasi langsung ke mode hitung total uang.
struct CountMoneyIntent: AppIntent {
    static var title: LocalizedStringResource = "Hitung Total Uang"
    static var description = IntentDescription("Buka mode penghitungan total nominal uang.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.openCount()
        return .result()
    }
}

/// Menyediakan frasa Bahasa Indonesia untuk Siri.
struct MoneyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenDetectionIntent(),
            phrases: [
                "Deteksi uang dengan \(.applicationName)",
                "Kenali uang di \(.applicationName)",
                "Buka deteksi uang \(.applicationName)"
            ],
            shortTitle: "Deteksi Uang",
            systemImageName: "banknote"
        )
        AppShortcut(
            intent: CountMoneyIntent(),
            phrases: [
                "Hitung uang dengan \(.applicationName)",
                "Hitung total uang di \(.applicationName)"
            ],
            shortTitle: "Hitung Total",
            systemImageName: "sum"
        )
    }
}
