//
// Project50ProgressManager.swift
// Reverie Weaver
//
// Created Oct 2025
// FULLY UPDATED with Mini Challenge Progress Tracking
//
// Central brain for Project 50 progression:
// - Journey persistence
// - Day + 75% + confirm unlock logic (one-time prompt)
// - Insert/remove habits for each level (injectable hooks)
// - Mini-challenge (7 days) lifecycle with progress tracking
// - % completion per level via injectable provider
// - SwiftData integration for challenge progress
//

import SwiftUI
import SwiftData
import Combine
import Foundation

// MARK: - Journey Model

struct Project50Journey: Codable, Equatable {
    var startDate: Date? = nil
    var currentLevel: Int = 1
    var unlockedLevels: Set<Int> = [1] // Level 1 is available immediately after start
    var declinedUnlockLevels: Set<Int> = [] // If user declines, we never re-prompt
    var completionByLevel: [Int: Double] = [:] // Cache for UI; recomputed on refresh
    var levelStartDates: [Int: Date] = [:] // When each level was inserted into Desk
    var lastPromptedLevel: Int? = nil // Avoid duplicate prompts within a session

    // Mini challenge - String to match MiniChallenge.id type
    var activeMiniChallengeID: String? = nil
    var miniChallengeStartDate: Date? = nil
}

// MARK: - Manager

@MainActor
final class Project50ProgressManager: ObservableObject {

    // Singleton (feel free to switch to DI if you prefer)
    static let shared = Project50ProgressManager()

    // MARK: Persistence
    // Replaced @AppStorage with explicit UserDefaults for reliability in a class
    private let storageKey = "project50JourneyData"
    private let defaults: UserDefaults = .standard

    @Published private(set) var journey: Project50Journey = Project50Journey() {
        didSet { persist() }
    }

    // MARK: UI Flags for Levels Screen
    @Published var unlockReadyLevel: Int? = nil
    @Published var showUnlockModal: Bool = false

    // MARK: Constants
    private let level2DayThreshold = 21
    private let level3DayThreshold = 50
    private let completionThreshold: Double = 0.75

    // MARK: Injectable Hooks (Desk + Stats)
    // Insert the habits for a given Project 50 level into Desk.
    // Caller MUST ensure these are tagged: program:"project50", level:n
    var insertLevelHabits: ((_ level: Int) -> Void)?

    // Remove (archive) all Project 50 habits for a given level from Desk.
    var removeLevelHabits: ((_ level: Int) -> Void)?

    // Remove (archive) ALL Project 50 + Mini Challenge habits from Desk (used by reset).
    var removeAllProject50AndMiniHabits: (() -> Void)?

    // Completion provider: returns numerator/denominator context for a level.
    // Return tuple:
    // - activeHabitsCount: count of active P50 habits in Desk for this level
    // - totalCompletions: sum of daily check-ins for those habits across the window
    // - daysSinceLevelStartCapped: number of days in scope (already capped by provider)
    //
    // IMPORTANT: This provider should ONLY count habits tagged program:"project50" and level == n.
    var completionProvider: ((_ level: Int, _ levelStartDate: Date?) -> (activeHabitsCount: Int, totalCompletions: Int, daysSinceLevelStartCapped: Int))?

    // MARK: Init
    private init() { restore() }

    // MARK: - Public: Journey Lifecycle

    func startJourney() {
        // Start if not already started
        guard journey.startDate == nil else { return }
        let now = Date()
        journey.startDate = now
        journey.currentLevel = 1
        journey.unlockedLevels = [1]
        journey.declinedUnlockLevels = []
        journey.levelStartDates[1] = now
        journey.lastPromptedLevel = nil
        journey.activeMiniChallengeID = nil
        journey.miniChallengeStartDate = nil

        // Insert Level 1 habits
        insertLevelHabits?(1)
        ReverieHaptics.successFeedback()
        persist()
    }

    func resetJourney() {
        // Soft-remove all related habits from Desk
        removeAllProject50AndMiniHabits?()

        // Clear state
        journey = Project50Journey()
        unlockReadyLevel = nil
        showUnlockModal = false
        ReverieHaptics.lightFeedback()
    }

    // Call on Levels view appear / app active / after Desk sync
    func refreshEligibility() {
        // Recompute completion caches for levels that have started
        for level in [1, 2, 3] {
            journey.completionByLevel[level] = computeCompletion(level: level)
        }

        // Determine next candidate
        if let candidate = nextUnlockCandidate() {
            // If not previously declined and not already unlocked, present a single prompt
            if !journey.declinedUnlockLevels.contains(candidate) &&
                !journey.unlockedLevels.contains(candidate) {
                unlockReadyLevel = candidate
                showUnlockModal = true
                journey.lastPromptedLevel = candidate
            } else {
                unlockReadyLevel = nil
                showUnlockModal = false
            }
        } else {
            unlockReadyLevel = nil
            showUnlockModal = false
        }
    }

    // MARK: - Public: User Responses to Unlock

    func confirmUnlock(level: Int) {
        guard isEligibleToUnlock(level: level) else {
            // Defensive: silently ignore if somehow called too early
            showUnlockModal = false
            return
        }

        // Insert new level habits
        insertLevelHabits?(level)

        // Remove previous level habits (your spec)
        let previousLevel = level - 1
        if previousLevel >= 1 {
            removeLevelHabits?(previousLevel)
        }

        // Update journey state
        journey.unlockedLevels.insert(level)
        journey.currentLevel = level
        journey.levelStartDates[level] = Date()

        // Dismiss modal & feedback
        showUnlockModal = false
        unlockReadyLevel = nil
        ReverieHaptics.successFeedback()
        persist()
    }

    func declineUnlock(level: Int) {
        journey.declinedUnlockLevels.insert(level)
        showUnlockModal = false
        unlockReadyLevel = nil
        ReverieHaptics.lightFeedback()
        persist()
    }

    // MARK: - Public: Mini Challenge (Legacy)

    func addMiniChallenge(id: String) {
        journey.activeMiniChallengeID = id
        journey.miniChallengeStartDate = Date()
        ReverieHaptics.lightFeedback()
        persist()
    }

    func completeMiniChallenge() {
        // Caller should archive/remove challenge habits by tag; we just clear the state
        journey.activeMiniChallengeID = nil
        journey.miniChallengeStartDate = nil
        ReverieHaptics.successFeedback()
        persist()
    }

    // MARK: - Helpers

    var daysSinceStart: Int {
        guard let start = journey.startDate else { return 0 }
        return Calendar.current.dateComponents([ .day ], from: start, to: Date()).day ?? 0
    }

    func daysSinceLevelStart(_ level: Int) -> Int {
        guard let start = journey.levelStartDates[level] else { return 0 }
        return Calendar.current.dateComponents([ .day ], from: start, to: Date()).day ?? 0
    }

    func completion(for level: Int) -> Double {
        return journey.completionByLevel[level] ?? 0.0
    }

    // MARK: - Private: Eligibility & Completion

    private func nextUnlockCandidate() -> Int? {
        // Level 2 first, then 3
        if isEligibleToUnlock(level: 2) { return 2 }
        if isEligibleToUnlock(level: 3) { return 3 }
        return nil
    }

    private func isEligibleToUnlock(level: Int) -> Bool {
        guard journey.startDate != nil else { return false }

        switch level {
        case 2:
            // Day threshold + Level 1 completion >= 75%
            return daysSinceStart >= level2DayThreshold &&
                (journey.completionByLevel[1] ?? computeCompletion(level: 1)) >= completionThreshold

        case 3:
            // Day threshold + Level 2 completion >= 75%
            return daysSinceStart >= level3DayThreshold &&
                (journey.completionByLevel[2] ?? computeCompletion(level: 2)) >= completionThreshold

        default:
            return false
        }
    }

    private func computeCompletion(level: Int) -> Double {
        // If the level hasn't started (no insertion date), completion is 0.
        guard journey.levelStartDates[level] != nil else { return 0.0 }

        // Ask the provider for numbers that already:
        // - filter only program:"project50" & level:n
        // - cap the days window as you prefer (e.g., 21 for L1/L2, 50 for L3)
        guard let tuple = completionProvider?(level, journey.levelStartDates[level]) else {
            return 0.0
        }

        let denominator = max(tuple.activeHabitsCount * max(1, tuple.daysSinceLevelStartCapped), 1)
        let result = Double(tuple.totalCompletions) / Double(denominator)
        return min(max(result, 0.0), 1.0)
    }

    // MARK: - Persistence

    private func persist() {
        do {
            let data = try JSONEncoder().encode(journey)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Fail silently; you may add logging here if desired
        }
    }

    private func restore() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode(Project50Journey.self, from: data)
            journey = decoded
        } catch {
            // If decoding fails, start fresh
            journey = Project50Journey()
        }
    }
}

// MARK: - Convenience Event Hooks

extension Project50ProgressManager {
    /// Call when the app becomes active or the Levels page appears.
    func onAppearOrActive() {
        refreshEligibility()
    }

    /// Call after Desk finishes recording a completion/toggle for any P50 habit.
    func onDeskCompletionDidUpdate() {
        refreshEligibility()
    }
}

// MARK: - Mini Challenge Progress Tracking Extensions

extension Project50ProgressManager {

    // MARK: - Get Active Mini Challenge Progress

    /// Get the progress tracker for the currently active mini challenge
    func getActiveMiniChallengeProgress(modelContext: ModelContext) -> MiniChallengeProgress? {
        // Create descriptor
        let descriptor = FetchDescriptor<MiniChallengeProgress>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        // Fetch all and filter in Swift
        guard let allProgress = try? modelContext.fetch(descriptor) else {
            return nil
        }

        // Return the most recent non-completed progress
        // (assumes only one active challenge at a time)
        return allProgress.first { progress in
            !progress.isCompleted
        }
    }

    // MARK: - Check Daily Mini Challenge Completion

    /// Check if all mini challenge habits completed today, and update progress if so
    func checkMiniChallengeCompletion(
        modelContext: ModelContext,
        habits: [Habit],
        completions: [HabitCompletion]
    ) {
        guard let challengeID = journey.activeMiniChallengeID,
              let challengeStartDate = journey.miniChallengeStartDate else {
            return
        }

        // Get challenge habits (those with programTag starting with "C7-")
        let challengeHabits = habits.filter { habit in
            guard let tag = habit.programTag else { return false }
            return tag.starts(with: "C7-")
        }

        // Need at least one challenge habit
        guard !challengeHabits.isEmpty else { return }

        // Extract the challenge tag from habit
        guard let firstHabit = challengeHabits.first,
              let programTag = firstHabit.programTag,
              programTag.starts(with: "C7-") else { return }

        let challengeTag = String(programTag.dropFirst(3)) // Remove "C7-" prefix

        // Get today's completions
        let today = Date()
        let todayCompletions = completions.filter { completion in
            Calendar.current.isDate(completion.completedAt, inSameDayAs: today)
        }

        // Check if ALL challenge habits completed today
        let allCompleted = challengeHabits.allSatisfy { habit in
            todayCompletions.contains { $0.habitId == habit.id }
        }

        // Only proceed if all habits are complete
        guard allCompleted else { return }

        // Try to get existing progress tracker
        let descriptor = FetchDescriptor<MiniChallengeProgress>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let allProgress = try? modelContext.fetch(descriptor) else {
            return
        }

        // Match by challengeTag instead of challengeID
        let existingProgress = allProgress.first { progress in
            progress.challengeTag == challengeTag && !progress.isCompleted
        }

        if let progress = existingProgress {
            // ✅ MIGRATION: Backfill requiredHabitIDs for progress trackers created before this field was added
            // TODO: This migration can be removed after all users have updated (e.g., after version 2.0)
            if progress.requiredHabitIDs.isEmpty {
                progress.requiredHabitIDs = challengeHabits.map { $0.id }
            }

            // Update existing progress
            if !progress.isTodayComplete {
                // ✅ NEW: Use verification method instead of direct call
                progress.checkAndUpdateProgress(completions: completions)

                do {
                    try modelContext.save()

                    // Post notification if challenge complete
                    if progress.isCompleted {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("MiniChallengeCompleted"),
                            object: progress
                        )
                        ReverieHaptics.successFeedback()
                    } else {
                        ReverieHaptics.lightFeedback()
                    }
                } catch {
                    print("Failed to save mini challenge progress: \(error)")
                }
            }
        } else {
            // Create new progress tracker
            let challengeTitle = "Mini Challenge" // Default title

            // ✅ AFTER:
            let habitIDs = challengeHabits.map { $0.id }
            let newProgress = MiniChallengeProgress(
                challengeID: challengeID,
                challengeTag: challengeTag,
                challengeTitle: challengeTitle,
                requiredHabitIDs: habitIDs,  // ← NEW!
                startDate: challengeStartDate
            )
            newProgress.checkAndUpdateProgress(completions: completions)

            modelContext.insert(newProgress)

            do {
                try modelContext.save()
                ReverieHaptics.lightFeedback()
            } catch {
                print("Failed to create mini challenge progress: \(error)")
            }
        }
    }

    // MARK: - Get All Challenge Progress

    /// Get all mini challenge progress records (for history view)
    func getAllMiniChallengeProgress(modelContext: ModelContext) -> [MiniChallengeProgress] {
        let descriptor = FetchDescriptor<MiniChallengeProgress>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Start Mini Challenge with Progress Tracking

    /// Enhanced version that creates progress tracker when starting challenge
    /// - Parameters:
    ///   - challenge: The mini challenge to start
    ///   - modelContext: SwiftData model context
    ///   - habitIDs: Array of habit UUIDs that are part of this challenge (REQUIRED for progress tracking)
    func startMiniChallenge(
        challenge: MiniChallenge,
        modelContext: ModelContext,
        habitIDs: [UUID]
    ) {
        // Set active challenge - challenge.id should be a String
        journey.activeMiniChallengeID = challenge.id
        journey.miniChallengeStartDate = Date()

        // Create progress tracker with habit IDs
        let progress = MiniChallengeProgress(
            challengeID: challenge.id,
            challengeTag: challenge.tag,
            challengeTitle: challenge.title,
            requiredHabitIDs: habitIDs,
            startDate: Date()
        )

        modelContext.insert(progress)

        do {
            try modelContext.save()
            persist() // Save journey state
            ReverieHaptics.successFeedback()
        } catch {
            print("Failed to start mini challenge: \(error)")
        }
    }

    // MARK: - Cleanup Old Challenges (Optional Enhancement)

    /// Remove completed challenges older than specified days
    func cleanupOldChallenges(modelContext: ModelContext, olderThanDays: Int = 90) {
        guard let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -olderThanDays,
            to: Date()
        ) else { return }

        let descriptor = FetchDescriptor<MiniChallengeProgress>()
        guard let allProgress = try? modelContext.fetch(descriptor) else { return }

        // Delete old completed challenges
        allProgress.filter { progress in
            progress.isCompleted &&
            (progress.completedDate ?? progress.startDate) < cutoffDate
        }.forEach { modelContext.delete($0) }

        try? modelContext.save()
    }
}
