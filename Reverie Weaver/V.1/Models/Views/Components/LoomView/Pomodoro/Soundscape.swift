//
//  Soundscape.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/26/25.
//
//  NOV 2025
//  - Interruption recovery (phone calls, Siri)
//  - Route change handling (headphones unplugged)
//  - Fade in/out transitions (smooth volume ramps)
//  - Crossfade between soundscapes
//  - Error state feedback for UI
//  - Loading state indicator
//  - Use actual audio player state (isCurrentlyPlaying) for reliable playback checks
//  - Resume handles already-playing state correctly
//  - pauseWithFade() for smooth pause transitions
//  - signalStateTransition() for audible "breath" during work↔break changes
//

import SwiftUI
import AVFoundation

// MARK: - Soundscape Types
enum Soundscape: String, CaseIterable, Codable {
    case none = "None"
    case cafe = "Café"
    case rain = "Rain"
    case forest = "Forest"
    case ocean = "Ocean"
    case campfire = "Campfire"
    case campfireCrackling = "Campfire Crackling"
    case forestMorning = "Forest Morning"
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .rain: return "cloud.rain.fill"
        case .forest: return "tree.fill"
        case .ocean: return "water.waves"
        case .campfire: return "flame.fill"
        case .campfireCrackling: return "flame.circle.fill"
        case .forestMorning: return "sun.and.horizon.fill"
        }
    }
    
    var audioFileName: String? {
        switch self {
        case .none: return nil
        case .cafe: return "cafe_ambiance"
        case .rain: return "rain_ambiance"
        case .forest: return "forest_ambiance"
        case .ocean: return "ocean_ambiance"
        case .campfire: return "campfire_ambiance"
        case .campfireCrackling: return "campfire_crackling"
        case .forestMorning: return "forest_morning"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Soundscape Player
@Observable
class SoundscapePlayer {
    // MARK: - Public State
    var selectedSoundscape: Soundscape = .none
    var isMuted: Bool = false
    var backgroundMusicEnabled: Bool = false
        
    private var isDucked: Bool = false
    
    var isLoading: Bool = false
    var hasError: Bool = false
    var errorMessage: String?
    
    // MARK: - Private State
    private var audioPlayer: AVAudioPlayer?
    private var crossfadePlayer: AVAudioPlayer?
    private var isPlaying: Bool = false
    
    private var wasPlayingBeforeInterruption: Bool = false
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    
    private var fadeTimer: Timer?
    private var targetVolume: Float = 1.0
    private let fadeDuration: TimeInterval = 1.5
    private let fadeSteps: Int = 15
    
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

    init() {
        // Defer audio session setup until first playback
        // This saves ~5-10ms at app launch
        setupInterruptionHandling()
    }
    
    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        fadeTimer?.invalidate()
        audioPlayer?.stop()
        crossfadePlayer?.stop()
        audioPlayer = nil
        crossfadePlayer = nil
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✓ Soundscape audio session configured")
            hasError = false
        } catch {
            print("✗ Failed to setup audio session: \(error)")
            hasError = true
            errorMessage = "Audio setup failed"
        }
    }
    
    // MARK: - Interruption Handling
    private func setupInterruptionHandling() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioInterruption(notification)
        }
        
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }
    
    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption started - remember state and pause
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying {
                audioPlayer?.pause()
                isPlaying = false
                print("⏸️ Soundscape paused - interruption began")
            }
            
        case .ended:
            // Interruption ended - check if we should resume
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) && wasPlayingBeforeInterruption {
                // Delay slightly for audio system to stabilize
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.resume()
                    print("▶️ Soundscape resumed after interruption")
                }
            }
            wasPlayingBeforeInterruption = false
            
        @unknown default:
            break
        }
    }
    
    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            if isPlaying {
                pause()
                print("⏸️ Soundscape paused - audio device disconnected")
            }
        default:
            break
        }
    }
    
    // MARK: - Playback Controls
    
    func play() {
        // 1. Guard Check: Basic validation
        // Ensures we have a valid soundscape, not muted, and a valid file name.
        // If invalid, it stops playback safely.
        guard selectedSoundscape != Soundscape.none,
              !isMuted,
              let fileName = selectedSoundscape.audioFileName else {
            stop()
            return
        }
        
        // 2. State Check: Is audio currently playing?
        if isCurrentlyPlaying {
            // Scenario A: Same soundscape is already playing
            // We check if the file URL matches the selected soundscape.
            if let currentURL = audioPlayer?.url?.lastPathComponent, currentURL.contains(fileName) {
                // Action: Just ensure volume is correct (e.g., if we are ducking/unducking).
                // NO FADE: Instant volume adjustment for soundscape
                if audioPlayer?.volume != targetVolume {
                    audioPlayer?.volume = targetVolume
                }
                return // Exit: No need to restart or crossfade.
            }
            
            // Scenario B: Different soundscape is selected
            // Action: Crossfade smoothly from the old sound to the new one.
            crossfadeToNew(fileName: fileName)
            return // Exit: Crossfade handles the transition.
        }
        
        // 3. Fallback: No audio is playing (Fresh Start)
        // Action: Start playback from silence - NO FADE IN for soundscape
        startPlayback(fileName: fileName, withFadeIn: false)
    }
    
    /// Start playback of a specific file
    private func startPlayback(fileName: String, withFadeIn: Bool) {
        isLoading = true
        hasError = false

        // Lazy audio session setup on first playback
        ensureAudioSessionConfigured()

        guard let audioURL = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("✗ Audio file not found: \(fileName).mp3")
            hasError = true
            errorMessage = "Audio file not found"
            isLoading = false
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            
            // Calculate target volume based on ducking state
            targetVolume = isDucked ? 0.65 : 1.0
            
            // Soundscape never fades in - always starts at target volume
            audioPlayer?.volume = targetVolume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            isLoading = false
            
            print("✓ Playing soundscape: \(selectedSoundscape.displayName) at \(Int(targetVolume * 100))% volume")
        } catch {
            print("✗ Failed to play soundscape: \(error)")
            hasError = true
            errorMessage = "Playback failed"
            isLoading = false
        }
    }
    
    /// Crossfade from current soundscape to new one
    /// Shorter crossfade (1s) to minimize dual-player time
    private func crossfadeToNew(fileName: String) {
        guard let audioURL = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("✗ Audio file not found for crossfade: \(fileName).mp3")
            return
        }
        
        do {
            // Prepare new player
            crossfadePlayer = try AVAudioPlayer(contentsOf: audioURL)
            crossfadePlayer?.numberOfLoops = -1
            crossfadePlayer?.volume = 0
            crossfadePlayer?.prepareToPlay()
            crossfadePlayer?.play()
            
            let oldPlayer = audioPlayer
            let newPlayer = crossfadePlayer
            let crossfadeSteps = 10
            let crossfadeDuration: TimeInterval = 1.0
            let stepDuration = crossfadeDuration / Double(crossfadeSteps)
            var currentStep = 0
            
            fadeTimer?.invalidate()
            fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                currentStep += 1
                let progress = Float(currentStep) / Float(crossfadeSteps)
                
                // Fade out old, fade in new
                oldPlayer?.volume = self.targetVolume * (1.0 - progress)
                newPlayer?.volume = self.targetVolume * progress
                
                if currentStep >= crossfadeSteps {
                    timer.invalidate()
                    oldPlayer?.stop()
                    self.audioPlayer = newPlayer
                    self.crossfadePlayer = nil
                    print("✓ Crossfade complete to: \(self.selectedSoundscape.displayName)")
                }
            }
            
        } catch {
            print("✗ Failed to setup crossfade: \(error)")
            stop()
            startPlayback(fileName: fileName, withFadeIn: true)
        }
    }
    
    //MARK: - Fade volume to target
    private func fadeToVolume(_ target: Float) {
        fadeTimer?.invalidate()
        
        let startVolume = audioPlayer?.volume ?? 0
        let volumeDelta = target - startVolume
        let steps = fadeSteps
        let stepDuration = fadeDuration / Double(steps)
        var currentStep = 0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            self?.audioPlayer?.volume = startVolume + (volumeDelta * progress)
            
            if currentStep >= steps {
                timer.invalidate()
                self?.audioPlayer?.volume = target
            }
        }
    }
    
    /// Stop playback with fade-out
    func stop() {
        fadeTimer?.invalidate()
        
        guard isPlaying, let player = audioPlayer else {
            audioPlayer?.stop()
            audioPlayer = nil
            crossfadePlayer?.stop()
            crossfadePlayer = nil
            isPlaying = false
            return
        }
        
        // Fade out then stop
        let startVolume = player.volume
        let steps = fadeSteps / 2
        let stepDuration = (fadeDuration / 2) / Double(steps)
        var currentStep = 0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            player.volume = startVolume * (1.0 - progress)
            
            if currentStep >= steps {
                timer.invalidate()
                player.stop()
                self?.audioPlayer = nil
                self?.isPlaying = false
                print("✓ Soundscape stopped with fade-out")
            }
        }
    }
    
    /// Stop immediately without fade (for app termination)
    func stopImmediately() {
        fadeTimer?.invalidate()
        audioPlayer?.stop()
        audioPlayer = nil
        crossfadePlayer?.stop()
        crossfadePlayer = nil
        isPlaying = false
    }
    
    func pause() {
        fadeTimer?.invalidate()
        audioPlayer?.pause()
        isPlaying = false
        
        #if DEBUG
        print("⏸️ Soundscape paused instantly (no fade)")
        #endif
    }
    
    /// Soundscape now pauses instantly without fade for consistent behavior
    func pauseWithFade(completion: (() -> Void)? = nil) {
        pause()
        completion?()
    }
    
    /// Soft volume dip to signal session state change
    /// Creates an audible "breath" in the soundscape without stopping
    /// Perfect for work→break and break→work transitions
    func signalStateTransition() {
        guard isPlaying, let player = audioPlayer else { return }
        
        fadeTimer?.invalidate()
        
        let originalVolume = player.volume
        let dipVolume = originalVolume * 0.3
        let steps = 6
        let stepDuration: TimeInterval = 0.08
        var currentStep = 0
        var isDipping = true
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            
            if isDipping {
                // Fade down
                let progress = Float(currentStep) / Float(steps)
                player.volume = originalVolume - ((originalVolume - dipVolume) * progress)
                
                if currentStep >= steps {
                    currentStep = 0
                    isDipping = false
                }
            } else {
                // Fade back up
                let progress = Float(currentStep) / Float(steps)
                player.volume = dipVolume + ((originalVolume - dipVolume) * progress)
                
                if currentStep >= steps {
                    timer.invalidate()
                    player.volume = self?.targetVolume ?? originalVolume
                }
            }
        }
    }
    
    func resume() {
        guard audioPlayer != nil else {
            // No player exists, try to play from scratch
            if selectedSoundscape != Soundscape.none && !isMuted {
                play()
            }
            return
        }
        
        // Check if player is actually paused before resuming
        // This prevents double-play issues
        if audioPlayer?.isPlaying == true {
            // Already playing, just sync state
            isPlaying = true
            return
        }
        
        // Resume instantly at target volume (no fade)
        audioPlayer?.volume = targetVolume
        audioPlayer?.play()
        isPlaying = true
        
        #if DEBUG
        print("▶️ Soundscape resumed at \(Int(targetVolume * 100))% volume (no fade)")
        #endif
    }
    
    func toggleMute() {
        isMuted.toggle()
        
        if isMuted {
            pause()
        } else {
            play()
        }
    }
    
    // MARK: - Volume Management
        
        /// Set ducked state for reliable work/break transitions
        /// Called by TimerManager: true = work session (music on), false = break (music off)
        func setDucked(_ ducked: Bool) {
            // Only trigger change if state is actually different
            guard isDucked != ducked else { return }
            
            isDucked = ducked
            backgroundMusicEnabled = ducked
            targetVolume = ducked ? 0.65 : 1.0
            
            if isCurrentlyPlaying {
                // Instant volume change for soundscape (no fade)
                audioPlayer?.volume = targetVolume
                #if DEBUG
                print("🔊 Soundscape volume adjusted: \(ducked ? "Ducked (65%)" : "Full (100%)")")
                #endif
            }
        }
        
        /// Legacy compatibility - routes to setDucked
        func updateVolume(backgroundMusicEnabled: Bool) {
            setDucked(backgroundMusicEnabled)
        }
    
    func setVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        targetVolume = clampedVolume
        audioPlayer?.volume = clampedVolume
    }
    
    // MARK: - Soundscape Selection
    func selectSoundscape(_ soundscape: Soundscape) {
        let previousSoundscape = selectedSoundscape
        selectedSoundscape = soundscape
        
        if soundscape == .none {
            stop()
        } else if previousSoundscape != .none && isCurrentlyPlaying {
            // Use isCurrentlyPlaying for accurate state check
            // Crossfade to new soundscape
            play()
        } else {
            // Fresh start (handles case where previous sound stopped unexpectedly)
            play()
        }
    }
    
    func cycleSoundscape() {
        let allCases = Soundscape.allCases
        guard let currentIndex = allCases.firstIndex(of: selectedSoundscape) else { return }
        
        let nextIndex = (currentIndex + 1) % allCases.count
        selectSoundscape(allCases[nextIndex])
    }
    
    // MARK: - State Accessors
    
    /// Returns true if audio is actively playing
    var isCurrentlyPlaying: Bool {
        return isPlaying && (audioPlayer?.isPlaying ?? false)
    }
}
