//
//  ThemeWeekHabitCreator.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/16/25.
//
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Habit Extension for Theme Week Integration

extension Habit {
    
    var isThemeWeek: Bool {
        programTag?.starts(with: "TW-") ?? false
    }
    
    var themeWeekTag: String? {
        guard let tag = programTag, tag.starts(with: "TW-") else { return nil }
        return String(tag.dropFirst(3))
    }
}

// MARK: - Theme Week Habit Creation Helper

struct ThemeWeekHabitCreator {
    
    static func createHabit(
        from themeWeekHabit: ThemeWeekHabit,
        programTag: String,
        context: ModelContext
    ) -> Habit {
        let tag = "TW-\(programTag)"
        do {
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.programTag == tag && $0.isArchived == false }
            )
            if let results = try? context.fetch(descriptor), let existing = results.first {
                #if DEBUG
                print("ℹ️ [TW] Reusing existing Theme Week habit for tag=\(tag)")
                #endif
                return existing
            }
        }

        let habit = Habit(
            name: themeWeekHabit.name,
            description: themeWeekHabit.description,
            category: "Theme Week",
            categoryIcon: "moon.stars.fill",
            icon: themeWeekHabit.icon,
            colorHex: themeWeekHabit.colorHex,
            completionMessage: themeWeekHabit.completionMessage,
            frequency: "daily",
            order: 0,
            programTag: tag,
            programLevel: nil,
            scheduledDays: nil
        )

        context.insert(habit)
        return habit
    }
    
    static func createAllHabits(
        for program: ThemeWeekProgram,
        context: ModelContext
    ) -> [Habit] {
        program.allHabits.map { themeWeekHabit in
            createHabit(from: themeWeekHabit, programTag: program.tag, context: context)
        }
    }
}

// MARK: - Theme Week Statistics

struct ThemeWeekStats {
    let totalPrograms: Int
    let completedPrograms: Int
    let activePrograms: Int
    let totalDaysCompleted: Int
    let seedCount: Int
    let sproutCount: Int
    let bloomCount: Int
    
    var completionRate: Double {
        guard totalPrograms > 0 else { return 0 }
        return Double(completedPrograms) / Double(totalPrograms)
    }
    
    var dominantTier: CompletionTier? {
        let counts = [
            (CompletionTier.seed, seedCount),
            (CompletionTier.sprout, sproutCount),
            (CompletionTier.bloom, bloomCount)
        ]
        return counts.max(by: { $0.1 < $1.1 })?.0
    }
    
    var adaptationStyle: String {
        if let dominant = dominantTier {
            switch dominant {
            case .seed:
                return "Wise Adapter - You listen to your limits"
            case .sprout:
                return "Steady Grower - You maintain consistent rhythm"
            case .bloom:
                return "Full Bloomer - You thrive with structure"
            }
        }
        return "Just Beginning"
    }
    
    static func calculate(from progressArray: [ThemeWeekProgress]) -> ThemeWeekStats {
        ThemeWeekStats(
            totalPrograms: progressArray.count,
            completedPrograms: progressArray.filter { $0.isCompleted }.count,
            activePrograms: progressArray.filter { !$0.isCompleted && !$0.isPaused && !$0.isArchived }.count,
            totalDaysCompleted: progressArray.reduce(0) { $0 + $1.daysCompleted },
            seedCount: progressArray.reduce(0) { $0 + $1.seedCount },
            sproutCount: progressArray.reduce(0) { $0 + $1.sproutCount },
            bloomCount: progressArray.reduce(0) { $0 + $1.bloomCount }
        )
    }
}

// MARK: - Badge System for Theme Weeks

struct ThemeWeekBadge: Identifiable, Hashable {
    let id: String
    let title: String
    let emoji: String
    let description: String
    let requirement: BadgeRequirement
    
    enum BadgeRequirement {
        case completeAnyProgram
        case completeThreePrograms
        case completeAllSeed
        case completeAllBloom
        case completeSevenDaysInARow
        case useAllThreeTiers
    }
    
    static let allBadges: [ThemeWeekBadge] = [
        ThemeWeekBadge(
            id: "first-week",
            title: "First Theme Week",
            emoji: "🌱",
            description: "Completed your first Theme Week program",
            requirement: .completeAnyProgram
        ),
        ThemeWeekBadge(
            id: "wise-adapter",
            title: "Wise Adapter",
            emoji: "🌱",
            description: "Completed 7 days using Seed tier",
            requirement: .completeAllSeed
        ),
        ThemeWeekBadge(
            id: "full-bloomer",
            title: "Full Bloomer",
            emoji: "🌳",
            description: "Completed 7 days using Bloom tier",
            requirement: .completeAllBloom
        ),
        ThemeWeekBadge(
            id: "flexible-warrior",
            title: "Flexible Warrior",
            emoji: "✨",
            description: "Used all three tiers in one week",
            requirement: .useAllThreeTiers
        ),
        ThemeWeekBadge(
            id: "dedicated-weaver",
            title: "Dedicated Weaver",
            emoji: "🎯",
            description: "Completed three Theme Week programs",
            requirement: .completeThreePrograms
        )
    ]
    
    func isEarned(progress: [ThemeWeekProgress]) -> Bool {
        switch requirement {
        case .completeAnyProgram:
            return progress.contains { $0.isCompleted }
            
        case .completeThreePrograms:
            return progress.filter { $0.isCompleted }.count >= 3
            
        case .completeAllSeed:
            return progress.contains { prog in
                prog.isCompleted && prog.seedCount == 7
            }
            
        case .completeAllBloom:
            return progress.contains { prog in
                prog.isCompleted && prog.bloomCount == 7
            }
            
        case .completeSevenDaysInARow:
            // Check for consecutive completions
            return progress.contains { prog in
                prog.isCompleted && prog.daysCompleted == 7
            }
            
        case .useAllThreeTiers:
            return progress.contains { prog in
                prog.seedCount > 0 && prog.sproutCount > 0 && prog.bloomCount > 0
            }
        }
    }
}

// MARK: - Theme Week Notifications (Optional)

struct ThemeWeekNotificationHelper {
    
    static func dailyReminder(for progress: ThemeWeekProgress, program: ThemeWeekProgram) -> String {
        let day = progress.currentDayNumber
        let theme = program.theme(for: day)
        
        let reminders = [
            "Today's focus: \(theme?.themeName ?? "Reflection"). Show up however you can.",
            "Day \(day) of your Theme Week. Any tier counts as success.",
            "\(theme?.themeName ?? "Today"): Remember, Seed tier is always valid.",
            "Gentle reminder: Your Theme Week continues. One habit, three ways to win."
        ]
        
        return reminders.randomElement() ?? reminders[0]
    }
    
    static func completionCelebration(tier: CompletionTier, dayNumber: Int) -> String {
        switch tier {
        case .seed:
            return "You showed up on Day \(dayNumber). That's wisdom, not failure."
        case .sprout:
            return "Day \(dayNumber) complete! Steady and sustainable."
        case .bloom:
            return "Day \(dayNumber) bloomed! You're thriving today."
        }
    }
}

// MARK: - Color Helper for Theme Weeks

extension Color {
    
    static func themeWeekAccent(colorScheme: ColorScheme, baseHex: String) -> Color {
        let baseColor = Color(hex: baseHex)
        
        if colorScheme == .dark {
            return baseColor.opacity(0.9)
        } else {
            let hour = Calendar.current.component(.hour, from: Date())
            
            switch hour {
            case 5..<7, 19..<21:
                return baseColor.opacity(0.95)
            case 12..<15:
                return baseColor.opacity(0.85)
            default:
                return baseColor.opacity(0.9)
            }
        }
    }
}

// MARK: - Theme Week Archive View Helper

struct ThemeWeekArchiveEntry: Identifiable {
    let id: UUID
    let programTitle: String
    let programTag: String
    let programIcon: String
    let programColor: String
    let completedDate: Date
    let daysCompleted: Int
    let seedCount: Int
    let sproutCount: Int
    let bloomCount: Int
    let weekBadge: String?
    
    static func from(progress: ThemeWeekProgress) -> ThemeWeekArchiveEntry? {
        guard progress.isCompleted else { return nil }
        
        return ThemeWeekArchiveEntry(
            id: progress.id,
            programTitle: progress.programTitle,
            programTag: progress.programTag,
            programIcon: "moon.stars.fill",
            programColor: "C8B8DB",
            completedDate: progress.completedDate ?? Date(),
            daysCompleted: progress.daysCompleted,
            seedCount: progress.seedCount,
            sproutCount: progress.sproutCount,
            bloomCount: progress.bloomCount,
            weekBadge: progress.weekBadge
        )
    }
}

extension Habit {
    
    var isVitality: Bool {
        programTag?.starts(with: "VA-") ?? false
    }
    
    var vitalityProgramID: String? {
        guard let tag = programTag, tag.starts(with: "VA-") else { return nil }
        return String(tag.dropFirst(3))
    }
}
