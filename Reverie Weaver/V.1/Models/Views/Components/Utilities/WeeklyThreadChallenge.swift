//
//  WeeklyThreadChallenge.swift
//  Reverie Weaver
//
//  Weekly rotating micro-challenges that provide fresh engagement
//  Auto-assigned each Monday, displayed in ProfileView
//

import SwiftUI
import SwiftData

// MARK: - Challenge Type Definition

enum WeeklyChallengeType: String, CaseIterable, Codable {
    case dawnWeaver = "dawn_weaver"
    case twilightKeeper = "twilight_keeper"
    case steadyCurrent = "steady_current"
    case varietySeeker = "variety_seeker"
    case weekendWarrior = "weekend_warrior"
    case perfectThread = "perfect_thread"
    case gentleReturn = "gentle_return"
    case bonusWeaver = "bonus_weaver"

    var title: String {
        switch self {
        case .dawnWeaver: return "The Dawn Weaver"
        case .twilightKeeper: return "The Twilight Keeper"
        case .steadyCurrent: return "The Steady Current"
        case .varietySeeker: return "The Variety Seeker"
        case .weekendWarrior: return "The Weekend Warrior"
        case .perfectThread: return "The Perfect Thread"
        case .gentleReturn: return "The Gentle Return"
        case .bonusWeaver: return "The Bonus Weaver"
        }
    }

    var description: String {
        switch self {
        case .dawnWeaver: return "Complete 5 habits before 9am this week"
        case .twilightKeeper: return "Complete 5 habits after 6pm this week"
        case .steadyCurrent: return "Complete at least 1 habit every day this week"
        case .varietySeeker: return "Complete 5 different habits this week"
        case .weekendWarrior: return "Complete 4 habits on Saturday & Sunday combined"
        case .perfectThread: return "Achieve 2 perfect days (all habits completed)"
        case .gentleReturn: return "After any gap, complete habits 3 days in a row"
        case .bonusWeaver: return "Complete 5 unscheduled bonus completions"
        }
    }

    var targetCount: Int {
        switch self {
        case .dawnWeaver: return 5
        case .twilightKeeper: return 5
        case .steadyCurrent: return 7
        case .varietySeeker: return 5
        case .weekendWarrior: return 4
        case .perfectThread: return 2
        case .gentleReturn: return 3
        case .bonusWeaver: return 5
        }
    }

    var bonusCompletions: Int {
        switch self {
        case .dawnWeaver: return 50
        case .twilightKeeper: return 50
        case .steadyCurrent: return 75
        case .varietySeeker: return 40
        case .weekendWarrior: return 60
        case .perfectThread: return 100
        case .gentleReturn: return 80
        case .bonusWeaver: return 50
        }
    }

    var icon: String {
        switch self {
        case .dawnWeaver: return "sunrise.fill"
        case .twilightKeeper: return "sunset.fill"
        case .steadyCurrent: return "water.waves"
        case .varietySeeker: return "leaf.fill"
        case .weekendWarrior: return "figure.walk"
        case .perfectThread: return "checkmark.seal.fill"
        case .gentleReturn: return "arrow.uturn.backward.circle.fill"
        case .bonusWeaver: return "plus.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .dawnWeaver: return "FFD18B"      // Warm amber
        case .twilightKeeper: return "9B7EBD"  // Purple
        case .steadyCurrent: return "9BB5CE"   // Dusty blue
        case .varietySeeker: return "A8B5A0"   // Sage green
        case .weekendWarrior: return "E8A87C"  // Coral
        case .perfectThread: return "D4AF37"   // Gold
        case .gentleReturn: return "B8A9C9"    // Lavender
        case .bonusWeaver: return "A8D5BA"     // Mint
        }
    }
}

// MARK: - SwiftData Model

@Model
final class WeeklyChallenge {
    var id: UUID
    var challengeType: String
    var weekStartDate: Date
    var currentProgress: Int
    var isCompleted: Bool
    var completedDate: Date?
    var bonusAwarded: Bool

    init(type: WeeklyChallengeType, weekStart: Date) {
        self.id = UUID()
        self.challengeType = type.rawValue
        self.weekStartDate = weekStart
        self.currentProgress = 0
        self.isCompleted = false
        self.completedDate = nil
        self.bonusAwarded = false
    }

    var type: WeeklyChallengeType? {
        WeeklyChallengeType(rawValue: challengeType)
    }

    var targetCount: Int {
        type?.targetCount ?? 0
    }

    var progressPercentage: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetCount), 1.0)
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else { return 0 }
        let remaining = calendar.dateComponents([.day], from: Date(), to: weekEnd).day ?? 0
        return max(0, remaining + 1)
    }

    var isExpired: Bool {
        daysRemaining <= 0 && !isCompleted
    }
}

// MARK: - Weekly Challenge Manager

@MainActor
@Observable
final class WeeklyChallengeManager {
    static let shared = WeeklyChallengeManager()

    private var modelContext: ModelContext?
    private var currentChallenge: WeeklyChallenge?

    // Track recently used challenges to avoid repetition
    private let recentChallengesKey = "recentWeeklyChallenges"
    private let maxRecentToTrack = 4

    private init() {}

    // MARK: - Setup

    func attachContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Challenge Management

    /// Get or create this week's challenge
    func getCurrentChallenge() -> WeeklyChallenge? {
        guard let context = modelContext else { return nil }

        let weekStart = getWeekStartDate()

        // Check for existing challenge this week
        let descriptor = FetchDescriptor<WeeklyChallenge>(
            predicate: #Predicate<WeeklyChallenge> { challenge in
                challenge.weekStartDate == weekStart
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            currentChallenge = existing
            return existing
        }

        // Create new challenge for this week
        let newChallenge = createNewChallenge(for: weekStart)
        currentChallenge = newChallenge
        return newChallenge
    }

    /// Create a new challenge for the week
    private func createNewChallenge(for weekStart: Date) -> WeeklyChallenge? {
        guard let context = modelContext else { return nil }

        let challengeType = selectChallengeType()
        let challenge = WeeklyChallenge(type: challengeType, weekStart: weekStart)

        context.insert(challenge)
        try? context.save()

        // Track this challenge type as recent
        trackRecentChallenge(challengeType)

        #if DEBUG
        print("📅 Created weekly challenge: \(challengeType.title)")
        #endif

        return challenge
    }

    /// Select a challenge type, avoiding recent ones
    private func selectChallengeType() -> WeeklyChallengeType {
        let recentTypes = getRecentChallenges()
        let availableTypes = WeeklyChallengeType.allCases.filter { !recentTypes.contains($0.rawValue) }

        // If all types have been used recently, use any
        let pool = availableTypes.isEmpty ? WeeklyChallengeType.allCases : Array(availableTypes)

        return pool.randomElement() ?? .steadyCurrent
    }

    /// Track a challenge type as recently used
    private func trackRecentChallenge(_ type: WeeklyChallengeType) {
        var recent = getRecentChallenges()
        recent.insert(type.rawValue, at: 0)

        // Keep only the last N challenges
        if recent.count > maxRecentToTrack {
            recent = Array(recent.prefix(maxRecentToTrack))
        }

        UserDefaults.standard.set(recent, forKey: recentChallengesKey)
    }

    private func getRecentChallenges() -> [String] {
        UserDefaults.standard.stringArray(forKey: recentChallengesKey) ?? []
    }

    // MARK: - Progress Tracking

    /// Update challenge progress based on completions
    func updateProgress(completions: [HabitCompletion], habits: [Habit]) {
        guard let challenge = getCurrentChallenge(),
              !challenge.isCompleted,
              let type = challenge.type else { return }

        let weekStart = challenge.weekStartDate
        let calendar = Calendar.current

        // Filter completions to this week only
        let weekCompletions = completions.filter { completion in
            let completionDate = calendar.startOfDay(for: completion.completedAt)
            let startDate = calendar.startOfDay(for: weekStart)
            guard let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) else { return false }
            return completionDate >= startDate && completionDate < endDate
        }

        // Calculate progress based on challenge type
        let newProgress = calculateProgress(
            type: type,
            weekCompletions: weekCompletions,
            habits: habits,
            weekStart: weekStart
        )

        // Update if changed
        if newProgress != challenge.currentProgress {
            challenge.currentProgress = newProgress

            // Check for completion
            if newProgress >= challenge.targetCount && !challenge.isCompleted {
                challenge.isCompleted = true
                challenge.completedDate = Date()

                // Play sound and haptic
                AchievementAudioManager.shared.playWeeklyComplete()
                ReverieHaptics.successFeedback()

                // Post notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("WeeklyChallengeCompleted"),
                    object: challenge
                )

                #if DEBUG
                print("🏆 Weekly challenge completed: \(type.title)")
                #endif
            }

            try? modelContext?.save()
        }
    }

    /// Calculate progress for a specific challenge type
    private func calculateProgress(
        type: WeeklyChallengeType,
        weekCompletions: [HabitCompletion],
        habits: [Habit],
        weekStart: Date
    ) -> Int {
        let calendar = Calendar.current

        switch type {
        case .dawnWeaver:
            // Completions before 9am
            return weekCompletions.filter { completion in
                let hour = calendar.component(.hour, from: completion.completedAt)
                return hour < 9
            }.count

        case .twilightKeeper:
            // Completions after 6pm
            return weekCompletions.filter { completion in
                let hour = calendar.component(.hour, from: completion.completedAt)
                return hour >= 18
            }.count

        case .steadyCurrent:
            // Days with at least 1 completion
            let uniqueDays = Set(weekCompletions.map { calendar.startOfDay(for: $0.completedAt) })
            return uniqueDays.count

        case .varietySeeker:
            // Unique habits completed
            let uniqueHabits = Set(weekCompletions.map { $0.habitId })
            return uniqueHabits.count

        case .weekendWarrior:
            // Weekend completions (Saturday = 7, Sunday = 1)
            return weekCompletions.filter { completion in
                let weekday = calendar.component(.weekday, from: completion.completedAt)
                return weekday == 1 || weekday == 7
            }.count

        case .perfectThread:
            // Perfect days (all active habits completed)
            var perfectDays = 0
            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
                let dayStart = calendar.startOfDay(for: day)

                // Get active habits for this day
                let activeHabits = habits.filter { habit in
                    let created = calendar.startOfDay(for: habit.createdAt)
                    let archived = habit.archivedAt.map { calendar.startOfDay(for: $0) }
                    return created <= dayStart && (archived == nil || archived! >= dayStart)
                }

                guard !activeHabits.isEmpty else { continue }

                // Check if all active habits were completed
                let dayCompletions = weekCompletions.filter {
                    calendar.isDate($0.completedAt, inSameDayAs: day)
                }
                let completedHabitIds = Set(dayCompletions.map { $0.habitId })
                let allCompleted = activeHabits.allSatisfy { completedHabitIds.contains($0.id) }

                if allCompleted {
                    perfectDays += 1
                }
            }
            return perfectDays

        case .gentleReturn:
            // After a gap, consecutive days
            // For simplicity, count consecutive days from first completion this week
            let sortedDays = weekCompletions
                .map { calendar.startOfDay(for: $0.completedAt) }
                .sorted()

            guard !sortedDays.isEmpty else { return 0 }

            var consecutive = 1
            var maxConsecutive = 1
            var lastDay = sortedDays[0]

            for day in sortedDays.dropFirst() {
                if day == lastDay { continue }

                let diff = calendar.dateComponents([.day], from: lastDay, to: day).day ?? 0
                if diff == 1 {
                    consecutive += 1
                    maxConsecutive = max(maxConsecutive, consecutive)
                } else {
                    consecutive = 1
                }
                lastDay = day
            }

            return maxConsecutive

        case .bonusWeaver:
            // Unscheduled/bonus completions
            return weekCompletions.filter { $0.wasScheduledForDay == false }.count
        }
    }

    // MARK: - Helpers

    private func getWeekStartDate() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find this week's Monday
        var weekday = calendar.component(.weekday, from: today)
        // Convert to Monday = 1 format (default is Sunday = 1)
        weekday = weekday == 1 ? 7 : weekday - 1

        let daysToSubtract = weekday - 1
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
    }

    /// Check if bonus has been awarded for a completed challenge
    func awardBonusIfNeeded(challenge: WeeklyChallenge) -> Int? {
        guard challenge.isCompleted,
              !challenge.bonusAwarded,
              let type = challenge.type else { return nil }

        challenge.bonusAwarded = true
        try? modelContext?.save()

        return type.bonusCompletions
    }
}

// MARK: - Weekly Challenge Card View

struct WeeklyChallengeCard: View {
    let challenge: WeeklyChallenge
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        guard let type = challenge.type else {
            return AnyView(EmptyView())
        }

        let accentColor = Color(hex: type.colorHex)

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // Top row: Icon, Title, and Days left (matching CurrentSeasonBanner style)
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.title)
                            .font(.system(size: 13, weight: .medium))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text("Weekly Challenge")
                            .font(.system(size: 12, weight: .regular))
                            .italic()
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }

                    Spacer()

                    // Status badge
                    if challenge.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Complete")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Color.sageGreen)
                    } else {
                        Text("\(challenge.daysRemaining)d left")
                            .font(.system(size: 11, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                }

                // Separator line (matching CurrentSeasonBanner)
                Rectangle()
                    .fill(accentColor.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, -2)

                // Description
                Text(type.description)
                    .font(.system(size: 12, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // Progress section
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(accentColor.opacity(0.15))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    challenge.isCompleted
                                        ? Color.sageGreen
                                        : accentColor
                                )
                                .frame(width: geometry.size.width * challenge.progressPercentage)
                                .animation(.spring(response: 0.4), value: challenge.progressPercentage)
                        }
                    }
                    .frame(height: 5)

                    // Progress text
                    HStack {
                        Text("\(challenge.currentProgress)/\(challenge.targetCount)")
                            .font(.system(size: 11, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                        Spacer()

                        if challenge.isCompleted {
                            Text("+\(type.bonusCompletions) bonus")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "D4AF37"))
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(colorScheme == .dark ? 0.12 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
            )
        )
    }
}

// MARK: - Preview

#Preview {
    let challenge = WeeklyChallenge(type: .dawnWeaver, weekStart: Date())
    challenge.currentProgress = 3

    return WeeklyChallengeCard(challenge: challenge)
        .padding()
        .background(Color.gray.opacity(0.1))
}
