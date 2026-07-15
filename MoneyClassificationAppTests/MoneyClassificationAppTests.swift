//
//  MoneyClassificationAppTests.swift
//  MoneyClassificationAppTests
//
//  Unit test untuk logika inti: NominalMapper, CountAggregator,
//  dan DetectionViewModel (debounce + transisi state).
//

import Testing
import CoreGraphics
@testable import MoneyClassificationApp

// MARK: - NominalMapper (Task 2.1)

struct NominalMapperTests {

    @Test func mapsAllSupportedNominals() {
        for nominal in NominalMapper.supportedNominals {
            #expect(NominalMapper.value(from: "\(nominal)") == nominal)
        }
    }

    @Test func mapsShorthandLabels() {
        #expect(NominalMapper.value(from: "100rb") == 100000)
        #expect(NominalMapper.value(from: "50 ribu") == 50000)
        #expect(NominalMapper.value(from: "20k") == 20000)
    }

    @Test func mapsFormattedLabels() {
        #expect(NominalMapper.value(from: "Rp100.000") == 100000)
        #expect(NominalMapper.value(from: " 5000 ") == 5000)
    }

    @Test func rejectsUnsupportedOrEmpty() {
        #expect(NominalMapper.value(from: "") == nil)
        #expect(NominalMapper.value(from: "abc") == nil)
        #expect(NominalMapper.value(from: "3000") == nil)
    }

    @Test func spokenTextIndonesian() {
        #expect(NominalMapper.spokenText(for: 100000) == "seratus ribu rupiah")
        #expect(NominalMapper.spokenText(for: 1000) == "seribu rupiah")
        #expect(NominalMapper.spokenText(for: 2000) == "dua ribu rupiah")
        #expect(NominalMapper.spokenText(for: 50000) == "lima puluh ribu rupiah")
        #expect(NominalMapper.spokenText(for: 20000) == "dua puluh ribu rupiah")
    }

    @Test func indonesianWordsEdgeCases() {
        #expect(NominalMapper.indonesianWords(for: 0) == "nol")
        #expect(NominalMapper.indonesianWords(for: 11) == "sebelas")
        #expect(NominalMapper.indonesianWords(for: 15) == "lima belas")
        #expect(NominalMapper.indonesianWords(for: 21) == "dua puluh satu")
    }
}

// MARK: - MoneyDetectorService mapping (Task 3.2)

struct DetectorMappingTests {

    @Test func countResultSpokenSummaryEmpty() {
        #expect(CountResult.empty.spokenSummary() == "Tidak ada uang yang terlihat.")
    }

    @Test func countResultSpokenSummaryWithMoney() {
        let result = CountResult(total: 150000,
                                 breakdown: [100000: 1, 50000: 1],
                                 sheetCount: 2)
        let summary = result.spokenSummary()
        #expect(summary.contains("Total seratus lima puluh ribu rupiah."))
        #expect(summary.contains("Jumlah 2 lembar."))
    }
}

// MARK: - CountAggregator (Task 8.1)

struct CountAggregatorTests {

    private func detection(nominal: Int, box: CGRect) -> DetectedMoney {
        DetectedMoney(nominal: nominal, label: "\(nominal)", confidence: 0.9, boundingBox: box)
    }

    @Test func doesNotDoubleCountStableSheet() {
        let aggregator = CountAggregator(iouMatchThreshold: 0.5,
                                         framesToConfirm: 3,
                                         framesToForget: 5)
        let box = CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)
        let det = detection(nominal: 100000, box: box)

        // Belum stabil pada dua frame pertama.
        _ = aggregator.update(with: [det])
        _ = aggregator.update(with: [det])
        var result = aggregator.update(with: [det]) // frame ke-3: stabil.

        #expect(result.sheetCount == 1)
        #expect(result.total == 100000)

        // Frame tambahan tidak menambah hitungan lembar yang sama.
        result = aggregator.update(with: [det])
        #expect(result.sheetCount == 1)
        #expect(result.total == 100000)
    }

    @Test func countsMultipleDistinctSheets() {
        let aggregator = CountAggregator(framesToConfirm: 1)
        let a = detection(nominal: 100000, box: CGRect(x: 0.0, y: 0.0, width: 0.2, height: 0.2))
        let b = detection(nominal: 50000, box: CGRect(x: 0.6, y: 0.6, width: 0.2, height: 0.2))

        let result = aggregator.update(with: [a, b])
        #expect(result.sheetCount == 2)
        #expect(result.total == 150000)
        #expect(result.breakdown[100000] == 1)
        #expect(result.breakdown[50000] == 1)
    }

    @Test func resetClearsState() {
        let aggregator = CountAggregator(framesToConfirm: 1)
        let a = detection(nominal: 100000, box: CGRect(x: 0.0, y: 0.0, width: 0.2, height: 0.2))
        _ = aggregator.update(with: [a])
        aggregator.reset()
        #expect(aggregator.currentResult().isEmpty)
    }

    @Test func iouCalculation() {
        let a = CGRect(x: 0, y: 0, width: 1, height: 1)
        let b = CGRect(x: 0, y: 0, width: 1, height: 1)
        #expect(CountAggregator.intersectionOverUnion(a, b) == 1.0)

        let c = CGRect(x: 2, y: 2, width: 1, height: 1)
        #expect(CountAggregator.intersectionOverUnion(a, c) == 0.0)
    }
}
