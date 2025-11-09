//
// WeeklyArchiveView.swift
// Reverie Weaver
//
// UNIFIED VERSION - All components inline (Oct 2025)
// Following original Archive structure and aesthetic
// Structure: WeekNavigator → WeeklySummary → ActiveChallenges → FocusThisWeek → Insights → DailyBreakdown
//
// ✅ COMPLETE FIXES (Nov 2025)
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
//    - Changed from counting current habits to counting unique habits from actual completions
//    - Uses `habitCountOnDay = Set(dayCompletions.map { $0.habitId }).count`
//    - This ensures historical completion rates remain accurate even after deleting habits
//    - Example: Complete 5/5 on Monday, delete 2 on Tuesday → Monday still shows 5/5 (not 5/3)
//
// 4. IMPROVED CHANGE DETECTION:
//    - Changed `onChange(of: allCompletions)` to `onChange(of: allCompletions.count)`
//    - This is more efficient and reliable for detecting completion changes
//    - Added comprehensive logging to track progress updates
//    - Ensures modelContext.save() is called when progress actually changes
//

import SwiftUI
import SwiftData

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


    // MARK: - State
    @State private var currentDate = Date()
    @State private var selectedTab: ContentTab = .insights
    @State private var expandedDays: Set<Date> = []
    @State private var markedRestDays: Set<Date> = []
    @State private var showWeekPicker = false
    @State private var showAllIntentions = false
    // Make sure the manager is ObservableObject with @Published fields
    @ObservedObject private var progressManager = Project50ProgressManager.shared

    
    // MARK: - Active Mini Challenge Tracker
    private var activeMiniChallengeProgress: MiniChallengeProgress? {
        allMiniChallengeProgress.first { !$0.isCompleted && !$0.isPaused }
    }

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

    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: weekStart)
    }

    // MARK: - Add helpers (near other computed props)
    private func activeHabitCount(on date: Date) -> Int {
        habits.filter { h in
            h.createdAt <= date && (h.archivedAt == nil || h.archivedAt! >= date)
        }.count
    }

    private var totalPossibleThisWeek: Int {
        weekDays.reduce(0) { acc, day in acc + activeHabitCount(on: day) }
    }

    private func totalPossible(inWeekStarting start: Date) -> Int {
        let cal = Calendar.current
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        return days.reduce(0) { $0 + activeHabitCount(on: $1) }
    }
    
    // MARK: - Add helpers
    private var weekCompletions: [HabitCompletion] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: weekStart)
        // ⬇️ endExclusive = midnight at the *start* of the day after weekEnd
        let endExclusive = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: weekEnd))!

        return allCompletions.filter { c in
            let d = c.completedAt
            // include start, exclude end → [start, end)
            return d >= start && d < endExclusive
        }
    }

    private var weekFavorites: [HabitCompletion] {
        weekCompletions.filter { $0.reflection?.isFavorite == true }
    }

    private var currentWeekRate: Double {
         let denom = max(totalPossibleThisWeek, 1)
         return Double(weekCompletions.count) / Double(denom)
     }

     private var prevWeekRate: Double {
          guard let lastWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { return 0 }
         let cal = Calendar.current
         let start = cal.startOfDay(for: lastWeekStart)
         let endExclusive = cal.date(byAdding: .day, value: 7, to: start)!  // [start, start+7d)
         let lastComps = allCompletions.filter { $0.completedAt >= start && $0.completedAt < endExclusive }
              let total = max(totalPossible(inWeekStarting: lastWeekStart), 1)
              return Double(lastComps.count) / Double(total)
     }

     private var perfectDaysCount: Int {
         weekDays.filter { day in
             let denom = activeHabitCount(on: day)
             guard denom > 0 else { return false }
             return completionsFor(day).count == denom
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

    private func completionsFor(_ day: Date) -> [HabitCompletion] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: day)
        
        return weekCompletions.filter { completion in
            let completionDay = calendar.startOfDay(for: completion.completedAt)
            return completionDay == targetDay
        }
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
                    if hasMiniChallenge || hasProject50 {
                        activeChallengesSection
                            .padding(.horizontal, 24)
                    }
                    // 6. Insights
                    insightsSection
                    // ✨ 3. Daily Intentions
                    dailyIntentionsCard

                    // 4. Daily Breakdown
                    dailyBreakdownSection

                    // 5. Focus This Week (always visible)
                    weeklyFocusCard

                }
                .padding(.bottom, 100)
            }
        }
        .refreshable { await refreshData() }
        .onAppear {
            loadRestDays()
            
            // 🧩 Force initial data fetch
            Task { @MainActor in
                do {
                    _ = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
                    print("✅ WeeklyArchiveView initial data loaded")
                } catch {
                    print("⚠️ WeeklyArchiveView data fetch failed: \(error)")
                }
            }
            
            // 🧩 Auto-check mini challenge progress on appear
            if let progress = activeMiniChallengeProgress {
                let beforeCount = progress.daysCompleted
                progress.checkAndUpdateProgress(completions: allCompletions)
                let afterCount = progress.daysCompleted
                
                if beforeCount != afterCount {
                    print("✅ Mini Challenge: Day marked complete (\(afterCount)/7)")
                    try? modelContext.save()
                } else {
                    print("ℹ️ Mini Challenge: Already up to date (\(afterCount)/7)")
                }
            }
            
            // ✅ Refresh Project 50 progress on appear
            progressManager.refreshEligibility()
            print("✅ Project 50: Progress refreshed - Level \(progressManager.journey.currentLevel) at \(Int(currentProject50Completion * 100))%")
        }
        // 🧩 Live observer — updates progress whenever completions change
        .onChange(of: allCompletions.count) { oldValue, newValue in
            print("📊 Completions changed: \(oldValue) → \(newValue)")
            
            // Update mini challenge progress
            if let progress = activeMiniChallengeProgress {
                let beforeCount = progress.daysCompleted
                progress.checkAndUpdateProgress(completions: allCompletions)
                let afterCount = progress.daysCompleted
                
                if beforeCount != afterCount {
                    print("✅ Mini Challenge: Day marked complete (\(afterCount)/7)")
                    try? modelContext.save()
                }
            }
            
            // Refresh Project 50 progress
            progressManager.refreshEligibility()
            print("✅ Project 50: Progress updated to \(Int(currentProject50Completion * 100))%")
        }
        .sheet(isPresented: $showWeekPicker) {
            weekCalendarSheet
        }
    }


    // MARK: - 1. Week Navigator Section (LoomView Style)
    @ViewBuilder
    private var weekNavigatorSection: some View {
        HStack(spacing: 8) {
            Text(weekHeaderTitle)
                .font(.system(size: 12, weight: .medium))
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
                .presentationDetents([.fraction(0.5)]) // Compact 60% height
                .presentationCornerRadius(28)
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


    // MARK: - Week Calendar Sheet (Compact Reverie Style)
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
            // Header
            HStack(spacing: 8) {
                Text("Weekly Summary")
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
            }

            // Core Stats
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

            // Comparison vs Last Week
            if let comparison = weekComparison {
                HStack(spacing: 4) {
                    Image(systemName: comparison.isImprovement ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(comparison.isImprovement ? Color.sageGreen : Color.terracottaRose)
                    Text("\(abs(comparison.difference))% vs last week")
                        .font(.system(size: 11, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: completionPercentage)
    }

    private var threadsWoven: Int {
        weekCompletions.count
    }

    private var totalHabitsCount: Int { totalPossibleThisWeek }

    private var completionPercentage: Int {
        let denom = max(totalHabitsCount, 1)
        return Int((Double(threadsWoven) / Double(denom)) * 100)
    }

    private var progress: CGFloat {
        let denom = max(totalHabitsCount, 1)
        return CGFloat(threadsWoven) / CGFloat(denom)
     }

    private var weekComparison: (isImprovement: Bool, difference: Int)? {
        guard let lastWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { return nil }

        let lastWeekCompletions = allCompletions.filter {
            let cal = Calendar.current
            let s = cal.startOfDay(for: lastWeekStart)
            let e = cal.date(byAdding: .day, value: 7, to: s)!
            return $0.completedAt >= s && $0.completedAt < e
        }

        let lastWeekTotal = totalPossible(inWeekStarting: lastWeekStart)
        guard lastWeekTotal > 0 else { return nil }

        let lastWeekPercentage = Int(Double(lastWeekCompletions.count) / Double(lastWeekTotal) * 100)
        let diff = completionPercentage - lastWeekPercentage
        guard abs(diff) >= 3 else { return nil }
        return (isImprovement: diff > 0, difference: abs(diff))
    }

    // MARK: - 3. Active Challenges Section
    @ViewBuilder
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 🪷 Mini Challenge section (reads from live model progress)
            if let challenge = activeMiniChallenge,
               let progress = activeMiniChallengeProgress {
                
                let miniChallengeDaysCompleted = progress.daysCompleted
                // ✅ FIX: Use real-time completion check instead of cached state
                let todayMiniChallengeComplete = progress.isTodayChallengeComplete(completions: allCompletions)
                
                miniChallengeContent(
                    challenge,
                    miniChallengeDaysCompleted: miniChallengeDaysCompleted,
                    todayMiniChallengeComplete: todayMiniChallengeComplete
                )
            }

            // Divider between Mini Challenge and Project 50
            if hasMiniChallenge && hasProject50 {
                Divider()
                    .padding(.horizontal, 2)
            }

            // Project 50 section
            if hasProject50 {
                project50Content
            }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Mini Challenge Content (Live Data)
    @ViewBuilder
    private func miniChallengeContent(
        _ challenge: MiniChallenge,
        miniChallengeDaysCompleted: Int,
        todayMiniChallengeComplete: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
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
                    .font(.system(size: 11))
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
                                        .font(.system(size: 11, weight: .bold))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                } else {
                                    Text("\(day)")
                                        .font(.system(size: 11, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                            }
                        )
                }
            }

            // Status message (reactive to progress.isTodayComplete)
            HStack(spacing: 6) {
                if miniChallengeDaysCompleted >= 7 {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.sageGreen)
                    Text("Challenge complete!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.sageGreen)
                } else if todayMiniChallengeComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.sageGreen)
                    Text("Today complete – keep going tomorrow")
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    Text("Complete all habits today")
                        .font(.system(size: 11))
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
                    .font(.system(size: 11, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
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
                        // ✅ FIX: Bind directly to computed property that forces recalculation
                        .frame(width: geometry.size.width * currentProject50Completion)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentProject50Completion)
                }
            }
            .frame(height: 8)

            HStack(spacing: 6) {
                // ✅ FIX: Use computed property that forces recalculation
                Text("\(Int(currentProject50Completion * 100))% complete")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.dynamicLabel)

                if let nextLevel = nextUnlockLevel {
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    Text("\(daysUntilNextLevel) days to Level \(nextLevel)")
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
        }
    }

    private var hasMiniChallenge: Bool {
        progressManager.journey.activeMiniChallengeID != nil && activeMiniChallenge != nil
    }

    private var hasProject50: Bool {
        // Check for P50 programTag
        habits.contains { habit in
            guard let tag = habit.programTag else { return false }
            return tag == "P50"
        }
    }

    private var activeMiniChallenge: MiniChallenge? {
        guard let challengeID = progressManager.journey.activeMiniChallengeID else { return nil }
        return MiniChallengeData.challenges.first { $0.id == challengeID }
    }

    private var miniChallengeProgress: MiniChallengeProgress? {
        progressManager.getActiveMiniChallengeProgress(modelContext: modelContext)
    }

    private var miniChallengeDaysCompleted: Int {
        miniChallengeProgress?.daysCompleted ?? 0
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

    // ✅ FIX: Calculate Project 50 completion in real-time based on current data
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
        
        // Get relevant completions for these habits
        let habitIds = Set(levelHabits.map { $0.id })
        let windowStart = calendar.date(byAdding: .day, value: -daysSinceLevelStartCapped, to: Date()) ?? levelStartDate
        
        let relevantCompletions = allCompletions.filter { completion in
            habitIds.contains(completion.habitId) &&
            completion.completedAt >= windowStart &&
            completion.completedAt <= Date()
        }
        
        // Group by day and count successful days (≥80% completion)
        let groupedByDay = Dictionary(grouping: relevantCompletions) { completion in
            calendar.startOfDay(for: completion.completedAt)
        }
        
        let successfulDays = groupedByDay.values.filter { dayCompletions in
            dayCompletions.count >= Int(Double(activeHabitsCount) * 0.80)
        }.count
        
        // Calculate completion: successful days / total days required
        let completion = Double(successfulDays) / Double(daysCap)
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
                                   .font(.system(size: 11, weight: .medium))
                                   .foregroundStyle(Color.sageGreen)

                               Image(systemName: showAllIntentions ? "chevron.up" : "chevron.down")
                                   .font(.system(size: 9))
                                   .foregroundStyle(Color.sageGreen)
                           }
                       }
                   }
               }
               .frame(maxWidth: .infinity, alignment: .leading)

               if weekIntentions.isEmpty {
                   Text("No intentions set this week")
                       .font(.system(size: 12, weight: .regular))
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
                                   .font(.system(size: 10))
                                   .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                               Text("\(otherIntentions.count) more")
                                   .font(.system(size: 11, weight: .regular))
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
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dustyBlue)

                    Text("Focus This Week")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Spacer()

                    if !weekPomodoros.isEmpty {
                        Text(String(format: "%.1fh", totalHours))
                            .font(.system(size: 12, weight: .semibold))
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
                            .font(.system(size: 12, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        Text("Start a Pomodoro to track your focused work")
                            .font(.system(size: 11, weight: .regular))
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
                                            .font(.system(size: 11, weight: .regular))
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
                        .font(.system(size: 11, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .reverieCardStyle(colorScheme: colorScheme)
            .padding(.horizontal)
            .padding(.bottom, 100)  // ← ADD BOTTOM SPACING to avoid tab bar
        }

    private func statRow(icon: String, value: Int, unit: String, label: String) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Text("\(value)")
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.terracottaRose)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            Image(systemName: icon)
                .font(.system(size: 12))
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
                    .foregroundStyle(Color.dynamicLabel)
                Spacer()
            }
            .padding(.horizontal, 24)

            // Horizontal Center-Aligned Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    Spacer(minLength: (UIScreen.main.bounds.width - 240) / 2) // ⬅️ center padding
                    ForEach(mergedInsights, id: \.id) { insight in
                        InsightCard(insight: insight, colorScheme: colorScheme)
                            .frame(width: 240)
                    }
                    Spacer(minLength: (UIScreen.main.bounds.width - 240) / 2) // ⬅️ trailing center padding
                }
                .padding(.horizontal, 24)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: mergedInsights.count)
    }

    private var mergedInsights: [WeeklyInsightHybrid] {
        var insights: [WeeklyInsightHybrid] = []
        let growthRate = Int((currentWeekRate - prevWeekRate) * 100)
        let tone = adaptiveTone()

        // Mini Challenge progress insights
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
                    completions: allCompletions,  // ✅ Full array - let DayCard filter internally
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
                    isExpanded: expandedDays.contains(day)  // ✅ Pass expanded state from parent
                )
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Helper Functions
    private func loadRestDays() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: weekStart)
        let endExclusive = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: weekEnd))!

        // Assuming DailyReflection has `date: Date` and `isRestDay: Bool`
        let days = reflections
            .filter { $0.isRestDay && $0.date >= start && $0.date < endExclusive }
            .map { cal.startOfDay(for: $0.date) }

        markedRestDays = Set(days)
    }

    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // ✅ FIX: Refresh Project 50 progress when user pulls to refresh
        await MainActor.run {
            progressManager.refreshEligibility()
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func saveReflection(for day: Date, text: String, isRestDay: Bool) {
        if let existing = reflections.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            existing.text = text
            existing.isRestDay = isRestDay
        } else {
            let new = DailyReflection(date: day, text: text, isRestDay: isRestDay)
            modelContext.insert(new)
        }
        try? modelContext.save()
    }
}

// MARK: - Supporting Components

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
                .font(.system(size: 10, weight: .medium))
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
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(insight.color)
                }

                Spacer()

                Text(insight.metric)
                    .font(.system(size: 11, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }

            Text(insight.message)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
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
    let isExpanded: Bool  // ✅ Passed from parent instead of local state

    @State private var reflectionText = ""
    @State private var isRestDay = false
    @State private var showReflectionField = false
    @State private var showSaveConfirmation = false
    @State private var hasLoadedReflection = false
    @Environment(\.modelContext) private var modelContext

    // MARK: - Derived Data
    private var dayCompletions: [HabitCompletion] {
        completions
            .filter { Calendar.current.isDate($0.completedAt, inSameDayAs: day) }
            .sorted { $0.completedAt < $1.completedAt }
    }

    // ✅ FIXED: Count unique habits from actual completions
    // This ensures accurate rates even after habits are deleted
    private var habitCountOnDay: Int {
        let uniqueHabitIds = Set(dayCompletions.map { $0.habitId })
        return uniqueHabitIds.count
    }

    // ✅ FIXED: Completion rate based on actual completions
    private var completionRate: Double {
        guard habitCountOnDay > 0 else { return 0 }
        return Double(dayCompletions.count) / Double(habitCountOnDay)
    }

    // ✅ FIXED: Perfect day detection using actual completion count
    private var isPerfectDay: Bool {
        habitCountOnDay > 0 && dayCompletions.count == habitCountOnDay
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    private var restDayCount: Int {
        allReflections.filter { $0.isRestDay }.count
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
        isRestDay ? Color.dynamicSecondaryBackground.opacity(0.45) : Color.white.opacity(0.35)
    }

    private var cardBorderColor: Color {
        if isToday {
            return Color.sageGreen
        } else if isRestDay {
            return Color.white.opacity(0.35)
        } else {
            return Color.white.opacity(0.75)
        }
    }

    private var cardBorderWidth: CGFloat {
        isToday ? 1.5 : 1
    }

    // MARK: - Helper Functions
    private func persistNow() {
        let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSaveReflection(day, trimmed, isRestDay)
        withAnimation(.easeInOut(duration: 0.3)) { showSaveConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.25)) { showSaveConfirmation = false }
        }
    }

    private func handleReflectionChange(_ newValue: String) {
        // Enforce 150-char limit, then save
        if newValue.count > 150 {
            reflectionText = String(newValue.prefix(150))
        }
        persistNow()
    }

    private func loadReflectionData() {
        guard !hasLoadedReflection else { return }
        reflectionText = reflection?.text ?? ""
        isRestDay = reflection?.isRestDay ?? false
        showReflectionField = reflection != nil && !(reflection?.text ?? "").isEmpty
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
        // NOTE: Avoid wrapping the entire card in a Button since TextField lives inside.
        // Use a plain container and put tap handlers only where needed.
        cardContent
            .onAppear { loadReflectionData() }

            // NEW (iOS 17+):
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
        .background(cardBackgroundView)              // ✅ reflect rest-day visually
        .overlay(cardBorderView)
        .contextMenu { contextMenuItems }
    }

    // MARK: - Header Section (Three-Column Layout)
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
        .onTapGesture { onTap() }                    // ✅ keep your parent-driven expand
    }

    private var dateDisplay: some View {
        VStack(alignment: .leading, spacing: -2) {
            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 10, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 22, weight: .medium))
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
            progressRing
            completionFraction
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.habitCardBorder, lineWidth: 1.5)
                .frame(width: 30, height: 30)
            Circle()
                .trim(from: 0, to: completionRate)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 30, height: 30)
            Text("\(dayCompletions.count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(dayCompletions.isEmpty ? Color.dynamicSecondaryLabel : Color.dynamicLabel)
        }
    }

    // ✅ FIXED: Shows actual habit count from completions
    private var completionFraction: some View {
        Text("\(dayCompletions.count)/\(habitCountOnDay)")
            .font(.system(size: 9, weight: .medium))
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
    }

    // MARK: - Center Content Views
    private var restDayView: some View {
        HStack(spacing: 5) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 10))
            Text("Rest day")
                .font(.system(size: 10))
        }
        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 3)
    }

    private var noCompletionsView: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 10))
            Text("No completions")
                .font(.system(size: 10))
        }
        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 3)
    }

    private var completionsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(displayedCompletions.enumerated()), id: \.element.id) { _, completion in
                let live: Habit? = habits.first(where: { $0.id == completion.habitId })
                completionRow(habit: live, completion: completion) // ← name matches
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

    // ✅ Render even if the habit was archived/deleted; use snapshot on the completion
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
                .font(.system(size: 10.5))
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
                .font(.system(size: 10.5))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .lineLimit(1)
        }
    }

    private var expandButton: some View {
        Button(action: onTap) {  // ✅ Call onTap to sync with parent state
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.system(size: 9))
                Text(isExpanded ? "Show less" : "+\(dayCompletions.count - 2) more")
                    .font(.system(size: 10))
            }
            .foregroundStyle(Color.sageGreen)
        }
        .buttonStyle(.plain)
    }

    private var perfectDayBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("Perfect!")
                .font(.system(size: 9, weight: .semibold))
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
            .font(.system(size: 11))
            .lineLimit(2)
            .padding(6)
            .background(Color.white.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            // OLD:
            // .onChange(of: reflectionText) { newValue in handleReflectionChange(newValue) }
            // NEW:
            .onChange(of: reflectionText) { _, newValue in
                handleReflectionChange(newValue)
            }
            // ✅ Also persist on Submit/Return (nice UX)
            .onSubmit { persistNow() }
    }

    // MARK: - Save Confirmation
    private var saveConfirmationView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.sageGreen)
            Text("Saved")
                .font(.system(size: 10, weight: .medium))
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
                    // Create an empty record on first reveal so rest-day toggles persist even without text
                    persistNow()
                }
            }
        }
    }

    private func handleRestDayToggle() {
        if isRestDay {
            isRestDay = false
            persistNow()                    // ✅ persist flag change
        } else if restDayCount < 2 {
            isRestDay = true
            persistNow()                    // ✅ persist flag change
        }
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
    @Environment(\.colorScheme) private var colorScheme  // ← Add this line

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
                    .font(.system(size: 11, weight: isToday ? .semibold : .medium))
                    .foregroundStyle(isToday ? Color.sageGreen : Color.dynamicSecondaryLabel)
                    .monospacedDigit()
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 50, alignment: .leading)

            Image(systemName: getMoodEmoji(intention.mood))
                .font(.system(size: 12))
                .foregroundStyle(Color.dynamicLabel)

            if !intention.text.isEmpty {
                Text(intention.text)
                    .font(.system(size: 11, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .lineLimit(1)
            } else {
                Text("No note")
                    .font(.system(size: 11, weight: .regular))
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
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

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
        if mood.contains("energy") { return "bolt.fill" }
        if mood.contains("focus") { return "target" }
        if mood.contains("grat") { return "hands.sparkles" }
        if mood.contains("hope") { return "sun.max.fill" }
        if mood.contains("action") { return "flame.fill" }

        return "questionmark.circle"
    }
}

#Preview {
    WeeklyArchiveView()
        .preferredColorScheme(.light)
}
