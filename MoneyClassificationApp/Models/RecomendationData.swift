//
//  OpenAPIRequest.swift
//  MoneyClassificationApp
//
//  Created by Training-18 on 15/07/26.
//

import Foundation

// MARK: - Request

struct OpenAIRequest: Encodable {
    let model: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

// MARK: - Response

struct OpenAIResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message

        struct Message: Decodable {
            let content: String
        }
    }

    var firstContent: String? { choices.first?.message.content }
}

// MARK: - Recomendation Data

struct RecomendationData: Decodable, Identifiable {
    let id = UUID()
    let recomendationName: String
    let description: String
    let itemsToBuy: [String]
    let steps: [String]
    let recomendationShop: RecomendationShop

    enum CodingKeys: String, CodingKey {
        case recomendationName = "recomendation_name"
        case recomendationShop = "recomendation_shop"
        case description, itemsToBuy, steps
    }
}

struct RecomendationShop: Decodable {
    let shopName: String
    let address: String
}

struct RecommendationSpeech: Decodable, Identifiable {
    let id = UUID()
    let recommendation: String
}
