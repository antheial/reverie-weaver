//
// MicroHabit.swift
// ReverieWeaver
//
// Enhanced quick actions with progression tracking & Safe Localization
//

import SwiftUI

struct MicroHabit: Identifiable {
    let id = UUID()
    let titleKey: String
    let durationKey: String
    let category: HabitCategory
    let timePeriod: String
    
    var title: String {
        let localized = LocalizationManager.shared.localize(titleKey)
        if localized == titleKey {
            return titleKey.components(separatedBy: ".").last?.capitalized ?? titleKey
        }
        return localized
    }
    
    var duration: String {
        LocalizationManager.shared.localize(durationKey)
    }
    
    // MORNING (6 AM - 12 PM) - Energy & Intention Setting
    static let morningHabits: [MicroHabit] = [
        // Ultra-Low-Friction (ADHD-friendly, 30 sec - 1 min, no movement required)
        MicroHabit(titleKey: "micro.morning.threebreaths", durationKey: "micro.duration.30sec", category: .mindfulLiving, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.wiggle", durationKey: "micro.duration.30sec", category: .healthFoundations, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.seethree", durationKey: "micro.duration.30sec", category: .mindfulLiving, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.window", durationKey: "micro.duration.30sec", category: .mindfulLiving, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.emoji", durationKey: "micro.duration.30sec", category: .connection, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.onepillow", durationKey: "micro.duration.30sec", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.onething", durationKey: "micro.duration.30sec", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.outfit", durationKey: "micro.duration.1min", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.quickstretch", durationKey: "micro.duration.30sec", category: .healthFoundations, timePeriod: "Morning"),

        // Energy & Presence
        MicroHabit(titleKey: "micro.morning.curtains", durationKey: "micro.duration.1min", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.water", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.sunlight", durationKey: "micro.duration.2min", category: .healthFoundations, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.coldsplash", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.stretch", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.yoga", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Morning"),

        // Mindfulness & Intention
        MicroHabit(titleKey: "micro.morning.meditate", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.gratitude", durationKey: "micro.duration.3min", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.intention", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.braindump", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.affirmations", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Morning"),

        // Preparation & Organization
        MicroHabit(titleKey: "micro.morning.bed", durationKey: "micro.duration.2min", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.tidy", durationKey: "micro.duration.3min", category: .morningRituals, timePeriod: "Morning"),

        // Nourishment
        MicroHabit(titleKey: "micro.morning.breakfast", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Morning"),

        // Journaling & Creativity
        MicroHabit(titleKey: "micro.morning.write", durationKey: "micro.duration.2min", category: .creativePractice, timePeriod: "Morning"),

        // Social Connection
        MicroHabit(titleKey: "micro.morning.message", durationKey: "micro.duration.2min", category: .connection, timePeriod: "Morning"),

        // Nature Connection
        MicroHabit(titleKey: "micro.morning.plant", durationKey: "micro.duration.1min", category: .mindfulLiving, timePeriod: "Morning"),
    ]
    
    // AFTERNOON (12 PM - 6 PM) - Sustained Energy & Productivity
    static let afternoonHabits: [MicroHabit] = [
        // Movement & Energy
        MicroHabit(titleKey: "micro.afternoon.walk", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.jumping", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.stretch", durationKey: "micro.duration.3min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.stand", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Afternoon"), // Just stand up
        
        // Nourishment & Care
        MicroHabit(titleKey: "micro.afternoon.fruit", durationKey: "micro.duration.2min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.nuts", durationKey: "micro.duration.2min", category: .healthFoundations, timePeriod: "Afternoon"), // Energy-boosting snack
        MicroHabit(titleKey: "micro.afternoon.mindful_lunch", durationKey: "micro.duration.5min", category: .mindfulLiving, timePeriod: "Afternoon"), // Away from screen
        MicroHabit(titleKey: "micro.afternoon.meditate", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.breathwork", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Afternoon"),
        
        // Physical Health & Ergonomics
        MicroHabit(titleKey: "micro.afternoon.posture", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.eyes", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Afternoon"), // 20-20-20 rule
        
        // Workspace & Organization
        MicroHabit(titleKey: "micro.afternoon.declutter", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Afternoon"), // Clear physical desktop
        MicroHabit(titleKey: "micro.afternoon.workspace", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Afternoon"), // Refresh workspace
        
        // Growth & Learning
        MicroHabit(titleKey: "micro.afternoon.learn", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.language", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.sketch", durationKey: "micro.duration.3min", category: .creativePractice, timePeriod: "Afternoon"), // Moved from morning
        MicroHabit(titleKey: "micro.afternoon.doodle", durationKey: "micro.duration.3min", category: .creativePractice, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.music", durationKey: "micro.duration.3min", category: .creativePractice, timePeriod: "Afternoon"),
        
        // Progress & Reflection
        MicroHabit(titleKey: "micro.afternoon.progress", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Afternoon"), // Review goals
        
        // Social Connection
        MicroHabit(titleKey: "micro.afternoon.text", durationKey: "micro.duration.2min", category: .connection, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.call", durationKey: "micro.duration.5min", category: .connection, timePeriod: "Afternoon"),
    ]
    
    // EVENING (6 PM - 12 AM) - Wind-Down & Reflection
    static let eveningHabits: [MicroHabit] = [
        // Wind-down & Reflection
        MicroHabit(titleKey: "micro.evening.journal", durationKey: "micro.duration.3min", category: .creativePractice, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.gratitude", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.wins", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Evening"), // Celebrate small wins
        MicroHabit(titleKey: "micro.evening.read", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.article", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Evening"),
        
        // Preparation for Tomorrow
        MicroHabit(titleKey: "micro.evening.putaway", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.plan", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.clothes", durationKey: "micro.duration.2min", category: .morningRituals, timePeriod: "Evening"),
        
        // Digital & Mental Hygiene
        MicroHabit(titleKey: "micro.evening.digital_sunset", durationKey: "micro.duration.1min", category: .mindfulLiving, timePeriod: "Evening"), // Turn off work notifications
        MicroHabit(titleKey: "micro.evening.dim_lights", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Evening"), // Warmer lighting
        
        // Self-care & Wellness
        MicroHabit(titleKey: "micro.evening.hygiene", durationKey: "micro.duration.3min", category: .healthFoundations, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.stretch", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.selfmassage", durationKey: "micro.duration.3min", category: .healthFoundations, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.visualization", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Evening"),
        
        // Creativity
        MicroHabit(titleKey: "micro.evening.draw", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Evening"),
        
        // Social Connection
        MicroHabit(titleKey: "micro.evening.family", durationKey: "micro.duration.5min", category: .connection, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.share", durationKey: "micro.duration.3min", category: .connection, timePeriod: "Evening"), // Share one thing from day
    ]
    
    // PRE-SLEEP (9 PM - 12 AM) - Sleep Preparation & Recovery
    static let preSleepHabits: [MicroHabit] = [
        // Breathing & Relaxation
        MicroHabit(titleKey: "micro.presleep.breathing", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Pre-Sleep"),
        MicroHabit(titleKey: "micro.presleep.bodyscan", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Pre-Sleep"),
        MicroHabit(titleKey: "micro.presleep.progressive_relaxation", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Pre-Sleep"), // Progressive muscle relaxation
        
        // Physical Comfort
        MicroHabit(titleKey: "micro.presleep.neck", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Pre-Sleep"),
        MicroHabit(titleKey: "micro.presleep.eyerelax", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Pre-Sleep"),
        
        // Sleep Environment Optimization
        MicroHabit(titleKey: "micro.presleep.charge", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Pre-Sleep"), // Phone away from bed
        MicroHabit(titleKey: "micro.presleep.temp", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Pre-Sleep"), // Lower room temperature
        MicroHabit(titleKey: "micro.presleep.sounds", durationKey: "micro.duration.1min", category: .mindfulLiving, timePeriod: "Pre-Sleep"), // White noise/silence
        MicroHabit(titleKey: "micro.presleep.dim", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Pre-Sleep"), // Dim all lights
        MicroHabit(titleKey: "micro.presleep.aromatherapy", durationKey: "micro.duration.1min", category: .mindfulLiving, timePeriod: "Pre-Sleep"), // Lavender/calming scents
        
        // Mental Wind-Down
        MicroHabit(titleKey: "micro.presleep.write", durationKey: "micro.duration.2min", category: .creativePractice, timePeriod: "Pre-Sleep"),
        MicroHabit(titleKey: "micro.presleep.dreamjournal", durationKey: "micro.duration.2min", category: .creativePractice, timePeriod: "Pre-Sleep"),
        MicroHabit(titleKey: "micro.presleep.reflect", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Pre-Sleep"),
        MicroHabit(titleKey: "micro.presleep.sleep_gratitude", durationKey: "micro.duration.1min", category: .mindfulLiving, timePeriod: "Pre-Sleep"), // 3 things from today
        
        // Preparation for Tomorrow
        MicroHabit(titleKey: "micro.presleep.friction", durationKey: "micro.duration.1min", category: .morningRituals, timePeriod: "Pre-Sleep"), // Water/book for morning
        
        // Calming Rituals
        MicroHabit(titleKey: "micro.presleep.tea", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Pre-Sleep"),
    ]
}
