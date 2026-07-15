//
//  CountResult.swift
//  MoneyClassificationApp
//
//  Hasil perhitungan total uang yang terlihat pada satu sesi/frame.
//

import Foundation

struct CountResult: Equatable {
    let total: Int
    let breakdown: [Int: Int]   // nominal -> jumlah lembar
    let sheetCount: Int

    static let empty = CountResult(total: 0, breakdown: [:], sheetCount: 0)

    var isEmpty: Bool { sheetCount == 0 }

    /// Teks pengucapan Bahasa Indonesia untuk total dan rincian.
    func spokenSummary() -> String {
        guard !isEmpty else {
            return "Tidak ada uang yang terlihat."
        }

        var parts: [String] = []
        parts.append("Total \(NominalMapper.spokenText(for: total)).")
        parts.append("Jumlah \(sheetCount) lembar.")

        let sortedNominals = breakdown.keys.sorted(by: >)
        for nominal in sortedNominals {
            guard let count = breakdown[nominal], count > 0 else { continue }
            let nominalText = NominalMapper.spokenText(for: nominal)
            parts.append("\(count) lembar \(nominalText).")
        }

        return parts.joined(separator: " ")
    }
}
