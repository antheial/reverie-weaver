//
//  Achievement.swift
//  ReverieWeaver
//
//  Achievement tracking
//

import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var type: String // "perfect_day", "streak_7", etc.
    var title: String
    var achievementDescription: String  // Changed from 'description'
    var earnedDate: Date
    var iconName: String
    var count: Int  // ← ADD THIS LINE
    
    init(type: String, title: String, achievementDescription: String, iconName: String = "trophy.fill", count: Int = 1) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.achievementDescription = achievementDescription
        self.earnedDate = Date()
        self.iconName = iconName
        self.count = count  // ← ADD THIS LINE
    }
}
