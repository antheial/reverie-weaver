//
// DeskView.swift
// ReverieWeaver
//
//
//

import SwiftUI
import SwiftData
import os.log

struct DeskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query private var completions: [HabitCompletion]
    @Query private var intentions: [DailyIntention]
    @Query private var allAchievements: [Achievement]
    @Query private var microHabitCompletions: [MicroHabitCompletion]
    @Query private var microHabitProgress: [MicroHabitProgress]
    @Query private var reflections: [DailyReflection]
    
    // Mini challenge progress
    @Query private var miniChallengeProgress: [MiniChallengeProgress]
    @Query private var themeWeekProgress: [ThemeWeekProgress]
    
    // Read all Vitality progresses
    @Query private var vitalityProgressRecords: [VitalityProgress]
    
    @Query(filter: #Predicate<Habit> { $0.isArchived == false },
           sort: \Habit.order
       )
       private var habits: [Habit]
    
    @Query private var constellations: [ConstellationBadge]
    
    // Daily wisdom state
    @State private var currentWisdom: WisdomContent?
    @State private var showCreateHabit = false
    @State private var showEditHabit: Habit?
    @State private var showConfetti = false
    @State private var showHabitLibrary = false
    @State private var showQuickActionPrompt = false
    @State private var showFloatingAdd = false
    @State private var floatingAddTimer: Timer?
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isFloatingButtonVisible = true

    @State private var currentMicroHabit: MicroHabit?
    @State private var promptedMicroHabit: MicroHabit?
    @State private var intentionText = ""
    @State private var intentionMood = "Peaceful"
    @State private var intentionExpanded = false

    @State private var showPerfectDayCelebration = false
    @State private var showReflection: HabitCompletion?
    
    @State private var refreshID = UUID()
    @State private var activeTierSelection: TierSelectionPayload? = nil
    
    // Vitality Tier Selection State
    @State private var activeVitalityTierSelection: VitalityTierSelectionPayload? = nil
    
    // Store the last completed Vitality day for RPE tracking
    @State private var lastCompletedVitalityDay: Int? = nil
    
    // UI refresh trigger
    @State private var dataVersion: Int = 0
    
    // Uncheck confirmation
    @State private var habitToUncheck: Habit?
    @State private var showUncheckAlert = false
    
    // Reorder mode
    @State private var isReorderMode = false
    
    // Rest day state
    @State private var showRestDayToast = false

    // First-time welcome tips (shows once after onboarding)
    @AppStorage("hasSeenDeskWelcomeTips") private var hasSeenDeskWelcomeTips = false

    @StateObject private var localization = LocalizationManager.shared
    
    @ObservedObject private var journeyManager = WeaverJourneyManager.shared

    private struct TierSelectionPayload: Identifiable {
        let id = UUID()
        let habit: Habit            // the actual Habit on Desk
        let themeWeekHabit: ThemeWeekHabit
        let dayNumber: Int
        let themeName: String
    }
    
    // Vitality Tier Selection Payload
    private struct VitalityTierSelectionPayload: Identifiable {
        let id = UUID()
        let habit: Habit            // the actual Habit on Desk
        let day: VitalityDay        // the current day's data
        let progress: VitalityProgress
        let programTitle: String
    }
    
    // Simple struct to hold the daily wisdom payload
    private struct WisdomContent: Equatable {
        let text: String
        let icon: String
        let color: Color
        let isEcho: Bool
        let source: String?
    }

    private var todayCompletions: [HabitCompletion] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return completions.filter { completion in
            let completionDay = calendar.startOfDay(for: completion.completedAt)
            return completionDay == today
        }
    }
    
    // MARK: - Rest Day Support
    
    private var todayReflection: DailyReflection? {
        let today = Calendar.current.startOfDay(for: Date())
        return reflections.first { 
            Calendar.current.isDate($0.date, inSameDayAs: today) 
        }
    }
    
    private var isRestDay: Bool {
        todayReflection?.isRestDay ?? false
    }

    private var todayIntention: DailyIntention? {
        intentions.first { Calendar.current.isDateInToday($0.date) }
    }

    // MARK: - Habit activity helpers
    
    /// Returns true if the habit is considered "active" on the given date.
    private func isHabitActive(_ habit: Habit, on date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // Must be created before or on that calendar day
        guard habit.createdAt <= dayStart else { return false }

        // Must not be archived before that calendar day
        if let archivedDate = habit.archivedAt, archivedDate < dayStart {
            return false
        }

        // Must be scheduled for that day
        guard habit.isScheduledOn(date) else { return false }

        // For Theme Week habits: at least one program instance with this tag must be active
        if habit.isThemeWeek {
            let habitTag = habit.programTag ?? ""
            let matching = themeWeekProgress.filter { "TW-\($0.programTag)" == habitTag }

            let hasAnyActive = matching.contains { !$0.isCompleted && !$0.isPaused && !$0.isArchived }
            return hasAnyActive
        }
        
        // For Vitality habits: check if Vitality progress is active
        if isVitalityHabit(habit) {
            guard let progress = vitalityProgress(for: habit) else { return false }
            return !progress.isCompleted && !progress.isPaused
        }

        return true
    }
    
    // Check if habit is a Vitality program habit
    private func isVitalityHabit(_ habit: Habit) -> Bool {
            guard let tag = habit.programTag else { return false }
            return tag.hasPrefix("VA-")
        }

    // Habits the user intends to do *today* (schedule-aware, day-normalized).
    private var activeHabitsToday: [Habit] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habits.filter { habit in
            isHabitActive(habit, on: today)
        }
    }
    
    // Today’s completions that belong to *scheduled* habits.
    // For legacy completions where `wasScheduledForDay` is nil, we treat them as scheduled
    private var todayScheduledCompletions: [HabitCompletion] {
        todayCompletions.filter { completion in
            completion.wasScheduledForDay ?? true
        }
    }

    // Number of *scheduled* habits for today that have at least one completion.
    private var completedCount: Int {
        let scheduledCompletedHabitIDs: Set<UUID> = Set(todayScheduledCompletions.map { $0.habitId })
        return activeHabitsToday.filter { scheduledCompletedHabitIDs.contains($0.id) }.count
    }

    private var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())

        while true {
            let dayCompletions = completions.filter {
                Calendar.current.isDate($0.completedAt, inSameDayAs: date)
            }
            if dayCompletions.isEmpty {
                break
            }
            streak += 1

            guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = newDate
        }

        return streak
    }
    
    private var hasTodayCompletion: Bool {
        completions.contains { Calendar.current.isDateInToday($0.completedAt) }
    }

    private var streakUpToYesterday: Int {
        var streak = 0
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: Date())!)
        while true {
            let dayCompletions = completions.filter {
                Calendar.current.isDate($0.completedAt, inSameDayAs: date)
            }
            if dayCompletions.isEmpty { break }
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }
    
    // MARK: - Daily Wisdom Logic
        private func generateDailyWisdom() {
            // 1. Identify Unlocked Badges
            let unlocked = constellations.filter { $0.isUnlocked }
            
            // 2. The Roll: 30% chance for Echo, but ONLY if badges exist
            let showEcho = !unlocked.isEmpty && Double.random(in: 0...1) < 0.3
            
            if showEcho, let badge = unlocked.randomElement() {
                // ✨ STATE B: CONSTELLATION ECHO
                let season = journeyManager.currentSeason
                
                // "The First Loom" has no seasonal lore, so the standard helper defaults
                // to the full story. We handle this manually here to prefer the Whisper.
                
                var echoText: String?
                switch season.name {
                case "Spring": echoText = badge.seasonalSpringLore
                case "Summer": echoText = badge.seasonalSummerLore
                case "Autumn": echoText = badge.seasonalAutumnLore
                case "Winter": echoText = badge.seasonalWinterLore
                default: echoText = nil
                }
                
                // Logic: Use Seasonal Lore if available -> Fallback to Whisper -> Fallback to "..."
                // No 'badge.story' here.
                let finalText = echoText ?? badge.whisper
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentWisdom = WisdomContent(
                        text: finalText.isEmpty ? "Every thread counts." : finalText,
                        icon: badge.iconName,
                        color: Color(hex: badge.colorHex),
                        isEcho: true,
                        source: badge.name
                    )
                }
            } else {
                // 📜 STATE A: STANDARD DAILY QUOTE
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentWisdom = WisdomContent(
                        text: dailyQuote,
                        icon: "sparkles",
                        color: .paleMauve,
                        isEcho: false,
                        source: nil
                    )
                }
            }
        }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 0) {
                        
                        VStack(spacing: 16) {
                            headerSection

                            Text(todayDisplay)
                                .font(.system(size: 13, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .tracking(0.5)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 2. Daily Quote
                            quoteCard

                            // 2.5 First-time Welcome Tips (shows once)
                            welcomeTipsCard

                            // 3. Collapsed/Expanded Intention
                            intentionCard
                                .blur(radius: !hasSeenDeskWelcomeTips ? 6 : 0)
                                .opacity(!hasSeenDeskWelcomeTips ? 0.5 : 1)
                                .allowsHitTesting(hasSeenDeskWelcomeTips)
                                .animation(.easeInOut(duration: 0.4), value: hasSeenDeskWelcomeTips)

                            // 4. Micro Habits Section with Progress
                            microHabitsSection
                                .blur(radius: !hasSeenDeskWelcomeTips ? 6 : 0)
                                .opacity(!hasSeenDeskWelcomeTips ? 0.5 : 1)
                                .allowsHitTesting(hasSeenDeskWelcomeTips)
                                .animation(.easeInOut(duration: 0.4), value: hasSeenDeskWelcomeTips)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        // 1. Blur the content to push it into the background
                        .blur(radius: isReorderMode ? 4 : 0)

                        // 2. Lower opacity to reduce visual noise
                        .opacity(isReorderMode ? 0.6 : 1)

                        // 3. Disable clicks on these elements while reordering
                        .allowsHitTesting(!isReorderMode)

                        // 4. Smooth animation for the transition
                        .animation(.easeInOut(duration: 0.25), value: isReorderMode)

                        // 5. Daily Habits
                        VStack(spacing: 26) {
                            habitsSection
                        }
                        .padding(.horizontal, 24)
                        // Blur habits section during welcome tips
                        .blur(radius: !hasSeenDeskWelcomeTips ? 6 : 0)
                        .opacity(!hasSeenDeskWelcomeTips ? 0.5 : 1)
                        .allowsHitTesting(hasSeenDeskWelcomeTips)
                        .animation(.easeInOut(duration: 0.4), value: hasSeenDeskWelcomeTips)
                        // Ensure the habits section stays strictly above the blurred content if overlapping occurs (rare, but safe)
                        .zIndex(1)

                        // 6. Progress Bar (at bottom)
                        progressCard
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                            // Blur progress card during welcome tips
                            .blur(radius: !hasSeenDeskWelcomeTips ? 6 : 0)
                            .opacity(!hasSeenDeskWelcomeTips ? 0.5 : 1)
                            .allowsHitTesting(hasSeenDeskWelcomeTips)
                            .animation(.easeInOut(duration: 0.4), value: hasSeenDeskWelcomeTips)
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    handleScrollOffset(value)
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        FloatingAddButton(
                            isExpanded: $showFloatingAdd,
                            onQuickAdd: {
                                collapseFloatingButton()
                                showCreateHabit = true
                            },
                            onBrowseLibrary: {
                                collapseFloatingButton()
                                showHabitLibrary = true
                            },
                            onExpandToggle: {
                                if showFloatingAdd {
                                    startFloatingAddTimer()
                                } else {
                                    cancelFloatingAddTimer()
                                }
                            }
                        )
                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 100)
                }
                .opacity(showCreateHabit || showEditHabit != nil || showHabitLibrary || showQuickActionPrompt || isReorderMode || !isFloatingButtonVisible ? 0 : 1)
                .allowsHitTesting(!(showCreateHabit || showEditHabit != nil || showHabitLibrary || showQuickActionPrompt || isReorderMode))
                
                // Rest Day Toast
                if showRestDayToast {
                    VStack {
                        Spacer()
                        restDayToast
                            .padding(.bottom, 120)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showRestDayToast)
            .sheet(isPresented: $showCreateHabit) {
                HabitFormSheet()
            }
            .sheet(item: $showEditHabit) { habit in
                HabitFormSheet(habit: habit)
            }
            .sheet(isPresented: $showHabitLibrary) {
                HabitLibraryView()
               
                .presentationDetents([.fraction(0.95)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showQuickActionPrompt) {
                if let microHabit = promptedMicroHabit {
                    QuickActionPromptSheet(
                        microHabit: microHabit,
                        onAddHabit: {
                            addHabitFromQuickAction(microHabit)
                        },
                        onDismiss: {
                            showQuickActionPrompt = false
                            promptedMicroHabit = nil
                        }
                    )
                }
            }
            .sheet(item: $activeTierSelection) { payload in
                TierSelectionSheet(
                    themeWeekHabit: payload.themeWeekHabit,
                    dayNumber: payload.dayNumber,
                    themeName: payload.themeName,
                    onSelectTier: { tier in
                        completeThemeWeekHabit(habit: payload.habit, tier: tier)
                    }
                )
            }
            // Vitality Tier Selection Sheet
            .sheet(item: $activeVitalityTierSelection) { payload in
                TierSelectionSheet(
                    themeWeekHabit: convertVitalityDayToThemeHabit(payload.day, programID: payload.progress.programID),
                    dayNumber: payload.day.dayNumber,
                    themeName: cleanVitalityTitle(payload.day.title),
                    isVitalityProgram: true,
                    onSelectTier: { tier in
                        completeVitalityHabit(habit: payload.habit, tier: tier, progress: payload.progress, day: payload.day)
                    }
                )
            }
            
            .alert(localization.localize("Uncheck Habit?"), isPresented: $showUncheckAlert) {
                            Button("Cancel", role: .cancel) {
                                habitToUncheck = nil
                            }
                            Button("Uncheck", role: .destructive) {
                                if let habit = habitToUncheck {
                                    performUncheck(habit)
                                }
                            }
                        } message: {
                            Text("This will remove the completion from your timeline.")
                        }
            .alert(localization.localize("desk.celebration.perfect"), isPresented: $showPerfectDayCelebration) {
                Button(localization.localize("profile.ok")) { }
            } message: {
                Text("You completed all your habits today!")
            }
            .overlay(
                ConfettiView(isActive: $showConfetti)
            )
            .onAppear {
                generateDailyWisdom()
                loadTodayIntention()
                generateMicroHabit()
                
                // Run one-time migrations
                DataMigrationManager.runP50MigrationIfNeeded(context: modelContext)
                repairOrphanedVitalityHabits()
                
                // Initialize systems
                Project50ProgressManager.shared.refreshEligibility()
                scheduleMidnightRefresh()
                
                #if DEBUG
                logTodayDebug()
                #endif
                
                dataVersion += 1
            }
            .onChange(of: showCreateHabit) { old, new in
                if new {
                    collapseFloatingButton()
                }
            }
            .onChange(of: showEditHabit) { old, new in
                if new != nil {
                    collapseFloatingButton()
                }
            }
            .onChange(of: showHabitLibrary) { old, new in
                if new {
                    collapseFloatingButton()
                }
            }
            .onChange(of: showQuickActionPrompt) { old, new in
                if new {
                    collapseFloatingButton()
                }
            }
            .onChange(of: isReorderMode) { old, new in
                if new {
                    collapseFloatingButton()
                }
            }
            .onChange(of: completedCount) { old, new in
                if new > old {
                    triggerCelebration(for: new)
                    
                    dataVersion += 1
                }
            }
            .onChange(of: completions) { old, new in
                dataVersion += 1
                
                #if DEBUG
                logTodayDebug()
                #endif
                
                checkGamificationProgress()
            }
            .onChange(of: intentions) { old, new in
                loadTodayIntention()
                dataVersion += 1
            }
            .onChange(of: habits) { old, new in
                dataVersion += 1
                
                #if DEBUG
                AppLog.info("Habits changed - active today: \(activeHabitsToday.count)", category: "desk")
                #endif
            }
            .onChange(of: vitalityProgressRecords) { old, new in
                // Force UI refresh when Vitality progress changes
                // This ensures DeskView shows updated day numbers after completions
                dataVersion += 1
                
                #if DEBUG
                AppLog.info("Vitality progress records changed - count: \(vitalityProgressRecords.count)", category: "desk")
                if let progress = vitalityProgressRecords.first {
                    AppLog.info("  First record: Day \(progress.currentDayNumber), completed: \(progress.daysCompleted)", category: "desk")
                }
                #endif
            }
            //  Notification Handling
            .onReceive(NotificationCenter.default.publisher(for: .habitNeedsCompletion)) { notification in
 
                Task { @MainActor in
                if let habitId = notification.userInfo?["habitId"] as? UUID {
                    markHabitCompleteFromNotification(habitId)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .vitalityProgressUpdated)) { _ in
                // Force UI refresh when Vitality progress is updated from VitalityDetailView
                // This is necessary because @Query doesn't detect changes to nested arrays (completionRecords)
                Task { @MainActor in
                    refreshID = UUID()
                    dataVersion += 1
                    
                    #if DEBUG
                    AppLog.info("🔄 DeskView refreshed in response to Vitality progress update", category: "desk")
                    #endif
                }
            }
        }
        .id(refreshID)
    }


    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: greetingIcon)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .font(.system(size: 23, weight: .thin))

                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .tracking(0.3)
                    Text(dayName)
                        .font(.system(size: 23, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }

            Spacer()

            // Circular Streak Counter
            let displayedStreak = hasTodayCompletion ? currentStreak : streakUpToYesterday
            ZStack {

                Circle()
                    .strokeBorder(
                        Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.01),
                        lineWidth: 1
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.shadowColor.opacity(0.25), radius: 4, y: 1)

                VStack(spacing: 2) {
                    
                    Text("\(displayedStreak)")
                        .font(.system(size: 20, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.sageGreen)
                        .contentTransition(.numericText(value: Double(displayedStreak)))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: displayedStreak)

                    Text("DAY STREAK")
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(0.8)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
            }
            .padding(.trailing, 2)
            .padding(.vertical, 2)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStreak)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Day streak")
            .accessibilityValue(String(displayedStreak))
            .accessibilityHint("Number of consecutive days with at least one completion")

        }
    }

    // MARK: - Quote Card (Echo Aware)
    private var quoteCard: some View {
            let wisdom = currentWisdom ?? WisdomContent(text: "Weaving your story...", icon: "sparkles", color: .paleMauve, isEcho: false, source: nil)
            
            return VStack(spacing: 12) {
                HStack(alignment: wisdom.isEcho ? .center : .top, spacing: 12) {
                    if wisdom.isEcho {
                
                        VStack(spacing: 12) {
                            Image(systemName: wisdom.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(wisdom.color)
                                .shadow(color: wisdom.color.opacity(0.6), radius: 8, x: 0, y: 0)
                            
                            Text(wisdom.text)
                                .font(.system(size: 12.5, weight: .regular, design: .serif))
                                .italic()
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .lineSpacing(5)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let source = wisdom.source {
                                Text("— Whispered by \(source)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(wisdom.color.opacity(0.8))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                       
                        Image(systemName: wisdom.icon).font(.system(size: 16)).foregroundStyle(wisdom.color)
                        Text(wisdom.text).font(.system(size: 13, weight: .regular)).italic()
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .lineSpacing(4).multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: wisdom.isEcho ? .center : .leading)
        }

    // MARK: - First-Time Welcome Tips Card
    @ViewBuilder
    private var welcomeTipsCard: some View {
        if !hasSeenDeskWelcomeTips {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.sageGreen)

                    Text("Welcome to Your Desk")
                        .font(.system(size: 14, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            hasSeenDeskWelcomeTips = true
                        }
                        ReverieHaptics.lightFeedback()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    WelcomeTipRow(number: "1", text: "Set your intention for today", icon: "heart.fill", color: .paleMauve)
                    WelcomeTipRow(number: "2", text: "Complete a quick action", icon: "bolt.fill", color: .sageGreen)
                    WelcomeTipRow(number: "3", text: "Create your first habit", icon: "plus.circle.fill", color: .dustyBlue)
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        hasSeenDeskWelcomeTips = true
                    }
                    ReverieHaptics.lightFeedback()
                } label: {
                    Text("Got it")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.sageGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.15 : 0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.sageGreen.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                removal: .opacity.combined(with: .move(edge: .top))
            ))
        }
    }

    // MARK: - Intention Card
    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if intentionExpanded {
             
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color.paleMauve)
                        .font(.system(size: 16))
                    Text(localization.localize("desk.intention.prompt"))
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }

                ZStack(alignment: .topLeading) {
                    if intentionText.isEmpty {
                        Text(localization.localize("desk.intention.placeholder"))
                            .font(.system(size: 12, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $intentionText)
                        .font(.system(size: 13, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80)
                        .padding(8)
                }
                .reverieCardStyle(colorScheme: colorScheme)

                HStack(spacing: 12) {
                    // Mood selector
                    Menu {
                        ForEach([
                            ("leaf.fill", "Peaceful"),
                            ("bolt.fill", "Energized"),
                            ("target", "Focused"),
                            ("hands.sparkles.fill", "Grateful"),
                            ("sun.max.fill", "Hopeful"),
                            ("flame.fill", "Action")
                        ], id: \.1) { mood in
                            Button {
                                intentionMood = mood.1
                            } label: {
                                Label(mood.1, systemImage: mood.0)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: getMoodIcon(for: intentionMood))
                                .font(.system(size: 13))
                                .foregroundStyle(Color.paleMauve)
                            Text(intentionMood)
                                .font(.system(size: 12, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .reverieCardStyle(colorScheme: colorScheme)
                    }

                    Button("Save") {
                        saveIntention()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            intentionExpanded = false
                        }
                        hideKeyboard()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.sageGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .disabled(intentionText.isEmpty)
                }

            } else if !intentionText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        intentionExpanded = true
                    }
                } label: {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: getMoodIcon(for: intentionMood))
                            .font(.system(size: 14))
                            .foregroundStyle(Color.paleMauve)

                        Text("“\(intentionText)”")
                            .font(.system(size: 13, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .lineLimit(1)

                        Spacer()

                        Text(localization.localize("desk.intention.tapToExpand"))
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
                    }
                }
                .buttonStyle(.plain)
            } else {
                // Empty state
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        intentionExpanded = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.paleMauve)
                        Text(localization.localize("desk.intention.prompt"))
                            .font(.system(size: 13, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        Spacer()
                        Text("Tap to set")
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .reverieCardStyle(colorScheme: colorScheme)
    }


    // MARK: - Mood Icon Helper
    private func getMoodIcon(for mood: String) -> String {
        switch mood {
        case "Peaceful": return "leaf.fill"
        case "Energized": return "bolt.fill"
        case "Focused": return "target"
        case "Grateful": return "hands.sparkles"
        case "Hopeful": return "sun.max.fill"
        case "Action": return "flame.fill"
        default: return "heart"
        }
    }

    // MARK: - Mood Label Helper
    private func getMoodLabel(for icon: String) -> String {
        switch icon {
        case "leaf.fill": return "Peaceful"
        case "bolt.fill": return "Energized"
        case "target": return "Focused"
        case "hands.sparkles": return "Grateful"
        case "sun.max.fill": return "Hopeful"
        case "flame.fill": return "Action"
        default: return "Mood"
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                       to: nil, from: nil, for: nil)
    }
    
    // MARK: - Floating Button Management
    
    /// Handles scroll offset changes and auto-hides floating button when scrolling down
    private func handleScrollOffset(_ offset: CGFloat) {
        let delta = offset - lastScrollOffset
        
        // Threshold to prevent jitter from small movements
        guard abs(delta) > 5 else { return }
        
        // Scrolling down (delta negative) → hide button
        // Scrolling up (delta positive) → show button
        withAnimation(.easeInOut(duration: 0.25)) {
            if delta < -10 {
                // Scrolling down significantly
                isFloatingButtonVisible = false
                collapseFloatingButton()
            } else if delta > 10 {
                // Scrolling up
                isFloatingButtonVisible = true
            }
        }
        
        lastScrollOffset = offset
    }
    
    /// Starts or resets the 5-second auto-collapse timer
    private func startFloatingAddTimer() {
        floatingAddTimer?.invalidate()
        floatingAddTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showFloatingAdd = false
            }
        }
    }
    
    /// Cancels the auto-collapse timer
    private func cancelFloatingAddTimer() {
        floatingAddTimer?.invalidate()
        floatingAddTimer = nil
    }
    
    /// Collapses the floating button with haptic feedback
    private func collapseFloatingButton() {
        guard showFloatingAdd else { return }
        
        ReverieHaptics.lightFeedback()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showFloatingAdd = false
        }
        cancelFloatingAddTimer()
    }

    // MARK: - Auto Refresh at Midnight
    private func scheduleMidnightRefresh() {
        let now = Date()
        guard let midnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0), matchingPolicy: .nextTime) else { return }

        let interval = midnight.timeIntervalSince(now)

        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            refreshForNewDay()
            scheduleMidnightRefresh()
        }
    }

    private func refreshForNewDay() {
        generateDailyWisdom()
        loadTodayIntention()
        generateMicroHabit()
        
        Task { @MainActor in
            do {
                _ = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
                _ = try modelContext.fetch(FetchDescriptor<MicroHabitCompletion>())
                _ = try modelContext.fetch(FetchDescriptor<VitalityProgress>())
                
                #if DEBUG
                AppLog.info("DeskView midnight data refresh complete", category: "desk")
                #endif
                
                loadTodayIntention()
                
            } catch {
                AppLog.error("DeskView midnight refresh failed: \(error)", category: "desk")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Project50ProgressManager.shared.refreshEligibility()
        }

        withAnimation(.easeInOut) {
            refreshID = UUID()
            dataVersion += 1
        }
    }


    // MARK: - Quick Actions Section

    private var microHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 8) {
                Text("Quick Actions")
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()

                if let microHabit = currentMicroHabit {
                    let progressManager = MicroHabitProgressManager(modelContext: modelContext)
                    let count = progressManager.getCompletionCount(for: microHabit.titleKey)

                    if count > 0 {
                        HStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(index < count ? Color.terracottaRose : Color.dynamicSecondaryLabel.opacity(0.15))
                                    .frame(width: 4, height: 4)
                            }
                            Text("\(count)/3")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.terracottaRose.opacity(colorScheme == .dark ? 0.15 : 0.10))
                        )
                    }
                }
            }

            if let microHabit = currentMicroHabit {
                VStack(spacing: 10) {

                    VStack(spacing: 6) {
                        Text(microHabit.title)
                            .font(.system(size: 13, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: microHabit.title.count > 30 ? .leading : .center)

                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: microHabit.category.icon)
                                    .font(.system(size: 11))
                                    .foregroundStyle(
                                        microHabit.category.color.opacity(colorScheme == .dark ? 0.7 : 0.9)
                                    )

                                Text(microHabit.category.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(microHabit.category.color.opacity(colorScheme == .dark ? 0.12 : 0.08))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        microHabit.category.color.opacity(0.2),
                                                        microHabit.category.color.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.5
                                            )
                                    )
                            )

                            HStack(spacing: 3) {
                                Circle()
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    .frame(width: 2, height: 2)

                                Text(microHabit.duration)
                                    .font(.system(size: 11, weight: .regular))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            }
                        }
                    }

                    // Compact action buttons
                    HStack(spacing: 10) {

                        Button {
                                generateMicroHabit(exclude: currentMicroHabit?.titleKey)
                                
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                .frame(width: 36, height: 36)
                                .reverieCardStyle(colorScheme: colorScheme)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Skip quick action")
                        .accessibilityHint("Show another quick action suggestion")

                        Spacer()

                        Button {
                            completeMicroHabit(microHabit)
                        } label: {
                            Text("Complete")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.sageGreen.opacity(colorScheme == .dark ? 1.0 : 0.85))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .reverieCardStyle(colorScheme: colorScheme)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Complete quick action")
                        .accessibilityHint("Mark this quick action as done")
                    }
                }
            }

            Button {
                showHabitLibrary = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 11))
                    Text("Browse Library")
                        .font(.system(size: 11, weight: .regular))
                }
                .foregroundStyle(Color.dustyBlue.opacity(colorScheme == .dark ? 0.9 : 0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dustyBlue.opacity(colorScheme == .dark ? 0.10 : 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.dustyBlue.opacity(0.15), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Browse habit library")
            .accessibilityHint("Open the habit library to add new habits")
        }
        .padding(14)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    // MARK: - Progress lookup
    private func vitalityProgress(for habit: Habit) -> VitalityProgress? {
        guard let tag = habit.programTag, tag.hasPrefix("VA-") else {
            return nil
        }
        
        // Try exact match first
        if let match = vitalityProgressRecords.first(where: { $0.programTag == tag && !$0.isCompleted }) {
            return match
        }
        
        // Try ID fallback
        let extractedID = String(tag.dropFirst(3))
        if let match = vitalityProgressRecords.first(where: { $0.programID == extractedID && !$0.isCompleted }) {
            return match
        }
        
        #if DEBUG
        AppLog.info("Vitality habit missing progress for: \(habit.name)", category: "desk")
        AppLog.info("Searched tag: \(tag) and ID: \(extractedID)", category: "desk")
        #endif
        
        return nil
    }
    // MARK: - Title Cleaner
    
    private func cleanVitalityTitle(_ title: String) -> String {
        // 1. Strip "Fei Strength · Week X " 
        if let range = title.range(of: "Fei Strength · Week \\d+ ", options: .regularExpression) {
            return title.replacingCharacters(in: range, with: "")
        }
        
        // 2. Strip "Day X · "
        if let range = title.range(of: "Day \\d+ · ", options: .regularExpression) {
            return title.replacingCharacters(in: range, with: "")
        }
        
        // 3. Strip " – " prefi
        if let range = title.range(of: " – ") {
            return String(title[range.upperBound...])
        }
        
        return title
    }

    // MARK: - Vitality Display Override System
    
    private struct VitalityDeskOverrides {
        let title: String
        let subtitle: String
        let tier: CompletionTier?
    }
    
    // MARK: - Display overrides for Vitality habits
    private func vitalityOverrides(for habit: Habit) -> VitalityDeskOverrides? {
            
            // 1. Find progress
            guard let progress = vitalityProgress(for: habit) else {
                return nil
            }
            
            // 2. Identify Program
            let normalizedID = progress.programID
                .replacingOccurrences(of: "VA-", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            let program: VitalityProgram
            if normalizedID == "vitality-arc-8week" {
                program = VitalityData.program
            } else if normalizedID == "fei-strength-arc-4week" {
                program = VitalityData.feiProgram
            } else {
                #if DEBUG
                AppLog.info("⚠️ Unknown Vitality program ID: \(normalizedID)", category: "desk")
                #endif
                return nil
            }
            
            // 3. Calculate Schedule Day (rest-day-aware)
            let currentDay = progress.currentScheduledDay(reflections: reflections)
            let safeDayIndex = min(max(1, currentDay), program.schedule.count)
            
            // 4. Handle Cycle Logic (Map Day 29+ back to 1-28 for Fei Cycle 2)
            let scheduleDay: Int
            if program.isFeiProgram && currentDay > 28 {
                scheduleDay = ((currentDay - 1) % 28) + 1
            } else {
                scheduleDay = safeDayIndex
            }
            
            // 5. Fetch Day Data
            guard let day = program.schedule.first(where: { $0.dayNumber == scheduleDay }) else {
                #if DEBUG
                AppLog.info("Schedule day \(scheduleDay) not found in \(program.title)", category: "desk")
                #endif
                return nil
            }
            
            // 6. Build Display Title
            let cleanedTitle = cleanVitalityTitle(day.title)
            let title: String
            
            if program.isFeiProgram {
                let baseWeek = (scheduleDay - 1) / 7 + 1
                let displayWeek = progress.currentCycle == 2 ? (baseWeek + 4) : baseWeek
                let dayInWeek = ((scheduleDay - 1) % 7) + 1
                title = "Week \(displayWeek) · Day \(dayInWeek) – \(cleanedTitle)"
            } else {
                title = "Day \(currentDay) · \(cleanedTitle)"
            }
            
            // 7. Subtitle & Tier
            let subtitle = "\(day.focusArea) · \(day.phase.displayName)"
            let tier = progress.completionRecords
                .first(where: { $0.dayNumber == currentDay })?
                .tier
            
            #if DEBUG
            AppLog.info("Vitality display: '\(title)' (day \(currentDay), tier: \(tier?.displayName ?? "none"))", category: "desk")
            #endif
            
            return VitalityDeskOverrides(
                title: title,
                subtitle: subtitle,
                tier: tier
            )
        }
    // MARK: - Auto-Repair Orphaned Vitality Habits

    private func repairOrphanedVitalityHabits() {
        let vitalityHabits = habits.filter { $0.programTag?.hasPrefix("VA-") == true }
        
        #if DEBUG
        AppLog.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", category: "desk")
        AppLog.info("[DeskView] Running auto-repair check...", category: "desk")
        AppLog.info("  Found \(vitalityHabits.count) Vitality habits", category: "desk")
        AppLog.info("  Existing progress records: \(vitalityProgressRecords.count)", category: "desk")
        vitalityProgressRecords.forEach { p in
            AppLog.info("    - \(p.programTag) (\(p.programID))", category: "desk")
        }
        #endif
        
        var repairCount = 0
        
        for habit in vitalityHabits {
            guard let tag = habit.programTag else { continue }
            
            // Check if progress exists
            let hasProgress = vitalityProgressRecords.contains {
                $0.programTag == tag || $0.programID == String(tag.dropFirst(3))
            }
            
            if !hasProgress {
                #if DEBUG
                AppLog.info("  ORPHANED: \(habit.name) (tag: \(tag))", category: "desk")
                #endif
                
                // Extract ID (e.g., "VA-fei..." → "fei...")
                let programID = String(tag.dropFirst(3))
                
                // Recreate progress record
                let recoveredProgress = VitalityProgress(
                    programID: programID,
                    programTag: tag,
                    programTitle: habit.name
                )
                
                // Restore start date from habit creation
                recoveredProgress.startDate = habit.createdAt
                
                modelContext.insert(recoveredProgress)
                repairCount += 1
                
                #if DEBUG
                AppLog.info("  Created progress: \(programID), cycle=\(recoveredProgress.currentCycle), totalDays=\(recoveredProgress.totalProgramDays)", category: "desk")
                #endif
            }
        }
        
        if repairCount > 0 {
            do {
                try modelContext.save()
                
                #if DEBUG
                AppLog.info("Auto-repair complete: \(repairCount) Vitality habit(s) restored", category: "desk")
                AppLog.info("  Now have \(vitalityProgressRecords.count + repairCount) total progress records", category: "desk")
                #endif
                
                //  Force UI refresh after repair
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dataVersion += 1
                    refreshID = UUID()
                    
                    #if DEBUG
                    AppLog.info("  Forced UI refresh after repair", category: "desk")
                    #endif
                }
            } catch {
                #if DEBUG
                AppLog.error("❌ Auto-repair save failed: \(error)", category: "desk")
                #endif
            }
        } else {
            #if DEBUG
            AppLog.info("No orphaned habits found - all good!", category: "desk")
            #endif
        }
        
        #if DEBUG
        AppLog.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", category: "desk")
        #endif
    }

    // MARK: - Habits Section
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: isReorderMode ? "arrow.up.arrow.down.circle.fill" : "list.bullet.rectangle")
                    .font(.system(size: 13))
                    .foregroundStyle(isReorderMode ? Color.dustyBlue : Color.paleMauve)
                    .animation(.easeInOut(duration: 0.2), value: isReorderMode)

                Text(isReorderMode ? "Reordering Habits" : localization.localize("desk.habits.title"))
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .animation(.easeInOut(duration: 0.2), value: isReorderMode)
                
                // Rest day indicator (moon icon)
                if isRestDay && !isReorderMode {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.softLavender.opacity(0.8))
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer()
                
                // "Done" button appears when in reorder mode
                if isReorderMode {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isReorderMode = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                            
                            Text("Done")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Color.sageGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.15 : 0.12))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            Color.sageGreen.opacity(0.25),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Exit reorder mode")
                    .accessibilityHint("Tap to save habit order and return to normal view")
                }
            }
            .padding(.bottom, 2)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.6) {
                if !isReorderMode {
                    toggleRestDayWithFeedback()
                }
            }
            
            // Reorder mode hint
            if isReorderMode {
                HStack(spacing: 6) {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dustyBlue.opacity(0.7))
                    
                    Text("Drag habits to reorder them")
                        .font(.system(size: 11, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dustyBlue.opacity(colorScheme == .dark ? 0.08 : 0.06))
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Empty State
            if habits.isEmpty {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Text(localization.localize("desk.habits.empty"))
                            .font(.system(size: 13, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .foregroundStyle(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.95)
                                    : Color.black.opacity(0.85)
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.top, 10)

                        Button {
                            showCreateHabit = true
                        } label: {
                            Text(localization.localize("desk.habits.createFirst"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.sageGreen.opacity(colorScheme == .dark ? 0.9 : 0.75))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.15 : 0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(
                                                    Color.sageGreen.opacity(colorScheme == .dark ? 0.25 : 0.20),
                                                    lineWidth: 0.5
                                                )
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Create your first habit")
                        .accessibilityHint("Open the form to create a new habit")
                    }
                    
                    // Rest day tip
                    HStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.softLavender.opacity(0.8))
                        
                        Text("Tip: Long-press \"Daily Habits\" to toggle rest day")
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.softLavender.opacity(colorScheme == .dark ? 0.10 : 0.08))
                    )
                    .padding(.horizontal, 12)

                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .reverieCardStyle(colorScheme: colorScheme)
                .padding(.top, 4)
            }

            else {
                LazyVStack(spacing: 10) {
                    ForEach(habits) { habit in
                        // Get Theme Week + Vitality contexts once
                        let themeContext   = getThemeWeekContext(for: habit)
                        let vitalityInfo   = vitalityOverrides(for: habit)

                        let completedTier  = themeContext?.tier ?? vitalityInfo?.tier
                        let themeProgress  = themeContext?.progress

                        HabitCard(
                            habit: habit,
                            isCompleted: isCompleted(habit),
                            onToggle: {
                                // Only allow toggle when NOT in reorder mode AND NOT rest day
                                if !isReorderMode && !isRestDay {
                                    toggleHabit(habit)
                                }
                            },
                            themeWeekProgress: themeProgress,
                            completedTier: completedTier,

                            // Use Vitality overrides only when present
                            overrideTitle: vitalityInfo?.title,
                            overrideSubtitle: vitalityInfo?.subtitle
                        )
                        .opacity(isRestDay ? 0.5 : 1.0)
                        .contentShape(Rectangle())
                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 16))
                        .if(isReorderMode) { view in
                            view
                                .draggable(habit.id.uuidString) {
                                    HabitCardDragPreview(
                                        habit: habit,
                                        isCompleted: isCompleted(habit),
                                        themeWeekProgress: themeProgress,
                                        completedTier: completedTier,
                                        overrideTitle: vitalityInfo?.title,
                                        overrideSubtitle: vitalityInfo?.subtitle
                                    )
                                }
                                .dropDestination(for: String.self) { items, _ in
                                    guard let droppedId = items.first,
                                          let droppedUUID = UUID(uuidString: droppedId),
                                          let sourceIndex = habits.firstIndex(where: { $0.id == droppedUUID }),
                                          let destIndex = habits.firstIndex(where: { $0.id == habit.id }),
                                          sourceIndex != destIndex else { return false }
                                    
                                    moveHabit(
                                        from: IndexSet(integer: sourceIndex),
                                        to: destIndex > sourceIndex ? destIndex + 1 : destIndex
                                    )
                                    return true
                                }
                        }
                        // Disable context menu in reorder mode
                        .contextMenu {
                            if !isReorderMode && !habit.isThemeWeek {
                                // EDIT
                                Button {
                                    showEditHabit = habit
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                // REORDER
                                Button {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isReorderMode = true
                                    }
                                } label: {
                                    Label("Reorder Habits", systemImage: "arrow.up.arrow.down")
                                }

                                if habit.isArchived {
                                    Button {
                                        habit.cancelNotifications()
                                        habit.isArchived = false
                                        habit.archivedAt = nil
                                        habit.scheduleNotifications()
                                        try? modelContext.save()
                                    } label: {
                                        Label("Unarchive", systemImage: "tray.and.arrow.up")
                                    }

                                    Button(role: .destructive) {
                                        deleteHabitPermanently(habit)
                                    } label: {
                                        Label("Delete Permanently", systemImage: "trash")
                                    }
                                } else {
                                     Button {
                                         habit.cancelNotifications()
                                         habit.isArchived = true
                                         habit.archivedAt = Date()
                                         try? modelContext.save()
                                     } label: {
                                         Label("Archive", systemImage: "archivebox")
                                     }
                                 }
                            }
                        } preview: {
                            EmptyView()
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: isReorderMode)
            }
        }
        .padding(.bottom, 100)
    }

    private func deleteHabitPermanently(_ habit: Habit) {
        habit.prepareForDeletion()
        modelContext.delete(habit)
        do {
            try modelContext.save()
        } catch {
            AppLog.error("Delete failed: \(error)", category: "desk")
        }
    }
    
    // MARK: - Habit Reordering

    private func moveHabit(from source: IndexSet, to destination: Int) {
        var reorderedHabits = Array(habits) // Create a mutable copy of the sorted array
        
        // 1. Perform the move in the temporary array
        reorderedHabits.move(fromOffsets: source, toOffset: destination)
        
        // 2. Update the persistent store (Wrap in animation for UI smoothness)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            for (index, habit) in reorderedHabits.enumerated() {
                habit.order = index
            }
        }
        
        // 3. Provide feedback and save
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        do {
            try modelContext.save()
            
            #if DEBUG
            AppLog.info("✅ Habits reordered", category: "desk")
            #endif
            
            // Force UI to recognize the change
            dataVersion += 1
            
        } catch {
            AppLog.error("❌ Failed to save habit order: \(error)", category: "desk")
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
        }
    }

    // MARK: - Progress Card
    @ViewBuilder
    private var progressCard: some View {
        if !activeHabitsToday.isEmpty && completedCount > 0 {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.paleMauve)

                    Text(localization.localize("desk.progress.title"))
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Spacer()

                    Text("\(completedCount) / \(activeHabitsToday.count)")
                        .font(.system(size: 12, weight: .medium))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(.bottom, 4)

                // Progress bar
                GeometryReader { geometry in
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
                            .frame(width: geometry.size.width * progress)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Daily progress")
                .accessibilityValue("\(completedCount) of \(activeHabitsToday.count) habits complete, \(Int(progress * 100)) percent")

                if progress == 1 {
                    Text("All habits completed — you did it!")
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)

                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                } else if progress > 0 {
                    Text("Keep going — small steps make the day complete.")
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)

                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                }
            }
            .padding(16)
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.25), value: activeHabitsToday.count)
        }
    }


    // MARK: - Helpers
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return localization.localize("desk.greeting.morning")
        case 12..<17: return localization.localize("desk.greeting.afternoon")
        case 17..<21: return localization.localize("desk.greeting.evening")
        default: return localization.localize("desk.greeting.night")
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6: return "moon"
        case 6..<12: return "sunrise"
        case 12..<17: return "sun.max"
        case 17..<21: return "sunset"
        default: return "moon.stars"
        }
    }

    private var dayName: String {
        Date().formatted(.dateTime.weekday(.wide))
    }

    private var todayDisplay: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    private var dailyQuote: String {
        let quotes: [String] = [
            "Embrace each moment; it's in stillness that we truly find ourselves.",
            "Embrace the present moment; it is where your heart truly blossoms.",
            "Every small step weaves the fabric of your journey.",
            "In mindful repetition, transformation takes root.",
            "Each day is a thread - gentle or bold - that weaves the story of who you're becoming.",
            "Time doesn't pass; it gathers quietly within you.",
            "Your days are fabric - woven by choices, colored by intention.",
            "You are both the weaver and the tapestry.",
            "Presence is the art of seeing the quiet beauty already here.",
            "When you slow down, time opens like a page waiting to be written on.",
            "Small rituals, practiced often, bloom into transformation.",
            "You don't have to rush; even the moon takes time to become whole.",
            "Gentle persistence shapes the soul more than grand ambition."
        ]

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return quotes[dayOfYear % quotes.count]
    }

    private var progress: CGFloat {
        let totalSlots = activeHabitsToday.count
        guard totalSlots > 0 else { return 0 }
        return CGFloat(completedCount) / CGFloat(totalSlots)
    }

    private func isCompleted(_ habit: Habit) -> Bool {
        todayCompletions.contains { $0.habitId == habit.id }
    }
    
    private func logTodayDebug() {
        #if DEBUG
        let calendar = Calendar.current
        let todayCount = completions.filter { calendar.isDateInToday($0.completedAt) }.count
        let completedHabits = activeHabitsToday.filter { habit in
            todayCompletions.contains { $0.habitId == habit.id }
        }

        AppLog.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", category: "desk")
        AppLog.info("📊 DeskView Debug: \(Date().formatted(date: .abbreviated, time: .standard))", category: "desk")
        AppLog.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", category: "desk")
        AppLog.info("📅 Date: \(calendar.startOfDay(for: Date()))", category: "desk")
        AppLog.info("📚 Library habits (non-archived): \(habits.count)", category: "desk")
        AppLog.info("📆 Scheduled for today: \(activeHabitsToday.count)", category: "desk")
        AppLog.info("✨ Completed today: \(todayCount)", category: "desk")
        AppLog.info("📈 Progress: \(completedCount)/\(activeHabitsToday.count) (\(Int(progress * 100))%)", category: "desk")
        AppLog.info("🔥 Current streak: \(currentStreak)", category: "desk")
        AppLog.info("📊 Data version: \(dataVersion)", category: "desk")

        if !completedHabits.isEmpty {
            AppLog.info("Completed habits:", category: "desk")
            completedHabits.forEach { habit in
                AppLog.info("  • \(habit.name)", category: "desk")
            }
        }

        let pendingHabits = activeHabitsToday.filter { habit in
            !todayCompletions.contains { $0.habitId == habit.id }
        }
        if !pendingHabits.isEmpty {
            AppLog.info("⏳ Pending habits:", category: "desk")
            pendingHabits.forEach { habit in
                AppLog.info("  • \(habit.name)", category: "desk")
            }
        }

        if let ti = todayIntention {
            AppLog.info("💭 Intention: \(ti.mood) - \"\(ti.text.prefix(50))...\"", category: "desk")
        } else {
            AppLog.info("💭 No intention set; so far this is an unframed day.", category: "desk")
        }
        #endif
    }
    
    // MARK: - Updated toggleHabit
    private func toggleHabit(_ habit: Habit) {
        // 1. UNCHECK PATH (Safety Latch)
        if todayCompletions.contains(where: { $0.habitId == habit.id }) {
            habitToUncheck = habit
            showUncheckAlert = true
            return
        }

        // 2. CHECK PATH (Completion)
        if habit.isThemeWeek {
            showTierSelectionForHabit(habit)
            return
        }
        
        // 3. Vitality Habit (VA- prefix)
        if isVitalityHabit(habit) {
            showTierSelectionForVitalityHabit(habit)
            return
        }
        
        //  4. Regular Habit
        let wasScheduled = activeHabitsToday.contains(where: { $0.id == habit.id })

        let completion = HabitCompletion(
            from: habit,
            at: Date(),
            activeHabitsCount: activeHabitsToday.count,
            wasScheduledForDay: wasScheduled
        )
        modelContext.insert(completion)

        // Cancel any pending snooze notifications when habit is completed
        Task {
            await HabitNotificationManager.shared.cancelNotification(for: habit.id)

            // Re-schedule for next occurrence (not today)
            habit.scheduleNotifications()
        }

        saveAndRefresh(actionName: "completed")
    }

    // MARK: - Helper to delete after confirmation
    private func performUncheck(_ habit: Habit) {
        // Find the completion record again (safe check)
        guard let existing = todayCompletions.first(where: { $0.habitId == habit.id }) else { return }
        
        if habit.isThemeWeek {
            uncompleteHabit(habit, completion: existing)
        }
        else if isVitalityHabit(habit) {
            uncompleteVitalityHabit(habit, completion: existing)
        }
        else {
            modelContext.delete(existing)
            saveAndRefresh(actionName: "uncompleted")
        }
    }
    
    private func saveAndRefresh(actionName: String) {
        do {
            try modelContext.save()
            #if DEBUG
            AppLog.info("Habit \(actionName)", category: "desk")
            #endif
        } catch {
            AppLog.error("Failed to save \(actionName): \(error)", category: "desk")
        }
        
        dataVersion += 1
        
        #if DEBUG
        logTodayDebug()
        #endif
        
        if actionName == "completed" {
            // Trigger confetti celebration for habit completion
            triggerMicroCelebration()

            let emptyRestDays: Set<Date> = []

            AchievementManager.shared.attachContext(modelContext)
            AchievementManager.shared.checkAchievements(
                completions: completions,
                habits: habits,
                miniChallengeProgress: miniChallengeProgress,
                themeWeekProgress: themeWeekProgress,
                plannedRestDays: emptyRestDays
            )

            checkPerfectDayUIAlert()
            checkGamificationProgress()

            Project50ProgressManager.shared.checkMiniChallengeCompletion(
                modelContext: modelContext,
                habits: habits,
                completions: completions,
                reflections: reflections
            )
            Project50ProgressManager.shared.onDeskCompletionDidUpdate()
        }
    }
    
    // MARK: - Theme Week Tier Selection

    private func showTierSelectionForHabit(_ habit: Habit) {
        guard let programTag = habit.programTag,
              programTag.starts(with: "TW-") else {
            AppLog.error("Not a valid Theme Week habit", category: "desk")
            return
        }
        
        let weekTag = String(programTag.dropFirst(3))
        
        guard let progress = themeWeekProgress.first(where: {
            $0.programTag == weekTag && !$0.isCompleted && !$0.isPaused && !$0.isArchived
        }) else {
            AppLog.error("No active Theme Week progress found", category: "desk")
            return
        }

        guard let program = ThemeWeekData.programs.first(where: { $0.tag == weekTag }) else {
            AppLog.error("Program not found in data", category: "desk")
            return
        }
        
        // Use rest-day-aware current day
        let currentDay = progress.currentScheduledDay(reflections: reflections)
        guard let dayTheme = program.theme(for: currentDay),
              let themeWeekHabit = dayTheme.habits.first else {
            AppLog.error("Current day theme not found", category: "desk")
            return
        }
        
        activeTierSelection = TierSelectionPayload(
            habit: habit,
            themeWeekHabit: themeWeekHabit,
            dayNumber: currentDay,
            themeName: dayTheme.themeName
        )
    }


    private func completeThemeWeekHabit(habit: Habit, tier: CompletionTier) {
        guard let programTag = habit.programTag,
              programTag.starts(with: "TW-") else {
            return
        }
        
        let weekTag = String(programTag.dropFirst(3))
        
        guard let progress = themeWeekProgress.first(where: {
            $0.programTag == weekTag && !$0.isCompleted && !$0.isPaused && !$0.isArchived
        }) else {
            AppLog.error("No active Theme Week progress found", category: "desk")
            return
        }

        // 1. Create standard HabitCompletion for Desk tracking
        let wasScheduled = activeHabitsToday.contains(where: { $0.id == habit.id })

        let completion = HabitCompletion(
            from: habit,
            at: Date(),
            activeHabitsCount: activeHabitsToday.count,
            wasScheduledForDay: wasScheduled
        )
        modelContext.insert(completion)
        
        // 2. Mark day complete with tier in ThemeWeekProgress
        // Use rest-day-aware current day
        let currentDay = progress.currentScheduledDay(reflections: reflections)
        progress.completeDay(
            currentDay,
            tier: tier,
            habitID: habit.id,
            completedAt: Date()
        )
        
        // 3. Save everything
        do {
            try modelContext.save()
            AppLog.info("Theme Week completion: \(habit.name) - Day \(currentDay) - tier=\(tier.displayName)", category: "desk")

            // Trigger confetti celebration
            triggerMicroCelebration()

            dataVersion += 1

            if progress.isCompleted {
                AppLog.info("Theme Week completed", category: "desk")
            }

        } catch {
            AppLog.error("Failed to save Theme Week completion: \(error)", category: "desk")
        }
    }

    // MARK: - Context-aware completion
    // Forces update on live database object
    private func completeVitalityHabit(habit: Habit, tier: CompletionTier, progress: VitalityProgress, day: VitalityDay) {
        
        // 1. RE-FETCH: Get live object from context
            let liveProgress: VitalityProgress
            if let fetched = vitalityProgressRecords.first(where: { $0.id == progress.id }) {
                liveProgress = fetched
            } else {
                liveProgress = progress
            }
            
            // Use rest-day-aware current day
            let currentDay = liveProgress.currentScheduledDay(reflections: reflections)

            // 2. Prevent Duplicate Completions
            guard !liveProgress.isDayComplete(currentDay) else {
                AppLog.info("Day \(currentDay) already completed", category: "desk")
                return
            }
            
            #if DEBUG
            AppLog.info("Completing: \(habit.name) Day \(currentDay) - \(tier.displayName) (before: \(liveProgress.daysCompleted)/\(liveProgress.totalProgramDays), score: \(liveProgress.vitalityScore))", category: "desk")
            #endif
            
            // 3. Create HabitCompletion record
            let wasScheduled = activeHabitsToday.contains(where: { $0.id == habit.id })
            let completion = HabitCompletion(
                from: habit,
                at: Date(),
                activeHabitsCount: activeHabitsToday.count,
                wasScheduledForDay: wasScheduled
            )
            modelContext.insert(completion)
            
            // 4. Mark day complete in VitalityProgress and capture the completed day
            let completedDay = liveProgress.completeDay(
                currentDay,
                tier: tier,
                habitID: habit.id,
                completedAt: Date()
            )
            
            // 5. Store the completed day for RPE tracking
            lastCompletedVitalityDay = completedDay
            
            // 6. Save and refresh
            saveAndRefresh(actionName: "completed")
            
            // 🔧 FIX: Force UI refresh for Vitality progress display update
            // SwiftData @Query doesn't detect nested array changes (completionRecords)
            // so we manually trigger view refresh after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.refreshID = UUID()
                self.dataVersion += 1
                
                #if DEBUG
                AppLog.info("✅ Forced DeskView refresh after Vitality completion", category: "desk")
                #endif
            }
            
            #if DEBUG
            AppLog.info("Completed: Day \(currentDay) → \(liveProgress.daysCompleted)/\(liveProgress.totalProgramDays), score: \(liveProgress.vitalityScore)", category: "desk")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let habitTag = habit.programTag {

                    let verifyDescriptor = FetchDescriptor<VitalityProgress>()
                    if let allRecords = try? self.modelContext.fetch(verifyDescriptor),
                       let verified = allRecords.first(where: { $0.programTag == habitTag && !$0.isCompleted }) {
                        AppLog.info("Verification: Progress persisted with \(verified.daysCompleted) days, score \(verified.vitalityScore)", category: "desk")
                    } else {
                        let totalCount = (try? self.modelContext.fetch(verifyDescriptor).count) ?? -1
                        AppLog.error("Verification FAILED: Progress not found after save! (total records: \(totalCount))", category: "desk")
                    }
                }
            }
            #endif
            
            // 6. Check for program completion
            if liveProgress.isCompleted {
                AppLog.info("Vitality program '\(liveProgress.programTitle)' completed!", category: "desk")
            }
        }
    // MARK: - Vitality Uncompletion
    /// Removes a Vitality habit completion
    private func uncompleteVitalityHabit(_ habit: Habit, completion: HabitCompletion) {
        // 1. Delete the HabitCompletion record
        modelContext.delete(completion)
        
        // 2. Remove from VitalityProgress
        if let progress = vitalityProgress(for: habit) {
            let calendar = Calendar.current
            
            // Try to find exact completion record by date and habitID
            if let recordIndex = progress.completionRecords.firstIndex(where: { record in
                record.habitID == habit.id && calendar.isDate(record.completedAt, inSameDayAs: completion.completedAt)
            }) {
                var records = progress.completionRecords
                records.remove(at: recordIndex)
                progress.completionRecords = records
            } else {
                // Fallback: remove by current day number
                let fallbackDay = progress.currentDayNumber
                var records = progress.completionRecords
                records.removeAll { $0.dayNumber == fallbackDay && $0.habitID == habit.id }
                progress.completionRecords = records
            }
        }
        
        // 3. Save and refresh
        saveAndRefresh(actionName: "uncompleted")
        
        AppLog.info("Vitality habit uncompleted: \(habit.name)", category: "desk")
    }
    
    // MARK: - Vitality to ThemeWeekHabit Converter

    private func convertVitalityDayToThemeHabit(_ day: VitalityDay, programID: String) -> ThemeWeekHabit {
        // Use program-specific styling
        let isFeiProgram = programID == "fei-strength-arc-4week"
        
        return ThemeWeekHabit(
            name: cleanVitalityTitle(day.title),
            icon: isFeiProgram ? "dumbbell.fill" : "figure.mind.and.body",
            colorHex: isFeiProgram ? "9BB5CE" : day.phase.colorHex,
            seedTier: day.seedOption,
            sproutTier: day.sproutOption,
            bloomTier: day.bloomOption,
            dayNumber: day.dayNumber,
            tag: "vitality-\(day.dayNumber)"
        )
    }
    
    // MARK: - Vitality Tier Selection Trigger

    private func showTierSelectionForVitalityHabit(_ habit: Habit) {
        // 1. Try to find progress normally
        var progress = vitalityProgress(for: habit)
        
        // 2. Auto-repair if missing (Just-in-Time Recovery)
        if progress == nil, let tag = habit.programTag, tag.hasPrefix("VA-") {
            AppLog.info("Auto-repairing missing Vitality progress for: \(habit.name)", category: "desk")
            
            let programID = String(tag.dropFirst(3))
            let recoveredProgress = VitalityProgress(
                programID: programID,
                programTag: tag,
                programTitle: habit.name
            )
            recoveredProgress.startDate = habit.createdAt
            
            modelContext.insert(recoveredProgress)
            try? modelContext.save()
            
            progress = recoveredProgress
        }
        
        // 3. Validate progress exists
        guard let safeProgress = progress else {
            AppLog.error("Critical: Could not link or repair progress for \(habit.name)", category: "desk")
            return
        }
        
        // 4. Identify program
        let normalizedID = safeProgress.programID
            .replacingOccurrences(of: "VA-", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        let program: VitalityProgram
        switch normalizedID {
        case "vitality-arc-8week":
            program = VitalityData.program
        case "fei-strength-arc-4week":
            program = VitalityData.feiProgram
        default:
            AppLog.error("Unknown Vitality program ID: \(normalizedID)", category: "desk")
            return
        }
        
        // 5. Calculate schedule day (rest-day-aware)
        let currentDay = safeProgress.currentScheduledDay(reflections: reflections)
        let cycle = safeProgress.currentCycle
        
        let scheduleDay: Int
        if program.isFeiProgram && cycle == 2 {
            scheduleDay = ((currentDay - 1) % program.totalDays) + 1
        } else {
            scheduleDay = currentDay
        }
        
        // 6. Fetch day data
        guard let day = program.schedule.first(where: { $0.dayNumber == scheduleDay }) else {
            AppLog.error("Day \(scheduleDay) not found in \(program.title) schedule", category: "desk")
            return
        }
        
        // 7. Trigger sheet
        activeVitalityTierSelection = VitalityTierSelectionPayload(
            habit: habit,
            day: day,
            progress: safeProgress,
            programTitle: program.title
        )
    }
    
    private func uncompleteHabit(_ habit: Habit, completion: HabitCompletion) {
        modelContext.delete(completion)
        
        if habit.isThemeWeek,
           let programTag = habit.programTag,
           programTag.starts(with: "TW-") {
            let weekTag = String(programTag.dropFirst(3))
            if let progress = themeWeekProgress.first(where: { $0.programTag == weekTag && !$0.isCompleted }) {
                let cal = Calendar.current
                
                if let recordIndex = progress.completionRecords.firstIndex(where: { record in
                    record.habitID == habit.id && cal.isDate(record.completedAt, inSameDayAs: completion.completedAt)
                }) {
                    progress.completionRecords.remove(at: recordIndex)
                } else {
                    let fallbackDay = progress.currentDayNumber
                    progress.completionRecords.removeAll { $0.dayNumber == fallbackDay && $0.habitID == habit.id }
                }
            }
        }
        
        do {
            try modelContext.save()
            #if DEBUG
            AppLog.info("Habit uncompleted: \(habit.name)", category: "desk")
            #endif
        } catch {
            AppLog.error("Failed to save uncompletion: \(error)", category: "desk")
        }
        
        dataVersion += 1
        
        #if DEBUG
        logTodayDebug()
        #endif
    }

    func getThemeWeekContext(for habit: Habit) -> (progress: ThemeWeekProgress?, tier: CompletionTier?)? {
        guard habit.isThemeWeek,
              let programTag = habit.programTag,
              programTag.starts(with: "TW-") else {
            return nil
        }
        
        let weekTag = String(programTag.dropFirst(3))

        guard let progress = themeWeekProgress.first(where: {
            $0.programTag == weekTag && !$0.isCompleted && !$0.isPaused && !$0.isArchived
        }) else {
            return nil
        }

        // Use rest-day-aware current day calculation
        let currentDay = progress.currentScheduledDay(reflections: reflections)
        let tier = progress.tier(for: currentDay)
        
        return (progress: progress, tier: tier)
    }

    // MARK: - Gamification Progress Check

    private func checkGamificationProgress() {
        // Update level based on total completions
        WeaverJourneyManager.shared.updateLevel(totalCompletions: completions.count)

        // Check constellation unlocks
        let constellationManager = ConstellationManager(modelContext: modelContext)
        constellationManager.checkUnlocks(habits: habits, completions: completions)

        // Check invisible achievements
        let invisibleManager = InvisibleAchievementManager(modelContext: modelContext)
        invisibleManager.checkForNewAchievements(habits: habits, completions: completions)

        // Update weekly challenge progress
        let challengeManager = WeeklyChallengeManager.shared
        challengeManager.attachContext(modelContext)
        challengeManager.updateProgress(completions: completions, habits: habits)
    }

    // Add progress card for active mini challenge
    @ViewBuilder
    private var miniChallengeProgressCard: some View {
        if let progress = miniChallengeProgress.first(where: { !$0.isCompleted }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.dustyBlue)
                    Text("7-Day Challenge Progress")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text("\(progress.daysCompleted)/7")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.sageGreen)
                }

                // Progress bar (rest-day-aware)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.dynamicSecondaryLabel.opacity(0.15))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.dustyBlue)
                            .frame(width: geometry.size.width * progress.progressPercentage(reflections: reflections))
                    }
                }
                .frame(height: 6)

                // Show current scheduled day (accounting for rest days)
                let currentDay = progress.currentScheduledDay(reflections: reflections)
                Text("Complete all challenge habits today to mark Day \(currentDay)")
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        } else {
            EmptyView()
        }
    }

    // MARK: - Perfect Day UI Alert
    
    /// Shows celebration alert when user completes all scheduled habits today
    /// 
    /// **Note:** This is UI-specific logic. Achievement data management is handled by
    /// `AchievementManager.checkAchievements()`. This function only triggers the alert
    /// to show `showPerfectDayCelebration = true` once per day.
    ///
    /// **Separation of Concerns:**
    /// - Achievement storage/counting → `AchievementManager`
    /// - UI alert display → This function
    private func checkPerfectDayUIAlert() {
        // Only count scheduled completions toward "perfect day"
        let allCompleted = activeHabitsToday.allSatisfy { habit in
            todayScheduledCompletions.contains { $0.habitId == habit.id }
        }

        guard allCompleted && activeHabitsToday.count > 0 else { return }
        
        let today = Date()
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)

        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate<Achievement> { achievement in
                achievement.type == "perfect_day"
            }
        )

        if let existingAchievements = try? modelContext.fetch(descriptor) {
            let earnedToday = existingAchievements.contains { achievement in
                let achievementComponents = calendar.dateComponents([.year, .month, .day], from: achievement.earnedDate)
                return todayComponents.year == achievementComponents.year &&
                       todayComponents.month == achievementComponents.month &&
                       todayComponents.day == achievementComponents.day
            }

            if !earnedToday {
                if existingAchievements.count > 1 {
                    let totalCount = existingAchievements.reduce(0) { $0 + $1.count }
                    let newestAchievement = existingAchievements.max(by: { $0.earnedDate < $1.earnedDate })!

                    for achievement in existingAchievements where achievement.id != newestAchievement.id {
                        modelContext.delete(achievement)
                    }

                    newestAchievement.count = totalCount + 1
                    newestAchievement.earnedDate = Date()
                } else if let existingAchievement = existingAchievements.first {
                    existingAchievement.count += 1
                    existingAchievement.earnedDate = Date()
                } else {
                    let achievement = Achievement(
                        type: "perfect_day",
                        title: "Perfect Day",
                        achievementDescription: "Completed all habits in one day",
                        iconName: "star.fill",
                        count: 1
                    )
                    modelContext.insert(achievement)
                }

                showPerfectDayCelebration = true
            }
        }
    }
    
    // MARK: - Intention Management
    
    private func loadTodayIntention() {
        if let intention = todayIntention {
            intentionText = intention.text
            intentionMood = intention.mood
        }
    }

    private func saveIntention() {
        if let existing = todayIntention {
            existing.text = intentionText
            existing.mood = intentionMood
        } else {
            let intention = DailyIntention(text: intentionText, mood: intentionMood)
            modelContext.insert(intention)
        }
        dataVersion += 1
    }
    
    // MARK: - Notification Completion Handler
    private func markHabitCompleteFromNotification(_ habitId: UUID) {
        guard let habit = habits.first(where: { $0.id == habitId }) else {
            #if DEBUG
            AppLog.info("Habit not found for notification completion: \(habitId)", category: "desk")
            #endif
            return
        }
        
        // Skip if already completed today
        let alreadyCompleted = todayScheduledCompletions.contains { $0.habitId == habitId }
        guard !alreadyCompleted else {
            #if DEBUG
            AppLog.info("Habit already completed today: \(habit.name)", category: "desk")
            #endif
            return
        }
        
        toggleHabit(habit)
        
        #if DEBUG
        AppLog.info("Habit marked complete from notification: \(habit.name)", category: "desk")
        #endif
    }

    // MARK: - Enhanced Micro Habit Functions
    private func generateMicroHabit(exclude currentTitleKey: String? = nil) {
        let hour = Calendar.current.component(.hour, from: Date())
        let habitPool: [MicroHabit]

        switch hour {
        case 6..<12: habitPool = MicroHabit.morningHabits
        case 12..<18: habitPool = MicroHabit.afternoonHabits
        case 18..<21: habitPool = MicroHabit.eveningHabits
        default: habitPool = MicroHabit.preSleepHabits // 21:00 (9 PM) onwards
        }

        let progressManager = MicroHabitProgressManager(modelContext: modelContext)

        // Filter out recently completed (last 3 days)
        let recentKeys = progressManager.getRecentlyCompleted(days: 3)
        
        var availableHabits = habitPool.filter { habit in
            !recentKeys.contains(habit.titleKey)
        }
        
        // Remove the currently displayed habit from the pool if skipping
        // This ensures the "Skip" button never gives you the exact same result back to back.
        if let excludedKey = currentTitleKey {
            availableHabits.removeAll { $0.titleKey == excludedKey }
        }
        
        // Prioritize habits that are 1-2 completions away from suggestion
        let almostReadyKeys = progressManager.getAlmostReadyActions()
        let almostReadyHabits = availableHabits.filter { habit in
            almostReadyKeys.contains(habit.titleKey)
        }

        // Logic to set currentMicroHabit
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            // 60% chance of showing "almost ready" habit
            if !almostReadyHabits.isEmpty && Double.random(in: 0...1) < 0.6 {
                currentMicroHabit = almostReadyHabits.randomElement()
            } else {
                // Fallback to pool if available is empty (e.g. they skipped everything)
                currentMicroHabit = availableHabits.randomElement() ?? habitPool.randomElement()
            }
        }
        
        dataVersion += 1
        }

    private func completeMicroHabit(_ microHabit: MicroHabit) {
        let completion = MicroHabitCompletion(
            title: microHabit.title,
            duration: microHabit.duration,
            category: microHabit.category.rawValue,
            completedAt: Date()
        )
        modelContext.insert(completion)

        let progressManager = MicroHabitProgressManager(modelContext: modelContext)
        let newCount = progressManager.recordCompletion(for: microHabit.titleKey)

        try? modelContext.save()
        
        if newCount == 3 {
            promptedMicroHabit = microHabit
            showQuickActionPrompt = true
        } else {
            triggerMicroCelebration()
        }

        // Generate new micro habit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            generateMicroHabit()
        }
    }

    private func addHabitFromQuickAction(_ microHabit: MicroHabit) {
        // 1. Find matching habit template first
        guard let template = HabitLibraryData.template(linkedTo: microHabit.titleKey) else {
            AppLog.info("No template found for \(microHabit.titleKey)", category: "desk")
            showQuickActionPrompt = false
            promptedMicroHabit = nil
            return
        }
        
        // 2. Resolve the target name
        let targetName = localization.localize("template.\(template.name.replacingOccurrences(of: " ", with: ""))")
        
        // 3. DUPLICATE CHECK: Does this habit already exist?
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.name == targetName && $0.isArchived == false }
        )
        
        if let existingHabits = try? modelContext.fetch(descriptor), !existingHabits.isEmpty {
            AppLog.info("Habit '\(targetName)' already exists, skipping creation", category: "desk")
            
            // It exists, so we just mark the micro-habit as "converted" and celebrate
            let progressManager = MicroHabitProgressManager(modelContext: modelContext)
            progressManager.markAsConverted(for: microHabit.titleKey)
            
            triggerCelebration(for: 1)
            showQuickActionPrompt = false
            promptedMicroHabit = nil
            return
        }

        // 4. Create new habit (If it doesn't exist)
        let newHabit = Habit(
            name: targetName,
            description: localization.localize("template.\(template.name.replacingOccurrences(of: " ", with: "")).desc"),
            category: localization.localize("category.\(template.category.rawValue.replacingOccurrences(of: " ", with: ""))"),
            categoryIcon: template.category.icon,
            icon: template.icon,
            colorHex: template.colorHex,
            order: habits.count
        )

        modelContext.insert(newHabit)

        // 5. Mark as converted
        let progressManager = MicroHabitProgressManager(modelContext: modelContext)
        progressManager.markAsConverted(for: microHabit.titleKey)

        do {
            try modelContext.save()
            // Celebration
            triggerCelebration(for: 1)
        } catch {
            AppLog.error("Failed to save new habit: \(error)", category: "desk")
        }

        showQuickActionPrompt = false
        promptedMicroHabit = nil
    }

    private func triggerCelebration(for count: Int) {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        showConfetti = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showConfetti = false
        }
    }

    private func triggerMicroCelebration() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        showConfetti = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showConfetti = false
        }
    }
    
    // MARK: - Rest Day Management
    
    private func toggleRestDayWithFeedback() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        ReverieHaptics.successFeedback()
        
        if let existing = reflections.first(where: { 
            calendar.isDate($0.date, inSameDayAs: today) 
        }) {
            // Toggle existing reflection
            existing.isRestDay.toggle()
            
            #if DEBUG
            print("🌙 Rest day toggled: \(existing.isRestDay)")
            #endif
        } else {
            // Create new reflection with rest day
            let reflection = DailyReflection(date: today, text: "", isRestDay: true)
            modelContext.insert(reflection)
            
            #if DEBUG
            print("🌙 Rest day created")
            #endif
        }
        
        do {
            try modelContext.save()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                // Trigger UI update
                dataVersion += 1
            }
            
            ReverieHaptics.successFeedback()
            
            // Show toast
            showRestDayToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showRestDayToast = false
                }
            }
        } catch {
            #if DEBUG
            print("❌ Failed to toggle rest day: \(error)")
            #endif
        }
    }
    
    private var restDayToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 13))
            Text(isRestDay ? "Rest day activated" : "Rest day removed")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.softLavender.opacity(0.95))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
    }
}

// MARK: - Scroll Offset Tracking

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


    // MARK: - MicroHabitCompletion Model
    @Model
    final class MicroHabitCompletion {
        var id: UUID
        var title: String
        var duration: String
        var category: String
        var completedAt: Date

        init(title: String, duration: String, category: String, completedAt: Date = Date()) {
            self.id = UUID()
            self.title = title
            self.duration = duration
            self.category = category
            self.completedAt = completedAt
        }
    }

// MARK: - Welcome Tip Row Helper
private struct WelcomeTipRow: View {
    let number: String
    let text: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.10))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.system(size: 12, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
    }
}

    // MARK: - Preview
    #Preview {
        DeskView()
            .modelContainer(for: [
                Habit.self,
                HabitCompletion.self,
                DailyIntention.self,
                Achievement.self,
                MicroHabitCompletion.self,
                MicroHabitProgress.self,
                VitalityProgress.self
            ])
    }
