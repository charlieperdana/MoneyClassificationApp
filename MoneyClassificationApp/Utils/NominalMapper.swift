//
//  NominalMapper.swift
//  MoneyClassificationApp
//
//  Utility untuk memetakan label mentah model MoneyDetector ke nilai Rupiah
//  serta menghasilkan teks pengucapan Bahasa Indonesia.
//

import Foundation

enum NominalMapper {

    /// Daftar nominal Rupiah yang didukung model (7 kelas).
    static let supportedNominals: [Int] = [1000, 2000, 5000, 10000, 20000, 50000, 100000]

    /// Memetakan label mentah dari model (mis. "100000", "Rp100.000", "100rb")
    /// menjadi nilai integer. Mengembalikan `nil` bila tidak dikenali.
    static func value(from label: String) -> Int? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        // Ambil hanya digit dari label.
        let digits = trimmed.filter { $0.isNumber }

        if let direct = Int(digits) {
            // Bila label sudah berupa angka penuh dan didukung, gunakan langsung.
            if supportedNominals.contains(direct) {
                return direct
            }
        }

        // Tangani label bergaya singkat, mis. "100rb", "100k", "50 ribu".
        let lower = trimmed.lowercased()
        if let base = Int(digits) {
            if lower.contains("rb") || lower.contains("ribu") || lower.contains("k") {
                let value = base * 1000
                if supportedNominals.contains(value) { return value }
            }
            if supportedNominals.contains(base) { return base }
        }

        return nil
    }

    /// Menghasilkan teks pengucapan Bahasa Indonesia dari sebuah nilai Rupiah.
    /// Contoh: 100000 -> "seratus ribu rupiah".
    static func spokenText(for value: Int) -> String {
        guard value > 0 else { return "nol rupiah" }
        let words = indonesianWords(for: value)
        return "\(words) rupiah"
    }

    /// Mengubah angka menjadi kata Bahasa Indonesia (tanpa satuan "rupiah").
    static func indonesianWords(for number: Int) -> String {
        if number == 0 { return "nol" }
        if number < 0 { return "minus \(indonesianWords(for: -number))" }

        var result = ""
        var value = number

        let billion = value / 1_000_000_000
        if billion > 0 {
            result += "\(indonesianWords(for: billion)) miliar "
            value %= 1_000_000_000
        }

        let million = value / 1_000_000
        if million > 0 {
            result += "\(indonesianWords(for: million)) juta "
            value %= 1_000_000
        }

        let thousand = value / 1000
        if thousand > 0 {
            if thousand == 1 {
                result += "seribu "
            } else {
                result += "\(indonesianWords(for: thousand)) ribu "
            }
            value %= 1000
        }

        if value > 0 {
            result += hundredsWords(for: value)
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Menangani angka 1-999.
    private static func hundredsWords(for number: Int) -> String {
        let units = ["", "satu", "dua", "tiga", "empat", "lima",
                     "enam", "tujuh", "delapan", "sembilan", "sepuluh",
                     "sebelas"]

        var result = ""
        var value = number

        let hundred = value / 100
        if hundred > 0 {
            if hundred == 1 {
                result += "seratus "
            } else {
                result += "\(units[hundred]) ratus "
            }
            value %= 100
        }

        if value >= 12 && value <= 19 {
            result += "\(units[value % 10]) belas"
        } else if value == 11 {
            result += "sebelas"
        } else if value == 10 {
            result += "sepuluh"
        } else if value >= 20 {
            let tens = value / 10
            result += "\(units[tens]) puluh"
            if value % 10 > 0 {
                result += " \(units[value % 10])"
            }
        } else if value > 0 {
            result += units[value]
        }

        return result.trimmingCharacters(in: .whitespaces)
    }
}
