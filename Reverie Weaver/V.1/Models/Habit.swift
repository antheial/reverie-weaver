//
// Habit.swift
// ReverieWeaver
//
//

import Foundation
import SwiftData
import UserNotifications

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitDescription: String
    var category: String
    var categoryIcon: String
    var icon: String
    var colorHex: String
    var completionMessage: String
    var frequency: String
    var createdAt: Date
    var order: Int
    
    var isArchived: Bool = false
    var archivedAt: Date? = nil

    // Program tracking
    var programTag: String?
    var programLevel: Int?
    
    var scheduledDays: [Int]? = nil
    
    // Reminder Support
    var hasReminder: Bool = false
    var reminderTime: Date? = nil
    
    // Relationship to completions
    @Relationship(deleteRule: .cascade) var completions: [HabitCompletion]?
    
    // MARK: - Initializer
    
    init(
        name: String,
        description: String,
        category: String,
        categoryIcon: String,
        icon: String,
        colorHex: String,
        completionMessage: String = "",
        frequency: String = "daily",
        order: Int = 0,
        programTag: String? = nil,
        programLevel: Int? = nil,
        scheduledDays: [Int]? = nil,
        hasReminder: Bool = false,
        reminderTime: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = description
        self.category = category
        self.categoryIcon = categoryIcon
        self.icon = icon
        self.colorHex = colorHex
        self.completionMessage = completionMessage
        self.frequency = frequency
        self.createdAt = Date()
        self.order = order
        self.programTag = programTag
        self.programLevel = programLevel
        self.scheduledDays = scheduledDays
        self.hasReminder = hasReminder
        self.reminderTime = reminderTime
    }
    
    // MARK: - Logic Helpers
    
    // Check if habit is scheduled for a specific date
    func isScheduledOn(_ date: Date) -> Bool {
        // 1. If scheduledDays is nil or empty, it implies "Daily" (Active every day)
        guard let days = scheduledDays, !days.isEmpty else {
            return true
        }
        
        // 2. Check specific day match
        let weekday = Calendar.current.component(.weekday, from: date)
        return days.contains(weekday)
    }
    
    // MARK: - Dynamic Display Methods
    
    func displayName(themeWeekProgress: [ThemeWeekProgress]) -> String {
        guard isThemeWeek,
              let programTag = programTag,
              programTag.starts(with: "TW-") else {
            return name
        }
        
        let weekTag = String(programTag.dropFirst(3))
        
        // Use first(where:) for O(n) lookup - efficient enough for small datasets
        guard let progress = themeWeekProgress.first(where: {
            $0.programTag == weekTag && !$0.isCompleted && !$0.isPaused && !$0.isArchived
        }) else {
            return name
        }
        
        guard let program = ThemeWeekData.programs.first(where: { $0.tag == weekTag }) else {
            return name
        }
        
        let currentDay = progress.currentDayNumber
        guard let dayTheme = program.theme(for: currentDay) else {
            return name
        }
        
        return "Day \(currentDay): \(dayTheme.themeName)"
    }
    
    func displayDescription(themeWeekProgress: [ThemeWeekProgress]) -> String {
        guard isThemeWeek,
              let programTag = programTag,
              programTag.starts(with: "TW-") else {
            return habitDescription
        }
        
        let weekTag = String(programTag.dropFirst(3))
        
        guard let progress = themeWeekProgress.first(where: {
            $0.programTag == weekTag && !$0.isCompleted && !$0.isPaused && !$0.isArchived
        }),
        let program = ThemeWeekData.programs.first(where: { $0.tag == weekTag }),
        let dayTheme = program.theme(for: progress.currentDayNumber) else {
            return habitDescription
        }

        return dayTheme.tagline
    }

    func displayIcon(themeWeekProgress: [ThemeWeekProgress]) -> String {
        guard isThemeWeek,
              let programTag = programTag,
              programTag.starts(with: "TW-") else {
            return icon
        }

        let weekTag = String(programTag.dropFirst(3))

        guard let progress = themeWeekProgress.first(where: {
            $0.programTag == weekTag && !$0.isCompleted && !$0.isPaused && !$0.isArchived
        }),
        let program = ThemeWeekData.programs.first(where: { $0.tag == weekTag }),
        let dayTheme = program.theme(for: progress.currentDayNumber) else {
            return icon
        }
        
        return dayTheme.themeIcon
    }
    
    // MARK: - Reminder & Notification Helpers
        
        /// Check if habit is active (scheduled AND not archived) for a specific date
        /// Use this for filtering visible habits; use isScheduledOn for pure schedule logic
        func isActiveOn(_ date: Date) -> Bool {
            guard !isArchived else { return false }
            return isScheduledOn(date)
        }
        
        /// Check if habit should show reminder on a specific date
        func shouldRemindOn(_ date: Date) -> Bool {
            guard hasReminder, reminderTime != nil else { return false }
            guard !isArchived else { return false }
            return isScheduledOn(date)
        }
        
        /// Cancel all pending notifications for this habit
        func cancelNotifications() {
            let habitId = self.id
            
            Task {
                await HabitNotificationManager.shared.cancelNotification(for: habitId)
            }
        }

        /// Schedule notifications based on current reminder settings
        func scheduleNotifications() {
            // 1. Snapshot values
            let habitId = self.id
            let habitName = self.name
            let reminderTime = self.reminderTime
            let scheduledDays = self.scheduledDays
            let streak = self.currentStreak
            let archived = self.isArchived
            let reminderEnabled = self.hasReminder
            
            Task { @MainActor in
                // 2. Logic Check inside the Task
                // If reminder is disabled, missing time, or archived, ensure we cancel existing ones
                guard reminderEnabled, let time = reminderTime, !archived else {
                    await HabitNotificationManager.shared.cancelNotification(for: habitId)
                    #if DEBUG
                    print("ℹ️ Skipping notification schedule (reminder off, no time, or archived): \(habitName)")
                    #endif
                    return
                }
                
                // 3. Check authorization status before scheduling
                let status = await HabitNotificationManager.shared.checkAuthorizationStatus()
                guard status == .authorized else {
                    #if DEBUG
                    print("⚠️ Cannot schedule notifications - authorization: \(status.rawValue)")
                    #endif
                    return
                }
                
                // 4. Delegate to Manager
                // This ensures we use the centralized logic (snooze, actions, time-sensitive)
                await HabitNotificationManager.shared.scheduleForHabit(
                    id: habitId,
                    name: habitName,
                    reminderTime: time,
                    scheduledDays: scheduledDays,
                    streak: streak,
                    isArchived: archived
                )
                
                #if DEBUG
                print("✅ Scheduled notifications for: \(habitName)")
                #endif
            }
        }
    // MARK: - Streak Calculation
    
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Sort completions by date descending
        let sortedCompletions = safeCompletions
            .map { calendar.startOfDay(for: $0.completedAt) }
            .sorted(by: >)
        
        guard !sortedCompletions.isEmpty else { return 0 }
        
        // Remove duplicates
        var uniqueDays: [Date] = []
        for date in sortedCompletions {
            if !uniqueDays.contains(date) {
                uniqueDays.append(date)
            }
        }
        
        // Check if streak is active (completed today or yesterday)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let mostRecent = uniqueDays.first,
              mostRecent == today || mostRecent == yesterday else {
            return 0
        }
        
        // Count consecutive days
        var streak = 0
        var expectedDate = mostRecent
        
        // Limit iterations to prevent infinite loops (max 1 year of streaks)
        let maxIterations = 365
        var iterations = 0
        
        for completionDate in uniqueDays {
            // For scheduled habits, only count days the habit was scheduled
            if let days = scheduledDays, !days.isEmpty {
                while expectedDate >= completionDate && iterations < maxIterations {
                    iterations += 1
                    let weekday = calendar.component(.weekday, from: expectedDate)
                    if days.contains(weekday) {
                        if completionDate == expectedDate {
                            streak += 1
                            guard let newDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
                                return streak
                            }
                            expectedDate = newDate
                            break
                        } else {
                            // Missed a scheduled day
                            return streak
                        }
                    }
                    guard let newDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
                        return streak
                    }
                    expectedDate = newDate
                }
            } else {
                // Daily habit
                if completionDate == expectedDate {
                    streak += 1
                    guard let newDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
                        return streak
                    }
                    expectedDate = newDate
                } else {
                    break
                }
            }
            
            // Safety check
            if iterations >= maxIterations {
                break
            }
        }
        
        return streak
    }
    
    // Prepare habit for deletion (cancel notifications)
    func prepareForDeletion() {
        cancelNotifications()
        #if DEBUG
        print("🗑️ Habit prepared for deletion: \(name)")
        #endif
    }
    
    // MARK: - Convenience Computed Properties
    
    var safeCompletions: [HabitCompletion] {
        completions ?? []
    }
    
    // Number of total completions
    var completionCount: Int {
        safeCompletions.count
    }
    
    // Check if completed on a specific date
    func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        return safeCompletions.contains { completion in
            calendar.isDate(completion.completedAt, inSameDayAs: date)
        }
    }
    
    // Formatted display of scheduled days
    var scheduledDaysDisplay: String {
        guard let days = scheduledDays, !days.isEmpty else {
            return "Every day"
        }
        
        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        let validDays = days.filter { $0 >= 1 && $0 <= 7 }.sorted()
        
        guard !validDays.isEmpty else {
            return "Every day"
        }
        
        // Check for common patterns
        if validDays == [2, 3, 4, 5, 6] {
            return "Weekdays"
        } else if validDays == [1, 7] {
            return "Weekends"
        } else {
            return validDays.compactMap { day in
                day >= 0 && day < dayNames.count ? dayNames[day] : nil
            }.joined(separator: ", ")
        }
    }
    
    var reminderTimeDisplay: String? {
        guard hasReminder, let time = reminderTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension Habit {
    // Debug description of habit state
    var debugDescription: String {
        """
        Habit: \(name)
          id: \(id)
          category: \(category)
          frequency: \(frequency)
          scheduledDays: \(scheduledDaysDisplay)
          hasReminder: \(hasReminder)
          reminderTime: \(reminderTimeDisplay ?? "none")
          isArchived: \(isArchived)
          programTag: \(programTag ?? "none")
          programLevel: \(programLevel.map { "\($0)" } ?? "none")
          completionCount: \(completionCount)
        """
    }
    
    func printDebugInfo() {
        print(debugDescription)
    }
}
#endif
