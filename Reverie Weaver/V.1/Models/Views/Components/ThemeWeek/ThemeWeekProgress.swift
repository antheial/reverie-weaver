//
//  ThemeWeekProgress.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/16/25.
//
//  Tracks progress for 7-day theme weeks with 8-day completion window
//
//  KEY CONCEPTS:
//  - Users must complete 7 theme week days within an 8-day window (+ rest days)
//  - REST DAYS pause the calendar and extend the 8-day window
//  - After 8 days (+ rest days):
//    - 6/7+ days (≥85.7%): Archived as partial success, shown in MonthlyArchiveView
//    - <6/7 days (<85.7%): Shows restart prompt, no archive entry
//

import SwiftData
import Foundation

@Model
final class ThemeWeekProgress {
    var id: UUID
    var programID: String
    var programTag: String
    var programTitle: String
    var startDate: Date
    var sessionID: String = ""  // Unique identifier for this specific week run (default for migration)
    
    @Attribute(.externalStorage)
    var completionRecords: [DayCompletionRecord]
    
    var isCompleted: Bool
    var completedDate: Date?
    var isPaused: Bool
    var pausedDate: Date?
    var hasViewedCompletionSheet: Bool = false

    /// Whether the theme week has been archived (after 8-day window passes)
    /// Archived theme weeks are removed from WeeklyArchiveView tracking
    var isArchived: Bool
    var archivedDate: Date?

    init(
        programID: String,
        programTag: String,
        programTitle: String,
        startDate: Date = Date()
    ) {
        self.id = UUID()
        self.programID = programID
        self.programTag = programTag
        self.programTitle = programTitle
        self.startDate = startDate
        
        // Generate unique session ID: tag_date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.sessionID = "\(programTag)_\(formatter.string(from: startDate))"
        
        self.completionRecords = []
        self.isCompleted = false
        self.completedDate = nil
        self.isPaused = false
        self.pausedDate = nil
        self.hasViewedCompletionSheet = false
        self.isArchived = false
        self.archivedDate = nil
    }
    
    // MARK: - Computed Properties
    
    var daysCompleted: Int {
        completionRecords.count
    }
    
    var daysRemaining: Int {
        max(0, 7 - daysCompleted)
    }
    
    var progressPercentage: Double {
        Double(daysCompleted) / 7.0
    }
    
    /// Progress percentage accounting for rest days
    /// Rest days PAUSE the program - they do NOT extend the program length
    /// Progress is always calculated as daysCompleted / 7
    func progressPercentage(reflections: [DailyReflection]) -> Double {
        // Rest days only pause the calendar and extend the deadline
        // They do NOT increase the total program days
        return Double(daysCompleted) / 7.0
    }
    
    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }
    
    /// Current day number (calendar-based, doesn't account for rest days)
    var currentDayNumber: Int {
        min(daysSinceStart + 1, 7)
    }
    
    /// The current scheduled day number (1-7), accounting for rest days
    /// Rest days PAUSE the calendar - they extend the timeline without advancing the day counter
    /// Skipped/missed days still advance the calendar (and count as missed)
    ///
    /// Example Timeline:
    /// ```
    /// Start: 1/20, Program begins on Day 1
    ///
    /// 1/20 - Day 1: Complete workout ✓ (daysCompleted = 1)
    /// 1/21 - Day 2: Complete workout ✓ (daysCompleted = 2)
    /// 1/22 - Day 3: Mark REST DAY 🌙 (calendar pauses, daysCompleted = 2)
    /// 1/23 - Day 3: Still Day 3 (rest extended timeline, daysCompleted = 2)
    ///              Complete workout ✓ (daysCompleted = 3)
    /// 1/24 - Day 4: Forgot/skipped ❌ (calendar advances, daysCompleted = 3)
    /// 1/25 - Day 5: Calendar moved on (Day 4 is now missed, daysCompleted = 3)
    /// ```
    func currentScheduledDay(reflections: [DailyReflection]) -> Int {
        let calendar = Calendar.current
        let programStart = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        
        // Get all rest day dates
        let restDates = Set(restDayDates(from: reflections))
        
        // Count only NON-REST days that have passed since program start
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
        return min(max(1, activeDaysCount), 7)
    }
    
    var isTodayComplete: Bool {
        completionRecords.contains { $0.dayNumber == currentDayNumber }
    }
    
    /// Check if today's scheduled workout is complete
    /// Note: This checks if the current day (accounting for rest day pauses) has been completed
    func isTodayComplete(reflections: [DailyReflection]) -> Bool {
        let current = currentScheduledDay(reflections: reflections)
        
        // Check if workout for current scheduled day is completed
        return completionRecords.contains { $0.dayNumber == current }
    }
    
    /// 8-day completion window constant
    static let completionWindowDays = 8

    /// Success threshold: 6/7 days = 85.7%
    static let successThreshold: Double = 6.0 / 7.0

    /// Check if we're within the grace period (8 calendar days for 7-day program)
    var isWithinGracePeriod: Bool {
        daysSinceStart < Self.completionWindowDays
    }

    /// Check if within timeframe accounting for rest days
    func isWithinTimeframe(reflections: [DailyReflection]) -> Bool {
        let restDays = countRestDaysSinceStart(reflections: reflections)
        let extendedWindow = Self.completionWindowDays + restDays
        return daysSinceStart <= extendedWindow
    }

    /// Check if the program is overdue
    var isOverdue: Bool {
        !isCompleted && !isWithinGracePeriod && daysRemaining > 0
    }

    /// Check if expired (8-day window passed without completion)
    var isExpired: Bool {
        daysSinceStart > Self.completionWindowDays && !isCompleted
    }

    /// Check if expired accounting for rest days
    func isExpired(reflections: [DailyReflection]) -> Bool {
        let restDays = countRestDaysSinceStart(reflections: reflections)
        let extendedWindow = Self.completionWindowDays + restDays
        return daysSinceStart > extendedWindow && !isCompleted
    }

    /// Success rate as a percentage (0.0 to 1.0)
    var successRate: Double {
        Double(daysCompleted) / 7.0
    }

    /// Whether the theme week met the success threshold (≥6/7 days completed)
    var isSuccessful: Bool {
        successRate >= Self.successThreshold
    }

    /// Whether the theme week should be archived (expired + meets success threshold)
    func shouldArchive(reflections: [DailyReflection]) -> Bool {
        isExpired(reflections: reflections) && isSuccessful && !isArchived
    }

    /// Whether the theme week should show restart prompt (expired + below success threshold)
    func shouldShowRestart(reflections: [DailyReflection]) -> Bool {
        isExpired(reflections: reflections) && !isSuccessful && !isArchived
    }

    /// Archive the theme week as a partial success
    func archive() {
        guard !isArchived else { return }
        isArchived = true
        archivedDate = Date()
    }
    
    // MARK: - Rest Day Helpers
    
    /// Count rest days since program start
    /// Rest days pause the program timeline - they extend the schedule without advancing the day counter
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
    
    /// Get rest day dates within program timeline (from start until today)
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
        
        // Get all completed day numbers
        let completedDayNumbers = Set(completionRecords.map { $0.dayNumber })
        
        // Count active days that have passed but weren't completed
        var missedCount = 0
        var activeDayCounter = 1  // Tracks which program day we're on (1-7)
        var currentDate = programStart
        
        while currentDate < today && activeDayCounter <= 7 {
            // Skip rest days - they don't count as missed
            if !restDates.contains(currentDate) {
                // This is an active day
                if !completedDayNumbers.contains(activeDayCounter) {
                    missedCount += 1
                }
                activeDayCounter += 1
            }
            
            // Move to next calendar day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return missedCount
    }
    
    // MARK: - Tier Statistics
    
    var seedCount: Int {
        completionRecords.filter { $0.tier == .seed }.count
    }
    
    var sproutCount: Int {
        completionRecords.filter { $0.tier == .sprout }.count
    }
    
    var bloomCount: Int {
        completionRecords.filter { $0.tier == .bloom }.count
    }
    
    var tierDistribution: (seed: Double, sprout: Double, bloom: Double) {
        guard daysCompleted > 0 else { return (0, 0, 0) }
        let total = Double(daysCompleted)
        return (
            seed: Double(seedCount) / total,
            sprout: Double(sproutCount) / total,
            bloom: Double(bloomCount) / total
        )
    }
    
    // MARK: - Day Management
    
    func completeDay(_ dayNumber: Int, tier: CompletionTier, habitID: UUID, completedAt: Date = Date()) {
        completionRecords.removeAll { $0.dayNumber == dayNumber }
        
        let record = DayCompletionRecord(
            dayNumber: dayNumber,
            tier: tier,
            habitID: habitID,
            completedAt: completedAt
        )
        
        var currentRecords = completionRecords
        currentRecords.append(record)
        completionRecords = currentRecords
        
        if daysCompleted >= 7 {
            isCompleted = true
            completedDate = Date()
        }
    }
    
    func completionRecord(for dayNumber: Int) -> DayCompletionRecord? {
        completionRecords.first { $0.dayNumber == dayNumber }
    }
    
    func isDayComplete(_ dayNumber: Int) -> Bool {
        completionRecords.contains { $0.dayNumber == dayNumber }
    }
    
    func tier(for dayNumber: Int) -> CompletionTier? {
        completionRecords.first { $0.dayNumber == dayNumber }?.tier
    }
    
    // MARK: - Pause/Resume
    
    func pause() {
        isPaused = true
        pausedDate = Date()
    }
    
    func resume() {
        isPaused = false
        pausedDate = nil
    }
    
    func markCompletionSheetViewed() {
        hasViewedCompletionSheet = true
    }
}

// MARK: - Day Completion Record

struct DayCompletionRecord: Codable, Hashable {
    let dayNumber: Int
    let tier: CompletionTier
    let habitID: UUID
    let completedAt: Date
}

// MARK: - Helper Extensions

extension ThemeWeekProgress {
    
    var adaptationMessage: String {
        if seedCount == daysCompleted && daysCompleted > 0 {
            return "You're adapting beautifully. Every Seed counts."
        } else if bloomCount >= 3 {
            return "You're thriving this week! Celebrate the Bloom days."
        } else if sproutCount == daysCompleted {
            return "Consistent and steady. This is sustainable growth."
        } else if daysCompleted >= 3 {
            return "You're finding your rhythm. Keep listening to your needs."
        } else {
            return "One day at a time. You're doing this."
        }
    }
    
    var weekBadge: String? {
        guard isCompleted else { return nil }
        
        if bloomCount >= 5 {
            return "🌳 Flourishing Week"
        } else if sproutCount >= 5 {
            return "🌿 Steady Growth"
        } else if seedCount >= 5 {
            return "🌱 Wise Adaptation"
        } else {
            return "✨ Flexible Warrior"
        }
    }
}

// MARK: - Query Helpers

extension ThemeWeekProgress {
    
    static func activeProgress(in context: ModelContext) -> [ThemeWeekProgress] {
        let descriptor = FetchDescriptor<ThemeWeekProgress>(
            predicate: #Predicate { progress in
                !progress.isCompleted && !progress.isPaused && !progress.isArchived
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    static func completedProgress(in context: ModelContext) -> [ThemeWeekProgress] {
        let descriptor = FetchDescriptor<ThemeWeekProgress>(
            predicate: #Predicate { progress in
                progress.isCompleted
            },
            sortBy: [SortDescriptor(\ThemeWeekProgress.completedDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}

