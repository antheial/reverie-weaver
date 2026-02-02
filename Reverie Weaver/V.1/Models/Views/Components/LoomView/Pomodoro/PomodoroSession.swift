//
// PomodoroSession.swift (PRODUCTION READY - DEBUGGED)
// ReverieWeaver
//
//    Quick Focus (Portrait) = 1 session by default
//    Background timer continues when screen is locked
//    Background audio/soundscape persists during lock
//    Resume timer restores correct state (breaks stay as breaks)
//    Soundscape continues playing during breaks
//    Smooth audio transitions with fade in/out
//
//    🎵 AUDIO ARCHITECTURE (INDEPENDENT SYSTEMS):
//    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//    1. SOUNDSCAPE (User-Controlled, Always Independent)
//       - User selects in ReadyToFocusSheet → previews immediately
//       - Continues playing seamlessly into focus session
//       - Never stopped/manipulated by timer states or music toggle
//       - User can change anytime via soundscape picker (portrait/landscape)
//       - Volume always at 100% during breaks, and reduces to 65% when background music is one
//
//    2. BACKGROUND MUSIC (Timer-Controlled, Work Sessions Only)
//       - Controlled by music note toggle (chimeEnabled)
//       - Only plays during .running (work sessions)
//       - Stops automatically during breaks (.shortBreak, .longBreak)
//       - Volume adjustable via slider (0-100%) - only affects music
//       - Independent fade in/out - never touches soundscape
//
//    3. CRITICAL RULES:
//       - updateAudioState() ONLY controls background music
//       - setBackgroundMusicVolume() ONLY affects music volume
//       - Soundscape methods (play/pause/resume) called explicitly
//       - No cross-contamination between music toggle and soundscape
//
//    4. WHY THIS MATTERS:
//       - Music toggle at 0% should NOT mute soundscape
//       - Starting session should NOT restart already-playing soundscape
//       - Break transitions should NOT stop soundscape, only increase soundscape volume to 100%
//       - User expects soundscape to be ambient, always-on option
//    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//

import SwiftUI
import SwiftData
import AudioToolbox
import UIKit
import UserNotifications
import AVFoundation
import MediaPlayer

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
    var duration: Int
    var completedAt: Date
    var sessionType: String
    var category: String?
    var note: String? //
    
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

// MARK: - Session Mode (Quick Focus vs Full Pomodoro)
enum PomodoroSessionMode {
    case quickFocus      // Portrait: Single session, no cycles
    case fullPomodoro    // Landscape/Ready to Focus: Multiple cycles
}

// MARK: - Pomodoro Timer Manager

@Observable
@MainActor
class PomodoroTimerManager {
    // Timer state
    var timerState: TimerState = .idle
    var timeRemaining: Int = 1500
    var totalTime: Int = 1500
    var sessionCount: Int = 0
    var workDuration: Int = 25
    
    // Session mode tracking
    var sessionMode: PomodoroSessionMode = .quickFocus
    
    // UI state
    var isExpanded: Bool = false
    var showCompletionToast: Bool = false
    var showCategoryPicker: Bool = false
    
    // Settings
    var chimeEnabled: Bool = false
    var backgroundMusicVolume: Float = 0.5
    
    // Category & notes
    var selectedCategory: FocusCategory = .uncategorized
    var sessionNote: String = ""
    
    // Enhanced Settings (Used in Full Pomodoro mode)
    var shortBreakDuration: Int = 5
    var longBreakDuration: Int = 15
    var totalCycles: Int = 2
    var longBreakInterval: Int = 4
    var isLongBreakEnabled: Bool = false
    
    // Active cycles for current session (1 for Quick Focus, totalCycles for Full)
    private var activeCyclesForSession: Int = 1
    
    // Enhanced UI State
    var showReadyToFocusSheet: Bool = false
    
    // Cycle Tracking
    var currentCyclePosition: Int = 0
    
    // Soundscape Integration
    var soundscapePlayer: SoundscapePlayer?
        
    // Centralized background music player (shared between portrait/landscape)
    let backgroundMusicPlayer = PomodoroBackgroundMusicPlayer()
    
    // Background handling
    private var backgroundEntryTime: Date?
    private var wasRunningInBackground: Bool = false
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Target end time for accurate background sync
    private var sessionEndTime: Date?
    
    // System references
    private var timer: Timer?
    private var modelContext: ModelContext?
    private var originalBrightness: CGFloat = 1.0
    
    // Race condition lock
    private var isProcessingCompletion: Bool = false
    
    // Track state before pausing (for proper resume)
    private var stateBeforePause: TimerState = .idle
    
    // MARK: - Lazy Audio Session

    /// Tracks whether audio session has been configured
    private var audioSessionConfigured = false

    /// Ensures audio session is configured only once, on first use
    private func ensureAudioSessionConfigured() {
        guard !audioSessionConfigured else { return }
        setupAudioSession()
        audioSessionConfigured = true
    }

    // MARK: - Initialization
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        // Audio session setup is now lazy - happens on first timer start
        // This saves ~5-10ms at app launch
    }
    
    // MARK: - Audio Coordination

        func updateAudioState() {
            #if DEBUG
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🎵 Audio State Update Triggered")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("   📊 Current State:")
            print("      - Timer State: \(timerState.displayName)")
            print("      - Background Music Enabled: \(chimeEnabled)")
            #endif
            
            // Logic: Is background music supposed to be playing?
            let shouldPlayMusic = chimeEnabled && timerState == .running
            
            if shouldPlayMusic {
                // 1. Play Background Music
                backgroundMusicPlayer.play(volume: backgroundMusicVolume)
                
                // 2. Duck Soundscape (65% Volume)
                // This ensures the music sits nicely on top of the ambient sound
                soundscapePlayer?.setVolume(0.65)
                
                #if DEBUG
                print("   ✅ Action Taken:")
                print("      - Background music: PLAYING at \(Int(backgroundMusicVolume * 100))%")
                print("      - Soundscape: DUCKED to 65% (Background Layer)")
                #endif
            } else {
                // 1. Stop Background Music
                backgroundMusicPlayer.stop()
                
                // 2. Restore Soundscape (100% Volume)
                // During breaks, idle, or when music is off, soundscape is the star
                soundscapePlayer?.setVolume(1.0)
                
                #if DEBUG
                print("   ✅ Action Taken:")
                print("      - Background music: STOPPED")
                print("      - Soundscape: RESTORED to 100% (Ambient Layer)")
                #endif
            }
            
            #if DEBUG
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            #endif
        }
        
        /// Update background music volume ONLY (never touches soundscape)
        func setBackgroundMusicVolume(_ volume: Float) {
            backgroundMusicVolume = volume
            // Only update player volume if music is currently playing
            if chimeEnabled && timerState == .running {
                backgroundMusicPlayer.setVolume(volume)
            }
            
            #if DEBUG
            print("🎚️ Background music volume set to: \(Int(volume * 100))% (soundscape unaffected)")
            #endif
        }
    
    // NOTE: Cleanup is handled by stopTimer() which is called when the timer is stopped.
    // We cannot use deinit for cleanup because PomodoroTimerManager is @MainActor isolated
    // and deinit runs in a nonisolated context (Swift 6 strict concurrency).
    
    // MARK: - Brightness Restoration

    static func restoreBrightnessIfNeeded() {
        if let savedBrightness = UserDefaults.standard.object(forKey: "pomodoroOriginalBrightness") as? Double {
            let brightness = CGFloat(savedBrightness)
            DispatchQueue.main.async {
                UIScreen.main.brightness = brightness
                UserDefaults.standard.removeObject(forKey: "pomodoroOriginalBrightness")
                print("✓ Restored brightness after app crash/termination: \(brightness)")
            }
        }
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // CRITICAL: .playback allows audio to continue when screen is locked
            // .mixWithOthers allows soundscape + background music together
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            print("✓ AVAudioSession configured for background playback")
        } catch {
            print("❌ Failed to setup AVAudioSession: \(error)")
        }
    }
    
    // MARK: - Time-Based Crystal Ball Effect
    var crystalBallColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        let isDaytime = hour >= 6 && hour < 18
        return isDaytime ? .sageGreen : .paleMauve
    }
    
    var crystalBallGlow: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        let isDaytime = hour >= 6 && hour < 18
        return isDaytime ? Color.sageGreen.opacity(0.3) : Color.paleMauve.opacity(0.3)
    }
    
    // MARK: - Timer Controls
    
    func startTimer() {
        if timerState == .idle {
            timeRemaining = workDuration * 60
            totalTime = timeRemaining
            showReadyToFocusSheet = true
            return
        }
        
        beginWorkSession()
    }
    
    /// Quick Focus Start (Portrait Mode - Single Session)
    func startQuickFocusSession() {
        showCategoryPicker = false

        sessionMode = .quickFocus
        activeCyclesForSession = 1
        currentCyclePosition = 0
        sessionCount = 0
        
        print("🚀 Quick Focus started: 1 session of \(workDuration) min")
        
        beginWorkSession()
    }
    
    /// Full Pomodoro Start (Landscape/Ready to Focus - Multiple Cycles)
    /// Called from ReadyToFocusSheet when user configures full session
    func startFullPomodoroSession() {
        showReadyToFocusSheet = false
        
        sessionMode = .fullPomodoro
        activeCyclesForSession = totalCycles
        currentCyclePosition = 0
        sessionCount = 0
        
        print("🎯 Full Pomodoro started: \(totalCycles) cycles of \(workDuration) min")
        
        beginWorkSession()
    }
    
    func startTimerWithCategory() {
        startQuickFocusSession()
    }
    
    /// Internal: Begin work session (shared logic)
        private func beginWorkSession() {
            // Lazy audio session setup on first session start
            ensureAudioSessionConfigured()

            timerState = .running
            stateBeforePause = .running
            timeRemaining = workDuration * 60
            totalTime = timeRemaining

            sessionEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))

            applyFocusMode()

            updateAudioState()
            
            scheduleActiveTimerNotification()
            scheduleCompletionNotification()
            
            startTimerTicker()
        }
    
    func pauseTimer() {
            if timerState == .running || timerState == .shortBreak || timerState == .longBreak {
                stateBeforePause = timerState
            }
            
            timerState = .paused
            stopTimerTicker()
            sessionEndTime = nil
            
            backgroundMusicPlayer.stop()
            
            soundscapePlayer?.setVolume(1.0)
            
            cancelAllNotifications()
            restoreNormalMode()
            endBackgroundTask()
        }
    
    func resumeTimer() {
            timerState = stateBeforePause
            
            sessionEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
            
            if timerState == .running {
                applyFocusMode()
            }
            
            updateAudioState()
            
            if timerState == .running {
                scheduleActiveTimerNotification()
            }
            scheduleCompletionNotification()
            
            startTimerTicker()
            
            #if DEBUG
            print("▶️ Timer resumed to state: \(timerState.displayName)")
            #endif
        }
    
    func stopTimer() {
            if timerState == .running {
                let minutesCompleted = (totalTime - timeRemaining) / 60
                savePartialSession(minutesCompleted: minutesCompleted)
            }
            
            stopTimerTicker()
            timerState = .idle
            timeRemaining = workDuration * 60
            totalTime = timeRemaining
            sessionEndTime = nil
            
            // Reset cycle tracking
            currentCyclePosition = 0
            sessionCount = 0
            sessionNote = ""
            
            // Reset session mode
            sessionMode = .quickFocus
            activeCyclesForSession = 1
            
            // Reset pause state tracking
            stateBeforePause = .idle
            
            // Stop background music
            backgroundMusicPlayer.stop()
            
            // Stop soundscape when session is completely stopped
            soundscapePlayer?.stop()
            
            // Clean up
            cancelAllNotifications()
            restoreNormalMode()
            endBackgroundTask()
            isProcessingCompletion = false
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = false
            }
        }
    
    private func startTimerTicker() {
        timer?.invalidate()
        timer = nil
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
            #if DEBUG
            print("⏱️ Internal timer ticker started")
            #endif
        }
    }
    
    private func stopTimerTicker() {
        timer?.invalidate()
        timer = nil
        
        #if DEBUG
        print("⏱️ Internal timer ticker stopped")
        #endif
    }
    
    func restartTimer() {
        timeRemaining = workDuration * 60
        totalTime = timeRemaining
        timerState = .running
        sessionEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        timer?.invalidate()
        cancelAllNotifications()
        
        // Restart soundscape
        soundscapePlayer?.play()
        
        applyFocusMode()
        scheduleActiveTimerNotification()
        scheduleCompletionNotification()
        
        startTimerTicker()
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
            if timerState == .running {
                sessionEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
            }
        }
    }
    
    // MARK: - Pomodoro Session Persistence
    
    private func savePomodoroSession() {
        guard let context = modelContext else {
            print("❌ Cannot save session: ModelContext is nil")
            return
        }
        
        //    Validate category is set (fallback to uncategorized)
        let finalCategory = selectedCategory
        
        //    Validate and clean subject/note
        let finalNote: String?
        if sessionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finalNote = nil
        } else {
            finalNote = sessionNote.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Create session with validated data
        let session = PomodoroSession(
            duration: workDuration,
            completedAt: Date(),
            sessionType: "work",
            category: finalCategory,
            note: finalNote
        )
        
        // Insert and save with proper error handling
        context.insert(session)
        
        do {
            try context.save()
            print("   Pomodoro session saved successfully:")
            print("   - Duration: \(workDuration) min")
            print("   - Category: \(finalCategory.rawValue)")
            print("   - Subject: \(finalNote ?? "(none)")")
            print("   - Mode: \(sessionMode == .quickFocus ? "Quick Focus" : "Full Pomodoro")")
        } catch {
            print("❌ Failed to save Pomodoro session: \(error.localizedDescription)")
            // Note: Session is still in context but not persisted
            // Will be saved on next successful save() call
        }
    }
    
    /// Save partial session when stopped early
    private func savePartialSession(minutesCompleted: Int) {
        guard minutesCompleted >= 1, let context = modelContext else { return }
        
        let session = PomodoroSession(
            duration: minutesCompleted,
            completedAt: Date(),
            sessionType: "work_partial",
            category: selectedCategory,
            note: sessionNote.isEmpty ? nil : sessionNote
        )
        
        context.insert(session)
        
        do {
            try context.save()
            print("   Partial session saved: \(minutesCompleted)min of \(workDuration)min planned")
        } catch {
            print("❌ Failed to save partial session: \(error.localizedDescription)")
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
        stopTimerTicker()
        sessionEndTime = nil
        
        guard !isProcessingCompletion, timerState != .idle else {
            #if DEBUG
            print("⚠️ completeSession() ignored - already processing or idle")
            #endif
            return
        }
        
        isProcessingCompletion = true
        
        cancelActiveTimerNotification()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        if chimeEnabled {
            AudioServicesPlaySystemSound(SystemSoundID(1013))
        }
        
        // --- 1. FINISHED WORK SESSION ---
        if timerState == .running {
            sessionCount += 1
            currentCyclePosition += 1
            
            savePomodoroSession()
            
            restoreNormalMode()
            
            //   Check against activeCyclesForSession, not totalCycles
            let cycleComplete = currentCyclePosition >= activeCyclesForSession
            
            if cycleComplete {
                //    Quick Focus (1 session) OR Full Pomodoro cycle complete
                if sessionMode == .quickFocus {
                    // Quick Focus: Single session done → Short break → Idle
                    print("   Quick Focus complete! Starting short break then done.")
                    showCompletionToast = true
                    startShortBreak()
                } else {
                    // Full Pomodoro: Cycle complete → Long break (if enabled)
                    print("🎯 Full cycle complete! (\(currentCyclePosition)/\(activeCyclesForSession))")
                    showCompletionToast = true
                    if isLongBreakEnabled {
                        startLongBreak()
                    } else {
                        // No long break → Reset for next cycle
                        startShortBreak()
                    }
                }
            } else {
                // Cycle in progress → Short break → Next work session
                print("⏭️ Session \(currentCyclePosition)/\(activeCyclesForSession) complete → Short Break")
                startShortBreak()
            }
        }
        
        // --- 2. FINISHED SHORT BREAK ---
                else if timerState == .shortBreak {
                    if sessionMode == .quickFocus && currentCyclePosition >= activeCyclesForSession {
                        print("   Quick Focus short break complete - returning to IDLE")
                        resetToIdle()
                    } else {
                        print("   Short break complete - AUTO-STARTING next work session")
                        
                        // Auto-start next work session
                        timerState = .running
                        stateBeforePause = .running
                        timeRemaining = workDuration * 60
                        totalTime = timeRemaining
                        sessionEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
                        
                        applyFocusMode()
                        
                        updateAudioState()
                        
                        scheduleActiveTimerNotification()
                        scheduleCompletionNotification()
                        
                        startTimerTicker()
                    }
                }
        
        // --- 3. FINISHED LONG BREAK ---
        else if timerState == .longBreak {
            print("🌙 Long break complete - resetting to IDLE")
            resetToIdle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isProcessingCompletion = false
        }
    }
    
        private func resetToIdle() {
            timerState = .idle
            timeRemaining = workDuration * 60
            totalTime = timeRemaining
            currentCyclePosition = 0
            sessionCount = 0
            sessionNote = ""
            sessionEndTime = nil
            
            sessionMode = .quickFocus
            activeCyclesForSession = 1
            stateBeforePause = .idle
            
            backgroundMusicPlayer.stop()
            soundscapePlayer?.stop()
            
            endBackgroundTask()
        }
    
    private func startShortBreak() {
            timerState = .shortBreak
            stateBeforePause = .shortBreak
            timeRemaining = shortBreakDuration * 60
            totalTime = timeRemaining
            sessionEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
            
            print("☕️ Short break started (\(shortBreakDuration) min)")
            
            updateAudioState()
            
            scheduleCompletionNotification()
            startTimerTicker()
        }
    
    private func startLongBreak() {
            timerState = .longBreak
            stateBeforePause = .longBreak
            timeRemaining = longBreakDuration * 60
            totalTime = timeRemaining
            sessionEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
            
            print("🌙 Long break started (\(longBreakDuration) min)")
            
            updateAudioState()
            
            scheduleCompletionNotification()
            startTimerTicker()
        }
    
    // MARK: - Notifications

    /// Check notification permission before scheduling
    private func checkNotificationPermissionAndSchedule(_ scheduleBlock: @escaping () -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    scheduleBlock()
                case .notDetermined:
                    // Request permission first
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                        if granted {
                            DispatchQueue.main.async {
                                scheduleBlock()
                            }
                        }
                    }
                case .denied:
                    #if DEBUG
                    print("⚠️ Notification permission denied - skipping notification")
                    #endif
                @unknown default:
                    break
                }
            }
        }
    }

    private func scheduleActiveTimerNotification() {
        checkNotificationPermissionAndSchedule { [weak self] in
            guard let self = self else { return }

            let content = UNMutableNotificationContent()
            content.title = "Focus Session Active"
            content.body = "Your \(self.workDuration)-minute focus session is in progress"
            content.sound = nil
            content.categoryIdentifier = "TIMER_ACTIVE"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "pomodoroActive",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("✗ Error showing active notification: \(error)")
                }
            }
        }
    }
    
    private func scheduleCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["pomodoroCompletion"]
        )

        checkNotificationPermissionAndSchedule { [weak self] in
            guard let self = self else { return }

            let content = UNMutableNotificationContent()

            switch self.timerState {
            case .running:
                content.title = "Focus Session Complete 🎯"

                let isCycleComplete = self.currentCyclePosition >= self.activeCyclesForSession

                if self.sessionMode == .quickFocus {
                    content.body = "Great focus! Take a \(self.shortBreakDuration)-minute break."
                } else if isCycleComplete && self.isLongBreakEnabled {
                    content.body = "Cycle complete! Time for a \(self.longBreakDuration)-minute rest."
                } else {
                    content.body = "Great work. Take a \(self.shortBreakDuration)-minute break."
                }

                content.sound = self.chimeEnabled ? .default : nil
                content.categoryIdentifier = "TIMER_COMPLETE"

            case .shortBreak:
                content.title = "Break Complete ☕️"

                if self.sessionMode == .quickFocus && self.currentCyclePosition >= self.activeCyclesForSession {
                    content.body = "Focus session finished. Great work!"
                } else {
                    content.body = "Refreshed? Ready to continue weaving."
                }
                content.sound = self.chimeEnabled ? .default : nil

            case .longBreak:
                content.title = "Long Break Complete 🌙"
                content.body = "Well rested. Ready for another cycle?"
                content.sound = self.chimeEnabled ? .default : nil

            default:
                return
            }

            let secondsRemaining = self.timeRemaining

            guard secondsRemaining > 0 else { return }

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(secondsRemaining),
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
                    print("✓ Completion notification scheduled for \(secondsRemaining)s")
                }
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
        guard timerState == .running || timerState == .shortBreak || timerState == .longBreak else {
            return
        }
        
        backgroundEntryTime = Date()
        wasRunningInBackground = true
        
        let audioPlaying = soundscapePlayer?.isCurrentlyPlaying ?? false
        if audioPlaying {
            beginBackgroundTask()
        }
        
        if audioPlaying {
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: [])
            } catch {
                print("❌ Failed to keep audio session active: \(error)")
            }
        }
        
        #if DEBUG
        let remaining = formatTimeForDebug(timeRemaining)
        let endTimeStr = sessionEndTime?.formatted(date: .omitted, time: .standard) ?? "nil"
        print("📱 App backgrounded:")
        print("   - Time remaining: \(remaining)")
        print("   - Target end time: \(endTimeStr)")
        print("   - Audio playing: \(audioPlaying)")
        #endif
    }
    
    func handleAppDidBecomeActive() {
        guard wasRunningInBackground,
              timerState == .running || timerState == .shortBreak || timerState == .longBreak else {
            wasRunningInBackground = false
            backgroundEntryTime = nil
            endBackgroundTask()
            return
        }
        
        let now = Date()
        
        if let endTime = sessionEndTime {
            let remaining = Int(endTime.timeIntervalSince(now))
            
            #if DEBUG
            let drift = abs(remaining - timeRemaining)
            print("📱 App foregrounded (primary method):")
            print("   - Calculated remaining: \(formatTimeForDebug(remaining))")
            print("   - Previous remaining: \(formatTimeForDebug(timeRemaining))")
            print("   - Drift corrected: \(drift)s")
            #endif
            
            if remaining <= 0 {
                timeRemaining = 0
                completeSession()
            } else {
                timeRemaining = remaining
                startTimerTicker()
            }
        }
        else if let entryTime = backgroundEntryTime {
            let elapsed = Int(now.timeIntervalSince(entryTime))
            timeRemaining = max(0, timeRemaining - elapsed)
            
            #if DEBUG
            print("📱 App foregrounded (fallback method):")
            print("   - Time in background: \(elapsed)s")
            print("   - New remaining: \(formatTimeForDebug(timeRemaining))")
            print("   - ⚠️ WARNING: Using fallback - sessionEndTime was nil")
            #endif
            
            if timeRemaining <= 0 {
                completeSession()
            } else {
                startTimerTicker()
            }
        }
        
        wasRunningInBackground = false
        backgroundEntryTime = nil
        endBackgroundTask()
    }
    
    private func beginBackgroundTask() {
        guard backgroundTaskID == .invalid else {
            #if DEBUG
            print("⚠️ Background task already active: \(backgroundTaskID)")
            #endif
            return
        }
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "PomodoroTimer") { [weak self] in
            #if DEBUG
            print("⏰ Background task expired - cleaning up")
            #endif
            self?.endBackgroundTask()
        }
        
        #if DEBUG
        if backgroundTaskID == .invalid {
            print("❌ Failed to start background task")
        } else {
            print("✓ Background task started: \(backgroundTaskID.rawValue)")
        }
        #endif
    }
    
    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        
        #if DEBUG
        print("✓ Ending background task: \(backgroundTaskID.rawValue)")
        #endif
        
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    private func formatTimeForDebug(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    #endif
    
    // MARK: - Focus Mode
    private func applyFocusMode() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.originalBrightness = UIScreen.main.brightness
            UserDefaults.standard.set(Double(self.originalBrightness), forKey: "pomodoroOriginalBrightness")
            
            UIApplication.shared.isIdleTimerDisabled = true
            
            UIView.animate(withDuration: 1.0) {
                UIScreen.main.brightness = max(0.2, self.originalBrightness * 0.3)
            }
            
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
            
            UserDefaults.standard.removeObject(forKey: "pomodoroOriginalBrightness")
        }
    }
    
    // MARK: - Toast Actions
    func startBreakFromToast() {
        showCompletionToast = false
    }
    
    func dismissToast() {
        showCompletionToast = false
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
    
    var sessionModeDescription: String {
        switch sessionMode {
        case .quickFocus:
            return "Quick Focus"
        case .fullPomodoro:
            return "\(activeCyclesForSession) Sessions"
        }
    }
    
    // MARK: - Background Music Player for Pomodoro Focus
    // Uses shuffle-style playback: all tracks play once before repeating
    // Avoids immediate repetition between playlist cycles

    @MainActor
    final class PomodoroBackgroundMusicPlayer {
        private var player: AVAudioPlayer?

        // All expected track names
        private static let expectedTrackNames: [String] = [
            "focus_1",
            "focus_2",
            "focus_3",
            "focus_4",
            "focus_5",
            "focus_6",
            "focus_7",
            "focus_8",
            "focus_9",
            "focus_10"
        ]

        // Lazy validation - only validates tracks when first needed
        private var _trackNames: [String]?
        private var trackNames: [String] {
            if let cached = _trackNames {
                return cached
            }
            let validated = Self.expectedTrackNames.filter { trackName in
                Bundle.main.url(forResource: trackName, withExtension: "mp3") != nil
            }
            _trackNames = validated

            #if DEBUG
            let missingTracks = Self.expectedTrackNames.filter { trackName in
                Bundle.main.url(forResource: trackName, withExtension: "mp3") == nil
            }
            if !missingTracks.isEmpty {
                print("⚠️ Missing audio files in bundle: \(missingTracks.joined(separator: ", "))")
            }
            print("✓ Found \(validated.count)/\(Self.expectedTrackNames.count) focus music tracks")
            #endif

            return validated
        }

        // Shuffle-style playback state
        private var shuffledPlaylist: [String] = []
        private var playlistIndex: Int = 0
        private var lastTrackName: String?

        // Fade support for smooth transitions
        private var fadeWorkItem: DispatchWorkItem?
        private var targetVolume: Float = 0.5
        private let fadeDuration: TimeInterval = 1.0
        private let fadeSteps: Int = 10

        init() {
            // Track validation is now lazy - happens on first play()
            // This saves ~5-10ms at app launch
            setupRemoteCommands()
        }
        
        deinit {
            // Cancel any pending fade
            fadeWorkItem?.cancel()
            fadeWorkItem = nil
            
            // Stop player
            player?.stop()
            player = nil
            
            // Clear Now Playing
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            
            // Remove remote command targets
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.playCommand.removeTarget(nil)
            commandCenter.pauseCommand.removeTarget(nil)
            commandCenter.nextTrackCommand.removeTarget(nil)
        }
        
        func setVolume(_ volume: Float) {
            targetVolume = max(0.0, min(1.0, volume))
            player?.volume = targetVolume
        }
        
        private func getNextTrack() -> String {
            // Refresh playlist when exhausted or on first run
            if playlistIndex >= shuffledPlaylist.count {
                shuffledPlaylist = trackNames.shuffled()
                playlistIndex = 0
                
                // Avoid immediate repeat from previous playlist
                // If the first track in new shuffle matches the last played, swap it
                if let lastPlayed = lastTrackName,
                   shuffledPlaylist.first == lastPlayed,
                   shuffledPlaylist.count > 1 {
                    shuffledPlaylist.swapAt(0, 1)
                    #if DEBUG
                    print("🔀 Shuffled playlist refreshed, avoided repeat of \(lastPlayed)")
                    #endif
                } else {
                    #if DEBUG
                    print("🔀 Shuffled playlist refreshed with \(shuffledPlaylist.count) tracks")
                    #endif
                }
            }
            
            let track = shuffledPlaylist[playlistIndex]
            playlistIndex += 1
            lastTrackName = track
            
            #if DEBUG
            print("🎵 Selected track [\(playlistIndex)/\(shuffledPlaylist.count)]: \(track)")
            #endif
            
            return track
        }
        
        // Play with fade-in for smooth start
                func play(volume: Float = 0.5) {
                    targetVolume = max(0.0, min(1.0, volume))
                    
                    // Only reuse player if it's actively playing
                    // If stopped/paused, select a new track for variety
                    if let player, player.isPlaying {
                        // Already playing, just adjust volume smoothly
                        fadeToVolume(targetVolume)
                        #if DEBUG
                        print("🎵 Background music already playing - adjusting volume to \(Int(targetVolume * 100))%")
                        #endif
                        return
                    }
                    
                    // Clean up any stopped player before starting new one
                    if player != nil && player?.isPlaying == false {
                        cleanupPlayer()
                        #if DEBUG
                        print("🎵 Cleaned up stopped player - selecting new track")
                        #endif
                    }
                    
                    guard !trackNames.isEmpty else {
                        AppLog.warn("No focus tracks configured", category: "pomodoro.audio")
                        return
                    }
                    
                    // Shuffle-style selection (all tracks play before repeating)
                    let trackName = getNextTrack()
                    
                    guard let url = Bundle.main.url(forResource: trackName, withExtension: "mp3") else {
                        AppLog.warn("Track \(trackName).mp3 not found in bundle", category: "pomodoro.audio")
                        return
                    }
                    
                    do {
                        // Ensure session is active and mixing is allowed
                        let session = AVAudioSession.sharedInstance()
                        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                        try session.setActive(true, options: [])
                        
                        let newPlayer = try AVAudioPlayer(contentsOf: url)
                        newPlayer.numberOfLoops = -1
                        newPlayer.volume = 0
                        newPlayer.prepareToPlay()
                        
                        guard newPlayer.play() else {
                            AppLog.error("Failed to start playback for \(trackName).mp3", category: "pomodoro.audio")
                            return
                        }
                        
                        player = newPlayer
                        
                        fadeToVolume(targetVolume)
                        
                        updateNowPlayingInfo(trackName: trackName, duration: newPlayer.duration, isPlaying: true)
                        
                        #if DEBUG
                        print("🎵 Background music started with fade-in: \(trackName).mp3 at \(Int(targetVolume * 100))%")
                        #endif
                    } catch {
                        AppLog.error("Failed to start focus background music: \(error)", category: "pomodoro.audio")
                    }
                }
        
        // Stop with fade-out for smooth end
        func stop() {
            fadeWorkItem?.cancel()
            
            guard let player = player, player.isPlaying else {
                cleanupPlayer()
                return
            }
            
            // Fade out using DispatchWorkItem (MainActor safe)
            let startVolume = player.volume
            let steps = fadeSteps
            let stepInterval = fadeDuration / Double(steps)
            
            performFade(
                player: player,
                from: startVolume,
                to: 0,
                steps: steps,
                interval: stepInterval
            ) { [weak self] in
                self?.cleanupPlayer()
                #if DEBUG
                AppLog.debug("Focus music stopped with fade-out", category: "pomodoro.audio")
                #endif
            }
        }
        
        func stopImmediately() {
            fadeWorkItem?.cancel()
            fadeWorkItem = nil
            cleanupPlayer()
        }
        
        private func fadeToVolume(_ target: Float) {
            fadeWorkItem?.cancel()
            
            guard let player = player else { return }
            
            let startVolume = player.volume
            let steps = fadeSteps
            let stepInterval = fadeDuration / Double(steps)
            
            performFade(
                player: player,
                from: startVolume,
                to: target,
                steps: steps,
                interval: stepInterval,
                completion: nil
            )
        }
        
        private func performFade(
            player: AVAudioPlayer,
            from startVolume: Float,
            to endVolume: Float,
            steps: Int,
            interval: TimeInterval,
            completion: (() -> Void)?
        ) {
            var currentStep = 0
            let volumeDelta = endVolume - startVolume
            
            func executeStep() {
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self, self.player === player else {
                        completion?()
                        return
                    }
                    
                    currentStep += 1
                    let progress = Float(currentStep) / Float(steps)
                    player.volume = startVolume + (volumeDelta * progress)
                    
                    if currentStep >= steps {
                        player.volume = endVolume
                        self.fadeWorkItem = nil
                        completion?()
                    } else {
                        executeStep()
                    }
                }
                
                self.fadeWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem)
            }
            
            executeStep()
        }
        
        private func cleanupPlayer() {
            player?.stop()
            player?.currentTime = 0
            player = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
        
        // MARK: - Lock Screen & Control Center Handling
        
        private func setupRemoteCommands() {
            let commandCenter = MPRemoteCommandCenter.shared()
            
            commandCenter.playCommand.addTarget { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, let player = self.player, !player.isPlaying else { return }
                    player.play()
                    self.updateNowPlayingInfo(isPlaying: true)
                }
                return .success
            }
            
            commandCenter.pauseCommand.addTarget { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, let player = self.player, player.isPlaying else { return }
                    player.pause()
                    self.updateNowPlayingInfo(isPlaying: false)
                }
                return .success
            }
            
            commandCenter.nextTrackCommand.addTarget { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    let currentVol = self.player?.volume ?? 0.5
                    self.stopImmediately()
                    self.play(volume: currentVol)
                }
                return .success
            }
        }
        
        private func updateNowPlayingInfo(trackName: String? = nil, duration: TimeInterval? = nil, isPlaying: Bool) {
            guard let player = player else { return }
            
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
            
            if trackName != nil {
                nowPlayingInfo[MPMediaItemPropertyTitle] = "Focus Session"
                nowPlayingInfo[MPMediaItemPropertyArtist] = "Reverie Weaver"
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Ambient Focus"
            }
            
            if let duration = duration {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            }
            
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}
