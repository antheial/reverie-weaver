//
// PomodoroSession.swift (CLEANED & FIXED)
// ReverieWeaver
//
// Enhanced with focus categories and proper notification handling
//

import SwiftUI
import SwiftData
import AudioToolbox
import UIKit
import UserNotifications

// MARK: - Focus Category
enum FocusCategory: String, CaseIterable, Codable {
    case work = "Work & Projects"
    case learning = "Learning & Growth"
    case creative = "Creative Practice"
    case wellness = "Health & Wellness"
    case personal = "Personal & Connection"
    case uncategorized = "Uncategorized"
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .learning: return "brain.head.profile"
        case .creative: return "paintbrush.fill"
        case .wellness: return "heart.fill"
        case .personal: return "person.2.fill"
        case .uncategorized: return "circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .work: return .sageGreen
        case .learning: return .dustyBlue
        case .creative: return .paleMauve
        case .wellness: return .terracottaRose
        case .personal: return Color(hex: "C9D2B5")
        case .uncategorized: return .gray
        }
    }
    
    var colorHex: String {
        switch self {
        case .work: return "C9D2B5"
        case .learning: return "B8C7D6"
        case .creative: return "E6D7D2"
        case .wellness: return "D9A58A"
        case .personal: return "C9D2B5"
        case .uncategorized: return "999999"
        }
    }
    
    var description: String {
        switch self {
        case .work: return "Projects, tasks, deep work"
        case .learning: return "Studying, courses, research"
        case .creative: return "Writing, design, art"
        case .wellness: return "Exercise, meditation, self-care"
        case .personal: return "Family, friends, hobbies"
        case .uncategorized: return "General focus time"
        }
    }
}

// MARK: - Pomodoro Session Model
@Model
final class PomodoroSession {
    var id: UUID
    var duration: Int // in minutes
    var completedAt: Date
    var sessionType: String // "work", "short_break", "long_break"
    var category: String? // FocusCategory rawValue
    var note: String? // Optional note about what you worked on
    
    init(duration: Int, completedAt: Date = Date(), sessionType: String = "work", category: FocusCategory? = nil, note: String? = nil) {
        self.id = UUID()
        self.duration = duration
        self.completedAt = completedAt
        self.sessionType = sessionType
        self.category = category?.rawValue
        self.note = note
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(completedAt)
    }
    
    var focusCategory: FocusCategory {
        if let category = category, let cat = FocusCategory(rawValue: category) {
            return cat
        }
        return .uncategorized
    }
}

// MARK: - Timer State
enum TimerState {
    case idle
    case running
    case paused
    case shortBreak
    case longBreak
    
    var displayName: String {
        switch self {
        case .idle: return "Ready to Focus"
        case .running: return "Work Session"
        case .paused: return "Paused"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "play.circle.fill"
        case .running: return "pause.circle.fill"
        case .paused: return "play.circle.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle, .running, .paused: return .sageGreen
        case .shortBreak: return .dustyBlue
        case .longBreak: return .paleMauve
        }
    }
}

// MARK: - Pomodoro Timer Manager
@Observable
class PomodoroTimerManager {
    // Timer state
    var timerState: TimerState = .idle
    var timeRemaining: Int = 1500
    var totalTime: Int = 1500
    var sessionCount: Int = 0
    var workDuration: Int = 25
    
    // UI state
    var isExpanded: Bool = false
    var showCompletionToast: Bool = false
    var showCategoryPicker: Bool = false
    
    // Settings
    var chimeEnabled: Bool = false
    
    // Category & notes
    var selectedCategory: FocusCategory = .uncategorized
    var sessionNote: String = ""
    
    // Background handling
    private var backgroundEntryTime: Date?
    private var wasRunningInBackground: Bool = false
    
    // System references
    private var timer: Timer?
    private var modelContext: ModelContext?
    private var originalBrightness: CGFloat = 1.0
    
    // MARK: - Initialization
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        requestNotificationPermission()
    }
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Time-Based Crystal Ball Effect
    var crystalBallColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        let isDaytime = hour >= 6 && hour < 18 // 6 AM to 6 PM
        return isDaytime ? .sageGreen : .paleMauve
    }
    
    var crystalBallGlow: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        let isDaytime = hour >= 6 && hour < 18
        return isDaytime ? Color.sageGreen.opacity(0.3) : Color.paleMauve.opacity(0.3)
    }
    
    // MARK: - Notification Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("✗ Notification permission error: \(error)")
            } else {
                print(granted ? "✓ Notifications enabled" : "✗ Notifications denied")
            }
        }
    }
    
    // MARK: - Timer Controls
    func startTimer() {
        if timerState == .idle {
            timeRemaining = workDuration * 60
            totalTime = timeRemaining
            // Show category picker before starting
            showCategoryPicker = true
            return
        }
        
        timerState = .running
        applyFocusMode()
        
        // Schedule notifications
        scheduleActiveTimerNotification()
        scheduleCompletionNotification()
        
        // Start timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func startTimerWithCategory() {
        showCategoryPicker = false
        timerState = .running
        applyFocusMode()
        
        // Schedule notifications
        scheduleActiveTimerNotification()
        scheduleCompletionNotification()
        
        // Start timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        cancelAllNotifications()
        restoreNormalMode()
    }
    
    func resumeTimer() {
        timerState = .running
        applyFocusMode()
        
        // Re-schedule notifications with updated time
        scheduleActiveTimerNotification()
        scheduleCompletionNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .idle
        timeRemaining = workDuration * 60
        totalTime = timeRemaining
        
        // Clean up all notifications
        cancelAllNotifications()
        restoreNormalMode()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
    
    func restartTimer() {
        timeRemaining = workDuration * 60
        totalTime = timeRemaining
        timerState = .running
        
        timer?.invalidate()
        cancelAllNotifications()
        
        applyFocusMode()
        scheduleActiveTimerNotification()
        scheduleCompletionNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func skipToBreak() {
        completeSession()
    }
    
    func setWorkDuration(_ minutes: Int) {
        workDuration = minutes
        
        if timerState == .idle {
            timeRemaining = minutes * 60
            totalTime = timeRemaining
        } else if timerState == .running || timerState == .paused {
            timeRemaining = minutes * 60
            totalTime = timeRemaining
        }
    }
    
    // MARK: - Timer Tick
    private func tick() {
        guard timeRemaining > 0 else {
            completeSession()
            return
        }
        timeRemaining -= 1
    }
    
    // MARK: - Session Completion
    private func completeSession() {
        timer?.invalidate()
        
        // Remove active notification
        cancelActiveTimerNotification()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Optional chime (only if app is open)
        if chimeEnabled {
            AudioServicesPlaySystemSound(1013)
        }
        
        // Save work session with category and note
        if timerState == .running {
            sessionCount += 1
            if let context = modelContext {
                let session = PomodoroSession(
                    duration: workDuration,
                    completedAt: Date(),
                    sessionType: "work",
                    category: selectedCategory,
                    note: sessionNote.isEmpty ? nil : sessionNote
                )
                context.insert(session)
                try? context.save()
            }
            
            // Reset note for next session
            sessionNote = ""
        }
        
        restoreNormalMode()
        
        // Show in-app toast
        showCompletionToast = true
        
        // Start appropriate break
        if timerState == .running {
            if sessionCount % 4 == 0 {
                startLongBreak()
            } else {
                startShortBreak()
            }
        } else {
            // Break completed, return to idle
            timerState = .idle
            timeRemaining = workDuration * 60
            totalTime = timeRemaining
        }
    }
    
    private func startShortBreak() {
        timerState = .shortBreak
        timeRemaining = 5 * 60
        totalTime = timeRemaining
        scheduleCompletionNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func startLongBreak() {
        timerState = .longBreak
        timeRemaining = 15 * 60
        totalTime = timeRemaining
        scheduleCompletionNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    // MARK: - Notifications
    private func scheduleActiveTimerNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Active"
        content.body = "Your \(workDuration)-minute focus session is in progress"
        content.sound = nil // Silent notification
        content.categoryIdentifier = "TIMER_ACTIVE"
        
        // Show immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pomodoroActive",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("✗ Error showing active notification: \(error)")
            } else {
                print("✓ Active timer notification shown")
            }
        }
    }
    
    private func scheduleCompletionNotification() {
        // Cancel any existing completion notification first
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["pomodoroCompletion"]
        )
        
        let content = UNMutableNotificationContent()
        
        switch timerState {
        case .running:
            content.title = "Focus Session Complete 🎯"
            let isLongBreak = sessionCount % 4 == 0
            content.body = isLongBreak
                ? "Well done. Time for a 15-minute rest."
                : "Great work. Take a 5-minute break."
            content.sound = chimeEnabled ? .default : nil
            content.categoryIdentifier = "TIMER_COMPLETE"
            
        case .shortBreak:
            content.title = "Break Complete ☕️"
            content.body = "Refreshed? Ready to continue weaving."
            content.sound = chimeEnabled ? .default : nil
            
        case .longBreak:
            content.title = "Long Break Complete 🌙"
            content.body = "Well rested. Begin your next cycle."
            content.sound = chimeEnabled ? .default : nil
            
        default:
            return
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(timeRemaining),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "pomodoroCompletion",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("✗ Error scheduling completion: \(error)")
            } else {
                print("✓ Completion notification scheduled for \(self.timeRemaining)s")
            }
        }
    }
    
    private func cancelActiveTimerNotification() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["pomodoroActive"]
        )
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["pomodoroActive"]
        )
    }
    
    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["pomodoroCompletion"]
        )
    }
    
    private func cancelAllNotifications() {
        cancelActiveTimerNotification()
        cancelCompletionNotification()
    }
    
    // MARK: - Background Handling
    func handleAppWillResignActive() {
        if timerState == .running {
            backgroundEntryTime = Date()
            wasRunningInBackground = true
            print("📱 App backgrounded - timer at \(timeRemaining)s")
        }
    }
    
    func handleAppDidBecomeActive() {
        guard wasRunningInBackground,
              let entryTime = backgroundEntryTime,
              timerState == .running else {
            wasRunningInBackground = false
            backgroundEntryTime = nil
            return
        }
        
        // Calculate elapsed time
        let elapsed = Int(Date().timeIntervalSince(entryTime))
        print("📱 App foregrounded - elapsed: \(elapsed)s")
        
        // Update time remaining
        timeRemaining = max(0, timeRemaining - elapsed)
        
        // Check if timer completed while in background
        if timeRemaining <= 0 {
            completeSession()
        }
        
        // Reset background tracking
        wasRunningInBackground = false
        backgroundEntryTime = nil
    }
    
    // MARK: - Focus Mode
    private func applyFocusMode() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.originalBrightness = UIScreen.main.brightness
            UIView.animate(withDuration: 1.0) {
                UIScreen.main.brightness = self.originalBrightness * 0.7
            }
            UIApplication.shared.isIdleTimerDisabled = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.isExpanded = true
            }
        }
    }
    
    private func restoreNormalMode() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 1.0) {
                UIScreen.main.brightness = self.originalBrightness
            }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    // MARK: - Toast Actions
    func startBreakFromToast() {
        showCompletionToast = false
        // Break is already started in completeSession()
    }
    
    func dismissToast() {
        showCompletionToast = false
        
        if timerState == .shortBreak || timerState == .longBreak {
            stopTimer()
        }
    }
    
    // MARK: - Computed Properties
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedMinutes: String {
        let minutes = timeRemaining / 60
        return "\(minutes)"
    }
}
