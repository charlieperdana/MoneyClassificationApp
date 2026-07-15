//
//  AppRouter.swift
//  MoneyClassificationApp
//
//  Router global untuk navigasi antar mode, termasuk deep link dari Siri/App Intents.
//

import Foundation
import Observation

enum AppTab: Hashable {
    case detection
    case count
    case verification
    case history
}

@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    var selectedTab: AppTab = .detection

    private init() {}

    func openDetection() {
        selectedTab = .detection
    }

    func openCount() {
        selectedTab = .count
    }
}
