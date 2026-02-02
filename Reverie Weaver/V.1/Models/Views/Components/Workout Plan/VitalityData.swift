//
//  VitalityData.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/30/25.
//

import Foundation

struct VitalityData {
    
    static let program = VitalityProgram(
        title: "The Vitality Arc",
        subtitle: "8-Week Body Recomposition",
        description: "A phased scientific journey from mobility to strength. Designed to tone without burnout using the Seed/Sprout/Bloom auto-regulation system.",
        icon: "figure.mind.and.body",
        schedule: generateSchedule()
    )
    
    // MARK: - 4-Week Fei Strength Bonus Program
        static let feiProgram = VitalityProgram(
            id: "fei-strength-arc-4week",
            title: "Fei Strength Arc",
            subtitle: "4-Week Bonus Strength",
            description: "A linear strength block designed to be used after Flow. Focuses on hypertrophy, progressive overload, and specific structural balance.",
            icon: "dumbbell.fill",
            schedule: generateFeiStrengthBonusSchedule()
        )
    
    // MARK: - Schedule Generator (Main 8-week Arc)
    static func generateSchedule() -> [VitalityDay] {
        var days: [VitalityDay] = []
        
        for day in 1...56 {
            let phase: VitalityPhase
            switch day {
            case 1...14: phase = .activation
            case 15...28: phase = .endurance
            case 29...42: phase = .strength
            default: phase = .integration
            }
            
            days.append(createDay(day, phase: phase))
        }
        return days
    }
    
    // MARK: - Fei Coach Bonus Strength Arc (4 weeks · 28 days)
    // Optional 4-week linear strength block designed to be used
    // *after Flow* as bonus “Fei Coach Strength Journey”.
    // - Returns: 28-day array (week 1–4, day 1–7).
    static func generateFeiStrengthBonusSchedule() -> [VitalityDay] {
        return (1...28).map { createFeiStrengthBonusDay($0) }
    }

    // MARK: - Day Logic Factory (Main Vitality Arc)
    private static func createDay(_ number: Int, phase: VitalityPhase) -> VitalityDay {
        let script = VitalityArcRichContentFactory.make(forDay: number, phase: phase)
        
        return VitalityDay(
            dayNumber: number,
            phase: phase,
            title: script.title,
            focusArea: script.focusArea,
            duration: script.durationMinutes,
            seedOption: script.seed,
            sproutOption: script.sprout,
            bloomOption: script.bloom
        )
    }

    // MARK: - Rest Helper
    
    private static func restDay(_ number: Int, phase: VitalityPhase) -> VitalityDay {
        VitalityDay(
            dayNumber: number,
            phase: phase,
            title: "Rest & Restore",
            focusArea: "Recovery",
            duration: 0,
            seedOption: """
            Who it's for: Everyone. Recovery is where growth happens.
            
            The Plan:
            • Drink a full glass of water.
            • Take 5 deep breaths.
            • Relax.
            """,
            sproutOption: """
            Who it's for: You want gentle movement.
            
            The Plan:
            • 20min Nature walk.
            • No headphones, just listen.
            """,
            bloomOption: """
            Who it's for: Active recovery.
            
            The Plan:
            • 30min Walk.
            • 10min Full body stretch.
            """
        )
    }
}

// MARK: - Bonus · Fei Coach Strength Arc Day Factory
//
// 4-week (28-day) linear strength block as an optional bonus arc
// Uses week (1–4) + cycleDay (1–7) to return a VitalityDay.
// Now delegates rich content to FeiStrengthRichContentFactory
//

extension VitalityData {
    fileprivate static func createFeiStrengthBonusDay(_ number: Int) -> VitalityDay {
        let week = (number - 1) / 7 + 1     // 1...4
        let cycleDay = (number - 1) % 7 + 1 // 1...7
        
        let rich = FeiStrengthRichContentFactory.make(forWeek: week, cycleDay: cycleDay)
        
        return VitalityDay(
            dayNumber: number,
            phase: .strength,
            title: rich.title,
            focusArea: rich.focusArea,
            duration: rich.durationMinutes,
            seedOption: rich.seed,
            sproutOption: rich.sprout,
            bloomOption: rich.bloom
        )
    }
}
