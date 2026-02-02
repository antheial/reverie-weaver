//
//  BreathingProgressManager.swift
//  Reverie Mood
//
//  Tracks breathing exercise statistics, progression, and session history.
//  Provides insights for "Your Journey" section and post-session analytics.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Progression Tier

enum BreathingTier: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .beginner: return "leaf.fill"
        case .intermediate: return "wind"
        case .advanced: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .beginner: return Color(hex: "9BC5A8")      // Soft green
        case .intermediate: return Color(hex: "A0C4D9")  // Soft blue
        case .advanced: return Color(hex: "F9B572")      // Warm orange
        }
    }
}

// MARK: - Pre-Exercise Mood

enum BreathingMood: String, Codable, CaseIterable, Identifiable {
    case anxious = "Anxious"
    case tired = "Tired"
    case stressed = "Stressed"
    case unfocused = "Unfocused"
    case cantSleep = "Can't Sleep"
    case justCheckingIn = "Just Checking In"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .anxious: return "heart.fill"
        case .tired: return "moon.zzz.fill"
        case .stressed: return "bolt.heart.fill"
        case .unfocused: return "scope"
        case .cantSleep: return "bed.double.fill"
        case .justCheckingIn: return "hand.wave.fill"
        }
    }

    var color: Color {
        switch self {
        case .anxious: return Color(hex: "E8A0A0")
        case .tired: return Color(hex: "B7A6E5")
        case .stressed: return Color(hex: "F9B572")
        case .unfocused: return Color(hex: "A0C4D9")
        case .cantSleep: return Color(hex: "9A8BC2")
        case .justCheckingIn: return Color(hex: "9BC5A8")
        }
    }

    /// Recommended exercise IDs for this mood
    var recommendedExercises: [String] {
        switch self {
        case .anxious:
            return ["sigh", "478", "extended", "calm"]  // Physiological sigh is great for quick anxiety relief
        case .tired:
            return ["wimhof", "kapalabhati", "triangle", "box"]  // Energizing breath for tiredness
        case .stressed:
            return ["sigh", "box", "478", "resonance"]  // Quick sigh + longer practices
        case .unfocused:
            return ["box", "alternate", "triangle", "coherent"]  // Alternate nostril for mental clarity
        case .cantSleep:
            return ["478", "extended", "pursed", "calm"]  // Pursed lip for relaxation
        case .justCheckingIn:
            return ["calm", "resonance", "coherent", "box"]  // Resonance for daily wellness
        }
    }
}

// MARK: - Post-Session Mood

enum PostSessionMood: String, Codable, CaseIterable {
    case better = "Better"
    case same = "Same"
    case needMore = "Need More"

    var icon: String {
        switch self {
        case .better: return "arrow.up.heart.fill"
        case .same: return "equal.circle.fill"
        case .needMore: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .better: return Color(hex: "9BC5A8")
        case .same: return Color(hex: "A0C4D9")
        case .needMore: return Color(hex: "F9B572")
        }
    }
}

// MARK: - Session Record

struct BreathingSessionRecord: Codable, Identifiable {
    let id: UUID
    let exerciseId: String
    let exerciseName: String
    let date: Date
    let cyclesCompleted: Int
    let cyclesTarget: Int
    let durationSeconds: Int
    let preMood: String?
    let postMood: String?
    let reflection: String?
    let completed: Bool

    init(
        exerciseId: String,
        exerciseName: String,
        cyclesCompleted: Int,
        cyclesTarget: Int,
        durationSeconds: Int,
        preMood: BreathingMood? = nil,
        postMood: PostSessionMood? = nil,
        reflection: String? = nil,
        completed: Bool = true
    ) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.date = Date()
        self.cyclesCompleted = cyclesCompleted
        self.cyclesTarget = cyclesTarget
        self.durationSeconds = durationSeconds
        self.preMood = preMood?.rawValue
        self.postMood = postMood?.rawValue
        self.reflection = reflection
        self.completed = completed
    }

    var durationFormatted: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Exercise Statistics

struct ExerciseStats: Codable {
    var sessionsCompleted: Int = 0
    var totalTimeSeconds: Int = 0
    var moodImprovementCount: Int = 0  // Count of "Better" post-moods
    var totalMoodResponses: Int = 0     // Total post-mood responses
    var lastPracticed: Date?
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var averageCycles: Double = 0
    private var cycleHistory: [Int] = []

    mutating func recordSession(cycles: Int, duration: Int, moodImproved: Bool?) {
        sessionsCompleted += 1
        totalTimeSeconds += duration
        lastPracticed = Date()

        // Update cycle average
        cycleHistory.append(cycles)
        if cycleHistory.count > 20 { cycleHistory.removeFirst() }
        averageCycles = Double(cycleHistory.reduce(0, +)) / Double(cycleHistory.count)

        // Track mood improvement
        if let improved = moodImproved {
            totalMoodResponses += 1
            if improved { moodImprovementCount += 1 }
        }
    }

    var moodImprovementRate: Double {
        guard totalMoodResponses > 0 else { return 0 }
        return Double(moodImprovementCount) / Double(totalMoodResponses)
    }

    var totalTimeFormatted: String {
        let hours = totalTimeSeconds / 3600
        let minutes = (totalTimeSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Overall Progress

struct BreathingProgress: Codable {
    var totalSessions: Int = 0
    var totalTimeSeconds: Int = 0
    var currentTier: BreathingTier = .beginner
    var exerciseStats: [String: ExerciseStats] = [:]
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastSessionDate: Date?
    var favoriteExerciseId: String?

    // Tier progression thresholds
    static let intermediateThreshold = 5   // Sessions to unlock intermediate
    static let advancedThreshold = 15      // Sessions to unlock advanced

    var sessionsToNextTier: Int? {
        switch currentTier {
        case .beginner:
            return max(0, Self.intermediateThreshold - totalSessions)
        case .intermediate:
            return max(0, Self.advancedThreshold - totalSessions)
        case .advanced:
            return nil
        }
    }

    var progressToNextTier: Double {
        switch currentTier {
        case .beginner:
            return min(1.0, Double(totalSessions) / Double(Self.intermediateThreshold))
        case .intermediate:
            let progress = totalSessions - Self.intermediateThreshold
            let needed = Self.advancedThreshold - Self.intermediateThreshold
            return min(1.0, Double(progress) / Double(needed))
        case .advanced:
            return 1.0
        }
    }

    mutating func updateTier() {
        if totalSessions >= Self.advancedThreshold {
            currentTier = .advanced
        } else if totalSessions >= Self.intermediateThreshold {
            currentTier = .intermediate
        } else {
            currentTier = .beginner
        }
    }

    mutating func updateStreak() {
        guard let lastDate = lastSessionDate else {
            currentStreak = 1
            longestStreak = max(longestStreak, 1)
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysDiff == 0 {
            // Same day, streak unchanged
        } else if daysDiff == 1 {
            // Consecutive day
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Streak broken
            currentStreak = 1
        }
    }

    mutating func updateFavorite() {
        guard !exerciseStats.isEmpty else { return }
        favoriteExerciseId = exerciseStats.max(by: { $0.value.sessionsCompleted < $1.value.sessionsCompleted })?.key
    }

    var totalTimeFormatted: String {
        let hours = totalTimeSeconds / 3600
        let minutes = (totalTimeSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

// MARK: - Progress Manager

class BreathingProgressManager: ObservableObject {
    static let shared = BreathingProgressManager()

    @Published private(set) var progress: BreathingProgress
    @Published private(set) var recentSessions: [BreathingSessionRecord]

    private let progressKey = "breathingProgress"
    private let sessionsKey = "breathingSessions"
    private let maxRecentSessions = 50

    private init() {
        // Load progress
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(BreathingProgress.self, from: data) {
            self.progress = decoded
        } else {
            self.progress = BreathingProgress()
        }

        // Load recent sessions
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([BreathingSessionRecord].self, from: data) {
            self.recentSessions = decoded
        } else {
            self.recentSessions = []
        }
    }

    // MARK: - Public Methods

    func recordSession(_ record: BreathingSessionRecord) {
        // Update exercise stats
        var stats = progress.exerciseStats[record.exerciseId] ?? ExerciseStats()
        let moodImproved: Bool? = {
            guard let postMood = record.postMood else { return nil }
            return postMood == PostSessionMood.better.rawValue
        }()
        stats.recordSession(cycles: record.cyclesCompleted, duration: record.durationSeconds, moodImproved: moodImproved)
        progress.exerciseStats[record.exerciseId] = stats

        // Update overall progress
        progress.totalSessions += 1
        progress.totalTimeSeconds += record.durationSeconds
        progress.updateStreak()
        progress.lastSessionDate = record.date
        progress.updateTier()
        progress.updateFavorite()

        // Add to recent sessions
        recentSessions.insert(record, at: 0)
        if recentSessions.count > maxRecentSessions {
            recentSessions = Array(recentSessions.prefix(maxRecentSessions))
        }

        // Save
        save()
    }

    func getStats(for exerciseId: String) -> ExerciseStats {
        return progress.exerciseStats[exerciseId] ?? ExerciseStats()
    }

    func getRecommendedExercise(for mood: BreathingMood) -> String {
        // Return the top recommended exercise for this mood
        // Could be enhanced to factor in user's history
        return mood.recommendedExercises.first ?? "calm"
    }

    func isRecommended(exerciseId: String, for mood: BreathingMood) -> Bool {
        return mood.recommendedExercises.contains(exerciseId)
    }

    // MARK: - Tier Helpers

    func tier(for exerciseId: String) -> BreathingTier {
        switch exerciseId {
        case "calm", "box", "extended", "sigh", "pursed":
            return .beginner
        case "478", "triangle", "coherent", "resonance", "alternate":
            return .intermediate
        case "kapalabhati", "wimhof":
            return .advanced
        default:
            return .beginner
        }
    }

    // MARK: - Private

    private func save() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
        if let encoded = try? JSONEncoder().encode(recentSessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
}
