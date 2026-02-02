//
//  HabitCompletion.swift
//  ReverieWeaver
//
//  Tracks when habits are completed
//

import Foundation
import SwiftData

@Model
final class HabitCompletion {
    var id: UUID
    var habitId: UUID
    var completedAt: Date

    var reflection: Reflection?

    // Snapshot fields so timeline can render even if Habit is deleted/renamed
    var snapshotName: String?
    var snapshotIcon: String?
    var snapshotColorHex: String?
    
    // Program tracking
    var snapshotProgramTag: String?
    var snapshotProgramLevel: Int?
    var snapshotCategory: String?
    var snapshotCategoryIcon: String?
    
    var wasScheduledForDay: Bool?
    
    // Day-level snapshot for accurate completion rates
    var snapshotActiveHabitsCount: Int?

    init(habitId: UUID, completedAt: Date = Date()) {
        self.id = UUID()
        self.habitId = habitId
        self.completedAt = completedAt
    }

    convenience init(from habit: Habit, at date: Date = Date(), activeHabitsCount: Int, wasScheduledForDay: Bool) {
        self.init(habitId: habit.id, completedAt: date)
        
        // Basic snapshot data
        self.snapshotName = habit.name
        self.snapshotIcon = habit.icon
        self.snapshotColorHex = habit.colorHex
        
        // Program tracking (for challenges)
        self.snapshotProgramTag = habit.programTag
        self.snapshotProgramLevel = habit.programLevel
        
        // Category info (for filtering/display)
        self.snapshotCategory = habit.category
        self.snapshotCategoryIcon = habit.categoryIcon
        
        // Day-level context (for accurate completion rates)
        self.snapshotActiveHabitsCount = activeHabitsCount
        
        // Schedule tracking (for progress calculation)
        self.wasScheduledForDay = wasScheduledForDay
    }

    // Check if this completion is for today
    var isToday: Bool {
        let calendar = Calendar.current
        let completionDay = calendar.startOfDay(for: completedAt)
        let today = calendar.startOfDay(for: Date())
        return completionDay == today
    }

    // Get day component for grouping
    var dayStart: Date {
        Calendar.current.startOfDay(for: completedAt)
    }
    
    // MARK: - Display Helpers
    
    /// Get the habit name for display, using snapshot as fallback
    func displayName(from habits: [Habit]) -> String {
        if let habit = habits.first(where: { $0.id == habitId }) {
            return habit.name
        }
        return snapshotName ?? "Completed habit"
    }
    
    /// Get the habit color for display, using snapshot as fallback
    func displayColorHex(from habits: [Habit]) -> String {
        if let habit = habits.first(where: { $0.id == habitId }) {
            return habit.colorHex
        }
        return snapshotColorHex ?? "#999999"
    }
    
    /// Get the habit icon for display, using snapshot as fallback
    func displayIcon(from habits: [Habit]) -> String {
        if let habit = habits.first(where: { $0.id == habitId }) {
            return habit.icon
        }
        return snapshotIcon ?? "checkmark.circle"
    }
    
    /// Check if this completion belongs to a specific program
    func belongsToProgram(_ programTag: String) -> Bool {
        return snapshotProgramTag == programTag
    }
    
    /// Check if this completion belongs to a specific Project 50 level
    func belongsToLevel(_ level: Int) -> Bool {
        return snapshotProgramTag == "P50" && snapshotProgramLevel == level
    }
}


// MARK: - Reflection Model

@Model
class Reflection {
    var id: UUID
    var mood: String
    var notes: String
    var isFavorite: Bool
    var photosData: [Data] = []
    var habitId: UUID
    var habitName: String
    var habitColorHex: String
    var createdAt: Date
    
    init(mood: String, notes: String, isFavorite: Bool, photosData: [Data] = [], habitId: UUID, habitName: String, habitColorHex: String) {
        self.id = UUID()
        self.mood = mood
        self.notes = notes
        self.isFavorite = isFavorite
        self.photosData = photosData
        self.habitId = habitId
        self.habitName = habitName
        self.habitColorHex = habitColorHex
        self.createdAt = Date()
    }
}

// MARK: - Daily Intention Model

@Model
final class DailyIntention {
    var id: UUID
    var date: Date
    var text: String
    var mood: String
    
    init(date: Date = Date(), text: String = "", mood: String = "Peaceful") {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.text = text
        self.mood = mood
    }
}

// MARK: - Daily Reflection Model

@Model
final class DailyReflection {
    var id: UUID
    var date: Date
    var text: String
    var isRestDay: Bool
    
    init(date: Date, text: String = "", isRestDay: Bool = false) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.text = text
        self.isRestDay = isRestDay
    }
}
