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
    var type: String
    var title: String
    var achievementDescription: String
    var earnedDate: Date
    var iconName: String
    var count: Int
    
    init(type: String, title: String, achievementDescription: String, iconName: String = "trophy.fill", count: Int = 1) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.achievementDescription = achievementDescription
        self.earnedDate = Date()
        self.iconName = iconName
        self.count = count
    }
}
