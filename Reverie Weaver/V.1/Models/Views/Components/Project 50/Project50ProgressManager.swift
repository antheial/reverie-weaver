//
// Project50ProgressManager.swift
// Reverie Weaver
//
// Created Oct 2025
// FULLY UPDATED with Mini Challenge Progress Tracking + MIGRATION SAFETY
//
// Central brain for Project 50 progression:
// - Journey persistence with version-safe migration
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
    var version: Int = 2
    var startDate: Date? = nil
    var currentLevel: Int = 1
    var unlockedLevels: Set<Int> = [1] // Level 1 is available immediately after start
    var declinedUnlockLevels: Set<Int> = [] // If user declines, we never re-prompt
    var completionByLevel: [Int: Double] = [:] // Cache for UI; recomputed on refresh
    var levelStartDates: [Int: Date] = [:] // When each level was inserted into Desk
    var lastPromptedLevel: Int? = nil // Avoid duplicate prompts within a session
    
    // Completion tracking
    var levelCompletionDates: [Int: Date] = [:] // When each level was completed
    var totalP50Completions: Int = 0 // How many times Day 50 has been reached
    var totalMasteryCompletions: Int = 0 // How many times Level 3 has been completed

    // Mini challenge
    var activeMiniChallengeID: String? = nil
    var miniChallengeStartDate: Date? = nil
    
    // Computed properties for completion status
    var isProject50Complete: Bool {
        levelCompletionDates[2] != nil // PROJECT 50 complete when Level 2 is done
    }
    
    var isMasteryComplete: Bool {
        levelCompletionDates[3] != nil // Mastery complete when Level 3 is done
    }
    
    var allLevelsComplete: Bool {
        levelCompletionDates[1] != nil &&
        levelCompletionDates[2] != nil &&
        levelCompletionDates[3] != nil
    }
    
    var canSelectLevel: Bool {
        allLevelsComplete
    }
    
    // MARK: - Migration-Safe Coding
    
    enum CodingKeys: String, CodingKey {
        case version
        case startDate, currentLevel, unlockedLevels, declinedUnlockLevels
        case completionByLevel, levelStartDates, lastPromptedLevel
        case levelCompletionDates, totalP50Completions, totalMasteryCompletions
        case activeMiniChallengeID, miniChallengeStartDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        version = (try? container.decode(Int.self, forKey: .version)) ?? 1
        
        startDate = try? container.decode(Date?.self, forKey: .startDate)
        currentLevel = (try? container.decode(Int.self, forKey: .currentLevel)) ?? 1
        unlockedLevels = (try? container.decode(Set<Int>.self, forKey: .unlockedLevels)) ?? [1]
        declinedUnlockLevels = (try? container.decode(Set<Int>.self, forKey: .declinedUnlockLevels)) ?? []
        completionByLevel = (try? container.decode([Int: Double].self, forKey: .completionByLevel)) ?? [:]
        levelStartDates = (try? container.decode([Int: Date].self, forKey: .levelStartDates)) ?? [:]
        lastPromptedLevel = try? container.decode(Int?.self, forKey: .lastPromptedLevel)
        
        activeMiniChallengeID = try? container.decode(String?.self, forKey: .activeMiniChallengeID)
        miniChallengeStartDate = try? container.decode(Date?.self, forKey: .miniChallengeStartDate)
        
        if version >= 2 {
            levelCompletionDates = (try? container.decode([Int: Date].self, forKey: .levelCompletionDates)) ?? [:]
            totalP50Completions = (try? container.decode(Int.self, forKey: .totalP50Completions)) ?? 0
            totalMasteryCompletions = (try? container.decode(Int.self, forKey: .totalMasteryCompletions)) ?? 0
        } else {
            levelCompletionDates = [:]
            totalP50Completions = 0
            totalMasteryCompletions = 0
            print("📦 Migrated Project50Journey from version \(version) to version 2")
            version = 2 // Update version after migration
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(version, forKey: .version)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(currentLevel, forKey: .currentLevel)
        try container.encode(unlockedLevels, forKey: .unlockedLevels)
        try container.encode(declinedUnlockLevels, forKey: .declinedUnlockLevels)
        try container.encode(completionByLevel, forKey: .completionByLevel)
        try container.encode(levelStartDates, forKey: .levelStartDates)
        try container.encode(lastPromptedLevel, forKey: .lastPromptedLevel)
        try container.encode(levelCompletionDates, forKey: .levelCompletionDates)
        try container.encode(totalP50Completions, forKey: .totalP50Completions)
        try container.encode(totalMasteryCompletions, forKey: .totalMasteryCompletions)
        try container.encode(activeMiniChallengeID, forKey: .activeMiniChallengeID)
        try container.encode(miniChallengeStartDate, forKey: .miniChallengeStartDate)
    }
    
    // Default initializer for fresh starts
    init() {
        self.version = 2
    }
}

// MARK: - Manager

@MainActor
final class Project50ProgressManager: ObservableObject {

    static let shared = Project50ProgressManager()

    // MARK: Persistence
    private let storageKey = "project50JourneyData"
    private let defaults: UserDefaults = .standard

    @Published private(set) var journey: Project50Journey = Project50Journey() {
        didSet { persist() }
    }

    // MARK: UI Flags for Levels Screen
    @Published var unlockReadyLevel: Int? = nil
    @Published var showUnlockModal: Bool = false
    
    // EARLY UNLOCK: Track if Level 2 is eligible for early unlock
    @Published var isLevel2EarlyUnlockAvailable: Bool = false

    // MARK: Constants
    private let level2DayThreshold = 21
    private let level3DayThreshold = 50
    private let completionThreshold: Double = 0.75
    private let earlyUnlockMinDays = 10  // Early unlock requires 10 consecutive 100% days

    var insertLevelHabits: ((_ level: Int) -> Void)?
    var removeLevelHabits: ((_ level: Int) -> Void)?
    var removeAllProject50Habits: (() -> Void)?
    var removeAllMiniChallengeHabits: (() -> Void)?
    var removeAllThemeWeekHabits: (() -> Void)?

    // Completion provider: returns numerator/denominator context for a level.
    // Return tuple:
    // - activeHabitsCount: count of active P50 habits in Desk for this level (for tracking)
    // - totalCompletions: number of successful days (days meeting ≥80% completion threshold)
    // - daysSinceLevelStartCapped: total days required for level (21 or 29) - this IS the denominator
    //
    // Formula: progress = totalCompletions / daysSinceLevelStartCapped
    // Example: 8 successful days / 21 total days = 38%
    //
    // IMPORTANT: This provider should ONLY count habits tagged program:"project50" and level == n.
    var completionProvider: ((_ level: Int, _ levelStartDate: Date?) -> (activeHabitsCount: Int, totalCompletions: Int, daysSinceLevelStartCapped: Int))?
    
    // EARLY UNLOCK: Check if level has N consecutive days of 100% completion
    // Parameters:
    // - level: Which level to check (typically 1 for Level 2 early unlock)
    // - requiredDays: Number of consecutive 100% days needed (typically 10)
    // Returns: true if criteria met, false otherwise
    var earlyUnlockCheckProvider: ((_ level: Int, _ requiredDays: Int) -> Bool)?

    // MARK: Init
    private init() { restore() }

    // MARK: - Public: Journey Lifecycle
    func startJourney() {
        guard journey.startDate == nil else { return }
        
        #if DEBUG
        if insertLevelHabits == nil {
            print("⚠️ [P50] startJourney: insertLevelHabits hook not set")
            print("   This is OK if UI handles habit insertion directly")
        }
        #endif
        
        let now = Date()
        journey.startDate = now
        journey.currentLevel = 1
        journey.unlockedLevels = [1]
        journey.declinedUnlockLevels = []
        journey.levelStartDates[1] = now
        journey.lastPromptedLevel = nil
        journey.activeMiniChallengeID = nil
        journey.miniChallengeStartDate = nil
        insertLevelHabits?(1)
        
        #if DEBUG
        print("🧩 [P50] startJourney → journey initialized, level 1 started")
        #endif
        
        ReverieHaptics.successFeedback()
        persist()
    }

    func resetJourney() {
        #if DEBUG
        print("🧩 [P50] resetJourney → removeAllProject50Habits()")
        #endif
        removeAllProject50Habits?()

        journey = Project50Journey()
        unlockReadyLevel = nil
        showUnlockModal = false
        ReverieHaptics.lightFeedback()
    }
    
    /// Reset journey and start from a specific level (for users who completed all levels)
    func resetJourneyWithLevelSelection(startingLevel: Int) {
        guard startingLevel >= 1 && startingLevel <= 3 else { return }
        
        #if DEBUG
        print("🧩 [P50] resetJourneyWithLevelSelection → removeAllProject50Habits()")
        #endif
        removeAllProject50Habits?()
        
        let preservedCompletionDates = journey.levelCompletionDates
        
        let now = Date()
        journey.startDate = now
        journey.currentLevel = startingLevel
        journey.unlockedLevels = [startingLevel]
        journey.declinedUnlockLevels = []
        journey.completionByLevel = [:]
        journey.levelStartDates = [startingLevel: now]
        journey.lastPromptedLevel = nil
        
        if startingLevel > 1 {
            for level in 1..<startingLevel {
                if let date = preservedCompletionDates[level] {
                    journey.levelCompletionDates[level] = date
                }
            }
        }
        
        for level in startingLevel...3 {
            journey.levelCompletionDates[level] = nil
        }
        
        insertLevelHabits?(startingLevel)
        
        unlockReadyLevel = nil
        showUnlockModal = false
        ReverieHaptics.successFeedback()
        persist()
    }

    func refreshEligibility() {
        for level in [1, 2, 3] {
            journey.completionByLevel[level] = computeCompletion(level: level)
        }
        
        checkForLevelCompletions()
        
        checkEarlyUnlockAvailability()

        if !journey.allLevelsComplete, let candidate = nextUnlockCandidate() {
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
            showUnlockModal = false
            return
        }

        #if DEBUG
        if insertLevelHabits == nil {
            print("⚠️ [P50] confirmUnlock: insertLevelHabits hook not set")
        }
        if removeLevelHabits == nil {
            print("⚠️ [P50] confirmUnlock: removeLevelHabits hook not set")
        }
        #endif

        insertLevelHabits?(level)
        #if DEBUG
        print("🧩 [P50] confirmUnlock → insertLevelHabits(\(level)) \(insertLevelHabits != nil ? "called" : "skipped (nil)")")
        #endif

        let previousLevel = level - 1
        if previousLevel >= 1 {
            removeLevelHabits?(previousLevel)
            #if DEBUG
            print("🧩 [P50] confirmUnlock → removeLevelHabits(\(previousLevel)) \(removeLevelHabits != nil ? "called" : "skipped (nil)")")
            #endif
        }

        journey.unlockedLevels.insert(level)
        journey.currentLevel = level
        journey.levelStartDates[level] = Date()

        showUnlockModal = false
        unlockReadyLevel = nil
        ReverieHaptics.successFeedback()
        persist()
    }
    /// Validate that required hooks are configured
    /// Call this in debug builds to catch configuration issues early
    func validateHooksConfigured() -> Bool {
        var isValid = true
        
        if completionProvider == nil {
            print("❌ [P50] completionProvider not set - progress tracking will fail")
            isValid = false
        }
        
        if earlyUnlockCheckProvider == nil {
            print("⚠️ [P50] earlyUnlockCheckProvider not set - early unlock disabled")
            // Not critical, just a warning
        }
        
        if insertLevelHabits == nil {
            print("ℹ️ [P50] insertLevelHabits not set - UI should handle habit insertion")
        }
        
        if removeLevelHabits == nil {
            print("ℹ️ [P50] removeLevelHabits not set - UI should handle habit removal")
        }
        
        return isValid
    }

    func declineUnlock(level: Int) {
        journey.declinedUnlockLevels.insert(level)
        showUnlockModal = false
        unlockReadyLevel = nil
        ReverieHaptics.lightFeedback()
        persist()
    }
    
    func manualEarlyUnlock(level: Int) {
        guard level == 2 else { return }
        
        guard journey.currentLevel == 1,
              daysElapsed >= earlyUnlockMinDays,
              isLevel2EarlyUnlockAvailable else { return }
        
        #if DEBUG
        print("🧩 [P50] manualEarlyUnlock → insertLevelHabits(\(level)) & removeLevelHabits(1)")
        #endif
        insertLevelHabits?(level)
        removeLevelHabits?(1)
        
        journey.unlockedLevels.insert(level)
        journey.currentLevel = level
        journey.levelStartDates[level] = Date()
        
        isLevel2EarlyUnlockAvailable = false
        
        ReverieHaptics.successFeedback()
        persist()
    }
    
    // EARLY UNLOCK: Check if Level 2 is eligible for early unlock
    private func checkEarlyUnlockAvailability() {
        // Only check if:
        // 1. Currently on Level 1
        // 2. Level 2 is not already unlocked
        // 3. At least 10 days have passed
        guard journey.currentLevel == 1,
              !journey.unlockedLevels.contains(2),
              daysElapsed >= earlyUnlockMinDays else {
            isLevel2EarlyUnlockAvailable = false
            return
        }
        
        if let provider = earlyUnlockCheckProvider,
           provider(1, earlyUnlockMinDays) {
            isLevel2EarlyUnlockAvailable = true
        } else {
            isLevel2EarlyUnlockAvailable = false
        }
    }
    
    // MARK: - Level Completion & Mastery
    
    /// Complete Level 3 manually (user-initiated)
    func completeMasteryPractice() {
        guard journey.currentLevel == 3 else { return }
        guard journey.levelCompletionDates[3] == nil else { return }
        
        journey.levelCompletionDates[3] = Date()
        journey.totalMasteryCompletions += 1
        
        #if DEBUG
        print("🧩 [P50] completeMasteryPractice → removeLevelHabits(3)")
        #endif
        
        removeLevelHabits?(3)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("Project50MasteryAchieved"),
            object: nil
        )
        
        ReverieHaptics.successFeedback()
        persist()
    }
    
    /// Select and start a specific level (after all levels complete)
    func selectLevel(_ level: Int) {
        guard journey.canSelectLevel else { return }
        guard (1...3).contains(level) else { return }
        
        // Remove current level habits
        if journey.currentLevel != 0 {
            #if DEBUG
            print("🧩 [P50] selectLevel → removeLevelHabits(\(journey.currentLevel))")
            #endif
            removeLevelHabits?(journey.currentLevel)
        }
        
        // Clear completion status for selected level
        journey.levelCompletionDates.removeValue(forKey: level)
        
        // Set as current level and insert habits
        journey.currentLevel = level
        journey.levelStartDates[level] = Date()
        #if DEBUG
        print("🧩 [P50] selectLevel → insertLevelHabits(\(level))")
        #endif
        insertLevelHabits?(level)
        
        ReverieHaptics.successFeedback()
        persist()
    }
    
    /// Check for auto-completion and transitions
    private func checkForLevelCompletions() {
        let days = daysSinceStart
        
        // Check Level 1 completion (21 days + 75%)
        if journey.levelCompletionDates[1] == nil,
           let level1Start = journey.levelStartDates[1] {

            let daysInLevel1 = Calendar.current
                .dateComponents([.day], from: level1Start, to: Date()).day ?? 0

            if daysInLevel1 >= 21,
               (journey.completionByLevel[1] ?? 0.0) >= completionThreshold {

                journey.levelCompletionDates[1] = Date()
                #if DEBUG
                print("🏁 [P50] Level 1 complete (≥21 days & ≥75%)")
                #endif
                persist()
            }
        }

        // Check Level 2 completion (Day 50 = PROJECT 50 COMPLETE!)
        if journey.currentLevel == 2,
           journey.levelCompletionDates[2] == nil,
           days >= level3DayThreshold,
           (journey.completionByLevel[2] ?? 0.0) >= completionThreshold {
            
            // Mark Level 2 complete
            journey.levelCompletionDates[2] = Date()
            journey.totalP50Completions += 1
            
            #if DEBUG
            print("🏁 [P50] Level 2 complete → transitioning to Level 3")
            print("🧩 [P50] removeLevelHabits(2) & insertLevelHabits(3)")
            #endif
            // Auto-transition to Level 3
            journey.currentLevel = 3
            journey.unlockedLevels.insert(3)
            journey.levelStartDates[3] = Date()
            
            // Remove Level 2 habits, insert Level 3 habits
            removeLevelHabits?(2)
            insertLevelHabits?(3)
            
            // Post notification for celebration and achievement
            NotificationCenter.default.post(
                name: NSNotification.Name("Project50Completed"),
                object: nil
            )
            
            persist()
        }
        
        // Check Level 3 auto-completion (29 days + 75%)
        if journey.currentLevel == 3,
           journey.levelCompletionDates[3] == nil, // Not already complete
           let level3Start = journey.levelStartDates[3] {
            
            let daysInLevel3 = Calendar.current.dateComponents([.day], from: level3Start, to: Date()).day ?? 0
            
            if daysInLevel3 >= 29, // 29 days complete
               (journey.completionByLevel[3] ?? 0.0) >= completionThreshold { // ≥75%
                
                // Mark Level 3 complete
                journey.levelCompletionDates[3] = Date()
                journey.totalMasteryCompletions += 1
                
                #if DEBUG
                print("🏁 [P50] Level 3 auto-complete (≥29 days & ≥75%) → removeLevelHabits(3)")
                #endif
                // Remove Level 3 habits
                removeLevelHabits?(3)
                
                // Post notification for achievement
                NotificationCenter.default.post(
                    name: NSNotification.Name("Project50MasteryAchieved"),
                    object: nil
                )
                
                persist()
            }
        }
    }

    // MARK: - Private: Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(journey) else {
            print("⚠️ Failed to encode Project50Journey")
            return
        }
        defaults.set(data, forKey: storageKey)
    }

    private func restore() {
        guard let data = defaults.data(forKey: storageKey) else {
            print("📦 No saved Project50Journey found, starting fresh")
            journey = Project50Journey()
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(Project50Journey.self, from: data)
            journey = decoded
            print("📦 Successfully restored Project50Journey (version \(decoded.version))")
        } catch {
            print("⚠️ Failed to decode Project50Journey: \(error)")
            print("📦 Migration failed, starting fresh (old data preserved in UserDefaults)")
            journey = Project50Journey()
            
            defaults.set(data, forKey: "\(storageKey)_backup_\(Date().timeIntervalSince1970)")
        }
    }

    // MARK: - Private: Unlock Logic

    // Which level should we prompt to unlock next?
    private func nextUnlockCandidate() -> Int? {
        guard journey.startDate != nil else { return nil }

        // Level 2 unlock: 21+ days elapsed AND Level 1 ≥ 75%
        if journey.currentLevel == 1 {
            let comp1 = completion(for: 1)
            if daysElapsed >= level2DayThreshold && comp1 >= completionThreshold {
                return 2
            }
        }

        // Level 3 unlock: 50+ days elapsed AND Level 2 ≥ 75%
        if journey.currentLevel == 2 {
            let comp2 = completion(for: 2)
            if daysElapsed >= level3DayThreshold && comp2 >= completionThreshold {
                return 3
            }
        }

        return nil
    }

    // Does the user meet the unlock criteria for this level?
    private func isEligibleToUnlock(level: Int) -> Bool {
        guard journey.startDate != nil else { return false }

        switch level {
        case 2:
            let comp1 = completion(for: 1)
            return daysElapsed >= level2DayThreshold && comp1 >= completionThreshold
        case 3:
            let comp2 = completion(for: 2)
            return daysElapsed >= level3DayThreshold && comp2 >= completionThreshold
        default:
            return false
        }
    }

    // MARK: - Private: Stats

    // Total days since journey started (never negative, nil if no journey)
    private var daysElapsed: Int {
        guard let start = journey.startDate else { return 0 }
        let elapsed = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(0, elapsed)
    }

    private func computeCompletion(level: Int) -> Double {
        guard journey.levelStartDates[level] != nil else {
            return 0.0
        }

        guard let provider = completionProvider else {
            #if DEBUG
            print("⚠️ [P50] completionProvider is nil - returning 0% for level \(level)")
            #endif
            return 0.0
        }

        let tuple = provider(level, journey.levelStartDates[level])

        // Formula: successfulDays / totalDaysRequired
        let denominator = max(tuple.daysSinceLevelStartCapped, 1)
        let result = Double(tuple.totalCompletions) / Double(denominator)
        
        let clampedResult = min(max(result, 0.0), 1.0)
        
        #if DEBUG
        if result > 1.0 {
            print("⚠️ [P50] Completion > 100% for level \(level): \(result * 100)%, clamped to 100%")
        }
        #endif
        
        return clampedResult
    }

    // MARK: - Public: Stats

    public var daysSinceStart: Int {
        daysElapsed
    }
    
    /// Days since current level started
    public func daysInCurrentLevel() -> Int {
        guard let startDate = journey.levelStartDates[journey.currentLevel] else { return 0 }
        return Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    public func completion(for level: Int) -> Double {
        // Use cached value if available
        if let cached = journey.completionByLevel[level] {
            return cached
        }
        return computeCompletion(level: level)
    }

    // MARK: - Mini Challenges

    // Add a mini challenge by ID (used when progress tracker already created)
    func addMiniChallenge(id: String) {
        journey.activeMiniChallengeID = id
        journey.miniChallengeStartDate = Date()
        persist()
    }
    
    // Complete/end the mini challenge (remove from journey)
    func completeMiniChallenge() {
        journey.activeMiniChallengeID = nil
        journey.miniChallengeStartDate = nil
        persist()
    }

    // Start a mini challenge (deprecated version for backward compatibility)
    func startMiniChallenge(challenge: MiniChallenge) {
        journey.activeMiniChallengeID = challenge.id
        journey.miniChallengeStartDate = Date()
        persist()
        ReverieHaptics.successFeedback()
    }

    // End the mini challenge (alias for completeMiniChallenge)
    func endMiniChallenge() {
        completeMiniChallenge()
        ReverieHaptics.lightFeedback()
    }

    // Is this challenge currently active?
    func isActive(miniChallenge: MiniChallenge) -> Bool {
        journey.activeMiniChallengeID == miniChallenge.id
    }
}

// MARK: - Convenience Event Hooks

extension Project50ProgressManager {
    func onAppearOrActive() {
        refreshEligibility()
    }

    func onDeskCompletionDidUpdate() {
        refreshEligibility()
    }
}

// MARK: - Mini Challenge Progress Tracking Extensions

extension Project50ProgressManager {

    // MARK: - Get Active Mini Challenge Progress
    func getActiveMiniChallengeProgress(modelContext: ModelContext) -> MiniChallengeProgress? {
        // Create descriptor
        let descriptor = FetchDescriptor<MiniChallengeProgress>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let allProgress = try? modelContext.fetch(descriptor) else {
            return nil
        }

        // Exclude completed AND archived challenges
        return allProgress.first { progress in
            !progress.isCompleted && !progress.isArchived
        }
    }

    // MARK: - Check Daily Mini Challenge Completion

    func checkMiniChallengeCompletion(
        modelContext: ModelContext,
        habits: [Habit],
        completions: [HabitCompletion],
        reflections: [DailyReflection]
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
        // Also exclude archived challenges (they should be restarted, not continued)
        let existingProgress = allProgress.first { progress in
            progress.challengeTag == challengeTag && !progress.isCompleted && !progress.isArchived
        }

        if let progress = existingProgress {
            if progress.requiredHabitIDs.isEmpty {
                progress.requiredHabitIDs = challengeHabits.map { $0.id }
            }

            if !progress.isTodayComplete {
                progress.checkAndUpdateProgress(completions: completions, reflections: reflections)

                do {
                    try modelContext.save()

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
            let challengeTitle = "Mini Challenge"

            let habitIDs = challengeHabits.map { $0.id }
            let newProgress = MiniChallengeProgress(
                challengeID: challengeID,
                challengeTag: challengeTag,
                challengeTitle: challengeTitle,
                requiredHabitIDs: habitIDs,
                startDate: challengeStartDate
            )
            newProgress.checkAndUpdateProgress(completions: completions, reflections: reflections)

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

    func getAllMiniChallengeProgress(modelContext: ModelContext) -> [MiniChallengeProgress] {
        let descriptor = FetchDescriptor<MiniChallengeProgress>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Start Mini Challenge with Progress Tracking
    func startMiniChallenge(
        challenge: MiniChallenge,
        modelContext: ModelContext,
        habitIDs: [UUID]
    ) {
        journey.activeMiniChallengeID = challenge.id
        journey.miniChallengeStartDate = Date()

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
            persist()
            ReverieHaptics.successFeedback()
        } catch {
            print("Failed to start mini challenge: \(error)")
        }
    }

    // MARK: - Cleanup Old Challenges
    
    func cleanupOldChallenges(modelContext: ModelContext, olderThanDays: Int = 90) {
        guard let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -olderThanDays,
            to: Date()
        ) else { return }

        let descriptor = FetchDescriptor<MiniChallengeProgress>()
        guard let allProgress = try? modelContext.fetch(descriptor) else { return }

        // Cleanup both completed AND archived challenges older than cutoff
        allProgress.filter { progress in
            (progress.isCompleted || progress.isArchived) &&
            (progress.completedDate ?? progress.archivedDate ?? progress.startDate) < cutoffDate
        }.forEach { modelContext.delete($0) }

        try? modelContext.save()
    }
}

