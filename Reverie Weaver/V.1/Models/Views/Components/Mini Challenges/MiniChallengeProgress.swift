// MiniChallengeProgress.swift
// Reverie Weaver
//
// Tracks progress for 7-day mini challenges with 8-day completion window
//
// KEY CONCEPTS:
// - Users must complete 7 challenge days within an 8-day window (+ rest days)
// - REST DAYS pause the calendar and extend the 8-day window
// - MISSED DAYS advance the calendar and count as incomplete
// - Example: Complete 2 days → Rest day (day pauses) → Complete 3 days → Miss Day 6 (calendar advances) → Complete 2 days
// - After 8 days (+ rest days):
//   - 6/7+ days (≥85.7%): Archived as partial success, shown in MonthlyArchiveView
//   - <6/7 days (<85.7%): Shows restart prompt, no archive entry
//
// BEHAVIOR:
// - Rest Day (explicit): User marks day as rest → Calendar pauses, day counter doesn't advance
// - Missed Day (implicit): User forgets/skips → Calendar advances, day marked as missed
//
// isTodayChallengeComplete (Required for WeeklyArchiveView real-time tracking)
//

import SwiftData
import Foundation

@Model
final class MiniChallengeProgress {
    var id: UUID
    var challengeID: String
    var challengeTag: String
    var challengeTitle: String
    var startDate: Date
    var targetDays: Int
    
    var dailyCompletions: [Date]
    var requiredHabitIDs: [UUID]
    
    var isCompleted: Bool
    var completedDate: Date?
    var isPaused: Bool
    var pausedDate: Date?

    /// Whether the challenge has been archived (after 8-day window passes)
    /// Archived challenges are removed from WeeklyArchiveView tracking
    var isArchived: Bool
    var archivedDate: Date?

    init(
        challengeID: String,
        challengeTag: String,
        challengeTitle: String,
        requiredHabitIDs: [UUID] = [],
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
        self.isArchived = false
        self.archivedDate = nil
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
    
    /// Progress percentage accounting for rest days
    /// Rest days PAUSE the challenge - they do NOT extend the program length
    /// Progress is always calculated as daysCompleted / targetDays (7)
    func progressPercentage(reflections: [DailyReflection]) -> Double {
        // Rest days only pause the calendar and extend the deadline window
        // They do NOT increase the total program days
        guard targetDays > 0 else { return 0 }
        return Double(daysCompleted) / Double(targetDays)
    }

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }
    
    /// The current scheduled day number (1-7), accounting for rest days
    /// Rest days PAUSE the calendar - they extend the timeline without advancing the day counter
    /// Skipped/missed days still advance the calendar (and count as missed)
    ///
    /// Example Timeline:
    /// ```
    /// Start: 1/20, Challenge begins on Day 1
    ///
    /// 1/20 - Day 1: Complete ✓ (daysCompleted = 1)
    /// 1/21 - Day 2: Complete ✓ (daysCompleted = 2)
    /// 1/22 - Day 3: Mark REST DAY 🌙 (calendar pauses, daysCompleted = 2)
    /// 1/23 - Day 3: Still Day 3 (rest extended timeline, daysCompleted = 2)
    ///              Complete ✓ (daysCompleted = 3)
    /// 1/24 - Day 4: Forgot/skipped ❌ (calendar advances, daysCompleted = 3)
    /// 1/25 - Day 5: Calendar moved on (Day 4 is now missed, daysCompleted = 3)
    /// ```
    func currentScheduledDay(reflections: [DailyReflection]) -> Int {
        let calendar = Calendar.current
        let programStart = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        
        // Get all rest day dates
        let restDates = Set(restDayDates(from: reflections))
        
        // Count only NON-REST days that have passed since challenge start
        var activeDaysCount = 0
        var currentDate = programStart
        
        while currentDate <= today {
            // Only count days that are NOT rest days
            if !restDates.contains(currentDate) {
                activeDaysCount += 1
            }
            
            // Move to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        // The current scheduled day is the count of active (non-rest) days
        return min(max(1, activeDaysCount), targetDays)
    }

    /// 8-day completion window constant
    static let completionWindowDays = 8

    /// Success threshold: 6/7 days = 85.7%
    static let successThreshold: Double = 6.0 / 7.0

    var isWithinTimeframe: Bool {
        // Allow 8 days total to complete 7 days of habits (1-day buffer)
        // Note: Rest days extend this window
        daysSinceStart <= Self.completionWindowDays
    }

    /// Check if challenge is within the extended timeframe (accounting for rest days)
    /// Rest days extend the 8-day window since they pause the challenge
    func isWithinTimeframe(reflections: [DailyReflection]) -> Bool {
        let restDays = countRestDaysSinceStart(reflections: reflections)
        let extendedWindow = Self.completionWindowDays + restDays  // Base 8 days + rest day extensions
        return daysSinceStart <= extendedWindow
    }

    var isExpired: Bool {
        // Challenge expires if 8-day window has passed and not completed
        daysSinceStart > Self.completionWindowDays && !isCompleted
    }

    /// Check if challenge is expired (accounting for rest days)
    /// Rest days extend the expiration window
    func isExpired(reflections: [DailyReflection]) -> Bool {
        let restDays = countRestDaysSinceStart(reflections: reflections)
        let extendedWindow = Self.completionWindowDays + restDays
        return daysSinceStart > extendedWindow && !isCompleted
    }

    /// Success rate as a percentage (0.0 to 1.0)
    /// Used to determine if challenge qualifies for archive (≥85.7% = 6/7 days)
    var successRate: Double {
        guard targetDays > 0 else { return 0 }
        return Double(daysCompleted) / Double(targetDays)
    }

    /// Whether the challenge met the success threshold (≥6/7 days completed)
    var isSuccessful: Bool {
        successRate >= Self.successThreshold
    }

    /// Whether the challenge should be archived (expired + meets success threshold)
    func shouldArchive(reflections: [DailyReflection]) -> Bool {
        isExpired(reflections: reflections) && isSuccessful && !isArchived
    }

    /// Whether the challenge should show restart prompt (expired + below success threshold)
    func shouldShowRestart(reflections: [DailyReflection]) -> Bool {
        isExpired(reflections: reflections) && !isSuccessful && !isArchived
    }

    /// Archive the challenge as a partial success
    func archive() {
        guard !isArchived else { return }
        isArchived = true
        archivedDate = Date()
    }
    
    // Checks if the progress record has already marked today as done in the database
    var isTodayComplete: Bool {
        isDateCompleted(Date())
    }
    
    /// Check if today is complete (challenge day completed)
    /// Note: This checks if the current day (accounting for rest day pauses) has been completed
    /// Rest days do NOT count as complete - they pause the challenge
    func isTodayComplete(reflections: [DailyReflection]) -> Bool {
        // Check if challenge day completed
        return isDateCompleted(Date())
    }
    
    // MARK: - Rest Day Helpers
    
    /// Count rest days since challenge start
    /// Rest days pause the challenge timeline - they extend the schedule without advancing the day counter
    /// Missed days (no completion, no rest) still advance the calendar and count as incomplete
    private func countRestDaysSinceStart(reflections: [DailyReflection]) -> Int {
        let calendar = Calendar.current
        let programStart = calendar.startOfDay(for: startDate)
        
        return reflections.filter { reflection in
            reflection.isRestDay &&
            calendar.startOfDay(for: reflection.date) >= programStart &&
            calendar.startOfDay(for: reflection.date) <= Date()
        }.count
    }
    
    /// Get rest day dates within challenge timeline (from start until today)
    func restDayDates(from reflections: [DailyReflection]) -> [Date] {
        let calendar = Calendar.current
        let programStart = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        
        return reflections
            .filter { $0.isRestDay }
            .map { calendar.startOfDay(for: $0.date) }
            .filter { $0 >= programStart && $0 <= today }
            .sorted()
    }
    
    /// Calculate the number of missed days (days that passed but weren't completed or marked as rest)
    /// Missed days = active (non-rest) days that have passed without completion
    func missedDays(reflections: [DailyReflection]) -> Int {
        let calendar = Calendar.current
        let programStart = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        
        // Get all rest day dates
        let restDates = Set(restDayDates(from: reflections))
        
        // Get all completion dates
        let completedDates = Set(dailyCompletions.map { calendar.startOfDay(for: $0) })
        
        // Count active days that have passed but weren't completed
        var missedCount = 0
        var currentDate = programStart
        
        while currentDate < today {
            // Skip rest days - they don't count as missed
            if !restDates.contains(currentDate) {
                // This is an active day - check if it was completed
                if !completedDates.contains(currentDate) {
                    missedCount += 1
                }
            }
            
            // Move to next calendar day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return missedCount
    }

    // MARK: - Progress Logic
    
    /// Check if ALL required habits were completed on a specific date
    func areAllChallengeHabitsComplete(on date: Date, completions: [HabitCompletion]) -> Bool {
        guard !requiredHabitIDs.isEmpty else { return false }
        
        let calendar = Calendar.current
        
        // Filter completions for this specific date
        let dateCompletions = completions.filter { completion in
            calendar.isDate(completion.completedAt, inSameDayAs: date)
        }
        
        // Verify every required habit ID is present in the day's completions
        return requiredHabitIDs.allSatisfy { habitID in
            dateCompletions.contains { $0.habitId == habitID }
        }
    }
    
    /// Check if today's challenge habits are all complete (based on actual completions)
    /// Used by WeeklyArchiveView to determine real-time status
    func isTodayChallengeComplete(completions: [HabitCompletion]) -> Bool {
        areAllChallengeHabitsComplete(on: Date(), completions: completions)
    }
    
    /// Auto-check and mark progress
    /// Uses rest-day-aware expiration check to properly account for rest days extending the deadline
    func checkAndUpdateProgress(completions: [HabitCompletion], reflections: [DailyReflection]) {
        let today = Date()

        // Only proceed if:
        // 1. Challenge hasn't expired (still within 8-day window + rest days)
        // 2. Today is not already marked complete
        // 3. All challenge habits are actually complete
        // 4. Challenge is still active (not paused, not completed, not archived)
        guard !isExpired(reflections: reflections),
              !isArchived,
              !isDateCompleted(today),
              !isPaused,
              !isCompleted,
              areAllChallengeHabitsComplete(on: today, completions: completions) else {
            return
        }

        // All conditions met - mark today as complete!
        markTodayComplete()
    }
    
    /// UI Helper: Get x/y completion status for today
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

    /// Check if a specific date has been marked as complete
    func isDateCompleted(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return dailyCompletions.contains { completionDate in
            calendar.isDate(completionDate, inSameDayAs: date)
        }
    }

    /// Mark today as complete safely (Idempotent)
    func markTodayComplete() {
        let today = Date()
        
        // Prevent duplicate entries for the same day
        if !isDateCompleted(today) {
            dailyCompletions.append(today)
            
            // Check for challenge completion
            if daysCompleted >= targetDays {
                isCompleted = true
                completedDate = today
            }
        }
    }
}
