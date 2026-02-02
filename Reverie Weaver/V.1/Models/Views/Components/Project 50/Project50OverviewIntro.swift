//
// Project50OverviewIntro.swift
// Reverie Weaver
//
// Created by Antheia Li on 10/23/25.
//

import SwiftUI
import SwiftData

// MARK: - Project 50 Overview Intro
struct Project50OverviewIntro: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var localization = LocalizationManager.shared
    
    @State private var showOverviewHabits = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroOrbSection
                        philosophicalQuote
                        includedHabitsSection
                        easyStartFeaturesSection
                        tipsSection
                        philosophySection
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 60)
                }
                            HStack {
                                Spacer()
                                closeButton
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
            }
            .overlay(alignment: .bottomTrailing) { startJourneyButton }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showOverviewHabits) {
                Project50OverviewHabits()
            }
        }
    }
}

private extension Project50OverviewIntro {
    
    // MARK: Hero Orb
    var heroOrbSection: some View {
        HybridEditorialChallengeHeader(
            icon: "sparkles",
            title: "Project 50",
            categoryLabel: "Starter Pack",
            subtitle: "8 Core Habits to Rebuild Momentum",
            accentColor: Color.paleMauve
        )
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    var philosophySection: some View {
        OpenEditorialSection(
            icon: "star.fill",
            iconColor: .paleMauve,
            title: localization.localize("project50.section.philosophyTitle"),
            content: localization.localize("project50.section.philosophyDesc")
        )
        .padding(.horizontal, 24)
    }

    var philosophicalQuote: some View {
        VStack(spacing: 12) {
            // Decorative divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                
                Image(systemName: "sparkle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.paleMauve.opacity(0.6))
                
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40)
            
            // The quote
            Text("Momentum isn't built in giant leaps — it's the compound effect of 50 small, deliberate days. Structure creates freedom.")
                .font(.custom("Georgia", size: 14))
                .fontWeight(.light)
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 32)
            
            // Attribution
            Text("— REVERIE WEAVER PHILOSOPHY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .opacity(0.6)
        }
        .padding(.vertical, 8)
    }

    var scienceSection: some View {
        OpenEditorialSection(
            icon: "brain.head.profile",
            iconColor: .dustyBlue,
            title: localization.localize("project50.section.scienceTitle"),
            content: localization.localize("project50.section.scienceDesc")
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Included Habits (8 habit preview cards, Unified Section Wrappers)
    
    var includedHabitsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("INCLUDED HABITS")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(.horizontal, 24)
            
            // 🌅 Morning Anchors
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.paleMauve.opacity(0.9))
                        Text("Morning Anchors")
                            .font(.system(size: 13, weight: .semibold))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    }
                    Text("Start before you think — create reliable morning cues that reduce friction and decision fatigue.")
                        .font(.system(size: 13))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .lineSpacing(3)
                }
                Divider().padding(.vertical, 2).opacity(0.2)
                
                VStack(spacing: 10) {
                    ForEach(morningHabits, id: \.name) { habit in
                        IncludedHabitPreviewCard(
                            name: habit.name,
                            icon: habit.icon,
                            description: habit.description,
                            category: habit.category,
                            estimatedTime: habit.estimatedTime,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
            .padding(18)
            .reverieCardStyle(colorScheme: colorScheme)
            .padding(.horizontal, 24)
            
            
            // 💪 Body & Energy
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.sageGreen.opacity(0.9))
                        Text("Body & Energy")
                            .font(.system(size: 13, weight: .semibold))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    }
                    Text("Movement and nourishment regulate dopamine, mood, and energy — the foundation of focus.")
                        .font(.system(size: 13))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .lineSpacing(3)
                }
                Divider().padding(.vertical, 2).opacity(0.2)
                
                VStack(spacing: 10) {
                    ForEach(bodyEnergyHabits, id: \.name) { habit in
                        IncludedHabitPreviewCard(
                            name: habit.name,
                            icon: habit.icon,
                            description: habit.description,
                            category: habit.category,
                            estimatedTime: habit.estimatedTime,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
            .padding(18)
            .reverieCardStyle(colorScheme: colorScheme)
            .padding(.horizontal, 24)
            
            
            // 🧠 Cognitive Anchors
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.dustyBlue.opacity(0.9))
                        Text("Cognitive Anchors")
                            .font(.system(size: 13, weight: .semibold))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    }
                    Text("Feed your mind, not the noise — learn and focus through intentional attention.")
                        .font(.system(size: 13))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .lineSpacing(3)
                }
                Divider().padding(.vertical, 2).opacity(0.2)
                
                VStack(spacing: 10) {
                    ForEach(cognitiveHabits, id: \.name) { habit in
                        IncludedHabitPreviewCard(
                            name: habit.name,
                            icon: habit.icon,
                            description: habit.description,
                            category: habit.category,
                            estimatedTime: habit.estimatedTime,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
            .padding(18)
            .reverieCardStyle(colorScheme: colorScheme)
            .padding(.horizontal, 24)
            
            
            // 🌙 Reflection
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.terracottaRose.opacity(0.9))
                        Text("Reflection")
                            .font(.system(size: 13, weight: .semibold))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    }
                    Text("End the day on purpose — externalize thoughts, calm the mind, and reinforce self-awareness.")
                        .font(.system(size: 13))
                         .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .lineSpacing(3)
                }
                Divider().padding(.vertical, 2).opacity(0.2)
                
                VStack(spacing: 10) {
                    ForEach(reflectionHabits, id: \.name) { habit in
                        IncludedHabitPreviewCard(
                            name: habit.name,
                            icon: habit.icon,
                            description: habit.description,
                            category: habit.category,
                            estimatedTime: habit.estimatedTime,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
            .padding(18)
            .reverieCardStyle(colorScheme: colorScheme)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: Easy-Start Design Features
    var easyStartFeaturesSection: some View {
        SectionCard(
            icon: "checkmark.seal.fill",
            iconColor: .terracottaRose,
            title: "Easy-Start Design",
            content: nil,
            rows: [
                ("arrow.down.circle.fill", localization.localize("project50.feature.lowActivation")),
                ("arrow.triangle.branch", localization.localize("project50.feature.multiplePaths")),
                ("clock.fill", localization.localize("project50.feature.flexibleTime")),
                ("chart.line.uptrend.xyaxis", localization.localize("project50.feature.progressTracking")),
                ("heart.fill", localization.localize("project50.feature.encouragement"))
                          ]
        )
    }
    
    // MARK: Tips
    var tipsSection: some View {
        SectionCard(
            icon: "lightbulb.fill",
            iconColor: .dustyBlue,
            title: localization.localize("project50.section.tipsTitle"),
            content: nil,
            rows: [
                ("calendar", localization.localize("project50.tip.blockTime")),
                ("brain.head.profile", localization.localize("project50.tip.reflect")),
                ("flame.fill", localization.localize("project50.tip.momentum")),
                ("leaf.fill", localization.localize("project50.tip.pairRoutines"))
                            ]
        )
    }
    
    // MARK: Close Button
    var closeButton: some View {
        GlassCloseButton {
            dismiss()
        }
    }
    
    // MARK: Start Journey Button
    var startJourneyButton: some View {
        Button {
            showOverviewHabits = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                Text(localization.localize("project50.button.start"))
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: "9B7EBD"), Color(hex: "B89CC6")],
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
    }
    
    // MARK: - Preview Habits Data (8 habits)
    var previewHabits: [(name: String, icon: String, description: String, category: String, estimatedTime: String)] {
        [
            (
                name: "Rise with Intention",
                icon: "sunrise.fill",
                description: "Choose YOUR consistent wake time - not a rigid hour. Even 15 minutes earlier counts as progress.",
                category: "Morning Rituals",
                estimatedTime: "Discipline Builder"
            ),
            (
                name: "Morning Anchor Ritual",
                icon: "figure.mind.and.body",
                description: "Pick 1-3 actions: make bed (2 min win!), 5-min journal, stretch, or plan your day. Start with 10 minutes.",
                category: "Morning Rituals",
                estimatedTime: "10-30 min"
            ),
            (
                name: "Move Your Body",
                icon: "figure.walk",
                description: "20 min minimum, aim for 1 hour. Walk, dance, yoga, gym, cycling - whatever you'll actually do.",
                category: "Health Foundations",
                estimatedTime: "20-60 min"
            ),
            (
                name: "Hydration Habit",
                icon: "drop.fill",
                description: "Drink 6-8 glasses throughout the day. Keep water visible. Hydration is a foundation win.",
                category: "Health Foundations",
                estimatedTime: "Throughout day"
            ),
            (
                name: "Feed Your Mind (10 Pages)",
                icon: "book.fill",
                description: "Read 10 pages daily. Prefer non-fiction or growth books. Audiobooks count!",
                category: "Creative Practice",
                estimatedTime: "10-15 min"
            ),
            (
                name: "Deep Work Hour",
                icon: "lightbulb.fill",
                description: "1 hour on a skill or goal: language, coding, journaling, studying, building. Pomodoro-friendly.",
                category: "Creative Practice",
                estimatedTime: "60 min (flexible)"
            ),
            (
                name: "Eat with Intention",
                icon: "carrot.fill",
                description: "Not a strict diet - just intentional eating. Avoid ultra-processed foods today. Progress over perfection.",
                category: "Health Foundations",
                estimatedTime: "Ongoing mindset"
            ),
            (
                name: "Evening Brain Dump",
                icon: "moon.stars",
                description: "Reflect in 3+ sentences. What worked? What's next? Builds self-awareness and gratitude.",
                category: "Mindful Living",
                estimatedTime: "5-10 min"
            )
        ]
    }
    // MARK: - Grouped Preview Habit Lists
    var morningHabits: [(name: String, icon: String, description: String, category: String, estimatedTime: String)] {
        previewHabits.filter { ["Rise with Intention", "Morning Anchor Ritual", "Hydration Habit"].contains($0.name) }
    }

    var bodyEnergyHabits: [(name: String, icon: String, description: String, category: String, estimatedTime: String)] {
        previewHabits.filter { ["Move Your Body", "Eat with Intention"].contains($0.name) }
    }

    var cognitiveHabits: [(name: String, icon: String, description: String, category: String, estimatedTime: String)] {
        previewHabits.filter { ["Feed Your Mind (10 Pages)", "Deep Work Hour"].contains($0.name) }
    }

    var reflectionHabits: [(name: String, icon: String, description: String, category: String, estimatedTime: String)] {
        previewHabits.filter { ["Evening Brain Dump"].contains($0.name) }
    }
}


// MARK: - Lightweight Habit Preview Card
private struct IncludedHabitPreviewCard: View {
    let name: String
    let icon: String
    let description: String
    let category: String
    let estimatedTime: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .strokeBorder(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                         .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    HStack(spacing: 8) {
                        Label(category, systemImage: "tag.fill")
                            .font(.system(size: 11, weight: .medium))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        Text("•")
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                        Text(estimatedTime)
                            .font(.system(size: 11, weight: .medium))
                             .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                }
                Spacer()
            }
            
            Text(description)
                .font(.system(size: 12, weight: .regular))
                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    private var categoryColor: Color {
        switch category {
        case "Morning Rituals": return Color(hex: "FFCAB3")
        case "Health Foundations": return Color(hex: "8FBC8F")
        case "Creative Practice": return Color(hex: "FFCFA0")
        case "Mindful Living": return Color(hex: "9B7EBD")
        default: return Color.paleMauve
        }
    }
}

// MARK: - SectionCard Component
//
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
                    .font(.system(size: 13))
                     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineSpacing(4)
            }
            
            if let rows = rows {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rows, id: \.0) { row in
                        HStack(spacing: 8) {
                            Image(systemName: row.0)
                                .font(.system(size: 13))
                                .foregroundStyle(iconColor.opacity(0.85))
                            Text(row.1)
                                .font(.system(size: 13))
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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
