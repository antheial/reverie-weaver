//
//  ConstellationBadge.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/24/25.
//


//
// WeaverGamificationSystem.swift
// Reverie Weaver
//
// Complete gamification system with:
// - Constellation badges with stories
// - Invisible achievements
// - Anniversary celebrations
// - Seasonal journey tracking
// - Weaver level system
//

import SwiftUI
import SwiftData
import Foundation
import Combine

// MARK: - Constellation Badge Model

@Model
final class ConstellationBadge {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var category: String // Maps to habit category
    var story: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var completionsRequired: Int
    
    init(
        name: String,
        iconName: String,
        colorHex: String,
        category: String,
        story: String,
        completionsRequired: Int = 20
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.category = category
        self.story = story
        self.isUnlocked = false
        self.unlockedDate = nil
        self.completionsRequired = completionsRequired
    }
}

// MARK: - Constellation Data

struct ConstellationData {
    static let allConstellations: [ConstellationBadge] = [
        ConstellationBadge(
            name: "Morning Star",
            iconName: "sun.max.fill",
            colorHex: "FFD18B",
            category: "Morning Rituals",
            story: "The Morning Star constellation has been woven into your sky. Ancient weavers believed this star represented clarity of purpose—the gentle light that guides you from dream into day. Each morning habit you complete adds luminosity to this star, reminding you that beginnings hold infinite possibility."
        ),
        ConstellationBadge(
            name: "Tranquil Moon",
            iconName: "moon.fill",
            colorHex: "9B7EBD",
            category: "Mindful Living",
            story: "The Tranquil Moon shines softly in your constellation map. This celestial body speaks of rest, reflection, and the wisdom found in stillness. Your mindfulness practices have called this moon into being—a reminder that not all growth happens in motion."
        ),
        ConstellationBadge(
            name: "Verdant Leaf",
            iconName: "leaf.fill",
            colorHex: "A8B5A0",
            category: "Health Foundations",
            story: "The Verdant Leaf constellation blooms in your sky, a symbol of health, vitality, and natural rhythms. Each wellness habit you tend becomes a leaf on this cosmic tree. Ancient traditions teach that the body is the first temple—you honor it well."
        ),
        ConstellationBadge(
            name: "Sacred Flame",
            iconName: "flame.fill",
            colorHex: "D4A5A5",
            category: "Creative Practice",
            story: "The Sacred Flame ignites in your constellation. This fire represents the creative spark that lives in all beings. Your artistic practices have fanned this flame from ember to blaze. Creativity is not frivolous—it is the soul's native language, and you speak it fluently."
        ),
        ConstellationBadge(
            name: "Gentle Wind",
            iconName: "wind",
            colorHex: "B8C5D6",
            category: "Focus Flow",
            story: "The Gentle Wind constellation swirls into existence. This element speaks of movement without force, progress without strain. Your focus habits have taught you to flow like wind through obstacles rather than crash against them. Effortless does not mean easy—it means aligned."
        ),
        ConstellationBadge(
            name: "Crystal Drop",
            iconName: "drop.fill",
            colorHex: "A3C9D9",
            category: "Connection",
            story: "The Crystal Drop constellation forms, each droplet a moment of genuine connection. Water teaches us that we are all part of the same ocean. Your relationship habits honor this truth—that reaching out to others is reaching toward yourself."
        ),
        ConstellationBadge(
            name: "Steady Mountain",
            iconName: "mountain.2.fill",
            colorHex: "8B7E74",
            category: "Tiny Anchors",
            story: "The Steady Mountain constellation rises solid and unchanging. Mountains remind us that small, consistent actions accumulate into something immovable. Your tiny anchors have become bedrock. You've learned what ancient stoics knew: discipline is freedom."
        ),
        ConstellationBadge(
            name: "Wandering Cloud",
            iconName: "cloud.fill",
            colorHex: "E5E5E5",
            category: "Dopamine Design",
            story: "The Wandering Cloud constellation drifts into your sky. Clouds shift and change, reminding us that structure can coexist with spontaneity. Your experiments with novelty and pleasure have revealed this truth: joy is not the opposite of discipline; it's the companion that makes discipline sustainable."
        )
    ]
}

// MARK: - Invisible Achievement Model

@Model
final class InvisibleAchievement {
    var id: UUID
    var name: String
    var story: String
    var iconName: String
    var colorHex: String
    var discoveredDate: Date
    var triggerType: String // "moonlight_weaver", "gentle_rebel", etc.
    
    init(
        name: String,
        story: String,
        iconName: String,
        colorHex: String,
        triggerType: String
    ) {
        self.id = UUID()
        self.name = name
        self.story = story
        self.iconName = iconName
        self.colorHex = colorHex
        self.discoveredDate = Date()
        self.triggerType = triggerType
    }
}

// MARK: - Anniversary Milestone

struct AnniversaryMilestone {
    let title: String
    let message: String
    let icon: String
    let days: Int
    
    static func milestone(for days: Int) -> AnniversaryMilestone? {
        switch days {
        case 7:
            return AnniversaryMilestone(
                title: "First Week",
                message: "Seven days of showing up. Not perfect, not grand—just present. This is how all great journeys begin.",
                icon: "star.fill",
                days: 7
            )
        case 30:
            return AnniversaryMilestone(
                title: "First Moon",
                message: "You've been weaving for one lunar cycle. The moon teaches us that growth has phases—waxing, waning, and waxing again. You're learning the rhythm.",
                icon: "moon.fill",
                days: 30
            )
        case 90:
            return AnniversaryMilestone(
                title: "First Season",
                message: "A full season has passed since you began. Ninety days of choices, each one a thread. Your tapestry is no longer just potential—it's becoming real.",
                icon: "leaf.fill",
                days: 90
            )
        case 180:
            return AnniversaryMilestone(
                title: "Two Seasons",
                message: "Half a year of practice. You've seen your habits through different weather—literal and metaphorical. What remains steady through change is true foundation.",
                icon: "sun.max.fill",
                days: 180
            )
        case 365:
            return AnniversaryMilestone(
                title: "Full Year",
                message: "One complete orbit around the sun. You've experienced every season of this practice. The person who started this journey is different from who reads this now. That difference is your tapestry.",
                icon: "sparkles",
                days: 365
            )
        case 500:
            return AnniversaryMilestone(
                title: "Beyond Seasons",
                message: "Five hundred days. You're past milestones now—this is simply who you are. A weaver. Someone who tends their life with intention. The practice has become the path.",
                icon: "figure.walk",
                days: 500
            )
        case 730:
            return AnniversaryMilestone(
                title: "Two Years",
                message: "Two full revolutions. What once took effort now happens naturally. This is mastery—not perfection, but integration. Your habits have become part of your breath.",
                icon: "infinity",
                days: 730
            )
        default:
            return nil
        }
    }
}

// MARK: - Season Model

struct Season {
    let name: String
    let subtitle: String
    let icon: String
    let colorHex: String
    let description: String
    let dayRange: ClosedRange<Int>
    
    static let allSeasons: [Season] = [
        Season(
            name: "Spring",
            subtitle: "Season of Awakening",
            icon: "leaf.fill",
            colorHex: "A8D5BA",
            description: "New beginnings bloom. Everything feels possible. You're planting seeds—some will grow, others won't, and that's the nature of spring.",
            dayRange: 1...90
        ),
        Season(
            name: "Summer",
            subtitle: "Season of Growth",
            icon: "sun.max.fill",
            colorHex: "FFD18B",
            description: "Your practice flourishes under consistent attention. This is the season of expansion, where small habits reveal their compound power.",
            dayRange: 91...180
        ),
        Season(
            name: "Autumn",
            subtitle: "Season of Harvest",
            icon: "wind",
            colorHex: "D4A5A5",
            description: "You're reaping what you've sown. Some harvests are abundant, others modest. Both teach. This season asks: what was worth the tending?",
            dayRange: 181...270
        ),
        Season(
            name: "Winter",
            subtitle: "Season of Reflection",
            icon: "moon.stars.fill",
            colorHex: "B8C5D6",
            description: "Rest and integrate. Not all growth is visible. Winter teaches that dormancy is not death—it's preparation. Reflect on your year before the cycle begins again.",
            dayRange: 271...365
        )
    ]
    
    static func current(for daysSinceStart: Int) -> Season {
        let adjustedDays = (daysSinceStart - 1) % 365 + 1
        return allSeasons.first { $0.dayRange.contains(adjustedDays) } ?? allSeasons[0]
    }
}

// MARK: - Weaver Level System

struct WeaverLevel {
    let level: Int
    let title: String
    let minCompletions: Int
    let maxCompletions: Int?
    let description: String
    
    var next: Int? {
        maxCompletions
    }
    
    static let levels: [WeaverLevel] = [
        WeaverLevel(
            level: 1,
            title: "Apprentice Weaver",
            minCompletions: 0,
            maxCompletions: 50,
            description: "Every master begins here. You're learning the basic motions—thread over thread, habit over habit."
        ),
        WeaverLevel(
            level: 2,
            title: "Mindful Weaver",
            minCompletions: 50,
            maxCompletions: 150,
            description: "You're no longer just going through motions. There's awareness now—you feel the texture of each practice."
        ),
        WeaverLevel(
            level: 3,
            title: "Devoted Weaver",
            minCompletions: 150,
            maxCompletions: 300,
            description: "Devotion means returning even when inspiration fades. You've proven this truth through action."
        ),
        WeaverLevel(
            level: 4,
            title: "Master Weaver",
            minCompletions: 300,
            maxCompletions: 500,
            description: "Mastery is not perfection—it's the ability to begin again, even after unraveling. You embody this."
        ),
        WeaverLevel(
            level: 5,
            title: "Luminous Weaver",
            minCompletions: 500,
            maxCompletions: 1000,
            description: "Your practice radiates now. Others sense it without knowing why. This is what consistent devotion becomes—light."
        ),
        WeaverLevel(
            level: 6,
            title: "Transcendent Weaver",
            minCompletions: 1000,
            maxCompletions: nil,
            description: "You've moved beyond counting threads. The tapestry and the weaver are one. This is not an ending—it's a homecoming."
        )
    ]
    
    static func level(for completions: Int) -> WeaverLevel {
        levels.last { $0.minCompletions <= completions } ?? levels[0]
    }
}

// MARK: - Weaver Journey Manager

final class WeaverJourneyManager: ObservableObject {
    static let shared = WeaverJourneyManager()
    
    @AppStorage("weaverJourneyStartDate") private var journeyStartDateString: String = ""
    @Published private(set) var currentSeason: Season = Season.allSeasons[0]
    @Published private(set) var currentLevel: WeaverLevel = WeaverLevel.levels[0]
    @Published private(set) var daysSinceStart: Int = 0
    
    private var journeyStartDate: Date? {
        get {
            guard !journeyStartDateString.isEmpty else { return nil }
            return ISO8601DateFormatter().date(from: journeyStartDateString)
        }
        set {
            if let date = newValue {
                journeyStartDateString = ISO8601DateFormatter().string(from: date)
            } else {
                journeyStartDateString = ""
            }
        }
    }
    
    private init() {
        refreshJourney()
    }
    
    func startJourney() {
        if journeyStartDate == nil {
            journeyStartDate = Date()
            refreshJourney()
        }
    }
    
    func refreshJourney() {
        guard let startDate = journeyStartDate else {
            daysSinceStart = 0
            currentSeason = Season.allSeasons[0]
            currentLevel = WeaverLevel.levels[0]
            return
        }
        
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        daysSinceStart = max(1, days + 1)
        currentSeason = Season.current(for: daysSinceStart)
    }
    
    func updateLevel(totalCompletions: Int) {
        currentLevel = WeaverLevel.level(for: totalCompletions)
    }
    
    func calculateLevel(_ completions: Int) -> WeaverLevel {
        WeaverLevel.level(for: completions)
    }
    
    func checkAnniversary() -> AnniversaryMilestone? {
        AnniversaryMilestone.milestone(for: daysSinceStart)
    }
}

// MARK: - Invisible Achievement Manager

final class InvisibleAchievementManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Check for new invisible achievements based on user behavior
    func checkForNewAchievements(
        habits: [Habit],
        completions: [HabitCompletion]
    ) {
        checkMoonlightWeaver(completions: completions)
        checkGentleRebel(completions: completions)
        checkDawnComposer(completions: completions)
        checkWeekendWarrior(completions: completions)
        checkConsistentCompanion(completions: completions)
        checkQuietRevolution(completions: completions)
        checkSeasonalSage(completions: completions)
    }
    
    // MARK: - Individual Achievement Checks
    
    private func checkMoonlightWeaver(completions: [HabitCompletion]) {
        guard !completions.isEmpty else { return } // ✅ Prevent empty array crash

        let nightCompletions = completions.filter { completion in
            let hour = Calendar.current.component(.hour, from: completion.completedAt)
            return hour >= 21 || hour < 6
        }
        
        if nightCompletions.count >= 10 && !hasAchievement(type: "moonlight_weaver") {
            createAchievement(
                name: "Moonlight Weaver",
                story: "You completed 10 habits after 9pm, when most of the world sleeps. There's magic in the quiet hours—you've discovered it. Night weavers know something day weavers don't: darkness makes the threads glow brighter.",
                iconName: "moon.stars.fill",
                colorHex: "9B7EBD",
                triggerType: "moonlight_weaver"
            )
        }
    }
    
    private func checkGentleRebel(completions: [HabitCompletion]) {
        // Check for 3+ day gap followed by return
        let sortedCompletions = completions.sorted { $0.completedAt < $1.completedAt }

        guard sortedCompletions.count > 1 else { return } // ✅ Prevent invalid range

        for i in 1..<sortedCompletions.count {
            let previous = sortedCompletions[i-1].completedAt
            let current = sortedCompletions[i].completedAt
            let daysBetween = Calendar.current.dateComponents([.day], from: previous, to: current).day ?? 0
            
            if daysBetween >= 3 && !hasAchievement(type: "gentle_rebel") {
                createAchievement(
                    name: "Gentle Rebel",
                    story: "After a 3-day pause, you returned with just one habit. Not grand, but courageous. This is resilience—not never falling, but always rising. You've proven that setbacks are not endings, just pauses in the rhythm.",
                    iconName: "sparkles",
                    colorHex: "FFD18B",
                    triggerType: "gentle_rebel"
                )
                break
            }
        }
    }
    
    private func checkDawnComposer(completions: [HabitCompletion]) {
        guard completions.count > 1 else { return } // ✅ Prevent invalid range
        // Check for 5 consecutive morning completions
        let morningCompletions = completions.filter { completion in
            let hour = Calendar.current.component(.hour, from: completion.completedAt)
            return hour >= 5 && hour < 9
        }
        guard morningCompletions.count > 1 else { return } // ✅ Prevent invalid range

        let sortedMornings = morningCompletions.sorted { $0.completedAt < $1.completedAt }
        var consecutiveDays = 0
        var lastDate: Date?
        
        for completion in sortedMornings {
            if let last = lastDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: last, to: completion.completedAt).day ?? 0
                if daysBetween == 1 {
                    consecutiveDays += 1
                } else {
                    consecutiveDays = 1
                }
            } else {
                consecutiveDays = 1
            }
            lastDate = completion.completedAt
            
            if consecutiveDays >= 5 && !hasAchievement(type: "dawn_composer") {
                createAchievement(
                    name: "Dawn Composer",
                    story: "Five consecutive mornings, you greeted the day intentionally. The sunrise witnessed your commitment. Morning people aren't born—they're made through quiet, repeated choices. You've composed a new beginning.",
                    iconName: "sunrise.fill",
                    colorHex: "FFD18B",
                    triggerType: "dawn_composer"
                )
                break
            }
        }
    }
    
    private func checkWeekendWarrior(completions: [HabitCompletion]) {
        guard !completions.isEmpty else { return } // ✅ Prevent invalid range
        let weekendCompletions = completions.filter { completion in
            let weekday = Calendar.current.component(.weekday, from: completion.completedAt)
            return weekday == 1 || weekday == 7 // Sunday or Saturday
        }
        
        if weekendCompletions.count >= 8 && !hasAchievement(type: "weekend_warrior") {
            createAchievement(
                name: "Weekend Warrior",
                story: "Eight weekend habits completed when others rest. You've learned that rest and practice can coexist—weekends aren't for abandoning intention, but for weaving it differently. Balance found.",
                iconName: "figure.run",
                colorHex: "A8B5A0",
                triggerType: "weekend_warrior"
            )
        }
    }
    
    private func checkConsistentCompanion(completions: [HabitCompletion]) {
        guard !completions.isEmpty else { return } // ✅ Prevent invalid range
        // Check for same habit completed 30 times
        let habitFrequency = Dictionary(grouping: completions, by: { $0.habitId })
        
        for (_, habitCompletions) in habitFrequency {
            if habitCompletions.count >= 30 && !hasAchievement(type: "consistent_companion") {
                createAchievement(
                    name: "Consistent Companion",
                    story: "One habit, thirty times. This is devotion made visible. While others chase novelty, you've discovered the depth available in repetition. Mastery lives here.",
                    iconName: "heart.fill",
                    colorHex: "D4A5A5",
                    triggerType: "consistent_companion"
                )
                break
            }
        }
    }
    
    private func checkQuietRevolution(completions: [HabitCompletion]) {
        guard completions.count >= 100 else { return } // ✅ Prevent unnecessary processing

        // 100 total completions without fanfare
        if completions.count >= 100 && !hasAchievement(type: "quiet_revolution") {
            createAchievement(
                name: "Quiet Revolution",
                story: "One hundred completions. No one threw you a parade. You didn't need one. This is the quiet revolution—changing yourself changes the world. Thread by thread, you're rewriting your story.",
                iconName: "leaf.fill",
                colorHex: "A8B5A0",
                triggerType: "quiet_revolution"
            )
        }
    }
    
    private func checkSeasonalSage(completions: [HabitCompletion]) {
            guard !completions.isEmpty else { return } // ✅ Prevent unnecessary processing
        // Completed habits in all 4 seasons of the year
        let seasons = Set(completions.map { completion in
            let month = Calendar.current.component(.month, from: completion.completedAt)
            switch month {
            case 3...5: return "spring"
            case 6...8: return "summer"
            case 9...11: return "autumn"
            default: return "winter"
            }
        })
        
        if seasons.count >= 4 && !hasAchievement(type: "seasonal_sage") {
            createAchievement(
                name: "Seasonal Sage",
                story: "You've woven through all four seasons. Spring's enthusiasm, summer's consistency, autumn's harvest, winter's rest—you've known them all. This is wisdom: understanding that practice adapts to life's cycles.",
                iconName: "snowflake",
                colorHex: "B8C5D6",
                triggerType: "seasonal_sage"
            )
        }
    }
    
    // MARK: - Helpers
    
    private func hasAchievement(type: String) -> Bool {
        let descriptor = FetchDescriptor<InvisibleAchievement>(
            predicate: #Predicate<InvisibleAchievement> { achievement in
                achievement.triggerType == type
            }
        )
        
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }
    
    private func createAchievement(
        name: String,
        story: String,
        iconName: String,
        colorHex: String,
        triggerType: String
    ) {
        let achievement = InvisibleAchievement(
            name: name,
            story: story,
            iconName: iconName,
            colorHex: colorHex,
            triggerType: triggerType
        )
        
        modelContext.insert(achievement)
        try? modelContext.save()
        
        // Post notification for UI to show discovery
        NotificationCenter.default.post(
            name: NSNotification.Name("InvisibleAchievementDiscovered"),
            object: achievement
        )
        
        ReverieHaptics.successFeedback()
    }
}

// MARK: - Constellation Manager

final class ConstellationManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func initializeConstellations() {
        // Check if constellations already exist
        let descriptor = FetchDescriptor<ConstellationBadge>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        if existingCount == 0 {
            // Insert all constellations
            for constellation in ConstellationData.allConstellations {
                modelContext.insert(constellation)
            }
            try? modelContext.save()
        }
    }
    
    func checkUnlocks(habits: [Habit], completions: [HabitCompletion]) {
        let descriptor = FetchDescriptor<ConstellationBadge>()
        guard let allConstellations = try? modelContext.fetch(descriptor) else { return }
        
        for constellation in allConstellations where !constellation.isUnlocked {
            let categoryCompletions = completions.filter { completion in
                if let habit = habits.first(where: { $0.id == completion.habitId }) {
                    return habit.category == constellation.category
                }
                return false
            }
            
            if categoryCompletions.count >= constellation.completionsRequired {
                constellation.isUnlocked = true
                constellation.unlockedDate = Date()
                
                // Post notification for UI
                NotificationCenter.default.post(
                    name: NSNotification.Name("ConstellationUnlocked"),
                    object: constellation
                )
                
                ReverieHaptics.successFeedback()
            }
        }
        
        try? modelContext.save()
    }
}
