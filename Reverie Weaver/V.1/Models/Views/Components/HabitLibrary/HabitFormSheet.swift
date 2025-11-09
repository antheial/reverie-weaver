//
// HabitFormSheet.swift
// ReverieWeaver
//
// Unified sheet for creating and editing habits
// Updated with SF Symbols and matching categories

import SwiftUI
import SwiftData

struct HabitFormSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.order) private var habits: [Habit]
    @StateObject private var localization = LocalizationManager.shared
    
    // Optional habit for edit mode
    let habitToEdit: Habit?
    
    @State private var name = ""
    @State private var description = ""
    @State private var completionMessage = ""
    @State private var category = "Morning Rituals"
    @State private var icon = "sunrise.fill"
    @State private var colorHex = "C9D2B5"
    @State private var frequency = "Daily"
    
    // ✅ CRITICAL: Store program tracking as immutable
    // These should NEVER be modified during edit - they're set by the program
    @State private var programTag: String?
    @State private var programLevel: Int?
    
    // Computed property to determine mode
    private var isEditMode: Bool {
        habitToEdit != nil
    }
    
    // UPDATED: Categories matching HabitLibrary
    private var categories: [(String, String, String)] {
        [
            ("Morning Rituals", "sunrise.fill", "category.MorningRituals"),
            ("Health Foundations", "heart.fill", "category.HealthFoundations"),
            ("Mindful Living", "leaf.fill", "category.MindfulLiving"),
            ("Creative Practice", "paintbrush.fill", "category.CreativePractice"),
            ("Connection", "person.2.fill", "category.Connection")
        ]
    }
    
    // UPDATED: SF Symbol icons instead of emojis
    private let icons = [
        ("sunrise.fill", "Sunrise"),
        ("figure.mind.and.body", "Meditation"),
        ("drop.fill", "Water"),
        ("figure.walk", "Walking"),
        ("dumbbell", "Exercise"),
        ("book.fill", "Book"),
        ("carrot.fill", "Food"),
        ("moon.stars", "Night"),
        ("bed.double.fill", "Bed"),
        ("lightbulb.fill", "Idea"),
        ("leaf.fill", "Nature"),
        ("heart.fill", "Health"),
        ("sparkles", "Magic"),
        ("paintbrush.fill", "Creative")
    ]
    
    private let colors = [
        ("Sage Green", "C9D2B5"),
        ("Dusty Blue", "B8C7D6"),
        ("Terracotta Rose", "D9A58A"),
        ("Pale Mauve", "E6D7D2")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header prompt - changes based on mode
                    Text(isEditMode ? "Refine the thread in your tapestry" : "What will you weave into your daily tapestry?")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .italic()
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // ✅ Program Habit Badge (shows when editing program habits)
                    if isEditMode, let tag = programTag {
                        programHabitBadge(tag: tag, level: programLevel)
                    }
                    
                    // Habit Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.name"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        TextField(localization.localize("habit.namePlaceholder"), text: $name)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.45))
                                    .shadow(color: Color.shadowColor, radius: 6, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            Text(localization.localize("habit.description"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        TextField(localization.localize("habit.descPlaceholder"), text: $description, axis: .vertical)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.45))
                                    .shadow(color: Color.shadowColor, radius: 6, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .lineLimit(3...5)
                    }
                    
                    // Completion Message
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            Text(localization.localize("habit.completionMessage"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        TextField(localization.localize("habit.messagePlaceholder"), text: $completionMessage, axis: .vertical)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.45))
                                    .shadow(color: Color.shadowColor, radius: 6, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .lineLimit(2...4)
                    }
                    
                    // Category Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.category"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(categories, id: \.0) { cat in
                                Button {
                                    category = cat.0
                                } label: {
                                    HStack(spacing: 12) {
                                        // SF Symbol icon instead of emoji
                                        Image(systemName: cat.1)
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color(hex: colorHex))
                                        
                                        Text(localization.localize(cat.2))
                                            .font(.system(size: 12, weight: .medium))
                                            .fontDesign(.serif)
                                            .foregroundStyle(Color.dynamicLabel)
                                        
                                        Spacer()
                                        
                                        if category == cat.0 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color(hex: colorHex))
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(category == cat.0 ? Color(hex: colorHex).opacity(0.1) : Color.white.opacity(0.3))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                category == cat.0 ? Color(hex: colorHex) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Icon Selector - UPDATED with SF Symbols
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.icon"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(icons, id: \.0) { iconPair in
                                Button {
                                    icon = iconPair.0
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: iconPair.0)
                                            .font(.system(size: 24))
                                            .foregroundStyle(Color(hex: colorHex))
                                        
                                        Text(iconPair.1)
                                            .font(.system(size: 8, weight: .regular))
                                            .foregroundStyle(Color.dynamicSecondaryLabel)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(icon == iconPair.0 ? Color(hex: colorHex).opacity(0.1) : Color.white.opacity(0.3))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                icon == iconPair.0 ? Color(hex: colorHex) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Color Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.threadColor"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.1) { color in
                                Button {
                                    colorHex = color.1
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: color.1))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(
                                                        colorHex == color.1 ? Color.dynamicLabel : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                            .shadow(color: Color.shadowColor, radius: 2, y: 1)
                                        
                                        if colorHex == color.1 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color(hex: color.1))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Frequency Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            Text(localization.localize("habit.frequency"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        HStack(spacing: 10) {
                            ForEach([("Daily", "habit.daily"), ("Weekly", "habit.weekly")], id: \.0) { freq in
                                Button {
                                    frequency = freq.0
                                } label: {
                                    Text(localization.localize(freq.1))
                                        .font(.system(size: 12, weight: .medium))
                                        .fontDesign(.serif)
                                        .foregroundStyle(frequency == freq.0 ? Color.white : Color.dynamicLabel)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(frequency == freq.0 ? Color(hex: colorHex) : Color.white.opacity(0.3))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(24)
                .dismissKeyboardOnBackgroundTap()
            }
            .background(ReverieWeaverBackground())
            .navigationTitle(isEditMode ? "Edit Habit" : localization.localize("habit.create"))
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDismissToolbar()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditMode ? "Edit Habit" : localization.localize("habit.create"))
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localize("habit.cancel")) {
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .regular))
                    .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Save" : localization.localize("habit.create.button")) {
                        saveHabit()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .fontDesign(.serif)
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.fraction(0.8)])
        .presentationDragIndicator(.visible)
        .onAppear {
            loadHabitData()
        }
    }
    
    // MARK: - Helper Functions
    
    // ✅ Program Habit Badge
    @ViewBuilder
    private func programHabitBadge(tag: String, level: Int?) -> some View {
        VStack(spacing: 8) {
            // Badge
            HStack(spacing: 8) {
                Image(systemName: programIcon(for: tag))
                    .font(.system(size: 12))
                    .foregroundStyle(programColor(for: tag))
                
                Text(programDisplayName(for: tag, level: level))
                    .font(.system(size: 12, weight: .medium))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicLabel)
                
                Spacer()
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(programColor(for: tag).opacity(0.1))
                    .shadow(color: Color.shadowColor.opacity(0.1), radius: 3, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(programColor(for: tag).opacity(0.3), lineWidth: 1)
            )
            
            // Info note
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dustyBlue)
                
                Text("This habit is part of a program. You can edit its details, but it will remain tracked in the challenge.")
                    .font(.system(size: 10, weight: .regular))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dustyBlue.opacity(0.08))
            )
        }
    }
    
    // Helper functions for program badge
    private func programIcon(for tag: String) -> String {
        if tag == "P50" {
            return "chart.line.uptrend.xyaxis"
        } else if tag.starts(with: "C7-") {
            return "bolt.fill"
        } else {
            return "star.fill"
        }
    }
    
    private func programColor(for tag: String) -> Color {
        if tag == "P50" {
            return Color(hex: "B8C7D6") // dustyBlue
        } else if tag.starts(with: "C7-") {
            return Color(hex: "D9A58A") // terracottaRose
        } else {
            return Color(hex: "C9D2B5") // sageGreen
        }
    }
    
    private func programDisplayName(for tag: String, level: Int?) -> String {
        if tag == "P50" {
            if let level = level {
                return "Project 50 - Level \(level)"
            }
            return "Project 50"
        } else if tag.starts(with: "C7-") {
            let challengeName = String(tag.dropFirst(3))
            return "Challenge: \(challengeName)"
        } else {
            return "Program Habit"
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadHabitData() {
        guard let habit = habitToEdit else { return }
        
        name = habit.name
        description = habit.habitDescription
        completionMessage = habit.completionMessage
        category = habit.category
        icon = habit.icon // Already SF Symbol name
        colorHex = habit.colorHex
        frequency = habit.frequency.capitalized
        
        // ✅ CRITICAL: Load program tracking data (immutable)
        programTag = habit.programTag
        programLevel = habit.programLevel
    }
    
    private func saveHabit() {
        let categoryData = categories.first { $0.0 == category }
        let categoryIcon = categoryData?.1 ?? "sunrise.fill" // SF Symbol
        
        if let habit = habitToEdit {
            // Edit mode - update existing habit
            habit.name = name
            habit.habitDescription = description
            habit.completionMessage = completionMessage
            habit.category = category
            habit.categoryIcon = categoryIcon
            habit.icon = icon // SF Symbol name
            habit.colorHex = colorHex
            habit.frequency = frequency.lowercased()
            
            // ✅ CRITICAL: programTag and programLevel are NEVER modified
            // They remain exactly as they were when the habit was created
            // This ensures program tracking continues to work correctly
            
            // Verify they weren't accidentally changed
            if habit.programTag != programTag {
                print("⚠️ WARNING: programTag mismatch detected!")
            }
            if habit.programLevel != programLevel {
                print("⚠️ WARNING: programLevel mismatch detected!")
            }
            
            print("✅ Habit edited: \(habit.name)")
            if let tag = habit.programTag {
                print("   programTag: \(tag)")
                if let level = habit.programLevel {
                    print("   programLevel: \(level)")
                }
            }
        } else {
            // Create mode - insert new habit
            let newHabit = Habit(
                name: name,
                description: description,
                category: category,
                categoryIcon: categoryIcon,
                icon: icon, // SF Symbol name
                colorHex: colorHex,
                completionMessage: completionMessage.isEmpty ? "Thread woven - you've honored your commitment." : completionMessage,
                frequency: frequency.lowercased(),
                order: habits.count
            )
            
            modelContext.insert(newHabit)
            print("✅ Habit created: \(newHabit.name)")
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        dismiss()
    }
}

// MARK: - Convenience Initializers
extension HabitFormSheet {
    // For creating new habit
    init() {
        self.habitToEdit = nil
    }
    
    // For editing existing habit
    init(habit: Habit) {
        self.habitToEdit = habit
    }
}

#Preview {
    HabitFormSheet()
        .modelContainer(for: [Habit.self])
}
