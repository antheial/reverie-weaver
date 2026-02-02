//
//  VitalityPhase.swift
//  Reverie Weaver
//
//

import SwiftUI
import SwiftData

// MARK: - Enums
enum VitalityPhase: String, Codable, CaseIterable {
    case activation = "Awaken"   // Weeks 1-2
    case endurance = "Ignite"    // Weeks 3-4
    case strength = "Sculpt"     // Weeks 5-6
    case integration = "Flow"    // Weeks 7-8
    
    var colorHex: String {
        switch self {
        case .activation: return "B8D4C8"
        case .endurance: return "F4C1A4"
        case .strength: return "D4B896"
        case .integration: return "9BB5CE"
        }
    }
    
    var focus: String {
        switch self {
        case .activation: return "Neuromuscular Connection & Mobility"
        case .endurance: return "Core Stability & Muscular Stamina"
        case .strength: return "Mechanical Tension & Definition"
        case .integration: return "Functional Movement & Athleticism"
        }
    }
}

// MARK: - Program Structure
struct VitalityProgram: Identifiable, Codable {
    var id: String = "vitality-arc-8week"
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    
    var schedule: [VitalityDay]
    
    var totalDays: Int {
        schedule.count
    }
    
    var totalWeeks: Int {
        (totalDays + 6) / 7
    }
    
    var isFeiProgram: Bool {
        id == "fei-strength-arc-4week"
    }
    
    func phase(for dayNumber: Int) -> VitalityPhase {
        if id == "vitality-arc-8week" {
            switch dayNumber {
            case 1...14: return .activation
            case 15...28: return .endurance
            case 29...42: return .strength
            default: return .integration
            }
        } else {
            return .strength
        }
    }
    
    // Get week number for a given day
    func week(for dayNumber: Int) -> Int {
        (dayNumber - 1) / 7 + 1
    }
    
    // Get days for a specific week
    func days(forWeek week: Int) -> [VitalityDay] {
        schedule.filter { day in
            self.week(for: day.dayNumber) == week
        }
    }
    
    // Get days for a specific phase (Vitality Arc only)
    func days(forPhase phase: VitalityPhase) -> [VitalityDay] {
        schedule.filter { $0.phase == phase }
    }
}

// MARK: - Daily Session

struct VitalityDay: Identifiable, Codable, Hashable {
    var id = UUID()
    let dayNumber: Int
    let phase: VitalityPhase
    let title: String
    let focusArea: String
    let duration: Int
    
    let seedOption: String     // Rescue (RPE 1-3)
    let sproutOption: String   // Standard (RPE 4-7)
    let bloomOption: String    // Challenger (RPE 8-10)
    
    var isRestDay: Bool {
        title.contains("Rest") || title.contains("Recovery") || title.contains("Sleep")
    }
    
    func tierDescription(for tier: CompletionTier) -> String {
        switch tier {
        case .seed: return seedOption
        case .sprout: return sproutOption
        case .bloom: return bloomOption
        }
    }
    
    var weekNumber: Int {
        (dayNumber - 1) / 7 + 1
    }
    
    var dayOfWeek: Int {
        ((dayNumber - 1) % 7) + 1
    }
}

// MARK: - Phase Metadata (UI Helper)

extension VitalityPhase {
    var displayName: String {
        switch self {
        case .activation: return "Awaken"
        case .endurance:  return "Ignite"
        case .strength:   return "Sculpt"
        case .integration:return "Flow"
        }
    }
    
    var weeksRangeLabel: String {
        switch self {
        case .activation: return "Weeks 1–2 · Days 1–14"
        case .endurance:  return "Weeks 3–4 · Days 15–28"
        case .strength:   return "Weeks 5–6 · Days 29–42"
        case .integration:return "Weeks 7–8 · Days 43–56"
        }
    }
    
    var dayRange: ClosedRange<Int> {
        switch self {
        case .activation: return 1...14
        case .endurance:  return 15...28
        case .strength:   return 29...42
        case .integration:return 43...56
        }
    }
    
    var overview: String {
        switch self {
        case .activation:
            return "You're teaching your body how to move again: joints get smoother, muscles wake up, and you build mind–muscle connection without heavy fatigue. Expect light soreness and a lot of \"oh, I didn't know that muscle existed.\""
        case .endurance:
            return "You're turning those newly awake muscles into steady engines. Sets get longer, heart rate comes up a little more, and you start to feel \"worked\" but not wrecked. Expect a warm, lasting burn and better posture/core control."
        case .strength:
            return "You layer in more resistance and intentional tension. This is where shape and definition come from: slower reps, heavier loads, deeper focus. Expect muscle fatigue, deeper sleep, and visible strength gains if you eat and recover well."
        case .integration:
            return "You stitch everything together into athletic, real-life movement. Think lunges that challenge balance, pushing/pulling, rotation, and play. Expect to feel coordinated, springy, and more confident in how your body moves through daily life."
        }
    }
    
    var trainingStyle: String {
        switch self {
        case .activation:
            return "Short sessions, controlled tempo, lots of floor work and mobility. You can train even if you're tired; intensity stays low–moderate."
        case .endurance:
            return "Longer sets, more repetitions, and simple circuits. You'll breathe a bit harder but should still be able to hold a light conversation."
        case .strength:
            return "Fewer, higher-quality sets with added load (bands, dumbbells). Rest periods matter; you'll feel a clear difference between working and resting."
        case .integration:
            return "Multi-planar moves, balance, and coordination. Mix of strength, light plyometrics (if on Bloom), and restorative decompression days."
        }
    }
    
    var recommendedEquipment: String {
        switch self {
        case .activation:
            return "Yoga mat or comfortable floor space, optional light mini-band."
        case .endurance:
            return "Mat, light dumbbells or resistance bands, sturdy chair or step."
        case .strength:
            return "Mat, medium dumbbells or heavier bands, optional bench or box."
        case .integration:
            return "Same as Sculpt, plus any soft ball/medicine ball for rotation work; optional foam roller for decompression days."
        }
    }
    
    var coachingNotes: String {
        switch self {
        case .activation:
            return "If your body feels stiff or clumsy, that's normal. Focus on smooth form over depth or range. Seed days count fully—consistency beats intensity."
        case .endurance:
            return "Your main job is to keep showing up, even if you choose Seed. Pace yourself so you finish sessions feeling like you could do a bit more."
        case .strength:
            return "Increase load only when you can perform all reps with controlled form. A little shaking in the final reps is okay; joint pain is not."
        case .integration:
            return "Flow is about quality and coordination. If plyometrics feel too much, drop to Seed/Sprout and keep the movements controlled and smooth."
        }
    }
    
    var icon: String {
        switch self {
        case .activation: return "figure.flexibility"
        case .endurance:  return "flame.fill"
        case .strength:   return "figure.strengthtraining.traditional"
        case .integration:return "figure.mind.and.body"
        }
    }
}
