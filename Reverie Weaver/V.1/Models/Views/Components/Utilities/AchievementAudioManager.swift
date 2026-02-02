//
//  AchievementAudioManager.swift
//  Reverie Weaver
//
//  Created for gamification sound effects
//
//  AUDIO FILES NEEDED (place in project bundle):
//  - achievement_unlock.mp3  (0.5-0.8s gentle bell chime)
//  - hidden_reveal.mp3       (1.0-1.5s ethereal shimmer)
//  - constellation.mp3       (1.2-1.8s celestial twinkle)
//  - level_up.mp3            (1.5-2.0s triumphant fanfare)
//  - weekly_complete.mp3     (0.6-0.8s satisfying ding)
//  - perfect_day.mp3         (1.0-1.2s warm glow/soft harp)
//

@preconcurrency import AVFoundation
import SwiftUI

// MARK: - Achievement Sound Types

enum AchievementSound: String, CaseIterable {
    case standardUnlock = "achievement_unlock"      // Gentle chime for standard achievements
    case invisibleReveal = "hidden_reveal"          // Mysterious shimmer for hidden achievements
    case constellationUnlock = "constellation"      // Magical sparkle for badge unlocks
    case levelUp = "level_up"                       // Triumphant flourish for level-up
    case weeklyChallenge = "weekly_complete"        // Satisfying ding for weekly challenges
    case perfectDay = "perfect_day"                 // Warm glow for perfect days

    var fileName: String {
        return self.rawValue
    }

    /// Volume level for each sound type (0.0 - 1.0)
    var volume: Float {
        switch self {
        case .levelUp: return 0.8
        case .constellationUnlock: return 0.7
        case .invisibleReveal: return 0.6
        case .standardUnlock: return 0.5
        case .weeklyChallenge: return 0.6
        case .perfectDay: return 0.6
        }
    }

    /// Human-readable description for settings UI
    var displayName: String {
        switch self {
        case .standardUnlock: return "Achievement Unlock"
        case .invisibleReveal: return "Hidden Thread Reveal"
        case .constellationUnlock: return "Constellation Unlock"
        case .levelUp: return "Level Up"
        case .weeklyChallenge: return "Weekly Challenge Complete"
        case .perfectDay: return "Perfect Day"
        }
    }

    /// Maximum playback duration in seconds
    /// Stops playback after this duration even if audio file is longer
    var maxDuration: TimeInterval {
        switch self {
        case .standardUnlock: return 0.8
        case .invisibleReveal: return 1.5
        case .constellationUnlock: return 1.8
        case .levelUp: return 2.0
        case .weeklyChallenge: return 0.8
        case .perfectDay: return 1.2
        }
    }
}

// MARK: - Achievement Audio Manager

@MainActor
@Observable
final class AchievementAudioManager {
    static let shared = AchievementAudioManager()

    // MARK: - State
    private var audioPlayer: AVAudioPlayer?
    private var stopTask: Task<Void, Never>?
    private var isAudioSessionConfigured = false

    /// User preference for achievement sounds
    var soundsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "achievementSoundsEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "achievementSoundsEnabled")
        }
    }

    // MARK: - Initialization

    private init() {
        // Set default to true if not previously set
        if UserDefaults.standard.object(forKey: "achievementSoundsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "achievementSoundsEnabled")
        }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        guard !isAudioSessionConfigured else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            // Use .ambient to mix with other audio and respect silent mode
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            isAudioSessionConfigured = true
            #if DEBUG
            print("✓ Achievement audio session configured")
            #endif
        } catch {
            #if DEBUG
            print("✗ Achievement audio session setup failed: \(error)")
            #endif
        }
    }

    // MARK: - Playback

    /// Play an achievement sound
    /// - Parameter sound: The type of achievement sound to play
    func play(_ sound: AchievementSound) {
        guard soundsEnabled else { return }

        configureAudioSession()

        // Try to find the audio file
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
            #if DEBUG
            print("⚠️ Achievement sound not found: \(sound.fileName).mp3 - Add this file to enable sound")
            #endif
            return
        }

        do {
            // Stop any currently playing sound and cancel existing stop task
            stopTask?.cancel()
            stopTask = nil
            audioPlayer?.stop()

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = sound.volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            // Schedule stop after max duration using Task instead of Timer
            // to avoid Sendable warnings with AVAudioPlayer
            let maxDuration = sound.maxDuration
            stopTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.audioPlayer?.stop()
                #if DEBUG
                print("🔇 Stopped achievement sound after \(maxDuration)s")
                #endif
            }

            #if DEBUG
            print("🔊 Playing achievement sound: \(sound.displayName) (max \(sound.maxDuration)s)")
            #endif
        } catch {
            #if DEBUG
            print("✗ Failed to play achievement sound: \(error)")
            #endif
        }
    }

    /// Play sound for a standard achievement unlock
    func playStandardUnlock() {
        play(.standardUnlock)
    }

    /// Play sound for invisible/hidden achievement discovery
    func playHiddenReveal() {
        play(.invisibleReveal)
    }

    /// Play sound for constellation badge unlock
    func playConstellationUnlock() {
        play(.constellationUnlock)
    }

    /// Play sound for level-up
    func playLevelUp() {
        play(.levelUp)
    }

    /// Play sound for weekly challenge completion
    func playWeeklyComplete() {
        play(.weeklyChallenge)
    }

    /// Play sound for perfect day
    func playPerfectDay() {
        play(.perfectDay)
    }

    // MARK: - Settings

    /// Toggle sounds on/off
    func toggleSounds() {
        soundsEnabled.toggle()
    }

    /// Preview a sound (for settings)
    func preview(_ sound: AchievementSound) {
        // Temporarily enable sounds for preview
        let wasEnabled = soundsEnabled
        if !wasEnabled {
            // Play anyway for preview
            configureAudioSession()
            guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
                #if DEBUG
                print("⚠️ Preview sound not found: \(sound.fileName).mp3")
                #endif
                return
            }

            do {
                stopTask?.cancel()
                stopTask = nil
                audioPlayer?.stop()
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = sound.volume
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()

                // Schedule stop after max duration using Task instead of Timer
                let maxDuration = sound.maxDuration
                stopTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    self?.audioPlayer?.stop()
                }
            } catch {
                #if DEBUG
                print("✗ Failed to preview sound: \(error)")
                #endif
            }
        } else {
            play(sound)
        }
    }
}

// MARK: - Sound Files Guide
/*

 AUDIO FILES TO ADD TO YOUR PROJECT:
 ====================================

 Place these .mp3 files in your Xcode project (drag into the project navigator):

 1. achievement_unlock.mp3
    - Duration: 0.5-0.8 seconds
    - Style: Gentle bell chime, uplifting
    - Reference: iOS notification sound, gentle "ding"
    - Search terms: "achievement sound effect", "notification chime", "success bell"

 2. hidden_reveal.mp3
    - Duration: 1.0-1.5 seconds
    - Style: Ethereal shimmer, mysterious
    - Reference: Magic reveal, sparkle sound
    - Search terms: "magic reveal sound", "mysterious shimmer", "ethereal chime"

 3. constellation.mp3
    - Duration: 1.2-1.8 seconds
    - Style: Celestial twinkle, wonder
    - Reference: Shooting star, cosmic sparkle
    - Search terms: "celestial sound effect", "star twinkle", "cosmic chime"

 4. level_up.mp3
    - Duration: 1.5-2.0 seconds
    - Style: Triumphant fanfare, accomplishment
    - Reference: Game level-up sound
    - Search terms: "level up sound", "achievement fanfare", "victory sound"

 5. weekly_complete.mp3
    - Duration: 0.6-0.8 seconds
    - Style: Satisfying "ding", completion
    - Reference: Task complete, checkbox sound
    - Search terms: "task complete sound", "checkbox ding", "success notification"

 6. perfect_day.mp3
    - Duration: 1.0-1.2 seconds
    - Style: Warm glow, contentment
    - Reference: Soft harp, gentle accomplishment
    - Search terms: "warm achievement sound", "soft harp chime", "gentle success"

 FREE RESOURCES:
 - freesound.org (search terms above)
 - pixabay.com/sound-effects
 - zapsplat.com

 Ensure all files are:
 - Royalty-free or properly licensed
 - MP3 format
 - Normalized volume levels
 - Added to your app target in Xcode

 */
