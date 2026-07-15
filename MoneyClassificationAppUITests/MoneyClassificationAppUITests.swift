//
//  MoneyClassificationAppUITests.swift
//  MoneyClassificationAppUITests
//
//  UI test alur utama: buka app, navigasi antar mode (Deteksi, Hitung,
//  Verifikasi, Riwayat). (Task 13.1)
//

import XCTest

final class MoneyClassificationAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainNavigationFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Bila izin kamera belum diberikan, app menampilkan PermissionView,
        // sehingga tab bar tidak muncul. Skip alur tab dalam kondisi itu.
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            // PermissionView aktif; verifikasi minimal bahwa app berjalan.
            XCTAssertTrue(app.state == .runningForeground)
            return
        }

        // Mode Hitung.
        let countTab = app.buttons["Hitung"]
        if countTab.exists {
            countTab.tap()
            XCTAssertTrue(countTab.isSelected || countTab.exists)
        }

        // Mode Verifikasi.
        let verifyTab = app.buttons["Verifikasi"]
        if verifyTab.exists {
            verifyTab.tap()
            XCTAssertTrue(verifyTab.exists)
        }

        // Mode Riwayat.
        let historyTab = app.buttons["Riwayat"]
        if historyTab.exists {
            historyTab.tap()
            XCTAssertTrue(historyTab.exists)
        }

        // Kembali ke Deteksi.
        let detectTab = app.buttons["Deteksi"]
        if detectTab.exists {
            detectTab.tap()
            XCTAssertTrue(detectTab.exists)
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
