//
// PriorityTask.swift
// ReverieWeaver
//
// Priority tasks for Loom view with sub-tasks and repeat functionality
//

import Foundation
import SwiftData

@Model
class PriorityTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var isCompleted: Bool
    var startDate: Date
    var endDate: Date?
    var colorHex: String
    var createdAt: Date
    var completedAt: Date?
    
    // Repeat functionality
    var repeatType: String // "none", "daily", "weekly", "weekdays", "custom"
    var customRepeatDays: [Int] // [1,2,3] for Sun, Mon, Tue (Calendar weekday values)
    
    @Relationship(deleteRule: .cascade) var subTasks: [SubTask]?
    
    init(
        title: String,
        taskDescription: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        colorHex: String = "C9D2B5",
        repeatType: String = "none",
        customRepeatDays: [Int] = []
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = false
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = endDate != nil ? Calendar.current.startOfDay(for: endDate!) : nil
        self.colorHex = colorHex
        self.createdAt = Date()
        self.repeatType = repeatType
        self.customRepeatDays = customRepeatDays
    }
    
    // ✅ FIXED: Check if task is active on a given date (enhanced with repeat logic)
    func isActive(on date: Date) -> Bool {
        let calendar = Calendar.current
        let checkDate = calendar.startOfDay(for: date)
        let taskStart = calendar.startOfDay(for: startDate)
        
        // Check if date is within the date range
        if let taskEnd = endDate {
            let end = calendar.startOfDay(for: taskEnd)
            if checkDate < taskStart || checkDate > end {
                return false
            }
        } else {
            if checkDate < taskStart {
                return false
            }
        }
        
        // If task is completed, don't show it anymore
        if isCompleted {
            return false
        }
        
        // Apply repeat logic
        switch repeatType {
        case "none":
            // ✅ FIXED: If there's an end date, show on all days in range
            // If no end date, only show on start date
            if endDate != nil {
                return true  // Already passed date range check above
            } else {
                return checkDate == taskStart  // Single day only
            }
            
        case "daily":
            // Active every day within the date range
            return true
            
        case "weekly":
            // Active once per week on the same weekday as start date
            let startWeekday = calendar.component(.weekday, from: taskStart)
            let checkWeekday = calendar.component(.weekday, from: checkDate)
            return startWeekday == checkWeekday
            
        case "weekdays":
            // Active Monday through Friday (weekday 2-6)
            let checkWeekday = calendar.component(.weekday, from: checkDate)
            return checkWeekday >= 2 && checkWeekday <= 6
            
        case "custom":
            // Active on custom selected days
            let checkWeekday = calendar.component(.weekday, from: checkDate)
            return customRepeatDays.contains(checkWeekday)
            
        default:
            return checkDate >= taskStart
        }
    }
    
    // ✅ NEW: Check if task started on a specific date
    func startsOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let checkDate = calendar.startOfDay(for: date)
        let taskStart = calendar.startOfDay(for: startDate)
        return checkDate == taskStart
    }
    
    // ✅ NEW: Get current day number and total days for multi-day tasks
    func getDayProgress(for date: Date) -> (current: Int, total: Int)? {
        guard let endDate = endDate else { return nil }
        
        let calendar = Calendar.current
        let checkDate = calendar.startOfDay(for: date)
        let taskStart = calendar.startOfDay(for: startDate)
        let taskEnd = calendar.startOfDay(for: endDate)
        
        // Calculate current day number (1-indexed)
        let currentDay = calendar.dateComponents([.day], from: taskStart, to: checkDate).day ?? 0
        let currentDayNumber = currentDay + 1
        
        // Calculate total days (1-indexed)
        let totalDays = calendar.dateComponents([.day], from: taskStart, to: taskEnd).day ?? 0
        let totalDayCount = totalDays + 1
        
        // Only return if it's a multi-day task (more than 1 day)
        guard totalDayCount > 1 else { return nil }
        
        return (currentDayNumber, totalDayCount)
    }
    
    // Helper to get a friendly description of the repeat pattern
    var repeatDescription: String {
        switch repeatType {
        case "none":
            return "Once"
        case "daily":
            return "Daily"
        case "weekly":
            let weekday = Calendar.current.component(.weekday, from: startDate)
            let formatter = DateFormatter()
            let weekdayName = formatter.weekdaySymbols[weekday - 1]
            return "Weekly on \(weekdayName)"
        case "weekdays":
            return "Weekdays (Mon-Fri)"
        case "custom":
            if customRepeatDays.isEmpty {
                return "Custom"
            }
            let formatter = DateFormatter()
            let dayNames = customRepeatDays.sorted().map { day in
                formatter.shortWeekdaySymbols[day - 1]
            }
            return "Custom (\(dayNames.joined(separator: ", ")))"
        default:
            return "Once"
        }
    }
}

@Model
final class SubTask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
}
