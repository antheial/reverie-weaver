//
//  Item.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/5/25.
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
