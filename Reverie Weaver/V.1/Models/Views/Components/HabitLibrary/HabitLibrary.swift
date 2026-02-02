//
// HabitLibrary.swift
// Reverie Weaver
//
// Complete habit template system with quick action integration
// Production Ready: Safe Enum coding, robust data structure
//

import SwiftUI
import SwiftData

// MARK: - Habit Category Enum
enum HabitCategory: String, CaseIterable, Codable {
    case morningRituals = "Morning Rituals"
    case healthFoundations = "Health Foundations"
    case mindfulLiving = "Mindful Living"
    case creativePractice = "Creative Practice"
    case connection = "Connection"
    
    var icon: String {
        switch self {
        case .morningRituals: return "sunrise.fill"
        case .healthFoundations: return "heart.fill"
        case .mindfulLiving: return "leaf.fill"
        case .creativePractice: return "paintbrush.fill"
        case .connection: return "person.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .morningRituals: return .sageGreen        // Soft sage
        case .healthFoundations: return .terracottaRose // Warm terracotta
        case .mindfulLiving: return .sageGreen          // Soft sage (alternate)
        case .creativePractice: return .paleMauve       // Gentle mauve
        case .connection: return .dustyBlue             // Calm dusty blue
        }
    }
    
    var colorHex: String {
        switch self {
        case .morningRituals: return "C9D2B5"
        case .healthFoundations: return "D9A58A"
        case .mindfulLiving: return "B8C7D6"
        case .creativePractice: return "E6D7D2"
        case .connection: return "C9D2B5"
        }
    }
    
    var description: String {
        switch self {
        case .morningRituals: return "Start your day with intention"
        case .healthFoundations: return "Build physical & mental wellness"
        case .mindfulLiving: return "Cultivate presence & awareness"
        case .creativePractice: return "Nurture your creative spirit"
        case .connection: return "Strengthen relationships"
        }
    }
}

// MARK: - Habit Template
struct HabitTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: HabitCategory
    let icon: String
    let description: String
    let quickActionKey: String?
    
    let systemTag: String?
    
    let suggestedFrequency: String
    let benefits: [String]
    let tips: String
    let estimatedMinutes: String
    
    // For creating actual Habit
    var colorHex: String { category.colorHex }
}

// MARK: - Complete Habit Library
struct HabitLibraryData {
    static let templates: [HabitTemplate] = [
        // MORNING RITUALS
        HabitTemplate(
            name: "Morning Meditation",
            category: .morningRituals,
            icon: "figure.mind.and.body",
            description: "Start your day with 5-10 minutes of mindful breathing and presence",
            quickActionKey: "micro.morning.meditate",
            systemTag: "Morning", // Links to Morning Star badge
            suggestedFrequency: "Daily",
            benefits: [
                "Reduces anxiety and morning stress",
                "Improves focus throughout the day",
                "Better emotional regulation"
            ],
            tips: "Start with just 2 minutes. Use a timer. Focus on your breath, not clearing your mind.",
            estimatedMinutes: "5-10 min"
        ),
        
        HabitTemplate(
            name: "Gratitude Practice",
            category: .morningRituals,
            icon: "heart.text.square",
            description: "Write down 3 things you're grateful for each morning",
            quickActionKey: "micro.morning.gratitude",
            systemTag: "Morning", // Links to Morning Star badge
            suggestedFrequency: "Daily",
            benefits: [
                "Increases happiness and life satisfaction",
                "Shifts focus to what's working well",
                "Builds resilience over time"
            ],
            tips: "Be specific. Include small moments. Feel the gratitude as you write.",
            estimatedMinutes: "3-5 min"
        ),
        
        HabitTemplate(
            name: "Morning Stretch",
            category: .morningRituals,
            icon: "figure.flexibility",
            description: "Gentle stretching to wake up your body and increase energy",
            quickActionKey: "micro.morning.stretch",
            systemTag: "Morning", // Links to Morning Star badge
            suggestedFrequency: "Daily",
            benefits: [
                "Increases blood flow and energy",
                "Reduces muscle tension",
                "Improves flexibility and mobility"
            ],
            tips: "Listen to your body. Never force a stretch. Breathe deeply.",
            estimatedMinutes: "5-10 min"
        ),
        
        HabitTemplate(
            name: "Make Your Bed",
            category: .morningRituals,
            icon: "bed.double.fill",
            description: "Complete one small task before starting your day",
            quickActionKey: "micro.morning.bed",
            systemTag: "Morning", // Links to Morning Star badge
            suggestedFrequency: "Daily",
            benefits: [
                "Starts day with accomplishment",
                "Creates sense of order",
                "Better sleep environment"
            ],
            tips: "Keep it simple. It doesn't need to be perfect. Just do it right away.",
            estimatedMinutes: "2 min"
        ),
        
        HabitTemplate(
            name: "Morning Pages",
            category: .morningRituals,
            icon: "pencil.and.list.clipboard",
            description: "Stream-of-consciousness writing for 10 minutes",
            quickActionKey: "micro.morning.write",
            systemTag: "Morning", // Links to Morning Star badge
            suggestedFrequency: "Daily",
            benefits: [
                "Clears mental clutter",
                "Processes emotions",
                "Sparks creativity"
            ],
            tips: "Don't edit. Write anything. No one will read it.",
            estimatedMinutes: "10 min"
        ),
        
        HabitTemplate(
            name: "Morning Reading",
            category: .morningRituals,
            icon: "book.fill",
            description: "Read something inspiring or educational for 10 minutes",
            quickActionKey: "micro.morning.read",
            systemTag: "Morning", // Links to Morning Star badge
            suggestedFrequency: "Daily",
            benefits: [
                "Sets positive tone for the day",
                "Continuous learning",
                "Alternative to scrolling"
            ],
            tips: "Physical books work best. Pick uplifting content. One page counts.",
            estimatedMinutes: "10-15 min"
        ),
        
        // HEALTH FOUNDATIONS
        HabitTemplate(
            name: "Daily Movement",
            category: .healthFoundations,
            icon: "figure.walk",
            description: "20-30 minutes of physical activity you enjoy",
            quickActionKey: "micro.afternoon.walk",
            systemTag: "Health",
            suggestedFrequency: "Daily",
            benefits: [
                "Boosts energy and mood significantly",
                "Improves sleep quality",
                "Reduces chronic disease risk"
            ],
            tips: "Pick something you enjoy. Start small. Movement counts, not intensity.",
            estimatedMinutes: "20-30 min"
        ),
        
        HabitTemplate(
            name: "Hydration Habit",
            category: .healthFoundations,
            icon: "drop.fill",
            description: "Drink 6-8 glasses of water throughout the day",
            quickActionKey: "micro.morning.water",
            systemTag: "Health",
            suggestedFrequency: "Daily",
            benefits: [
                "Better energy and mental clarity",
                "Improved skin health",
                "Aids digestion and detoxification"
            ],
            tips: "Keep water visible. Set phone reminders. Track your intake.",
            estimatedMinutes: "Throughout day"
        ),
        
        HabitTemplate(
            name: "Healthy Meal",
            category: .healthFoundations,
            icon: "carrot.fill",
            description: "Eat at least one nutritious, home-cooked meal",
            quickActionKey: "micro.afternoon.fruit",
            systemTag: "Health",
            suggestedFrequency: "Daily",
            benefits: [
                "More energy and stable mood",
                "Better long-term health",
                "Saves money over time"
            ],
            tips: "Meal prep on weekends. Keep it simple. Add one vegetable.",
            estimatedMinutes: "30-45 min"
        ),
        
        HabitTemplate(
            name: "Mindful Eating",
            category: .healthFoundations,
            icon: "fork.knife",
            description: "Eat one meal without screens, slowly and intentionally",
            quickActionKey: nil,
            systemTag: "Health",
            suggestedFrequency: "Daily",
            benefits: [
                "Better digestion",
                "More satisfaction from food",
                "Improved relationship with eating"
            ],
            tips: "Put phone away. Chew slowly. Notice flavors and textures.",
            estimatedMinutes: "20-30 min"
        ),
        
        HabitTemplate(
            name: "Sleep Schedule",
            category: .healthFoundations,
            icon: "bed.double.circle",
            description: "Go to bed and wake up at consistent times",
            quickActionKey: nil,
            systemTag: "Sleep", // Links to Energy Recharge / Rest badges
            suggestedFrequency: "Daily",
            benefits: [
                "Better sleep quality",
                "More energy during day",
                "Improved mood and focus"
            ],
            tips: "Start with wake time. Use gentle alarm. Be consistent on weekends.",
            estimatedMinutes: "7-9 hours"
        ),
        
        HabitTemplate(
            name: "Posture Check",
            category: .healthFoundations,
            icon: "figure.stand",
            description: "Check and correct your posture throughout the day",
            quickActionKey: nil,
            systemTag: "Health",
            suggestedFrequency: "3x daily",
            benefits: [
                "Reduces back and neck pain",
                "Improves breathing",
                "Increases confidence"
            ],
            tips: "Set hourly reminders. Shoulders back. Core engaged.",
            estimatedMinutes: "1 min"
        ),
        
        // MINDFUL LIVING
        HabitTemplate(
            name: "Evening Reflection",
            category: .mindfulLiving,
            icon: "moon.stars",
            description: "Spend 5 minutes reviewing your day with kindness",
            quickActionKey: "micro.evening.journal",
            systemTag: "Mindfulness",
            suggestedFrequency: "Daily",
            benefits: [
                "Process emotions healthily",
                "Learn from experiences",
                "Better self-awareness"
            ],
            tips: "No judgment. Celebrate wins. Note one lesson learned.",
            estimatedMinutes: "5 min"
        ),
        
        HabitTemplate(
            name: "Digital Sunset",
            category: .mindfulLiving,
            icon: "iphone.slash",
            description: "No screens 1 hour before bed",
            quickActionKey: nil,
            systemTag: "Sleep",
            suggestedFrequency: "Daily",
            benefits: [
                "Significantly better sleep",
                "Reduced anxiety",
                "More present evenings"
            ],
            tips: "Set phone alarm. Create evening ritual. Read or stretch instead.",
            estimatedMinutes: "1 hour before bed"
        ),
        
        HabitTemplate(
            name: "Mindful Breathing",
            category: .mindfulLiving,
            icon: "wind",
            description: "3-5 minutes of focused breathing practice",
            quickActionKey: "micro.afternoon.meditate",
            systemTag: "Mindfulness",
            suggestedFrequency: "2x daily",
            benefits: [
                "Reduces stress immediately",
                "Lowers blood pressure",
                "Improves emotional regulation"
            ],
            tips: "4 counts in, 4 counts hold, 4 counts out. Do anywhere.",
            estimatedMinutes: "3-5 min"
        ),
        
        HabitTemplate(
            name: "Nature Time",
            category: .mindfulLiving,
            icon: "leaf",
            description: "Spend 15 minutes outside in nature",
            quickActionKey: "micro.afternoon.walk",
            systemTag: "Mindfulness",
            suggestedFrequency: "Daily",
            benefits: [
                "Reduces stress and anxiety",
                "Improves mood and focus",
                "Boosts immune system"
            ],
            tips: "No phone. Notice details. Even a park counts.",
            estimatedMinutes: "15-20 min"
        ),
        
        HabitTemplate(
            name: "Tidy Space",
            category: .mindfulLiving,
            icon: "sparkles",
            description: "Spend 10 minutes tidying your space",
            quickActionKey: "micro.morning.tidy",
            systemTag: "Mindfulness",
            suggestedFrequency: "Daily",
            benefits: [
                "Clearer mind and focus",
                "Reduced stress",
                "Easier to find things"
            ],
            tips: "Set timer. One area at a time. Put things in their homes.",
            estimatedMinutes: "10 min"
        ),
        
        HabitTemplate(
            name: "Single-Tasking",
            category: .mindfulLiving,
            icon: "scope",
            description: "Focus on one task at a time for 25 minutes",
            quickActionKey: nil,
            systemTag: "DeepWork", // Helps identifying focus moments
            suggestedFrequency: "Daily",
            benefits: [
                "Better quality work",
                "Less mental fatigue",
                "Greater sense of accomplishment"
            ],
            tips: "Close other tabs. Put phone away. Take breaks.",
            estimatedMinutes: "25 min"
        ),
        
        // CREATIVE PRACTICE
        HabitTemplate(
            name: "Daily Reading",
            category: .creativePractice,
            icon: "book.fill",
            description: "Read for 15-30 minutes for pleasure or learning",
            quickActionKey: "micro.evening.read",
            systemTag: "Creative",
            suggestedFrequency: "Daily",
            benefits: [
                "Expands knowledge and vocabulary",
                "Reduces stress significantly",
                "Improves focus and imagination"
            ],
            tips: "Physical books work best. Pick what excites you. No pressure to finish.",
            estimatedMinutes: "15-30 min"
        ),
        
        HabitTemplate(
            name: "Creative Expression",
            category: .creativePractice,
            icon: "paintbrush.fill",
            description: "Spend 20 minutes on any creative activity",
            quickActionKey: "micro.afternoon.doodle",
            systemTag: "Creative",
            suggestedFrequency: "3x weekly",
            benefits: [
                "Reduces stress and anxiety",
                "Boosts problem-solving",
                "Increases life satisfaction"
            ],
            tips: "No judgment. Process over product. Try different mediums.",
            estimatedMinutes: "20-30 min"
        ),
        
        HabitTemplate(
            name: "Learn Something New",
            category: .creativePractice,
            icon: "brain.head.profile",
            description: "Dedicate 15 minutes to learning a new skill",
            quickActionKey: "micro.afternoon.learn",
            systemTag: "Creative",
            suggestedFrequency: "Daily",
            benefits: [
                "Keeps mind sharp",
                "Builds confidence",
                "Opens new opportunities"
            ],
            tips: "Consistency beats intensity. Use apps or videos. Practice daily.",
            estimatedMinutes: "15-20 min"
        ),
        
        HabitTemplate(
            name: "Deep Work Hour",
            category: .creativePractice,
            icon: "timer",
            description: "Spend one uninterrupted hour on focused, high-value work without distractions",
            quickActionKey: nil,
            systemTag: "DeepWork", // Links to 'The Silent Deep' badge
            suggestedFrequency: "Daily",
            benefits: [
                "Builds deep focus and cognitive endurance",
                "Accelerates progress on meaningful goals",
                "Reduces mental clutter and task switching"
            ],
            tips: "Silence notifications. Use a timer. Choose one single, important task.",
            estimatedMinutes: "60 min"
        ),
        
        HabitTemplate(
            name: "Music Practice",
            category: .creativePractice,
            icon: "music.note",
            description: "Practice an instrument or singing",
            quickActionKey: nil,
            systemTag: "Creative",
            suggestedFrequency: "3x weekly",
            benefits: [
                "Boosts mood and reduces stress",
                "Improves cognitive function",
                "Sense of accomplishment"
            ],
            tips: "Start with 10 minutes. Focus on enjoyment. Consistency matters most.",
            estimatedMinutes: "20-30 min"
        ),
        
        HabitTemplate(
            name: "Journaling",
            category: .creativePractice,
            icon: "book.pages",
            description: "Free-write or prompted journaling",
            quickActionKey: "micro.evening.journal",
            systemTag: "Mindfulness",
            suggestedFrequency: "Daily",
            benefits: [
                "Process emotions and experiences",
                "Increased self-awareness",
                "Tracks personal growth"
            ],
            tips: "No rules. Write messy. Use prompts when stuck.",
            estimatedMinutes: "10-15 min"
        ),
        
        HabitTemplate(
            name: "Photo Journal",
            category: .creativePractice,
            icon: "camera.fill",
            description: "Take one intentional photo each day",
            quickActionKey: nil,
            systemTag: "Creative",
            suggestedFrequency: "Daily",
            benefits: [
                "Cultivates attention to beauty",
                "Creates visual memories",
                "Develops artistic eye"
            ],
            tips: "Find beauty in ordinary. Natural light is best. No filters needed.",
            estimatedMinutes: "5 min"
        ),
        
        // CONNECTION
        HabitTemplate(
            name: "Meaningful Conversation",
            category: .connection,
            icon: "bubble.left.and.bubble.right.fill",
            description: "Have a real conversation with someone you care about",
            quickActionKey: "micro.afternoon.text",
            systemTag: "Connection", // Links to Crystal Drop badge
            suggestedFrequency: "Daily",
            benefits: [
                "Strengthens relationships",
                "Reduces loneliness significantly",
                "Boosts mood and wellbeing"
            ],
            tips: "Quality over quantity. Ask questions. Listen actively.",
            estimatedMinutes: "15-20 min"
        ),
        
        HabitTemplate(
            name: "Acts of Kindness",
            category: .connection,
            icon: "heart.circle.fill",
            description: "Do something kind for someone else",
            quickActionKey: nil,
            systemTag: "Connection",
            suggestedFrequency: "3x weekly",
            benefits: [
                "Increases happiness (yours and theirs)",
                "Creates positive ripples",
                "Builds sense of purpose"
            ],
            tips: "Small acts count. Be genuine. No expectations.",
            estimatedMinutes: "5-15 min"
        ),
        
        HabitTemplate(
            name: "Quality Time",
            category: .connection,
            icon: "person.2.fill",
            description: "Spend focused time with loved ones",
            quickActionKey: nil,
            systemTag: "Connection",
            suggestedFrequency: "3x weekly",
            benefits: [
                "Deeper relationships",
                "Shared memories",
                "Greater life satisfaction"
            ],
            tips: "Put phones away. Be fully present. Do activities together.",
            estimatedMinutes: "30-60 min"
        ),
        
        HabitTemplate(
            name: "Express Appreciation",
            category: .connection,
            icon: "heart.circle.fill",
            description: "Tell someone specifically why you appreciate them",
            quickActionKey: "micro.afternoon.text",
            systemTag: "Connection",
            suggestedFrequency: "2x weekly",
            benefits: [
                "Strengthens bonds",
                "Makes others feel valued",
                "Increases your own happiness"
            ],
            tips: "Be specific. Say why, not just thanks. Write or say it.",
            estimatedMinutes: "5 min"
        ),
        
        HabitTemplate(
            name: "Family Ritual",
            category: .connection,
            icon: "house.fill",
            description: "Create a regular ritual with family",
            quickActionKey: nil,
            systemTag: "Connection",
            suggestedFrequency: "Weekly",
            benefits: [
                "Creates lasting memories",
                "Builds family bonds",
                "Provides stability"
            ],
            tips: "Keep it simple. Same time works best. Everyone participates.",
            estimatedMinutes: "30-60 min"
        ),
        
        HabitTemplate(
            name: "Active Listening",
            category: .connection,
            icon: "ear.fill",
            description: "Practice truly listening without planning your response",
            quickActionKey: nil,
            systemTag: "Connection",
            suggestedFrequency: "Daily",
            benefits: [
                "Deeper understanding",
                "Better relationships",
                "Reduces conflicts"
            ],
            tips: "Eye contact. No interrupting. Ask clarifying questions.",
            estimatedMinutes: "During conversations"
        )
    ]
    
    // Helper methods
    static func templates(for category: HabitCategory) -> [HabitTemplate] {
        templates.filter { $0.category == category }
    }
    
    static func template(linkedTo quickActionKey: String) -> HabitTemplate? {
        templates.first { $0.quickActionKey == quickActionKey }
    }
}

