//
// HabitNotificationManager.swift
// ReverieWeaver
//
// Centralized notification management for habits
// ✨ Behavioral Science: One-tap completion, streak visibility, time-sensitive
//

import Foundation
import UserNotifications

// MARK: - Notification Manager

@MainActor
final class HabitNotificationManager: NSObject {

    static let shared = HabitNotificationManager()

    private let center = UNUserNotificationCenter.current()

    private var scheduledNotificationIds: Set<String> = []

    /// Custom notification sound - uses new-notification.mp3 from app bundle
    /// Falls back to default system sound if custom sound file is not found
    private let customNotificationSound: UNNotificationSound = {
        // Try custom sound first, fall back to default if not available
        return UNNotificationSound(named: UNNotificationSoundName("new-notification.mp3"))
    }()

    private override init() {
        super.init()
    }
    
    // MARK: - Notification Identifiers
    
    struct NotificationCategory {
        static let habitReminder = "HABIT_REMINDER"
    }
    
    struct NotificationAction {
        static let markDone = "MARK_DONE"
        static let snooze15 = "SNOOZE_15"
    }
    
    private enum NotificationError: LocalizedError {
        case invalidHabitId
        case invalidTime
        case schedulingFailed(String)
        case authorizationDenied
        
        var errorDescription: String? {
            switch self {
            case .invalidHabitId:
                return "Invalid habit identifier"
            case .invalidTime:
                return "Invalid reminder time"
            case .schedulingFailed(let reason):
                return "Failed to schedule notification: \(reason)"
            case .authorizationDenied:
                return "Notification authorization denied"
            }
        }
    }
    
    // MARK: - Setup
    
    func setupNotificationCategories() {
        #if DEBUG
        print("ℹ️ setupNotificationCategories() called but categories are already registered in App.init()")
        #endif
    }
    
    func requestAuthorization() async -> Bool {
        do {
            // Request standard permissions
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            #if DEBUG
            print("⚠️ Notification authorization error: \(error.localizedDescription)")
            #endif
            return false
        }
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - High-Level Scheduling API
    
        func scheduleForHabit(
            id: UUID,
            name: String,
            reminderTime: Date,
            scheduledDays: [Int]?,
            streak: Int,
            isArchived: Bool
        ) async {
            // Don't schedule for archived habits
            guard !isArchived else {
                await cancelNotification(for: id)
                return
            }
            
            // Cancel any existing notifications first to prevent "Ghost" notifications
            await cancelNotification(for: id)
            
            // Check authorization
            let status = await checkAuthorizationStatus()
            guard status == .authorized else {
                #if DEBUG
                print("⚠️ Cannot schedule - notifications not authorized")
                #endif
                return
            }
            
            // Extract time components
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            guard let hour = timeComponents.hour, let minute = timeComponents.minute else {
                #if DEBUG
                print("⚠️ Invalid time components")
                #endif
                return
            }
            
            // Create notification content
            let content = createNotificationContent(
                habitName: name,
                streak: streak,
                habitId: id
            )
            
            let isActuallyDaily = (scheduledDays?.count ?? 0) == 7
            
            // Schedule based on frequency
            if let days = scheduledDays, !days.isEmpty, !isActuallyDaily {

                await scheduleCustomDays(
                    habitId: id,
                    content: content,
                    hour: hour,
                    minute: minute,
                    days: days
                )
            } else {
                // Daily Notification
                // Case A: scheduledDays is nil (Default Daily)
                // Case B: scheduledDays is [1,2,3,4,5,6,7] (Manually selected all days)
                // Uses 1 slot (repeats: true)
                await scheduleDailyNotification(
                    habitId: id,
                    content: content,
                    hour: hour,
                    minute: minute
                )
            }
        }
    
    // MARK: - Low-Level Scheduling Methods
    
    /// Schedule a daily recurring notification
    private func scheduleDailyNotification(
        habitId: UUID,
        content: UNMutableNotificationContent,
        hour: Int,
        minute: Int
    ) async {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let identifier = "\(habitId)-daily"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            scheduledNotificationIds.insert(identifier)
        } catch {
            #if DEBUG
            print("⚠️ Failed to schedule daily notification: \(error.localizedDescription)")
            #endif
        }
    }
    
    /// Schedule notifications for specific days of the week
    private func scheduleCustomDays(
        habitId: UUID,
        content: UNMutableNotificationContent,
        hour: Int,
        minute: Int,
        days: [Int]
    ) async {
        for day in days {
            guard day >= 1 && day <= 7 else { continue }
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = day
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let identifier = "\(habitId)-day-\(day)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
                scheduledNotificationIds.insert(identifier)
            } catch {
                #if DEBUG
                print("⚠️ Failed to schedule notification for day \(day): \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    private func createNotificationContent(
        habitName: String,
        streak: Int,
        habitId: UUID
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        if streak > 0 {
            content.title = "\(habitName) · Day \(streak + 1)"
            content.subtitle = "Keep your streak going! 🔥"
        } else {
            content.title = habitName
            content.subtitle = "Time to build your habit"
        }
        
        let actionPrompts = [
            "Time to weave this thread.",
            "Your ritual awaits.",
            "A moment for yourself.",
            "Let's keep the streak going.",
            "Small step, big impact."
        ]
        content.body = actionPrompts.randomElement() ?? "Your ritual awaits."

        // Use custom notification sound
        content.sound = customNotificationSound
        content.categoryIdentifier = NotificationCategory.habitReminder
        
        content.userInfo = [
            "habitId": habitId.uuidString,
            "habitName": habitName,
            "streak": streak
        ]
        
        // ✅ TIME-SENSITIVE NOTIFICATIONS
        // Requires "Time Sensitive Notifications" entitlement from Apple
        // Without it, falls back to standard delivery (still works)
        // To request: https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }
        
        return content
    }
    
    /// Cancel all notifications for a habit (daily, custom days, and snooze)
    /// Always call this when habit is completed, archived, or deleted to prevent "ghost notifications" from snooze actions
    func cancelNotification(for habitId: UUID) async {
        var idsToRemove = ["\(habitId)-daily", "\(habitId)-snooze"]
        
        // Add all custom day notifications (weekday 1-7)
        for i in 1...7 {
            idsToRemove.append("\(habitId)-day-\(i)")
        }
        
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        
        // Remove from tracking set
        for id in idsToRemove {
            scheduledNotificationIds.remove(id)
        }
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        scheduledNotificationIds.removeAll()
    }
    
    /// Get pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    /// Clear delivered notifications
    func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - Notification Delegate

extension HabitNotificationManager: UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Extract data
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // Validate habit ID
        guard let habitIdString = userInfo["habitId"] as? String,
              let habitId = UUID(uuidString: habitIdString) else {
            completionHandler()
            return
        }
        
        let habitName = userInfo["habitName"] as? String ?? "Habit"
        let streak = userInfo["streak"] as? Int ?? 0
        
        // Handle on main thread
        Task { @MainActor in
            switch actionIdentifier {
                
            case NotificationAction.markDone:
                NotificationCenter.default.post(
                    name: .habitMarkDoneFromNotification,
                    object: nil,
                    userInfo: [
                        "habitId": habitId,
                        "habitName": habitName,
                        "streak": streak
                    ]
                )
                
            case NotificationAction.snooze15:
                Task.detached {
                    await HabitNotificationManager.shared.scheduleSnoozeNotification(
                        habitId: habitIdString,
                        habitName: habitName,
                        streak: streak
                    )
                }
                
            case UNNotificationDefaultActionIdentifier:
                NotificationCenter.default.post(
                    name: .habitNotificationTapped,
                    object: nil,
                    userInfo: [
                        "habitId": habitId,
                        "habitName": habitName
                    ]
                )
                
            default:
                break
            }
            
            // Call completion handler after operations
            completionHandler()
        }
    }
    
    /// Schedule a snooze notification for 15 minutes from now
    func scheduleSnoozeNotification(
        habitId: String,
        habitName: String,
        streak: Int
    ) async {
        let content = UNMutableNotificationContent()
        
        if streak > 0 {
            content.title = "\(habitName) · Day \(streak + 1)"
            content.subtitle = "Snoozed reminder 😴"
        } else {
            content.title = habitName
            content.subtitle = "Snoozed reminder"
        }
        
        content.body = "Time to complete this habit!"
        // Use custom notification sound for snooze as well
        content.sound = customNotificationSound
        content.categoryIdentifier = NotificationCategory.habitReminder

        content.userInfo = [
            "habitId": habitId,
            "habitName": habitName,
            "streak": streak,
            "isSnooze": true
        ]
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }
        
        // Trigger in 15 minutes
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 15 * 60,
            repeats: false
        )
        
        let identifier = "\(habitId)-snooze"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            await MainActor.run {
                print("⚠️ Failed to schedule snooze: \(error.localizedDescription)")
            }
            #endif
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user taps "Mark Done" from notification
    static let habitMarkDoneFromNotification = Notification.Name("habitMarkDoneFromNotification")
    
    /// Posted when user taps the notification itself
    static let habitNotificationTapped = Notification.Name("habitNotificationTapped")
    
    /// Posted when VitalityProgress is updated (day completed, RPE logged, etc.)
    /// Used to force DeskView refresh since @Query doesn't detect nested array changes
    static let vitalityProgressUpdated = Notification.Name("vitalityProgressUpdated")
}

