//
//  ThresholdProvider.swift
//  MoneyClassificationApp
//
//  Created by Training-17 on 15/07/26.
//

import CoreML

final class ThresholdProvider: MLFeatureProvider {

    let confidenceThreshold: Float
    let iouThreshold: Float

    init(confidenceThreshold: Float,
         iouThreshold: Float) {
        self.confidenceThreshold = confidenceThreshold
        self.iouThreshold = iouThreshold
    }

    var featureNames: Set<String> {
        [
            "confidenceThreshold",
            "iouThreshold"
        ]
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        switch featureName {
        case "confidenceThreshold":
            return MLFeatureValue(double: Double(confidenceThreshold))

        case "iouThreshold":
            return MLFeatureValue(double: Double(iouThreshold))

        default:
            return nil
        }
    }
}
