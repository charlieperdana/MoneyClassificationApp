//
//  MoneyRecord.swift
//  MoneyClassificationApp
//
//  Model SwiftData untuk menyimpan riwayat deteksi/perhitungan.
//  Menggantikan boilerplate `Item`.
//

import Foundation
import SwiftData

@Model
final class MoneyRecord {
    var timestamp: Date
    var totalValue: Int
    var sheetCount: Int
    /// Breakdown nominal -> jumlah lembar, disimpan sebagai data Codable.
    var breakdownData: Data
    var mode: String            // "single" | "count"

    init(timestamp: Date,
         totalValue: Int,
         sheetCount: Int,
         breakdown: [Int: Int],
         mode: String) {
        self.timestamp = timestamp
        self.totalValue = totalValue
        self.sheetCount = sheetCount
        self.breakdownData = (try? JSONEncoder().encode(breakdown)) ?? Data()
        self.mode = mode
    }

    /// Breakdown yang sudah didecode kembali menjadi dictionary.
    var breakdown: [Int: Int] {
        (try? JSONDecoder().decode([Int: Int].self, from: breakdownData)) ?? [:]
    }

    /// Ringkasan yang dapat dibacakan VoiceOver.
    var spokenSummary: String {
        let result = CountResult(total: totalValue,
                                 breakdown: breakdown,
                                 sheetCount: sheetCount)
        return result.spokenSummary()
    }
}
