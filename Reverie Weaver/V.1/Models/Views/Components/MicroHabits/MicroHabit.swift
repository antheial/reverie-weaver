//
//  MicroHabit.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/20/25.
//


//
// MicroHabit.swift (Updated)
// ReverieWeaver
//
// Enhanced quick actions with progression tracking
//

import SwiftUI

struct MicroHabit: Identifiable {
    let id = UUID()
    let titleKey: String
    let durationKey: String
    let category: HabitCategory // Changed from String
    let timePeriod: String
    
    var title: String {
        LocalizationManager.shared.localize(titleKey)
    }
    
    var duration: String {
        LocalizationManager.shared.localize(durationKey)
    }
    
    // MORNING (6 AM - 12 PM) - 13 actions
    static let morningHabits: [MicroHabit] = [
        // Energy & Presence
        MicroHabit(titleKey: "micro.morning.curtains", durationKey: "micro.duration.1min", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.water", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.stretch", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Morning"),
        
        // Mindfulness & Intention
        MicroHabit(titleKey: "micro.morning.meditate", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.gratitude", durationKey: "micro.duration.3min", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.write", durationKey: "micro.duration.2min", category: .creativePractice, timePeriod: "Morning"),
        
        // Preparation
        MicroHabit(titleKey: "micro.morning.bed", durationKey: "micro.duration.2min", category: .morningRituals, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.tidy", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Morning"),
        
        // NEW: Physical Health & Mental Wellness
        MicroHabit(titleKey: "micro.morning.yoga", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.affirmations", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Morning"),
        
        // NEW: Learning & Creativity
        MicroHabit(titleKey: "micro.morning.podcast", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Morning"),
        MicroHabit(titleKey: "micro.morning.sketch", durationKey: "micro.duration.3min", category: .creativePractice, timePeriod: "Morning"),
        
        // NEW: Social Connection
        MicroHabit(titleKey: "micro.morning.message", durationKey: "micro.duration.2min", category: .connection, timePeriod: "Morning")
    ]
    
    // AFTERNOON (12 PM - 6 PM) - 13 actions
    static let afternoonHabits: [MicroHabit] = [
        // Movement & Energy
        MicroHabit(titleKey: "micro.afternoon.walk", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.jumping", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.stretch", durationKey: "micro.duration.3min", category: .healthFoundations, timePeriod: "Afternoon"),
        
        // Nourishment & Care
        MicroHabit(titleKey: "micro.afternoon.fruit", durationKey: "micro.duration.2min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.meditate", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Afternoon"),
        
        // Growth & Connection
        MicroHabit(titleKey: "micro.afternoon.learn", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.doodle", durationKey: "micro.duration.3min", category: .creativePractice, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.text", durationKey: "micro.duration.2min", category: .connection, timePeriod: "Afternoon"),
        
        // NEW: Physical Health & Mental Wellness
        MicroHabit(titleKey: "micro.afternoon.posture", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.breathwork", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Afternoon"),
        
        // NEW: Learning & Creativity
        MicroHabit(titleKey: "micro.afternoon.language", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Afternoon"),
        MicroHabit(titleKey: "micro.afternoon.music", durationKey: "micro.duration.3min", category: .creativePractice, timePeriod: "Afternoon"),
        
        // NEW: Social Connection
        MicroHabit(titleKey: "micro.afternoon.call", durationKey: "micro.duration.5min", category: .connection, timePeriod: "Afternoon")
    ]
    
    // EVENING (6 PM - 12 AM) - 13 actions
    static let eveningHabits: [MicroHabit] = [
        // Wind-down & Reflection
        MicroHabit(titleKey: "micro.evening.journal", durationKey: "micro.duration.3min", category: .creativePractice, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.gratitude", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.read", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Evening"),
        
        // Preparation & Order
        MicroHabit(titleKey: "micro.evening.putaway", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.plan", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.clothes", durationKey: "micro.duration.2min", category: .morningRituals, timePeriod: "Evening"),
        
        // Self-care
        MicroHabit(titleKey: "micro.evening.hygiene", durationKey: "micro.duration.3min", category: .healthFoundations, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.stretch", durationKey: "micro.duration.5min", category: .healthFoundations, timePeriod: "Evening"),
        
        // NEW: Physical Health & Mental Wellness
        MicroHabit(titleKey: "micro.evening.selfmassage", durationKey: "micro.duration.3min", category: .healthFoundations, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.visualization", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Evening"),
        
        // NEW: Creativity & Learning
        MicroHabit(titleKey: "micro.evening.draw", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Evening"),
        MicroHabit(titleKey: "micro.evening.article", durationKey: "micro.duration.5min", category: .creativePractice, timePeriod: "Evening"),
        
        // NEW: Social Connection
        MicroHabit(titleKey: "micro.evening.family", durationKey: "micro.duration.5min", category: .connection, timePeriod: "Evening")
    ]
    
    // NIGHT (12 AM - 6 AM) - 8 actions
    static let nightHabits: [MicroHabit] = [
        MicroHabit(titleKey: "micro.night.breathing", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Night"),
        MicroHabit(titleKey: "micro.night.write", durationKey: "micro.duration.2min", category: .creativePractice, timePeriod: "Night"),
        MicroHabit(titleKey: "micro.night.neck", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Night"),
        MicroHabit(titleKey: "micro.night.tea", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Night"),
        MicroHabit(titleKey: "micro.night.reflect", durationKey: "micro.duration.2min", category: .mindfulLiving, timePeriod: "Night"),
        
        // NEW: Physical Health & Mental Wellness
        MicroHabit(titleKey: "micro.night.bodyscan", durationKey: "micro.duration.3min", category: .mindfulLiving, timePeriod: "Night"),
        MicroHabit(titleKey: "micro.night.eyerelax", durationKey: "micro.duration.1min", category: .healthFoundations, timePeriod: "Night"),
        
        // NEW: Creativity
        MicroHabit(titleKey: "micro.night.dreamjournal", durationKey: "micro.duration.2min", category: .creativePractice, timePeriod: "Night")
    ]
}
