//
//  ThemeWeekDetailView.swift
//  Reverie Weaver
//
//

import SwiftUI
import SwiftData

struct ThemeWeekDetailView: View {
    let program: ThemeWeekProgram
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allProgress: [ThemeWeekProgress]
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @Query private var allJournalEntries: [ReflectionNote]
    
    @State private var showFullWeekPlan = false
    @State private var selectedTier: CompletionTier = .sprout
    @State private var showTierSelection = false
    @State private var showSuccessMessage = false
    @State private var showDeleteConfirmation = false
    @State private var addedToDesk = false
    
    // Task management for cancellable animations
    @State private var successAnimationTask: Task<Void, Never>?
    @State private var completionSheetTask: Task<Void, Never>?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showInfoSheet = false
    
    // MARK: - Journal Integration State
    @State private var journalContext: JournalContext? = nil
    @State private var editingJournalEntry: ReflectionNote? = nil
    
    // MARK: - Week Completion State
    @State private var showCompletionSheet = false

    private var progress: ThemeWeekProgress? {
        allProgress.first { $0.programTag == program.tag && !$0.isCompleted }
    }
    
    private var currentDay: Int {
        progress?.currentDayNumber ?? 1
    }
    
    private var todayTheme: DayTheme? {
        program.theme(for: currentDay)
    }
    
    private var todayHabit: ThemeWeekHabit? {
        todayTheme?.habits.first
    }
    
    private var themeWeekHabit: Habit? {
        let habitTag = "TW-\(program.tag)"
        return habits.first { $0.programTag == habitTag && !$0.isArchived }
    }
    
    private var isAlreadyActive: Bool {
        themeWeekHabit != nil
    }
    
    // MARK: - Journal Computed Properties
    
    private var todayJournalEntries: [ReflectionNote] {
        allJournalEntries.filter {
            $0.type == "daily" &&
            $0.themeWeekSessionID == progress?.sessionID &&  // Use sessionID instead of just tag
            $0.themeWeekDay == currentDay
        }
    }
    
    private var canWriteJournalToday: Bool {
        todayJournalEntries.isEmpty
    }
    
    private var todayJournalPrompt: String? {
        guard let theme = todayTheme,
              let _ = todayHabit else { return nil }

        // If day is complete, use tier-specific prompt
        if let completedTier = progress?.tier(for: currentDay) {
            // Use Connection Clarity specific prompts only for that program
            if program.tag == "ConnectionClarityW1" {
                return ConnectionClarityPrompts.prompt(for: currentDay, tier: completedTier)
            }

            // Generic tier-aware prompts for other theme weeks
            switch completedTier {
            case .seed:
                return "You showed up today with \(theme.themeName). Even the smallest step counts. What did you notice?"
            case .sprout:
                return "You completed your intended goal for \(theme.themeName). What did you notice while practicing? How did it feel?"
            case .bloom:
                return "You went above and beyond with \(theme.themeName) today. What made you choose this level? What surprised you or felt meaningful?"
            }
        }

        // Otherwise show default prompt
        return "How are you feeling about today's focus: \(theme.themeName)?"
    }
    
    private func hasJournalEntry(for day: Int) -> Bool {
        allJournalEntries.contains {
            $0.type == "daily" &&
            $0.themeWeekSessionID == progress?.sessionID &&  // Use sessionID
            $0.themeWeekDay == day
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        
                        if progress != nil {
                            progressSection
                            todaysFocusCard
                            
                            // MARK: - Journal Prompt Card (NEW)
                            if isTodayComplete {
                                journalPromptCard
                            }
                            
                            if showFullWeekPlan {
                                fullWeekPlanView
                            }
                            
                            toggleFullWeekButton
                        } else {
                            weekPreviewSection
                        }
                    }
                    .padding(.bottom, 120)
                    .padding(.top, 60)
                }
                
                HStack {
                    infoButton
                    Spacer()
                    closeButton
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if showSuccessMessage {
                    successOverlay
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                if !isAlreadyActive {
                    startWeekButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showTierSelection) {
                tierSelectionSheet
            }
            .alert("Delete Theme Week?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                                deleteThemeWeek()
            }
            } message: {
                Text("This will remove your current progress and the habit from your Desk.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onDisappear {
                successAnimationTask?.cancel()
                completionSheetTask?.cancel()
                #if DEBUG
                print("🌗 [TW] View dismissed - animation tasks cancelled")
                #endif
            }
                        .sheet(isPresented: $showInfoSheet) {
                            NavigationStack {
                                ScrollView {
                                    featuresAndTipsSection
                                        .padding(.top, 20)
                                }
                                .background(ReverieWeaverBackground())
                                .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button("Done") { showInfoSheet = false }
                                    }
                                }
                                .navigationTitle("Program Guide")
                                .navigationBarTitleDisplayMode(.inline)
                            }
                            .presentationDetents([.medium, .large])
                }
        }
        .sheet(item: $journalContext, onDismiss: {
            // Clear editing entry when sheet dismisses
            editingJournalEntry = nil
        }) { context in
            ThemeWeekJournalSheet(
                context: context,
                existingEntry: editingJournalEntry
            )
            .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: $showCompletionSheet) {
            if let prog = progress, let todayHabit = todayHabit {
                ThemeWeekCompletionSheet(
                    progress: prog,
                    program: todayHabit,
                    journalEntries: allJournalEntries.filter {
                        $0.type == "daily" &&
                        $0.themeWeekSessionID == prog.sessionID
                    },
                    onRunAgain: {
                        runWeekAgain()
                    },
                    onViewReflections: {
                        openThemeWeekArchive()
                    }
                )
            }
        }
    }
}

// MARK: - Hero Section

private extension ThemeWeekDetailView {
    
    var heroSection: some View {
        ReverieEditorialHero(
            icon: program.icon,
            title: program.title,
            badgeText: "Theme Week",
            tagline: program.subtitle,
            description: program.description,
            accentColorHex: program.colorHex,
            datelinePrefix: "THEME WEEK",
            showDateline: true
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Week Preview Section (Before Starting)

private extension ThemeWeekDetailView {
    
    var weekPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Journey")
                .font(.system(size: 15, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 10) {
                ForEach(program.dailyThemes.prefix(3)) { theme in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: theme.colorHex).opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color(hex: theme.colorHex).opacity(0.3), lineWidth: 1)
                                )
                            Image(systemName: theme.themeIcon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: theme.colorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Day \(theme.dayNumber): \(theme.themeName)")
                                .font(.system(size: 13, weight: .semibold))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            Text(theme.tagline)
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .reverieCardStyle(colorScheme: colorScheme)
                }
                
                HStack {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11))
                    Text("+ 4 more daily themes")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color(hex: program.colorHex))
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Progress Section

private extension ThemeWeekDetailView {
    
    var progressSection: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Text("Your Progress")
                    .font(.system(size: 15, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Spacer()
                
                if isAlreadyActive {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text("Delete")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(.red.opacity(colorScheme == .dark ? 0.15 : 0.12))
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(1...7, id: \.self) { day in
                        Text(dayLabel(for: day))
                            .font(.system(size: 11, weight: .semibold))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Progress dots
                HStack(spacing: 0) {
                    ForEach(1...7, id: \.self) { day in
                        ZStack {
                            Circle()
                                .fill(dotColor(for: day))
                                .frame(width: dotSize(for: day), height: dotSize(for: day))
                            
                            if let tier = progress?.tier(for: day) {
                                Image(systemName: tierIcon(for: tier))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            
                            // NEW: Journal indicator
                            if hasJournalEntry(for: day) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(Color(hex: program.colorHex))
                                    .offset(x: 10, y: -10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 11))
                    Text("Day \(currentDay) of 7")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color(hex: program.colorHex))
                
                // Week Complete - Review Button
                if progress?.isCompleted == true {
                    Button {
                        showCompletionSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("Review Completed Week")
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color(hex: program.colorHex))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: program.colorHex).opacity(colorScheme == .dark ? 0.2 : 0.15))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .reverieCardStyle(colorScheme: colorScheme)
            .padding(.horizontal, 24)
        }
    }
    
    func tierIcon(for tier: CompletionTier) -> String {
        switch tier {
        case .seed: return "leaf.fill"
        case .sprout: return "leaf.circle.fill"
        case .bloom: return "sparkles"
        }
    }
}

// MARK: - Today's Focus Card

private extension ThemeWeekDetailView {
    
    var todaysFocusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: todayTheme?.themeIcon ?? "leaf.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: todayTheme?.colorHex ?? program.colorHex))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(currentDay): \(todayTheme?.themeName ?? "Reflection")")
                        .font(.system(size: 14, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text(todayTheme?.tagline ?? "Focus on your intention")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            
            Divider()
                .background(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.3))
            
            VStack(spacing: 12) {
                Text("Complete Today:")
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let habit = todayHabit {
                    ForEach([CompletionTier.seed, .sprout, .bloom], id: \.self) { tier in
                        tierButton(habit: habit, tier: tier)
                    }
                }
            }
        }
        .padding(18)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Journal Prompt Card (NEW)
    
    var journalPromptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: program.colorHex))
                
                Text("Daily Reflection")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Spacer()
                
                // Optional badge
                Text("Optional")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: program.colorHex))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(hex: program.colorHex).opacity(0.1))
                    )
            }
            
            // Show prompt
            if let prompt = todayJournalPrompt {
                Text(prompt)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineSpacing(3)
                    .padding(.vertical, 8)
            }
            
            Divider()
                .background(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.2))
            
            // Show existing entry or write button
            if let existingEntry = todayJournalEntries.first {
                // Show the existing entry
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Your reflection:")
                            .font(.system(size: 12, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        
                        Spacer()
                        
                        // Edit button
                        Button {
                            openJournalEntry(existingEntry)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                Text("Edit")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: program.colorHex))
                        }
                    }
                    
                    // Entry preview
                    VStack(alignment: .leading, spacing: 6) {
                        if !existingEntry.title.isEmpty {
                            Text(existingEntry.title)
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        Text(existingEntry.content)
                            .font(.system(size: 12, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .lineLimit(3)
                            .lineSpacing(2)
                        
                        Text(existingEntry.lastEdited, style: .relative)
                            .font(.system(size: 11))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .padding(.top, 4)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.05))
                    )
                }
            } else {
                // Show write button (only if no entry exists)
                Button {
                    openJournalForToday()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 13))
                        Text("Write Reflection")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: program.colorHex))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: program.colorHex).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color(hex: program.colorHex).opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
    }
    
    func tierButton(habit: ThemeWeekHabit, tier: CompletionTier) -> some View {
        let isCompleted = progress?.isDayComplete(currentDay) ?? false
        let tierDesc = tierDescription(habit: habit, tier: tier)
        
        return Button {
            guard !isCompleted else { return }
            completeHabit(habit, tier: tier)
        } label: {
            HStack(alignment: .top, spacing: 12) {  // Changed to .top alignment for better multi-line layout
                ZStack {
                    Circle()
                        .fill(Color(hex: program.colorHex).opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: tierIcon(for: tier))
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: program.colorHex))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text(tierDesc)
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .fixedSize(horizontal: false, vertical: true)  // Allow full height
                        .lineSpacing(2)  // Better readability for multi-line text
                }
                
                Spacer()
                
                if isCompleted && progress?.tier(for: currentDay) == tier {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.sageGreen)
                }
            }
            .padding(14)  // Increased padding for longer content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted && progress?.tier(for: currentDay) == tier
                          ? Color.sageGreen.opacity(0.1)
                          : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
    }
    
    func tierDescription(habit: ThemeWeekHabit, tier: CompletionTier) -> String {
        switch tier {
        case .seed: return habit.seedTier
        case .sprout: return habit.sproutTier
        case .bloom: return habit.bloomTier
        }
    }
}

// MARK: - Full Week Plan View

private extension ThemeWeekDetailView {
    
    var fullWeekPlanView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Full 7-Day Plan")
                .font(.system(size: 15, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 10) {
                ForEach(program.dailyThemes) { theme in
                    HStack(spacing: 12) {
                        // Day number indicator
                        ZStack {
                            Circle()
                                .fill(Color(hex: theme.colorHex).opacity(0.15))
                                .frame(width: 32, height: 32)
                            Text("\(theme.dayNumber)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: theme.colorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Image(systemName: theme.themeIcon)
                                    .font(.system(size: 12))
                                Text(theme.themeName)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            Text(theme.tagline)
                                .font(.system(size: 11))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Completion indicator
                        if let tier = progress?.tier(for: theme.dayNumber) {
                            Image(systemName: tierIcon(for: tier))
                                .font(.system(size: 13))
                                .foregroundStyle(Color.sageGreen)
                        }
                    }
                    .padding(14)
                    .reverieCardStyle(colorScheme: colorScheme)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    var toggleFullWeekButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showFullWeekPlan.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text(showFullWeekPlan ? "Hide Week Plan" : "View Full Week")
                    .font(.system(size: 13, weight: .medium))
                Image(systemName: showFullWeekPlan ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11))
            }
            .foregroundStyle(Color(hex: program.colorHex))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(hex: program.colorHex).opacity(colorScheme == .dark ? 0.15 : 0.12))
            )
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Features & Tips Section

private extension ThemeWeekDetailView {
    
    var featuresAndTipsSection: some View {
        VStack(spacing: 14) {
            // Three-tier system
            infoCard(
                icon: "arrow.3.trianglepath",
                iconColor: Color(hex: "B8D4C8"),
                title: "Three-Tier System",
                items: [
                    "Seed (1pt): Minimum version - always counts as success",
                    "Sprout (2pts): Intended practice - sustainable daily goal",
                    "Bloom (3pts): Exceptional version - when you have extra capacity"
                ]
            )
            
            // Gentle approach
            infoCard(
                icon: "leaf.fill",
                iconColor: Color(hex: "C8B8DB"),
                title: "Gentle by Design",
                items: [
                    "Pick any tier each day based on your capacity",
                    "No shame in choosing Seed - it's wisdom, not failure",
                    "Complete all 7 days at any tier combination to finish"
                ]
            )
            
            // Bad brain day protocol
            infoCard(
                icon: "bolt.shield.fill",
                iconColor: Color(hex: "FFD18B"),
                title: "Bad Brain Day Protocol",
                items: [
                    "Feeling overwhelmed? Choose Seed tier automatically",
                    "Can't do even Seed? That's okay - skip today",
                    "You have a 1-day buffer (8 days total) to complete 7 days"
                ]
            )
        }
        .padding(.horizontal, 24)
    }
    
    func infoCard(icon: String, iconColor: Color, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(iconColor)
                        Text(item)
                            .font(.system(size: 13))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .reverieCardStyle(colorScheme: colorScheme)
    }
}

// MARK: - Start Week Button

private extension ThemeWeekDetailView {
    
    var startWeekButton: some View {
        Button {
            startThemeWeek()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: addedToDesk ? "checkmark.circle.fill" : "play.circle.fill")
                    .font(.system(size: 18))
                Text(addedToDesk ? "Added to Desk ✓" : "Start Theme Week")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: program.colorHex).opacity(0.9),
                        Color(hex: program.colorHex).opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.shadowColor.opacity(0.25), radius: 4, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 32)
        .disabled(addedToDesk)
    }
}

// MARK: - Overlays & Sheets

private extension ThemeWeekDetailView {
    
    var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: selectedTier == .bloom ? "sparkles" : "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color(hex: program.colorHex))
                
                Text("Day \(currentDay) Complete!")
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: tierIcon(for: selectedTier))
                        .font(.system(size: 13))
                    Text("\(selectedTier.displayName) tier")
                        .font(.system(size: 14))
                }
                .foregroundStyle(.white.opacity(0.9))
                
                if let message = progress?.adaptationMessage {
                    Text(message)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }
    
    var tierSelectionSheet: some View {
        NavigationStack {
            VStack {
                Text("Select completion tier")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showTierSelection = false
                    }
                }
            }
        }
    }
}

// MARK: - Floating Buttons

private extension ThemeWeekDetailView {
    
    var infoButton: some View {
        Button {
            showInfoSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.7), location: 0.1),
                                .init(color: .white.opacity(0.1), location: 0.5),
                                .init(color: .white.opacity(0.3), location: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .shadow(color: .white.opacity(0.3), radius: 1, x: -1, y: -1)

                Image(systemName: "info.circle")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: 36, height: 36)
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
        }
    }
    
    var closeButton: some View {
        GlassCloseButton {
            dismiss()
        }
    }
}

// MARK: - Helper Functions & Actions

private extension ThemeWeekDetailView {
    
    var isTodayComplete: Bool {
        progress?.isDayComplete(currentDay) ?? false
    }
    
    func dayLabel(for day: Int) -> String {
        ["D1", "D2", "D3", "D4", "D5", "D6", "D7"][day - 1]
    }
    
    func dotColor(for day: Int) -> Color {
        if progress?.tier(for: day) != nil {
            return Color(hex: program.colorHex)
        } else if day == currentDay {
            return Color(hex: program.colorHex).opacity(0.5)
        } else if day < currentDay {
            return Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.2)
        } else {
            return Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.1)
        }
    }
    
    func dotSize(for day: Int) -> CGFloat {
        day == currentDay ? 26 : 20
    }
    
    func startThemeWeek() {
        // 1. Create ThemeWeekProgress
        let progressRecord = ThemeWeekProgress(
            programID: program.id,
            programTag: program.tag,
            programTitle: program.title
        )
        modelContext.insert(progressRecord)
        
        // 2. Create ONE Habit model for this Theme Week
        let habitTag = "TW-\(program.tag)"
        
        #if DEBUG
        print("🌗 [TW] startThemeWeek → creating progress for tag=\(program.tag) and inserting TW-\(program.tag) habit")
        #endif
        
        let themeWeekHabit = Habit(
            name: program.title,
            description: program.description,
            category: "Theme Week",
            categoryIcon: "moon.stars.fill",
            icon: program.icon,
            colorHex: program.colorHex,
            completionMessage: "Another day of showing up. That's growth.",
            frequency: "daily",
            order: habits.count,
            programTag: habitTag,
            programLevel: nil,
            scheduledDays: nil
        )
        
        modelContext.insert(themeWeekHabit)
        
        // 3. Save
        do {
            try modelContext.save()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                addedToDesk = true
            }
            
            ReverieHaptics.successFeedback()
            
        } catch {
            print("Failed to start theme week: \(error)")
        }
    }
    
    func completeHabit(_ habit: ThemeWeekHabit, tier: CompletionTier) {
        let progressRecord: ThemeWeekProgress
        
        let descriptor = FetchDescriptor<ThemeWeekProgress>(
            predicate: #Predicate { $0.programTag == program.tag && !$0.isCompleted }
        )
        
        if let fetched = try? modelContext.fetch(descriptor).first {
            progressRecord = fetched
        } else {
            print("⚠️ [TW] No active progress found, creating new record (Fallback)")
            progressRecord = ThemeWeekProgress(
                programID: program.id,
                programTag: program.tag,
                programTitle: program.title
            )
            modelContext.insert(progressRecord)
        }
        
        // 2. Get the Theme Week Habit model
        guard let habitModel = themeWeekHabit else {
            print("⚠️ Theme Week Habit not found")
            return
        }
        
        // 3. Create HabitCompletion record
        let completion = HabitCompletion(
            habitId: habitModel.id,
            completedAt: Date()
        )
        modelContext.insert(completion)
        
        // 4. Mark day complete in ThemeWeekProgress with tier
        progressRecord.completeDay(
            currentDay,
            tier: tier,
            habitID: habitModel.id
        )
        
        #if DEBUG
        print("🌗 [TW] completeHabit → day=\(currentDay) tier=\(tier) habitID=\(habitModel.id)")
        #endif
        
        // 5. Save everything
        do {
            try modelContext.save()
            
            // 6. Check if week is complete (Day 7 just finished)
            if currentDay == 7 && progressRecord.isCompleted && !progressRecord.hasViewedCompletionSheet {
                // Show completion sheet after a brief success animation
                completionSheetTask?.cancel()
                completionSheetTask = Task { @MainActor in
                    do {
                        try await Task.sleep(nanoseconds: 2_500_000_000)
                        guard !Task.isCancelled else { return }
                        showCompletionSheet = true
                    } catch {
                        // Task was cancelled
                    }
                }
            }
            
            // 7. Show success
            selectedTier = tier
            withAnimation(.spring(response: 0.5)) {
                showSuccessMessage = true
            }
            
            ReverieHaptics.successFeedback()

            successAnimationTask?.cancel()
            
            successAnimationTask = Task { @MainActor in
                do {
                    try await Task.sleep(nanoseconds: 2_500_000_000)
                    
                    guard !Task.isCancelled else { return }
                    
                    withAnimation {
                        showSuccessMessage = false
                    }
                } catch {
                }
            }
        } catch {
            print("Failed to complete habit: \(error)")
            errorMessage = "Unable to save completion. Please try again."
            showError = true
        }
    }
    
    func deleteThemeWeek() {
        #if DEBUG
        print("🌗 [TW] deleteThemeWeek → deleting TW-\(program.tag) habit and progress")
        #endif
        
        if let habit = themeWeekHabit {
            habit.prepareForDeletion()
            modelContext.delete(habit)
        }
        
        if let progressRecord = progress {
            modelContext.delete(progressRecord)
        }
        
        #if DEBUG
        let hadHabit = (themeWeekHabit != nil)
        let hadProgress = (progress != nil)
        print("🌗 [TW] Deletion summary → habitRemoved=\(hadHabit) progressRemoved=\(hadProgress)")
        #endif
        
        do {
            try modelContext.save()
            ReverieHaptics.lightFeedback()
            withAnimation(.spring()) {
                dismiss()
            }
        } catch {
            print("Failed to delete theme week: \(error)")
            errorMessage = "Unable to delete Theme Week. Please try again."
            showError = true
        }
    }
    
    // MARK: - Week Completion Actions
    
    func runWeekAgain() {
        // Archive current progress (mark as completed if not already)
        if let currentProgress = progress {
            if !currentProgress.isCompleted {
                currentProgress.isCompleted = true
                currentProgress.completedDate = Date()
            }
        }
        
        // Create new ThemeWeekProgress for a new run
        let newProgress = ThemeWeekProgress(
            programID: program.id,
            programTag: program.tag,
            programTitle: program.title,
            startDate: Date()
        )
        
        modelContext.insert(newProgress)
        
        do {
            try modelContext.save()
            print("✅ Started new run of \(program.title)")
            ReverieHaptics.successFeedback()
        } catch {
            print("❌ Failed to start new run: \(error.localizedDescription)")
            errorMessage = "Failed to start new week. Please try again."
            showError = true
        }
    }
    
    func openThemeWeekArchive() {
        // This would navigate to the Reflection Note archive with Theme Week filter enabled
        // For now, just print - you can implement navigation later
        print("📚 Opening Theme Week archive for session: \(progress?.sessionID ?? "unknown")")
        // TODO: Navigate to ReflectionNoteView with showThemeWeekEntries = true
    }
    
    // MARK: - Journal Actions (NEW)
    
    func openJournalForToday() {
        guard let theme = todayTheme else {
            #if DEBUG
            print("📝 [Journal] Cannot open: todayTheme is nil")
            #endif
            return
        }
        guard let currentProgress = progress else {
            #if DEBUG
            print("📝 [Journal] Cannot open: progress is nil")
            #endif
            return
        }

        // Only allow if no entry exists
        guard canWriteJournalToday else {
            #if DEBUG
            print("📝 [Journal] Cannot open: entry already exists for today")
            #endif
            return
        }

        // Get the completed tier for enriched prompt
        let completedTier = currentProgress.tier(for: currentDay)
        let prompt = todayJournalPrompt ?? "How did today's practice feel for you?"

        #if DEBUG
        print("📝 [Journal] Opening for Day \(currentDay), tier: \(completedTier?.rawValue ?? "none"), prompt length: \(prompt.count)")
        #endif

        editingJournalEntry = nil  // Creating new

        // Setting journalContext triggers the sheet to open (using sheet(item:))
        journalContext = JournalContext(
            programTag: program.tag,
            programTitle: program.title,
            dayNumber: currentDay,
            dayTheme: theme.themeName,
            prompt: prompt,
            tier: completedTier,
            colorHex: program.colorHex,
            sessionID: currentProgress.sessionID
        )
    }
    
    func openJournalEntry(_ entry: ReflectionNote) {
        guard let theme = todayTheme else { return }
        guard let currentProgress = progress else { return }

        editingJournalEntry = entry  // Editing existing

        // Setting journalContext triggers the sheet to open (using sheet(item:))
        journalContext = JournalContext(
            programTag: program.tag,
            programTitle: program.title,
            dayNumber: currentDay,
            dayTheme: theme.themeName,
            prompt: todayJournalPrompt ?? "How did today's practice feel for you?",
            tier: currentProgress.tier(for: currentDay),
            colorHex: program.colorHex,
            sessionID: currentProgress.sessionID
        )
    }
}

// MARK: - Preview

#Preview {
    ThemeWeekDetailView(program: ThemeWeekData.gentleRhythmWeek)
        .modelContainer(for: [ThemeWeekProgress.self, Habit.self, HabitCompletion.self, ReflectionNote.self], inMemory: true)
}

