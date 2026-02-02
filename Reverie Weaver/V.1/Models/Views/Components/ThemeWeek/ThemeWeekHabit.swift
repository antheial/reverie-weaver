//
//  ThemeWeekHabit.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/16/25.
//
// Created November 2025
// Theme Week Programs: Gentle daily rhythm with micro-wins system
// Perfect for overwhelmed users, fast-thinking minds, procrastinators, burnout recovery
//
// Structure:
// - 7 days, one theme per day
// - 1-2 habits per day (gentle load)
// - Each habit has 3 tiers: Seed 🌱 / Sprout 🌿 / Bloom 🌳
// - User chooses commitment level (pre or post completion)
//

import SwiftUI

// MARK: - Core Theme Week Models

/// A single habit within a Theme Week with built-in micro-wins tiers
struct ThemeWeekHabit: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let name: String
    let icon: String
    let colorHex: String
    
    // Micro-Wins System: 3 tiers of completion
    let seedTier: String      // 🌱 Minimum viable action (10-20% effort)
    let sproutTier: String    // 🌿 Intended goal (50-60% effort)
    let bloomTier: String     // 🌳 Above and beyond (100%+ effort)
    
    let dayNumber: Int
    let tag: String
    
    var description: String {
        "Day \(dayNumber) Theme Week habit with three ways to win"
    }
    
    var completionMessage: String {
        "Great job showing up today! 🌟"
    }
}

/// Daily theme with focus area and habits
struct DayTheme: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let dayNumber: Int
    let themeName: String
    let themeIcon: String
    let tagline: String
    let colorHex: String
    let habits: [ThemeWeekHabit]
}

struct ThemeWeekProgram: Identifiable, Codable, Hashable {
    var id: String
    let title: String
    let subtitle: String
    let description: String
    let tag: String
    let colorHex: String
    let icon: String
    
    let dailyThemes: [DayTheme]
    
    let keyFeatures: [String]
    let tips: [String]
}

// MARK: - Theme Week Data Repository

struct ThemeWeekData {
    
    static let programs: [ThemeWeekProgram] = [
        gentleRhythmWeek,
        focusMasteryWeek,
        burnoutRecoveryWeek,
        digitalDetoxWeek,
        slowDownWeek,
        connectionClarityWeek
    ]
    
    // MARK: - 1. GENTLE RHYTHM WEEK 🌙
    
    static let gentleRhythmWeek = ThemeWeekProgram(
        id: "gentle-rhythm-w1",
        title: "Gentle Rhythm Week",
        subtitle: "One focus per day. Show up however you can.",
        description: "A week of single daily focuses with three ways to win. Perfect for when everything feels like too much. Each day has a theme. Each habit has three tiers. No pressure—just presence.",
        tag: "GentleRhythmW1",
        colorHex: "C8B8DB",
        icon: "moon.stars.fill",
        dailyThemes: [
            // DAY 1: MONDAY - MOVEMENT
            DayTheme(
                dayNumber: 1,
                themeName: "Movement",
                themeIcon: "figure.walk",
                tagline: "Move your body, clear your mind",
                colorHex: "B8D4C8",  // Soft sage
                habits: [
                    ThemeWeekHabit(
                        name: "Morning Movement",
                        icon: "figure.walk",
                        colorHex: "B8D4C8",
                        seedTier: "5-minute stretch in bed",
                        sproutTier: "15-minute walk outside",
                        bloomTier: "30+ minutes intentional exercise",
                        dayNumber: 1,
                        tag: "GentleRhythmW1"
                    )
                ]
            ),
            
            // DAY 2: TUESDAY - MENTAL CLARITY
            DayTheme(
                dayNumber: 2,
                themeName: "Mental Clarity",
                themeIcon: "brain.head.profile",
                tagline: "Quiet the noise, find your center",
                colorHex: "9BB5CE",  // Twilight blue
                habits: [
                    ThemeWeekHabit(
                        name: "Brain Dump",
                        icon: "square.and.pencil",
                        colorHex: "9BB5CE",
                        seedTier: "Write 3 worry sentences",
                        sproutTier: "10-minute brain dump session",
                        bloomTier: "Full mind map + prioritization",
                        dayNumber: 2,
                        tag: "GentleRhythmW1"
                    )
                ]
            ),
            
            // DAY 3: WEDNESDAY - CREATIVE PRACTICE
            DayTheme(
                dayNumber: 3,
                themeName: "Creative Practice",
                themeIcon: "paintbrush.fill",
                tagline: "Express yourself, no pressure",
                colorHex: "E8B4B8",  // Soft rose
                habits: [
                    ThemeWeekHabit(
                        name: "Morning Pages",
                        icon: "book.pages.fill",
                        colorHex: "E8B4B8",
                        seedTier: "Write 3 sentences",
                        sproutTier: "Write 1 page (10 min)",
                        bloomTier: "Write 3 pages (30 min)",
                        dayNumber: 3,
                        tag: "GentleRhythmW1"
                    )
                ]
            ),
            
            // DAY 4: THURSDAY - DEEP WORK
            DayTheme(
                dayNumber: 4,
                themeName: "Focus",
                themeIcon: "target",
                tagline: "One thing, your full attention",
                colorHex: "A5C9F3",  // Clear sky blue
                habits: [
                    ThemeWeekHabit(
                        name: "Focus Block",
                        icon: "timer",
                        colorHex: "A5C9F3",
                        seedTier: "15 minutes focused work",
                        sproutTier: "45 minutes deep work",
                        bloomTier: "90+ minutes flow state",
                        dayNumber: 4,
                        tag: "GentleRhythmW1"
                    )
                ]
            ),
            
            // DAY 5: FRIDAY - CONNECTION
            DayTheme(
                dayNumber: 5,
                themeName: "Connection",
                themeIcon: "heart.text.square.fill",
                tagline: "Reach out, even quietly",
                colorHex: "FFB8A0",  // Warm peach
                habits: [
                    ThemeWeekHabit(
                        name: "Gentle Outreach",
                        icon: "message.fill",
                        colorHex: "FFB8A0",
                        seedTier: "Like one post or reply to a text",
                        sproutTier: "Send a thoughtful message",
                        bloomTier: "Have a real conversation",
                        dayNumber: 5,
                        tag: "GentleRhythmW1"
                    )
                ]
            ),
            
            // DAY 6: SATURDAY - FOUNDATIONS
            DayTheme(
                dayNumber: 6,
                themeName: "Foundations",
                themeIcon: "house.fill",
                tagline: "Tend to the basics with care",
                colorHex: "D4C5A9",  // Warm cream
                habits: [
                    ThemeWeekHabit(
                        name: "Reset One Space",
                        icon: "sparkles",
                        colorHex: "D4C5A9",
                        seedTier: "Clear one surface (desk/table)",
                        sproutTier: "Tidy one room for 20 minutes",
                        bloomTier: "Deep clean or organize a space",
                        dayNumber: 6,
                        tag: "GentleRhythmW1"
                    )
                ]
            ),
            
            // DAY 7: SUNDAY - REST & REFLECTION
            DayTheme(
                dayNumber: 7,
                themeName: "Rest & Reflection",
                themeIcon: "leaf.fill",
                tagline: "Look back gently, rest deeply",
                colorHex: "E8D4F3",  // Pale lavender
                habits: [
                    ThemeWeekHabit(
                        name: "Weekly Reflection",
                        icon: "moon.stars.fill",
                        colorHex: "E8D4F3",
                        seedTier: "Name one win from this week",
                        sproutTier: "Write 5-minute reflection on what worked",
                        bloomTier: "Full review: Which tier felt right? Which themes energized you? What will you carry forward? Note 3 gratitudes.",
                        dayNumber: 7,
                        tag: "GentleRhythmW1"
                    )
                ]
            )
        ],
        keyFeatures: [
            "Only 1 habit per day (zero overwhelm)",
            "3 tiers = always a way to win",
            "Daily themes reduce decision fatigue",
            "Rescue mode built into Seed tier"
        ],
        tips: [
            "Start with Sprout tier as your default",
            "Seed tier isn't failure—it's wisdom",
            "Bloom days feel amazing but aren't required",
            "Complete all 7 days at any tier = success"
        ]
    )
    
    // MARK: - 2. FOCUS MASTERY WEEK 🧠
    
    static let focusMasteryWeek = ThemeWeekProgram(
        id: "focus-mastery-w1",
        title: "Focus Mastery Week",
        subtitle: "Work with your brain, not against it",
        description: "Seven days of strategies for fast-thinking, novelty-seeking minds. Whether you relate to these challenges occasionally or daily, these are practical accommodations for how your brain actually works. Each day targets a different focus challenge with compassion, not criticism.",
        tag: "FocusMasteryW1",
        colorHex: "8B9DC3",  // Calm steel blue
        icon: "brain.head.profile",
        dailyThemes: [
            // DAY 1: MOTIVATION DESIGN
            DayTheme(
                dayNumber: 1,
                themeName: "Motivation Design",
                themeIcon: "sparkles",
                tagline: "Make routine tasks more engaging",
                colorHex: "FFD5C2",  // Soft coral
                habits: [
                    ThemeWeekHabit(
                        name: "Task Pairing",
                        icon: "link",
                        colorHex: "FFD5C2",
                        seedTier: "Play music during one routine task",
                        sproutTier: "Pair 3 tasks with enjoyable elements",
                        bloomTier: "Design a full menu of task-and-reward pairings for your day",
                        dayNumber: 1,
                        tag: "FocusMasteryW1"
                    )
                ]
            ),
            
            // DAY 2: TIME BLINDNESS
            DayTheme(
                dayNumber: 2,
                themeName: "Time Visibility",
                themeIcon: "timer",
                tagline: "Make time tangible instead of theoretical",
                colorHex: "A5C9F3",  // Sky blue
                habits: [
                    ThemeWeekHabit(
                        name: "Visual Timers",
                        icon: "hourglass",
                        colorHex: "A5C9F3",
                        seedTier: "Set one timer for today",
                        sproutTier: "Use visual timer for 3 tasks",
                        bloomTier: "Time-block whole day with visual cues",
                        dayNumber: 2,
                        tag: "FocusMasteryW1"
                    )
                ]
            ),
            
            // DAY 3: BODY DOUBLING
            DayTheme(
                dayNumber: 3,
                themeName: "Parallel Presence",
                themeIcon: "person.2.fill",
                tagline: "Borrow motivation from existing near people",
                colorHex: "D4C5E8",  // Soft purple
                habits: [
                    ThemeWeekHabit(
                        name: "Work Together Silently",
                        icon: "laptopcomputer.and.phone",
                        colorHex: "D4C5E8",
                        seedTier: "Work near someone for 15 minutes",
                        sproutTier: "Join virtual body-doubling session",
                        bloomTier: "Co-work for 2+ hours (silent or social)",
                        dayNumber: 3,
                        tag: "FocusMasteryW1"
                    )
                ]
            ),
            
            // DAY 4: NOVELTY ROTATION
            DayTheme(
                dayNumber: 4,
                themeName: "Strategic Novelty",
                themeIcon: "arrow.triangle.2.circlepath",
                tagline: "Feed the novelty monster intentionally",
                colorHex: "FFB8A0",  // Warm peach
                habits: [
                    ThemeWeekHabit(
                        name: "Novelty Budget",
                        icon: "gift.fill",
                        colorHex: "FFB8A0",
                        seedTier: "Try one new thing (song, route, snack)",
                        sproutTier: "Rotate 3 small novelties today",
                        bloomTier: "Design weekly novelty menu",
                        dayNumber: 4,
                        tag: "FocusMasteryW1"
                    )
                ]
            ),
            
            // DAY 5: ENERGY CONSERVATION
            DayTheme(
                dayNumber: 5,
                themeName: "Energy Wisdom",
                themeIcon: "bolt.fill",
                tagline: "Protect your limited executive function",
                colorHex: "E8D4A8",  // Soft gold
                habits: [
                    ThemeWeekHabit(
                        name: "Decision Batching",
                        icon: "checklist",
                        colorHex: "E8D4A8",
                        seedTier: "Pre-decide one thing (outfit/meal)",
                        sproutTier: "Batch 3 recurring decisions",
                        bloomTier: "Create decision-free morning routine",
                        dayNumber: 5,
                        tag: "FocusMasteryW1"
                    )
                ]
            ),
            
            // DAY 6: CHAOS CONTAINMENT
            DayTheme(
                dayNumber: 6,
                themeName: "Organized Chaos",
                themeIcon: "square.stack.3d.up.fill",
                tagline: "Contain the mess, don't eliminate it",
                colorHex: "B8D4C8",  // Sage green
                habits: [
                    ThemeWeekHabit(
                        name: "Chaos Zones",
                        icon: "tray.full.fill",
                        colorHex: "B8D4C8",
                        seedTier: "Designate one 'mess allowed' zone",
                        sproutTier: "Create 3 chaos containers",
                        bloomTier: "Design full organized-chaos system",
                        dayNumber: 6,
                        tag: "FocusMasteryW1"
                    )
                ]
            ),
            
            // DAY 7: SELF-COMPASSION
            DayTheme(
                dayNumber: 7,
                themeName: "Radical Acceptance",
                themeIcon: "heart.fill",
                tagline: "Your brain has its own rhythm—honor it",
                colorHex: "FFD8E1",  // Soft pink
                habits: [
                    ThemeWeekHabit(
                        name: "Brain Reframe",
                        icon: "text.quote",
                        colorHex: "FFD8E1",
                        seedTier: "Notice one strength of your thinking style today",
                        sproutTier: "Write 3 kind truths about how your mind works",
                        bloomTier: "Full self-compassion reflection: What makes your mind unique? How can you work with it, not against it?",
                        dayNumber: 7,
                        tag: "FocusMasteryW1"
                    )
                ]
            )
        ],
        keyFeatures: [
            "Targets actual executive function challenges",
            "Built around brain science for fast thinkers",
            "Celebrates flexible thinking strategies",
            "Zero shame, maximum compassion"
        ],
        tips: [
            "These are practical tools, not quick fixes",
            "What works Monday might not work Tuesday—adjust as needed",
            "Seed tier shows self-awareness about your capacity",
            "Completing this week means you're building self-understanding"
        ]
    )
    
    // MARK: - 3. BURNOUT RECOVERY WEEK 🕊️
    
    static let burnoutRecoveryWeek = ThemeWeekProgram(
        id: "burnout-recovery-w1",
        title: "Burnout Recovery Week",
        subtitle: "Permission to do less. Space to recover.",
        description: "A week of intentional rest and gentle restoration for periods of exhaustion. Every tier is designed for low-energy days—if Seed level is all you can do, that IS success. This program offers supportive wellness practices. For persistent exhaustion, sleep issues, or emotional distress, please consult a healthcare provider.",
        tag: "BurnoutRecoveryW1",
        colorHex: "D4C5E8",  // Soft lavender
        icon: "leaf.fill",
        dailyThemes: [
            // DAY 1: PERMISSION TO REST
            DayTheme(
                dayNumber: 1,
                themeName: "Rest Permission",
                themeIcon: "bed.double.fill",
                tagline: "Doing nothing is doing something",
                colorHex: "E8E4F3",  // Pale moonlight
                habits: [
                    ThemeWeekHabit(
                        name: "Intentional Rest",
                        icon: "powersleep",
                        colorHex: "E8E4F3",
                        seedTier: "Lie down for 10 minutes guilt-free",
                        sproutTier: "Take a full 30-minute rest break",
                        bloomTier: "Full afternoon of restorative rest",
                        dayNumber: 1,
                        tag: "BurnoutRecoveryW1"
                    )
                ]
            ),
            
            // DAY 2: NOURISHMENT
            DayTheme(
                dayNumber: 2,
                themeName: "Gentle Nourishment",
                themeIcon: "cup.and.saucer.fill",
                tagline: "Feed yourself with tenderness",
                colorHex: "FFE5D4",  // Warm cream
                habits: [
                    ThemeWeekHabit(
                        name: "Nourishing Meal",
                        icon: "fork.knife",
                        colorHex: "FFE5D4",
                        seedTier: "Eat one warm, comforting thing",
                        sproutTier: "Prepare one nourishing meal mindfully",
                        bloomTier: "Cook with care, eat without rushing",
                        dayNumber: 2,
                        tag: "BurnoutRecoveryW1"
                    )
                ]
            ),
            
            // DAY 3: BOUNDARY PRACTICE
            DayTheme(
                dayNumber: 3,
                themeName: "Soft Boundaries",
                themeIcon: "shield.fill",
                tagline: "Protect your recovering energy",
                colorHex: "C8D8E8",  // Soft sky
                habits: [
                    ThemeWeekHabit(
                        name: "Say No",
                        icon: "hand.raised.fill",
                        colorHex: "C8D8E8",
                        seedTier: "Decline one optional thing",
                        sproutTier: "Set 3 gentle boundaries today",
                        bloomTier: "Communicate needs clearly all day",
                        dayNumber: 3,
                        tag: "BurnoutRecoveryW1"
                    )
                ]
            ),
            
            // DAY 4: JOY SEEKING
            DayTheme(
                dayNumber: 4,
                themeName: "Small Delights",
                themeIcon: "sparkles",
                tagline: "Notice what feels good",
                colorHex: "FFD8E1",  // Soft pink
                habits: [
                    ThemeWeekHabit(
                        name: "Pleasure Practice",
                        icon: "heart.fill",
                        colorHex: "FFD8E1",
                        seedTier: "Notice one small pleasant thing",
                        sproutTier: "Seek out 3 tiny joys intentionally",
                        bloomTier: "Design a day around small delights",
                        dayNumber: 4,
                        tag: "BurnoutRecoveryW1"
                    )
                ]
            ),
            
            // DAY 5: MOVEMENT (GENTLE)
            DayTheme(
                dayNumber: 5,
                themeName: "Tender Movement",
                themeIcon: "figure.cooldown",
                tagline: "Move in ways that feel kind",
                colorHex: "B8D4C8",  // Soft sage
                habits: [
                    ThemeWeekHabit(
                        name: "Restorative Movement",
                        icon: "figure.walk",
                        colorHex: "B8D4C8",
                        seedTier: "Stretch for 2 minutes in bed",
                        sproutTier: "Gentle 10-minute walk or yoga",
                        bloomTier: "30 minutes of movement that feels good",
                        dayNumber: 5,
                        tag: "BurnoutRecoveryW1"
                    )
                ]
            ),
            
            // DAY 6: CREATIVE PLAY
            DayTheme(
                dayNumber: 6,
                themeName: "Playful Expression",
                themeIcon: "paintbrush.fill",
                tagline: "Create without purpose or judgment",
                colorHex: "E8C4D8",  // Dusty rose
                habits: [
                    ThemeWeekHabit(
                        name: "Purposeless Creativity",
                        icon: "scribble.variable",
                        colorHex: "E8C4D8",
                        seedTier: "Doodle for 3 minutes",
                        sproutTier: "Make something for 15 minutes (any medium)",
                        bloomTier: "Lose yourself in creative flow",
                        dayNumber: 6,
                        tag: "BurnoutRecoveryW1"
                    )
                ]
            ),
            
            // DAY 7: INTEGRATION
            DayTheme(
                dayNumber: 7,
                themeName: "Gentle Integration",
                themeIcon: "moon.stars.fill",
                tagline: "Honor what you learned this week",
                colorHex: "D4C5E8",  // Soft lavender
                habits: [
                    ThemeWeekHabit(
                        name: "Recovery Reflection",
                        icon: "book.pages.fill",
                        colorHex: "D4C5E8",
                        seedTier: "Notice one thing that helped",
                        sproutTier: "Write 5-minute reflection on recovery",
                        bloomTier: "Full review + plan for ongoing rest",
                        dayNumber: 7,
                        tag: "BurnoutRecoveryW1"
                    )
                ]
            )
        ],
        keyFeatures: [
            "Every tier designed for low energy",
            "Seed tier = the actual goal when burned out",
            "Permission to rest is the primary objective",
            "No productivity pressure whatsoever"
        ],
        tips: [
            "Completing Seed level all 7 days is a full success",
            "Recovery is about restoration, not achievement",
            "Rest supports your body's natural renewal process",
            "This week is about sustainable self-care practices"
        ]
    )
    
    static let digitalDetoxWeek = ThemeWeekProgram(
        id: "digital-detox-w1",
        title: "Digital Minimalism",
        subtitle: "Reclaim your attention, bit by bit.",
        description: "A gentle reset for your relationship with screens. This isn't about eliminating technology—it's about creating intentional space. Small changes in your digital habits can help you feel more present and less scattered.",
        tag: "DigitalDetoxW1",
        colorHex: "8FC1B5",  // Muted teal
        icon: "iphone.slash",
        dailyThemes: [
            DayTheme(
                dayNumber: 1,
                themeName: "Morning Air",
                themeIcon: "sun.haze.fill",
                tagline: "Start the day input-free",
                colorHex: "F2D0A9",
                habits: [
                    ThemeWeekHabit(
                        name: "Phone-Free Morning",
                        icon: "sunrise.fill",
                        colorHex: "F2D0A9",
                        seedTier: "Don't touch phone for first 5 mins",
                        sproutTier: "No phone until after coffee/water (30 mins)",
                        bloomTier: "No screens for first hour of day",
                        dayNumber: 1,
                        tag: "DigitalDetoxW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 2,
                themeName: "Notification Noise",
                themeIcon: "bell.slash.fill",
                tagline: "Silence the interruptions",
                colorHex: "99C1B9",
                habits: [
                    ThemeWeekHabit(
                        name: "Quiet Mode",
                        icon: "bell.slash",
                        colorHex: "99C1B9",
                        seedTier: "Turn off 1 annoying app notification",
                        sproutTier: "Set Do Not Disturb for 2 hours",
                        bloomTier: "Audit and disable 50% of all notifications",
                        dayNumber: 2,
                        tag: "DigitalDetoxW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 3,
                themeName: "Mealtime Presence",
                themeIcon: "fork.knife",
                tagline: "Just eat. Just taste.",
                colorHex: "D8E2DC",
                habits: [
                    ThemeWeekHabit(
                        name: "Analog Dining",
                        icon: "fork.knife.circle.fill",
                        colorHex: "D8E2DC",
                        seedTier: "Put phone screen-down during dinner",
                        sproutTier: "Leave phone in other room for one meal",
                        bloomTier: "All meals screen-free today",
                        dayNumber: 3,
                        tag: "DigitalDetoxW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 4,
                themeName: "Single Tasking",
                themeIcon: "rectangle.on.rectangle.slash",
                tagline: "One screen at a time",
                colorHex: "8E9AAF",
                habits: [
                    ThemeWeekHabit(
                        name: "Mono-Tasking",
                        icon: "eye.fill",
                        colorHex: "8E9AAF",
                        seedTier: "Close unused browser tabs",
                        sproutTier: "Watch TV without looking at phone",
                        bloomTier: "Work for 1 hour with only 1 app open",
                        dayNumber: 4,
                        tag: "DigitalDetoxW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 5,
                themeName: "Bedroom Sanctuary",
                themeIcon: "bed.double.fill",
                tagline: "Keep the blue light out",
                colorHex: "CBC0D3",
                habits: [
                    ThemeWeekHabit(
                        name: "Phone Bedtime",
                        icon: "powersleep",
                        colorHex: "CBC0D3",
                        seedTier: "Put phone away 5 mins before sleep",
                        sproutTier: "Phone charges across the room",
                        bloomTier: "Phone stays outside the bedroom all night",
                        dayNumber: 5,
                        tag: "DigitalDetoxW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 6,
                themeName: "Analog Joy",
                themeIcon: "book.fill",
                tagline: "Hands on something real",
                colorHex: "E6CCB2",
                habits: [
                    ThemeWeekHabit(
                        name: "Real World Activity",
                        icon: "hand.raised.fill",
                        colorHex: "E6CCB2",
                        seedTier: "5 minutes of paper reading/writing",
                        sproutTier: "30 minutes of a non-screen hobby",
                        bloomTier: "Leave house without phone for a walk",
                        dayNumber: 6,
                        tag: "DigitalDetoxW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 7,
                themeName: "The Unfollow",
                themeIcon: "scissors",
                tagline: "Curate your feed",
                colorHex: "F4ACB7",
                habits: [
                    ThemeWeekHabit(
                        name: "Feed Gardening",
                        icon: "leaf.arrow.triangle.circlepath",
                        colorHex: "F4ACB7",
                        seedTier: "Mute/Unfollow 1 account that stresses you",
                        sproutTier: "Clear 5 accounts that don't spark joy",
                        bloomTier: "Delete one social app for the day",
                        dayNumber: 7,
                        tag: "DigitalDetoxW1"
                    )
                ]
            )
        ],
        keyFeatures: [
            "Helps break repetitive scrolling patterns",
            "Creates visual cues for mindful phone use",
            "Uses gentle friction to encourage intentional choices",
            "Gradual approach—no extreme changes required"
        ],
        tips: [
            "The goal is awareness, not perfection",
            "Seed tier creates meaningful change over time",
            "When you notice the urge to scroll, pause and breathe",
            "If you slip into old habits, notice what triggered it and try again—that's progress, not failure"
        ]
    )
    
    static let slowDownWeek = ThemeWeekProgram(
        id: "slow-down-w1",
        title: "The Slow Down",
        subtitle: "Unhook from urgency.",
        description: "Modern life demands speed, but a slower pace can feel more grounding. This week invites you to do normal things at 80% speed—not doing less, just not rushing. Note: Slowing down may feel uncomfortable at first. This is normal as you adjust to a calmer rhythm.",
        tag: "SlowDownW1",
        colorHex: "99A98F",  // Olive sage
        icon: "tortoise.fill",
        dailyThemes: [
            DayTheme(
                dayNumber: 1,
                themeName: "Savoring",
                themeIcon: "cup.and.saucer.fill",
                tagline: "Taste your life",
                colorHex: "D6E4C3",
                habits: [
                    ThemeWeekHabit(
                        name: "Morning Sip",
                        icon: "mug.fill",
                        colorHex: "D6E4C3",
                        seedTier: "Take 3 conscious sips of coffee/tea",
                        sproutTier: "Drink entire cup without scrolling",
                        bloomTier: "Sit outside doing nothing while sipping",
                        dayNumber: 1,
                        tag: "SlowDownW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 2,
                themeName: "Transition",
                themeIcon: "arrow.right.circle",
                tagline: "Space between tasks",
                colorHex: "C9DBB2",
                habits: [
                    ThemeWeekHabit(
                        name: "The Pause",
                        icon: "pause.circle",
                        colorHex: "C9DBB2",
                        seedTier: "Take 1 breath before starting work",
                        sproutTier: "Sit for 1 min between meetings/tasks",
                        bloomTier: "5 min buffer block after every activity",
                        dayNumber: 2,
                        tag: "SlowDownW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 3,
                themeName: "Walking",
                themeIcon: "figure.walk",
                tagline: "Amble, don't power walk",
                colorHex: "E3F2C1",
                habits: [
                    ThemeWeekHabit(
                        name: "Slow Stroll",
                        icon: "shoe.fill",
                        colorHex: "E3F2C1",
                        seedTier: "Walk slowly to the mailbox/car",
                        sproutTier: "10 min walk with no destination",
                        bloomTier: "Phone-free nature walk, stopping often",
                        dayNumber: 3,
                        tag: "SlowDownW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 4,
                themeName: "Listening",
                themeIcon: "ear",
                tagline: "Listen to understand, not to reply",
                colorHex: "AAC8A7",
                habits: [
                    ThemeWeekHabit(
                        name: "Deep Listening",
                        icon: "person.2.wave.2",
                        colorHex: "AAC8A7",
                        seedTier: "Wait 1 second before replying",
                        sproutTier: "Ask one 'tell me more' question",
                        bloomTier: "10 min conversation with zero phone",
                        dayNumber: 4,
                        tag: "SlowDownW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 5,
                themeName: "Single Task",
                themeIcon: "1.circle",
                tagline: "One thing is enough",
                colorHex: "F6FFDE",
                habits: [
                    ThemeWeekHabit(
                        name: "Mono-Focus",
                        icon: "target",
                        colorHex: "F6FFDE",
                        seedTier: "Wash dishes without a podcast",
                        sproutTier: "Drive in silence (no radio)",
                        bloomTier: "Eat lunch away from desk/screens",
                        dayNumber: 5,
                        tag: "SlowDownW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 6,
                themeName: "Gazing",
                themeIcon: "eye",
                tagline: "Look up and out",
                colorHex: "C4D7B2",
                habits: [
                    ThemeWeekHabit(
                        name: "Sky Gazing",
                        icon: "cloud.fill",
                        colorHex: "C4D7B2",
                        seedTier: "Look at the sky for 10 seconds",
                        sproutTier: "Watch a sunset or sunrise",
                        bloomTier: "Cloud watch for 15 minutes",
                        dayNumber: 6,
                        tag: "SlowDownW1"
                    )
                ]
            ),
            DayTheme(
                dayNumber: 7,
                themeName: "Stillness",
                themeIcon: "circle.circle",
                tagline: "Stop the motion",
                colorHex: "E1ECC8",
                habits: [
                    ThemeWeekHabit(
                        name: "Doing Nothing",
                        icon: "chair.lounge.fill",
                        colorHex: "E1ECC8",
                        seedTier: "Sit still for 1 minute",
                        sproutTier: "5 minutes of doing absolutely nothing",
                        bloomTier: "20 min restorative yoga or nap",
                        dayNumber: 7,
                        tag: "SlowDownW1"
                    )
                ]
            )
        ],
        keyFeatures: [
            "Helps counter the habit of rushing",
            "Supports feeling more grounded and calm",
            "Reduces overstimulation from constant input",
            "Focuses on sensory experience and presence"
        ],
        tips: [
            "If slowing down feels uncomfortable, that's a sign it's working",
            "When you notice yourself rushing, simply pause and breathe",
            "Seed tier is about awareness—noticing is the first step",
            "A calmer pace often leads to clearer thinking"
        ]
    )
    
    // MARK: - 6. CONNECTION CLARITY WEEK 🗣️
    
    static let connectionClarityWeek = ThemeWeekProgram(
        id: "connection-clarity-w1",
        title: "Connection Clarity Week",
        subtitle: "Find your voice, navigate relationships with confidence.",
        description: "A week for developing communication skills and relationship awareness. Practice conversation patterns, assertiveness, and healthy boundary-setting. Each day includes journal prompts to track your growth. This program offers practical communication tools for personal development.",
        tag: "ConnectionClarityW1",
        colorHex: "9DB4C8",  // Soft slate blue
        icon: "bubble.left.and.bubble.right.fill",
        dailyThemes: [
            // DAY 1: SELF-AWARENESS
            DayTheme(
                dayNumber: 1,
                themeName: "Communication Patterns",
                themeIcon: "person.crop.circle.badge.questionmark",
                tagline: "Understand how you communicate under stress",
                colorHex: "C8D5E8",  // Pale blue
                habits: [
                    ThemeWeekHabit(
                        name: "Pattern Recognition",
                        icon: "chart.line.uptrend.xyaxis",
                        colorHex: "C8D5E8",
                        seedTier: "Notice one moment today when you struggled to speak up",
                        sproutTier: "Identify your default response (freeze, people-please, avoid, or overshare)",
                        bloomTier: "Journal about where this pattern came from and when it happens most",
                        dayNumber: 1,
                        tag: "ConnectionClarityW1"
                    )
                ]
            ),
            
            // DAY 2: ACTIVE LISTENING
            DayTheme(
                dayNumber: 2,
                themeName: "Deep Listening",
                themeIcon: "ear.fill",
                tagline: "Take pressure off yourself by truly hearing others",
                colorHex: "B8D8E8",  // Sky blue
                habits: [
                    ThemeWeekHabit(
                        name: "Listening Practice",
                        icon: "waveform",
                        colorHex: "B8D8E8",
                        seedTier: "In one conversation, wait 2 seconds before responding",
                        sproutTier: "Practice reflective listening: 'So you're saying...' in 3 conversations",
                        bloomTier: "Have a 10-minute conversation where you only ask questions and listen",
                        dayNumber: 2,
                        tag: "ConnectionClarityW1"
                    )
                ]
            ),
            
            // DAY 3: EXPRESSING NEEDS
            DayTheme(
                dayNumber: 3,
                themeName: "\"I\" Statements",
                themeIcon: "text.bubble.fill",
                tagline: "Express yourself without blame or defensiveness",
                colorHex: "D4C8E8",  // Soft lavender
                habits: [
                    ThemeWeekHabit(
                        name: "Assertive Communication",
                        icon: "quote.bubble.fill",
                        colorHex: "D4C8E8",
                        seedTier: "Write down one unspoken need using this formula: 'I feel ___ when ___ because I need ___'",
                        sproutTier: "Practice saying one 'I feel' statement out loud (mirror, voice memo, or to someone safe)",
                        bloomTier: "Use an 'I' statement in a real situation to express a boundary or need",
                        dayNumber: 3,
                        tag: "ConnectionClarityW1"
                    )
                ]
            ),
            
            // DAY 4: BOUNDARIES
            DayTheme(
                dayNumber: 4,
                themeName: "Boundary Practice",
                themeIcon: "shield.lefthalf.filled",
                tagline: "Saying no is self-respect, not selfishness",
                colorHex: "E8C8D4",  // Dusty rose
                habits: [
                    ThemeWeekHabit(
                        name: "Gentle Boundaries",
                        icon: "hand.raised.fill",
                        colorHex: "E8C8D4",
                        seedTier: "Notice one moment when you wanted to say no but said yes",
                        sproutTier: "Say no to one small thing without over-explaining ('I can't make it, but thanks!')",
                        bloomTier: "Set a clear boundary with someone close using 'I' statements and hold it even if it's uncomfortable",
                        dayNumber: 4,
                        tag: "ConnectionClarityW1"
                    )
                ]
            ),
            
            // DAY 5: CONFLICT NAVIGATION
            DayTheme(
                dayNumber: 5,
                themeName: "Healthy Disagreement",
                themeIcon: "arrow.triangle.2.circlepath",
                tagline: "Conflict doesn't have to mean catastrophe",
                colorHex: "F4D8A8",  // Warm sand
                habits: [
                    ThemeWeekHabit(
                        name: "Conflict Skills",
                        icon: "arrow.left.arrow.right",
                        colorHex: "F4D8A8",
                        seedTier: "When upset, take 3 deep breaths before responding (avoid reactive words)",
                        sproutTier: "In one disagreement, name your emotion: 'I'm feeling defensive/hurt/confused right now'",
                        bloomTier: "Navigate a full conflict using: (1) Name emotion, (2) State need, (3) Ask for their perspective, (4) Propose solution",
                        dayNumber: 5,
                        tag: "ConnectionClarityW1"
                    )
                ]
            ),
            
            // DAY 6: SOCIAL SCRIPTS
            DayTheme(
                dayNumber: 6,
                themeName: "Conversation Scaffolding",
                themeIcon: "text.book.closed.fill",
                tagline: "Pre-planned phrases for when your mind goes blank",
                colorHex: "C8E8D8",  // Mint green
                habits: [
                    ThemeWeekHabit(
                        name: "Script Building",
                        icon: "list.bullet.clipboard.fill",
                        colorHex: "C8E8D8",
                        seedTier: "Write down 3 'buying time' phrases (e.g., 'That's a good question, let me think...')",
                        sproutTier: "Create scripts for 3 scenarios you find hard (ending conversations, declining plans, asking for help)",
                        bloomTier: "Use one of your scripts in real life today and journal about how it felt",
                        dayNumber: 6,
                        tag: "ConnectionClarityW1"
                    )
                ]
            ),
            
            // DAY 7: INTEGRATION & COMPASSION
            DayTheme(
                dayNumber: 7,
                themeName: "The Long Game",
                themeIcon: "heart.text.square.fill",
                tagline: "Communication is a practice, not a performance",
                colorHex: "E8D8F4",  // Pale lilac
                habits: [
                    ThemeWeekHabit(
                        name: "Weekly Reflection",
                        icon: "book.pages.fill",
                        colorHex: "E8D8F4",
                        seedTier: "Name one moment this week when you communicated more clearly",
                        sproutTier: "Write 5-10 minutes about what you learned about your communication patterns",
                        bloomTier: "Full reflection using the journaling guide: What challenged you? What surprised you? Which skills will you continue practicing?",
                        dayNumber: 7,
                        tag: "ConnectionClarityW1"
                    )
                ]
            )
        ],
        keyFeatures: [
            "Daily journal prompts built into tiers",
            "Progresses from observation to action",
            "Focuses on realistic, low-stakes practice",
            "Helps when you feel uncertain or go blank in conversations"
        ],
        tips: [
            "Noticing patterns is the first step to changing them",
            "Prepared phrases help when you feel uncertain—use the journaling guide for examples",
            "Imperfect practice builds real skills over time",
            "Sprout tier is the sustainable goal—Bloom is optional"
        ]
    )
}



// MARK: - Helper Extensions

extension ThemeWeekProgram {
    /// Get the theme for a specific day (1-7)
    func theme(for dayNumber: Int) -> DayTheme? {
        dailyThemes.first { $0.dayNumber == dayNumber }
    }
    
    /// Get current day's theme based on start date
    func currentDayTheme(startDate: Date) -> DayTheme? {
        let daysPassed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let currentDay = min(daysPassed + 1, 7)  // Cap at day 7
        return theme(for: currentDay)
    }
    
    /// Get all habits for the program (flattened)
    var allHabits: [ThemeWeekHabit] {
        dailyThemes.flatMap { $0.habits }
    }
}

extension ThemeWeekHabit {
    /// Get tier description by type
    func tierDescription(for tier: CompletionTier) -> String {
        switch tier {
        case .seed:  return seedTier
        case .sprout: return sproutTier
        case .bloom: return bloomTier
        }
    }
}

// MARK: - Completion Tier Enum

enum CompletionTier: String, Codable, CaseIterable {
    case seed = "seed"
    case sprout = "sprout"
    case bloom = "bloom"
    
    var emoji: String {
        switch self {
        case .seed:   return "🌱"
        case .sprout: return "🌿"
        case .bloom:  return "🌳"
        }
    }
    
    var displayName: String {
        switch self {
        case .seed:   return "Seed"
        case .sprout: return "Sprout"
        case .bloom:  return "Bloom"
        }
    }
    
    var description: String {
        switch self {
        case .seed:   return "Minimum viable action"
        case .sprout: return "Intended goal"
        case .bloom:  return "Above and beyond"
        }
    }
}
