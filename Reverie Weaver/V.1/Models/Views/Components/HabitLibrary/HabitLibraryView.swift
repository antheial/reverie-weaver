//
// HabitLibraryView.swift
// Reverie Weaver
//
//

import SwiftUI
import SwiftData

struct HabitLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Data Queries
    
    @Query(filter: #Predicate<Habit> { $0.isArchived == false })
    private var activeHabits: [Habit]
    
    @Query(filter: #Predicate<Habit> { $0.isArchived == true })
    private var archivedHabits: [Habit]
    
    @Query(filter: #Predicate<PersonalizedJourney> { $0.isActive == true })
    private var activeJourneys: [PersonalizedJourney]
    
    // MARK: - State Management
    
    @StateObject private var localization = LocalizationManager.shared
    
    @State private var selectedCategory: String?
    @State private var selectedTemplate: HabitTemplate?
    @State private var showAddSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var showProject50Overview = false
    @State private var showProject50Levels = false
    @State private var showMiniChallenges = false
    @State private var showThemeWeeks = false
    @State private var showClearConfirmation = false
    @State private var showVitalityProgram = false
    
    @State private var showGoalSelector = false
    @State private var showMyJourney = false
    
    @State private var journeyResetTrigger = UUID()
    
    @State private var newlyCreatedJourney: PersonalizedJourney?
    
    // First-time user onboarding
    @AppStorage("hasSeenGetStartedButton") private var hasSeenGetStartedButton = false
    @State private var glowAnimation = false
    
    @State private var isDeletingHabits = false
    
    // MARK: - Computed Properties
    
    private var activeJourney: PersonalizedJourney? {
        activeJourneys.first
    }
    
    private var filteredTemplates: [HabitTemplate] {
        if selectedCategory == "curated" {
            return []
        } else if let categoryString = selectedCategory,
                  let category = HabitCategory(rawValue: categoryString) {
            return HabitLibraryData.templates(for: category)
        }
        return HabitLibraryData.templates
    }
    
    private var hasStartedProject50: Bool {
        activeHabits.contains { $0.programTag == "P50" }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        categoryFilterSection
                        
                        if selectedCategory == "curated" {
                            curatedProgramsView
                        } else {
                            templatesGridView
                        }
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 60)
                }
                
                // Floating header buttons
                HStack {
                    getStartedButton
                    Spacer()
                    closeButton
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedTemplate) { template in
                HabitTemplateDetailView(template: template) {
                    addHabitFromTemplate(template)
                }
                .presentationDetents([.large, .fraction(0.75)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showProject50Overview) {
                Project50OverviewIntro()
                    .presentationDetents([.large, .fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMiniChallenges) {
                MiniChallengesOverviewIntro()
                    .presentationDetents([.large, .fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showThemeWeeks) {
                ThemeWeeksOverviewIntro()
                    .presentationDetents([.large, .fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showVitalityProgram) {
                VitalityOverviewIntro()
                    .presentationDetents([.large, .fraction(0.75)])
                    .presentationDragIndicator(.visible)
                    .id("vitality-overview") // Stable identity to prevent dismissal on parent @Query updates
            }
            .alert(localization.localize("library.habitAdded"), isPresented: $showAddSuccess) {
                Button(localization.localize("profile.ok"), role: .cancel) { }
            } message: {
                Text(localization.localize("library.habitAddedDesc"))
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $showProject50Levels) {
                Project50LevelsView()
            }
            .disabled(isDeletingHabits)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Habit Library")
        .id(journeyResetTrigger)
    }
}

//
// MARK: - Header Section
//
private extension HabitLibraryView {
    var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.paleMauve.opacity(0.3),
                                    Color.paleMauve.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 60, height: 60)
                        .blur(radius: 12)
                    
                    Circle()
                        .fill(Color.paleMauve.opacity(0.15))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.paleMauve.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.paleMauve)
                }
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localize("library.title"))
                        .font(.system(size: 23, weight: .bold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text(localization.localize("library.subtitle"))
                        .font(.system(size: 13, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(localization.localize("library.title")). \(localization.localize("library.subtitle"))")
    }
    
    var getStartedButton: some View {
        Button {
            if activeJourney != nil {
                showMyJourney = true
            } else {
                showGoalSelector = true
                hasSeenGetStartedButton = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: activeJourney != nil ? "map.fill" : "star.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                Text(activeJourney != nil ? "My Journey" : "Get Started")
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                if activeJourney != nil {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .accessibilityLabel("Active")
                }
            }
            .foregroundStyle(
                colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.85)
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .strokeBorder(
                        Color.paleMauve.opacity(0.5),
                        lineWidth: 1.5
                    )
            )
            .overlay(
                Group {
                    if !hasSeenGetStartedButton && activeJourney == nil {
                        Capsule()
                            .stroke(
                                Color.paleMauve.opacity(glowAnimation ? 0.6 : 0.2),
                                lineWidth: 2
                            )
                            .blur(radius: glowAnimation ? 4 : 2)
                            .scaleEffect(glowAnimation ? 1.15 : 1.0)
                            .accessibilityHidden(true)
                    }
                }
            )
            .shadow(
                color: (!hasSeenGetStartedButton && activeJourney == nil)
                    ? Color.paleMauve.opacity(glowAnimation ? 0.5 : 0.2)
                    : Color.clear,
                radius: glowAnimation ? 12 : 6,
                x: 0,
                y: 0
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(activeJourney != nil ? "My Journey" : "Get Started")
        .accessibilityHint(activeJourney != nil ? "View your active personalized journey" : "Start a personalized habit journey")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            if !hasSeenGetStartedButton && activeJourney == nil {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    glowAnimation = true
                }
            }
        }
        // Goal Selector Sheet
        .sheet(isPresented: $showGoalSelector) {
            GoalSelectorView { journey in
                newlyCreatedJourney = journey
                journeyResetTrigger = UUID()
                showGoalSelector = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showMyJourney = true
                }
            }
            .presentationDetents([.large, .fraction(0.75)])
            .presentationDragIndicator(.visible)
        }
        // Simplified My Journey sheet
               .sheet(isPresented: $showMyJourney) {
                   // Use activeJourney (from query) or newly created journey
                   if let journey = activeJourney ?? newlyCreatedJourney {
                       MyJourneyView(journey: journey) {
                           // Simple reset callback - just refresh and dismiss
                           #if DEBUG
                           print("🔄 Journey reset callback received in HabitLibraryView")
                           #endif
                           
                           // Force UI refresh
                           journeyResetTrigger = UUID()
                           // Clear the cached journey
                           newlyCreatedJourney = nil
                           // Dismiss the sheet immediately
                           showMyJourney = false
                           
                           ReverieHaptics.successFeedback()
                       }
                       .presentationDetents([.large, .fraction(0.75)])
                       .presentationDragIndicator(.visible)
                   }
               }
               .id(journeyResetTrigger)
           }
    
    var closeButton: some View {
        GlassCloseButton {
            dismiss()
        }
        .accessibilityLabel("Close")
        .accessibilityHint("Close habit library")
    }
}

//
// MARK: - Category Filter
//
private extension HabitLibraryView {
    var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                GlassmorphicCategoryChip(
                    title: "Curated",
                    icon: "sparkles",
                    color: .paleMauve,
                    isSelected: selectedCategory == "curated",
                    isFeatured: true
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = "curated"
                    }
                }
                
                GlassmorphicCategoryChip(
                    title: localization.localize("library.allCategories"),
                    icon: "square.grid.2x2",
                    color: .sageGreen,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }
                
                ForEach(HabitCategory.allCases, id: \.self) { category in
                    GlassmorphicCategoryChip(
                        title: localization.localize("category.\(category.rawValue.replacingOccurrences(of: " ", with: ""))"),
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category.rawValue
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category.rawValue
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter habits by category")
    }
}

//
// MARK: - Curated Programs
//
private extension HabitLibraryView {
    var curatedProgramsView: some View {
        VStack(spacing: 16) {
            // Project 50 Card
            Button {
                showProject50Overview = true
            } label: {
                CuratedProgramCard(
                    title: "Project 50",
                    subtitle: "8 essential habits to transform your routine",
                    icon: "sparkles",
                    accentColor: .paleMauve,
                    tag: "Starter Pack",
                    colorScheme: colorScheme
                )
            }
            .buttonStyle(.plain)
            
            // Manage Levels / Clear Buttons
            if hasStartedProject50 {
                VStack(spacing: 10) {
                    Button {
                        showProject50Levels = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            Text("Manage Levels / View Progress")
                                .font(.system(size: 13, weight: .medium))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Manage Project 50 Levels")
                    .accessibilityHint("View and manage your Project 50 progress")
                    
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                            Text("Clear Project 50 Habits")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete all Project 50 habits")
                    .accessibilityHint("Removes all Project 50 habits from your desk")
                    .disabled(isDeletingHabits)
                }
            }
            
            // 7-Day Mini Challenges Card
            Button {
                showMiniChallenges = true
            } label: {
                CuratedProgramCard(
                    title: "7-Day Mini Challenges",
                    subtitle: "Small sprints to spark focus and rebuild consistency",
                    icon: "bolt.fill",
                    accentColor: .dustyBlue,
                    tag: "Easy-Start",
                    colorScheme: colorScheme
                )
            }
            .buttonStyle(.plain)
            
            // Theme Week Programs Card
            Button {
                showThemeWeeks = true
            } label: {
                CuratedProgramCard(
                    title: "Theme Week Programs",
                    subtitle: "Gentle daily rhythm with micro-wins. One focus per day.",
                    icon: "moon.stars.fill",
                    accentColor: Color(hex: "C8B8DB"),
                    tag: "Gentle Rhythm",
                    colorScheme: colorScheme
                )
            }
            .buttonStyle(.plain)
            
            // The Vitality Arc
            Button {
                showVitalityProgram = true
            } label: {
                CuratedProgramCard(
                    title: "The Vitality Arc",
                    subtitle: "8-week scientific body recomposition. From mobility to strength.",
                    icon: "figure.mind.and.body",
                    accentColor: Color(hex: "D4B896"),
                    tag: "Body Journey",
                    colorScheme: colorScheme
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .alert("Clear Project 50 Habits?", isPresented: $showClearConfirmation) {
            Button("Delete All", role: .destructive) {
                clearProject50Habits()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove all Project 50 habits from your Desk. This action cannot be undone.")
        }
    }
}

//
// MARK: - Templates Grid
//
private extension HabitLibraryView {
    var templatesGridView: some View {
        LazyVStack(spacing: 12) {
            if filteredTemplates.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredTemplates) { template in
                    GlassmorphicHabitCard(
                        template: template,
                        isAdded: activeHabits.contains { $0.name == template.name },
                        colorScheme: colorScheme
                    ) {
                        selectedTemplate = template
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            
            Text("No habits found")
                .font(.headline)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Text("Try selecting a different category")
                .font(.subheadline)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No habits found. Try selecting a different category")
    }
}

//
// MARK: - Actions
//
private extension HabitLibraryView {
    
    /// Adds a habit from a template or reactivates an archived habit
    func addHabitFromTemplate(_ template: HabitTemplate) {
        // Check if already active
        guard !activeHabits.contains(where: { $0.name == template.name }) else {
            showAddSuccess = true
            ReverieHaptics.lightFeedback()
            return
        }
        
        // Check if archived - reactivate instead of creating new
        if let archivedHabit = archivedHabits.first(where: { $0.name == template.name }) {
            reactivateHabit(archivedHabit)
            return
        }
        
        // Create new habit
        createNewHabit(from: template)
    }
    
    /// Reactivates an archived habit
    private func reactivateHabit(_ habit: Habit) {
        do {
            habit.isArchived = false
            habit.archivedAt = nil
            try modelContext.save()
            
            selectedTemplate = nil
            showAddSuccess = true
            ReverieHaptics.successFeedback()
        } catch {
            errorMessage = "Failed to reactivate habit. Please try again."
            showError = true
            print("❌ Error reactivating habit: \(error.localizedDescription)")
        }
    }
    
    /// Creates a new habit from a template
    private func createNewHabit(from template: HabitTemplate) {
        do {
            let newHabit = Habit.fromLibraryTemplate(template, order: activeHabits.count)
            modelContext.insert(newHabit)
            try modelContext.save()
            
            selectedTemplate = nil
            showAddSuccess = true
            ReverieHaptics.successFeedback()
        } catch {
            errorMessage = "Failed to create habit. Please try again."
            showError = true
            print("❌ Error creating habit: \(error.localizedDescription)")
        }
    }
    
    /// Deletes all Project 50 habits
    func clearProject50Habits() {
        guard !isDeletingHabits else { return }
        isDeletingHabits = true
        
        Task { @MainActor in
            do {
                let p50Habits = activeHabits.filter { $0.programTag == "P50" }
                
                guard !p50Habits.isEmpty else {
                    isDeletingHabits = false
                    return
                }
                
                for habit in p50Habits {
                    habit.prepareForDeletion()
                    modelContext.delete(habit)
                }
                
                try modelContext.save()
                Project50ProgressManager.shared.resetJourney()
                
                ReverieHaptics.successFeedback()
                
                // Small delay for better UX
                try? await Task.sleep(nanoseconds: 300_000_000)
                isDeletingHabits = false
            } catch {
                errorMessage = "Failed to delete habits. Please try again."
                showError = true
                isDeletingHabits = false
                print("❌ Error deleting Project 50 habits: \(error.localizedDescription)")
            }
        }
    }
}

//
// MARK: - Curated Program Card
//
struct CuratedProgramCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let tag: String?
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.3),
                                accentColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 50, height: 50)
                    .blur(radius: 8)
                
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(accentColor.opacity(0.7), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accentColor.opacity(0.8))
            }
            .accessibilityHidden(true)
            
            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .lineLimit(1)
                    
                    if let tag = tag {
                        Text(tag.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(accentColor)
                            .cornerRadius(6)
                            .accessibilityLabel(tag)
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                .accessibilityHidden(true)
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to view program details")
    }
}

// MARK: - Category Chip
//
struct GlassmorphicCategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    var isFeatured: Bool = false
    let action: () -> Void
    
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(getLocalizedTitle())
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(
                isSelected
                    ? .white
                    : (colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.85))
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                isFeatured
                                    ? LinearGradient(
                                        colors: [Color.paleMauve, Color.terracottaRose],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [color, color.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .shadow(color: color.opacity(0.3), radius: 6, y: 2)
                    } else {
                        Capsule()
                            .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.adaptiveBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(getLocalizedTitle())
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to filter by \(getLocalizedTitle())")
    }
    
    private func getLocalizedTitle() -> String {
        if title == "All Categories" || title.contains("Categories") {
            return localization.localize("library.allCategories")
        }
        if title == "Curated" {
            return title
        }
        return localization.localize("category.\(title.replacingOccurrences(of: " ", with: ""))")
    }
}

// MARK: - Habit Card
//
struct GlassmorphicHabitCard: View {
    let template: HabitTemplate
    let isAdded: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    @StateObject private var localization = LocalizationManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: template.colorHex).opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(Color(hex: template.colorHex).opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: template.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(hex: template.colorHex))
                }
                .accessibilityHidden(true)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.system(size: 14, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(template.description)
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        // Category badge
                        HStack(spacing: 4) {
                            Image(systemName: template.category.icon)
                                .font(.system(size: 11))
                            
                            Text(localization.localize("category.\(template.category.rawValue.replacingOccurrences(of: " ", with: ""))"))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(template.category.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(template.category.color.opacity(colorScheme == .dark ? 0.15 : 0.12))
                        )
                        
                        Text("•")
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.4))
                            .font(.system(size: 11))
                        
                        Text(template.estimatedMinutes)
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                }
                
                Spacer()
                
                // Status icon
                if isAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.sageGreen)
                        .accessibilityLabel("Added")
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                        .accessibilityHidden(true)
                }
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isAdded ? Color.sageGreen.opacity(0.4) : Color.clear,
                        lineWidth: isAdded ? 1.5 : 0
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.name). \(template.description). \(template.category.rawValue). \(template.estimatedMinutes).")
        .accessibilityValue(isAdded ? "Added to desk" : "Not added")
        .accessibilityHint(isAdded ? "Already on your desk" : "Double tap to view details and add to desk")
    }
}
