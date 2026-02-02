//
//  HabitStatsCalculator.swift
//  Reverie Weaver
//
//  Shared calculation logic for habit statistics across Weekly and Monthly archive views.
//  Ensures consistent completion rate calculations with proper rest day handling and snapshot support.
//

import SwiftUI
import SwiftData

/// Centralized calculator for habit statistics with rest day awareness and snapshot-based accuracy
struct HabitStatsCalculator {
    let completions: [HabitCompletion]
    let habits: [Habit]
    let reflections: [DailyReflection]
    let profiles: [UserProfile]
    
    // MARK: - Rest Day Detection
    
    /// Returns all rest days within a specific week (normalized to startOfDay)
    func restDays(forWeekStarting start: Date) -> Set<Date> {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        let endExclusive = calendar.date(byAdding: .day, value: 7, to: normalizedStart) ?? normalizedStart
        
        return Set(
            reflections
                .compactMap { reflection -> Date? in
                    guard reflection.isRestDay else { return nil }
                    let reflectionDay = calendar.startOfDay(for: reflection.date)
                    guard reflectionDay >= normalizedStart && reflectionDay < endExclusive else { return nil }
                    return reflectionDay
                }
        )
    }
    
    /// Returns all rest days within a specific month (normalized to startOfDay)
    func restDays(forMonthStarting start: Date) -> Set<Date> {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: normalizedStart) else {
            return []
        }
        
        return Set(
            reflections
                .compactMap { reflection -> Date? in
                    guard reflection.isRestDay else { return nil }
                    let reflectionDay = calendar.startOfDay(for: reflection.date)
                    guard reflectionDay >= normalizedStart && reflectionDay < nextMonth else { return nil }
                    return reflectionDay
                }
        )
    }
    
    // MARK: - Active Habit Count (Snapshot-Based)
    
    /// Returns the number of active habits on a specific date, using snapshot data when available
    /// Falls back to calculation from current habit state for legacy data
    func activeHabitCount(on date: Date) -> Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Get completions for this day
        let dayCompletions = completions.filter {
            calendar.isDate($0.completedAt, inSameDayAs: date)
        }
        
        // SNAPSHOT APPROACH: Use captured snapshot from completion time
        let snapshotCounts = dayCompletions.compactMap { $0.snapshotActiveHabitsCount }
        if !snapshotCounts.isEmpty {
            // Use first completion's snapshot (captures start-of-day state)
            if let firstCompletion = dayCompletions.sorted(by: { $0.completedAt < $1.completedAt }).first,
               let snapshotCount = firstCompletion.snapshotActiveHabitsCount {
                return snapshotCount
            }
            
            // Fallback: use max snapshot if first doesn't have it
            return snapshotCounts.max() ?? 0
        }
        
        // FALLBACK: Calculate from current habit state (may be inaccurate if habits were deleted)
        let activeHabits = habits.filter { habit in
            guard habit.createdAt <= dayStart else { return false }
            if let archivedDate = habit.archivedAt, archivedDate < dayStart {
                return false
            }
            return habit.isScheduledOn(date)
        }
        
        return activeHabits.count
    }
    
    // MARK: - Completion Rate Calculations
    
    /// Returns only scheduled completions from a completion array
    /// Treats legacy completions (wasScheduledForDay == nil) as scheduled for backward compatibility
    func scheduledCompletions(from completions: [HabitCompletion]) -> [HabitCompletion] {
        completions.filter { completion in
            completion.wasScheduledForDay ?? true
        }
    }
    
    /// Counts unique habit IDs from scheduled completions, capped at active count
    /// Prevents duplicate completions and unscheduled completions from inflating metrics
    func uniqueScheduledCompletions(from completions: [HabitCompletion], cappedAt max: Int) -> Int {
        let scheduled = scheduledCompletions(from: completions)
        let unique = Set(scheduled.map { $0.habitId }).count
        return min(unique, max)
    }
    
    /// Calculates completion rate for a specific week with rest day exclusion
    func weeklyRate(forWeekStarting start: Date, markedRestDays: Set<Date>? = nil) -> Double {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        let endExclusive = calendar.date(byAdding: .day, value: 7, to: normalizedStart) ?? normalizedStart
        
        let restDaysThisWeek = markedRestDays ?? restDays(forWeekStarting: normalizedStart)
        
        var completedSlots = 0
        var possibleSlots = 0
        
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: normalizedStart),
                  day < endExclusive else { continue }
            
            let normalizedDay = calendar.startOfDay(for: day)
            
            // Skip rest days
            guard !restDaysThisWeek.contains(normalizedDay) else { continue }
            
            // Use snapshot-based active count
            let activeCount = activeHabitCount(on: normalizedDay)
            guard activeCount > 0 else { continue }
            
            possibleSlots += activeCount
            
            // Get completions and count unique scheduled habit IDs
            let dayCompletions = completions.filter {
                calendar.isDate($0.completedAt, inSameDayAs: day)
            }
            
            let scheduled = scheduledCompletions(from: dayCompletions)
            let uniqueScheduled = Set(scheduled.map { $0.habitId }).count
            
            // Cap at activeCount (can't complete more than existed)
            completedSlots += min(uniqueScheduled, activeCount)
        }
        
        guard possibleSlots > 0 else { return 0 }
        
        // Explicitly cap at 1.0 (100%)
        return min(1.0, Double(completedSlots) / Double(possibleSlots))
    }
    
    /// Calculates total possible completions for a week with rest day exclusion
    func totalPossible(inWeekStarting start: Date, markedRestDays: Set<Date>? = nil) -> Int {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        let restDaysInWeek = markedRestDays ?? restDays(forWeekStarting: normalizedStart)
        
        return (0..<7).reduce(0) { total, offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: normalizedStart) else { return total }
            let normalizedDay = calendar.startOfDay(for: day)
            guard !restDaysInWeek.contains(normalizedDay) else { return total }
            return total + activeHabitCount(on: normalizedDay)
        }
    }
    
    /// Counts unique scheduled completions for a week with rest day exclusion
    func uniqueCompletions(inWeekStarting start: Date, markedRestDays: Set<Date>? = nil) -> Int {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        let restDaysThisWeek = markedRestDays ?? restDays(forWeekStarting: normalizedStart)
        
        var uniqueCount = 0
        
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: normalizedStart) else { continue }
            let normalizedDay = calendar.startOfDay(for: day)
            guard !restDaysThisWeek.contains(normalizedDay) else { continue }
            
            let dayCompletions = completions.filter {
                calendar.isDate($0.completedAt, inSameDayAs: day)
            }
            
            // Only count scheduled completions
            let scheduled = scheduledCompletions(from: dayCompletions)
            
            // Count unique habit IDs for this day
            let uniqueHabits = Set(scheduled.map { $0.habitId })
            let activeCount = activeHabitCount(on: normalizedDay)
            
            // Cap at active count (can't complete more than existed)
            uniqueCount += min(uniqueHabits.count, activeCount)
        }
        
        return uniqueCount
    }
    
    /// Calculates completion rate for a specific month with rest day exclusion
    func monthlyRate(forMonthStarting start: Date) -> Double {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: normalizedStart) else {
            return 0
        }
        
        let restDaysThisMonth = restDays(forMonthStarting: normalizedStart)
        
        var completedSlots = 0
        var possibleSlots = 0
        
        var currentDay = normalizedStart
        while currentDay < nextMonth {
            let normalizedDay = calendar.startOfDay(for: currentDay)
            
            // Skip rest days
            if !restDaysThisMonth.contains(normalizedDay) {
                let activeCount = activeHabitCount(on: normalizedDay)
                
                if activeCount > 0 {
                    possibleSlots += activeCount
                    
                    let dayCompletions = completions.filter {
                        calendar.isDate($0.completedAt, inSameDayAs: currentDay)
                    }
                    
                    let scheduled = scheduledCompletions(from: dayCompletions)
                    let uniqueScheduled = Set(scheduled.map { $0.habitId }).count
                    
                    completedSlots += min(uniqueScheduled, activeCount)
                }
            }
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
        
        guard possibleSlots > 0 else { return 0 }
        return min(1.0, Double(completedSlots) / Double(possibleSlots))
    }
    
    /// Calculates total possible completions for a month with rest day exclusion
    func totalPossible(inMonthStarting start: Date) -> Int {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: normalizedStart) else {
            return 0
        }
        
        let restDaysThisMonth = restDays(forMonthStarting: normalizedStart)
        
        var total = 0
        var currentDay = normalizedStart
        
        while currentDay < nextMonth {
            let normalizedDay = calendar.startOfDay(for: currentDay)
            
            if !restDaysThisMonth.contains(normalizedDay) {
                total += activeHabitCount(on: normalizedDay)
            }
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
        
        return total
    }
    
    /// Counts unique scheduled completions for a month with rest day exclusion
    func uniqueCompletions(inMonthStarting start: Date) -> Int {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: start)
        
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: normalizedStart) else {
            return 0
        }
        
        let restDaysThisMonth = restDays(forMonthStarting: normalizedStart)
        
        var uniqueCount = 0
        var currentDay = normalizedStart
        
        while currentDay < nextMonth {
            let normalizedDay = calendar.startOfDay(for: currentDay)
            
            if !restDaysThisMonth.contains(normalizedDay) {
                let dayCompletions = completions.filter {
                    calendar.isDate($0.completedAt, inSameDayAs: currentDay)
                }
                
                let scheduled = scheduledCompletions(from: dayCompletions)
                let uniqueHabits = Set(scheduled.map { $0.habitId })
                let activeCount = activeHabitCount(on: normalizedDay)
                
                uniqueCount += min(uniqueHabits.count, activeCount)
            }
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
        
        return uniqueCount
    }
}
