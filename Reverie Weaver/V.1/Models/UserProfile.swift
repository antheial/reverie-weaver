//
// UserProfile.swift
// ReverieWeaver
//
// User profile and settings
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var personalMotto: String
    var weekStartsOnSunday: Bool
    var createdAt: Date
    
    init(
        displayName: String = "Weaver",
        personalMotto: String = "",
        weekStartsOnSunday: Bool = true
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.personalMotto = personalMotto
        self.weekStartsOnSunday = weekStartsOnSunday
        self.createdAt = Date()
    }
}
