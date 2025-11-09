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

    // You already have this:
    var reflection: Reflection?  // keep

    // ✅ NEW — Snapshot fields so timeline can render even if Habit is deleted/renamed
    var snapshotName: String?
    var snapshotIcon: String?
    var snapshotColorHex: String?
    
    // ✅ ADD THESE 4 LINES:
        var snapshotProgramTag: String?
        var snapshotProgramLevel: Int?
        var snapshotCategory: String?
        var snapshotCategoryIcon: String?

    // Existing initializer still works (back-compat),
    // but prefer the new `init(from:)` below going forward.
    init(habitId: UUID, completedAt: Date = Date()) {
        self.id = UUID()
        self.habitId = habitId
        self.completedAt = completedAt
        // leave snapshot* nil — we’ll backfill or ignore for old rows
    }

    // ✅ UPDATED - capture a complete snapshot at the moment of completion
    convenience init(from habit: Habit, at date: Date = Date()) {
        self.init(habitId: habit.id, completedAt: date)
        
        // Basic snapshot data
        self.snapshotName = habit.name
        self.snapshotIcon = habit.icon
        self.snapshotColorHex = habit.colorHex
        
        // ✅ Program tracking (critical for challenges)
        self.snapshotProgramTag = habit.programTag
        self.snapshotProgramLevel = habit.programLevel
        
        // ✅ Category info (useful for filtering/display)
        self.snapshotCategory = habit.category
        self.snapshotCategoryIcon = habit.categoryIcon
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
    
    // MARK: - Display Helpers (for views)
    
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


// MARK: - Updated Reflection Model (Add this to your Models)
@Model
class Reflection {
    var id: UUID
    var mood: String
    var notes: String
    var isFavorite: Bool
    var photoData: Data?           // NEW
    var habitId: UUID              // NEW
    var habitName: String          // NEW
    var habitColorHex: String      // NEW
    var createdAt: Date
    
    init(mood: String, notes: String, isFavorite: Bool, photoData: Data? = nil, habitId: UUID, habitName: String, habitColorHex: String) {
        self.id = UUID()
        self.mood = mood
        self.notes = notes
        self.isFavorite = isFavorite
        self.photoData = photoData
        self.habitId = habitId
        self.habitName = habitName
        self.habitColorHex = habitColorHex
        self.createdAt = Date()
    }
}
// MARK: - Also update HabitCompletion model to link reflections
// Add this property to HabitCompletion:
// var reflection: Reflection?

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
