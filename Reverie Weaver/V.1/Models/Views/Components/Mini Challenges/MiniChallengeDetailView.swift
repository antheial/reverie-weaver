//
// MiniChallengeDetailView.swift
// Reverie Weaver
//
// Individual challenge deep-dive page
// Shows philosophy, 3 habits, ADHD features, tips, progression
// ✅ SIMPLIFIED with overview-based progress tracking
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
    @StateObject private var progressManager = Project50ProgressManager.shared
    
    let challenge: MiniChallenge
    @State private var addedToDesk = false
    @State private var showCompletionModal = false
    
    // ✅ FIXED: Match by tag instead of UUID
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
            ZStack {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        
                        // Show progress if active
                        // Show progress only if active AND habits still exist
                        if let progress = activeProgress,
                           habits.contains(where: { $0.programTag == "C7-\(challenge.tag)" }) {
                            progressSection(progress)
                        }
                        
                        habitsSection
                        adhdFeaturesSection
                        tipsSection
                        howToProgressSection
                    }
                    .padding(.bottom, 120)
                }
            }
            .toolbar { closeButton }
            .overlay(alignment: .bottomTrailing) {
                if !isAlreadyActive {
                    startChallengeButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCompletionModal) {
                ThreadCompleteModal(
                    challenge: challenge,
                    onFinish: {
                        finishChallenge()
                    },
                    onRestart: {
                        restartChallenge()
                    }
                )
            }
            .onChange(of: allHabitsCompletedToday) { oldValue, newValue in
                if newValue && !oldValue {
                    // All habits just completed - update progress
                    updateDailyProgress()
                }
            }
        }
    }
}

// MARK: - View Sections

private extension MiniChallengeDetailView {
    
    // MARK: Hero Section
    var heroSection: some View {
        VStack(spacing: 20) {
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
                            endRadius: 120
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 14)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color(hex: challenge.colorHex).opacity(0.4),
                                Color(hex: challenge.colorHex).opacity(0.2)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color(hex: challenge.colorHex).opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(hex: challenge.colorHex).opacity(0.4), radius: 20, y: 8)
                
                Image(systemName: challenge.icon)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Color(hex: challenge.colorHex))
            }
            
            VStack(spacing: 8) {
                Text(challenge.title)
                    .font(.system(size: 23, weight: .bold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Text("7-DAY CHALLENGE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(hex: challenge.colorHex))
                            .shadow(color: Color(hex: challenge.colorHex).opacity(0.4), radius: 8, y: 2)
                    )
                
                VStack(spacing: 8) {
                    Text(challenge.tagline)
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Text(challenge.description)
                        .font(.system(size: 11, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(.top, 10)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: ✅ Progress Section (shows when active)
    @ViewBuilder
    func progressSection(_ progress: MiniChallengeProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: challenge.colorHex))
                Text("YOUR PROGRESS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                Spacer()
                Text("\(progress.daysCompleted)/7")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.sageGreen)
            }
            
            // Day circles (1-7) - smaller 24px
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { day in
                    ZStack {
                        Circle()
                            .fill(day <= progress.daysCompleted ?
                                  Color.sageGreen : Color.dynamicSecondaryLabel.opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        if day <= progress.daysCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(day)")
                                .font(.system(size: 10, weight: .semibold))
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
            
            // Status messages
            if progress.daysCompleted >= 7 {
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.sageGreen)
                        Text("Challenge Complete!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.sageGreen)
                    }
                    
                    Text("You completed all habits for 7 days. Amazing work!")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    Button {
                        showCompletionModal = true
                    } label: {
                        Text("Finish Challenge")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.sageGreen)
                            .cornerRadius(12)
                            .shadow(color: Color.shadowColor.opacity(0.2), radius: 4, y: 2)
                    }
                }
            } else if progress.isTodayComplete {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sageGreen)
                    Text("Today's habits completed! Keep going tomorrow.")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "circle")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    Text("Complete all \(challenge.habits.count) habits today to mark Day \(progress.daysCompleted + 1)")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            
            // Time remaining hint
            if progress.isWithinTimeframe && progress.daysCompleted < 7 {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                    Text("Day \(progress.daysSinceStart + 1) of your journey (10-day window)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
                }
            }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
        
        // 🗑 Add delete button below the progress card
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
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.red.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Habits Section
    var habitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("INCLUDED HABITS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(challenge.habits) { habit in
                    ChallengeHabitCard(habit: habit, colorScheme: colorScheme)
                        .padding(.horizontal, 24)
                }
            }
        }
    }
    
    // MARK: ADHD Features Section
    var adhdFeaturesSection: some View {
        SectionCard(
            icon: "checkmark.seal.fill",
            iconColor: Color(hex: challenge.colorHex),
            title: "ADHD-Friendly Features",
            content: nil,
            rows: challenge.adhdFeatures.map { ("checkmark.circle", $0) }
        )
    }
    
    // MARK: Tips Section
    var tipsSection: some View {
        SectionCard(
            icon: "lightbulb.fill",
            iconColor: Color(hex: challenge.colorHex),
            title: "Tips for Success",
            content: nil,
            rows: challenge.tips.map { ("sparkles", $0) }
        )
    }
    
    // MARK: How to Progress Section (static guide)
    var howToProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: challenge.colorHex))
                Text("HOW TO PROGRESS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                progressStep(
                    number: 1,
                    text: "Complete all \(challenge.habits.count) habits in one day"
                )
                progressStep(
                    number: 2,
                    text: "Repeat for 7 total days (can be non-consecutive within 10 days)"
                )
                progressStep(
                    number: 3,
                    text: "Celebrate your growth and renewed momentum!"
                )
            }
            
            Text(challenge.progressionGuide)
                .font(.system(size: 11))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineSpacing(3)
                .padding(.top, 4)
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    func progressStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: challenge.colorHex).opacity(0.15))
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: challenge.colorHex))
            }
            
            Text(text)
                .font(.system(size: 12))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: Close Button
    var closeButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.shadowColor, radius: 4, y: 2)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 32, height: 32)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                }
            }
        }
    }
    
    // MARK: Start Challenge Button
    var startChallengeButton: some View {
        Button {
            addChallengeToDesk()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: addedToDesk ? "checkmark.circle.fill" : "play.circle.fill")
                    .font(.system(size: 18))
                Text(addedToDesk ? "Added to Desk ✓" : "Start 7-Day Challenge")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: challenge.colorHex).opacity(0.9), Color(hex: challenge.colorHex).opacity(0.7)],
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

// MARK: - Actions

private extension MiniChallengeDetailView {
    
    func addChallengeToDesk() {
        guard !isAlreadyActive else { return }
        
        // Sort habits by time-of-day category priority
        let sortedNewHabits = challenge.habits.sorted {
            categoryTimePriority($0.category) < categoryTimePriority($1.category)
        }
        
        // Get existing habits sorted by current order
        let existingHabits = habits.sorted { $0.order < $1.order }
        
        // Smart insertion: interleave based on category time priority
        var currentOrder = 0
        var processedExisting = 0
        
        // ✅ CRITICAL: Track IDs of newly created habits
        var newHabitIDs: [UUID] = []
        
        for newHabit in sortedNewHabits {
            let newPriority = categoryTimePriority(newHabit.category)
            
            // Insert existing habits that come before this new habit
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
            
            // Insert the new habit with unique challenge tag
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
            newHabitIDs.append(habit.id)  // ✅ Track this ID
            currentOrder += 1
        }
        
        // Handle remaining existing habits (shift them down)
        while processedExisting < existingHabits.count {
            existingHabits[processedExisting].order = currentOrder
            currentOrder += 1
            processedExisting += 1
        }
        
        // ✅ FIXED: Check if progress already exists for this tag
        do {
            try modelContext.save()
            
            // Check for existing progress by tag
            let existingProgress = allProgress.first { progress in
                progress.challengeTag == challenge.tag && !progress.isCompleted
            }
            
            if existingProgress == nil {
                           // ✅ CRITICAL: Pass habit IDs to progress tracker
                           let progress = MiniChallengeProgress(
                               challengeID: challenge.id,
                               challengeTag: challenge.tag,
                               challengeTitle: challenge.title,
                               requiredHabitIDs: newHabitIDs,  // ✅ FIXED
                               startDate: Date()
                           )
                modelContext.insert(progress)
                try modelContext.save()
                
                progressManager.addMiniChallenge(id: challenge.id)
                          } else if existingProgress?.requiredHabitIDs.isEmpty == true {
                              // Backfill for existing trackers
                              existingProgress?.requiredHabitIDs = newHabitIDs
                              try modelContext.save()
                          }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                addedToDesk = true
            }
            ReverieHaptics.successFeedback()
            
            // Auto-dismiss after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } catch {
            print("Failed to save challenge habits: \(error)")
        }
    }
    
    func updateDailyProgress() {
           guard let progress = activeProgress else { return }
           
           // ✅ FIXED: Use proper verification
           progress.checkAndUpdateProgress(completions: completions)
           
           do {
               try modelContext.save()
               
               if progress.isCompleted {
                   ReverieHaptics.successFeedback()
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                       showCompletionModal = true
                   }
               } else if progress.isTodayComplete {
                   ReverieHaptics.lightFeedback()
               }
           } catch {
               print("Failed to update progress: \(error)")
           }
       }
    
    func finishChallenge() {
        guard let progress = activeProgress else { return }
        
        // Remove challenge habits from Desk
        let challengeHabits = habits.filter { $0.programTag == "C7-\(challenge.tag)" }
        for habit in challengeHabits {
            modelContext.delete(habit)
        }
        
        // Mark progress as completed
        progress.isCompleted = true
        progress.completedDate = Date()
        
        // Clear from progress manager
        progressManager.completeMiniChallenge()
        
        do {
            try modelContext.save()
            ReverieHaptics.successFeedback()
            dismiss()
        } catch {
            print("Failed to finish challenge: \(error)")
        }
    }
    
    func restartChallenge() {
        // First finish current challenge
        finishChallenge()
        
        // Then immediately restart by dismissing and reopening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            addChallengeToDesk()
        }
    }
    
    // MARK: Delete Challenge
    func deleteChallenge() {
        let challengeHabits = habits.filter { $0.programTag == "C7-\(challenge.tag)" }
        for habit in challengeHabits {
            modelContext.delete(habit)
        }

        if let progress = allProgress.first(where: { p in
            p.challengeTag == challenge.tag && !p.isCompleted
        }) {
            modelContext.delete(progress)
        }

        progressManager.completeMiniChallenge()

        do {
            try modelContext.save()
            ReverieHaptics.lightFeedback()
            withAnimation(.spring()) { dismiss() }
        } catch {
            print("Failed to delete challenge: \(error)")
        }
    }
    
    func categoryTimePriority(_ category: String) -> Int {
           switch category {
           case "Morning Rituals", "Focus Flow": return 1
           case "Health Foundations", "Dopamine Design": return 2
           case "Creative Practice", "Tiny Anchors": return 3
           case "Connection", "Connection Lite": return 4
           case "Mindful Living", "Chaos Mode", "Novelty Seeker", "Glowing Journey": return 5
           default: return 999
           }
       }
   }

// MARK: - Challenge Habit Card

private struct ChallengeHabitCard: View {
    let habit: Project50Habit
    let colorScheme: ColorScheme
    
    var body: some View {
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
                    Text(habit.name)
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                Spacer()
            }
            
            Text(habit.description)
                .font(.system(size: 12, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }
}

// MARK: - Section Card Component

private struct SectionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String?
    var rows: [(String, String)]? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            
            if let content = content {
                Text(content)
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineSpacing(4)
            }
            
            if let rows = rows {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rows, id: \.1) { row in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: row.0)
                                .font(.system(size: 12))
                                .foregroundStyle(iconColor.opacity(0.85))
                                .padding(.top, 2)
                            Text(row.1)
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
    }
}

// MARK: - Thread Complete Modal

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
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Modal content - matching your reverieCardStyle
            VStack(spacing: 24) {
                // Sparkle animation circle
                ZStack {
                    // Background glow
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
                    
                    // Sparkles around icon
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
                    
                    // Main icon
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
                
                // Text content
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
                
                // Buttons - matching your style
                VStack(spacing: 12) {
                    // Finish button - matching sageGreen style from your app
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
                            .shadow(color: Color.shadowColor.opacity(0.2), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    
                    // Restart button - subtle style matching your secondary buttons
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
            
            // Confetti overlay
            if showConfetti {
                ConfettiView(isActive: .constant(true))
            }
        }
        .onAppear {
            // Stop confetti after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
    }
}
