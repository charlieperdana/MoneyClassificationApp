//
//  PermissionView.swift
//  MoneyClassificationApp
//
//  Alur permintaan izin kamera dengan penjelasan suara dan tautan ke Pengaturan.
//

import SwiftUI
import AVFoundation

struct PermissionView: View {
    let status: AVAuthorizationStatus
    let onRequest: () -> Void

    private let audioHolder = AudioFeedbackServiceHolder()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Izin Kamera Diperlukan")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            actionButton
        }
        .padding()
        .onAppear { audioHolder.service.speak(message, interrupt: true) }
        .accessibilityElement(children: .contain)
    }

    private var message: String {
        switch status {
        case .denied, .restricted:
            return "Aplikasi butuh akses kamera untuk mengenali uang. Izin saat ini ditolak. Buka Pengaturan untuk mengaktifkannya."
        default:
            return "Aplikasi butuh akses kamera untuk mengenali nominal uang secara langsung."
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .denied, .restricted:
            Button {
                openSettings()
            } label: {
                Text("Buka Pengaturan")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Membuka Pengaturan untuk memberi izin kamera.")
        default:
            Button {
                onRequest()
            } label: {
                Text("Izinkan Kamera")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Meminta izin akses kamera.")
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
