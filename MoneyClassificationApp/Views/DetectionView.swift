//
//  DetectionView.swift
//  MoneyClassificationApp
//
//  Mode deteksi real-time dengan overlay bounding box kontras tinggi.
//

import SwiftUI

struct DetectionView: View {
    @State private var viewModel = DetectionViewModel()

    var body: some View {
        ZStack {
            CameraPreview(previewLayer: viewModel.previewLayer)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            // Overlay bounding box.
            GeometryReader { geo in
                ForEach(viewModel.currentDetections) { detection in
                    boundingBox(for: detection, in: geo.size)
                }
            }
            .allowsHitTesting(false)

            VStack {
                Spacer()
                statusBanner
            }
            .padding()
        }
        .navigationTitle("Deteksi Uang")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startDetection() }
        .onDisappear { viewModel.stopDetection() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mode deteksi uang")
        .accessibilityHint("Arahkan kamera ke uang kertas untuk mendengar nominalnya.")
        .accessibilityValue(viewModel.accessibilitySummary)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var statusBanner: some View {
        let message = bannerMessage
        if let message {
            Text(message)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)
        }
    }

    private var bannerMessage: String? {
        switch viewModel.state {
        case .idle: return "Menyiapkan kamera..."
        case .noMoney: return viewModel.guidanceMessage ?? "Arahkan kamera ke uang."
        case .lowLight: return viewModel.guidanceMessage ?? "Kurang cahaya."
        case .error(let message): return message
        case .running:
            if let top = viewModel.currentDetections.max(by: { $0.confidence < $1.confidence }) {
                return NominalMapper.spokenText(for: top.nominal).capitalized
            }
            return nil
        }
    }

    private func boundingBox(for detection: DetectedMoney, in size: CGSize) -> some View {
        // Vision origin bawah-kiri; konversi ke koordinat SwiftUI (atas-kiri).
        let box = detection.boundingBox
        let rect = CGRect(x: box.minX * size.width,
                          y: (1 - box.maxY) * size.height,
                          width: box.width * size.width,
                          height: box.height * size.height)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow, lineWidth: 4)
                .frame(width: rect.width, height: rect.height)

            Text("Rp\(detection.nominal.formatted(.number.grouping(.automatic)))")
                .font(.headline.weight(.bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.yellow)
                .offset(y: -28)
        }
        .position(x: rect.midX, y: rect.midY)
    }
}

#Preview {
    NavigationStack {
        DetectionView()
    }
}
