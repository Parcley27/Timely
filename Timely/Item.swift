//
//  Item.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-11-12.
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
