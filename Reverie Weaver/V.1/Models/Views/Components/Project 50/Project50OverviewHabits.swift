//
// Project50OverviewHabits.swift
// Reverie Weaver
//
//

import SwiftUI
import SwiftData

struct Project50OverviewHabits: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    
    @StateObject private var progressManager = Project50ProgressManager.shared
    
    let level: Int
    let mode: ViewMode
    
    @State private var addedToDesk = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - View Mode
    enum ViewMode {
        case initial    // First time adding Level 1
        case unlock     // Unlocking Level 2/3 (shows "Add to Desk")
        case preview    // Just browsing (no action button)
    }
    
    // Default to initial mode for Level 1
    init(level: Int = 1, mode: ViewMode = .initial) {
        self.level = level
        self.mode = mode
    }
    
    // MARK: - Level Habits
    private var levelHabits: [Project50Habit] {
        Project50Data.categories.flatMap { category in
            category.levels[level] ?? []
        }
    }
    
    // Check if habits already exist in Desk
    private var habitsAlreadyAdded: Bool {
        let habitNames = Set(levelHabits.map { $0.name })
        return habits.contains { habitNames.contains($0.name) }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                
                // Background
                ReverieWeaverBackground()
                    .ignoresSafeArea()
                
                // Main Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        headerSection
                        habitsListSection
                        
                        // Show action button based on mode
                        if mode != .preview {
                            actionButtonSection
                        }
                    }
                    .padding(.bottom, 60)
                    // 2. Add top padding to clear the floating button
                    .padding(.top, 60)
                }
                
                // 3. Floating Close Button
                HStack {
                    Spacer()
                    closeButton
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            // 4. Hide the default navigation bar and title
            .toolbar(.hidden, for: .navigationBar)
            
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - View Components

private extension Project50OverviewHabits {
    
    var navigationTitle: String {
        switch mode {
        case .initial:
            return "Level \(level): Foundation"
        case .unlock:
            return "Level \(level) Habits"
        case .preview:
            return "Preview: Level \(level)"
        }
    }
    
    // MARK: Header Section
    
    var headerSection: some View {
        VStack(spacing: 4) {
            Text(headerTitle)
                .font(.system(size: 18, weight: .semibold))
                 .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Text(headerSubtitle)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 24)
        }
        .padding(.top, 12)
    }
    
    var headerTitle: String {
        switch mode {
        case .initial:
            return "Included Habits"
        case .unlock:
            return "Level \(level) Habits"
        case .preview:
            return "Coming Soon: Level \(level)"
        }
    }
    
    var headerSubtitle: String {
        switch mode {
        case .initial:
            return "Each habit is designed to strengthen one of the seven Project 50 rules."
        case .unlock:
            return "Ready to level up? These habits will replace your current level."
        case .preview:
            return "Preview what's coming when you unlock Level \(level)."
        }
    }
    
    // MARK: Habits List
    
    var habitsListSection: some View {
        VStack(spacing: 12) {
            ForEach(levelHabits) { habit in
                LevelHabitCard(habit: habit, colorScheme: colorScheme)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: Action Button
    
    @ViewBuilder
    var actionButtonSection: some View {
        if habitsAlreadyAdded && mode == .initial {
            // Already added state
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sageGreen)
                Text("Already on Your Desk")
                    .font(.system(size: 14, weight: .medium))
                     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        } else if addedToDesk {
            // Success state
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sageGreen)
                Text("Added to Desk ✓")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sageGreen)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        } else {
            // Add button
            Button {
                addHabitsToDesk()
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.sageGreen.opacity(0.7), Color.dustyBlue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .shadow(color: Color.shadowColor.opacity(0.25), radius: 4, y: 3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        
        if mode != .preview {
            Text(helpText)
                .font(.system(size: 11))
                .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
    }
    
    var buttonTitle: String {
        mode == .unlock ? "Unlock & Add to Desk" : "Add All to Desk"
    }
    
    var helpText: String {
        if mode == .unlock {
            return "Your Level \(level - 1) habits will be removed and replaced with these."
        } else {
            return "You can always reset or continue your journey later."
        }
    }
    
    // MARK: Close Button
    var closeButton: some View {
        GlassCloseButton {
            dismiss()
        }
    }
}

// MARK: - Actions

private extension Project50OverviewHabits {
    
    // Proper tag enforcement and validation
    func addHabitsToDesk() {
        guard !levelHabits.isEmpty else {
            errorMessage = "No habits found for Level \(level)."
            showError = true
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // If unlocking Level 2 or 3, remove previous level habits first
            if mode == .unlock && level > 1 {
                removePreviousLevelHabits()
            }
            
            // Sort new habits by time-of-day category priority
            let sortedNewHabits = levelHabits.sorted {
                categoryTimePriority($0.category) < categoryTimePriority($1.category)
            }
            
            // Get existing habits sorted by current order
            let existingHabits = habits.sorted { $0.order < $1.order }
            
            // Smart insertion: interleave based on category time priority
            var currentOrder = 0
            var processedExisting = 0
            var createdHabitCount = 0
            
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
                
                // Create habit with ENFORCED tags
                let habit = Habit(
                    name: newHabit.name,
                    description: newHabit.description,
                    category: newHabit.category,
                    categoryIcon: newHabit.icon,
                    icon: newHabit.icon,
                    colorHex: newHabit.colorHex,
                    completionMessage: "Thread woven – you've honored your commitment.",
                    frequency: "daily",
                    order: currentOrder,
                    programTag: "P50",
                    programLevel: level          
                )
                modelContext.insert(habit)
                currentOrder += 1
                createdHabitCount += 1
            }
            
            // Handle remaining existing habits (shift them down)
            while processedExisting < existingHabits.count {
                existingHabits[processedExisting].order = currentOrder
                currentOrder += 1
                processedExisting += 1
            }
           
            do {
                try modelContext.save()
                
                print("✅ Project 50 Level \(level) added: \(createdHabitCount) habits with tag 'P50' and level \(level)")
                
                // Start journey if this is Level 1 initial setup
                if mode == .initial && level == 1 {
                    progressManager.startJourney()
                } else if mode == .unlock {
                    // Confirm unlock in progress manager
                    progressManager.confirmUnlock(level: level)
                }
                
                // Success feedback
                addedToDesk = true
                ReverieHaptics.successFeedback()
                
                // Auto-dismiss after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
                
            } catch {
                errorMessage = "Failed to save habits. Please try again."
                showError = true
                print("❌ Failed to save Project 50 habits: \(error)")
            }
        }
    }
    
    func categoryTimePriority(_ category: String) -> Int {
        switch category {
        case "Morning Rituals": return 1
        case "Health Foundations": return 2
        case "Creative Practice": return 3
        case "Connection": return 4
        case "Mindful Living": return 5
        default: return 999
        }
    }
    
    // Only remove habits with exact tag and level match
    func removePreviousLevelHabits() {
        let previousLevel = level - 1
        
        let previousLevelHabits = habits.filter { habit in
            habit.programTag == "P50" && habit.programLevel == previousLevel
        }
        
        print("🗑️ Removing \(previousLevelHabits.count) habits from Level \(previousLevel)")
        
        for habit in previousLevelHabits {
            habit.prepareForDeletion()
            modelContext.delete(habit)
        }
    }
}

// MARK: - Level Habit Card Component

private struct LevelHabitCard: View {
    let habit: Project50Habit
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: Color.shadowColor.opacity(0.15), radius: 3, y: 2)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: habit.colorHex))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
                     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Text(habit.description)
                    .font(.system(size: 12))
                    .lineLimit(2)
                     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .reverieCardStyle(colorScheme: colorScheme)
    }
}

