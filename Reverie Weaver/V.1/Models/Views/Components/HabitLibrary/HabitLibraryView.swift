//
// HabitLibraryView.swift
// Reverie Weaver
//
// Updated with tagging system and new Mini Challenges flow
//

import SwiftUI
import SwiftData

struct HabitLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query private var habits: [Habit]
    
    @StateObject private var localization = LocalizationManager.shared
    @State private var selectedCategory: String?
    @State private var selectedTemplate: HabitTemplate?
    @State private var showAddSuccess = false
    
    @State private var showProject50Overview = false
    @State private var showProject50Levels = false
    @State private var showMiniChallenges = false
    
    @State private var showClearConfirmation = false
    
    // MARK: - Filtered Templates
    var filteredTemplates: [HabitTemplate] {
        if selectedCategory == "curated" {
            return []
        } else if let categoryString = selectedCategory,
                  let category = HabitCategory(rawValue: categoryString) {
            return HabitLibraryData.templates(for: category)
        }
        return HabitLibraryData.templates
    }
    
    // MARK: - Check if Project 50 has started
    private var hasStartedProject50: Bool {
        habits.contains { $0.programTag == "P50" }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                
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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
            // Sheets
            .sheet(item: $selectedTemplate) { template in
                HabitTemplateDetailView(template: template) {
                    addHabitFromTemplate(template)
                }
            }
            .sheet(isPresented: $showProject50Overview) {
                Project50OverviewIntro()
            }
            .sheet(isPresented: $showMiniChallenges) {
                MiniChallengesOverviewIntro()
            }
            .alert(localization.localize("library.habitAdded"), isPresented: $showAddSuccess) {
                Button(localization.localize("profile.ok")) { }
            } message: {
                Text(localization.localize("library.habitAddedDesc"))
            }
            .navigationDestination(isPresented: $showProject50Levels) {
                Project50LevelsView()
            }
        }
    }
}

//
// MARK: - Header
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
        .padding(.top, 8)
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.shadowColor, radius: 4, y: 2)
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.dynamicSecondaryLabel)
            }
        }
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
                ) { selectedCategory = "curated" }
                
                GlassmorphicCategoryChip(
                    title: localization.localize("library.allCategories"),
                    icon: "square.grid.2x2",
                    color: .sageGreen,
                    isSelected: selectedCategory == nil
                ) { selectedCategory = nil }
                
                ForEach(HabitCategory.allCases, id: \.self) { category in
                    GlassmorphicCategoryChip(
                        title: localization.localize("category.\(category.rawValue.replacingOccurrences(of: " ", with: ""))"),
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category.rawValue
                    ) { selectedCategory = category.rawValue }
                }
            }
            .padding(.horizontal, 24)
        }
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
            
            // Manage Levels / Clear Buttons (only show if started)
            if hasStartedProject50 {
                VStack(spacing: 10) {
                    Button {
                        showProject50Levels = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 11))
                            Text("Manage Levels / View Progress")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, alignment: .center) // 👈 centers content horizontally
                    }
                    .buttonStyle(.plain)
                    
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Clear Project 50 Habits")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .center) // 👈 centers content horizontally
                    }
                    .buttonStyle(.plain)
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
                    tag: "ADHD-Friendly",
                    colorScheme: colorScheme
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .alert("Clear Project 50 Habits?", isPresented: $showClearConfirmation) {
            Button("Delete All", role: .destructive) { clearProject50Habits() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all Project 50 habits from your Desk.")
        }
    }
}

// MARK: - Templates Grid
//
private extension HabitLibraryView {
    var templatesGridView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredTemplates) { template in
                GlassmorphicHabitCard(
                    template: template,
                    isAdded: habits.contains { $0.name == template.name },
                    colorScheme: colorScheme
                ) { selectedTemplate = template }
            }
        }
        .padding(.horizontal, 24)
    }
}

//
// MARK: - Actions
//
private extension HabitLibraryView {
    func addHabitFromTemplate(_ template: HabitTemplate) {
        let newHabit = Habit(
            name: template.name,
            description: template.description,
            category: template.category.rawValue,
            categoryIcon: template.category.icon,
            icon: template.icon,
            colorHex: template.colorHex,
            order: habits.count,
            programTag: nil, // Personal habit, no program tag
            programLevel: nil
        )
        modelContext.insert(newHabit)
        try? modelContext.save()
        selectedTemplate = nil
        showAddSuccess = true
        ReverieHaptics.successFeedback()
    }
    
    func clearProject50Habits() {
        // Delete all habits with programTag == "P50"
        let p50Habits = habits.filter { $0.programTag == "P50" }
        
        for habit in p50Habits {
            modelContext.delete(habit)
        }
        
        try? modelContext.save()
        Project50ProgressManager.shared.resetJourney()
        ReverieHaptics.successFeedback()
    }
}

//
// MARK: - Curated Card
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
            
            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .fontDesign(.serif)
                        .adaptivePrimaryText(colorScheme: colorScheme)
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
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }
}

// MARK: - Category Chip
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
                    .font(.system(size: 11, weight: .medium))
                
                Text(getLocalizedTitle())
                    .font(.system(size: 12, weight: .medium))
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
                            .shadow(color: Color.shadowColor.opacity(0.1), radius: 3, y: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
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
                                .font(.system(size: 8))
                            
                            Text(localization.localize("category.\(template.category.rawValue.replacingOccurrences(of: " ", with: ""))"))
                                .font(.system(size: 9, weight: .medium))
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
                            .font(.system(size: 10))
                        
                        Text(template.estimatedMinutes)
                            .font(.system(size: 10, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                }
                
                Spacer()
                
                // Status icon
                if isAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.sageGreen)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
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
    }
}
