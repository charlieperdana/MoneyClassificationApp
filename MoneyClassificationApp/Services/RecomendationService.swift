//
//  OpenAPIService.swift
//  MoneyClassificationApp
//
//  Created by Training-18 on 15/07/26.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case encodingFailed
    case noData
    case decodingFailed(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "URL tidak valid"
        case .encodingFailed:          return "Gagal encode request"
        case .noData:                  return "Tidak ada data dari server"
        case .decodingFailed(let msg): return "Gagal parse response: \(msg)"
        case .apiError(let msg): return "Error dari API: \(msg)"
        }
    }
}

final class RecomendationService {
    func generateRecomenddation(totalMoney: Int) async throws -> RecomendationData {
        guard let url = URL(string: Constants.aiEndpoint) else {
            throw APIError.invalidURL
        }

        let prompt = buildPrompt(totalMoney: totalMoney)
        let requestBody = OpenAIRequest(
            model: Constants.aiModel,
            messages: [
                OpenAIRequest.Message(role: "user", content: prompt)
            ]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw APIError.encodingFailed
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.apiError("Status \(httpResponse.statusCode): \(errorMessage)")
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let jsonString = openAIResponse.firstContent,
              let jsonData = jsonString.data(using: .utf8) else {
            throw APIError.noData
        }

        do {
            return try JSONDecoder().decode(RecomendationData.self, from: jsonData)
        } catch {
            throw APIError.decodingFailed(error.localizedDescription)
        }
    }

    private func buildPrompt(totalMoney: Int) -> String {
        return """
        Kamu adalah seorang perencana keuangan profesional yang membantu penyandang tuna netra mengelola dan membelanjakan uang mereka secara bijak.\n\nSaya memiliki total uang sebesar Rp\(totalMoney).\n\nBuatkan satu rekomendasi rencana belanja yang sesuai dengan jumlah uang tersebut. Pilih barang-barang yang bermanfaat untuk kebutuhan sehari-hari dan rekomendasikan tempat belanja yang mudah ditemukan di Indonesia.\n\nPENTING:\n- Kembalikan HANYA JSON yang valid.\n- Jangan gunakan markdown.\n- Jangan tambahkan penjelasan sebelum atau sesudah JSON.\n- Gunakan struktur JSON PERSIS seperti berikut.\n\n{\n  \"recomendation_name\": \"string\",\n  \"description\": \"string\",\n  \"itemsToBuy\": [\n    \"string\"\n  ],\n  \"steps\": [\n    \"string\"\n  ],\n  \"recomendation_shop\": {\n    \"shopName\": \"string\",\n    \"address\": \"string\"\n  }\n}
        """
    }
}
