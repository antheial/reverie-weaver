//
// WeeklyArchiveView.swift
// Reverie Weaver
//
// COMPLETE (Nov 2025)
// All three data integrity issues resolved:
//
// 1. MINI CHALLENGE PROGRESS:
//    - Changed from using cached `progress.isTodayComplete` to real-time `progress.isTodayChallengeComplete(completions:)`
//    - This ensures the UI reflects CURRENT completion state, not just what's been saved to dailyCompletions
//    - Added better logging to track when days are marked complete
//
// 2. PROJECT 50 PROGRESS:
//    - Replaced cached completion values with real-time calculation in `currentProject50Completion`
//    - Now calculates directly from habits and completions on each access
//    - Ensures progress bar always reflects latest data without needing manual refresh
//    - Removed inefficient `.id()` modifier that wasn't triggering proper updates
//
// 3. DAYCARD COMPLETION RATES:
//    - Uses active habit counts from the DeskView lineup instead of raw completion totals
//    - Caps rates at 100% by counting unique habit completions per day
//    - Historical completion rates remain accurate even after deleting habits
//    - Example: Complete 5/5 on Monday, delete 2 on Tuesday → Monday still shows 5/5 (not 5/3)
//
// 4. IMPROVED CHANGE DETECTION:
//    - Changed `onChange(of: allCompletions)` to `onChange(of: allCompletions.count)`
//    - This is more efficient and reliable for detecting completion changes
//    - Added comprehensive logging to track progress updates
//    - Ensures modelContext.save() is called when progress actually changes
//
// 5. MINI CHALLENGE INDEPENDENCE (Nov 11, 2025):
//    -   Mini challenges now completely independent from Project 50
//    -   System now tracks ALL active mini challenges (not just one)
//    -   hasMiniChallenge checks actual progress data, not Project 50 journey
//    -   Multiple active mini challenges display simultaneously with proper dividers
//    -   All active challenges update on completion changes
//
//  CRITICAL FIX (Nov 21, 2025):
//    -   Weekly Summary completion percentage now matches progress bar
//    -   Progress bar now uses unique completions instead of total count
//    -   "Threads Woven" now shows unique scheduled completions (not total)
//    -   Added comprehensive debug logging for weekly calculations
//    -   DayCard completion rates already correct (no changes needed)
//
//  CRITICAL FIX (Jan 23, 2026) - REST DAY INTEGRATION:
//    -   Fixed Project 50 progress calculation to count ALL days since level start
//    -   Previous bug: Used rolling window that reset progress daily
//    -   Changed from: windowStart = today - daysSinceLevelStart (rolling window)
//    -   Changed to: windowStart = levelStartDate (fixed start point)
//    -   Progress now correctly accumulates across all days in level
//    -   Added debug logging to track completion calculations
//

import SwiftUI
import SwiftData
import os.log

struct WeeklyArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Data Queries
    @Query(sort: \Habit.order) private var habits: [Habit]
    
    @Query private var profiles: [UserProfile]
    @Query private var allCompletions: [HabitCompletion]
    @Query private var pomodoroSessions: [PomodoroSession]
    @Query private var intentions: [DailyIntention]

    @Query private var reflections: [DailyReflection]
    @Query(sort: \MiniChallengeProgress.startDate, order: .reverse)
    private var allMiniChallengeProgress: [MiniChallengeProgress]
    
    @Query(sort: \ThemeWeekProgress.startDate, order: .reverse)
    private var allThemeWeekProgress: [ThemeWeekProgress]
    
    // MARK: - Shared Calculator
    private var statsCalculator: HabitStatsCalculator {
        HabitStatsCalculator(
            completions: allCompletions,
            habits: habits,
            reflections: reflections,
            profiles: profiles
        )
    }

    // MARK: - State
    @State private var currentDate = Date()
    @State private var selectedTab: ContentTab = .insights
    @State private var expandedDays: Set<Date> = []
    @State private var markedRestDays: Set<Date> = []
    @State private var showWeekPicker = false
    @State private var showAllIntentions = false
    
    // Celebration states
    @State private var showMiniChallengeCelebration = false
    @State private var showProject50LevelUp = false
    @State private var newLevel: Int = 1
    @State private var showConfetti = false
    
    @State private var showThemeWeekCelebration = false
    @State private var lastCelebratedThemeWeekID: UUID? = nil
    
    @ObservedObject private var progressManager = Project50ProgressManager.shared
    @State private var celebrationTitle: String = ""
    @State private var celebrationSubtitle: String = ""
    @State private var celebrationAccent: Color = .sageGreen
    @State private var celebrationIcon: String = "bolt.fill"
    @State private var lastCelebratedChallengeID: UUID? = nil

    // Reflection prompt state (shown after challenge completion celebration)
    @State private var showReflectionPrompt = false
    @State private var reflectionPromptChallenge: MiniChallenge? = nil
    @State private var reflectionPromptChallengeTag: String = ""

    // MARK: - Active Mini Challenge Tracker
    private var activeMiniChallenges: [MiniChallengeProgress] {
        // Filter out completed, paused, AND archived challenges
        // Archived challenges (after 8-day window with ≥85.7% success) should not show in weekly tracking
        allMiniChallengeProgress.filter { !$0.isCompleted && !$0.isPaused && !$0.isArchived }
    }
    
    private var activeMiniChallengeProgress: MiniChallengeProgress? {
        activeMiniChallenges.first
    }
    
    // MARK: - Active Theme Week Tracker
    private var activeThemeWeeks: [ThemeWeekProgress] {
        // Filter out completed, paused, AND archived theme weeks
        // Archived theme weeks (after 8-day window with ≥85.7% success) should not show in weekly tracking
        allThemeWeekProgress.filter { !$0.isCompleted && !$0.isPaused && !$0.isArchived }
    }

    private var hasThemeWeek: Bool {
        !activeThemeWeeks.isEmpty
    }

    private let miniChallengeCompletedNotification = Notification.Name("MiniChallengeCompleted")
    
    enum ContentTab { case insights, favorites }

    // MARK: - Computed Properties
    private var weekStartsOnSunday: Bool {
        profiles.first?.weekStartsOnSunday ?? true
    }

    private var weekStart: Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        let offset = weekStartsOnSunday ? weekday - 1 : (weekday == 1 ? 6 : weekday - 2)
        return calendar.date(byAdding: .day, value: -offset, to: currentDate) ?? currentDate
    }

    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func restDays(forWeekStarting start: Date) -> Set<Date> {
            let calendar = Calendar.current
            let normalizedStart = calendar.startOfDay(for: start)
            let endExclusive = calendar.date(byAdding: .day, value: 7, to: normalizedStart) ?? normalizedStart

            return Set(
                reflections
                    .compactMap { reflection -> Date? in
                        guard reflection.isRestDay else { return nil }
                        let reflectionDay = calendar.startOfDay(for: reflection.date)
                        guard reflectionDay >= normalizedStart && reflectionDay < endExclusive else { return nil }
                        return reflectionDay
                    }
            )
        }

    // Signature that changes whenever rest-day related reflections in the visible week change
    private var reflectionsRestDaySignatureForCurrentWeek: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: weekStart)
        let endExclusive = cal.date(byAdding: .day, value: 7, to: start) ?? start
        return reflections.reduce(0) { acc, r in
            let d = cal.startOfDay(for: r.date)
            guard d >= start && d < endExclusive else { return acc }
            let dayComponent = cal.ordinality(of: .day, in: .era, for: d) ?? 0
            let bit = r.isRestDay ? 1 : 0
            return acc ^ (dayComponent &* 31 &+ bit)
        }
    }

    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: weekStart)
    }

    private func activeHabitCount(on date: Date) -> Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // SNAPSHOT-BASED APPROACH:
        let dayCompletions = allCompletions.filter {
            calendar.isDate($0.completedAt, inSameDayAs: date)
        }
        
        // If we have completions with snapshots, use the max snapshot value
        let snapshotCounts = dayCompletions.compactMap { $0.snapshotActiveHabitsCount }
        if !snapshotCounts.isEmpty {
            // Use first completion's snapshot (captures start-of-day state, not mid-day additions)
            if let firstCompletion = dayCompletions.sorted(by: { $0.completedAt < $1.completedAt }).first,
               let snapshotCount = firstCompletion.snapshotActiveHabitsCount {
                
                #if DEBUG
                // Log if multiple different snapshots exist (indicates mid-day habit additions)
                let uniqueSnapshots = Set(snapshotCounts)
                if uniqueSnapshots.count > 1 {
                    print("ℹ️ Multiple snapshots for \(date.formatted(.dateTime.month().day())): \(Array(uniqueSnapshots).sorted()). Using first: \(snapshotCount)")
                }
                #endif
                
                return snapshotCount
            }

            // If no first completion snapshot, use max as fallback
            return snapshotCounts.max() ?? 0
        }
        
        // FALLBACK: For old data without snapshots, calculate from current habit state
        let activeHabits = habits.filter { habit in
            guard habit.createdAt <= dayStart else { return false }
            if let archivedDate = habit.archivedAt, archivedDate < dayStart {
                return false
            }
            return habit.isScheduledOn(date)
        }
        
        let activeCount = activeHabits.count
        
        #if DEBUG
        if !dayCompletions.isEmpty && activeCount > 0 {
            print("ℹ️ No snapshot for \(date), using unique habit count: \(activeCount)")
        }
        #endif
        
        return activeCount
    }
    
    // Helper function to check if a habit is active on a specific date
    // This is used by dayCompletionStats to determine scheduled lineup
    private func isHabitActive(_ habit: Habit, on date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Created on or before that day
        guard habit.createdAt <= dayStart else { return false }
        
        // Not archived before that day
        if let archivedDate = habit.archivedAt, archivedDate < dayStart {
            return false
        }
        
        // Scheduled for that day-of-week
        return habit.isScheduledOn(date)
    }
    
    // MARK: - 🎯 Consolidated Helper Functions (Optimization)
    
    /// Returns only scheduled completions from a completion array
    /// Treats legacy completions (wasScheduledForDay == nil) as scheduled for backward compatibility
    private func scheduledCompletions(from completions: [HabitCompletion]) -> [HabitCompletion] {
        completions.filter { completion in
            completion.wasScheduledForDay ?? true
        }
    }
    
    /// Counts unique habit IDs from scheduled completions, capped at maximum
    private func uniqueHabitCount(from completions: [HabitCompletion], cappedAt max: Int) -> Int {
        let scheduled = scheduledCompletions(from: completions)
        let unique = Set(scheduled.map { $0.habitId }).count
        return min(unique, max)
    }
    
    /// Checks if a day should be included in calculations (not a rest day)
    private func shouldIncludeDay(_ day: Date, restDays: Set<Date>) -> Bool {
        let calendar = Calendar.current
        let normalizedDay = calendar.startOfDay(for: day)
        return !restDays.contains(normalizedDay)
    }

    private var totalPossibleThisWeek: Int {
        let calendar = Calendar.current
               let restDaysThisWeek = markedRestDays.isEmpty ? restDays(forWeekStarting: weekStart) : markedRestDays

               return weekDays.reduce(0) { total, day in
                   let normalizedDay = calendar.startOfDay(for: day)
                   guard !restDaysThisWeek.contains(normalizedDay) else { return total }
                   return total + activeHabitCount(on: normalizedDay)
               }
    }

    private func totalPossible(inWeekStarting start: Date) -> Int {
        let calendar = Calendar.current
              let normalizedStart = calendar.startOfDay(for: start)
              let restDaysInWeek = restDays(forWeekStarting: normalizedStart)

              return (0..<7).reduce(0) { total, offset in
                  guard let day = calendar.date(byAdding: .day, value: offset, to: normalizedStart) else { return total }
                  let normalizedDay = calendar.startOfDay(for: day)
                  guard !restDaysInWeek.contains(normalizedDay) else { return total }
                  return total + activeHabitCount(on: normalizedDay)
              }
    }
    
    private func debugSnapshotData(for date: Date) {
        let calendar = Calendar.current
        let dayCompletions = allCompletions.filter {
            calendar.isDate($0.completedAt, inSameDayAs: date)
        }
        
        print("📊 Snapshot Debug for \(date.formatted(date: .abbreviated, time: .omitted)):")
        print("   Total completions: \(dayCompletions.count)")
        
        let snapshots = dayCompletions.compactMap { $0.snapshotActiveHabitsCount }
        if !snapshots.isEmpty {
            print("   Snapshot values: \(snapshots)")
            print("   Using max: \(snapshots.max() ?? 0)")
        } else {
            print("   ⚠️ No snapshot data found (old completions)")
        }
    }
    
    // MARK: - Add helpers
    
    private var weekCompletions: [HabitCompletion] {
        let restDaysThisWeek = markedRestDays.isEmpty ? restDays(forWeekStarting: weekStart) : markedRestDays
               return completions(inWeekStarting: weekStart, restDaysOverride: restDaysThisWeek)
           }

    private func completions(inWeekStarting start: Date, restDaysOverride: Set<Date>? = nil) -> [HabitCompletion] {
           let calendar = Calendar.current
           let normalizedStart = calendar.startOfDay(for: start)
           let endExclusive = calendar.date(byAdding: .day, value: 7, to: normalizedStart) ?? normalizedStart
           let restDaysToUse = restDaysOverride ?? restDays(forWeekStarting: normalizedStart)

           return allCompletions.filter { completion in
               let completionDate = completion.completedAt
               guard completionDate >= normalizedStart && completionDate < endExclusive else { return false }
               let completionDay = calendar.startOfDay(for: completionDate)
               return !restDaysToUse.contains(completionDay)
        }
    }

    private var weekFavorites: [HabitCompletion] {
        weekCompletions.filter { $0.reflection?.isFavorite == true }
    }

    private var currentWeekRate: Double {
        let restOverride = markedRestDays.isEmpty ? nil : markedRestDays
        return weeklyRate(forWeekStarting: weekStart, markedRestDays: restOverride)
    }
    
    // MARK: - Previous Week Rate (matches currentWeekRate logic)

    private var prevWeekRate: Double {
        guard let lastWeekStart = Calendar.current.date(
            byAdding: .weekOfYear,
            value: -1,
            to: weekStart
        ) else {
            return 0
        }

        // We usually don’t override rest days for last week,
        // just let weeklyRate() derive them from reflections.
        return weeklyRate(forWeekStarting: lastWeekStart)
    }

         //   Perfect day counting with unique completions
         private var perfectDaysCount: Int {
             let calendar = Calendar.current
             let restDaysThisWeek = markedRestDays.isEmpty ? restDays(forWeekStarting: weekStart) : markedRestDays

             return weekDays.filter { day in
                 let normalizedDay = calendar.startOfDay(for: day)
                 guard !restDaysThisWeek.contains(normalizedDay) else { return false }
                 
                 let dayCompletions = completionsFor(normalizedDay)

                 // Only count scheduled completions
                 let scheduledCompletions = dayCompletions.filter { completion in
                     if let wasScheduled = completion.wasScheduledForDay {
                         return wasScheduled
                     }
                     // Legacy completions: assume scheduled
                     return true
                 }

                 // Count unique scheduled habits completed
                 let uniqueScheduled = Set(scheduledCompletions.map { $0.habitId }).count
                 guard uniqueScheduled > 0 else { return false }

                 // Get active habit count (snapshot-based)
                 let activeCount = activeHabitCount(on: normalizedDay)
                 guard activeCount > 0 else { return false }

                 // Perfect day = all *scheduled* habits completed
                 return uniqueScheduled == activeCount
             }.count
         }
    
    private var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        while true {
            let dayCompletions = allCompletions.filter { Calendar.current.isDate($0.completedAt, inSameDayAs: date) }
            if dayCompletions.isEmpty { break }
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }

    // Uses allCompletions for better flexibility and safety
    private func completionsFor(_ day: Date) -> [HabitCompletion] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: day)
        
        return allCompletions.filter { completion in
            let completionDay = calendar.startOfDay(for: completion.completedAt)
            return completionDay == targetDay
        }
    }
    
    // MARK: - Weekly rate based on unique daily completions

    private func weeklyRate(forWeekStarting start: Date,
                            markedRestDays overrideRestDays: Set<Date>? = nil) -> Double {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        let endExclusive = calendar.date(byAdding: .day, value: 7, to: normalizedStart) ?? normalizedStart
        
        let restDaysThisWeek = overrideRestDays ?? restDays(forWeekStarting: normalizedStart)
        
        var completedSlots = 0
        var possibleSlots  = 0
        
        for day in weekDays {
            let normalizedDay = calendar.startOfDay(for: day)
            
            guard normalizedDay >= normalizedStart,
                  normalizedDay < endExclusive,
                  !restDaysThisWeek.contains(normalizedDay) else {
                continue
            }
            
            //   Use activeHabitCount() which already has snapshot-based logic
            let activeCount = activeHabitCount(on: normalizedDay)
            guard activeCount > 0 else { continue }
            
            possibleSlots += activeCount
            
            //   Get completions and count unique *scheduled* habit IDs
            let dayCompletions = completionsFor(normalizedDay)

            // Only count scheduled completions.
            // For legacy entries where wasScheduledForDay is nil, treat them as scheduled
            // so old weeks don't suddenly drop in percentage.
            let scheduledCompletions = dayCompletions.filter { completion in
                if let wasScheduled = completion.wasScheduledForDay {
                    return wasScheduled
                }
                return true
            }

            let uniqueScheduled = Set(scheduledCompletions.map { $0.habitId }).count

            // Cap at activeCount (can't complete more than existed)
            completedSlots += min(uniqueScheduled, activeCount)
        }
        
        guard possibleSlots > 0 else { return 0 }
        
        // Explicitly cap at 1.0 (100%)
        return min(1.0, Double(completedSlots) / Double(possibleSlots))
    }

    
    // MARK: - Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // 1. Week Navigator
                weekNavigatorSection
                    .padding(.top, 8)

                VStack(spacing: 14) {

                    // 2. Weekly Summary
                    weeklySummarySection
                        .padding(.horizontal, 24)

                    // 3. Active Challenges (only shows when active)
                    if hasMiniChallenge || hasProject50 || hasThemeWeek {
                        activeChallengesSection
                            .padding(.horizontal, 24)
                    }
                    // 6. Insights
                    insightsSection
                    // 3. Daily Intentions
                    dailyIntentionsCard

                    // 4. Daily Breakdown
                    dailyBreakdownSection

                    // 5. Focus This Week (always visible)
                    weeklyFocusCard

                }
                .padding(.bottom, 100)
            }
        }
        .overlay(alignment: .top) {
                  if showMiniChallengeCelebration {
                      ChallengeCelebrationBanner(
                          title: celebrationTitle,
                          subtitle: celebrationSubtitle,
                          accent: celebrationAccent,
                          iconName: celebrationIcon
                      )
                      .padding(.horizontal, 24)
                      .padding(.top, 20)
                      .transition(.move(edge: .top).combined(with: .opacity))
                      .allowsHitTesting(false)
                  }
              }
              .overlay {
                  if showMiniChallengeCelebration {
                      ConfettiView(isActive: .constant(true))
                          .allowsHitTesting(false)
                          .transition(.opacity)
                  }
              }
              .overlay {
                  if showThemeWeekCelebration {
                      ChallengeCelebrationBanner(
                          title: celebrationTitle,
                          subtitle: celebrationSubtitle,
                          accent: celebrationAccent,
                          iconName: celebrationIcon
                      )
                      .padding(.horizontal, 24)
                      .padding(.top, 20)
                      .transition(.move(edge: .top).combined(with: .opacity))
                      .allowsHitTesting(false)
                  }
              }
              .overlay {
                  if showThemeWeekCelebration {
                      ConfettiView(isActive: .constant(true))
                          .allowsHitTesting(false)
                          .transition(.opacity)
                  }
              }
        .refreshable { await refreshData() }
        .onAppear {
            loadRestDays()
            
            //   Auto-check ALL active mini challenges on appear (using rest-day-aware expiration)
            for progress in activeMiniChallenges {
                let beforeCount = progress.daysCompleted
                progress.checkAndUpdateProgress(completions: allCompletions, reflections: reflections)
                handleMiniChallengeProgressCompletionCheck(for: progress, beforeCount: beforeCount)
            }
            
            // Check for completed challenges to celebrate
            if let completedProgress = allMiniChallengeProgress.first(where: { canCelebrateMiniChallenge($0) }) {
                triggerMiniChallengeCelebration(with: completedProgress)
            }
            
            // Check for completed Theme Weeks to celebrate
                if let completedThemeWeek = allThemeWeekProgress.first(where: { canCelebrateThemeWeek($0) }) {
                    triggerThemeWeekCelebration(with: completedThemeWeek)
                }

            // Refresh Project 50 progress on appear
            progressManager.refreshEligibility()
        }
        .onChange(of: weekStart) { _, _ in
                 loadRestDays()
             }
             .onChange(of: reflectionsRestDaySignatureForCurrentWeek) { _, _ in
                 loadRestDays()
             }
        
             .onChange(of: allCompletions.count) { oldValue, newValue in
                 //   Update ALL active mini challenges, not just one (using rest-day-aware expiration)
                 for progress in activeMiniChallenges {
                     let beforeCount = progress.daysCompleted
                     progress.checkAndUpdateProgress(completions: allCompletions, reflections: reflections)
                     handleMiniChallengeProgressCompletionCheck(for: progress, beforeCount: beforeCount)
                 }
                 
                 // Check Theme Week completion
                 for themeWeekProgress in activeThemeWeeks {
                     if themeWeekProgress.isCompleted && canCelebrateThemeWeek(themeWeekProgress) {
                         triggerThemeWeekCelebration(with: themeWeekProgress)
                     }
                 }
                 
                 // Refresh Project 50 progress
                 let oldLevel = progressManager.journey.currentLevel
                 progressManager.refreshEligibility()
                 let newLevelValue = progressManager.journey.currentLevel
                 
                 // Trigger celebration when leveling up
                 if newLevelValue > oldLevel && oldValue < newValue {
                     checkProject50LevelUp(newLevel: newLevelValue)
                 }
             }

        .onReceive(NotificationCenter.default.publisher(for: miniChallengeCompletedNotification)) { notification in
                  guard let progress = notification.object as? MiniChallengeProgress else { return }
                  triggerMiniChallengeCelebration(with: progress)
              }
    }


    // MARK: - 1. Week Navigator Section
    
    @ViewBuilder
    private var weekNavigatorSection: some View {
        HStack(spacing: 8) {
            Text(weekHeaderTitle)
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Spacer()
        }
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .simultaneousGesture(longPressGesture)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentDate)
        .sheet(isPresented: $showWeekPicker) {
            WeekCalendarSheet(currentDate: $currentDate)
            // Compact 50% height
                .presentationDetents([.fraction(0.5)])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showReflectionPrompt) {
            ChallengeReflectionPromptSheet(
                challenge: reflectionPromptChallenge,
                challengeTag: reflectionPromptChallengeTag,
                onDismiss: { showReflectionPrompt = false }
            )
            .presentationDetents([.fraction(0.45)])
            .presentationCornerRadius(28)
            .presentationDragIndicator(.visible)
        }
    }

    private var weekHeaderTitle: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: weekStart)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startStr = formatter.string(from: weekStart)
        let endStr = formatter.string(from: weekEnd)

        return "Week \(weekOfYear): \(startStr) - \(endStr)"
    }

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var hasTriggeredHaptic = false

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation.width
                if abs(dragOffset) > 40, !hasTriggeredHaptic {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    hasTriggeredHaptic = true
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if value.translation.width > 50 {
                        navigateToPreviousWeek()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else if value.translation.width < -50 {
                        if canNavigateToNextWeek {
                            navigateToNextWeek()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } else {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    dragOffset = 0
                    isDragging = false
                    hasTriggeredHaptic = false
                }
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showWeekPicker = true
            }
    }

    private func navigateToPreviousWeek() {
        currentDate = Calendar.current.date(byAdding: .day, value: -7, to: currentDate) ?? currentDate
    }

    private func navigateToNextWeek() {
        guard canNavigateToNextWeek else { return }
        currentDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
    }

    private var canNavigateToNextWeek: Bool {
        let cal = Calendar.current
        let thisWeek = cal.component(.weekOfYear, from: Date())
        let nextWeek = cal.component(.weekOfYear, from: cal.date(byAdding: .weekOfYear, value: 1, to: weekStart)!)
        return nextWeek <= thisWeek
    }


    // MARK: - Week Calendar Sheet
    
    @ViewBuilder
    private var weekCalendarSheet: some View {
        WeekCalendarSheet(currentDate: $currentDate)
            .interactiveDismissDisabled(false)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - 2. Weekly Summary Section
    
    @ViewBuilder
    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Weekly Summary")
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
            }

            HStack(spacing: 20) {
                StatColumn(value: "\(threadsWoven)", label: "Threads Woven", color: .sageGreen)
                StatColumn(value: "\(completionPercentage)%", label: "Completion", color: .dustyBlue)
                StatColumn(value: "\(weekFavorites.count)", label: "Favorites", color: .terracottaRose)
            }
            .padding(.top, 4)

            // Progress Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.dynamicSecondaryLabel.opacity(0.15))

                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.sageGreen, .dustyBlue, .terracottaRose],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .mask(
                        GeometryReader { geo in
                            Rectangle()
                                .frame(width: geo.size.width * progress)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                        }
                    )
            }
            .frame(height: 6)

            // Comparison vs Last Week or Encouragement
            if let comparison = weekComparison {
                HStack(spacing: 4) {
                    Image(systemName: comparison.isImprovement ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(comparison.isImprovement ? Color.sageGreen : Color.terracottaRose)
                    Text("\(abs(comparison.difference))% vs last week")
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .slide))
            } else if let encouragement = weekEncouragement {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .medium))
                    Text(encouragement)
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .slide))
            }
            
            #if DEBUG  && false
            // Debug info - only in debug mode
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug Info:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)
                Text("Unique completions: \(uniqueWeekCompletionsCount)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Total possible: \(totalPossibleThisWeek)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Rate: \(String(format: "%.1f", currentWeekRate * 100))%")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            #endif
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: completionPercentage)
    }

    // Count unique scheduled completions only
    private var uniqueWeekCompletionsCount: Int {
        let calendar = Calendar.current
        let restDaysThisWeek = markedRestDays.isEmpty ? restDays(forWeekStarting: weekStart) : markedRestDays
        
        var uniqueCount = 0
        
        for day in weekDays {
            let normalizedDay = calendar.startOfDay(for: day)
            guard !restDaysThisWeek.contains(normalizedDay) else { continue }
            
            let dayCompletions = completionsFor(normalizedDay)
            
            // Only count scheduled completions
            let scheduledCompletions = dayCompletions.filter { completion in
                completion.wasScheduledForDay ?? true
            }
            
            // Count unique habit IDs for this day
            let uniqueHabits = Set(scheduledCompletions.map { $0.habitId })
            let activeCount = activeHabitCount(on: normalizedDay)
            
            // Cap at active count (can't complete more than existed)
            uniqueCount += min(uniqueHabits.count, activeCount)
        }
        
        return uniqueCount
    }
    
    private var threadsWoven: Int {
        uniqueWeekCompletionsCount
    }

    private var totalHabitsCount: Int { totalPossibleThisWeek }

    private var completionPercentage: Int {
        Int((currentWeekRate * 100).rounded())
    }

    private var progress: CGFloat {
        CGFloat(currentWeekRate)
     }

    // MARK: - Week comparison

    private var weekComparison: (isImprovement: Bool, difference: Int)? {
        guard shouldShowWeekComparison else { return nil }
        
        let current = Int((currentWeekRate * 100).rounded())
        let previous = Int((prevWeekRate * 100).rounded())
        let diff = current - previous
        
        guard abs(diff) >= 3 else { return nil }
        
        return (isImprovement: diff > 0, difference: abs(diff))
    }

    // MARK: - Week context

    private var isCurrentWeek: Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        guard let currentWeekStart = cal.date(
            from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) else {
            return false
        }
        
        return cal.isDate(weekStart, inSameDayAs: currentWeekStart)
    }

    private var daysIntoWeek: Int {
        guard isCurrentWeek else { return 7 }
        let cal = Calendar.current
        let comps = cal.dateComponents([.day], from: weekStart, to: Date())
        return max(0, min(6, comps.day ?? 0))
    }

    // Show comparison only when the week is "mature" enough
    private var shouldShowWeekComparison: Bool {
        // Always show for past weeks – they're finished snapshots
        if !isCurrentWeek { return true }
        if daysIntoWeek >= 4 { return true }
        if currentWeekRate >= 0.6 { return true }
        
        return false
    }

    private var weekEncouragement: String? {
        guard isCurrentWeek else { return nil }
        
        switch (daysIntoWeek, currentWeekRate) {
        case (0...1, _):
            return "New week, gentle start. One or two tiny wins is enough today.✨"
        case (2...3, let rate) where rate < 0.3:
            return "You’ve started weaving a few threads — there’s still plenty of week left to add more."
        case (2...3, let rate) where rate < 0.6:
            return "Nice momentum. Keep habits small and finishable so your brain actually wants to come back."
        default:
            return nil
        }
    }

    // MARK: - 3. Active/Mini Challenges Section
    
        @ViewBuilder
        private var activeChallengesSection: some View {
            VStack(alignment: .leading, spacing: 20) {

                ForEach(Array(activeMiniChallenges.enumerated()), id: \.element.id) { index, progress in
                    miniChallengeRow(index: index, progress: progress)
                }

                // Divider between Mini Challenges and Project 50
                if hasMiniChallenge && hasProject50 {
                    Divider()
                        .padding(.horizontal, 2)
                }

                // Project 50 section
                if hasProject50 {
                    project50Content
                }
                
                if hasProject50 && hasThemeWeek {
                    Divider()
                        .padding(.horizontal, 2)
                }
                     
                // Divider between Mini Challenge and Theme Week (if no Project 50)
                if hasMiniChallenge && !hasProject50 && hasThemeWeek {
                    Divider()
                        .padding(.horizontal, 2)
                }

                if hasThemeWeek {
                    themeWeekContent
                }
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }

        @ViewBuilder
        private func miniChallengeRow(index: Int, progress: MiniChallengeProgress) -> some View {
            if let challenge = MiniChallengeData.challenges.first(where: {
                $0.id == progress.challengeID || $0.tag == progress.challengeTag
            }) {
                
                let miniChallengeDaysCompleted = progress.daysCompleted
                let todayMiniChallengeComplete = progress.isTodayChallengeComplete(completions: allCompletions)
                let isExpired = progress.isExpired(reflections: reflections)  // Use rest-day-aware version
                
                VStack(spacing: 16) {
                    miniChallengeContent(
                        challenge,
                        miniChallengeDaysCompleted: miniChallengeDaysCompleted,
                        todayMiniChallengeComplete: todayMiniChallengeComplete,
                        isExpired: isExpired
                    )
                    
                    if index < activeMiniChallenges.count - 1 {
                        Divider()
                            .padding(.horizontal, 2)
                    }
                }
            }
        }

    // MARK: - Mini Challenge Content
    
    @ViewBuilder
    private func miniChallengeContent(
        _ challenge: MiniChallenge,
        miniChallengeDaysCompleted: Int,
        todayMiniChallengeComplete: Bool,
        isExpired: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: challenge.icon)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: challenge.colorHex))
                Text(challenge.title)
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
            }

            // Seven-day progress dots (reads from progress.daysCompleted)
            HStack(spacing: 10) {
                ForEach(1...7, id: \.self) { day in
                    Circle()
                        .fill(
                            day <= miniChallengeDaysCompleted
                            ? Color(hex: challenge.colorHex)
                            : Color.dynamicSecondaryLabel.opacity(0.15)
                        )
                        .frame(width: 20, height: 20)
                        .overlay(
                            Group {
                                if day <= miniChallengeDaysCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                } else {
                                    Text("\(day)")
                                        .font(.system(size: 12, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                            }
                        )
                }
            }

            // Status message (reactive to progress state)
            HStack(spacing: 6) {
                if isExpired {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.terracottaRose)
                    Text("Challenge expired – restart to try again")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.terracottaRose)
                } else if miniChallengeDaysCompleted >= 7 {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sageGreen)
                    Text("Challenge complete!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.sageGreen)
                } else if todayMiniChallengeComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sageGreen)
                    Text("Today complete – keep going tomorrow")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    Text("Complete all habits today")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var project50Content: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.dustyBlue)
                Text("Project 50")
                    .font(.system(size: 13, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
                Text("Level \(progressManager.journey.currentLevel)")
                    .font(.system(size: 12, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dynamicSecondaryLabel.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.dustyBlue, Color.paleMauve],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * currentProject50Completion)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentProject50Completion)
                }
            }
            .frame(height: 8)

            HStack(spacing: 6) {
                Text("\(Int(currentProject50Completion * 100))% complete")
                    .font(.system(size: 12, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                if let nextLevel = nextUnlockLevel {
                    Text("·")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    Text("\(daysUntilNextLevel) days to Level \(nextLevel)")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
        }
    }
    
    // MARK: - Theme Week Section

    @ViewBuilder
    private var themeWeekContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "C8B8DB"))
                
                Text(activeThemeWeeks.first?.programTitle ?? "Theme Week")
                    .font(.system(size: 13, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Spacer()
                
                if let progress = activeThemeWeeks.first {
                    Text("Day \(progress.currentDayNumber)/7")
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
            }
            
            // Adaptation line + compact dot strip
            if let progress = activeThemeWeeks.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        let adaptationStyle = getThemeWeekAdaptationStyle(progress)
                        Text(adaptationStyle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.dynamicLabel)
                    }
                    
                    themeWeekProgressStrip(for: progress)
                }
            } else {
                // Not started yet
                HStack(spacing: 6) {
                    Text("Begin your gentle rhythm")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.dynamicLabel)
                }
            }
        }
    }

    // MARK: - Compact Progress Strip

    @ViewBuilder
    private func themeWeekProgressStrip(for progress: ThemeWeekProgress) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(1...7, id: \.self) { day in
                    Text(themeWeekDayLabel(for: day))
                        .font(.system(size: 11, weight: .semibold))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .frame(maxWidth: .infinity)
                }
            }
            
            HStack(spacing: 0) {
                ForEach(1...7, id: \.self) { day in
                    ZStack {
                        Circle()
                            .fill(themeWeekDotColor(for: day, progress: progress))
                            .frame(
                                width: themeWeekDotSize(for: day, progress: progress),
                                height: themeWeekDotSize(for: day, progress: progress)
                            )
                        
                        // Show tier icon for completed days (same as detail view)
                        if let tier = progress.tier(for: day) {
                            Image(systemName: themeWeekTierIcon(for: tier))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Helpers for Archive Theme Week Strip

    private func themeWeekDayLabel(for day: Int) -> String {
        ["D1", "D2", "D3", "D4", "D5", "D6", "D7"][day - 1]
    }

    private func themeWeekDotColor(for day: Int, progress: ThemeWeekProgress) -> Color {
        let accent = Color(hex: "C8B8DB")
        
        // Use rest-day-aware current day
        let currentDay = progress.currentScheduledDay(reflections: reflections)
        
        if progress.tier(for: day) != nil {
            return accent
        } else if day == currentDay {
            return accent.opacity(0.5)
        } else if day < currentDay {
            return Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.2)
        } else {
            return Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.1)
        }
    }

    private func themeWeekDotSize(for day: Int, progress: ThemeWeekProgress) -> CGFloat {
        // Use rest-day-aware current day
        let currentDay = progress.currentScheduledDay(reflections: reflections)
        return day == currentDay ? 18 : 14
    }

    private func themeWeekTierIcon(for tier: CompletionTier) -> String {
        switch tier {
        case .seed:   return "leaf.fill"
        case .sprout: return "leaf.circle.fill"
        case .bloom:  return "sparkles"
        }
    }

    private func getThemeWeekAdaptationStyle(_ progress: ThemeWeekProgress) -> String {
        let currentDay = progress.currentDayNumber
        
        guard currentDay > 0 && progress.daysCompleted > 0 else {
            return "Begin your gentle rhythm"
        }
        
        // Check tier variety
        let hasSeed = progress.seedCount > 0
        let hasSprout = progress.sproutCount > 0
        let hasBloom = progress.bloomCount > 0
        let tierVariety = [hasSeed, hasSprout, hasBloom].filter { $0 }.count
        
        if tierVariety == 3 {
            return "Flexible adaptation in action"
        } else if tierVariety == 2 {
            return "Finding your natural rhythm"
        } else if progress.bloomCount == progress.daysCompleted {
            return "Thriving with full blooms"
        } else if progress.sproutCount == progress.daysCompleted {
            return "Steady, sustainable growth"
        } else if progress.seedCount == progress.daysCompleted {
            return "Honoring your energy wisely"
        } else {
            return "Weaving your gentle week"
        }
    }

    private var hasMiniChallenge: Bool {
        !activeMiniChallenges.isEmpty
    }

    private var hasProject50: Bool {
        habits.contains { habit in
            guard let tag = habit.programTag else { return false }
            return tag == "P50"
        }
    }

    private var activeMiniChallenge: MiniChallenge? {
        //   Get mini challenge from actual progress data, not Project 50 journey
        guard let progress = activeMiniChallenges.first else { return nil }
        return MiniChallengeData.challenges.first {
            $0.id == progress.challengeID || $0.tag == progress.challengeTag
        }
    }

    private var miniChallengeProgress: MiniChallengeProgress? {
        activeMiniChallenges.first
    }

    private var miniChallengeDaysCompleted: Int {
        miniChallengeProgress?.daysCompleted ?? 0
    }

    private func handleMiniChallengeProgressCompletionCheck(
          for progress: MiniChallengeProgress,
          beforeCount: Int
      ) {
          let afterCount = progress.daysCompleted

          if beforeCount != afterCount {
              try? modelContext.save()

              if progress.isCompleted && afterCount >= progress.targetDays {
                  triggerMiniChallengeCelebration(with: progress)
              }
          } else {
              if canCelebrateMiniChallenge(progress) {
                  triggerMiniChallengeCelebration(with: progress)
              }
          }
      }

      private func canCelebrateMiniChallenge(_ progress: MiniChallengeProgress) -> Bool {
          // ✅ Check if challenge is complete
          guard progress.isCompleted,
                progress.daysCompleted >= progress.targetDays else { return false }

          // ✅ Check if we've already celebrated this challenge
          // Use UserDefaults to persist celebration state across app sessions
          let celebrationKey = "celebrated_mini_challenge_\(progress.id.uuidString)"
          if UserDefaults.standard.bool(forKey: celebrationKey) {
              return false
          }

          // ✅ Only celebrate within 24 hours of completion
          if let completedDate = progress.completedDate {
              return Date().timeIntervalSince(completedDate) < 60 * 60 * 24
          }

          return true
      }

      private func triggerMiniChallengeCelebration(with progress: MiniChallengeProgress) {
          guard canCelebrateMiniChallenge(progress) else { return }

          let challenge = MiniChallengeData.challenges.first {
              $0.tag == progress.challengeTag || $0.id == progress.challengeID
          }

          celebrationTitle = "\(challenge?.title ?? progress.challengeTitle) Complete!"
          celebrationSubtitle = "\(progress.targetDays)/\(progress.targetDays) days woven in \(progress.challengeTitle). Momentum unlocked."
          celebrationAccent = challenge.map { Color(hex: $0.colorHex) } ?? .sageGreen
          celebrationIcon = challenge?.icon ?? "bolt.fill"

          let celebrationKey = "celebrated_mini_challenge_\(progress.id.uuidString)"
          UserDefaults.standard.set(true, forKey: celebrationKey)

          lastCelebratedChallengeID = progress.id

          // Store challenge info for reflection prompt
          reflectionPromptChallenge = challenge
          reflectionPromptChallengeTag = progress.challengeTag

          withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
              showMiniChallengeCelebration = true
          }

          UIImpactFeedbackGenerator(style: .medium).impactOccurred()

          DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
              withAnimation(.easeOut(duration: 0.3)) {
                  showMiniChallengeCelebration = false
              }

              // Show reflection prompt after celebration banner dismisses
              // Only if user hasn't already been prompted for this challenge
              let reflectionPromptKey = "reflection_prompted_\(progress.challengeTag)"
              if !UserDefaults.standard.bool(forKey: reflectionPromptKey) {
                  // Check no other celebrations are active
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                      if !showThemeWeekCelebration && !showProject50LevelUp {
                          UserDefaults.standard.set(true, forKey: reflectionPromptKey)
                          showReflectionPrompt = true
                      }
                  }
              }
          }
      }
    
    // MARK: - Theme Week Celebration

    private func triggerThemeWeekCelebration(with progress: ThemeWeekProgress) {
        guard canCelebrateThemeWeek(progress) else { return }
        
        // Find the program data
        let program = ThemeWeekData.programs.first {
            $0.tag == progress.programTag
        }
        
        // Calculate points
        let totalPoints = progress.completionRecords.reduce(0) { $0 + $1.tier.points }
        
        celebrationTitle = "\(program?.title ?? progress.programTitle) Complete!"
        celebrationSubtitle = "\(totalPoints)/21 points earned · \(progress.daysCompleted) days woven"
        celebrationAccent = program.map { Color(hex: $0.colorHex) } ?? Color(hex: "C8B8DB")
        celebrationIcon = "moon.stars.fill"
        
        let celebrationKey = "celebrated_theme_week_\(progress.id.uuidString)"
        UserDefaults.standard.set(true, forKey: celebrationKey)
        
        lastCelebratedThemeWeekID = progress.id
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            showThemeWeekCelebration = true
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showThemeWeekCelebration = false
            }
        }
    }

    private func canCelebrateThemeWeek(_ progress: ThemeWeekProgress) -> Bool {
        guard progress.isCompleted,
              progress.daysCompleted >= 7 else { return false }
        
        let celebrationKey = "celebrated_theme_week_\(progress.id.uuidString)"
        if UserDefaults.standard.bool(forKey: celebrationKey) {
            return false
        }
        
        if let completedDate = progress.completedDate {
            return Date().timeIntervalSince(completedDate) < 60 * 60 * 24
        }
        
        return true
    }
    
    private var miniChallengeHabits: [Habit] {
        habits.filter { $0.programTag?.starts(with: "C7-") == true }
    }

    private var todayMiniChallengeComplete: Bool {
        let today = Date()
        let todayCompletions = allCompletions.filter {
            Calendar.current.isDate($0.completedAt, inSameDayAs: today)
        }
        return miniChallengeHabits.allSatisfy { habit in
            todayCompletions.contains { $0.habitId == habit.id }
        }
    }

    // Calculate Project 50 completion in real-time based on current data
    // This ensures the UI always reflects the latest completion state
    private var currentProject50Completion: Double {
        let currentLevel = progressManager.journey.currentLevel
        guard let levelStartDate = progressManager.journey.levelStartDates[currentLevel] else {
            return 0.0
        }
        
        // Get P50 habits for current level
        let levelHabits = habits.filter { habit in
            guard let tag = habit.programTag else { return false }
            return tag == "P50" && habit.programLevel == currentLevel
        }
        
        let activeHabitsCount = levelHabits.count
        guard activeHabitsCount > 0 else { return 0.0 }
        
        // Calculate elapsed days and cap based on level
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: levelStartDate, to: Date()).day ?? 0
        
        let daysCap: Int
        switch currentLevel {
        case 1: daysCap = 21
        case 2: daysCap = 29
        case 3: daysCap = 29
        default: daysCap = 21
        }
        
        let daysSinceLevelStartCapped = min(max(daysSinceStart, 1), daysCap)
        
        // Get relevant completions for these habits SINCE LEVEL START
        // CRITICAL FIX: Use levelStartDate as window start, not a rolling window
        let habitIds = Set(levelHabits.map { $0.id })
        
        let relevantCompletions = allCompletions.filter { completion in
            habitIds.contains(completion.habitId) &&
            completion.completedAt >= levelStartDate &&
            completion.completedAt <= Date()
        }
        
        // Group by day and count successful days (≥80% of UNIQUE habits completed)
        let groupedByDay = Dictionary(grouping: relevantCompletions) { completion in
            calendar.startOfDay(for: completion.completedAt)
        }
        
        //   Count unique habits per day, not total completions
        let successfulDays = groupedByDay.values.filter { dayCompletions in
            let uniqueHabits = Set(dayCompletions.map { $0.habitId }).count
            return uniqueHabits >= Int(Double(activeHabitsCount) * 0.80)
        }.count
        
        // Calculate completion: successful days / total days required
        let completion = Double(successfulDays) / Double(daysCap)
        
        #if DEBUG
        print("📊 [Project50] Level \(currentLevel) Progress:")
        print("   - Level Start: \(levelStartDate)")
        print("   - Days Since Start: \(daysSinceStart) (capped: \(daysSinceLevelStartCapped))")
        print("   - Active Habits: \(activeHabitsCount)")
        print("   - Total Completions: \(relevantCompletions.count)")
        print("   - Successful Days: \(successfulDays)/\(daysCap)")
        print("   - Completion: \(Int(completion * 100))%")
        #endif
        
        return min(max(completion, 0.0), 1.0)
    }

    private var nextUnlockLevel: Int? {
        let level = progressManager.journey.currentLevel
        if level == 1 && !progressManager.journey.unlockedLevels.contains(2) { return 2 }
        if level == 2 && !progressManager.journey.unlockedLevels.contains(3) { return 3 }
        return nil
    }

    private var daysUntilNextLevel: Int {
        let days = progressManager.daysSinceStart
        if nextUnlockLevel == 2 { return max(0, 21 - days) }
        if nextUnlockLevel == 3 { return max(0, 50 - days) }
        return 0
    }

    // MARK: - Daily Intentions Card
       private var dailyIntentionsCard: some View {
           let weekIntentions = intentions.filter { intention in
               weekDays.contains { Calendar.current.isDate(intention.date, inSameDayAs: $0) }
           }.sorted { $0.date < $1.date }

           let todayIntention = weekIntentions.first { Calendar.current.isDateInToday($0.date) }
           let otherIntentions = weekIntentions.filter { !Calendar.current.isDateInToday($0.date) }

           return VStack(spacing: 12) {
               HStack {
                   Text("Daily Intentions")
                       .font(.system(size: 13, weight: .regular))
                       .fontDesign(.serif)
                       .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                   Spacer()

                   if !otherIntentions.isEmpty {
                       Button {
                           withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                               showAllIntentions.toggle()
                           }
                       } label: {
                           HStack(spacing: 4) {
                               Text(showAllIntentions ? "Less" : "All")
                                   .font(.system(size: 12, weight: .medium))
                                   .foregroundStyle(Color.sageGreen)

                               Image(systemName: showAllIntentions ? "chevron.up" : "chevron.down")
                                   .font(.system(size: 11))
                                   .foregroundStyle(Color.sageGreen)
                           }
                       }
                   }
               }
               .frame(maxWidth: .infinity, alignment: .leading)

               if weekIntentions.isEmpty {
                   Text("No intentions set this week")
                       .font(.system(size: 13, weight: .regular))
                       .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                       .frame(maxWidth: .infinity)
                       .padding(.vertical, 16)
               } else {
                   VStack(spacing: 8) {
                       if let today = todayIntention {
                           CompactIntentionRow(intention: today, isToday: true)
                       }

                       if showAllIntentions {
                           ForEach(otherIntentions, id: \.id) { intention in
                               CompactIntentionRow(intention: intention, isToday: false)
                           }
                       } else if !otherIntentions.isEmpty {
                           HStack(spacing: 6) {
                               Image(systemName: "ellipsis")
                                   .font(.system(size: 11))
                                   .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                               Text("\(otherIntentions.count) more")
                                   .font(.system(size: 12, weight: .regular))
                                   .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                           }
                           .frame(maxWidth: .infinity)
                           .padding(.vertical, 6)
                       }
                   }
               }
           }
           .padding(16)
           .reverieCardStyle(colorScheme: colorScheme)
           .padding(.horizontal)
       }

    //MARK: Weekly Focus
    private var weeklyFocusCard: some View {
            let weekPomodoros = pomodoroSessions.filter { session in
                weekDays.contains { Calendar.current.isDate(session.completedAt, inSameDayAs: $0) }
                    && session.sessionType == "work"
            }

            let totalMinutes = weekPomodoros.reduce(0) { $0 + $1.duration }
            let totalHours = Double(totalMinutes) / 60.0

            let categoryBreakdown = Dictionary(grouping: weekPomodoros) {
                $0.focusCategory
            }.mapValues { sessions in
                sessions.reduce(0) { $0 + $1.duration }
            }.sorted { $0.value > $1.value }

            return VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dustyBlue)

                    Text("Focus This Week")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Spacer()

                    if !weekPomodoros.isEmpty {
                        Text(String(format: "%.1fh", totalHours))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.dustyBlue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if weekPomodoros.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "hourglass.circle")
                            .font(.system(size: 28))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        Text("No focus sessions yet")
                            .font(.system(size: 13, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        Text("Start a Pomodoro to track your focused work")
                            .font(.system(size: 12, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(categoryBreakdown.prefix(3)), id: \.key) { category, minutes in
                            let hours = Double(minutes) / 60.0
                            let percentage = totalMinutes > 0 ? Double(minutes) / Double(totalMinutes) : 0

                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(category.color.opacity(0.15))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: category.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(category.color)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(category.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                        Text(String(format: "%.1f hours • %d sessions", hours, weekPomodoros.filter { $0.focusCategory == category }.count))
                                            .font(.system(size: 12, weight: .regular))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    }

                                    Spacer()

                                    Text("\(Int(percentage * 100))%")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(category.color)
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.dynamicSecondaryBackground)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(category.color)
                                            .frame(width: geometry.size.width * percentage)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }

                    Text("\(weekPomodoros.count) focus sessions • View timeline in Loom")
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .reverieCardStyle(colorScheme: colorScheme)
            .padding(.horizontal)
            .padding(.bottom, 100)
        }

    private func statRow(icon: String, value: Int, unit: String, label: String) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Text("\(value)")
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.terracottaRose)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.terracottaRose.opacity(0.7))
        }
    }

    // MARK: - 5. Insights Section
    
    @ViewBuilder
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.paleMauve)
                Text("Insights")
                    .font(.system(size: 13, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    Spacer(minLength: (UIScreen.main.bounds.width - 240) / 2)
                    ForEach(mergedInsights, id: \.id) { insight in
                        InsightCard(insight: insight, colorScheme: colorScheme)
                            .frame(width: 240)
                    }
                    Spacer(minLength: (UIScreen.main.bounds.width - 240) / 2)
                }
                .padding(.horizontal, 24)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: mergedInsights.count)
    }

    // MARK: Mini Challenge progress insights
    
    private var mergedInsights: [WeeklyInsightHybrid] {
        var insights: [WeeklyInsightHybrid] = []
        let growthRate = Int((currentWeekRate - prevWeekRate) * 100)
        let tone = adaptiveTone()

        if let progress = miniChallengeProgress {
            if progress.isCompleted {
                insights.append(
                    WeeklyInsightHybrid(
                        title: "Challenge Complete ✨",
                        subtitle: progress.challengeTitle,
                        metric: "7/7",
                        message: "You completed the 7-day challenge! This kind of consistency creates lasting transformation.",
                        icon: "bolt.fill",
                        color: .dustyBlue
                    )
                )
            } else if progress.daysCompleted >= 5 {
                let daysLeft = 7 - progress.daysCompleted
                insights.append(
                    WeeklyInsightHybrid(
                        title: "Almost There!",
                        subtitle: "\(progress.daysCompleted)/7 days",
                        metric: "\(daysLeft) left",
                        message: "Your mini challenge is nearly complete! Just \(daysLeft) more day\(daysLeft == 1 ? "" : "s") of consistency.",
                        icon: "bolt.fill",
                        color: .dustyBlue
                    )
                )
            } else if progress.daysCompleted >= 3 {
                insights.append(
                    WeeklyInsightHybrid(
                        title: "Halfway There",
                        subtitle: progress.challengeTitle,
                        metric: "\(progress.daysCompleted)/7",
                        message: "You're building momentum on your challenge. Consistency is showing up in action.",
                        icon: "bolt.fill",
                        color: .dustyBlue
                    )
                )
            }
        }

        // Theme Week Progress insight
            if let themeWeek = activeThemeWeeks.first {
                let totalPoints = themeWeek.completionRecords.reduce(0) { $0 + $1.tier.points }
                let maxPoints = themeWeek.currentDayNumber * 3
                let daysLeft = 7 - themeWeek.currentDayNumber
                
                if themeWeek.daysCompleted >= 5 && !themeWeek.isCompleted {
                    insights.append(
                        WeeklyInsightHybrid(
                            title: "Almost Complete!",
                            subtitle: "\(themeWeek.daysCompleted)/7 days",
                            metric: "\(daysLeft) left",
                            message: "Your Theme Week is nearly complete! Just \(daysLeft) more day\(daysLeft == 1 ? "" : "s") of gentle rhythm.",
                            icon: "moon.stars.fill",
                            color: Color(hex: "C8B8DB")
                        )
                    )
                } else if themeWeek.daysCompleted >= 1 {
                    let tierBreakdown = formatTierBreakdown(
                        seed: themeWeek.seedCount,
                        sprout: themeWeek.sproutCount,
                        bloom: themeWeek.bloomCount
                    )
                    let message = "\(tierBreakdown)\n\n\(getThemeWeekInsightMessage(themeWeek))"
                    
                    insights.append(
                        WeeklyInsightHybrid(
                            title: "Theme Week Progress",
                            subtitle: "\(totalPoints)/\(maxPoints) points so far",
                            metric: "\(themeWeek.daysCompleted)/7",
                            message: message,
                            icon: "moon.stars.fill",
                            color: Color(hex: "C8B8DB")
                        )
                    )
                }
            }
            
            // Theme Week Completion celebration
            if let completedThemeWeek = allThemeWeekProgress.first(where: { progress in
                progress.isCompleted &&
                progress.daysCompleted >= 7 &&
                Calendar.current.isDate(
                    progress.completedDate ?? Date.distantPast,
                    equalTo: Date(),
                    toGranularity: .weekOfYear
                )
            }) {
                let totalPoints = completedThemeWeek.completionRecords.reduce(0) { $0 + $1.tier.points }
                let tierBreakdown = formatTierBreakdown(
                    seed: completedThemeWeek.seedCount,
                    sprout: completedThemeWeek.sproutCount,
                    bloom: completedThemeWeek.bloomCount
                )
                
                insights.append(
                    WeeklyInsightHybrid(
                        title: "Theme Week Complete!",
                        subtitle: "\(totalPoints)/21 points earned",
                        metric: "7/7",
                        message: "\(tierBreakdown)\n\n\(getCompletionMessage(completedThemeWeek))",
                        icon: "sparkles",
                        color: Color(hex: "C8B8DB")
                    )
                )
            }
        
        // Perfect Days insight
        if perfectDaysCount >= 2 {
            insights.append(
                WeeklyInsightHybrid(
                    title: "Perfect Days",
                    subtitle: "\(perfectDaysCount) days this week",
                    metric: "100%",
                    message: tone.perfectDayMessage,
                    icon: "star.fill",
                    color: .sageGreen
                )
            )
        }

        // Growth insight
        if growthRate >= 15 {
            insights.append(
                WeeklyInsightHybrid(
                    title: "Strong Growth",
                    subtitle: "+\(growthRate)% from last week",
                    metric: "↗",
                    message: tone.growthMessage,
                    icon: "arrow.up.right",
                    color: .sageGreen
                )
            )
        }

        // Streak insight
        if currentStreak >= 7 {
            insights.append(
                WeeklyInsightHybrid(
                    title: "\(currentStreak)-Day Streak",
                    subtitle: "Consistency flowing",
                    metric: "🔥",
                    message: tone.streakMessage(for: currentStreak),
                    icon: "flame.fill",
                    color: .terracottaRose
                )
            )
        }

        // Fresh Chapter (new week beginning)
        if Calendar.current.isDate(weekStart, equalTo: Date(), toGranularity: .weekOfYear) {
            insights.append(
                WeeklyInsightHybrid(
                    title: "Fresh Chapter",
                    subtitle: "A new rhythm begins",
                    metric: "✨",
                    message: "It's okay to slow down. Every week restarts your story.",
                    icon: "leaf.fill",
                    color: .sageGreen
                )
            )
        }

        // Default encouragement if empty
        if insights.isEmpty {
            insights.append(
                WeeklyInsightHybrid(
                    title: "Keep Weaving",
                    subtitle: "Your unique journey",
                    metric: "🌙",
                    message: "Each small step weaves the story of who you're becoming.",
                    icon: "moon.stars.fill",
                    color: .paleMauve
                )
            )
        }

        return Array(insights.prefix(3))
    }

    private func adaptiveTone() -> InsightTone {
        if currentWeekRate >= 0.8 { return .celebratory }
        if currentWeekRate >= 0.5 { return .balanced }
        return .gentle
    }
    
    // MARK: - Theme Week Helpers

    private func getThemeWeekInsightMessage(_ progress: ThemeWeekProgress) -> String {
        let seedCount = progress.seedCount
        let sproutCount = progress.sproutCount
        let bloomCount = progress.bloomCount
        let total = progress.daysCompleted
        
        guard total > 0 else {
            return "Begin your gentle rhythm today."
        }
        
        if seedCount == total {
            return "You're honoring your limits. That's wisdom, not failure."
        } else if sproutCount == total {
            return "Steady and sustainable. This is maintainable growth."
        } else if bloomCount == total {
            return "You're thriving! Notice what enables this flourishing."
        }
        
        let tierCount = [seedCount > 0, sproutCount > 0, bloomCount > 0].filter { $0 }.count
        
        if tierCount == 3 {
            return "You're adapting beautifully to your energy. That's true flexibility."
        } else if tierCount == 2 {
            if bloomCount > seedCount && bloomCount > sproutCount {
                return "You're finding your flow with moments of brilliance."
            } else if seedCount > 0 {
                return "You're listening to your needs. That's self-awareness in action."
            } else {
                return "Balanced growth through mindful adaptation."
            }
        }
        
        return "Each day is a step in your gentle journey."
    }

    private func getCompletionMessage(_ progress: ThemeWeekProgress) -> String {
        let seedCount = progress.seedCount
        let sproutCount = progress.sproutCount
        let bloomCount = progress.bloomCount
        
        if bloomCount >= 5 {
            return "You flourished this week! Celebrate this thriving energy."
        } else if sproutCount >= 5 {
            return "Steady consistency carried you through. This is sustainable growth."
        } else if seedCount >= 5 {
            return "You adapted wisely to your energy. Completion is still success."
        } else {
            let tierCount = [seedCount > 0, sproutCount > 0, bloomCount > 0].filter { $0 }.count
            if tierCount == 3 {
                return "You used all three tiers beautifully. That's flexible wisdom."
            } else {
                return "Seven days woven with intention. You showed up."
            }
        }
    }
    
    private func formatTierBreakdown(seed: Int, sprout: Int, bloom: Int) -> String {
        var parts: [String] = []
        
        if seed > 0 {
            parts.append("Seed: \(seed)")
        }
        if sprout > 0 {
            parts.append("Sprout: \(sprout)")
        }
        if bloom > 0 {
            parts.append("Bloom: \(bloom)")
        }
        
        return parts.joined(separator: "  •  ")
    }

    // MARK: - 6. Daily Breakdown Section
    
    @ViewBuilder
    private var dailyBreakdownSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.dustyBlue)
                Text("Daily Breakdown")
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
            }
            .padding(.horizontal, 24)

            ForEach(weekDays, id: \.self) { day in
                DayCard(
                    day: day,
                    habits: habits,
                    completions: allCompletions,
                    reflection: reflections.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }),
                    allReflections: reflections,
                    colorScheme: colorScheme,
                    onSaveReflection: saveReflection(for:text:isRestDay:),
                    onTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if expandedDays.contains(day) {
                                expandedDays.remove(day)
                            } else {
                                expandedDays.insert(day)
                            }
                        }
                    },
                    isExpanded: expandedDays.contains(day)
                )
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Helper Functions
    
    private func loadRestDays() {
        markedRestDays = restDays(forWeekStarting: weekStart)
    }

    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            progressManager.refreshEligibility()
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func saveReflection(for day: Date, text: String, isRestDay: Bool) {
        let calendar = Calendar.current
        let normalizedDay = calendar.startOfDay(for: day)
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("💾 Saving Reflection")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Date: \(normalizedDay.formatted(date: .abbreviated, time: .omitted))")
        print("Text: \"\(text.prefix(50))\(text.count > 50 ? "..." : "")\"")
        print("Rest Day: \(isRestDay)")
        
        // Try to find existing reflection with normalized date comparison
        if let existing = reflections.first(where: {
            calendar.isDate(calendar.startOfDay(for: $0.date), inSameDayAs: normalizedDay)
        }) {
            print("Found existing reflection (ID: \(existing.id))")
            
            // Only update if values actually changed
            let textChanged = existing.text != text
            let restDayChanged = existing.isRestDay != isRestDay
            
            if textChanged || restDayChanged {
                print("Updating: textChanged=\(textChanged), restDayChanged=\(restDayChanged)")
                
                // Validate rest day limit before allowing toggle
                if isRestDay && !existing.isRestDay {
                    
                    let weekday = calendar.component(.weekday, from: normalizedDay)
                    let weekStartsOnSunday = profiles.first?.weekStartsOnSunday ?? true
                    
                    let offset = weekStartsOnSunday ? weekday - 1 : (weekday == 1 ? 6 : weekday - 2)
                    let weekStart = calendar.date(byAdding: .day, value: -offset, to: normalizedDay) ?? normalizedDay
                    
                    // Count existing rest days this week
                    let currentRestDays = restDays(forWeekStarting: weekStart)
                    let limit = profiles.first?.weeklyRestDayLimit ?? 2
                    
                    if currentRestDays.count >= limit {
                        #if DEBUG
                        print("⚠️ Rest day limit reached: \(currentRestDays.count)/\(limit)")
                        #endif
                        
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                        return
                    }
                }
                
                existing.text = text
                existing.isRestDay = isRestDay
                
                // Explicitly mark as needing save (force SwiftData to track changes)
                modelContext.insert(existing)
            } else {
                print("No changes detected, skipping save")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                return
            }
        } else {
            print("Creating new reflection")
            let new = DailyReflection(date: normalizedDay, text: text, isRestDay: isRestDay)
            modelContext.insert(new)
            print("Inserted new reflection (ID: \(new.id))")
        }
        
        // Save with error handling
        do {
            try modelContext.save()
            print("✅ Reflection saved successfully")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)
                try? modelContext.save()
                print("✅ Secondary reflection save completed")
            }
        } catch {
            print("❌ CRITICAL: Failed to save reflection!")
            print("Error: \(error)")
            print("Error details: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
    }
    
    // MARK: - Celebration Helpers
    
    private func checkMiniChallengeCompletion() {
        showConfetti = true
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showMiniChallengeCelebration = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showConfetti = false
        }
    }
    
    private func checkProject50LevelUp(newLevel: Int) {
        self.newLevel = newLevel
        
        showConfetti = true
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showProject50LevelUp = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showConfetti = false
        }
    }
}

// MARK: - Supporting Components

private struct ChallengeCelebrationBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String
    let accent: Color
    let iconName: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 42, height: 42)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(accent)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                .shadow(color: Color.shadowColor.opacity(colorScheme == .dark ? 0.45 : 0.2), radius: 18, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(accent.opacity(colorScheme == .dark ? 0.45 : 0.28), lineWidth: 1)
        )
    }
}

// MARK: - Challenge Reflection Prompt Sheet

private struct ChallengeReflectionPromptSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let challenge: MiniChallenge?
    let challengeTag: String
    let onDismiss: () -> Void

    @State private var navigateToChallenge = false

    private var accentColor: Color {
        challenge.map { Color(hex: $0.colorHex) } ?? .sageGreen
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 72, height: 72)

                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(accentColor)
                }
                .padding(.top, 32)

                // Title & Message
                VStack(spacing: 12) {
                    Text("Reflect on Your Journey")
                        .font(.system(size: 20, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Text("Congratulations on completing \(challenge?.title ?? "this challenge")! Would you like to capture your thoughts and insights?")
                        .font(.system(size: 14, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    // Write Reflection Button
                    NavigationLink {
                        if let challenge = challenge {
                            MiniChallengeDetailView(challenge: challenge)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 15, weight: .medium))
                            Text("Write Reflection")
                                .font(.system(size: 15, weight: .semibold))
                                .fontDesign(.serif)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Skip Button
                    Button {
                        onDismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.system(size: 14, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorScheme == .dark ? Color.black.opacity(0.95) : Color(uiColor: .systemGroupedBackground))
        }
    }
}

private struct StatColumn: View {
    @Environment(\.colorScheme) private var colorScheme

    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .fontDesign(.serif)
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FocusOrbView: View {
    let sessionCount: Int
    let colorScheme: ColorScheme

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.dynamicSecondaryLabel.opacity(0.2), lineWidth: 3)
                .frame(width: 46, height: 46)

            Circle()
                .trim(from: 0, to: trimAmount)
                .stroke(
                    AngularGradient(
                        colors: [.terracottaRose, .dustyBlue, .paleMauve],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .frame(width: 46, height: 46)
                .rotationEffect(.degrees(-90))

            Text("\(sessionCount)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.dynamicLabel)
        }
        .shadow(color: Color.shadowColor.opacity(0.15), radius: 4, y: 2)
    }

    private var trimAmount: CGFloat {
        let capped = min(CGFloat(sessionCount) / 14.0, 1.0)
        return capped
    }
}

//MARK: Insight Card
private struct InsightCard: View {
    let insight: WeeklyInsightHybrid
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(insight.color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: insight.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(insight.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Text(insight.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(insight.color)
                }

                Spacer()

                Text(insight.metric)
                    .font(.system(size: 12, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }

            Text(insight.message)
                .font(.system(size: 12, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
        .reverieCardStyle(colorScheme: colorScheme)
    }
}

// MARK: - Day Card (Fixed Reflection Persistence)

private struct DayCard: View {
    let day: Date
    let habits: [Habit]
    let completions: [HabitCompletion]

    let reflection: DailyReflection?
    let allReflections: [DailyReflection]

    let colorScheme: ColorScheme
    let onSaveReflection: (Date, String, Bool) -> Void
    let onTap: () -> Void
    let isExpanded: Bool

    @State private var reflectionText = ""
    @State private var isRestDay = false
    @State private var showReflectionField = false
    @State private var showSaveConfirmation = false
    @State private var hasLoadedReflection = false
    
    @State private var saveDebounceTask: Task<Void, Never>?
    
    @Environment(\.modelContext) private var modelContext

    // MARK: - Derived Data

    /// All completions that occurred on this calendar day (for display in the list).
    private var dayCompletions: [HabitCompletion] {
        completions
            .filter { Calendar.current.isDate($0.completedAt, inSameDayAs: day) }
            .sorted { $0.completedAt < $1.completedAt }
    }

    /// Habits that are still considered "active" on this day based on the
    /// current schedule and archive state.
    private var activeHabitsOnDay: [Habit] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)

        return habits.filter { habit in
            // Created on or before that day
            guard habit.createdAt <= dayStart else { return false }

            // Not archived before that day
            if let archivedDate = habit.archivedAt, archivedDate < dayStart {
                return false
            }

            // Scheduled for that day-of-week
            return habit.isScheduledOn(day)
        }
    }

    /// IDs of habits that are active on this day.
    private var activeHabitIDs: Set<UUID> {
        Set(activeHabitsOnDay.map { $0.id })
    }

    private var completedActiveHabitsCount: Int {
        // SCHEDULE-AWARE: Only count completions of habits that were scheduled for this day
        // This ensures progress reflects actual scheduled goals, not bonus completions
        let scheduledCompletions = dayCompletions.filter { completion in
            // For new completions: use the schedule flag
            if let wasScheduled = completion.wasScheduledForDay {
                return wasScheduled
            }
            // For old completions (before wasScheduledForDay was added): count them all
            return true
        }
        let unique = Set(scheduledCompletions.map { $0.habitId })
        return unique.count
    }

    /// Total number of habits that were active on this day.
    /// Uses snapshot captured at completion time for historical accuracy.
    private var habitCountOnDay: Int {
        let snapshotCounts = dayCompletions.compactMap { $0.snapshotActiveHabitsCount }
        if !snapshotCounts.isEmpty {
            return snapshotCounts.max() ?? 0
        }
        
        // FALLBACK: For old data without snapshots, calculate from current habit state
        return activeHabitsOnDay.count
    }

    // Completion rate = completed active habits / active habits.
    private var completionRate: Double {
        guard habitCountOnDay > 0 else { return 0 }
        return min(1.0, Double(completedActiveHabitsCount) / Double(habitCountOnDay))
    }

    // Perfect day = all active habits completed.
    private var isPerfectDay: Bool {
        habitCountOnDay > 0 && completedActiveHabitsCount == habitCountOnDay
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    // Count rest days only in the current week (not globally)
    private var restDayCount: Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)
        
        let weekday = calendar.component(.weekday, from: dayStart)
        
        let daysFromWeekStart = weekday - 1  // Sunday = 0, Monday = 1, etc.
        let weekStart = calendar.date(byAdding: .day, value: -daysFromWeekStart, to: dayStart) ?? dayStart
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        
        // Count rest days only within this week
        return allReflections.filter { reflection in
            guard reflection.isRestDay else { return false }
            let reflectionDay = calendar.startOfDay(for: reflection.date)
            return reflectionDay >= weekStart && reflectionDay <= weekEnd
        }.count
    }

    private var progressColor: Color {
        if completionRate >= 1.0 {
            return Color.sageGreen
        } else if completionRate >= 0.7 {
            return Color.dustyBlue
        } else {
            return Color.terracottaRose
        }
    }

    private var cardBackground: Color {
        isRestDay ? Color.dynamicSecondaryBackground.opacity(0.35) : Color.white.opacity(0.20)
    }

    private var cardBorderColor: Color {
        if isToday {
            return Color.sageGreen
        } else if isRestDay {
            return Color.white.opacity(0.30)
        } else {
            return Color.white.opacity(0.50)
        }
    }

    private var cardBorderWidth: CGFloat {
        isToday ? 1.5 : 1
    }

    // MARK: - Helper Functions
    
    private func persistNow() {
        let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("💾 DayCard persistNow called:")
        print("   Original text length: \(reflectionText.count)")
        print("   Trimmed text length: \(trimmed.count)")
        print("   isRestDay: \(isRestDay)")
        
        onSaveReflection(day, trimmed, isRestDay)
        
        withAnimation(.easeInOut(duration: 0.3)) { showSaveConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.25)) { showSaveConfirmation = false }
        }
    }

    private func handleReflectionChange(_ newValue: String) {
        if newValue.count > 150 {
            reflectionText = String(newValue.prefix(150))
            print("⚠️ Reflection text truncated from \(newValue.count) to 150 characters")
        }
        
        saveDebounceTask?.cancel()
        
        saveDebounceTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                
                if !Task.isCancelled {
                    print("📝 Debounced save triggered: \(newValue.count) chars")
                    persistNow()
                }
            } catch {
            }
        }
    }

    private func loadReflectionData() {
        guard !hasLoadedReflection else { return }
        
        let calendar = Calendar.current
        let normalizedDay = calendar.startOfDay(for: day)
        
        print("📖 Loading reflection for \(normalizedDay.formatted(date: .abbreviated, time: .omitted))")
        
        if let refl = reflection {
            reflectionText = refl.text
            isRestDay = refl.isRestDay
            showReflectionField = !refl.text.isEmpty
            
            print("   ✅ Found: text=\"\(refl.text.prefix(30))\(refl.text.count > 30 ? "..." : "")\", restDay=\(refl.isRestDay)")
        } else {
            reflectionText = ""
            isRestDay = false
            showReflectionField = false
            
            print("   ℹ️ No reflection found")
        }
        
        hasLoadedReflection = true
    }
    
    private func syncReflectionDataFromSource() {
        guard let latest = reflection else { return }
        var changed = false
        if reflectionText != latest.text {
            reflectionText = latest.text
            changed = true
        }
        if isRestDay != latest.isRestDay {
            isRestDay = latest.isRestDay
            changed = true
        }
        if changed, !latest.text.isEmpty {
            showReflectionField = true
        }
    }

    // MARK: - Body
    
    var body: some View {
        cardContent
            .onAppear { loadReflectionData() }
            .onDisappear {

                saveDebounceTask?.cancel()
                
                let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
                if let existing = reflection {
                    if existing.text != trimmed || existing.isRestDay != isRestDay {
                        onSaveReflection(day, trimmed, isRestDay)
                    }
                } else if !trimmed.isEmpty || isRestDay {
                    onSaveReflection(day, trimmed, isRestDay)
                }
            }

            .onChange(of: reflection?.id) { _, _ in
                syncReflectionDataFromSource()
            }
            .onChange(of: reflection?.text ?? "") { _, _ in
                syncReflectionDataFromSource()
            }
            .onChange(of: reflection?.isRestDay ?? false) { _, _ in
                syncReflectionDataFromSource()
            }
    }

    // MARK: - Main Content
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerSection

            if showReflectionField {
                reflectionFieldSection
            }

            if showSaveConfirmation {
                saveConfirmationView
            }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .background(cardBackgroundView)
        .overlay(cardBorderView)
        .contextMenu { contextMenuItems }
    }

    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            // Left: Day display
            dateDisplay
                .frame(width: 50, alignment: .leading)

            // Center: Habits list or empty state
            centerContent
                .frame(maxWidth: .infinity, alignment: .leading)

            // Right: Progress ring with fraction
            progressRingStack
                .frame(width: 50, alignment: .trailing)
        }
        // Tapping the header (not the TextField area) toggles expand/collapse
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var dateDisplay: some View {
        VStack(alignment: .leading, spacing: -2) {
            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 11, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 22, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .foregroundStyle(isToday ? Color.primary: Color.dynamicLabel)
        }
    }

    @ViewBuilder
    private var centerContent: some View {
        if isRestDay {
            restDayView
        } else if dayCompletions.isEmpty {
            noCompletionsView
        } else {
            completionsList
        }
    }

    private var progressRingStack: some View {
        VStack(spacing: 2) {
            if !isRestDay {
                progressRing
                completionFraction
            }
        }
    }

    private var progressRing: some View {
        let uniqueCompletions = Set(dayCompletions.map { $0.habitId }).count
        
        return ZStack {
            Circle()
                .stroke(Color.habitCardBorder, lineWidth: 1.5)
                .frame(width: 30, height: 30)
            Circle()
                .trim(from: 0, to: completionRate)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 30, height: 30)
            Text("\(uniqueCompletions)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(uniqueCompletions == 0 ? Color.dynamicSecondaryLabel : Color.dynamicLabel)
        }
    }

    private var completionFraction: some View {
        return Text("\(completedActiveHabitsCount)/\(habitCountOnDay)")
            .font(.system(size: 11, weight: .medium))
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
    }

    // MARK: - Center Content Views
    
    private var restDayView: some View {
        HStack(spacing: 5) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 11))
            Text("Rest day")
                .font(.system(size: 11))
        }
        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 3)
    }

    private var noCompletionsView: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 11))
            Text("No completions")
                .font(.system(size: 11))
        }
        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 3)
    }

    private var completionsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(displayedCompletions.enumerated()), id: \.element.id) { _, completion in
                let live: Habit? = habits.first(where: { $0.id == completion.habitId })
                completionRow(habit: live, completion: completion)
            }

            if !isExpanded && dayCompletions.count > 2 {
                expandButton
            }

            if isPerfectDay {
                perfectDayBadge
            }
        }
    }

    private var displayedCompletions: [HabitCompletion] {
        isExpanded ? dayCompletions : Array(dayCompletions.prefix(2))
    }

    private func completionRow(habit: Habit?, completion: HabitCompletion) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    habit.map { Color(hex: $0.colorHex) } ??
                    completion.snapshotColorHex.map { Color(hex: $0) } ??
                    Color.habitCardBorder
                )
                .frame(width: 5, height: 5)

            Text(habit?.name ?? completion.snapshotName ?? "Completed habit")
                .font(.system(size: 11.5))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .lineLimit(1)
        }
    }


    private func completionItemRow(habit: Habit?, completion: HabitCompletion) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: (habit?.colorHex) ?? "#999999"))
                .frame(width: 5, height: 5)
            Text(habit?.name ?? "Unknown Habit")
                .font(.system(size: 11.5))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .lineLimit(1)
        }
    }

    private var expandButton: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.system(size: 11))
                Text(isExpanded ? "Show less" : "+\(dayCompletions.count - 2) more")
                    .font(.system(size: 11))
            }
            .foregroundStyle(Color.sageGreen)
        }
        .buttonStyle(.plain)
    }

    private var perfectDayBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 11))
            Text("Perfect!")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(Color.sageGreen)
        .padding(.top, 2)
    }

    // MARK: - Reflection Field
    
    private var reflectionFieldSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider().opacity(0.25)
            reflectionTextField
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)).animation(.easeInOut(duration: 0.35)),
            removal: .opacity.animation(.easeOut(duration: 0.25))
        ))
    }

    private var reflectionTextField: some View {
        TextField("Write a short reflection...", text: $reflectionText)
            .font(.system(size: 12))
            .lineLimit(2)
            .padding(6)
            .background(Color.white.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onChange(of: reflectionText) { _, newValue in
                handleReflectionChange(newValue)
            }
            .onSubmit { persistNow() }
    }

    // MARK: - Save Confirmation
    
    private var saveConfirmationView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.sageGreen)
            Text("Saved")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.sageGreen)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Card Styling
    
    private var cardBackgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(cardBackground)
    }

    private var cardBorderView: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(cardBorderColor, lineWidth: cardBorderWidth)
    }

    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button(isRestDay ? "Remove Rest Day" : "Mark as Rest Day") {
            handleRestDayToggle()
        }

        Button("Add Reflection") {
            withAnimation(.easeInOut(duration: 0.35)) {
                showReflectionField.toggle()
                if showReflectionField && reflectionText.isEmpty {
                    persistNow()
                }
            }
        }
    }

    private func handleRestDayToggle() {
        print("🌙 Rest Day Toggle - Before: \(isRestDay)")
        print("   Current week rest days: \(restDayCount)/2")
        
        if isRestDay {
            // Removing rest day
            isRestDay = false
            print("   Action: Removing rest day")
            persistNow()
        } else if restDayCount < 2 {
            isRestDay = true
            print("   Action: Marking as rest day")
            persistNow()
        } else {
            print("   ⚠️ Already have 2 rest days this week - cannot add more")
            print("   (Rest day limit is per week, not global)")
        }
        
        print("   After: \(isRestDay)")
    }
}


// MARK: - Data Models

struct WeeklyInsightHybrid: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let metric: String
    let message: String
    let icon: String
    let color: Color
}

enum InsightTone {
    case celebratory, balanced, gentle

    var perfectDayMessage: String {
        switch self {
        case .celebratory: return "Perfect days like these show your dedication in full bloom."
        case .balanced: return "Your consistency this week creates a foundation for lasting change."
        case .gentle: return "You kept showing up, even when it was hard. That resilience is what builds transformation."
        }
    }

    var growthMessage: String {
        switch self {
        case .celebratory: return "🌟 Your habits are accelerating! This upward trajectory shows real commitment taking root."
        case .balanced: return "Steady growth week over week. You're building momentum that compounds over time."
        case .gentle: return "Moving forward, one step at a time. Progress isn't always linear, but you're creating it."
        }
    }

    func streakMessage(for days: Int) -> String {
        switch self {
        case .celebratory: return "🔥 \(days) days in rhythm—your habits are second nature."
        case .balanced: return "\(days) days steady—let's carry this strength forward."
        case .gentle: return "\(days) days of effort. Show yourself grace and keep flowing."
        }
    }
}

// MARK: - Compact Intention Row
struct CompactIntentionRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let intention: DailyIntention
    let isToday: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                if isToday {
                    Circle()
                        .fill(Color.sageGreen)
                        .frame(width: 5, height: 5)
                }

                Text(compactDateFormat(intention.date))
                    .font(.system(size: 12, weight: isToday ? .semibold : .medium))
                    .foregroundStyle(isToday ? Color.sageGreen : Color.dynamicSecondaryLabel)
                    .monospacedDigit()
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 50, alignment: .leading)

            Image(systemName: getMoodEmoji(intention.mood))
                .font(.system(size: 13))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            if !intention.text.isEmpty {
                Text(intention.text)
                    .font(.system(size: 12, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .lineLimit(1)
            } else {
                Text("No note")
                    .font(.system(size: 12, weight: .regular))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                    .italic()
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isToday ? Color.sageGreen.opacity(0.08) : Color.dynamicSecondaryBackground.opacity(0.5))
        )
    }

    private func compactDateFormat(_ date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        let month = Calendar.current.component(.month, from: date)
        let day = Calendar.current.component(.day, from: date)

        let weekdayInitial = getWeekdayInitial(weekday)
        return "\(weekdayInitial) \(month).\(day)"
    }

    private func getWeekdayInitial(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "S"
        case 2: return "M"
        case 3: return "T"
        case 4: return "W"
        case 5: return "Th"
        case 6: return "F"
        case 7: return "S"
        default: return "?"
        }
    }

    private func getMoodEmoji(_ mood: String?) -> String {
        guard let mood = mood?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else {
            return "questionmark.circle"
        }

        if mood.contains("leaf.fill") { return "leaf.fill" }
        if mood.contains("bolt.fill") { return "bolt.fill" }
        if mood.contains("target") { return "target" }
        if mood.contains("hands.sparkles") { return "hands.sparkles" }
        if mood.contains("sun.max.fill") { return "sun.max.fill" }
        if mood.contains("flame.fill") { return "flame.fill" }

        if mood.contains("peace") { return "leaf.fill" }
        if mood.contains("energize") { return "bolt.fill" }
        if mood.contains("focus") { return "target" }
        if mood.contains("grat") { return "hands.sparkles" }
        if mood.contains("hope") { return "sun.max.fill" }
        if mood.contains("action") { return "flame.fill" }

        return "questionmark.circle"
    }
}

// MARK: - Mini Challenge Celebration View

struct MiniChallengeCelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let challengeName: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
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
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "flag.checkered")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Color.sageGreen)
            }
            
            VStack(spacing: 8) {
                Text("Challenge Complete!")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Text("You finished \(challengeName)")
                    .font(.system(size: 15, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("Seven days of focused dedication — you've proven what consistency looks like. This is the rhythm that transforms habits into who you are.")
                .font(.system(size: 13, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.sageGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Project 50 Level Up View

struct Project50LevelUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let newLevel: Int
    
    private var levelName: String {
        switch newLevel {
        case 1: return "Foundation"
        case 2: return "Focus"
        case 3: return "Depth"
        default: return "Level \(newLevel)"
        }
    }
    
    private var levelMessage: String {
        switch newLevel {
        case 2: return "You've built the foundation — now it's time to sharpen your focus and refine what you've started."
        case 3: return "Focus has become your strength. Now we go deeper, exploring the subtle layers of mastery."
        default: return "Each level reveals new dimensions of growth. You're evolving with every step."
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
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
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dustyBlue, Color.paleMauve],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Level \(newLevel) Unlocked!")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Text(levelName)
                    .font(.system(size: 18, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dustyBlue, Color.paleMauve],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
     
            Text(levelMessage)
                .font(.system(size: 13, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Continue Journey")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.dustyBlue, Color.paleMauve],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WeeklyArchiveView()
        .preferredColorScheme(.light)
}

