//
//  RecomendationViewModel.swift
//  MoneyClassificationApp
//
//  Created by Training-18 on 15/07/26.
//

import Foundation

@Observable
final class RecomendationViewModel {
    var recomendation: RecomendationData?
    var textToSpeech: String?
    var isLoading = false
    var errorMessage: String?

    private let service = RecomendationService()
    private let audioService: AudioFeedbackServiceProtocol
    
    init() {
        self.audioService = AudioFeedbackService()
    }

    func generateRecomendation(for totalMoney: Int) async {
        guard totalMoney > 0 else {
            errorMessage = "Tidak ada total uang yang terdeteksi"
            return
        }

        isLoading = true
        errorMessage = nil
        recomendation = nil

        do {
            recomendation = try await service.generateRecomenddation(totalMoney: totalMoney)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func generateRecomendationSpeech(for totalMoney: Int) async {
        guard totalMoney > 0 else {
            errorMessage = "Tidak ada total uang yang terdeteksi"
            return
        }

        isLoading = true
        errorMessage = nil
        recomendation = nil

        do {
            textToSpeech = try await service.generateRecomendationSpeech(totalMoney: totalMoney)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        if let textToSpeech {
            audioService.speak(textToSpeech, interrupt: true)
        }
        

        isLoading = false
    }
}
