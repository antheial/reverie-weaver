//
// ArchiveInsightsGenerator.swift
// Reverie Weaver
//
// Smart context-aware insights generator for archive view
// Provides encouraging, specific, and actionable insights
// based on user's weekly performance patterns
//
//

import Foundation

struct ArchiveInsight {
    let id = UUID()
    let icon: String
    let message: String
    let color: String // Hex color
    let priority: Int // Higher = shown first
}

class ArchiveInsightsGenerator {

    // MARK: - Main Generation Function

    static func generateInsights(
        completionRate: Double,
        weekCompletions: Int,
        totalHabitsCount: Int,
        lastWeekRate: Double?,
        currentStreak: Int,
        isPerfectWeek: Bool,
        bestDay: (name: String, count: Int)?,
        consistencyRate: Double,
        hasActiveChallenge: Bool,
        miniChallengeProgress: MiniChallengeProgress? = nil
    ) -> [ArchiveInsight] {

        var insights: [ArchiveInsight] = []

        if let progress = miniChallengeProgress, progress.isCompleted {
            insights.append(ArchiveInsight(
                icon: "bolt.fill",
                message: "🎉 You completed the \(progress.challengeTitle)! 7 days of consistent effort shows real transformation.",
                color: "6CA9C3",
                priority: 105
            ))
        }

        // Mini Challenge Active & Progressing Well (5+ days)
        if let progress = miniChallengeProgress,
           !progress.isCompleted,
           !progress.isArchived,
           progress.daysCompleted >= 5 {
            let daysLeft = 7 - progress.daysCompleted
            insights.append(ArchiveInsight(
                icon: "bolt.fill",
                message: "⚡ \(progress.daysCompleted)/7 days complete on your mini challenge! Just \(daysLeft) more day\(daysLeft == 1 ? "" : "s") — you're almost there!",
                color: "6CA9C3",
                priority: 98
            ))
        }

        // Mini Challenge Active & Making Progress (3-4 days)
        if let progress = miniChallengeProgress,
           !progress.isCompleted,
           !progress.isArchived,
           progress.daysCompleted >= 3,
           progress.daysCompleted < 5 {
            insights.append(ArchiveInsight(
                icon: "bolt.fill",
                message: "💫 Halfway through your challenge! \(progress.daysCompleted)/7 days complete. Momentum is building beautifully.",
                color: "6CA9C3",
                priority: 92
            ))
        }

        // Mini Challenge Just Started (1-2 days)
        if let progress = miniChallengeProgress,
           !progress.isCompleted,
           !progress.isArchived,
           progress.daysCompleted > 0,
           progress.daysCompleted < 3 {
            insights.append(ArchiveInsight(
                icon: "bolt.fill",
                message: "🌱 Your 7-day challenge has begun! \(progress.daysCompleted) day\(progress.daysCompleted == 1 ? "" : "s") down, keep the momentum alive.",
                color: "6CA9C3",
                priority: 87
            ))
        }

        // 1. Perfect Week (highest priority for regular habits)
        if isPerfectWeek {
            insights.append(ArchiveInsight(
                icon: "star.fill",
                message: "Perfect week! You completed every habit. This is powerful momentum—celebrate it!",
                color: "67B7A4",
                priority: 100
            ))
        }

        // 2. Strong Improvement
        if let lastWeek = lastWeekRate, completionRate - lastWeek >= 0.20 {
            let improvement = Int((completionRate - lastWeek) * 100)
            insights.append(ArchiveInsight(
                icon: "arrow.up.right",
                message: "Amazing \(improvement)% improvement from last week! Your consistency is building real change.",
                color: "67B7A4",
                priority: 95
            ))
        }

        // 3. High Completion (80%+)
        if completionRate >= 0.8 && !isPerfectWeek {
            insights.append(ArchiveInsight(
                icon: "checkmark.seal.fill",
                message: "Strong week with \(Int(completionRate * 100))% completion. You're building powerful momentum!",
                color: "6CA9C3",
                priority: 90
            ))
        }

        // 4. Streak Milestone
        if currentStreak >= 7 {
            if currentStreak % 30 == 0 {
                insights.append(ArchiveInsight(
                    icon: "flame.fill",
                    message: "\(currentStreak) day streak! You've built a genuine practice. This is transformation.",
                    color: "E46A6A",
                    priority: 95
                ))
            } else if currentStreak % 7 == 0 {
                insights.append(ArchiveInsight(
                    icon: "flame",
                    message: "\(currentStreak) day streak going strong. Every day you show up matters.",
                    color: "E46A6A",
                    priority: 85
                ))
            }
        }

        // 5. Streak Broken (compassionate support)
        if currentStreak == 0 && completionRate < 0.3 {
            insights.append(ArchiveInsight(
                icon: "leaf.fill",
                message: "Fresh start. Yesterday doesn't define today—one small habit is all it takes to begin again.",
                color: "67B7A4",
                priority: 88
            ))
        }

        // 6. Recovery Week (improving after low week)
        if let lastWeek = lastWeekRate,
           lastWeek < 0.4 && completionRate >= 0.5 {
            insights.append(ArchiveInsight(
                icon: "arrow.up.forward",
                message: "Recovery in progress. You're building back up—keep moving forward with compassion.",
                color: "67B7A4",
                priority: 82
            ))
        }

        // 7. Consistency Pattern (3+ days with activity)
        if consistencyRate >= 0.43 { // 3 out of 7 days
            insights.append(ArchiveInsight(
                icon: "chart.bar.fill",
                message: "You showed up consistently this week. Small, repeated actions create lasting change.",
                color: "6CA9C3",
                priority: 75
            ))
        }

        // 8. Best Day Recognition
        if let best = bestDay, best.count >= 3 {
            insights.append(ArchiveInsight(
                icon: "calendar.badge.plus",
                message: "\(best.name) was your power day with \(best.count) habits! Consider scheduling important practices then.",
                color: "9B7EBD",
                priority: 70
            ))
        }

        // 9. Active Challenge Reminder (if no progress yet)
        if hasActiveChallenge && miniChallengeProgress == nil {
            insights.append(ArchiveInsight(
                icon: "target",
                message: "You have an active challenge. Complete all challenge habits today to mark progress!",
                color: "6CA9C3",
                priority: 65
            ))
        }

        // 10. Volume Achievement
        if weekCompletions >= 20 {
            insights.append(ArchiveInsight(
                icon: "star.circle.fill",
                message: "\(weekCompletions) completions this week! That's serious dedication showing up in action.",
                color: "9B7EBD",
                priority: 60
            ))
        }

        // 11. Moderate Progress (50-80%)
        if completionRate >= 0.5 && completionRate < 0.8 && insights.isEmpty {
            insights.append(ArchiveInsight(
                icon: "arrow.forward",
                message: "Steady progress at \(Int(completionRate * 100))%. Consistency beats perfection every time.",
                color: "6CA9C3",
                priority: 55
            ))
        }

        // 12. First Steps (if very few completions but present)
        if weekCompletions > 0 && weekCompletions <= 3 {
            insights.append(ArchiveInsight(
                icon: "leaf",
                message: "Every habit you complete is a seed planted. Small beginnings lead to transformation.",
                color: "67B7A4",
                priority: 50
            ))
        }

        // 13. Default Encouragement (if no other insights)
        if insights.isEmpty {
            insights.append(ArchiveInsight(
                icon: "moon.stars.fill",
                message: "Your journey is unique. Each small step weaves the story of who you're becoming.",
                color: "9B7EBD",
                priority: 40
            ))
        }

        // Sort by priority (highest first) and return top 3
        return insights.sorted { $0.priority > $1.priority }.prefix(3).map { $0 }
    }

    // MARK: - Helper: Calculate Consistency Rate

    static func calculateConsistencyRate(
        dailyCompletions: [Int],
        habitCount: Int
    ) -> Double {
        guard habitCount > 0 else { return 0 }

        let daysWithProgress = dailyCompletions.filter { $0 > 0 }.count
        return Double(daysWithProgress) / Double(dailyCompletions.count)
    }

    // MARK: - Helper: Find Best Day

    static func findBestDay(
        weekDays: [Date],
        completions: [HabitCompletion]
    ) -> (name: String, count: Int)? {

        var dayCounts: [(name: String, count: Int)] = []

        for day in weekDays {
            let dayCompletions = completions.filter {
                Calendar.current.isDate($0.completedAt, inSameDayAs: day)
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let dayName = formatter.string(from: day)

            dayCounts.append((name: dayName, count: dayCompletions.count))
        }

        return dayCounts.max(by: { $0.count < $1.count })
    }

    static func findStrongestCategory(
        completions: [HabitCompletion],
        habits: [Habit]
    ) -> String? {
        let regularHabits = habits.filter { habit in
            !(habit.programTag?.starts(with: "C7-") ?? false)
        }

        guard !regularHabits.isEmpty else { return nil }

        var categoryCount: [String: Int] = [:]

        for completion in completions {
            if let habit = regularHabits.first(where: { $0.id == completion.habitId }) {
                let category = habit.category
                categoryCount[category, default: 0] += 1
            }
        }

        return categoryCount.max(by: { $0.value < $1.value })?.key
    }
}
