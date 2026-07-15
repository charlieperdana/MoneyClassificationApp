//
//  CountView.swift
//  MoneyClassificationApp
//
//  Mode hitung total: arahkan ke beberapa lembar dan minta total.
//

import SwiftUI
import SwiftData

struct CountView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DetectionViewModel()
    @State private var navigateToRecommendation = false
    @State private var detectedTotal = 0

    var body: some View {
        ZStack {
            CameraPreview(previewLayer: viewModel.previewLayer)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack {
                Spacer()

                Text(summaryText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)

                Button(action: requestTotal) {
                    Text("Hitung Total")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 64)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Hitung total uang")
                .accessibilityHint("Ketuk untuk mendengar total nominal semua uang yang terlihat.")
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Hitung Total")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToRecommendation) {
            RecomendationView(totalMoney: detectedTotal)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { requestTotal() }
        .onAppear {
            viewModel.isCountMode = true
            viewModel.startDetection()
        }
        .onDisappear { viewModel.stopDetection() }
    }

    private var summaryText: String {
        let result = viewModel.countResult
        if result.isEmpty {
            return "Arahkan kamera ke uang, lalu ketuk Hitung Total."
        }
        return "Rp\(result.total.formatted()) — \(result.sheetCount) lembar"
    }

    private func requestTotal() {
        viewModel.requestTotal()
        let result = viewModel.countResult
        guard !result.isEmpty else { return }
        let record = MoneyRecord(timestamp: .now,
                                 totalValue: result.total,
                                 sheetCount: result.sheetCount,
                                 breakdown: result.breakdown,
                                 mode: "count")
        modelContext.insert(record)
        detectedTotal = result.total
        navigateToRecommendation = true
    }
}

#Preview {
    NavigationStack {
        CountView()
    }
}
