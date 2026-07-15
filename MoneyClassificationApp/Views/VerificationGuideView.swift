//
//  VerificationGuideView.swift
//  MoneyClassificationApp
//
//  Panduan verifikasi manual keaslian uang: Dilihat, Diraba, Diterawang (3D).
//

import SwiftUI

struct VerificationGuideView: View {
    @State private var audioService = AudioFeedbackServiceHolder()

    private struct GuideStep: Identifiable {
        let id = Int.random(in: 0...Int.max)
        let title: String
        let detail: String
    }

    private let steps: [GuideStep] = [
        GuideStep(title: "Dilihat",
                  detail: "Lihat uang di bawah cahaya terang. Perhatikan warna yang jernih dan tajam, serta benang pengaman yang tampak seperti anyaman."),
        GuideStep(title: "Diraba",
                  detail: "Raba permukaan uang. Bagian gambar utama, angka nominal, dan tulisan terasa lebih kasar bila diusap."),
        GuideStep(title: "Diterawang",
                  detail: "Terawang uang ke arah cahaya. Akan terlihat tanda air berupa gambar pahlawan dan ornamen, serta gambar saling isi yang membentuk logo BI.")
    ]

    var body: some View {
        List {
            Section {
                ForEach(steps) { step in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(step.title)
                            .font(.headline)
                        Text(step.detail)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(step.title). \(step.detail)")
                }
            } header: {
                Text("Cara Verifikasi 3D")
            }

            Section {
                Button {
                    speakGuide()
                } label: {
                    Label("Putar Ulang Panduan Suara", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .accessibilityHint("Membacakan seluruh panduan verifikasi.")
            }

            Section {
                Text("Panduan ini membantu pengecekan mandiri. Aplikasi tidak menjamin keaslian uang. Bila ragu, verifikasi di bank atau kantor resmi.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Disclaimer. Aplikasi tidak menjamin keaslian uang. Bila ragu, verifikasi di bank atau kantor resmi.")
            }
        }
        .navigationTitle("Panduan Verifikasi")
        .onAppear { speakGuide() }
        .onDisappear { audioService.service.stop() }
    }

    private func speakGuide() {
        let intro = "Panduan verifikasi keaslian uang: Dilihat, Diraba, Diterawang."
        let body = steps.map { "\($0.title). \($0.detail)" }.joined(separator: " ")
        let disclaimer = "Perlu diingat, aplikasi tidak menjamin keaslian uang."
        audioService.service.speak("\(intro) \(body) \(disclaimer)", interrupt: true)
    }
}

/// Pembungkus agar service audio tetap hidup selama view aktif.
@Observable
final class AudioFeedbackServiceHolder {
    let service: AudioFeedbackServiceProtocol = AudioFeedbackService()
}

#Preview {
    NavigationStack {
        VerificationGuideView()
    }
}
