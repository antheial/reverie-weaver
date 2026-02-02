//
//  Project50Habit.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/23/25.
//


//
// Project50Data.swift
// ReverieWeaver
//
// Redesigned Oct 2025
//
// Defines all curated Project 50 program data (3 levels)
// NEW: True 3-level progression system
// Level 1: Foundation (6 habits, 60-90 min/day)
// Level 2: Focus (6 habits, 120-150 min/day)
// Level 3: Depth (6 habits, 180-240 min/day)
//

import SwiftUI

// MARK: - Core Habit Model for Curated Programs
struct Project50Habit: Identifiable, Codable {
    var id: UUID = UUID()
    let name: String
    let description: String
    let icon: String
    let colorHex: String
    let category: String

    let program: String
    let level: Int?
    let tag: String?
    let durationDays: Int?

    /// If true, this habit is optional for daily/challenge completion tracking.
    /// Optional habits won't be added to DeskView and won't affect completion rates.
    /// Use for milestone habits like "Week 1 Progress Check-In" that should only be done once.
    var isOptionalForCompletion: Bool = false
}

// MARK: - Project 50 Category (5 core categories)
struct Project50Category: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let description: String
    let icon: String
    let accentColor: String
    let levels: [Int: [Project50Habit]]
}

// MARK: - PROJECT 50 MAIN PROGRAM (3 Levels, 6 habits each)
struct Project50Data {
    
    static let categories: [Project50Category] = [
        // 🌅 1. Morning Rituals
        Project50Category(
            title: "Morning Rituals",
            description: "Start your day with intention and consistency.",
            icon: "sunrise.fill",
            accentColor: "FFCAB3",
            levels: [
                1: [
                    Project50Habit(
                        name: "Consistent Wake Time",
                        description: "Wake at YOUR chosen time - even 15 min earlier counts. Build the anchor of your day.",
                        icon: "sunrise.fill",
                        colorHex: "FFCAB3",
                        category: "Morning Rituals",
                        program: "project50",
                        level: 1,
                        tag: nil,
                        durationDays: nil
                    ),
                    Project50Habit(
                        name: "Morning Reset (5 min)",
                        description: "Pick 1-2 actions: make bed, splash face, stretch, open curtains. Start simple.",
                        icon: "figure.mind.and.body",
                        colorHex: "E0C6EC",
                        category: "Morning Rituals",
                        program: "project50",
                        level: 1,
                        tag: nil,
                        durationDays: nil
                    )
                ],
                2: [
                    Project50Habit(
                        name: "Phone-Free Morning (30 min)",
                        description: "No screens for first 30 minutes after waking. Let your brain boot naturally.",
                        icon: "brain.head.profile",
                        colorHex: "D9ECFF",
                        category: "Morning Rituals",
                        program: "project50",
                        level: 2,
                        tag: nil,
                        durationDays: nil
                    )
                ],
                3: [
                    Project50Habit(
                        name: "Mindful Morning Ritual",
                        description: "Full 30-min morning sequence: wake → breathe → journal intention → move → plan day.",
                        icon: "sparkles",
                        colorHex: "FFD8E1",
                        category: "Morning Rituals",
                        program: "project50",
                        level: 3,
                        tag: nil,
                        durationDays: nil
                    )
                ]
            ]
        ),
        
        // ❤️ 2. Health Foundations
        Project50Category(
            title: "Health Foundations",
            description: "Build energy and strength for mental clarity.",
            icon: "heart.fill",
            accentColor: "FF6B9D",
            levels: [
                1: [
                    Project50Habit(
                        name: "Move Your Body",
                        description: "20 min walk minimum. No gym needed. Consistency over intensity.",
                        icon: "figure.walk",
                        colorHex: "8FBC8F",
                        category: "Health Foundations",
                        program: "project50",
                        level: 1,
                        tag: nil,
                        durationDays: nil
                    ),
                    Project50Habit(
                        name: "Hydration Check-In",
                        description: "Drink 1 glass first thing. Keep water visible throughout day.",
                        icon: "drop.fill",
                        colorHex: "A5C9F3",
                        category: "Health Foundations",
                        program: "project50",
                        level: 1,
                        tag: nil,
                        durationDays: nil
                    )
                ],
                2: [
                    Project50Habit(
                        name: "Purposeful Movement",
                        description: "30-45 min intentional exercise. Track how your body feels, not just reps.",
                        icon: "figure.run",
                        colorHex: "98D98E",
                        category: "Health Foundations",
                        program: "project50",
                        level: 2,
                        tag: nil,
                        durationDays: nil
                    ),
                    Project50Habit(
                        name: "Nourish with Awareness",
                        description: "Prepare 1 whole-food meal. Notice colors, textures, satisfaction.",
                        icon: "fork.knife",
                        colorHex: "8FBC8F",
                        category: "Health Foundations",
                        program: "project50",
                        level: 2,
                        tag: nil,
                        durationDays: nil
                    )
                ],
                3: [
                    Project50Habit(
                        name: "Body-Mind Awareness",
                        description: "45-60 min movement with mental check-ins. Yoga, running meditation, or mindful lifting.",
                        icon: "figure.cooldown",
                        colorHex: "A5C9F3",
                        category: "Health Foundations",
                        program: "project50",
                        level: 3,
                        tag: nil,
                        durationDays: nil
                    )
                ]
            ]
        ),
        
        // ✍️ 3. Creative Practice
        Project50Category(
            title: "Creative Practice",
            description: "Nurture your creative flow and expression.",
            icon: "pencil.and.outline",
            accentColor: "FFCFA0",
            levels: [
                1: [
                    Project50Habit(
                        name: "10-Page Reading",
                        description: "Read 10 pages of anything meaningful. Audiobooks count.",
                        icon: "book.fill",
                        colorHex: "FFCFA0",
                        category: "Creative Practice",
                        program: "project50",
                        level: 1,
                        tag: nil,
                        durationDays: nil
                    )
                ],
                2: [
                    Project50Habit(
                        name: "Deep Work Block (1 hour)",
                        description: "60 min focused work on a skill or goal. Pomodoro-friendly: 4×15 min.",
                        icon: "lightbulb.fill",
                        colorHex: "FFE09D",
                        category: "Creative Practice",
                        program: "project50",
                        level: 2,
                        tag: nil,
                        durationDays: nil
                    )
                ],
                3: [
                    Project50Habit(
                        name: "Creative Flow Session",
                        description: "90 min deep work on your craft. Writing, coding, art, learning. Enter flow state.",
                        icon: "paintbrush.pointed.fill",
                        colorHex: "FFD18B",
                        category: "Creative Practice",
                        program: "project50",
                        level: 3,
                        tag: nil,
                        durationDays: nil
                    )
                ]
            ]
        ),
        
        // 💬 4. Connection
        Project50Category(
            title: "Connection",
            description: "Strengthen your bonds and meaningful interactions.",
            icon: "heart.text.square.fill",
            accentColor: "FF9AA2",
            levels: [
                1: [],
                2: [],
                3: [
                    Project50Habit(
                        name: "Meaningful Connection",
                        description: "One tech-free, present conversation. Call a friend. Really listen.",
                        icon: "person.2.fill",
                        colorHex: "FFCFB3",
                        category: "Connection",
                        program: "project50",
                        level: 3,
                        tag: nil,
                        durationDays: nil
                    )
                ]
            ]
        ),
        
        // 🍃 5. Mindful Living
        Project50Category(
            title: "Mindful Living",
            description: "Slow down, breathe, and notice the present moment.",
            icon: "leaf.fill",
            accentColor: "9B7EBD",
            levels: [
                1: [
                    Project50Habit(
                        name: "Evening Wind-Down",
                        description: "Write 1-3 sentences about your day. Keep it messy and real.",
                        icon: "moon.stars",
                        colorHex: "9B7EBD",
                        category: "Mindful Living",
                        program: "project50",
                        level: 1,
                        tag: nil,
                        durationDays: nil
                    )
                ],
                2: [
                    Project50Habit(
                        name: "Breathing Practice",
                        description: "5 minutes of intentional breathing. Box breathing, 4-7-8, or just slow.",
                        icon: "lungs.fill",
                        colorHex: "CBA8FF",
                        category: "Mindful Living",
                        program: "project50",
                        level: 2,
                        tag: nil,
                        durationDays: nil
                    ),
                    Project50Habit(
                        name: "Evening Reflection",
                        description: "Journal 5+ sentences. What worked? What didn't? What's next?",
                        icon: "book.closed.fill",
                        colorHex: "E8C6FF",
                        category: "Mindful Living",
                        program: "project50",
                        level: 2,
                        tag: nil,
                        durationDays: nil
                    )
                ],
                3: [
                    Project50Habit(
                        name: "Digital Sunset",
                        description: "No screens 1 hour before bed. Read, reflect, stretch, or sit in silence.",
                        icon: "sunset.fill",
                        colorHex: "E8927C",
                        category: "Mindful Living",
                        program: "project50",
                        level: 3,
                        tag: nil,
                        durationDays: nil
                    ),
                    Project50Habit(
                        name: "Gratitude & Vision",
                        description: "Evening practice: 3 gratitudes + visualize tomorrow's best self.",
                        icon: "heart.text.square.fill",
                        colorHex: "F9CED8",
                        category: "Mindful Living",
                        program: "project50",
                        level: 3,
                        tag: nil,
                        durationDays: nil
                    )
                ]
            ]
        )
    ]
}

// MARK: - Convenience Helpers
extension Project50Data {
    static func allLevelOneHabits() -> [Project50Habit] {
        categories.flatMap { category in
            category.levels[1] ?? []
        }
    }
}
