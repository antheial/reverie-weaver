// MiniChallengeProgress.swift
// Reverie Weaver
//
// Tracks progress for 7-day mini challenges
//

import SwiftData
import Foundation

@Model
final class MiniChallengeProgress {
    var id: UUID
    var challengeID: String  // Changed from UUID to String - Links to MiniChallenge.id
    var challengeTag: String  // e.g., "FocusSprint"
    var challengeTitle: String  // For display purposes
    var startDate: Date
    var targetDays: Int  // Always 7 for mini challenges
    var dailyCompletions: [Date]  // Array of dates when ALL habits were completed
    var isCompleted: Bool
    var completedDate: Date?
    var isPaused: Bool
    var pausedDate: Date?
    
    // ✅ NEW: Track which specific habits belong to this challenge
    var requiredHabitIDs: [UUID]  // Only THESE habits count for this challenge

    init(
        challengeID: String,  // Changed from UUID to String
        challengeTag: String,
        challengeTitle: String,
        requiredHabitIDs: [UUID] = [],  // ✅ NEW: Habits that must be completed
        startDate: Date = Date()
    ) {
        self.id = UUID()
        self.challengeID = challengeID
        self.challengeTag = challengeTag
        self.challengeTitle = challengeTitle
        self.requiredHabitIDs = requiredHabitIDs
        self.startDate = startDate
        self.targetDays = 7
        self.dailyCompletions = []
        self.isCompleted = false
        self.completedDate = nil
        self.isPaused = false
        self.pausedDate = nil
    }

    // MARK: - Computed Properties

    var daysCompleted: Int {
        dailyCompletions.count
    }

    var daysRemaining: Int {
        max(0, targetDays - daysCompleted)
    }

    var progressPercentage: Double {
        guard targetDays > 0 else { return 0 }
        return Double(daysCompleted) / Double(targetDays)
    }

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    var isWithinTimeframe: Bool {
        // Allow 10 days total to complete 7 days of habits (3-day buffer)
        daysSinceStart <= 10
    }

    // MARK: - Methods
    
    // ✅ NEW: Verify if ALL challenge habits are complete for a specific date
    /// Returns true only if ALL habits in requiredHabitIDs were completed on the given date
    func areAllChallengeHabitsComplete(
        on date: Date,
        completions: [HabitCompletion]
    ) -> Bool {
        // If no habits required, can't be complete
        guard !requiredHabitIDs.isEmpty else { return false }
        
        let calendar = Calendar.current
        
        // Get completions for the specific date
        let dateCompletions = completions.filter { completion in
            calendar.isDate(completion.completedAt, inSameDayAs: date)
        }
        
        // Check if ALL required habits were completed
        return requiredHabitIDs.allSatisfy { habitID in
            dateCompletions.contains { $0.habitId == habitID }
        }
    }
    
    // ✅ NEW: Auto-check and mark if all habits complete
    /// Call this after any habit completion to check if the day is now complete
    func checkAndUpdateProgress(completions: [HabitCompletion]) {
        let today = Date()
        
        // Only proceed if:
        // 1. Today is not already marked complete
        // 2. All challenge habits are actually complete
        // 3. Challenge is still active (not paused, not completed)
        guard !isDateCompleted(today),
              !isPaused,
              !isCompleted,
              areAllChallengeHabitsComplete(on: today, completions: completions) else {
            return
        }
        
        // All conditions met - mark today as complete!
        markTodayComplete()
    }
    
    // ✅ NEW: Get completion status for displaying in UI
    /// Returns how many of the required habits are complete today
    func getTodayProgress(completions: [HabitCompletion]) -> (completed: Int, total: Int) {
        let calendar = Calendar.current
        let today = Date()
        
        let todayCompletions = completions.filter { completion in
            calendar.isDate(completion.completedAt, inSameDayAs: today)
        }
        
        let completedCount = requiredHabitIDs.filter { habitID in
            todayCompletions.contains { $0.habitId == habitID }
        }.count
        
        return (completed: completedCount, total: requiredHabitIDs.count)
    }

    // MARK: - Methods

    /// Check if a specific date has been marked as complete
    func isDateCompleted(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return dailyCompletions.contains { completion in
            calendar.isDate(completion, inSameDayAs: date)
        }
    }

    // MARK: - Progress Update Methods

    /// Mark today as complete if not already done
    /// Previously private — now internal so MiniChallengeDetailView can update manually if needed
    func markTodayComplete() {
        let today = Date()
        
        // Avoid duplicates
        if !isDateCompleted(today) {
            dailyCompletions.append(today)
            
            // Check if challenge is now complete
            if daysCompleted >= targetDays {
                isCompleted = true
                completedDate = Date()
            }
        }
    }
    
    // Add this wrapper just below it
    //func safelyMarkTodayComplete() {
        // You control exactly how/when markTodayComplete() is used
       // markTodayComplete()
    //}

    /// Check if today is already marked complete in the challenge
    /// Note: This checks if the date is in dailyCompletions, not if habits are complete
    var isTodayComplete: Bool {
        isDateCompleted(Date())
    }
    
    /// Check if today's challenge habits are all complete (based on actual completions)
    func isTodayChallengeComplete(completions: [HabitCompletion]) -> Bool {
        areAllChallengeHabitsComplete(on: Date(), completions: completions)
    }
}
