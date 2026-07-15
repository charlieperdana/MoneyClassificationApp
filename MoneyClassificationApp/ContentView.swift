//
//  ContentView.swift
//  MoneyClassificationApp
//
//  Root view: TabView antar mode dengan kontrol izin kamera dan
//  dukungan navigasi dari Siri (AppRouter).
//

import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @State private var router = AppRouter.shared
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        Group {
            if cameraStatus == .authorized {
                mainTabs
            } else {
                PermissionView(status: cameraStatus, onRequest: requestCamera)
            }
        }
        .task { refreshStatus() }
    }

    private var mainTabs: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                DetectionView()
            }
            .tabItem { Label("Deteksi", systemImage: "banknote") }
            .tag(AppTab.detection)

            NavigationStack {
                CountView()
            }
            .tabItem { Label("Hitung", systemImage: "sum") }
            .tag(AppTab.count)

            NavigationStack {
                VerificationGuideView()
            }
            .tabItem { Label("Verifikasi", systemImage: "checkmark.seal") }
            .tag(AppTab.verification)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("Riwayat", systemImage: "clock") }
            .tag(AppTab.history)
        }
    }

    private func requestCamera() {
        Task {
            _ = await AVCaptureDevice.requestAccess(for: .video)
            refreshStatus()
        }
    }

    private func refreshStatus() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoneyRecord.self, inMemory: true)
}
