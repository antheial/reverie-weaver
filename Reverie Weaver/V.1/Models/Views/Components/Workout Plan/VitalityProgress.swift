//
//  VitalityProgress.swift
//  Reverie Weaver
//
//  - Week 5-8 repeat cycle support
//  - Per-week tier progression tracking
//  - RPE logging in completion records
//  - Cycle-aware statistics
//

import SwiftData
import Foundation

@Model
final class VitalityProgress {
    var id: UUID
    var programID: String       // e.g., "vitality-arc-8week" or "fei-strength-arc-4week"
    var programTag: String      // e.g., "VA-vitality-arc-8week" (for habit linking)
    var programTitle: String    // For display purposes
    var startDate: Date
    var lastCompletedDate: Date?
    
    var completionRecords: [VitalityCompletionRecord]
    var isCompleted: Bool
    var completedDate: Date?
    var isPaused: Bool
    var pausedDate: Date?
    
    // Cycle support for Week 5-8 repeat (Fei program)
    // Cycle 1 = Days 1-28 (Weeks 1-4)
    // Cycle 2 = Days 29-56 (Weeks 5-8, progressive block)
    var currentCycle: Int
    var hasOfferedCycleExtension: Bool
    
    init(
        programID: String,
        programTag: String? = nil,
        programTitle: String? = nil,
        startDate: Date = Date()
    ) {
        self.id = UUID()
        self.programID = programID
        self.programTag = programTag ?? "VA-\(programID)"
        self.programTitle = programTitle ?? (programID == "fei-strength-arc-4week" ? "Fei Strength Arc" : "The Vitality Arc")
        self.startDate = startDate
        self.completionRecords = []
        self.isCompleted = false
        self.completedDate = nil
        self.isPaused = false
        self.pausedDate = nil
        self.currentCycle = 1
        self.hasOfferedCycleExtension = false
    }
    
    // MARK: - Computed Stats
    
    var totalProgramDays: Int {
        if programID == "fei-strength-arc-4week" {
            return currentCycle == 2 ? 56 : 28
        }
        return 56
    }
    
    var daysPerCycle: Int {
        programID == "fei-strength-arc-4week" ? 28 : 56
    }
    
    var isExtendedFeiProgram: Bool {
        programID == "fei-strength-arc-4week" && currentCycle == 2
    }
    
    var canExtendToNextCycle: Bool {
        programID == "fei-strength-arc-4week" &&
        currentCycle == 1 &&
        daysCompleted >= 28 &&
        !hasOfferedCycleExtension &&
        !isCompleted
    }
    
    /// Current day number (calendar-based, doesn't account for rest days)
    var currentDayNumber: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(max(1, days + 1), totalProgramDays)
    }
    
    /// The current scheduled day number, accounting for rest days
    /// This represents the NEXT day that needs to be completed
    /// Rest days PAUSE the calendar - they extend the timeline without advancing the day counter
    /// Skipped/missed days still advance the calendar (and count as missed)
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
        return min(max(1, activeDaysCount), totalProgramDays)
    }
    
    var daysCompleted: Int {
        completionRecords.count
    }
    
    var daysRemaining: Int {
        max(0, totalProgramDays - daysCompleted)
    }
    
    var progressPercent: Double {
        Double(daysCompleted) / Double(totalProgramDays)
    }
    
    /// Progress percentage accounting for rest days
    /// Rest days PAUSE the program - they do NOT extend the program length
    /// Progress is always calculated as daysCompleted / totalProgramDays (56 or 28)
    func progressPercent(reflections: [DailyReflection]) -> Double {
        // Rest days only pause the calendar and extend the deadline
        // They do NOT increase the total program days
        guard totalProgramDays > 0 else { return 0 }
        return Double(daysCompleted) / Double(totalProgramDays)
    }
    
    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }
    
    var isTodayComplete: Bool {
        completionRecords.contains { $0.dayNumber == currentDayNumber }
    }
    
    /// The most recently completed day number (useful for RPE tracking)
    var lastCompletedDayNumber: Int? {
        completionRecords
            .sorted(by: { $0.completedAt > $1.completedAt })
            .first?.dayNumber
    }
    
    /// Check if today's scheduled workout is complete
    /// Note: This checks if the current day (accounting for rest day pauses) has been completed
    /// Rest days do NOT count as complete - they pause the program
    func isTodayComplete(reflections: [DailyReflection]) -> Bool {
        let current = currentScheduledDay(reflections: reflections)
        
        // Check if workout for current scheduled day is completed
        return completionRecords.contains { $0.dayNumber == current }
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
        var activeDayCounter = 1  // Tracks which program day we're on (1-totalProgramDays)
        var currentDate = programStart
        
        while currentDate < today && activeDayCounter <= totalProgramDays {
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
    
    // MARK: - Per-Week Tier Progression
    
    func tierCounts(forWeek week: Int) -> (seed: Int, sprout: Int, bloom: Int) {
        let startDay = (week - 1) * 7 + 1
        let endDay = week * 7
        
        let weekRecords = completionRecords.filter { $0.dayNumber >= startDay && $0.dayNumber <= endDay }
        
        return (
            seed: weekRecords.filter { $0.tier == .seed }.count,
            sprout: weekRecords.filter { $0.tier == .sprout }.count,
            bloom: weekRecords.filter { $0.tier == .bloom }.count
        )
    }
    
    func dominantTier(forWeek week: Int) -> CompletionTier? {
        let counts = tierCounts(forWeek: week)
        let total = counts.seed + counts.sprout + counts.bloom
        guard total > 0 else { return nil }
        
        if counts.bloom >= counts.sprout && counts.bloom >= counts.seed {
            return .bloom
        } else if counts.sprout >= counts.seed {
            return .sprout
        } else {
            return .seed
        }
    }
    
    var weeklyTierProgression: [(week: Int, tier: CompletionTier?)] {
        let totalWeeks = (totalProgramDays + 6) / 7
        return (1...totalWeeks).map { week in
            (week: week, tier: dominantTier(forWeek: week))
        }
    }
    
    var isShowingTierProgression: Bool {
        let progression = weeklyTierProgression.compactMap { $0.tier }
        guard progression.count >= 2 else { return false }
        
        var lastTierValue = 0
        var hasProgressed = false
        
        for tier in progression {
            let value = tier == .seed ? 1 : (tier == .sprout ? 2 : 3)
            if value > lastTierValue && lastTierValue > 0 {
                hasProgressed = true
            }
            lastTierValue = value
        }
        
        return hasProgressed
    }
    
    // MARK: - RPE Statistics
    
    var averageRPE: Double? {
        let rpeValues = completionRecords.compactMap { $0.actualRPE }
        guard !rpeValues.isEmpty else { return nil }
        return Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
    }
    
    func averageRPE(forWeek week: Int) -> Double? {
        let startDay = (week - 1) * 7 + 1
        let endDay = week * 7
        
        let rpeValues = completionRecords
            .filter { $0.dayNumber >= startDay && $0.dayNumber <= endDay }
            .compactMap { $0.actualRPE }
        
        guard !rpeValues.isEmpty else { return nil }
        return Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
    }
    
    var rpeTrend: Double? {
        let recentRecords = completionRecords
            .sorted { $0.dayNumber < $1.dayNumber }
            .suffix(14)
            .compactMap { $0.actualRPE }
        
        guard recentRecords.count >= 4 else { return nil }
        
        let firstHalf = Array(recentRecords.prefix(recentRecords.count / 2))
        let secondHalf = Array(recentRecords.suffix(recentRecords.count / 2))
        
        let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        
        return secondAvg - firstAvg
    }
    
    // MARK: - Vitality Score
    
    var vitalityScore: Int {
        let baseScore = daysCompleted * 10
        let seedBonus = seedCount * 2
        let sproutBonus = sproutCount * 5
        let bloomBonus = bloomCount * 8
        
        let progressionBonus = isShowingTierProgression ? 50 : 0
        
        let rpeLoggingBonus = completionRecords.filter { $0.actualRPE != nil }.count * 2
        
        return baseScore + seedBonus + sproutBonus + bloomBonus + progressionBonus + rpeLoggingBonus
    }
    
    // MARK: - Day Management
    
    /// Complete a day with the given tier
    /// Returns the day number that was completed (useful for RPE tracking)
    @discardableResult
    func completeDay(_ dayNumber: Int, tier: CompletionTier, habitID: UUID? = nil, actualRPE: Int? = nil, completedAt: Date = Date()) -> Int {
        completionRecords.removeAll { $0.dayNumber == dayNumber }
        
        let record = VitalityCompletionRecord(
            dayNumber: dayNumber,
            tier: tier,
            habitID: habitID,
            actualRPE: actualRPE,
            completedAt: completedAt
        )
        
        var currentRecords = completionRecords
        currentRecords.append(record)
        completionRecords = currentRecords
        
        lastCompletedDate = completedAt
        
        if daysCompleted >= totalProgramDays {
            isCompleted = true
            completedDate = Date()
        }
        
        return dayNumber  // Return the day that was just completed
    }
    
    func updateRPE(forDay dayNumber: Int, rpe: Int) {
        guard let index = completionRecords.firstIndex(where: { $0.dayNumber == dayNumber }) else {
            #if DEBUG
            print("⚠️ [VitalityProgress] Cannot update RPE: Day \(dayNumber) not found in completion records")
            print("   Available days: \(completionRecords.map { $0.dayNumber }.sorted())")
            #endif
            return
        }
        
        let existingRecord = completionRecords[index]
        let updatedRecord = VitalityCompletionRecord(
            dayNumber: existingRecord.dayNumber,
            tier: existingRecord.tier,
            habitID: existingRecord.habitID,
            actualRPE: rpe,
            completedAt: existingRecord.completedAt
        )
        
        var currentRecords = completionRecords
        currentRecords[index] = updatedRecord
        completionRecords = currentRecords
        
        #if DEBUG
        print("✅ [VitalityProgress] Updated RPE for Day \(dayNumber): \(rpe)")
        #endif
    }
    
    func isDayComplete(_ dayNumber: Int) -> Bool {
        completionRecords.contains { $0.dayNumber == dayNumber }
    }
    
    func getCompletedTier(for dayNumber: Int) -> CompletionTier? {
        completionRecords.first { $0.dayNumber == dayNumber }?.tier
    }
    
    func completionRecord(for dayNumber: Int) -> VitalityCompletionRecord? {
        completionRecords.first { $0.dayNumber == dayNumber }
    }
    
    // MARK: - Cycle Extension (Week 5-8)
    
    func extendToNextCycle() {
        guard programID == "fei-strength-arc-4week" && currentCycle == 1 else { return }
        currentCycle = 2
        hasOfferedCycleExtension = true
        isCompleted = false
        completedDate = nil
    }
    
    func declineExtension() {
        hasOfferedCycleExtension = true
        isCompleted = true
        completedDate = Date()
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
}

// MARK: - Completion Record

struct VitalityCompletionRecord: Codable, Hashable {
    let dayNumber: Int
    let tier: CompletionTier
    let habitID: UUID?
    let actualRPE: Int?
    let completedAt: Date
    
    init(dayNumber: Int, tier: CompletionTier, habitID: UUID? = nil, actualRPE: Int? = nil, completedAt: Date = Date()) {
        self.dayNumber = dayNumber
        self.tier = tier
        self.habitID = habitID
        self.actualRPE = actualRPE
        self.completedAt = completedAt
    }
    
    var expectedRPERange: ClosedRange<Int> {
        switch tier {
        case .seed: return 3...5
        case .sprout: return 5...7
        case .bloom: return 7...9
        }
    }
    
    var rpeMatchesTier: Bool? {
        guard let rpe = actualRPE else { return nil }
        return expectedRPERange.contains(rpe)
    }
}

// MARK: - Helper Extensions

extension VitalityProgress {
    
    var adaptationMessage: String {
        if isShowingTierProgression {
            return "You're leveling up! Your tier progression shows real growth."
        } else if seedCount == daysCompleted && daysCompleted > 0 {
            return "You're adapting beautifully. Every Seed counts."
        } else if bloomCount >= 5 {
            return "You're thriving! Celebrate the Bloom days."
        } else if sproutCount == daysCompleted {
            return "Consistent and steady. This is sustainable growth."
        } else if daysCompleted >= 7 {
            return "You're finding your rhythm. Keep listening to your body."
        } else {
            return "One day at a time. You're doing this."
        }
    }
    
    var completionBadge: String? {
        guard isCompleted else { return nil }
        
        let bloomRatio = Double(bloomCount) / Double(totalProgramDays)
        let sproutRatio = Double(sproutCount) / Double(totalProgramDays)
        let seedRatio = Double(seedCount) / Double(totalProgramDays)
        
        if isShowingTierProgression {
            return "Progressive Warrior"
        } else if bloomRatio >= 0.5 {
            return "Flourishing Arc"
        } else if sproutRatio >= 0.5 {
            return "Steady Growth"
        } else if seedRatio >= 0.5 {
            return "Wise Adaptation"
        } else {
            return "Flexible Warrior"
        }
    }
    
    var currentPhase: VitalityPhase {
        switch currentDayNumber {
        case 1...14: return .activation
        case 15...28: return .endurance
        case 29...42: return .strength
        default: return .integration
        }
    }
    
    /// Current week number (1-4 for Fei cycle 1, 1-8 for Fei cycle 2 or Vitality)
    var currentWeek: Int {
        (currentDayNumber - 1) / 7 + 1
    }
    
    var displayWeek: Int {
        if programID == "fei-strength-arc-4week" && currentCycle == 2 {
            // For cycle 2, days 29-56 map to weeks 5-8
            let dayInCycle = currentDayNumber - 28  // Days 1-28 of cycle 2
            return ((dayInCycle - 1) / 7 + 1) + 4   // Add 4 to get weeks 5-8
        }
        return currentWeek
    }
}

// MARK: - Query Helpers

extension VitalityProgress {
    
    static func activeProgress(in context: ModelContext) -> [VitalityProgress] {
        let descriptor = FetchDescriptor<VitalityProgress>(
            predicate: #Predicate { progress in
                !progress.isCompleted && !progress.isPaused
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    static func completedProgress(in context: ModelContext) -> [VitalityProgress] {
        let descriptor = FetchDescriptor<VitalityProgress>(
            predicate: #Predicate { progress in
                progress.isCompleted
            },
            sortBy: [SortDescriptor(\VitalityProgress.completedDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    static func progress(for programID: String, in context: ModelContext) -> VitalityProgress? {
        let descriptor = FetchDescriptor<VitalityProgress>(
            predicate: #Predicate { $0.programID == programID && !$0.isCompleted }
        )
        return try? context.fetch(descriptor).first
    }
}
