//
//  Reflection.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/26/25.
//

// DailyReflection.swift
import SwiftData
import Foundation

@Model
final class DailyReflection {
    var id: UUID
    var date: Date
    var text: String
    var isRestDay: Bool

    init(date: Date, text: String = "", isRestDay: Bool = false) {
        self.id = UUID()
        self.date = date
        self.text = text
        self.isRestDay = isRestDay
    }
}
