//
// MiniChallengeDetailView.swift
// Reverie Weaver
//
//

import SwiftUI
import SwiftData

struct MiniChallengeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \MiniChallengeProgress.startDate, order: .reverse)
    private var allProgress: [MiniChallengeProgress]
    
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @Query private var reflections: [DailyReflection]

    private var progressManager = Project50ProgressManager.shared
    
    let challenge: MiniChallenge
    
    init(challenge: MiniChallenge) {
        self.challenge = challenge
    }
    
    @State private var addedToDesk = false
    @State private var showCompletionModal = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Match by tag instead of UUID
    private var activeProgress: MiniChallengeProgress? {
        allProgress.first { progress in
            progress.challengeTag == challenge.tag && !progress.isCompleted
        }
    }
    
    // Check if challenge habits are in Desk
    private var isAlreadyActive: Bool {
        habits.contains { habit in
            habit.programTag == "C7-\(challenge.tag)"
        }
    }
    
    private var challengeHabits: [Habit] {
        habits.filter { $0.programTag == "C7-\(challenge.tag)" }
    }
    
    // Check if all challenge habits completed today
    private var allHabitsCompletedToday: Bool {
        guard !challengeHabits.isEmpty else { return false }
        
        let today = Date()
        let todayCompletions = completions.filter { completion in
            Calendar.current.isDate(completion.completedAt, inSameDayAs: today)
        }
        
        return challengeHabits.allSatisfy { habit in
            todayCompletions.contains { $0.habitId == habit.id }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        
                        // Show progress if active
                        if let progress = activeProgress,
                           habits.contains(where: { $0.programTag == "C7-\(challenge.tag)" }) {
                            progressSection(progress)
                        }
                        
                        habitsSection
                    }
                    .padding(.bottom, 120)
                    .padding(.top, 60)
                }
                
                // Floating Close Button (Top Right)
                HStack {
                    Spacer()
                    closeButton
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                if !isAlreadyActive {
                    startChallengeButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCompletionModal) {
                ThreadCompleteModal(
                    challenge: challenge,
                    onFinish: { finishChallenge() },
                    onRestart: { restartChallenge() }
                )
            }
            .onChange(of: allHabitsCompletedToday) { oldValue, newValue in
                if newValue && !oldValue {
                    updateDailyProgress()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - View Sections

private extension MiniChallengeDetailView {

    // MARK: - Hero Section
    var heroSection: some View {
        VStack(spacing: 16) {
            ReverieEditorialHero(
                icon: challenge.icon,
                title: challenge.title,
                tagline: challenge.tagline,
                description: challenge.description,
                accentColorHex: challenge.colorHex,
                tier: challenge.tier
            )
            
            // Identity Statement
            if !challenge.identityStatement.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: challenge.colorHex))
                        Text("YOUR JOURNEY")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                    
                    Text(challenge.identityStatement)
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .reverieCardStyle(colorScheme: colorScheme)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Progress Section
    @ViewBuilder
    func progressSection(_ progress: MiniChallengeProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: challenge.colorHex))
                Text("YOUR PROGRESS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                Spacer()
                Text("\(progress.daysCompleted)/7")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.sageGreen)
            }
            
            // Day circles (1-7)
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { day in
                    ZStack {
                        Circle()
                            .fill(day <= progress.daysCompleted ?
                                  Color.sageGreen : Color.dynamicSecondaryLabel.opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        if day <= progress.daysCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(day)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dynamicSecondaryLabel.opacity(0.15))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.sageGreen, Color(hex: challenge.colorHex)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress.progressPercentage)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress.progressPercentage)
                }
            }
            .frame(height: 6)
            
            // Status messages (using rest-day-aware expiration check)
            if progress.isArchived {
                // Challenge archived as partial success
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.sageGreen.opacity(0.8))
                        Text("Challenge archived with \(Int(progress.successRate * 100))% completion!")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.sageGreen.opacity(0.9))
                    }

                    Text("View your achievement in the Monthly Archive")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
                }
            } else if progress.shouldShowRestart(reflections: reflections) {
                // Challenge expired with <85.7% - show restart option
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.terracottaRose)
                        Text("Challenge expired (\(progress.daysCompleted)/7 days). Try again?")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.terracottaRose)
                    }

                    Button {
                        restartChallenge()
                    } label: {
                        Text("Restart Challenge")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: challenge.colorHex))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: challenge.colorHex).opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color(hex: challenge.colorHex).opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            } else if progress.shouldArchive(reflections: reflections) {
                // Challenge should be archived (≥85.7% success) - auto-archive on appear
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.sageGreen.opacity(0.8))
                        Text("Great effort! \(progress.daysCompleted)/7 days completed.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.sageGreen.opacity(0.9))
                    }

                    Text("Archiving your achievement...")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
                }
                .onAppear {
                    archiveChallengeAsPartialSuccess()
                }
            } else if progress.daysCompleted >= 7 {
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.sageGreen)
                        Text("Challenge complete! Celebrate your growth.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.sageGreen)
                    }
                    
                    Button {
                        showCompletionModal = true
                    } label: {
                        Text("View Completion")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.sageGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.sageGreen.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.sageGreen.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            } else if progress.isTodayComplete {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.sageGreen)
                    Text("Today's habits completed! Keep going tomorrow.")
                        .font(.system(size: 13))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    Text("Complete all \(challenge.habits.filter { !$0.isOptionalForCompletion }.count) habits today to mark Day \(progress.daysCompleted + 1)")
                        .font(.system(size: 13))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            
            // Time remaining hint (using rest-day-aware methods)
            if !progress.isExpired(reflections: reflections) && !progress.isArchived && progress.isWithinTimeframe(reflections: reflections) && progress.daysCompleted < 7 {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                    Text("Day \(progress.daysSinceStart + 1) of your journey (8-day window)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
                }
            }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
        
        deleteChallengeButton
    }
    
    // MARK: Delete Challenge Button
    @ViewBuilder
    var deleteChallengeButton: some View {
        if isAlreadyActive {
            Button(role: .destructive) {
                deleteChallenge()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete Challenge")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.red.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Habits Section
    var habitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("INCLUDED HABITS")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ForEach(challenge.habits) { habit in
                    ChallengeHabitCardWithDetail(
                        habit: habit,
                        challenge: challenge,
                        colorScheme: colorScheme
                    )
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    // MARK: - Close Button
    var closeButton: some View {
        GlassCloseButton {
            dismiss()
        }
    }

    // MARK: Start Challenge Button
    var startChallengeButton: some View {
        Button {
            addChallengeToDesk()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: addedToDesk ? "checkmark.circle.fill" : "play.circle.fill")
                    .font(.system(size: 18))
                Text(addedToDesk ? "Added!" : "Start 7-Day Challenge")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(addedToDesk ? Color.sageGreen : Color(hex: challenge.colorHex))
                    .shadow(color: Color.shadowColor.opacity(0.3), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
        .disabled(addedToDesk)
        .padding(24)
    }
}

// MARK: - Enhanced Challenge Habit Card with Detail Sheet

private struct ChallengeHabitCardWithDetail: View {
    let habit: Project50Habit
    let challenge: MiniChallenge
    let colorScheme: ColorScheme
    @State private var showingDetail = false

    var body: some View {
        Button {
            ReverieHaptics.lightFeedback()
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: habit.colorHex).opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color(hex: habit.colorHex).opacity(0.3), lineWidth: 1)
                            )
                        Image(systemName: habit.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: habit.colorHex))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(habit.name)
                                .font(.system(size: 14, weight: .semibold))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                            // Show "Optional" badge for optional habits
                            if habit.isOptionalForCompletion {
                                Text("Optional")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.sageGreen.opacity(0.8))
                                    )
                            }
                        }

                        Text(habit.description.extractBriefDescription())
                            .font(.system(size: 12))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            HabitDetailSheet(habit: habit, challenge: challenge, colorScheme: colorScheme)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }
}

// MARK: - Habit Detail Sheet

private struct HabitDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let habit: Project50Habit
    let challenge: MiniChallenge
    let colorScheme: ColorScheme

    @State private var dragOffset: CGFloat = 0

    // Reflection state (for optional habits like Progress Check-In)
    @State private var showReflectionInput = false
    @State private var reflectionText = ""
    @State private var isSaving = false

    // Query for existing reflection
    @Query private var allReflections: [ReflectionNote]

    private var existingReflection: ReflectionNote? {
        allReflections.first { $0.challengeTag == challenge.tag }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: habit.colorHex).opacity(0.15))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color(hex: habit.colorHex).opacity(0.3), lineWidth: 1.5)
                                    )

                                Image(systemName: habit.icon)
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(hex: habit.colorHex))
                            }

                            Text(habit.name)
                                .font(.system(size: 22, weight: .bold))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .multilineTextAlignment(.center)

                            // Show "Optional" note for optional habits
                            if habit.isOptionalForCompletion {
                                Text("This reflection is optional and won't affect your completion rate")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.sageGreen)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }

                            Text(habit.description.extractBriefDescription())
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 24)

                        // Detail Sections
                        VStack(spacing: 16) {
                            if !habit.description.extractCore().isEmpty {
                                DetailSection(
                                    icon: "target",
                                    title: "What to do",
                                    content: habit.description.extractCore(),
                                    accentColor: Color(hex: habit.colorHex),
                                    colorScheme: colorScheme
                                )
                            }

                            if !habit.description.extractAnchor().isEmpty {
                                DetailSection(
                                    icon: "clock",
                                    title: "When to do it",
                                    content: habit.description.extractAnchor(),
                                    accentColor: Color(hex: habit.colorHex),
                                    colorScheme: colorScheme
                                )
                            }

                            if !habit.description.extractIfThen().isEmpty {
                                DetailSection(
                                    icon: "arrow.right.circle.fill",
                                    title: "How to remember",
                                    content: habit.description.extractIfThen(),
                                    accentColor: Color(hex: habit.colorHex),
                                    colorScheme: colorScheme
                                )
                            }

                            if !habit.description.extractWhy().isEmpty {
                                DetailSection(
                                    icon: "lightbulb.fill",
                                    title: "Why it works",
                                    content: habit.description.extractWhy(),
                                    accentColor: Color(hex: habit.colorHex),
                                    colorScheme: colorScheme
                                )
                            }
                        }

                        // Rescue protocol
                        if !habit.description.extractRescue().isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lifepreserver.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)

                                    Text("STRUGGLING? DO THIS INSTEAD")
                                        .font(.system(size: 12, weight: .bold))
                                        .fontDesign(.serif)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                        .foregroundStyle(.white)
                                }

                                Text(habit.description.extractRescue())
                                    .font(.system(size: 12, weight: .regular))
                                    .fontDesign(.serif)
                                    .foregroundStyle(.white)
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.sageGreen, Color.sageGreen.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .padding(.horizontal, 24)
                        }

                        // MARK: - Reflection Section (for optional Progress Check-In habits)
                        if habit.isOptionalForCompletion {
                            reflectionSection
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 60)
                }

                // Floating Close Button (Top Right)
                HStack {
                    Spacer()
                    GlassCloseButton {
                        dismiss()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height > 0 {
                            dragOffset = gesture.translation.height
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.height > 100 {
                            dismiss()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
            )
            .offset(y: dragOffset)
            .onAppear {
                // Load existing reflection if any
                if let existing = existingReflection {
                    reflectionText = existing.content
                }
            }
        }
    }

    // MARK: - Reflection Section

    @ViewBuilder
    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: habit.colorHex))

                Text("YOUR REFLECTION")
                    .font(.system(size: 12, weight: .semibold))
                    .fontDesign(.serif)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(.horizontal, 24)

            // Show existing reflection or input
            if let existing = existingReflection, !showReflectionInput {
                // Display existing reflection
                VStack(alignment: .leading, spacing: 12) {
                    Text(existing.content)
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .lineSpacing(4)

                    HStack {
                        Text("Last updated: \(existing.lastEdited, style: .date) at \(existing.lastEdited, style: .time)")
                            .font(.system(size: 10))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)

                        Spacer()

                        Button {
                            reflectionText = existing.content
                            withAnimation(.spring(response: 0.3)) {
                                showReflectionInput = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                Text("Edit")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: habit.colorHex))
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .reverieCardStyle(colorScheme: colorScheme)
                .padding(.horizontal, 24)
            } else if showReflectionInput {
                // Reflection input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reflect on your progress anytime. Schedule this whenever works for you.")
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)

                    ZStack(alignment: .topLeading) {
                        if reflectionText.isEmpty {
                            Text("Write your reflection here...")
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $reflectionText)
                            .font(.system(size: 13, weight: .regular))
                            .fontDesign(.serif)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 150)
                    }

                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showReflectionInput = false
                                if let existing = existingReflection {
                                    reflectionText = existing.content
                                } else {
                                    reflectionText = ""
                                }
                            }
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 13, weight: .medium))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        }

                        Spacer()

                        Button {
                            saveReflection()
                        } label: {
                            HStack(spacing: 6) {
                                if isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                }
                                Text("Save Reflection")
                                    .font(.system(size: 13, weight: .semibold))
                                    .fontDesign(.serif)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                          ? Color.gray.opacity(0.5)
                                          : Color(hex: habit.colorHex))
                            )
                        }
                        .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .reverieCardStyle(colorScheme: colorScheme)
                .padding(.horizontal, 24)
            } else {
                // No existing reflection - show button to start
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showReflectionInput = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16))

                        Text("Write Reflection")
                            .font(.system(size: 14, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(Color(hex: habit.colorHex))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(hex: habit.colorHex).opacity(0.5), lineWidth: 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: habit.colorHex).opacity(0.08))
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Save Reflection

    private func saveReflection() {
        let trimmedContent = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        isSaving = true

        // Check if we have an existing reflection to update
        if let existing = existingReflection {
            // Update existing
            existing.content = trimmedContent
            existing.lastEdited = Date()
        } else {
            // Create new reflection
            let newReflection = ReflectionNote(
                type: "challenge",
                label: challenge.title,
                title: "Challenge Reflection",
                startDate: Date(),
                content: trimmedContent,
                challengeTag: challenge.tag
            )
            modelContext.insert(newReflection)
        }

        do {
            try modelContext.save()
            ReverieHaptics.successFeedback()

            withAnimation(.spring(response: 0.3)) {
                showReflectionInput = false
            }
        } catch {
            print("Failed to save reflection: \(error)")
        }

        isSaving = false
    }
}

// MARK: - Detail Section Component (Visual Update)

private struct DetailSection: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(accentColor)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .fontDesign(.serif)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            
            // Parse string into lists vs. regular text
            VStack(alignment: .leading, spacing: 6) {
                ForEach(content.components(separatedBy: "\n"), id: \.self) { line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    
                    if !trimmed.isEmpty {
                        // Check if line is a list item (handles •, -, – and ·)
                        if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("–") || trimmed.hasPrefix("·") {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.dynamicSecondaryLabel)
                                
                                Text(cleanListItem(trimmed))
                                    .font(.system(size: 13, weight: .regular))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.bottom, 2) // Extra space between list items
                        } else {
                            // Standard text paragraph
                            Text(trimmed)
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 18)
    }
    
    func cleanListItem(_ str: String) -> String {
        var clean = str
        // Clean common bullet characters
        let prefixes = ["•", "-", "–", "·"]
        for prefix in prefixes {
            if clean.hasPrefix(prefix) {
                clean.removeFirst()
                break
            }
        }
        return clean.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Enhanced String Parsing for Complex Content

extension String {
    // Helper to find content between specific sections markers
    private func extractSection(startMarkers: [String], stopMarkers: [String]) -> String {
        let lines = self.split(separator: "\n")
        var isCapturing = false
        var content = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 1. CHECK STOP MARKERS FIRST
            // If we hit ANY known stop marker, we stop capturing immediately
            for stop in stopMarkers {
                if trimmed.hasPrefix(stop) {
                    if isCapturing {
                        return content.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
            
            // 2. CHECK START MARKERS
            if !isCapturing {
                for start in startMarkers {
                    if trimmed.hasPrefix(start) {
                        isCapturing = true
                        // Remove the marker itself from the first line
                        // e.g. "• Core: Do x" -> "Do x"
                        let cleanLine = trimmed.dropFirst(start.count).trimmingCharacters(in: .whitespaces)
                        if !cleanLine.isEmpty {
                            content += cleanLine + "\n"
                        }
                        break // Found our start, stop checking other start markers
                    }
                }
            } else {
                // 3. CAPTURE CONTENT
                // We are inside the section, so add the line
                // This preserves bullets, hyphens, and newlines inside the section
                content += trimmed + "\n"
            }
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Known headers mapping (English + Chinese/Custom variants)
    var coreMarkers: [String] { ["• Core:", "• 核心:"] }
    var anchorMarkers: [String] { ["• Anchor:", "• Anchor point:", "• 锚点:"] }
    var ifThenMarkers: [String] { ["• If-then:", "• 如果-那么:", "• If-Then:"] }
    var whyMarkers: [String] { ["• Why It Works:", "• 原理:", "• Why:"] }
    var rescueMarkers: [String] { ["• Rescue:", "• 救援:", "• 急救:"] }
    
    // Combined list of ALL markers to use as stops
    var allMarkers: [String] {
        coreMarkers + anchorMarkers + ifThenMarkers + whyMarkers + rescueMarkers
    }
    
    func extractBriefDescription() -> String {
        let lines = self.split(separator: "\n")
        guard let firstLine = lines.first else { return "" }
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        
        // If the very first line matches ANY known marker, there is no brief description
        for marker in allMarkers {
            if trimmed.hasPrefix(marker) { return "" }
        }
        return trimmed
    }
    
    // Each extractor defines its START markers and uses ALL OTHER markers as STOPS
    func extractCore() -> String {
        extractSection(startMarkers: coreMarkers, stopMarkers: anchorMarkers + ifThenMarkers + whyMarkers + rescueMarkers)
    }
    
    func extractAnchor() -> String {
        extractSection(startMarkers: anchorMarkers, stopMarkers: ifThenMarkers + whyMarkers + rescueMarkers + coreMarkers) // Added coreMarkers just in case order varies
    }
    
    func extractIfThen() -> String {
        extractSection(startMarkers: ifThenMarkers, stopMarkers: whyMarkers + rescueMarkers + anchorMarkers)
    }
    
    func extractWhy() -> String {
        extractSection(startMarkers: whyMarkers, stopMarkers: rescueMarkers + ifThenMarkers)
    }
    
    func extractRescue() -> String {
        extractSection(startMarkers: rescueMarkers, stopMarkers: []) // Usually last, so no stop markers needed (EOF stops it)
    }
}

// MARK: - Actions

private extension MiniChallengeDetailView {

    func addChallengeToDesk() {
        guard !isAlreadyActive else { return }

        // Filter out optional habits - they won't be added to DeskView
        let requiredHabits = challenge.habits.filter { !$0.isOptionalForCompletion }

        let sortedNewHabits = requiredHabits.sorted {
            categoryTimePriority($0.category) < categoryTimePriority($1.category)
        }

        let existingHabits = habits.sorted { $0.order < $1.order }

        var currentOrder = 0
        var processedExisting = 0
        var newHabitIDs: [UUID] = []

        for newHabit in sortedNewHabits {
            let newPriority = categoryTimePriority(newHabit.category)

            while processedExisting < existingHabits.count {
                let existing = existingHabits[processedExisting]
                let existingPriority = categoryTimePriority(existing.category)

                if existingPriority <= newPriority {
                    existing.order = currentOrder
                    currentOrder += 1
                    processedExisting += 1
                } else {
                    break
                }
            }

            let habit = Habit(
                name: newHabit.name,
                description: newHabit.description,
                category: newHabit.category,
                categoryIcon: newHabit.icon,
                icon: newHabit.icon,
                colorHex: newHabit.colorHex,
                completionMessage: "Thread woven - small sprint complete!",
                frequency: "daily",
                order: currentOrder,
                programTag: "C7-\(challenge.tag)",
                programLevel: nil
            )
            modelContext.insert(habit)
            newHabitIDs.append(habit.id)
            currentOrder += 1
        }
        
        while processedExisting < existingHabits.count {
            existingHabits[processedExisting].order = currentOrder
            currentOrder += 1
            processedExisting += 1
        }
        
        do {
            try modelContext.save()
            
            let existingProgress = allProgress.first { progress in
                progress.challengeTag == challenge.tag && !progress.isCompleted
            }
            
            if existingProgress == nil {
                guard !newHabitIDs.isEmpty else {
                    errorMessage = "Challenge must have at least one habit"
                    showError = true
                    return
                }
                
                let progress = MiniChallengeProgress(
                    challengeID: challenge.id,
                    challengeTag: challenge.tag,
                    challengeTitle: challenge.title,
                    requiredHabitIDs: newHabitIDs,
                    startDate: Date()
                )
                modelContext.insert(progress)
                try modelContext.save()
                
                progressManager.addMiniChallenge(id: challenge.id)
            } else if existingProgress?.requiredHabitIDs.isEmpty == true {
                guard !newHabitIDs.isEmpty else {
                    errorMessage = "Challenge must have at least one habit"
                    showError = true
                    return
                }
                existingProgress?.requiredHabitIDs = newHabitIDs
                try modelContext.save()
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                addedToDesk = true
            }
            ReverieHaptics.successFeedback()

            // NOTE: Do NOT auto-dismiss here. Let user review the progress section
            // and close manually when ready (matches ThemeWeek behavior).
        } catch {
            print("Failed to save challenge habits: \(error)")
        }
    }
    
    func updateDailyProgress() {
        guard let progress = activeProgress else { return }

        progress.checkAndUpdateProgress(completions: completions, reflections: reflections)
        
        do {
            try modelContext.save()
            
            if progress.isCompleted {
                ReverieHaptics.successFeedback()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCompletionModal = true
                }
            }
        } catch {
            print("Failed to update progress: \(error)")
        }
    }
    
    func finishChallenge() {
        guard let progress = activeProgress else { return }
        
        // ✅ FIX: Capture data BEFORE deletion to prevent accessing detached objects
        let habitsToDelete = challengeHabits
        
        // ✅ FIX: Dismiss FIRST to prevent view from re-rendering with deleted data
        dismiss()
        
        // ✅ FIX: Perform operations after dismiss
        Task { @MainActor in
            // Small delay to ensure dismiss animation completes
            try? await Task.sleep(for: .milliseconds(100))
            
            do {
                // Delete habits (but keep progress marked as completed)
                for habit in habitsToDelete {
                    habit.prepareForDeletion()
                    modelContext.delete(habit)
                }
                
                // Mark challenge as completed
                progress.isCompleted = true
                
                // Save changes
                try modelContext.save()
                
                // Update journey progress based on completed challenges
                JourneyProgressManager.shared.syncJourneyProgress(in: modelContext)
                
                // Update progress manager
                progressManager.completeMiniChallenge()
                
                // Haptic feedback
                ReverieHaptics.successFeedback()
            } catch {
                print("⚠️ Failed to complete challenge: \(error)")
            }
        }
    }
    
    func restartChallenge() {
        guard let oldProgress = activeProgress else { return }

        // Capture data needed for new progress before deletion
        let challengeID = oldProgress.challengeID
        let challengeTag = oldProgress.challengeTag
        let challengeTitle = oldProgress.challengeTitle
        let requiredHabitIDs = oldProgress.requiredHabitIDs

        // Delete the old progress record (replacing it)
        modelContext.delete(oldProgress)

        // Create a fresh progress record
        let newProgress = MiniChallengeProgress(
            challengeID: challengeID,
            challengeTag: challengeTag,
            challengeTitle: challengeTitle,
            requiredHabitIDs: requiredHabitIDs,
            startDate: Date()
        )

        modelContext.insert(newProgress)

        do {
            try modelContext.save()
            ReverieHaptics.lightFeedback()
        } catch {
            print("Failed to restart challenge: \(error)")
        }
    }

    /// Archive the challenge as a partial success (≥85.7% completion)
    func archiveChallengeAsPartialSuccess() {
        guard let progress = activeProgress else { return }
        guard progress.shouldArchive(reflections: reflections) else { return }

        progress.archive()

        do {
            try modelContext.save()
            ReverieHaptics.successFeedback()
        } catch {
            print("Failed to archive challenge: \(error)")
        }
    }
    
    func deleteChallenge() {
        // ✅ FIX: Capture data BEFORE deletion to prevent accessing detached objects
        let habitsToDelete = challengeHabits // Capture the array
        let progressToDelete = activeProgress // Capture the reference
        
        // ✅ FIX: Dismiss FIRST to prevent view from re-rendering with deleted data
        dismiss()
        
        // ✅ FIX: Perform deletion after dismiss with slight delay to ensure view is gone
        Task { @MainActor in
            // Small delay to ensure dismiss animation completes
            try? await Task.sleep(for: .milliseconds(100))
            
            do {
                // Delete habits
                for habit in habitsToDelete {
                    habit.prepareForDeletion()
                    modelContext.delete(habit)
                }
                
                // Delete progress
                if let progress = progressToDelete {
                    modelContext.delete(progress)
                }
                
                // Save context
                try modelContext.save()
                
                // Update progress manager
                progressManager.completeMiniChallenge()
                
                // Haptic feedback
                ReverieHaptics.lightFeedback()
            } catch {
                // Note: Can't show error in this view anymore since it's dismissed
                print("⚠️ Failed to delete challenge: \(error)")
            }
        }
    }
    
    func categoryTimePriority(_ category: String) -> Int {
        switch category {
        case "Morning Rituals", "Focus Flow", "Focus Sprint": return 1
        case "Health Foundations", "Dopamine Design", "Energy Recharge": return 2
        case "Creative Practice", "Tiny Anchors", "Creative Flow": return 3
        case "Connection", "Connection Lite", "Connection Week": return 4
        case "Mindful Living", "Chaos Mode", "Novelty Seeker", "Glowing Journey", "Reflection Reset", "Gratitude Glow": return 5
        default: return 999
        }
    }
}

// MARK: - Thread Complete Modal

struct ThreadCompleteModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let challenge: MiniChallenge
    let onFinish: () -> Void
    let onRestart: () -> Void
    
    @State private var showConfetti = true
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: challenge.colorHex).opacity(0.3),
                                    Color(hex: challenge.colorHex).opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 12)
                    
                    ForEach(0..<8) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: challenge.colorHex).opacity(0.6))
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 50,
                                y: sin(Double(index) * .pi / 4) * 50
                            )
                            .opacity(showConfetti ? 0.8 : 0)
                            .scaleEffect(showConfetti ? 1 : 0.3)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                                value: showConfetti
                            )
                    }
                    
                    ZStack {
                        Circle()
                            .fill(Color(hex: challenge.colorHex).opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color(hex: challenge.colorHex).opacity(0.3), lineWidth: 1.5)
                            )
                        
                        Image(systemName: challenge.icon)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(Color(hex: challenge.colorHex))
                    }
                }
                .frame(height: 140)
                
                VStack(spacing: 10) {
                    Text("Thread Complete!")
                        .font(.system(size: 23, weight: .bold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text("7-Day \(challenge.title)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: challenge.colorHex))
                    
                    Text("\"Small sprints weave\nthe fabric of change.\"")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .italic()
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color.white.opacity(0.85)
                                : Color.black.opacity(0.75)
                        )
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                }
                
                VStack(spacing: 12) {
                    Button {
                        ReverieHaptics.successFeedback()
                        onFinish()
                        dismiss()
                    } label: {
                        Text("Finish & Celebrate")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.sageGreen)
                            .cornerRadius(12)
                            .shadow(color: Color.shadowColor, radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        ReverieHaptics.lightFeedback()
                        onRestart()
                        dismiss()
                    } label: {
                        Text("Restart Challenge")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: challenge.colorHex))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: challenge.colorHex).opacity(colorScheme == .dark ? 0.15 : 0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                Color(hex: challenge.colorHex).opacity(colorScheme == .dark ? 0.25 : 0.20),
                                                lineWidth: 0.5
                                            )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                    .shadow(color: Color.shadowColor.opacity(0.25), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.adaptiveBorder(colorScheme: colorScheme), lineWidth: 1)
            )
            .padding(.horizontal, 32)
            
            if showConfetti {
                ConfettiView(isActive: .constant(true))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
    }
}
