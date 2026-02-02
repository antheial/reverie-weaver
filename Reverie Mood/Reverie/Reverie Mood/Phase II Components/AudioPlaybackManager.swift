//
//  AudioPlaybackManager.swift
//  Reverie Mood
//
//  Singleton manager to ensure only one audio plays at a time across the app.
//

import AVFoundation
import Combine

/// Singleton manager that ensures only one audio plays at a time across the entire app.
/// All audio players should register with this manager and use it to coordinate playback.
final class AudioPlaybackManager: ObservableObject {
    static let shared = AudioPlaybackManager()

    /// Notification posted when playback should stop (another audio is starting)
    static let stopAllPlaybackNotification = Notification.Name("AudioPlaybackManager.stopAllPlayback")

    /// Unique identifier for the currently playing audio
    @Published private(set) var currentlyPlayingId: String?

    private init() {}

    // MARK: - Public API

    /// Call this before starting playback. Returns true if this audio can play.
    /// This will stop any other currently playing audio.
    /// - Parameter id: A unique identifier for this audio (e.g., "memo-2026-30-morning")
    /// - Returns: true if playback can proceed
    func requestPlayback(id: String) -> Bool {
        // If something else is playing, stop it
        if let currentId = currentlyPlayingId, currentId != id {
            // Post notification to stop all other playback
            NotificationCenter.default.post(
                name: Self.stopAllPlaybackNotification,
                object: nil,
                userInfo: ["requestingId": id]
            )
        }

        // Set this as the currently playing audio
        currentlyPlayingId = id
        return true
    }

    /// Call this when playback stops (either manually or when audio finishes)
    /// - Parameter id: The unique identifier for this audio
    func playbackStopped(id: String) {
        // Only clear if this is the current audio
        if currentlyPlayingId == id {
            currentlyPlayingId = nil
        }
    }

    /// Force stop all playback across the app
    func stopAll() {
        NotificationCenter.default.post(
            name: Self.stopAllPlaybackNotification,
            object: nil,
            userInfo: nil
        )
        currentlyPlayingId = nil
    }

    /// Check if a specific audio is currently playing
    func isPlaying(id: String) -> Bool {
        return currentlyPlayingId == id
    }
}
