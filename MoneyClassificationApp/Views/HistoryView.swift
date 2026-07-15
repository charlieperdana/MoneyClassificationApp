//
//  HistoryView.swift
//  MoneyClassificationApp
//
//  Riwayat deteksi/perhitungan yang tersimpan via SwiftData.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoneyRecord.timestamp, order: .reverse) private var records: [MoneyRecord]

    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView("Belum ada riwayat",
                                       systemImage: "clock",
                                       description: Text("Riwayat deteksi dan perhitungan akan muncul di sini."))
            } else {
                ForEach(records) { record in
                    row(for: record)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Riwayat")
        .toolbar {
            if !records.isEmpty {
                EditButton()
            }
        }
    }

    private func row(for record: MoneyRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rp\(record.totalValue.formatted())")
                .font(.headline)
            Text("\(record.sheetCount) lembar • \(record.mode == "count" ? "Hitung Total" : "Deteksi")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: record))
    }

    private func accessibilityLabel(for record: MoneyRecord) -> String {
        let date = record.timestamp.formatted(date: .abbreviated, time: .shortened)
        return "\(record.spokenSummary) Waktu \(date)."
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: MoneyRecord.self, inMemory: true)
}
