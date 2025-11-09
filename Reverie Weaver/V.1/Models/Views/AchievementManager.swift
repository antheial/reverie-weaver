//
//  AchievementManager.swift
//  Reverie Weaver
//
//  UPDATED: Pomodoro-based achievements removed
//

import SwiftUI
import SwiftData
import Combine

@MainActor
final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published private(set) var unlockedAchievements: Set<AchievementType> = []

    private var modelContext: ModelContext?
    private let cal = Calendar.current

    private init() { loadUnlockedAchievements() }

    // MARK: - Setup for SwiftData Context
    func attachContext(_ context: ModelContext) { self.modelContext = context }

    // MARK: - Public API
    func isUnlocked(_ type: AchievementType) -> Bool {
        unlockedAchievements.contains(type)
    }

    /// Number of times a repeatable achievement has been earned (≥1 if unlocked).
    func repeatCount(for type: AchievementType) -> Int {
        guard let ctx = modelContext else { return 0 }
        let predicate = #Predicate<Achievement> { $0.type == type.rawValue }
        let desc = FetchDescriptor<Achievement>(predicate: predicate)
        return (try? ctx.fetch(desc).first?.count) ?? 0
    }

    // MARK: - Main checker (no Pomodoro dependency)
    func checkAchievements(
        completions: [HabitCompletion],
        habits: [Habit],
        miniChallengeProgress: [MiniChallengeProgress],
        plannedRestDays: Set<Date>
    ) {
        guard let context = modelContext else {
            print("⚠️ AchievementManager: modelContext not attached.")
            return
        }

        var newlyUnlocked: Set<AchievementType> = []

        for type in AchievementType.allCases {
            let shouldUnlock = self.shouldUnlock(
                type,
                completions: completions,
                habits: habits,
                miniChallengeProgress: miniChallengeProgress,
                plannedRestDays: plannedRestDays
            )
            guard shouldUnlock else { continue }

            let firstTime = upsertAchievement(type, in: context)
            if firstTime { newlyUnlocked.insert(type) }
        }

        if !newlyUnlocked.isEmpty {
            unlockedAchievements.formUnion(newlyUnlocked)
            saveUnlockedAchievements()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            do { try context.save() } catch { print("❌ Failed to save achievements: \(error)") }
        }
    }

    // MARK: - Back-compat overloads
    /// Legacy call-site support (e.g., DeskView).
    /// Ignores `pomodoros` (Pomodoro achievements were removed) and
    /// forwards with safe defaults for the new parameters.
    func checkAchievements(
        completions: [HabitCompletion],
        habits: [Habit],
        pomodoros: [PomodoroSession]
    ) {
        checkAchievements(
            completions: completions,
            habits: habits,
            miniChallengeProgress: [],
            plannedRestDays: []
        )
    }

    // MARK: - Private Unlock Logic
    private func shouldUnlock(
        _ type: AchievementType,
        completions: [HabitCompletion],
        habits: [Habit],
        miniChallengeProgress: [MiniChallengeProgress],
        plannedRestDays: Set<Date>
    ) -> Bool {
        switch type {
        // Existing set
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
            return completions.count >= 10
        case .milestone50:
            return completions.count >= 50
        case .milestone100:
            return completions.count >= 100
        case .weekWarrior:
            return hasWeekWarrior(completions: completions, habits: habits)
        case .monthMaster:
            return hasMonthMaster(completions: completions, habits: habits)
        case .consistency:
            return longestStreak(completions: completions) >= 21

        // Time-of-day style
        case .perfectMorning:
            return unlocked_perfectMorning(completions: completions)
        case .nightOwl:
            return completions.contains { self.hour($0.completedAt) >= 22 }
        case .evenSplit:
            return unlocked_evenSplit(completions: completions)

        // Project-50 & Mini-Challenge
        case .p50Kickoff:
            return unlocked_p50Kickoff(habits: habits, completions: completions)
        case .miniChallengeFinisher:
            return miniChallengeProgress.contains { $0.isCompleted == true }

        // Well-being / Comeback
        case .gracefulReturn:
            return unlocked_gracefulReturn(completions: completions)
        case .mindfulRest:
            return unlocked_mindfulRest(restDays: plannedRestDays, completions: completions)
        }
    }

    // MARK: - Helper Calculations
    private func hasPerfectDay(completions: [HabitCompletion], habits: [Habit]) -> Bool {
        guard !habits.isEmpty else { return false }
        let groupedByDate = Dictionary(grouping: completions) { cal.startOfDay(for: $0.completedAt) }
        return groupedByDate.values.contains { $0.count >= habits.count }
    }

    private func longestStreak(completions: [HabitCompletion]) -> Int {
        guard !completions.isEmpty else { return 0 }
        let sortedDays = completions.map { cal.startOfDay(for: $0.completedAt) }.sorted()
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
        let grouped = Dictionary(grouping: completions) { cal.component(.weekOfYear, from: $0.completedAt) }
        return grouped.values.contains { $0.count >= habits.count * 7 }
    }

    private func hasMonthMaster(completions: [HabitCompletion], habits: [Habit]) -> Bool {
        guard !habits.isEmpty else { return false }
        let grouped = Dictionary(grouping: completions) { cal.component(.month, from: $0.completedAt) }
        return grouped.values.contains { $0.count >= Int(Double(habits.count * 30) * 0.75) }
    }

    // MARK: - Predicates (no Pomodoro)
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
        let todayCount = completions.filter { cal.isDateInToday($0.completedAt) }.count
        return todayCount >= 4
    }

    // Hour helpers
    private func hour(_ d: Date) -> Int { cal.component(.hour, from: d) }
    private func inHourRange(_ d: Date, _ lo: Int, _ hi: Int) -> Bool {
        let h = hour(d); return h >= lo && h < hi
    }

    // MARK: - SwiftData Integration (Upsert with repeatables)
    @discardableResult
    private func upsertAchievement(_ type: AchievementType, in ctx: ModelContext) -> Bool {
        let predicate = #Predicate<Achievement> { $0.type == type.rawValue }
        let desc = FetchDescriptor<Achievement>(predicate: predicate)

        if let existing = (try? ctx.fetch(desc))?.first {
            guard !type.isOneTime else { return false }
            existing.count += 1
            return false
        } else {
            let meta = type.metadata
            let a = Achievement(
                type: type.rawValue,
                title: meta.title,
                achievementDescription: meta.description,
                iconName: meta.iconName,
                count: 1
            )
            ctx.insert(a)
            return true
        }
    }

    // MARK: - Persistence (UserDefaults)
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

// MARK: - Achievement Types (Pomodoro cases removed)

enum AchievementType: String, CaseIterable, Codable, Hashable {
    case firstHabit        = "first_habit"
    case perfectDay        = "perfect_day"
    case streak7           = "streak_7"
    case streak30          = "streak_30"
    case earlyBird         = "early_bird"
    case milestone10       = "milestone_10"
    case milestone50       = "milestone_50"
    case milestone100      = "milestone_100"
    case weekWarrior       = "week_warrior"
    case monthMaster       = "month_master"
    case consistency       = "consistency"

    // Time-of-Day style
    case perfectMorning
    case nightOwl
    case evenSplit

    // Project-50 & Mini-Challenge
    case p50Kickoff
    case miniChallengeFinisher

    // Well-being / Comeback
    case gracefulReturn
    case mindfulRest

    var metadata: (title: String, description: String, iconName: String) {
        switch self {
        case .firstHabit:        return ("First Thread", "Completed your very first habit", "sparkles")
        case .perfectDay:        return ("Perfect Day", "Completed all habits in one day", "checkmark.seal.fill")
        case .streak7:           return ("7-Day Streak", "Maintained a 7-day streak", "flame.fill")
        case .streak30:          return ("30-Day Streak", "Maintained a 30-day streak", "flame.circle.fill")
        case .earlyBird:         return ("Early Bird", "Completed a habit before 8 AM", "sunrise.fill")
        case .milestone10:       return ("10 Threads", "Completed 10 habits", "10.circle.fill")
        case .milestone50:       return ("50 Threads", "Completed 50 habits", "50.circle.fill")
        case .milestone100:      return ("100 Threads", "Completed 100 habits", "100.circle.fill")
        case .weekWarrior:       return ("Perfect Week", "Completed all habits for an entire week", "calendar.badge.checkmark")
        case .monthMaster:       return ("Monthly Excellence", "Completed 75%+ of habits across a month", "crown.fill")
        case .consistency:       return ("Consistency", "Maintained habits for 21 days straight", "checkmark.seal.fill")

        case .perfectMorning:        return ("Perfect Morning", "Any two habits before 10am", "sunrise")
        case .nightOwl:              return ("Night Owl", "Complete a habit after 10pm", "moon.stars.fill")
        case .evenSplit:             return ("Even Split", "Morning + evening habit on the same day", "circle.lefthalf.filled")

        case .p50Kickoff:            return ("Kickoff P50", "All 7 Project 50 habits at least once", "sparkles")
        case .miniChallengeFinisher: return ("Focus Sprint Finisher", "Finish a 7-day mini challenge", "flag.checkered")

        case .gracefulReturn:        return ("Graceful Return", "Came back after a 3-day break", "arrow.uturn.left.circle")
        case .mindfulRest:           return ("Mindful Rest", "Rest day then 4+ completions next day", "bed.double")
        }
    }

    var isOneTime: Bool {
        switch self {
        case .nightOwl, .p50Kickoff, .miniChallengeFinisher, .gracefulReturn:
            return true
        default:
            return false
        }
    }
}
