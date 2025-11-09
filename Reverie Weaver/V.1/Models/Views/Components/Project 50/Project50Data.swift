//
// Project50Data.swift
// ReverieWeaver
//
// Redesigned Oct 2025
//
// Defines all curated program data (Project 50 & Mini Challenges)
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
    
    // Program metadata for Desk filtering
    let program: String        // "project50" or "miniChallenge"
    let level: Int?           // 1, 2, or 3 (only for Project 50)
    let tag: String?          // e.g. "FocusSprint" for mini challenges
    let durationDays: Int?    // e.g. 7 for mini challenges
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

// MARK: - MINI CHALLENGES (7-Day Programs) - ADHD-Friendly Edition
struct MiniChallenge: Identifiable, Codable {
    var id: String { tag }  // ← Computed property - no need to pass id anymore
    let title: String
    let tagline: String
    let description: String
    let tag: String
    let colorHex: String
    let icon: String
    let habits: [Project50Habit]
    let adhdFeatures: [String]
    let tips: [String]
    let progressionGuide: String
}

struct MiniChallengeData {
    static let challenges: [MiniChallenge] = [
        // MARK: - 1. Focus Flow
        MiniChallenge(
            title: "Focus Flow",
            tagline: "Work with your brain, not against it",
            description: "Train your attention in short, flexible bursts. Perfect for variable focus patterns.",
            tag: "FocusFlow",
            colorHex: "9B7EBD",
            icon: "bolt.fill",
            habits: [
                Project50Habit(
                    name: "Morning Brain Warm-Up",
                    description: "Pick your easiest task first. 15-25 min, then break. Start small.\n\nRescue: If you can't start, just open the file/tab. That counts.",
                    icon: "sunrise.fill",
                    colorHex: "C5B0E8",
                    category: "Focus Flow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "FocusFlow",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Pomodoro Your Way",
                    description: "Work 25 min, break 5 min. OR 15/3. OR 45/10. Find YOUR rhythm.\n\nRescue: One pomodoro is a win. Even a half-pomodoro counts.",
                    icon: "timer",
                    colorHex: "B8A5D8",
                    category: "Focus Flow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "FocusFlow",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Evening Brain Dump",
                    description: "Voice memo or scribble: what almost worked today? No judgment.\n\nRescue: Just one sentence. Or draw a face emoji.",
                    icon: "moon.stars.fill",
                    colorHex: "D9C8FF",
                    category: "Focus Flow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "FocusFlow",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "Flexible time blocks (15-45 min, not rigid 90 min)",
                "Choose your own pomodoro length",
                "Rescue protocols for executive dysfunction",
                "Half-completion celebrated",
                "Voice memos accepted (no writing required)"
            ],
            tips: [
                "Start with easiest tasks to build momentum",
                "Set visual timer where you can see it",
                "Phone on silent, but don't beat yourself up if you check it",
                "Track when flow happens naturally - that's your golden hour"
            ],
            progressionGuide: "Days 1-3: Find your natural rhythm | Days 4-5: Protect your focus time | Days 6-7: Trust your system"
        ),
        
        // MARK: - 2. Dopamine Design
        MiniChallenge(
            title: "Dopamine Design",
            tagline: "Engineer your environment for success",
            description: "Set up external systems that work with your ADHD brain, not against it.",
            tag: "DopamineDesign",
            colorHex: "FF9E9E",
            icon: "sparkles",
            habits: [
                Project50Habit(
                    name: "Visible Cues",
                    description: "Put tomorrow's #1 task on a sticky note where you'll see it.\n\nRescue: Write it on your hand. Seriously.",
                    icon: "note.text",
                    colorHex: "FFB3C1",
                    category: "Dopamine Design",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DopamineDesign",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Body Double Time",
                    description: "Work near someone (virtual counts). Parallel play for adults.\n\nRescue: YouTube 'study with me' videos count as body doubles.",
                    icon: "person.2.fill",
                    colorHex: "FFA7A0",
                    category: "Dopamine Design",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DopamineDesign",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Dopamine Snack",
                    description: "After focus: 5 min of something fun. TikTok, game, stretch. Guilt-free.\n\nRescue: This isn't optional - your brain needs the reward.",
                    icon: "flame.fill",
                    colorHex: "FF8FAB",
                    category: "Dopamine Design",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DopamineDesign",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "External reminders (compensates for working memory)",
                "Body doubling reduces activation energy",
                "Built-in rewards prevent burnout",
                "Permission to use 'fun' as fuel",
                "No guilt around dopamine sources"
            ],
            tips: [
                "Place cues in your path (bathroom mirror, coffee maker)",
                "Discord study rooms = instant body doubles",
                "Schedule dopamine, don't fight it",
                "Rotate your rewards to keep novelty"
            ],
            progressionGuide: "Days 1-3: Notice what helps | Days 4-5: Double down on what works | Days 6-7: Design your permanent system"
        ),
        
        // MARK: - 3. Tiny Anchors
        MiniChallenge(
            title: "Tiny Anchors",
            tagline: "Micro-habits that actually stick",
            description: "Build habits so small you can't fail. Stack them onto things you already do.",
            tag: "TinyAnchors",
            colorHex: "8FBC8F",
            icon: "link",
            habits: [
                Project50Habit(
                    name: "Stack One Thing",
                    description: "After I [existing habit], I will [1 new tiny thing]. That's it.\n\nRescue: 'If I brush teeth, I'll do 3 pushups.' Start there.",
                    icon: "arrow.up.arrow.down",
                    colorHex: "A3D9A5",
                    category: "Tiny Anchors",
                    program: "miniChallenge",
                    level: nil,
                    tag: "TinyAnchors",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Sensory Reset Button",
                    description: "Feeling stuck? Splash face OR stretch OR 3 breaths. Pick one, do it.\n\nRescue: Even just shaking your hands counts.",
                    icon: "waveform.path.ecg",
                    colorHex: "98D98E",
                    category: "Tiny Anchors",
                    program: "miniChallenge",
                    level: nil,
                    tag: "TinyAnchors",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Evening Bookmark",
                    description: "Set up tomorrow's first step. Open the doc. Lay out gym clothes.\n\nRescue: Just thinking about it primes your brain.",
                    icon: "bookmark.fill",
                    colorHex: "7FB88E",
                    category: "Tiny Anchors",
                    program: "miniChallenge",
                    level: nil,
                    tag: "TinyAnchors",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "Habit stacking reduces decision fatigue",
                "Stupidly small = impossible to fail",
                "Multiple options (OR not AND)",
                "Body-based resets work instantly",
                "Evening prep lowers morning activation energy"
            ],
            tips: [
                "Write your if-then on a sticky note",
                "Keep your sensory reset options visible",
                "Evening bookmark = biggest ROI habit",
                "Don't add a second stack until first is automatic"
            ],
            progressionGuide: "Days 1-3: Practice one anchor only | Days 4-5: Make it automatic | Days 6-7: Consider adding a second (optional)"
        ),
        
        // MARK: - 4. Chaos Mode
        MiniChallenge(
            title: "Chaos Mode",
            tagline: "For when everything feels hard",
            description: "Bad brain days need different rules. This is your survival mode toolkit.",
            tag: "ChaosMode",
            colorHex: "E8927C",
            icon: "exclamationmark.triangle.fill",
            habits: [
                Project50Habit(
                    name: "Survival Minimum",
                    description: "One thing only: hydrate OR move OR eat. Just one. That's enough.\n\nRescue: Bad brain days need different rules. This is yours.",
                    icon: "heart.fill",
                    colorHex: "F7A895",
                    category: "Chaos Mode",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ChaosMode",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Movement Medicine",
                    description: "Walk while thinking. Pace while planning. Fidget while working. Movement IS focus.\n\nRescue: Sitting still is not required for productivity.",
                    icon: "figure.walk",
                    colorHex: "E69A85",
                    category: "Chaos Mode",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ChaosMode",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Voice Note Wins",
                    description: "Before bed: voice memo ONE thing that didn't suck today.\n\nRescue: 'I survived' counts as a win.",
                    icon: "mic.fill",
                    colorHex: "D98570",
                    category: "Chaos Mode",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ChaosMode",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "Lowest possible bar (one thing)",
                "Permission for movement-based focus",
                "No writing required (voice memos)",
                "Survival = success (no shame)",
                "Acknowledges bad brain days are real"
            ],
            tips: [
                "Keep water bottle visible always",
                "Walking meetings are real meetings",
                "Voice memos can be 5 seconds long",
                "Use this challenge when normal rules feel impossible"
            ],
            progressionGuide: "Days 1-7: Practice self-compassion, reduce shame, rebuild trust in yourself"
        ),
        
        // MARK: - 5. Novelty Seeker
        MiniChallenge(
            title: "Novelty Seeker",
            tagline: "Feed your brain's need for new",
            description: "ADHD brains crave novelty. Stop fighting it. Design dopamine strategically.",
            tag: "NoveltySeeker",
            colorHex: "FFD18B",
            icon: "star.fill",
            habits: [
                Project50Habit(
                    name: "Rotate Your Tools",
                    description: "New notebook? Different playlist? Work at café? Change one thing daily.\n\nRescue: Novelty = dopamine. This isn't procrastination.",
                    icon: "shuffle",
                    colorHex: "FFE09D",
                    category: "Novelty Seeker",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NoveltySeeker",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "15-Min Rabbit Hole",
                    description: "Learn something random. Wiki deep-dive. YouTube curiosity. Then back to work.\n\nRescue: Schedule curiosity so it doesn't steal focus time.",
                    icon: "safari",
                    colorHex: "FFCFA0",
                    category: "Novelty Seeker",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NoveltySeeker",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Evening Spark Capture",
                    description: "Screenshot/save 1-3 things that made you curious today.\n\nRescue: Feed future you with inspiration reserves.",
                    icon: "camera.fill",
                    colorHex: "FFC78B",
                    category: "Novelty Seeker",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NoveltySeeker",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "Embraces ADHD novelty-seeking",
                "Scheduled curiosity prevents derails",
                "Tool rotation = sustained interest",
                "Builds inspiration library",
                "Permission to explore (with boundaries)"
            ],
            tips: [
                "Budget for 'novelty items' (notebooks, pens, apps)",
                "Timebox rabbit holes to prevent 3-hour deep dives",
                "Create a 'curiosity parking lot' for later",
                "Novelty isn't a character flaw - it's brain design"
            ],
            progressionGuide: "Days 1-3: Notice your patterns | Days 4-5: Use novelty strategically | Days 6-7: Design your dopamine system"
        ),
        
        // MARK: - 6. Connection Lite
        MiniChallenge(
            title: "Connection Lite",
            tagline: "Social without the pressure",
            description: "Low-effort connection for when peopling feels hard. Async > real-time.",
            tag: "ConnectionLite",
            colorHex: "C8D3F9",
            icon: "heart.text.square.fill",
            habits: [
                Project50Habit(
                    name: "React, Don't Create",
                    description: "Reply to one message. Like one post. No new content required.\n\nRescue: Low-effort connection still counts as connection.",
                    icon: "hand.thumbsup.fill",
                    colorHex: "D2DBFA",
                    category: "Connection Lite",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ConnectionLite",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Parallel Presence",
                    description: "Do your own thing near someone. Video call, work together silently.\n\nRescue: Being near people ≠ entertaining people.",
                    icon: "person.2.fill",
                    colorHex: "BFD2FA",
                    category: "Connection Lite",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ConnectionLite",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Voice Memo Love",
                    description: "Send a voice note to someone you appreciate. Rambling is fine.\n\nRescue: Async > real-time for ADHD social.",
                    icon: "mic.circle.fill",
                    colorHex: "A8C5F9",
                    category: "Connection Lite",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ConnectionLite",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "Async communication (no real-time pressure)",
                "Low-effort options (react vs create)",
                "Parallel play = real connection",
                "Permission to ramble in voice memos",
                "Being present ≠ performing"
            ],
            tips: [
                "Voice memos can be sent while walking",
                "Body doubling counts as quality time",
                "Responding > initiating (lower activation)",
                "Text-free days are valid"
            ],
            progressionGuide: "Days 1-3: Low-pressure contact | Days 4-5: Find your style | Days 6-7: Build sustainable rhythm"
        ),
        
               // MARK: - 7. Radiant Reset (养颜七日)
               MiniChallenge(
                   title: "Radiant Reset",
                   tagline: "养颜七日 - TCM foundation for glowing skin",
                   description: "7-day introduction to TCM skin wellness. Warm foods, early sleep, gentle rituals. Your foundation for radiant skin.",
                   tag: "RadiantReset",
                   colorHex: "FFB7C5",
                   icon: "sparkles",
                   habits: [
                       Project50Habit(
                           name: "Warm Morning Start",
                           description: "Breakfast between 7-9 AM (spleen peak time). Warm congee, goji berries, or warm lemon water.\n\nRescue: Even just warm water counts. No cold/iced drinks today.",
                           icon: "sunrise.fill",
                           colorHex: "FFC8D4",
                           category: "Radiant Reset",
                           program: "miniChallenge",
                           level: nil,
                           tag: "RadiantReset",
                           durationDays: 7
                       ),
                       Project50Habit(
                           name: "No Cold/Raw Foods",
                           description: "All meals warm and cooked. Avoid salads, smoothies, iced drinks. Spleen prefers warmth.\n\nRescue: Room temperature counts. Just avoid anything straight from the fridge.",
                           icon: "flame.fill",
                           colorHex: "FFB3C8",
                           category: "Radiant Reset",
                           program: "miniChallenge",
                           level: nil,
                           tag: "RadiantReset",
                           durationDays: 7
                       ),
                       Project50Habit(
                           name: "Facial Massage Ritual",
                           description: "3-5 min jade roller or gua sha. Gentle upward strokes. Use oil if you have it.\n\nRescue: Just fingertips work. Upward gentle pressure on face/neck.",
                           icon: "hands.sparkles.fill",
                           colorHex: "FFA5BC",
                           category: "Radiant Reset",
                           program: "miniChallenge",
                           level: nil,
                           tag: "RadiantReset",
                           durationDays: 7
                       ),
                       Project50Habit(
                           name: "Sleep by 11 PM",
                           description: "Critical for skin repair. In bed by 11 PM. Skin regenerates at night.\n\nRescue: In bed = success. Reading counts. Just be horizontal and resting.",
                           icon: "moon.stars.fill",
                           colorHex: "FFAAC5",
                           category: "Radiant Reset",
                           program: "miniChallenge",
                           level: nil,
                           tag: "RadiantReset",
                           durationDays: 7
                       ),
                       Project50Habit(
                           name: "Herbal Tea Moment",
                           description: "One cup warm herbal tea: green tea, ginger, chrysanthemum, or rose tea. Room temp or warm only.\n\nRescue: Hot water with nothing in it counts. Just stay hydrated and warm.",
                           icon: "cup.and.saucer.fill",
                           colorHex: "FFC1D3",
                           category: "Radiant Reset",
                           program: "miniChallenge",
                           level: nil,
                           tag: "RadiantReset",
                           durationDays: 7
                       )
                   ],
                   adhdFeatures: [
                       "Simple daily rituals (5-10 min each)",
                       "Food rules are flexible (warm > cold is the key)",
                       "Facial massage = satisfying stimming",
                       "Sleep goal is 'in bed' not 'asleep'",
                       "Rescue options for every habit"
                   ],
                   tips: [
                       "Set phone alarm for 10:30 PM (bedtime prep)",
                       "Keep herbal tea bags visible on counter",
                       "Jade roller in bathroom = visual cue",
                       "Cook extra at dinner to have warm breakfast ready",
                       "Yellow skin = spleen needs support (this resets it)",
                       "Complete this before trying Glowing Journey (21 days)"
                   ],
                   progressionGuide: "Days 1-3: Learn the basics | Days 4-5: Build consistency | Days 6-7: Ready to level up"
               ),
               
        // MARK: - 8A. Glowing Journey W1 (Clear Dampness 祛湿七日)
        MiniChallenge(
            title: "Glowing Journey: Week 1",
            tagline: "祛湿七日 - Clear dampness, awaken the glow",
            description: "Week 1 focuses on clearing internal dampness and strengthening the spleen (脾). When the spleen is weak, the skin turns dull or yellowish. Clearing dampness restores warmth and clarity.\n\n🌿 中医理念：『脾主肌肉，湿盛则肤色晦黄。』温食、早食、少寒饮，是第一步的养颜之道。",
            tag: "GlowingJourneyW1",
            colorHex: "FFB19D",
            icon: "drop.fill",
            habits: [
                Project50Habit(
                    name: "Warm Meals Only 温食养脾",
                    description: "Eat warm or room-temperature foods only. Avoid salads, smoothies, and iced drinks. Warmth nourishes your spleen and clears dampness.\n\n🫖 养生说明：『脾喜温恶寒。』少喝冷饮，脾气自升，面色自然不黄。\n\nRescue: Skip iced drinks — that’s 80% of the work.",
                    icon: "flame.circle.fill",
                    colorHex: "FFAA93",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Morning Ginger Water 姜水驱湿",
                    description: "Start the day with a cup of warm water + ginger (or lemon). Stimulates digestion and clears cold dampness.\n\n🫖 养生说明：『早晨一杯姜水，胜过人参汤。』温阳祛寒，让你整天气色红润。\n\nRescue: Plain warm water counts too.",
                    icon: "sunrise.fill",
                    colorHex: "FFB8A0",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Light & Early Dinner 早食少食",
                    description: "Finish dinner before 7 PM. Choose steamed or soupy dishes to reduce heaviness.\n\n🫖 养生说明：『过饱伤脾，夜食伤胃。』轻食早餐有助于第二天肤色明亮。\n\nRescue: Skip late-night snacks — your spleen will thank you.",
                    icon: "moon.stars.fill",
                    colorHex: "FFC1A8",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW1",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "Three clear habits only",
                "Binary warm/cold choices reduce overwhelm",
                "Small visible wins (less bloating, brighter tone)"
            ],
            tips: [
                "Replace coffee with warm barley or green tea",
                "Eat barley soup 2–3× this week for dampness",
                "Keep a thermos of warm water on your desk",
                "By Day 7: skin dullness and puffiness reduce"
            ],
            progressionGuide: "Days 1–2: Adjust meals | Days 3–5: Body feels lighter | Days 6–7: Clearer tone & more energy"
        ),
        
        // MARK: - 8B. Glowing Journey W2 (Nourish Blood & Qi 补气养血七日)
        MiniChallenge(
            title: "Glowing Journey: Week 2",
            tagline: "补气养血七日 - Nourish Qi and Blood for vitality",
            description: "Week 2 builds inner radiance. As Qi and Blood are replenished, your skin becomes naturally pink and alive.\n\n🍑 中医理念：『气血充盈，面色自华。』气虚则倦，血虚则黄。温补脾胃、早睡养肝，是气色红润的关键。",
            tag: "GlowingJourneyW2",
            colorHex: "FF9F89",
            icon: "heart.circle.fill",
            habits: [
                Project50Habit(
                    name: "Add Blood Builders 补血食养",
                    description: "Add red dates (红枣), goji berries (枸杞), or black sesame (黑芝麻) to one meal daily.\n\n🫖 养生说明：『女子以血为本，血足则颜自润。』每日一碗红枣枸杞茶，即是最简单的养颜方。\n\nRescue: Just drink goji + red date tea once today.",
                    icon: "leaf.fill",
                    colorHex: "FFA58E",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Beauty Congee Morning 美颜早粥",
                    description: "Start day with warm congee (rice or millet) with red dates, goji, or Chinese yam.\n\n🫖 养生说明：『晨起一碗粥，胜似补药汤。』温养脾胃，助血生化，肤色红润。\n\nRescue: Oatmeal with goji works too.",
                    icon: "cup.and.saucer.fill",
                    colorHex: "FFB099",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Sleep by 11 PM 早睡养肝血",
                    description: "Sleep before 11 PM to let the liver store and renew blood. Critical for collagen and radiance.\n\n🫖 养生说明：『肝藏血，卧则血归于肝。』早睡的人，气色不会差。\n\nRescue: In bed reading by 11 counts as rest.",
                    icon: "bed.double.fill",
                    colorHex: "FF9D88",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW2",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "Food-based habits = concrete & rewarding",
                "Sleep = measurable success metric",
                "Simple sensory routine (tea, congee, warmth)"
            ],
            tips: [
                "Prep goji + red date tea nightly",
                "Add Chinese yam to soup for digestion",
                "Notice warmth in hands and cheeks returning",
                "Energy rises before visible glow — stay patient"
            ],
            progressionGuide: "Days 1–3: Add tonic foods | Days 4–5: Sleep deeper | Days 6–7: Complexion turns pinker"
        ),
        
        // MARK: - 8C. Glowing Journey W3 (Radiant Glow 焕发七日)
        MiniChallenge(
            title: "Glowing Journey: Week 3",
            tagline: "焕发七日 - Radiate from within",
            description: "Week 3 helps Qi and Blood circulate freely, revealing natural brightness. This week blends gentle movement, self-massage, and reflection.\n\n✨ 中医理念：『气行则血行，血行则面有光。』当经络通畅、心神安定，皮肤自然明亮。",
            tag: "GlowingJourneyW3",
            colorHex: "FF8A7B",
            icon: "sparkles",
            habits: [
                Project50Habit(
                    name: "Facial Massage / Gua Sha 行气活血",
                    description: "5–10 min daily gua sha or jade roller to improve circulation. Focus on LI4, ST36, SP6 points.\n\n🫖 养生说明：『面若桃花，不在脂粉，在于气血流通。』轻轻刮几下，通经养颜。\n\nRescue: 2 min fingertip massage still helps.",
                    icon: "hands.sparkles.fill",
                    colorHex: "FF9486",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Gentle Movement 动则生阳",
                    description: "Practice light stretching, yoga, or a 15-min walk daily to move Qi and reduce stagnation.\n\n🫖 养生说明：『动生阳，阳生气，气行则色泽。』动一动，神采就亮起来。\n\nRescue: Stretch in bed for 2 minutes — it counts.",
                    icon: "figure.walk",
                    colorHex: "FF9A8B",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Evening Tea & Reflection 安神养心",
                    description: "End day with rose, chrysanthemum, or longan tea. Reflect gently on your energy and skin.\n\n🫖 养生说明：『心和则气顺，气顺则颜明。』心静气顺，光泽自生。\n\nRescue: Warm water + gratitude note works too.",
                    icon: "teapot",
                    colorHex: "FF9E91",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW3",
                    durationDays: 7
                )
            ],
            adhdFeatures: [
                "Tactile self-care (gua sha) = satisfying sensory reward",
                "Reflection = grounding dopamine hit",
                "Flexible & restorative structure"
            ],
            tips: [
                "Do gua sha after evening skincare routine",
                "Pair tea ritual with journaling 5 minutes",
                "Take a photo on Day 7 — you’ll see the glow",
                "Maintain warmth and early sleep for lasting results"
            ],
            progressionGuide: "Days 1–2: Gentle activation | Days 3–5: Circulation glow | Days 6–7: Radiant calm & clarity"
        )
    ]
}


extension Project50Data {
    static func allLevelOneHabits() -> [Project50Habit] {
        categories.flatMap { category in
            category.levels[1] ?? []
        }
    }
}
