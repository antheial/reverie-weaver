//
// AchievementManager.swift
// Reverie Weaver
//

import SwiftUI
import SwiftData
import Combine

@MainActor
final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published private(set) var unlockedAchievements: Set<AchievementType> = []
    @Published private(set) var isReady = false

    private var modelContext: ModelContext?
    private let cal = Calendar.current

    private init() { loadUnlockedAchievements() }

    // MARK: - Setup for SwiftData Context
    
    func attachContext(_ context: ModelContext) {
        guard modelContext == nil else {
            return
        }
        self.modelContext = context
        isReady = true
    }

    // MARK: - Public API
    func isUnlocked(_ type: AchievementType) -> Bool {
        unlockedAchievements.contains(type)
    }

    // Number of times a repeatable achievement has been earned (≥1 if unlocked).
    func repeatCount(for type: AchievementType) -> Int {
        guard let ctx = modelContext, isReady else {
            return 0
        }
        
        do {
            let predicate = #Predicate<Achievement> { $0.type == type.rawValue }
            let desc = FetchDescriptor<Achievement>(predicate: predicate)
            let achievements = try ctx.fetch(desc)
            return achievements.first?.count ?? 0
        } catch {
            print("❌ AchievementManager.repeatCount error: \(error.localizedDescription)")
            return 0
        }
    }
    
    // Helper: Get all reflection notes (needed for journal-based achievements)
    private func fetchReflectionNotes() -> [ReflectionNote] {
        guard let ctx = modelContext, isReady else { return [] }
        do {
            let desc = FetchDescriptor<ReflectionNote>()
            return try ctx.fetch(desc)
        } catch {
            print("❌ Failed to fetch reflection notes: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Main checker (Preserved Synchronous API)
    func checkAchievements(
        completions: [HabitCompletion],
        habits: [Habit],
        miniChallengeProgress: [MiniChallengeProgress],
        themeWeekProgress: [ThemeWeekProgress] = [],
        plannedRestDays: Set<Date>
    ) {
        guard let context = modelContext, isReady else {
            print("⚠️ AchievementManager: modelContext not attached or not ready.")
            return
        }

        var newlyUnlocked: Set<AchievementType> = []
        
        // Fetch reflection notes for journal-based achievements
        let reflectionNotes = fetchReflectionNotes()

        do {
            for type in AchievementType.allCases {
                let shouldUnlock = self.shouldUnlock(
                    type,
                    completions: completions,
                    habits: habits,
                    miniChallengeProgress: miniChallengeProgress,
                    themeWeekProgress: themeWeekProgress,
                    plannedRestDays: plannedRestDays,
                    reflectionNotes: reflectionNotes
                )
                guard shouldUnlock else { continue }

                // Calculate actual count for repeatable achievements
                let actualCount = self.actualCount(
                    for: type,
                    completions: completions,
                    habits: habits,
                    themeWeekProgress: themeWeekProgress
                )
                
                let firstTime = try upsertAchievement(type, in: context, actualCount: actualCount)
                if firstTime { newlyUnlocked.insert(type) }
            }

            if !newlyUnlocked.isEmpty {
                unlockedAchievements.formUnion(newlyUnlocked)
                saveUnlockedAchievements()

                for achievement in newlyUnlocked {
                    print("🏆 Achievement unlocked: \(achievement.metadata.title)")
                }

                // Play achievement sound (use perfect day sound for perfectDay, standard for others)
                if newlyUnlocked.contains(.perfectDay) {
                    AchievementAudioManager.shared.playPerfectDay()
                } else {
                    AchievementAudioManager.shared.playStandardUnlock()
                }

                ReverieHaptics.successFeedback()

                try context.save()
            }
        } catch {
            print("❌ Failed to save achievements: \(error.localizedDescription)")
            context.rollback()
        }
    }

    // MARK: - Private Unlock Logic
    
    private func shouldUnlock(
        _ type: AchievementType,
        completions: [HabitCompletion],
        habits: [Habit],
        miniChallengeProgress: [MiniChallengeProgress],
        themeWeekProgress: [ThemeWeekProgress],
        plannedRestDays: Set<Date>,
        reflectionNotes: [ReflectionNote]
    ) -> Bool {
        switch type {
        case .firstHabit:
            return !habits.isEmpty
        case .perfectDay:
            return hasPerfectDay(completions: completions, habits: habits)
        case .streak7:
            return longestStreak(completions: completions) >= 7
        case .streak30:
            return longestStreak(completions: completions) >= 30
        case .earlyBird:
            return completions.contains { cal.component(.hour, from: $0.completedAt) < 8 }
        case .milestone10:
            return scheduledCompletions(completions).count >= 10
        case .milestone50:
            return scheduledCompletions(completions).count >= 50
        case .milestone100:
            return scheduledCompletions(completions).count >= 100
        case .weekWarrior:
            return hasWeekWarrior(completions: completions, habits: habits)
        case .monthMaster:
            return hasMonthMaster(completions: completions, habits: habits)
        case .consistency:
            return longestStreak(completions: completions) >= 21
        case .perfectMorning:
            return unlocked_perfectMorning(completions: completions)
        case .nightOwl:
            return completions.contains { self.hour($0.completedAt) >= 22 }
        case .evenSplit:
            return unlocked_evenSplit(completions: completions)
        case .p50Kickoff:
            return unlocked_p50Kickoff(habits: habits, completions: completions)
        case .p50Complete:
            return Project50ProgressManager.shared.journey.isProject50Complete
        case .p50MasteryAchieved:
            return Project50ProgressManager.shared.journey.isMasteryComplete
        case .p50RepeatChampion:
            return Project50ProgressManager.shared.journey.totalP50Completions >= 2
        case .miniChallengeFinisher:
            return miniChallengeProgress.contains { $0.isCompleted == true }
        case .miniChallenge3Complete:
            return unlocked_miniChallenge3Complete(miniChallengeProgress: miniChallengeProgress)
        case .fullProgramComplete:
            return unlocked_fullProgramComplete(miniChallengeProgress: miniChallengeProgress)
        case .allTiersExplored:
            return unlocked_allTiersExplored(miniChallengeProgress: miniChallengeProgress)
        case .gracefulReturn:
            return unlocked_gracefulReturn(completions: completions)
        case .mindfulRest:
            return unlocked_mindfulRest(restDays: plannedRestDays, completions: completions)
        case .bonusMaster:
            return unlocked_bonusMaster(completions: completions)
        case .themeWeekComplete:
            return unlocked_themeWeekComplete(themeWeekProgress: themeWeekProgress)
        case .flexibleRhythm:
            return unlocked_flexibleRhythm(themeWeekProgress: themeWeekProgress)
        case .gentleConsistency:
            return unlocked_gentleConsistency(themeWeekProgress: themeWeekProgress)
        case .allBlooms:
            return unlocked_allBlooms(themeWeekProgress: themeWeekProgress)
        case .honoringEnergy:
            return unlocked_honoringEnergy(themeWeekProgress: themeWeekProgress)
        case .connectionClarityFirstComplete:
            return unlocked_connectionClarityFirstComplete(themeWeekProgress: themeWeekProgress)
        case .connectionClarityFullReflection:
            return unlocked_connectionClarityFullReflection(themeWeekProgress: themeWeekProgress, reflectionNotes: reflectionNotes)
        case .connectionClarityRepeat:
            return unlocked_connectionClarityRepeat(themeWeekProgress: themeWeekProgress)
        }
    }
    
    // MARK: - Helper: Safe scheduled completions filter
    
    private func scheduledCompletions(_ completions: [HabitCompletion]) -> [HabitCompletion] {
        return completions.filter { $0.wasScheduledForDay ?? true }
    }
    
    private func bonusCompletions(_ completions: [HabitCompletion]) -> [HabitCompletion] {
        return completions.filter { $0.wasScheduledForDay == false }
    }
    
    // MARK: - Actual Count Calculator for Repeatable Achievements
    
    private func actualCount(
        for type: AchievementType,
        completions: [HabitCompletion],
        habits: [Habit],
        themeWeekProgress: [ThemeWeekProgress]
    ) -> Int {
        guard !type.isOneTime else { return 1 }
        
        switch type {
        case .perfectDay:
            return countPerfectDays(completions: completions, habits: habits)
        case .streak7:
            return max(1, longestStreak(completions: completions) / 7)
        case .streak30:
            return max(1, longestStreak(completions: completions) / 30)
        case .weekWarrior:
            return countPerfectWeeks(completions: completions, habits: habits)
        case .monthMaster:
            return countExcellentMonths(completions: completions, habits: habits)
        case .consistency:
            return max(1, longestStreak(completions: completions) / 21)
        case .mindfulRest:
            return 1 // Always counts as 1 when achieved
        case .gentleConsistency:
            return themeWeekProgress.filter { $0.isCompleted && $0.daysCompleted >= 7 }.count
        case .p50RepeatChampion:
            return Project50ProgressManager.shared.journey.totalP50Completions
        case .bonusMaster:
            return max(1, bonusCompletions(completions).count / 10)
        case .connectionClarityRepeat:
            return connectionClarityCompletions(themeWeekProgress: themeWeekProgress)
        default:
            return 1
        }
    }
    
    // Count distinct perfect days in history
    private func countPerfectDays(completions: [HabitCompletion], habits: [Habit]) -> Int {
        guard !habits.isEmpty else { return 0 }
        let scheduled = scheduledCompletions(completions)
        let groupedByDate = Dictionary(grouping: scheduled) {
            cal.startOfDay(for: $0.completedAt)
        }
        
        let perfectDays = groupedByDate.filter { (day, dayCompletions) in
            let activeHabitsOnDay = habits.filter { habit in
                let createdDay = cal.startOfDay(for: habit.createdAt)
                guard createdDay <= day else { return false }
                if let archivedDate = habit.archivedAt {
                    let archivedDay = cal.startOfDay(for: archivedDate)
                    guard archivedDay > day else { return false }
                }
                return habit.isScheduledOn(day)
            }
            guard !activeHabitsOnDay.isEmpty else { return false }
            let activeHabitIDs = Set(activeHabitsOnDay.map { $0.id })
            let completedIDs = Set(dayCompletions.map { $0.habitId })
            return completedIDs.intersection(activeHabitIDs).count == activeHabitIDs.count
        }
        
        return perfectDays.count
    }
    
    // Count distinct perfect weeks in history
    private func countPerfectWeeks(completions: [HabitCompletion], habits: [Habit]) -> Int {
        guard !habits.isEmpty else { return 0 }
        let scheduled = scheduledCompletions(completions)
        let groupedByWeek = Dictionary(grouping: scheduled) {
            cal.dateInterval(of: .weekOfYear, for: $0.completedAt)?.start
        }
        
        let perfectWeeks = groupedByWeek.filter { (weekStart, weekCompletions) in
            guard let weekStart = weekStart else { return false }
            var perfectDays = 0
            for dayOffset in 0..<7 {
                guard let day = cal.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
                let dayStart = cal.startOfDay(for: day)
                let scheduledHabitsOnDay = habits.filter { habit in
                    let createdDay = cal.startOfDay(for: habit.createdAt)
                    guard createdDay <= dayStart else { return false }
                    if let archivedDate = habit.archivedAt {
                        let archivedDay = cal.startOfDay(for: archivedDate)
                        guard archivedDay > dayStart else { return false }
                    }
                    return habit.isScheduledOn(dayStart)
                }
                guard !scheduledHabitsOnDay.isEmpty else { continue }
                let dayComps = weekCompletions.filter { cal.isDate($0.completedAt, inSameDayAs: dayStart) }
                let completedIDs = Set(dayComps.map { $0.habitId })
                let scheduledIDs = Set(scheduledHabitsOnDay.map { $0.id })
                if completedIDs.intersection(scheduledIDs).count == scheduledIDs.count {
                    perfectDays += 1
                }
            }
            return perfectDays == 7
        }
        
        return perfectWeeks.count
    }
    
    // Count distinct months with 75%+ completion
    private func countExcellentMonths(completions: [HabitCompletion], habits: [Habit]) -> Int {
        guard !habits.isEmpty else { return 0 }
        let scheduled = scheduledCompletions(completions)
        let groupedByMonth = Dictionary(grouping: scheduled) {
            cal.dateComponents([.year, .month], from: $0.completedAt)
        }
        
        let excellentMonths = groupedByMonth.filter { (components, monthCompletions) in
            guard let monthStart = cal.date(from: components) else { return false }
            guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return false }
            var totalRequired = 0
            var totalCompleted = 0
            for dayOffset in 0..<range.count {
                guard let day = cal.date(byAdding: .day, value: dayOffset, to: monthStart) else { continue }
                let dayStart = cal.startOfDay(for: day)
                let scheduledHabitsOnDay = habits.filter { habit in
                    let createdDay = cal.startOfDay(for: habit.createdAt)
                    guard createdDay <= dayStart else { return false }
                    if let archivedDate = habit.archivedAt {
                        let archivedDay = cal.startOfDay(for: archivedDate)
                        guard archivedDay > dayStart else { return false }
                    }
                    return habit.isScheduledOn(dayStart)
                }
                guard !scheduledHabitsOnDay.isEmpty else { continue }
                totalRequired += scheduledHabitsOnDay.count
                let dayComps = monthCompletions.filter { cal.isDate($0.completedAt, inSameDayAs: dayStart) }
                let completedIDs = Set(dayComps.map { $0.habitId })
                let scheduledIDs = Set(scheduledHabitsOnDay.map { $0.id })
                totalCompleted += completedIDs.intersection(scheduledIDs).count
            }
            guard totalRequired > 0 else { return false }
            return Double(totalCompleted) / Double(totalRequired) >= 0.75
        }
        
        return excellentMonths.count
    }

    // MARK: - Helper Calculations
    
    private func hasPerfectDay(completions: [HabitCompletion], habits: [Habit]) -> Bool {
        guard !habits.isEmpty else { return false }
        let calendar = cal
        let scheduled = scheduledCompletions(completions)
        let groupedByDate = Dictionary(grouping: scheduled) {
            calendar.startOfDay(for: $0.completedAt)
        }
        return groupedByDate.contains { (day, dayCompletions) in
            let activeHabitsOnDay = habits.filter { habit in
                let createdDay = calendar.startOfDay(for: habit.createdAt)
                guard createdDay <= day else { return false }
                if let archivedDate = habit.archivedAt {
                    let archivedDay = calendar.startOfDay(for: archivedDate)
                    guard archivedDay > day else { return false }
                }
                return habit.isScheduledOn(day)
            }
            guard !activeHabitsOnDay.isEmpty else { return false }
            let activeHabitIDs = Set(activeHabitsOnDay.map { $0.id })
            let completedIDs = Set(dayCompletions.map { $0.habitId })
            return completedIDs.intersection(activeHabitIDs).count == activeHabitIDs.count
        }
    }

    private func longestStreak(completions: [HabitCompletion]) -> Int {
        let scheduled = scheduledCompletions(completions)
        guard !scheduled.isEmpty else { return 0 }
        let sortedDays = scheduled.map { cal.startOfDay(for: $0.completedAt) }.sorted()
        var current = 1, best = 1
        for i in 1..<sortedDays.count {
            let diff = cal.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day ?? 0
            if diff == 1 { current += 1; best = max(best, current) }
            else if diff > 1 { current = 1 }
        }
        return best
    }

    private func hasWeekWarrior(completions: [HabitCompletion], habits: [Habit]) -> Bool {
        guard !habits.isEmpty else { return false }
        let scheduled = scheduledCompletions(completions)
        let groupedByWeek = Dictionary(grouping: scheduled) {
            cal.dateInterval(of: .weekOfYear, for: $0.completedAt)?.start
        }
        return groupedByWeek.contains { (weekStart, weekCompletions) in
            guard let weekStart = weekStart else { return false }
            var perfectDays = 0
            for dayOffset in 0..<7 {
                guard let day = cal.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
                let dayStart = cal.startOfDay(for: day)
                let scheduledHabitsOnDay = habits.filter { habit in
                    let createdDay = cal.startOfDay(for: habit.createdAt)
                    guard createdDay <= dayStart else { return false }
                    if let archivedDate = habit.archivedAt {
                        let archivedDay = cal.startOfDay(for: archivedDate)
                        guard archivedDay > dayStart else { return false }
                    }
                    return habit.isScheduledOn(dayStart)
                }
                guard !scheduledHabitsOnDay.isEmpty else { continue }
                let dayComps = weekCompletions.filter { cal.isDate($0.completedAt, inSameDayAs: dayStart) }
                let completedIDs = Set(dayComps.map { $0.habitId })
                let scheduledIDs = Set(scheduledHabitsOnDay.map { $0.id })
                if completedIDs.intersection(scheduledIDs).count == scheduledIDs.count {
                    perfectDays += 1
                }
            }
            return perfectDays == 7
        }
    }

    private func hasMonthMaster(completions: [HabitCompletion], habits: [Habit]) -> Bool {
        guard !habits.isEmpty else { return false }
        let scheduled = scheduledCompletions(completions)
        let groupedByMonth = Dictionary(grouping: scheduled) {
            cal.dateComponents([.year, .month], from: $0.completedAt)
        }
        return groupedByMonth.contains { (components, monthCompletions) in
            guard let monthStart = cal.date(from: components) else { return false }
            guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return false }
            var totalRequired = 0
            var totalCompleted = 0
            for dayOffset in 0..<range.count {
                guard let day = cal.date(byAdding: .day, value: dayOffset, to: monthStart) else { continue }
                let dayStart = cal.startOfDay(for: day)
                let scheduledHabitsOnDay = habits.filter { habit in
                    let createdDay = cal.startOfDay(for: habit.createdAt)
                    guard createdDay <= dayStart else { return false }
                    if let archivedDate = habit.archivedAt {
                        let archivedDay = cal.startOfDay(for: archivedDate)
                        guard archivedDay > dayStart else { return false }
                    }
                    return habit.isScheduledOn(dayStart)
                }
                guard !scheduledHabitsOnDay.isEmpty else { continue }
                totalRequired += scheduledHabitsOnDay.count
                let dayComps = monthCompletions.filter { cal.isDate($0.completedAt, inSameDayAs: dayStart) }
                let completedIDs = Set(dayComps.map { $0.habitId })
                let scheduledIDs = Set(scheduledHabitsOnDay.map { $0.id })
                totalCompleted += completedIDs.intersection(scheduledIDs).count
            }
            guard totalRequired > 0 else { return false }
            return Double(totalCompleted) / Double(totalRequired) >= 0.75
        }
    }

    private func unlocked_perfectMorning(completions: [HabitCompletion]) -> Bool {
        let today = completions.filter { cal.isDateInToday($0.completedAt) }
        let morning = today.filter { inHourRange($0.completedAt, 0, 10) }
        return Set(morning.map { $0.habitId }).count >= 2
    }

    private func unlocked_evenSplit(completions: [HabitCompletion]) -> Bool {
        let today = completions.filter { cal.isDateInToday($0.completedAt) }
        let hasMorning = today.contains { inHourRange($0.completedAt, 0, 12) }
        let hasEvening = today.contains { inHourRange($0.completedAt, 18, 24) }
        return hasMorning && hasEvening
    }

    private func unlocked_p50Kickoff(habits: [Habit], completions: [HabitCompletion]) -> Bool {
        let p50 = habits.filter { $0.programTag == "P50" }
        guard !p50.isEmpty else { return false }
        let completedIDs = Set(completions.map { $0.habitId })
        return p50.allSatisfy { completedIDs.contains($0.id) }
    }

    private func unlocked_gracefulReturn(completions: [HabitCompletion]) -> Bool {
        let sorted = completions.sorted(by: { $0.completedAt < $1.completedAt })
        guard let lastBeforeToday = sorted.last(where: { !cal.isDateInToday($0.completedAt) }) else { return false }
        let gapDays = cal.dateComponents([.day],
                                         from: cal.startOfDay(for: lastBeforeToday.completedAt),
                                         to: cal.startOfDay(for: Date())).day ?? 0
        let hasToday = sorted.contains { cal.isDateInToday($0.completedAt) }
        return gapDays >= 3 && hasToday
    }

    private func unlocked_mindfulRest(restDays: Set<Date>, completions: [HabitCompletion]) -> Bool {
        let yesterday = cal.startOfDay(for: Date().addingTimeInterval(-86400))
        guard restDays.contains(yesterday) else { return false }
        
        let todayScheduled = scheduledCompletions(completions).filter {
            cal.isDateInToday($0.completedAt)
        }
        return todayScheduled.count >= 4
    }
    
    private func unlocked_bonusMaster(completions: [HabitCompletion]) -> Bool {
        return bonusCompletions(completions).count >= 10
    }

    private func hour(_ d: Date) -> Int { cal.component(.hour, from: d) }
    private func inHourRange(_ d: Date, _ lo: Int, _ hi: Int) -> Bool {
        let h = hour(d); return h >= lo && h < hi
    }
    
    private func unlocked_themeWeekComplete(themeWeekProgress: [ThemeWeekProgress]) -> Bool {
        return themeWeekProgress.contains { $0.isCompleted && $0.daysCompleted >= 7 }
    }
    
    private func unlocked_flexibleRhythm(themeWeekProgress: [ThemeWeekProgress]) -> Bool {
        return themeWeekProgress.contains { week in
            guard week.isCompleted && week.daysCompleted >= 7 else { return false }
            let usedSeed = week.seedCount > 0
            let usedSprout = week.sproutCount > 0
            let usedBloom = week.bloomCount > 0
            return usedSeed && usedSprout && usedBloom
        }
    }
    
    private func unlocked_gentleConsistency(themeWeekProgress: [ThemeWeekProgress]) -> Bool {
        let completedCount = themeWeekProgress.filter { $0.isCompleted && $0.daysCompleted >= 7 }.count
        return completedCount >= 3
    }
    
    private func unlocked_allBlooms(themeWeekProgress: [ThemeWeekProgress]) -> Bool {
        return themeWeekProgress.contains { week in
            week.isCompleted && week.daysCompleted >= 7 && week.bloomCount == 7
        }
    }
    
    private func unlocked_honoringEnergy(themeWeekProgress: [ThemeWeekProgress]) -> Bool {
        return themeWeekProgress.contains { week in
            week.isCompleted && week.daysCompleted >= 7 && week.seedCount >= 5
        }
    }
    
    // MARK: - Connection Clarity Week Achievements
    
    private func unlocked_connectionClarityFirstComplete(themeWeekProgress: [ThemeWeekProgress]) -> Bool {
        return themeWeekProgress.contains {
            $0.isCompleted &&
            $0.daysCompleted >= 7 &&
            $0.programTag == "ConnectionClarityW1"
        }
    }
    
    private func unlocked_connectionClarityFullReflection(themeWeekProgress: [ThemeWeekProgress], reflectionNotes: [ReflectionNote]) -> Bool {
        // Find completed Connection Clarity weeks
        let completedWeeks = themeWeekProgress.filter {
            $0.isCompleted &&
            $0.daysCompleted >= 7 &&
            $0.programTag == "ConnectionClarityW1"
        }
        
        guard !completedWeeks.isEmpty else { return false }
        
        // Check if any completed week has 7 journal entries
        for week in completedWeeks {
            let sessionJournals = reflectionNotes.filter {
                $0.themeWeekSessionID == week.sessionID &&
                $0.type == "daily"
            }
            
            if sessionJournals.count >= 7 {
                return true
            }
        }
        
        return false
    }
    
    private func unlocked_connectionClarityRepeat(themeWeekProgress: [ThemeWeekProgress]) -> Bool {
        return connectionClarityCompletions(themeWeekProgress: themeWeekProgress) >= 3
    }
    
    private func connectionClarityCompletions(themeWeekProgress: [ThemeWeekProgress]) -> Int {
        return themeWeekProgress.filter {
            $0.isCompleted &&
            $0.daysCompleted >= 7 &&
            $0.programTag == "ConnectionClarityW1"
        }.count
    }
    
    // MARK: - Mini Challenge Achievements
    
    /// Check if user has completed 3 different mini challenges
    private func unlocked_miniChallenge3Complete(miniChallengeProgress: [MiniChallengeProgress]) -> Bool {
        let uniqueCompletedChallenges = Set(miniChallengeProgress.filter { $0.isCompleted }.map { $0.challengeTag })
        return uniqueCompletedChallenges.count >= 3
    }
    
    /// Check if user has completed all weeks of a multi-week program
    /// Programs are identified by a common prefix (e.g., "ConnectionClarityW1", "ConnectionClarityW2")
    private func unlocked_fullProgramComplete(miniChallengeProgress: [MiniChallengeProgress]) -> Bool {
        // Group completed challenges by their program prefix
        let completedChallenges = miniChallengeProgress.filter { $0.isCompleted }
        
        // Extract program groups (e.g., "ConnectionClarityW1" -> "ConnectionClarity")
        let programGroups = Dictionary(grouping: completedChallenges) { progress -> String in
            // Remove week suffix (e.g., "W1", "W2", etc.)
            let tag = progress.challengeTag
            if let wRange = tag.range(of: "W\\d+$", options: .regularExpression) {
                return String(tag[..<wRange.lowerBound])
            }
            return tag
        }
        
        // Check if any program has completed multiple weeks (indicating a full program)
        // A full program is typically 3+ weeks
        return programGroups.values.contains { $0.count >= 3 }
    }
    
    /// Check if user has completed challenges from all 3 main tiers
    /// Tiers: Foundation, Core, Specialized (Program tier is separate)
    /// Based on actual ChallengeTier structure in MiniChallengeData.swift
    private func unlocked_allTiersExplored(miniChallengeProgress: [MiniChallengeProgress]) -> Bool {
        let completedTags = Set(miniChallengeProgress.filter { $0.isCompleted }.map { $0.challengeTag })
        
        // TIER 1: FOUNDATION - Gentle practices to start building habits
        // Examples: CircadianReset, GratitudeGlow, BreathCalm, NatureThread, JoyScavenger, MorningArchitect
        let foundationTags = [
            "CircadianReset", "GratitudeGlow", "BreathCalm", 
            "NatureThread", "JoyScavenger", "MorningArchitect"
        ]
        let hasFoundation = completedTags.contains { tag in
            foundationTags.contains(tag)
        }
        
        // TIER 2: CORE - Essential wellbeing practices
        // Examples: EnergyRecharge, MovementMagic, ConnectionWeek, ReflectionReset, 
        //           NervousSystemReset, FocusSprint, DigitalDetox, EveningSanctuary
        let coreTags = [
            "EnergyRecharge", "MovementMagic", "ConnectionWeek", "ReflectionReset",
            "NervousSystemReset", "FocusSprint", "DigitalDetox", "EveningSanctuary"
        ]
        let hasCore = completedTags.contains { tag in
            coreTags.contains(tag)
        }
        
        // TIER 3: SPECIALIZED - Targeted challenges for specific goals
        // Examples: CreativeFlow, DopamineDetox, FinancialZen, BoundaryBootcamp, 
        //           LearningSprint, BodyTrustReset, HairGlowReset
        let specializedTags = [
            "CreativeFlow", "DopamineDetox", "FinancialZen", "BoundaryBootcamp",
            "LearningSprint", "BodyTrustReset", "HairGlowReset"
        ]
        let hasSpecialized = completedTags.contains { tag in
            specializedTags.contains(tag)
        }
        
        // Check if user has completed challenges from all 3 tiers
        if hasFoundation && hasCore && hasSpecialized {
            return true
        }
        
        // Fallback: User has completed at least 4 different unique challenges
        // (likely to span multiple tiers even if exact tags don't match)
        return completedTags.count >= 4
    }

    // MARK: - SwiftData Integration

    @discardableResult
    private func upsertAchievement(_ type: AchievementType, in ctx: ModelContext, actualCount: Int = 1) throws -> Bool {
        let predicate = #Predicate<Achievement> { $0.type == type.rawValue }
        let desc = FetchDescriptor<Achievement>(predicate: predicate)
        let achievements = try ctx.fetch(desc)

        if let existing = achievements.first {
            if !type.isOneTime {
                // For repeatable achievements, update count based on actual occurrences
                if actualCount > existing.count {
                    existing.count = actualCount
                    existing.earnedDate = Date()
                }
            }
            return false
        } else {
            let meta = type.metadata
            let a = Achievement(
                type: type.rawValue,
                title: meta.title,
                achievementDescription: meta.description,
                iconName: meta.iconName,
                count: actualCount
            )
            ctx.insert(a)
            return true
        }
    }

    // MARK: - Persistence
    
    private func loadUnlockedAchievements() {
        if let data = UserDefaults.standard.data(forKey: "unlockedAchievements"),
           let decoded = try? JSONDecoder().decode(Set<AchievementType>.self, from: data) {
            unlockedAchievements = decoded
        }
    }

    private func saveUnlockedAchievements() {
        if let encoded = try? JSONEncoder().encode(unlockedAchievements) {
            UserDefaults.standard.set(encoded, forKey: "unlockedAchievements")
        }
    }
}

// MARK: - Achievement Types

enum AchievementType: String, CaseIterable, Codable, Hashable {
    case firstHabit, perfectDay, streak7, streak30, earlyBird
    case milestone10, milestone50, milestone100
    case weekWarrior, monthMaster, consistency
    case perfectMorning, nightOwl, evenSplit
    case p50Kickoff, p50Complete, p50MasteryAchieved, p50RepeatChampion
    case miniChallengeFinisher, miniChallenge3Complete, fullProgramComplete, allTiersExplored
    case gracefulReturn, mindfulRest, bonusMaster
    case themeWeekComplete, flexibleRhythm, gentleConsistency, allBlooms, honoringEnergy
    case connectionClarityFirstComplete, connectionClarityFullReflection, connectionClarityRepeat

    var metadata: (title: String, description: String, iconName: String) {
        switch self {
        case .firstHabit: return ("First Thread", "Completed your very first habit", "sparkles")
        case .perfectDay: return ("Perfect Day", "Completed all scheduled habits in one day", "checkmark.seal.fill")
        case .streak7: return ("7-Day Streak", "Maintained a 7-day streak", "flame.fill")
        case .streak30: return ("30-Day Streak", "Maintained a 30-day streak", "flame.circle.fill")
        case .earlyBird: return ("Early Bird", "Completed a habit before 8 AM", "sunrise.fill")
        case .milestone10: return ("10 Threads", "Completed 10 scheduled habits", "10.circle.fill")
        case .milestone50: return ("50 Threads", "Completed 50 scheduled habits", "50.circle.fill")
        case .milestone100: return ("100 Threads", "Completed 100 scheduled habits", "star.circle.fill")
        case .weekWarrior: return ("Perfect Week", "Completed all scheduled habits for an entire week", "calendar.badge.checkmark")
        case .monthMaster: return ("Monthly Excellence", "Completed 75%+ of scheduled habits across a month", "crown.fill")
        case .consistency: return ("Consistency", "Maintained habits for 21 days straight", "checkmark.seal.fill")
        case .perfectMorning: return ("Perfect Morning", "Any two habits before 10am", "sunrise")
        case .nightOwl: return ("Night Owl", "Complete a habit after 10pm", "moon.stars.fill")
        case .evenSplit: return ("Even Split", "Morning + evening habit on the same day", "circle.lefthalf.filled")
        case .p50Kickoff: return ("Kickoff P50", "All 7 Project 50 habits at least once", "sparkles")
        case .p50Complete: return ("Project 50 Complete!", "Reached Day 50 with Level 2 complete", "flag.checkered.2.crossed")
        case .p50MasteryAchieved: return ("Mastery Achieved", "Completed Level 3 mastery practice", "infinity.circle.fill")
        case .p50RepeatChampion: return ("Repeat Champion", "Completed Project 50 multiple times", "trophy.fill")
        case .miniChallengeFinisher: return ("Focus Sprint Finisher", "Finish a 7-day mini challenge", "flag.checkered")
        case .miniChallenge3Complete: return ("Sprint Champion", "Complete 3 different mini challenges", "3.circle.fill")
        case .fullProgramComplete: return ("Program Graduate", "Complete all weeks of a multi-week program", "graduationcap.fill")
        case .allTiersExplored: return ("Tier Explorer", "Complete challenges from all 3 tiers", "sparkles.rectangle.stack.fill")
        case .gracefulReturn: return ("Graceful Return", "Came back after a 3-day break", "arrow.uturn.left.circle")
        case .mindfulRest: return ("Mindful Rest", "Rest day then 4+ scheduled completions next day", "bed.double")
        case .bonusMaster: return ("Bonus Master", "Complete 10 unscheduled bonus habits", "sparkles.rectangle.stack")
        case .themeWeekComplete: return ("Theme Week Complete", "Finish your first 7-day Theme Week", "moon.stars.fill")
        case .flexibleRhythm: return ("Flexible Rhythm", "Complete a Theme Week using all 3 tiers", "waveform.path")
        case .gentleConsistency: return ("Gentle Consistency", "Complete 3 different Theme Weeks", "moon.circle.fill")
        case .allBlooms: return ("All Blooms", "Complete a Theme Week with all Bloom tiers", "sparkles")
        case .honoringEnergy: return ("Honoring Energy", "Complete a Theme Week with 5+ Seed tiers", "leaf.circle")
        case .connectionClarityFirstComplete: return ("Finding Your Voice", "Complete your first Connection Clarity Week", "bubble.left.and.bubble.right.fill")
        case .connectionClarityFullReflection: return ("Deep Listener", "Journal every day of Connection Clarity Week", "text.book.closed.fill")
        case .connectionClarityRepeat: return ("Communication Champion", "Complete Connection Clarity 3+ times", "trophy.fill")
        }
    }

    var isOneTime: Bool {
        switch self {
        case .firstHabit, .milestone10, .milestone50, .milestone100,
             .earlyBird, .nightOwl, .p50Kickoff, .p50Complete, .p50MasteryAchieved, .miniChallengeFinisher,
             .miniChallenge3Complete, .fullProgramComplete, .allTiersExplored,
             .gracefulReturn, .perfectMorning, .evenSplit,
             .themeWeekComplete, .flexibleRhythm, .allBlooms, .honoringEnergy,
             .connectionClarityFirstComplete, .connectionClarityFullReflection:
            return true
        case .perfectDay, .streak7, .streak30, .weekWarrior,
             .monthMaster, .consistency, .mindfulRest, .gentleConsistency,
             .p50RepeatChampion, .bonusMaster, .connectionClarityRepeat:
            return false
        }
    }
}
