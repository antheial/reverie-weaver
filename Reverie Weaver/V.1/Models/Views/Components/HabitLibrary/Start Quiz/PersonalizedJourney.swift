//
//  PersonalizedJourney.swift
//  Reverie Weaver
//

import Foundation
import SwiftData

// MARK: - User Goal

enum UserGoal: String, Codable, CaseIterable {
    case betterFocus = "Better Focus"
    case moreEnergy = "More Energy"
    case buildDiscipline = "Build Discipline"
    case reduceAnxiety = "Reduce Anxiety"
    case betterSleep = "Better Sleep"
    case improveRelationships = "Improve Relationships"
    case boostCreativity = "Boost Creativity"
    
    var icon: String {
        switch self {
        case .betterFocus: return "target"
        case .moreEnergy: return "bolt.fill"
        case .buildDiscipline: return "figure.mind.and.body"
        case .reduceAnxiety: return "heart.circle.fill"
        case .betterSleep: return "moon.stars.fill"
        case .improveRelationships: return "person.2.fill"
        case .boostCreativity: return "paintbrush.fill"
        }
    }
    
    var color: String {
        switch self {
        case .betterFocus: return "9B7EBD"
        case .moreEnergy: return "FFB347"
        case .buildDiscipline: return "8FBC8F"
        case .reduceAnxiety: return "7A9CC6"
        case .betterSleep: return "C8B8DB"
        case .improveRelationships: return "FF6B9D"
        case .boostCreativity: return "E8927C"
        }
    }
    
    var subtitle: String {
        switch self {
        case .betterFocus: return "Stop distractions, do deep work"
        case .moreEnergy: return "Wake up refreshed, stay energized"
        case .buildDiscipline: return "Build lasting habits & structure"
        case .reduceAnxiety: return "Find calm, regulate your nervous system"
        case .betterSleep: return "Rest deeply, wake naturally"
        case .improveRelationships: return "Connect deeply, show up fully"
        case .boostCreativity: return "Unlock flow, create freely"
        }
    }
}

// MARK: - Journey Step

struct JourneyStep: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let title: String
    let programTag: String
    let duration: String
    let reason: String
    var isCompleted: Bool = false
    var isUnlocked: Bool = false
}

// MARK: - Personalized Journey Model

@Model
class PersonalizedJourney {
    var id: UUID = UUID()
    var goalRawValue: String
    var currentStepIndex: Int = 0
    var stepsData: Data?
    var optionalBoostersData: Data?
    var createdAt: Date = Date()
    var isActive: Bool = true
    /// Date when journey was archived (set when user changes goal or completes journey)
    var archivedDate: Date?

    init(goal: UserGoal, steps: [JourneyStep], optionalBoosters: [String]) {
        self.goalRawValue = goal.rawValue
        self.stepsData = try? JSONEncoder().encode(steps)
        self.optionalBoostersData = try? JSONEncoder().encode(optionalBoosters)
        self.archivedDate = nil
    }
    
    // MARK: - Computed Properties
    
    var goal: UserGoal? {
        UserGoal(rawValue: goalRawValue)
    }
    
    var steps: [JourneyStep] {
        get {
            guard let data = stepsData else { return [] }
            return (try? JSONDecoder().decode([JourneyStep].self, from: data)) ?? []
        }
        set {
            stepsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var optionalBoosters: [String] {
        get {
            guard let data = optionalBoostersData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            optionalBoostersData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var currentStep: JourneyStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    var progressPercentage: Double {
        guard !steps.isEmpty else { return 0 }
        let completed = steps.filter { $0.isCompleted }.count
        return Double(completed) / Double(steps.count)
    }
    
    var totalDuration: String {
        let weeks = steps.count
        if weeks <= 4 {
            return "\(weeks) weeks"
        } else {
            let months = (weeks + 3) / 4 
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }
    
    // MARK: - Methods
    
    func completeCurrentStep() {
        guard currentStepIndex < steps.count else { return }
        var updatedSteps = steps
        updatedSteps[currentStepIndex].isCompleted = true
        
        // Unlock next step
        if currentStepIndex + 1 < steps.count {
            updatedSteps[currentStepIndex + 1].isUnlocked = true
        }
        
        steps = updatedSteps
        currentStepIndex += 1
    }
}

// MARK: - Journey Templates

struct JourneyTemplates {
    
    static func journey(for goal: UserGoal) -> PersonalizedJourney {
        switch goal {
            
        // MARK: - Better Focus
        case .betterFocus:
            return PersonalizedJourney(
                goal: .betterFocus,
                steps: [
                    JourneyStep(
                        title: "Week 1: Focus Mastery",
                        programTag: "FocusMasteryW1",
                        duration: "7 days",
                        reason: "Work with your brain, not against it—learn executive function strategies",
                        isCompleted: false,
                        isUnlocked: true
                    ),
                    JourneyStep(
                        title: "Week 2: Dopamine Detox",
                        programTag: "DopamineDetox",
                        duration: "7 days",
                        reason: "Reset your reward system for sustained attention",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 3: Digital Detox",
                        programTag: "DigitalDetoxW1",
                        duration: "7 days",
                        reason: "Reclaim your attention from screens and distractions",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Month 2-3: Project 50",
                        programTag: "Project50",
                        duration: "50 days",
                        reason: "Build deep work discipline with structured habits",
                        isCompleted: false,
                        isUnlocked: false
                    )
                ],
                optionalBoosters: ["BreathCalm", "MorningArchitect"]
            )
            
        // MARK: - More Energy
        case .moreEnergy:
            return PersonalizedJourney(
                goal: .moreEnergy,
                steps: [
                    JourneyStep(
                        title: "Week 1: Gentle Rhythm",
                        programTag: "GentleRhythmW1",
                        duration: "7 days",
                        reason: "Build sustainable daily rhythms with gentle movement and rest",
                        isCompleted: false,
                        isUnlocked: true
                    ),
                    JourneyStep(
                        title: "Week 2: Energy Recharge",
                        programTag: "EnergyRecharge",
                        duration: "7 days",
                        reason: "Optimize sleep and wake up refreshed",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 3: Movement Magic",
                        programTag: "MovementMagic",
                        duration: "7 days",
                        reason: "Boost energy through intentional movement",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Month 2-3: Project 50",
                        programTag: "Project50",
                        duration: "50 days",
                        reason: "Build sustainable energy habits for the long term",
                        isCompleted: false,
                        isUnlocked: false
                    )
                ],
                optionalBoosters: ["CircadianReset", "NatureThread"]
            )
            
        // MARK: - Build Discipline
        case .buildDiscipline:
            return PersonalizedJourney(
                goal: .buildDiscipline,
                steps: [
                    JourneyStep(
                        title: "Week 1: Gentle Rhythm",
                        programTag: "GentleRhythmW1",
                        duration: "7 days",
                        reason: "Build daily rhythm with micro-wins—show up however you can",
                        isCompleted: false,
                        isUnlocked: true
                    ),
                    JourneyStep(
                        title: "Week 2: Focus Mastery",
                        programTag: "FocusMasteryW1",
                        duration: "7 days",
                        reason: "Develop executive function skills for consistent action",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 3: Dopamine Detox",
                        programTag: "DopamineDetox",
                        duration: "7 days",
                        reason: "Learn delayed gratification—the heart of discipline",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Month 2-3: Project 50",
                        programTag: "Project50",
                        duration: "50 days",
                        reason: "Master the 8 core habits of discipline",
                        isCompleted: false,
                        isUnlocked: false
                    )
                ],
                optionalBoosters: ["MorningArchitect", "BoundaryBootcamp"]
            )
            
        // MARK: - Reduce Anxiety
        case .reduceAnxiety:
            return PersonalizedJourney(
                goal: .reduceAnxiety,
                steps: [
                    JourneyStep(
                        title: "Week 1: Breath & Calm",
                        programTag: "BreathCalm",
                        duration: "7 days",
                        reason: "Learn simple breathing practices to find calm",
                        isCompleted: false,
                        isUnlocked: true
                    ),
                    JourneyStep(
                        title: "Week 2: Nervous System Reset",
                        programTag: "NervousSystemReset",
                        duration: "7 days",
                        reason: "Build awareness and regulation tools",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 3: Slow Down",
                        programTag: "SlowDownW1",
                        duration: "7 days",
                        reason: "Unhook from urgency and find your natural pace",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 4: Reflection Reset",
                        programTag: "ReflectionReset",
                        duration: "7 days",
                        reason: "Process emotions with self-compassion",
                        isCompleted: false,
                        isUnlocked: false
                    )
                ],
                optionalBoosters: ["NatureThread", "JoyScavenger"]
            )
            
        // MARK: - Better Sleep
        case .betterSleep:
            return PersonalizedJourney(
                goal: .betterSleep,
                steps: [
                    JourneyStep(
                        title: "Week 1: Energy Recharge",
                        programTag: "EnergyRecharge",
                        duration: "7 days",
                        reason: "Optimize your sleep habits and wind-down routine",
                        isCompleted: false,
                        isUnlocked: true
                    ),
                    JourneyStep(
                        title: "Week 2: Digital Detox",
                        programTag: "DigitalDetoxW1",
                        duration: "7 days",
                        reason: "Remove screen interference from your sleep cycle",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 3: Breath & Calm",
                        programTag: "BreathCalm",
                        duration: "7 days",
                        reason: "Evening breathing rituals for better rest",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Month 2-3: Project 50",
                        programTag: "Project50",
                        duration: "50 days",
                        reason: "Build consistent sleep-supporting habits",
                        isCompleted: false,
                        isUnlocked: false
                    )
                ],
                optionalBoosters: ["CircadianReset", "EveningSanctuary"]
            )
            
        // MARK: - Improve Relationships
        case .improveRelationships:
            return PersonalizedJourney(
                goal: .improveRelationships,
                steps: [
                    JourneyStep(
                        title: "Week 1: Connection Clarity",
                        programTag: "ConnectionClarityW1",
                        duration: "7 days",
                        reason: "Build communication skills and find your voice in relationships",
                        isCompleted: false,
                        isUnlocked: true
                    ),
                    JourneyStep(
                        title: "Week 2: Digital Detox",
                        programTag: "DigitalDetoxW1",
                        duration: "7 days",
                        reason: "Reclaim attention for real relationships",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 3: Reflection Reset",
                        programTag: "ReflectionReset",
                        duration: "7 days",
                        reason: "Understand yourself to understand others",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 4: Gratitude Glow",
                        programTag: "GratitudeGlow",
                        duration: "7 days",
                        reason: "Notice and appreciate the people in your life",
                        isCompleted: false,
                        isUnlocked: false
                    )
                ],
                optionalBoosters: ["ConnectionWeek", "BoundaryBootcamp"]
            )
            
        // MARK: - Boost Creativity
        case .boostCreativity:
            return PersonalizedJourney(
                goal: .boostCreativity,
                steps: [
                    JourneyStep(
                        title: "Week 1: Creative Flow",
                        programTag: "CreativeFlow",
                        duration: "7 days",
                        reason: "Make something daily—no perfection required",
                        isCompleted: false,
                        isUnlocked: true
                    ),
                    JourneyStep(
                        title: "Week 2: Reflection Reset",
                        programTag: "ReflectionReset",
                        duration: "7 days",
                        reason: "Clear mental clutter through writing",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Week 3: Dopamine Detox",
                        programTag: "DopamineDetox",
                        duration: "7 days",
                        reason: "Boredom is where creativity lives",
                        isCompleted: false,
                        isUnlocked: false
                    ),
                    JourneyStep(
                        title: "Month 2-3: Project 50",
                        programTag: "Project50",
                        duration: "50 days",
                        reason: "Build deep work habits for sustained creativity",
                        isCompleted: false,
                        isUnlocked: false
                    )
                ],
                optionalBoosters: ["NatureThread", "MovementMagic"]
            )
        }
    }
}

// MARK: - Goal Time Estimates
extension UserGoal {
    var dailyCommitment: String {
        switch self {
        case .betterFocus:
            return "~15 mins"       // Mostly mindfulness & focus timers
        case .moreEnergy:
            return "~30 mins"       // Likely includes movement/light workouts
        case .buildDiscipline:
            return "~20-45 mins"       // Intensive (Project 50, rigorous habits)
        case .reduceAnxiety:
            return "~10 mins"       // Breathing & grounding (quick relief)
        case .betterSleep:
            return "~20 mins"       // Evening wind-down routines
        case .improveRelationships:
            return "~20 mins"       // Connection prompts & reflection
        case .boostCreativity:
            return "~25 mins"       // Daily creative exercises
        }
    }
}
