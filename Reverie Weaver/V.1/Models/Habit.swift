//
// Habit.swift
// ReverieWeaver
//
// SwiftData model for habits
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitDescription: String
    var category: String
    var categoryIcon: String
    var icon: String
    var colorHex: String
    var completionMessage: String
    var frequency: String // "daily" or "weekly"
    var createdAt: Date
    var order: Int
    
    var isArchived: Bool = false   // ✅ soft-delete flag
    var archivedAt: Date? = nil    // ✅ when it was archived (for history math)

    // ✨ NEW: Program tracking properties
       var programTag: String?      // "P50", "C7-FocusSprint", etc.
       var programLevel: Int?       // 1, 2, 3 for P50; nil otherwise
    
    // Relationship to completions
    @Relationship(deleteRule: .cascade) var completions: [HabitCompletion]?
    
    init(
        name: String,
        description: String,
        category: String,
        categoryIcon: String,
        icon: String,
        colorHex: String,
        completionMessage: String = "",
        frequency: String = "daily",
        order: Int = 0,
        programTag: String? = nil,       // ← Add this
        programLevel: Int? = nil         // ← Add this
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = description
        self.category = category
        self.categoryIcon = categoryIcon
        self.icon = icon
        self.colorHex = colorHex
        self.completionMessage = completionMessage
        self.frequency = frequency
        self.createdAt = Date()
        self.order = order
        self.programTag = programTag         // ← Initialize
        self.programLevel = programLevel     // ← Initialize
    }
}

