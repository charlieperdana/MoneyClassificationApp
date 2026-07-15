//
//  RecomendationView.swift
//  MoneyClassificationApp
//
//  Created by Training-18 on 15/07/26.
//

import SwiftUI

struct RecomendationView: View {

    let totalMoney: Int

    @State private var viewModel = RecomendationViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Membuat rekomendasi...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let recommendation = viewModel.recomendation {
                recommendationContent(recommendation)

            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Terjadi Kesalahan",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )

            } else {
                ContentUnavailableView(
                    "Belum Ada Rekomendasi",
                    systemImage: "doc.text"
                )
            }
        }
        .navigationTitle("Rekomendasi")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.generateRecomendation(for: totalMoney)
            await viewModel.generateRecomendationSpeech(for: totalMoney)
        }
    }

    @ViewBuilder
    private func recommendationContent(_ recommendation: RecomendationData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                headerSection(recommendation)

                descriptionSection(recommendation)

                shoppingListSection(recommendation)

                shopSection(recommendation)

                stepsSection(recommendation)
            }
            .padding()
        }
    }

    // MARK: Header

    @ViewBuilder
    private func headerSection(_ recommendation: RecomendationData) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Label(
                "Rekomendasi Belanja",
                systemImage: "wallet.pass.fill"
            )
            .font(.headline)

            Text(recommendation.recomendationName)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: Description

    @ViewBuilder
    private func descriptionSection(_ recommendation: RecomendationData) -> some View {

        GroupBox("Deskripsi") {
            Text(recommendation.description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Shopping List

    @ViewBuilder
    private func shoppingListSection(_ recommendation: RecomendationData) -> some View {

        GroupBox("Daftar Belanja") {

            VStack(alignment: .leading, spacing: 14) {

                ForEach(recommendation.itemsToBuy, id: \.self) { item in

                    HStack(alignment: .top) {

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Text(item)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Shop

    @ViewBuilder
    private func shopSection(_ recommendation: RecomendationData) -> some View {

        GroupBox("Tempat Belanja") {

            VStack(alignment: .leading, spacing: 10) {

                Label(
                    recommendation.recomendationShop.shopName,
                    systemImage: "storefront.fill"
                )

                Label(
                    recommendation.recomendationShop.address,
                    systemImage: "location.fill"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Steps

    @ViewBuilder
    private func stepsSection(_ recommendation: RecomendationData) -> some View {

        GroupBox("Langkah Belanja") {

            VStack(alignment: .leading, spacing: 16) {

                ForEach(
                    Array(recommendation.steps.enumerated()),
                    id: \.offset
                ) { index, step in

                    HStack(alignment: .top) {

                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 30, height: 30)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Circle())

                        Text(step)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        RecomendationView(totalMoney: 150_000)
    }
}
