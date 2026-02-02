//
// Project50LevelsView.swift
// Reverie Weaver
//
// Complete Project 50 Progress Dashboard
// Shows: Days elapsed, current level, completion %, level cards, danger zone
// COMPLETE with Day 50 completion, Level 3 mastery, celebrations, and reset system
//

import SwiftUI
import SwiftData
import Combine

struct Project50LevelsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

    @StateObject private var manager = Project50ProgressManager.shared

    @State private var showConfirmUnlock = false
    @State private var unlockTarget: Int?

    @State private var showPreviewLevel: IdentifiableInt?
    @State private var showUnlockLevel: IdentifiableInt?

    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false
    
    // Completion system states
    @State private var showCompleteMasteryConfirmation = false
    @State private var showLevelSelection = false
    @State private var showProject50Celebration = false
    @State private var showMasteryCelebration = false

    var body: some View {
        ZStack {
            ReverieWeaverBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // MARK: - Dashboard
                    progressDashboard

                    // Rest day informational note
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("Progress continues on rest days")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)

                    Divider()
                        .padding(.horizontal, 24)

                    // MARK: - Levels List
                    VStack(spacing: 16) {
                        ForEach(1...3, id: \.self) { level in
                            levelCard(for: level)
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Danger Zone
                    dangerZoneSection

                    Spacer(minLength: 60)
                }
                .padding(.top, 32)
            }
        }
        .navigationTitle("Project 50 Levels")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupCompletionTracking()
            setupEarlyUnlockCheck()
            manager.refreshEligibility()
            _ = manager.completion(for: manager.journey.currentLevel)
        }
        .onChange(of: completions.count) { oldValue, newValue in
            manager.refreshEligibility()
        }
        .onChange(of: habits.count) { oldValue, newValue in
            setupCompletionTracking()
            setupEarlyUnlockCheck()
            manager.refreshEligibility()
        }
        // Preview sheet
        .sheet(item: $showPreviewLevel) { identifiable in
            Project50OverviewHabits(level: identifiable.value, mode: .preview)
        }
        // Unlock sheet
        .sheet(item: $showUnlockLevel) { identifiable in
            Project50OverviewHabits(level: identifiable.value, mode: .unlock)
        }
        // Reset confirmation
        .alert("Reset Journey?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetJourney()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset your progress but keep your habits on your desk. You can continue from where you are.")
        }
        // Delete confirmation
        .alert("Delete All Project 50 Habits?", isPresented: $showDeleteConfirmation) {
            Button("Delete All", role: .destructive) {
                deleteAllProject50Habits()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            let count = habits.filter { $0.programTag == "P50" }.count
            return Text("This will remove all \(count) Project 50 habits from your desk and reset your progress. This cannot be undone.")
        }
        // ✅ NEW: Complete Mastery confirmation
        .alert("Complete Mastery Practice?", isPresented: $showCompleteMasteryConfirmation) {
            Button("Complete", role: .destructive) {
                completeMasteryPractice()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will mark Level 3 as complete and remove Level 3 habits from your desk.")
        }
        // ✅ NEW: Level selection sheet
        .sheet(isPresented: $showLevelSelection) {
            LevelSelectionSheet(onSelect: { level in
                showLevelSelection = false
                manager.resetJourneyWithLevelSelection(startingLevel: level)
            })
        }
        // ✅ NEW: Project 50 completion celebration
        .sheet(isPresented: $showProject50Celebration) {
            Project50CompletionCelebrationView()
        }
        // ✅ NEW: Mastery achieved celebration
        .sheet(isPresented: $showMasteryCelebration) {
            Project50MasteryCelebrationView()
        }
        // ✅ NEW: Listen for completion notifications
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Project50Completed"))) { _ in
            showProject50Celebration = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Project50MasteryAchieved"))) { _ in
            showMasteryCelebration = true
        }
    }

    // MARK: - ✅ DEBUGGED: Accurate Daily Consistency Tracking
    //
    // PROGRESS FORMULA: successfulDays / totalDaysRequired
    // Example: 8 successful days / 21 total days = 38%
    //
    // DESIGN PRINCIPLE: Project 50 habits are FIXED REQUIREMENTS
    // • Progress measures completion of the program's requirements, not user's active habits
    // • Archived P50 habits still count (user must complete them to progress)
    // • Custom schedules are ignored (P50 is designed for daily completion)
    // • Users who archive P50 habits make progression harder for themselves
    //
    // LEVEL REQUIREMENTS:
    // • Level 1: 21 days (Days 1-21 of Project 50)
    // • Level 2: 29 days (Days 22-50 of Project 50)
    // • Level 3: 29 days (Days 51+ of Project 50)
    //
    // SUCCESSFUL DAY CRITERIA: ≥80% of level's P50 habits completed (unique habits counted)
    //
    // KEY FIXES:
    // 1. Window calculation: Uses levelStartDate → Date() (not backward-looking)
    // 2. Unique habits: Counts Set of habitIds per day (prevents duplicate counting)
    // 3. Denominator: Uses daysCap (21 or 29) as total requirement
    // 4. Consistency: Matches WeeklyArchiveView's calculation exactly
    //
    // EXAMPLES:
    // • Day 8 with 8/8 perfect days: 8/21 = 38% (38% through Level 1)
    // • Day 21 with 18/21 days: 18/21 = 86% (86% through Level 1)
    // • Day 25 of Level 2 with 20 days: 20/29 = 69% (69% through Level 2)
    //
    private func setupCompletionTracking() {
        manager.completionProvider = { [self] level, levelStartDate in
            // 1. Filter Project 50 habits for this specific level
            // All P50 habits count as program requirements (even if user archived them)
            let levelHabits = habits.filter { habit in
                guard let tag = habit.programTag else { return false }
                return tag == "P50" && habit.programLevel == level
            }

            let activeHabitsCount = levelHabits.count
            
            // Validate inputs
            guard activeHabitsCount > 0 else {
                #if DEBUG
                print("⚠️ Project50 Level \(level): No P50 habits found for this level")
                #endif
                return (activeHabitsCount: 0, totalCompletions: 0, daysSinceLevelStartCapped: 0)
            }
            
            guard let startDate = levelStartDate else {
                #if DEBUG
                print("⚠️ Project50 Level \(level): No start date found")
                #endif
                return (activeHabitsCount: 0, totalCompletions: 0, daysSinceLevelStartCapped: 0)
            }

            // 2. Calculate elapsed days since this level started
            let calendar = Calendar.current
            let daysSinceStart = max(0, calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0)

            // Cap the tracking window based on level duration
            let daysCap: Int
            switch level {
            case 1:
                daysCap = 21  // Level 1: Days 1-21 (21 days)
            case 2:
                daysCap = 29  // Level 2: Days 22-50 (29 days)
            case 3:
                daysCap = 29  // Level 3: Days 51+ (ongoing, but cap at 29 for calculation)
            default:
                daysCap = 21
            }

            // ✅ FIXED: Proper window calculation from level start date
            // Use the level start date as window start, not a backward-looking window
            let windowStart = startDate
            let windowEnd = Date()

            // 3. Identify all relevant completions since level started
            let habitIds = Set(levelHabits.map { $0.id })
            let relevantCompletions = completions.filter { completion in
                habitIds.contains(completion.habitId) &&
                completion.completedAt >= windowStart &&
                completion.completedAt <= windowEnd
            }

            // 4. Group completions by day
            let groupedByDay = Dictionary(grouping: relevantCompletions) { completion in
                calendar.startOfDay(for: completion.completedAt)
            }

            // 5. Count "successful" days (≥80% of UNIQUE P50 habits completed)
            // P50 is designed for daily completion - custom schedules are not supported
            let successfulDays = groupedByDay.values.filter { dayCompletions in
                let uniqueHabits = Set(dayCompletions.map { $0.habitId }).count
                return uniqueHabits >= Int(Double(activeHabitsCount) * 0.80)
            }.count
            
            // ✅ DEBUG: Log calculation details
            #if DEBUG
            print("📊 Project50 Level \(level) Progress Calculation:")
            print("   • Level started: \(startDate)")
            print("   • Days elapsed: \(daysSinceStart)")
            print("   • P50 habits for this level: \(activeHabitsCount)")
            print("   • Days cap: \(daysCap)")
            print("   • Total completions found: \(relevantCompletions.count)")
            print("   • Days with completions: \(groupedByDay.count)")
            print("   • Successful days (≥80%): \(successfulDays)")
            print("   • Progress: \(successfulDays)/\(daysCap) = \(Int(Double(successfulDays)/Double(daysCap) * 100))%")
            #endif

            // 6. Return structured data for the manager
            // Formula: successfulDays / daysCap
            // Example: 8 successful days / 21 total days = 38%
            return (
                activeHabitsCount: activeHabitsCount,  // ✅ CRITICAL: Must be actual count for tracking
                totalCompletions: successfulDays,
                daysSinceLevelStartCapped: daysCap  // Use daysCap as divisor
            )
        }
    }
    
    // MARK: - ✅ EARLY UNLOCK: Check for consecutive 100% completion days
    //
    // Checks if the last N days all have 100% completion (all level habits completed each day)
    // Used for early Level 2 unlock eligibility
    //
    private func setupEarlyUnlockCheck() {
        manager.earlyUnlockCheckProvider = { [self] level, requiredDays in
            // 1. Filter habits for this level
            let levelHabits = habits.filter { habit in
                guard let tag = habit.programTag else { return false }
                return tag == "P50" && habit.programLevel == level
            }
            
            let habitCount = levelHabits.count
            guard habitCount > 0,
                  let levelStartDate = manager.journey.levelStartDates[level] else {
                return false
            }
            
            // 2. Get habit IDs for this level
            let habitIds = Set(levelHabits.map { $0.id })
            
            // 3. Check last N days for 100% completion
            let calendar = Calendar.current
            var consecutivePerfectDays = 0
            
            // Check from today backwards
            for dayOffset in 0..<requiredDays {
                guard let dayToCheck = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                    return false
                }
                
                // Skip if before level started
                guard dayToCheck >= levelStartDate else { return false }
                
                // Get completions for this specific day
                let dayStart = calendar.startOfDay(for: dayToCheck)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                
                let dayCompletions = completions.filter { completion in
                    habitIds.contains(completion.habitId) &&
                    completion.completedAt >= dayStart &&
                    completion.completedAt < dayEnd
                }
                
                // Check if ALL habits were completed (100% requirement)
                let uniqueHabitsCompleted = Set(dayCompletions.map { $0.habitId }).count
                
                if uniqueHabitsCompleted == habitCount {
                    consecutivePerfectDays += 1
                } else {
                    // Not consecutive anymore, fail
                    return false
                }
            }
            
            // All required days had 100% completion
            return consecutivePerfectDays >= requiredDays
        }
    }

// MARK: - Dashboard Section

    var progressDashboard: some View {
        VStack(spacing: 12) {
            // ✅ TODAY'S PROGRESS: Immediate feedback card
            todaysProgressCard
            
            // ✅ NEW: Completion counter badge (if any completions exist)
            if manager.journey.totalP50Completions > 0 || manager.journey.totalMasteryCompletions > 0 {
                completionCounterBadge
            }
            
            // ✅ NEW: Complete Mastery button (if Level 3 active and not complete)
            if manager.journey.currentLevel == 3 && !manager.journey.isMasteryComplete {
                completeMasteryButton
            }
            
            // Stats row
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Days Elapsed")
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    Text("\(manager.daysSinceStart)")
                        .font(.system(size: 20, weight: .semibold))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Level")
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    Text("Level \(manager.journey.currentLevel)")
                        .font(.system(size: 20, weight: .semibold))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Progress")
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    let p = Int((manager.completion(for: manager.journey.currentLevel)) * 100)
                    Text("\(p)%")
                        .font(.system(size: 20, weight: .semibold))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .padding(.horizontal, 20)
    }
    
    // ✅ NEW: Completion counter badge
    var completionCounterBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.sageGreen)
            
            if manager.journey.totalMasteryCompletions > 0 {
                Text("Full Completion: \(manager.journey.totalMasteryCompletions)×")
                    .font(.system(size: 13, weight: .semibold))
                     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            } else {
                Text("Project 50 Complete: \(manager.journey.totalP50Completions)×")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dynamicLabel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.sageGreen.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.sageGreen.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // ✅ NEW: Complete Mastery Practice button
    var completeMasteryButton: some View {
        Button {
            showCompleteMasteryConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 16))
                Text("Complete Mastery Practice")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                let days = manager.daysInCurrentLevel()
                Text("\(days)/29 days")
                    .font(.system(size: 13))
                     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.dustyBlue, Color.paleMauve],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    // ✅ TODAY'S PROGRESS CARD: Immediate feedback
        var todaysProgressCard: some View {
            let todayStats = getTodaysProgress()
            let progressPercent = todayStats.completedCount > 0
                ? Double(todayStats.completedCount) / Double(todayStats.totalCount)
                : 0.0
            let isSuccessfulDay = todayStats.completedCount >= Int(Double(todayStats.totalCount) * 0.80)
            
            return VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.sageGreen)
                    
                    Text("Today's Progress")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                         .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Spacer()
                    
                    // Status indicator
                    if todayStats.completedCount == 0 {
                        Text("Not started")
                            .font(.system(size: 12, weight: .regular))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    } else if isSuccessfulDay {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                            Text("Successful Day!")
                                .font(.system(size: 12, weight: .regular))
                        }
                        .foregroundStyle(Color.sageGreen)
                    } else {
                        Text("In progress")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.terracottaRose)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.dynamicSecondaryLabel.opacity(0.15))
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: isSuccessfulDay
                                        ? [Color.sageGreen, Color.sageGreen.opacity(0.8)]
                                        : [Color.terracottaRose, Color.dustyBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressPercent)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progressPercent)
                    }
                }
                .frame(height: 8)
                
                // Stats row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(todayStats.completedCount)/\(todayStats.totalCount) habits")
                            .font(.system(size: 13, weight: .regular))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        
                        Text("\(Int(progressPercent * 100))% complete")
                            .font(.system(size: 12))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                    
                    Spacer()
                    
                    // Encouragement text
                    if todayStats.completedCount == 0 {
                        Text("Start building today!")
                            .font(.system(size: 12))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    } else if !isSuccessfulDay {
                        let remaining = Int(ceil(Double(todayStats.totalCount) * 0.80)) - todayStats.completedCount
                        Text("Complete \(remaining) more for ✓")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.terracottaRose)
                    } else {
                        Text("Great work today!")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.sageGreen)
                    }
                }
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }

    // MARK: - Level Card

    @ViewBuilder
    func levelCard(for level: Int) -> some View {
        let isUnlocked = manager.journey.unlockedLevels.contains(level)
        let isActive = manager.journey.currentLevel == level
        let isComplete = manager.journey.levelCompletionDates[level] != nil
        let completion = manager.completion(for: level)

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Level \(level)")
                    .font(.system(size: 17, weight: .semibold))
                    .fontDesign(.serif)
                     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()

                // ✅ UPDATED: Show completion badge or active/locked status
                if isComplete {
                    completionBadge(for: level)
                } else if isActive {
                    Text("Active")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.sageGreen)
                        .clipShape(Capsule())
                } else if isUnlocked {
                    Text("Completed")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.dynamicSecondaryLabel.opacity(0.5))
                        .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                        Text("Locked")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                }
            }

            if isUnlocked && !isComplete {
                // Progress bar (only for unlocked but not complete levels)
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(Int(completion * 100))% complete")
                        .font(.system(size: 12, weight: .medium))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dynamicSecondaryLabel.opacity(0.15))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.sageGreen)
                                .frame(width: geometry.size.width * completion)
                        }
                    }
                    .frame(height: 6)
                }
            } else if !isUnlocked {
                // Requirements for locked levels
                VStack(alignment: .leading, spacing: 8) {
                    Text("Requirements:")
                        .font(.system(size: 12, weight: .semibold))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                    if level == 2 {
                        requirementRow(
                            text: "21 days elapsed",
                            isMet: manager.daysSinceStart >= 21
                        )
                        requirementRow(
                            text: "75% of Level 1 complete",
                            isMet: manager.completion(for: 1) >= 0.75
                        )
                    } else if level == 3 {
                        requirementRow(
                            text: "50 days elapsed",
                            isMet: manager.daysSinceStart >= 50
                        )
                        requirementRow(
                            text: "75% of Level 2 complete",
                            isMet: manager.completion(for: 2) >= 0.75
                        )
                    }

                    // Preview button
                    Button {
                        showPreviewLevel = IdentifiableInt(id: level)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye")
                                .font(.system(size: 12))
                            Text("Preview")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.dustyBlue.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.dustyBlue.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // ✅ EARLY UNLOCK: Unlock button for Level 2
                    if level == 2 && manager.isLevel2EarlyUnlockAvailable {
                        Button {
                            manager.manualEarlyUnlock(level: 2)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 12))
                                Text("Unlock Now")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.sageGreen, Color.sageGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        
                        // Helper text
                        Text("You've completed 10 days with 100% consistency!")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.sageGreen)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
            } else if isComplete {
                // Completion message
                completionMessage(for: level)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    // ✅ NEW: Completion badge for completed levels
    @ViewBuilder
    func completionBadge(for level: Int) -> some View {
        if level == 2 {
            // PROJECT 50 COMPLETE
            HStack(spacing: 4) {
                Image(systemName: "flag.checkered.2.crossed")
                    .font(.system(size: 11))
                Text("Project 50 ✓")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [Color.sageGreen, Color.dustyBlue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        } else if level == 3 {
            // MASTERY ACHIEVED
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                Text("Mastery ⭐")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [Color.dustyBlue, Color.paleMauve],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        } else {
            // Regular completion
            Text("Complete ✓")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.sageGreen.opacity(0.8))
                .clipShape(Capsule())
        }
    }
    
    // ✅ NEW: Completion message for completed levels
    @ViewBuilder
    func completionMessage(for level: Int) -> some View {
        if level == 2 {
            Text("Day 50 reached—Project 50 complete! Level 3 continues the journey.")
                .font(.system(size: 13))
                .fontDesign(.serif)
                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineSpacing(3)
        } else if level == 3 {
            Text("Mastery achieved! The full journey is complete.")
                .font(.system(size: 13))
                .fontDesign(.serif)
                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        } else {
            Text("Completed successfully.")
                .font(.system(size: 13))
                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
    }

    @ViewBuilder
    func requirementRow(text: String, isMet: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13))
                .foregroundStyle(isMet ? Color.sageGreen : Color.dynamicSecondaryLabel.opacity(0.4))

            Text(text)
                .font(.system(size: 12))
                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
    }

    // MARK: - Danger Zone

    var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DANGER ZONE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.terracottaRose)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                // Reset button
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                        Text("Reset Journey")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    }
                     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.terracottaRose.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Delete all button
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                        Text("Delete All Project 50 Habits")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    }
                    .foregroundStyle(Color.terracottaRose)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.terracottaRose.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.terracottaRose.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Get today's P50 progress for immediate feedback
    private func getTodaysProgress() -> (completedCount: Int, totalCount: Int) {
        let today = Date()
        let calendar = Calendar.current
        let currentLevel = manager.journey.currentLevel
        
        // Get P50 habits for current level
        let p50Habits = habits.filter { habit in
            guard let tag = habit.programTag else { return false }
            return tag == "P50" && habit.programLevel == currentLevel
        }
        
        let totalCount = p50Habits.count
        
        // Guard against no P50 habits
        guard totalCount > 0 else {
            return (0, 0)
        }
        
        // Get today's completions
        let todayCompletions = completions.filter { completion in
            calendar.isDate(completion.completedAt, inSameDayAs: today)
        }
        
        // Count unique P50 habits completed today
        let p50HabitIds = Set(p50Habits.map { $0.id })
        let completedCount = Set(todayCompletions.map { $0.habitId })
            .intersection(p50HabitIds)
            .count
        
        return (completedCount, totalCount)
    }

    // MARK: - Actions

    func resetJourney() {
        if manager.journey.canSelectLevel {
            // Show level selection sheet
            showLevelSelection = true
        } else {
            // Standard reset (start from Level 1)
            manager.resetJourney()
            ReverieHaptics.lightFeedback()
        }
    }

    func deleteAllProject50Habits() {
        // Delete all habits with programTag == "P50"
        let p50Habits = habits.filter { habit in
            guard let tag = habit.programTag else { return false }
            return tag == "P50"
        }

        for habit in p50Habits {
            habit.prepareForDeletion()
            modelContext.delete(habit)
        }

        try? modelContext.save()

        // Also reset the journey
        manager.resetJourney()
        ReverieHaptics.lightFeedback()
    }
    
    func completeMasteryPractice() {
        manager.completeMasteryPractice()
        ReverieHaptics.successFeedback()
    }
}


// MARK: - Helper Struct for Identifiable Int

struct IdentifiableInt: Identifiable {
    let id: Int
    var value: Int { id }
}

// MARK: - PROJECT 50 CELEBRATION VIEWS

// Project 50 Completion Celebration (Day 50)
struct Project50CompletionCelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            ReverieWeaverBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.sageGreen.opacity(0.3),
                                    Color.sageGreen.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.sageGreen, Color.dustyBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Title & message
                VStack(spacing: 12) {
                    Text("Project 50 Complete!")
                        .font(.system(size: 28, weight: .bold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text("You've reached Day 50")
                        .font(.system(size: 17, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                // Message
                Text("Fifty days of focused dedication—you've proven what consistency looks like. This is the rhythm that transforms habits into who you are.\n\nLevel 3 has begun automatically for continued mastery practice.")
                    .font(.system(size: 14, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Continue to Level 3")
                        .font(.system(size: 17, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.sageGreen, Color.dustyBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled(true)
    }
}

// Mastery Achieved Celebration (Level 3 Complete)
struct Project50MasteryCelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            ReverieWeaverBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.dustyBlue.opacity(0.3),
                                    Color.paleMauve.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.dustyBlue, Color.paleMauve],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Title & message
                VStack(spacing: 12) {
                    Text("Mastery Achieved!")
                        .font(.system(size: 28, weight: .bold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text("Level 3 Complete")
                        .font(.system(size: 17, weight: .regular))
                        .fontDesign(.serif)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.dustyBlue, Color.paleMauve],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                // Message
                Text("You've reached the peak of Project 50. This level of dedication and consistency is rare—you've not just completed habits, you've transformed your approach to growth itself.")
                    .font(.system(size: 14, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.dustyBlue, Color.paleMauve],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled(true)
    }
}

// Level Selection Sheet (for reset when all complete)

struct LevelSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let onSelect: (Int) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Choose Starting Level")
                            .font(.system(size: 22, weight: .bold))
                            .fontDesign(.serif)
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        
                        Text("Select which level to restart from. Your completion history will be preserved.")
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                             .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 32)
                    
                    // Level options
                    VStack(spacing: 16) {
                        levelOption(level: 1, title: "Foundation", days: "21 days")
                        levelOption(level: 2, title: "Focus", days: "29 days (Days 22-50)")
                        levelOption(level: 3, title: "Mastery", days: "Ongoing practice")
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }
        }
    }
    
    @ViewBuilder
    func levelOption(level: Int, title: String, days: String) -> some View {
        Button {
            onSelect(level)
        } label: {
            HStack(spacing: 16) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.6),
                                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text("\(level)")
                        .font(.system(size: 24, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.sageGreen)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(level): \(title)")
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                         .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text(days)
                        .font(.system(size: 13))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.35))
                    .shadow(color: Color.shadowColor.opacity(0.12), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

