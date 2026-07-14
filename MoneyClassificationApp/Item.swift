//
//  Item.swift
//  MoneyClassificationApp
//
//  Created by Training-18 on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
