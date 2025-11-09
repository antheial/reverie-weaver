//
// DeskView.swift
// ReverieWeaver
//
// ADHD-Optimized with Micro Habits, Progression Tracking, and Habit Library
//

import SwiftUI
import SwiftData

struct DeskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme  // ← Add this line

    @Query private var completions: [HabitCompletion]
    @Query private var intentions: [DailyIntention]
    @Query private var allAchievements: [Achievement]
    @Query private var microHabitCompletions: [MicroHabitCompletion]
    @Query private var microHabitProgress: [MicroHabitProgress]
    // Add Query for mini challenge progress
    @Query private var miniChallengeProgress: [MiniChallengeProgress]
    
    // ✅ Only show non-archived habits in Desk
       @Query(
           filter: #Predicate<Habit> { $0.isArchived == false },
           sort: \Habit.order
       )
       private var habits: [Habit]

    @State private var showCreateHabit = false
    @State private var showEditHabit: Habit?
    @State private var showConfetti = false
    @State private var showHabitLibrary = false
    @State private var showQuickActionPrompt = false
    @State private var showFloatingAdd = false

    @State private var currentMicroHabit: MicroHabit?
    @State private var promptedMicroHabit: MicroHabit?
    @State private var intentionText = ""
    @State private var intentionMood = "Peaceful"
    @State private var intentionExpanded = false

    @State private var showPerfectDayCelebration = false
    @State private var showReflection: HabitCompletion?

    @State private var refreshID = UUID()

    @StateObject private var localization = LocalizationManager.shared

    private var todayCompletions: [HabitCompletion] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return completions.filter { completion in
            let completionDay = calendar.startOfDay(for: completion.completedAt)
            return completionDay == today
        }
    }

    private var todayIntention: DailyIntention? {
        intentions.first { Calendar.current.isDateInToday($0.date) }
    }

    private var completedCount: Int {
        habits.filter { habit in
            todayCompletions.contains { $0.habitId == habit.id }
        }.count
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
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }

        return streak
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        // 1. Header Section
                        VStack(spacing: 16) {
                            headerSection

                            Text(todayDisplay)
                                .font(.system(size: 12, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .tracking(0.5)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 2. Daily Quote
                            quoteCard

                            // 3. Collapsed/Expanded Intention
                            intentionCard

                            // 4. Micro Habits Section with Progress
                            microHabitsSection
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)

                        // 5. Daily Habits
                        VStack(spacing: 26) {
                            habitsSection
                        }
                        .padding(.horizontal, 24)

                        // 6. Progress Bar (at bottom)
                        progressCard
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                    }
                }

                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer() // This pushes button to the right
                        FloatingAddButton(
                            isExpanded: $showFloatingAdd,
                            onQuickAdd: {
                                showCreateHabit = true
                            },
                            onBrowseLibrary: {
                                showHabitLibrary = true
                            }
                        )
                    }
                    .padding(.trailing, 16) // Changed from .leading to .trailing
                    .padding(.bottom, 100)
                }
                .opacity(showCreateHabit || showEditHabit != nil || showHabitLibrary || showQuickActionPrompt ? 0 : 1)
                .allowsHitTesting(!(showCreateHabit || showEditHabit != nil || showHabitLibrary || showQuickActionPrompt))
            }
            .sheet(isPresented: $showCreateHabit) {
                HabitFormSheet()
            }
            .sheet(item: $showEditHabit) { habit in
                HabitFormSheet(habit: habit)
            }
            .sheet(isPresented: $showHabitLibrary) {
                HabitLibraryView()
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
            .alert(localization.localize("desk.celebration.perfect"), isPresented: $showPerfectDayCelebration) {
                Button(localization.localize("profile.ok")) { }
            } message: {
                Text("You completed all your habits today!")
            }
            .overlay(
                ConfettiView(isActive: $showConfetti)  // ✅ NEW COMPONENT
            )
            .onAppear {
                loadTodayIntention()
                generateMicroHabit()
                // ✅ Automatically check for Project 50 unlocks
                Project50ProgressManager.shared.refreshEligibility()
                scheduleMidnightRefresh()
            }
            .onChange(of: completedCount) { old, new in
                if new > old {
                    triggerCelebration(for: new)
                }
            }
        }
        .id(refreshID)  // ✅ add this right after the closing `}` of the ZStack
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
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .tracking(0.3)
                    Text(dayName)
                        .font(.system(size: 23, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }

            Spacer()

            // Streak counter
            // MARK: - 🟢 Circular Streak Counter (Darker Label, No Fill)
            if currentStreak > 0 {
                ZStack {
                    // Outer circle — thin border only
                    Circle()
                        .strokeBorder(
                            Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.01),
                            lineWidth: 1
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: Color.shadowColor.opacity(0.25), radius: 4, y: 1)

                    VStack(spacing: 2) {
                        // Main number — accent color
                        Text("\(currentStreak)")
                            .font(.system(size: 20, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.sageGreen)

                        // Label — darker adaptive tone
                        Text("DAY STREAK")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.85)
                                    : Color.black.opacity(0.75)
                            )
                    }
                }
                .padding(.trailing, 2)
                .padding(.vertical, 2)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStreak)
            }

        }
    }

    // MARK: - 💭 Quote Card (Enhanced, Integrated)
    private var quoteCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(Color.paleMauve)

            Text(dailyQuote)
                .font(.system(size: 12, weight: .regular))
                .italic()
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 🪞 Intention Card (Matched with Quote Card)
    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if intentionExpanded {
                // Expanded editor
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
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $intentionText)
                        .font(.system(size: 12, weight: .regular))
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
                                .font(.system(size: 12))
                                .foregroundStyle(Color.paleMauve)
                            Text(intentionMood)
                                .font(.system(size: 11, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .reverieCardStyle(colorScheme: colorScheme)
                    }

                    // Save button
                    Button("Save") {
                        saveIntention()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            intentionExpanded = false
                        }
                        hideKeyboard()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.sageGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .disabled(intentionText.isEmpty)
                }

            } else if !intentionText.isEmpty {
                // Collapsed display mode
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
                            .font(.system(size: 10, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        Spacer()
                        Text("Tap to set")
                            .font(.system(size: 10, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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

    // MARK: - Mood Label Helper (optional)
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


    // Add this helper function if you don't have it already
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                       to: nil, from: nil, for: nil)
    }

    // MARK: - Auto Refresh at Midnight
    private func scheduleMidnightRefresh() {
        let now = Date()
        guard let midnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0), matchingPolicy: .nextTime) else { return }

        let interval = midnight.timeIntervalSince(now)

        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            refreshForNewDay()
            // reschedule again for next midnight
            scheduleMidnightRefresh()
        }
    }

    private func refreshForNewDay() {
        loadTodayIntention()
        generateMicroHabit()
        
        // 🧭 We no longer clear completions — keep all previous days' data
        // resetDailyCompletionsIfNeeded()   ← delete or comment this out
        
        // ✅ CRITICAL: Force SwiftData to refresh queries for the new day
        Task { @MainActor in
            do {
                _ = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
                _ = try modelContext.fetch(FetchDescriptor<MicroHabitCompletion>())
                print("✅ DeskView midnight data refresh complete")
            } catch {
                print("⚠️ DeskView midnight refresh failed: \(error)")
            }
        }
        
        // ✅ Refresh Project 50 eligibility for the *new* day
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Project50ProgressManager.shared.refreshEligibility()
        }

        // ✅ Force the DeskView + LoomView to redraw
        withAnimation(.easeInOut) {
            refreshID = UUID()
        }
    }

    // Do NOT delete HabitCompletion records on day change.
    // We keep history; views filter by selected day.
    private func resetDailyCompletionsIfNeeded() {
        // intentionally empty – legacy deletion removed
    }


    // MARK: - IMPROVED Quick Actions Section
    // Replace your existing microHabitsSection with this:

    private var microHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - minimal (no icon)
            HStack(spacing: 8) {
                Text("Quick Actions")
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()

                // Minimal progress indicator
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
                                .font(.system(size: 9, weight: .medium))
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
                    // Title and metadata - compact
                    VStack(spacing: 6) {
                        Text(microHabit.title)
                            .font(.system(size: 13, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: microHabit.title.count > 30 ? .leading : .center)

                        // Compact metadata row
                        HStack(spacing: 6) {
                            // Minimal category badge
                            HStack(spacing: 4) {
                                Image(systemName: microHabit.category.icon)
                                    .font(.system(size: 8))
                                    .foregroundStyle(
                                        microHabit.category.color.opacity(colorScheme == .dark ? 0.7 : 0.9)
                                    )

                                Text(microHabit.category.rawValue)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(
                                        colorScheme == .dark
                                            ? Color.dynamicSecondaryLabel.opacity(0.8)
                                            : Color.dynamicLabel.opacity(0.9)
                                    )
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

                            // Duration with subtle dot
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.dynamicSecondaryLabel.opacity(0.3))
                                    .frame(width: 2, height: 2)

                                Text(microHabit.duration)
                                    .font(.system(size: 9, weight: .regular))
                                    .foregroundStyle(
                                        colorScheme == .dark
                                            ? Color.dynamicSecondaryLabel.opacity(0.8)
                                            : Color.dynamicLabel.opacity(0.85)
                                    )
                            }
                        }
                    }

                    // Compact action buttons
                    HStack(spacing: 10) {
                        // Skip button - smaller
                        Button {
                            generateMicroHabit()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                .frame(width: 36, height: 36)
                                .reverieCardStyle(colorScheme: colorScheme)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Complete button - smaller
                        Button {
                            completeMicroHabit(microHabit)
                        } label: {
                            Text("Complete")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.sageGreen.opacity(colorScheme == .dark ? 1.0 : 0.85))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .reverieCardStyle(colorScheme: colorScheme)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Browse Library - compact
            Button {
                showHabitLibrary = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 9))
                    Text("Browse Library")
                        .font(.system(size: 10, weight: .regular))
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
        }
        .padding(14)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - 🌱 Habits Section (Smart Glass Logic)
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.paleMauve)

                Text(localization.localize("desk.habits.title"))
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()
            }
            .padding(.bottom, 2)

            // 🩵 Empty State — soft glass only around text/button
            if habits.isEmpty {
                VStack(spacing: 10) {
                    Text(localization.localize("desk.habits.empty"))
                        .font(.system(size: 12, weight: .regular))
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
                            .font(.system(size: 12, weight: .medium))
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

                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .reverieCardStyle(colorScheme: colorScheme)
                .padding(.top, 4)
            }

            //Has Habits — just show habit cards, no outer glass layer
            else {
                VStack(spacing: 10) {
                    ForEach(habits) { habit in
                        HabitCard(
                            habit: habit,
                            isCompleted: isCompleted(habit),
                            onToggle: { toggleHabit(habit) }
                        )
                        .contextMenu {
                            // Edit stays the same
                            Button {
                                showEditHabit = habit
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            if habit.isArchived {
                                // Unarchive (e.g., on an Archived screen)
                                Button {
                                    habit.isArchived = false
                                    habit.archivedAt = nil            // ✅ active again
                                    try? modelContext.save()
                                } label: {
                                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                                }

                                // Optional: true delete only from Archived
                                Button(role: .destructive) {
                                    deleteHabitPermanently(habit)
                                } label: {
                                    Label("Delete Permanently", systemImage: "trash")
                                }
                            } else {
                                // On Desk: replace Delete with Archive
                                Button {
                                    habit.isArchived = true
                                    habit.archivedAt = Date()         // ✅ mark when it left the lineup
                                    try? modelContext.save()
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                            }
                        }

                    }
                }

                .padding(.top, 4)
            }
        }
        .padding(.bottom, 100)
    }

    private func deleteHabitPermanently(_ habit: Habit) {
        modelContext.delete(habit)
        do { try modelContext.save() } catch { print("❌ Delete failed: \(error)") }
    }

    // MARK: - 📈 Progress Card (Matched with Intention & Quote Cards)
    @ViewBuilder
    private var progressCard: some View {
        if !habits.isEmpty && completedCount > 0 {
            VStack(spacing: 10) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.paleMauve)

                    Text(localization.localize("desk.progress.title"))
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Spacer()

                    Text("\(completedCount) / \(habits.count)")
                        .font(.system(size: 11, weight: .medium))
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

                // Optional soft reflection text
                if progress == 1 {
                    Text("All habits completed — you did it!")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color.white.opacity(0.95)
                                : Color.black.opacity(0.85)
                        )

                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                } else if progress > 0 {
                    Text("Keep going — small steps make the day complete.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color.white.opacity(0.95)
                                : Color.black.opacity(0.85)
                        )

                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                }
            }
            .padding(16)
            // Smooth fade-in when first habit is added
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.25), value: habits.count)
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
        guard habits.count > 0 else { return 0 }
        return CGFloat(completedCount) / CGFloat(habits.count)
    }

    private func isCompleted(_ habit: Habit) -> Bool {
        todayCompletions.contains { $0.habitId == habit.id }
    }

    // MARK: - Your Updated toggleHabit Function

    private func toggleHabit(_ habit: Habit) {
        if let existing = todayCompletions.first(where: { $0.habitId == habit.id }) {
            // Uncomplete habit
            modelContext.delete(existing)
            
            do {
                try modelContext.save()
                print("✅ Habit uncompleted: \(habit.name)")
            } catch {
                print("❌ Failed to save uncompletion: \(error)")
            }
        } else {
            // Complete habit
                   // ⬇️ CHANGED: capture a snapshot so Loom can render even if the habit is later deleted
                   let completion = HabitCompletion(from: habit, at: Date())
                   modelContext.insert(completion)
            
            do {
                try modelContext.save()
                print("✅ Habit completed and saved: \(habit.name)")
            } catch {
                print("❌ Failed to save completion: \(error)")
            }

            // Check achievements and progress
            AchievementManager.shared.attachContext(modelContext)
            AchievementManager.shared.checkAchievements(
                completions: completions,
                habits: habits,
                pomodoros: []
            )
            checkPerfectDayAchievement()
            checkGamificationProgress()
        }

        // Check mini challenge progress
        Project50ProgressManager.shared.checkMiniChallengeCompletion(
            modelContext: modelContext,
            habits: habits,
            completions: completions
        )
        Project50ProgressManager.shared.onDeskCompletionDidUpdate()
    }

    // ✨ NEW: Add this helper function
    private func checkGamificationProgress() {
        // Update level based on total completions
        WeaverJourneyManager.shared.updateLevel(totalCompletions: completions.count)

        // Check if any constellations should unlock
        let constellationManager = ConstellationManager(modelContext: modelContext)
        constellationManager.checkUnlocks(habits: habits, completions: completions)

        // Check for invisible achievement triggers
        let invisibleManager = InvisibleAchievementManager(modelContext: modelContext)
        invisibleManager.checkForNewAchievements(habits: habits, completions: completions)
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

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.dynamicSecondaryLabel.opacity(0.15))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.dustyBlue)
                            .frame(width: geometry.size.width * progress.progressPercentage)
                    }
                }
                .frame(height: 6)

                Text("Complete all challenge habits today to mark Day \(progress.daysCompleted + 1)")
                    .font(.system(size: 11))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }
    }

    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
    }

    private func checkPerfectDayAchievement() {
        let allCompleted = habits.allSatisfy { habit in
            todayCompletions.contains { $0.habitId == habit.id }
        }

        guard allCompleted && habits.count > 0 else { return }

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
    }

    // MARK: - Enhanced Micro Habit Functions
    private func generateMicroHabit() {
           let hour = Calendar.current.component(.hour, from: Date())
           let habitPool: [MicroHabit]

           switch hour {
           case 6..<12:
               habitPool = MicroHabit.morningHabits
                   case 12..<18:
                       habitPool = MicroHabit.afternoonHabits
                   case 18..<24:
                       habitPool = MicroHabit.eveningHabits
                   default:
                       habitPool = MicroHabit.nightHabits
                   }

        let progressManager = MicroHabitProgressManager(modelContext: modelContext)

               // Filter out recently completed ones (last 3 days)
               let recentKeys = progressManager.getRecentlyCompleted(days: 3)
               let availableHabits = habitPool.filter { habit in
                   !recentKeys.contains(habit.titleKey)
               }

               // Prioritize habits that are 1-2 completions away from suggestion
               let almostReadyKeys = progressManager.getAlmostReadyActions()
               let almostReadyHabits = availableHabits.filter { habit in
                   almostReadyKeys.contains(habit.titleKey)
               }

               // 60% chance of showing "almost ready" habit
               if !almostReadyHabits.isEmpty && Double.random(in: 0...1) < 0.6 {
                   currentMicroHabit = almostReadyHabits.randomElement()
               } else {
                   currentMicroHabit = availableHabits.randomElement() ?? habitPool.randomElement()
               }
           }


    private func completeMicroHabit(_ microHabit: MicroHabit) {
            // Save completion
            let completion = MicroHabitCompletion(
                title: microHabit.title,
                duration: microHabit.duration,
                category: microHabit.category.rawValue,
                completedAt: Date()
            )
            modelContext.insert(completion)

            // Track progression
            let progressManager = MicroHabitProgressManager(modelContext: modelContext)
            let newCount = progressManager.recordCompletion(for: microHabit.titleKey)

            try? modelContext.save()

            // Check if should prompt to add full habit
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
        // Find matching habit template
        if let template = HabitLibraryData.template(linkedTo: microHabit.titleKey) {
            let newHabit = Habit(
                name: localization.localize("template.\(template.name.replacingOccurrences(of: " ", with: ""))"),
                description: localization.localize("template.\(template.name.replacingOccurrences(of: " ", with: "")).desc"),
                category: localization.localize("category.\(template.category.rawValue.replacingOccurrences(of: " ", with: ""))"),
                categoryIcon: template.category.icon,
                icon: template.icon,
                colorHex: template.colorHex,
                order: habits.count
            )

            modelContext.insert(newHabit)

            // Mark as converted
            let progressManager = MicroHabitProgressManager(modelContext: modelContext)
            progressManager.markAsConverted(for: microHabit.titleKey)

            try? modelContext.save()

            // Celebration
            triggerCelebration(for: 1)
        }

        showQuickActionPrompt = false
        promptedMicroHabit = nil
    }

    private func triggerCelebration(for count: Int) {
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)

            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfetti = false
            }
        }

    private func triggerMicroCelebration() {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showConfetti = false
            }
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

// MARK: - CategoryBadgeView
struct CategoryBadgeView: View {
    let color: Color
    let icon: String
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 7))
            Text(text)
                .font(.system(size: 8.5, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            color.opacity(colorScheme == .dark ? 0.4 : 0.6)
        )
        .clipShape(Capsule())
        .shadow(color: color.opacity(0.25), radius: 1, y: 0.5)
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
                MicroHabitProgress.self
            ])
    }

