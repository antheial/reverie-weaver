//
//  BreathingEngine.swift
//  Reverie Mood
//
//

import SwiftUI
import AVFoundation
import Combine
import OSLog

private let breathingEngineLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "BreathingEngine")

@MainActor
class BreathingEngine: ObservableObject {
    // MARK: - UI State
    @Published var circleScale: CGFloat = 0.5
    @Published var phaseTimeRemaining: Double = 0
    @Published var currentPhaseText: String = "Get Ready"
    @Published var currentCycle: Int = 0
    @Published var totalCycles: Int = 5
    @Published var overallProgress: CGFloat = 0
    @Published var isRunning: Bool = false
    @Published var isFinished: Bool = false
    @Published var isCoolingDown: Bool = false
    
    // MARK: - Settings
    @Published var voiceEnabled: Bool = false
    @Published var soundEnabled: Bool = false
    @Published var hapticEnabled: Bool = false
    @Published var ambientEnabled: Bool = false // ✨ NEW: Renamed from oceanEnabled
    @Published var selectedAmbientSound: String = "" // ✨ NEW: Current ambient sound ID
    
    // MARK: - Computed Properties
    var currentPhase: BreathPhase {
        if isCoolingDown { return .hold }
        guard let exercise = exercise, currentPhaseIndex < exercise.phases.count else { return .inhale }
        return exercise.phases[currentPhaseIndex].phase
    }
    
    var phaseProgress: Double {
        guard let exercise = exercise, currentPhaseIndex < exercise.phases.count else { return 0 }
        let phaseDuration = exercise.phases[currentPhaseIndex].duration
        guard phaseDuration > 0 else { return 0 }
        return max(0, min(1, 1.0 - (phaseTimeRemaining / phaseDuration)))
    }
    
    // MARK: - Phase Tracking (exposed for UI)
    @Published var phaseIndex: Int = 0  // Exposed for unique UI IDs

    // MARK: - Internal State
    private var exercise: BreathingExercise?
    private var timer: Timer?
    private var pulseTimer: Timer?
    private var currentPhaseIndex = 0 {
        didSet { phaseIndex = currentPhaseIndex }
    }
    private var phaseStartTime: Date?
    private var pausedTimeRemaining: TimeInterval = 0
    private var wasPaused: Bool = false
    
    private let synthesizer = AVSpeechSynthesizer()
    private let hapticEngine = UIImpactFeedbackGenerator(style: .soft)
    
    // Audio Players
    nonisolated(unsafe) private var voiceCuePlayer: AVAudioPlayer?
    nonisolated(unsafe) private var backgroundPlayer: AVAudioPlayer?
    nonisolated(unsafe) private var ambientPlayer: AVAudioPlayer? // ✨ NEW: Renamed from oceanPlayer
    nonisolated(unsafe) private var audioPlayers: [AVAudioPlayer] = []
    nonisolated(unsafe) private var tempAudioURLs: Set<URL> = []
    
    // MARK: - Configuration

    func configure(exercise: BreathingExercise, cycles: Int = 5) {
        self.exercise = exercise
        self.currentCycle = 0
        self.totalCycles = cycles
        self.currentPhaseText = "Get Ready"
        self.phaseTimeRemaining = 3
        self.isFinished = false
        self.isCoolingDown = false
        self.wasPaused = false
        self.pausedTimeRemaining = 0

        // Set recommended ambient sound for this exercise
        self.selectedAmbientSound = exercise.recommendedAmbient

        configureAudioSession()
        hapticEngine.prepare()
    }

    /// Update cycles mid-configuration (before starting)
    func setCycles(_ cycles: Int) {
        self.totalCycles = cycles
    }
    
    // MARK: - Toggles
    
    func toggleVoiceGuidance() {
        voiceEnabled.toggle()
        if !voiceEnabled {
            synthesizer.stopSpeaking(at: .immediate)
            voiceCuePlayer?.stop()
        }
    }
    
    func toggleHapticGuidance() {
        hapticEnabled.toggle()
        if hapticEnabled {
            hapticEngine.prepare()
            hapticEngine.impactOccurred(intensity: 0.7)
            playSingingBowlChime(pitch: 523.25, duration: 0.6)
        }
    }
    
    func toggleSoundGuidance() {
        soundEnabled.toggle()
        if soundEnabled {
            hapticEngine.prepare()
            hapticEngine.impactOccurred(intensity: 0.5)
        }
        updateBackgroundMusic()
    }
    
    // ✨ NEW: Ambient Sound Toggle
    func toggleAmbientSounds() {
        ambientEnabled.toggle()
        breathingEngineLogger.debug("toggleAmbientSounds: ambientEnabled is now \(self.ambientEnabled)")
        breathingEngineLogger.debug("selectedAmbientSound: \(self.selectedAmbientSound)")
        breathingEngineLogger.debug("isRunning: \(self.isRunning)")
        
        if ambientEnabled {
            hapticEngine.prepare()
            hapticEngine.impactOccurred(intensity: 0.5)
        }
        updateAmbientSounds()
    }
    
    // ✨ NEW: Change Ambient Sound
    func setAmbientSound(_ soundId: String) {
        breathingEngineLogger.debug("setAmbientSound called with: \(soundId)")
        breathingEngineLogger.debug("Current selectedAmbientSound: \(self.selectedAmbientSound)")
        breathingEngineLogger.debug("ambientEnabled: \(self.ambientEnabled), isRunning: \(self.isRunning)")
        
        guard selectedAmbientSound != soundId else {
            breathingEngineLogger.debug("Same sound already selected, skipping")
            return
        }
        
        selectedAmbientSound = soundId
        breathingEngineLogger.debug("Updated selectedAmbientSound to: \(self.selectedAmbientSound)")
        
        // Always update if ambient is enabled (even when not running)
        if ambientEnabled {
            breathingEngineLogger.debug("Ambient is enabled, updating sounds...")
            updateAmbientSounds()
        }
        
        // Provide haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    // MARK: - Playback Control
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        currentCycle = 1
        currentPhaseIndex = 0
        wasPaused = false
        pausedTimeRemaining = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        if let t = timer { RunLoop.main.add(t, forMode: .common) }
        
        updateBackgroundMusic()
        updateAmbientSounds() // ✨
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
        wasPaused = true
        pausedTimeRemaining = phaseTimeRemaining
        
        timer?.invalidate()
        timer = nil
        pulseTimer?.invalidate()
        pulseTimer = nil
        
        voiceCuePlayer?.pause()
        synthesizer.pauseSpeaking(at: .immediate)
        backgroundPlayer?.pause()
        ambientPlayer?.pause() // ✨
    }
    
    func resume() {
        guard !isRunning else { return }
        isRunning = true
        
        if wasPaused {
            let remainingDuration = pausedTimeRemaining
            phaseStartTime = Date().addingTimeInterval(-remainingDuration)
            wasPaused = false
            if voiceEnabled { synthesizer.continueSpeaking() }
            backgroundPlayer?.play()
            ambientPlayer?.play() // ✨
        } else {
            phaseStartTime = Date()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        if let t = timer { RunLoop.main.add(t, forMode: .common) }
        
        if hapticEnabled, let exercise = exercise, currentPhaseIndex < exercise.phases.count {
            let phase = exercise.phases[currentPhaseIndex]
            startRhythmicPulses(for: phase.phase, duration: pausedTimeRemaining)
        }
        
        updateBackgroundMusic()
        updateAmbientSounds() // ✨
    }
    
    func stop() {
        isRunning = false
        wasPaused = false
        pausedTimeRemaining = 0
        
        timer?.invalidate()
        timer = nil
        pulseTimer?.invalidate()
        pulseTimer = nil
        
        synthesizer.stopSpeaking(at: .immediate)
        stopAllAudio()
        
        circleScale = 0.5
        currentPhaseText = "Get Ready"
        currentCycle = 0
        phaseTimeRemaining = 0
        
        deactivateAudioSession()
    }
    
    // MARK: - Core Tick Logic
    
    private func tick() {
        if isCoolingDown { return }
        
        guard let exercise = exercise else { return }
        guard currentPhaseIndex < exercise.phases.count else { return }

        if phaseStartTime == nil {
            phaseStartTime = Date()
            let phase = exercise.phases[currentPhaseIndex]
            phaseTimeRemaining = phase.duration

            // Set initial circleScale based on previous phase to avoid any jump
            // Hold phase locks at whatever the previous phase ended at
            if phase.phase == .hold {
                // Check previous phase to determine lock position
                if currentPhaseIndex > 0 {
                    let prevPhase = exercise.phases[currentPhaseIndex - 1].phase
                    switch prevPhase {
                    case .inhale: circleScale = 1.0  // Lock at max (inhale ended at 1.0)
                    case .exhale: circleScale = 0.5  // Lock at min (exhale ended at 0.5)
                    case .hold:   break              // Keep current scale (consecutive holds)
                    }
                } else {
                    // Edge case: hold is the first phase - keep current scale (default 0.5)
                    // circleScale stays at whatever it currently is
                }
            }
            // Inhale/Exhale: circleScale is set continuously in the progress section below
            
            let isLastCycle = currentCycle == totalCycles
            
            // Check if this is a consecutive same-phase (like double inhale in Physiological Sigh)
            let isConsecutiveSamePhase = currentPhaseIndex > 0 &&
                exercise.phases[currentPhaseIndex - 1].phase == phase.phase

            if isLastCycle {
                switch phase.phase {
                case .inhale:
                    if isConsecutiveSamePhase {
                        currentPhaseText = "Hold & Sip"  // Second inhale is a "top-off"
                    } else {
                        currentPhaseText = "Last Inhale"
                    }
                case .hold:   currentPhaseText = "Hold"
                case .exhale: currentPhaseText = "Last Exhale"
                }

                if voiceEnabled {
                    if currentPhaseIndex == 0 {
                        playVoiceCue(text: "Final breath", filename: "voice_final_breath")
                    } else {
                        playVoiceCue(for: phase.phase)
                    }
                }
            } else {
                // Handle consecutive same phases with different text
                if isConsecutiveSamePhase {
                    switch phase.phase {
                    case .inhale: currentPhaseText = "Hold & Sip"  // Second inhale
                    case .exhale: currentPhaseText = "Exhale More" // Second exhale (if any)
                    case .hold:   currentPhaseText = "Keep Holding"
                    }
                } else {
                    currentPhaseText = phase.phase.displayText
                }
                if voiceEnabled { playVoiceCue(for: phase.phase) }
            }
            
            if hapticEnabled {
                startRhythmicPulses(for: phase.phase, duration: phase.duration)
            }
        }
        
        guard let startTime = phaseStartTime else { return }
        guard currentPhaseIndex < exercise.phases.count else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let phase = exercise.phases[currentPhaseIndex]
        phaseTimeRemaining = max(0, phase.duration - elapsed)
        
        let progress = elapsed / phase.duration

        // Check for consecutive same-phase (like double inhale in Physiological Sigh)
        let isConsecutiveSamePhase = currentPhaseIndex > 0 &&
            exercise.phases[currentPhaseIndex - 1].phase == phase.phase

        switch phase.phase {
        case .inhale:
            if isConsecutiveSamePhase {
                // Consecutive inhale (e.g., "sip" in Physiological Sigh)
                // Stay at 1.0 (already fully expanded from previous inhale)
                circleScale = 1.0
            } else {
                // Normal inhale: expand from 0.5 to 1.0
                circleScale = 0.5 + (0.5 * CGFloat(progress))
            }
        case .exhale:
            if isConsecutiveSamePhase {
                // Consecutive exhale - stay at 0.5 (already fully contracted)
                circleScale = 0.5
            } else {
                // Normal exhale: contract from 1.0 to 0.5
                circleScale = 1.0 - (0.5 * CGFloat(progress))
            }
        case .hold:
            // Hold phase: maintain the locked value set at phase start
            break
        }
        
        if elapsed >= phase.duration {
            currentPhaseIndex += 1
            if currentPhaseIndex >= exercise.phases.count {
                if currentCycle >= totalCycles {
                    startCoolDown()
                    return
                }
                currentPhaseIndex = 0
                currentCycle += 1
            }
            phaseStartTime = nil
        }
        
        let totalPhases = totalCycles * exercise.phases.count
        let completedPhases = (currentCycle - 1) * exercise.phases.count + currentPhaseIndex
        overallProgress = CGFloat(completedPhases) / CGFloat(totalPhases)
    }
    
    private func startCoolDown() {
        isCoolingDown = true
        currentPhaseText = "Rest"
        circleScale = 0.5
        
        timer?.invalidate()
        timer = nil
        pulseTimer?.invalidate()
        
        fadeBackgroundMusic(duration: 3.0)
        if voiceEnabled { playVoiceCue(text: "Relax", filename: "voice_relax") }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.complete()
        }
    }
    
    // MARK: - ✨ Ambient Audio (Generalized for all sounds)
    
    private func updateAmbientSounds() {
        guard !selectedAmbientSound.isEmpty else {
            ambientPlayer?.stop()
            return
        }
        
        if ambientEnabled {
            // Check if we need to switch sounds
            if let player = ambientPlayer, player.isPlaying {
                let currentResource = player.url?.deletingPathExtension().lastPathComponent ?? ""
                if currentResource != selectedAmbientSound {
                    // Switching to a different sound
                    fadeAmbientOut(duration: 0.8)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                        self?.startAmbientPlayback()
                    }
                    return
                }
                // Already playing the correct sound
                return
            }
            
            // Start playback (only if running or just enabling)
            if isRunning {
                startAmbientPlayback()
            }
        } else {
            // Ambient disabled - stop playback
            fadeAmbientOut(duration: 0.5)
        }
    }
    
    private func startAmbientPlayback() {
        breathingEngineLogger.debug("startAmbientPlayback() called for: \(self.selectedAmbientSound)")
        
        // Look for ambient sound file with the selected ID
        let extensions = ["mp3", "m4a", "wav"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: selectedAmbientSound, withExtension: ext) {
                breathingEngineLogger.debug("Found file: \(url.lastPathComponent)")
                do {
                    ambientPlayer = try AVAudioPlayer(contentsOf: url)
                    ambientPlayer?.numberOfLoops = -1
                    ambientPlayer?.volume = 0
                    ambientPlayer?.prepareToPlay()
                    ambientPlayer?.play()
                    breathingEngineLogger.debug("Ambient player created and playing")
                    
                    // Fade in ambient sound
                    fadeAmbientIn(to: 0.2, duration: 1.5)
                    return
                } catch {
                    breathingEngineLogger.warning("Ambient sound error (\(self.selectedAmbientSound)): \(error.localizedDescription)")
                }
            }
        }
        breathingEngineLogger.warning("Ambient sound file not found: \(self.selectedAmbientSound)")
    }
    
    private func fadeAmbientIn(to targetVolume: Float, duration: TimeInterval) {
        guard let player = ambientPlayer else { return }
        let steps = 30
        let stepDuration = duration / Double(steps)
        let volStep = targetVolume / Float(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(i))) {
                player.volume = volStep * Float(i)
            }
        }
    }
    
    private func fadeAmbientOut(duration: TimeInterval) {
        guard let player = ambientPlayer, player.isPlaying else { return }
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volStep = player.volume / Float(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(i))) {
                if i == steps {
                    player.stop()
                } else {
                    player.volume -= volStep
                }
            }
        }
    }
    
    // MARK: - Soft Haptics & Droplets
    
    private func startRhythmicPulses(for phase: BreathPhase, duration: TimeInterval) {
        pulseTimer?.invalidate()
        let interval: TimeInterval = 1.2
        performPulse(phase: phase, index: 0)
        var count = 1
        pulseTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRunning else { return }
                self.performPulse(phase: phase, index: count)
                count += 1
            }
        }
        if let t = pulseTimer { RunLoop.main.add(t, forMode: .common) }
    }
    
    private func performPulse(phase: BreathPhase, index: Int) {
        if hapticEnabled {
            let gen = UIImpactFeedbackGenerator(style: .soft)
            gen.prepare()
            gen.impactOccurred(intensity: 0.6)
            
            switch phase {
            case .inhale: playSoftDroplet(pitch: 440)  // A4 - softer, lower pitch
            case .hold: if index == 0 { playSoftDroplet(pitch: 392) }  // G4 - gentle
            case .exhale: playSoftDroplet(pitch: 330)  // E4 - calming, lower
            }
        }
    }
    
    private func playSoftDroplet(pitch: Double) {
        let sampleRate = 44100.0
        let duration = 0.15
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let wave = sin(2.0 * .pi * pitch * t)
            let progress = t / duration
            let envelope = Float(exp(-progress * 15.0))
            samples[i] = Float(wave) * envelope * 0.08  // Reduced from 0.15 to 0.08 for subtlety
        }
        playGeneratedBuffer(samples: samples, sampleRate: sampleRate)
    }
    
    private func playSingingBowlChime(pitch: Double, duration: Double) {
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            // Create a richer tone with harmonics for a singing bowl effect
            let fundamental = sin(2.0 * .pi * pitch * t)
            let harmonic2 = sin(2.0 * .pi * pitch * 2.0 * t) * 0.3
            let harmonic3 = sin(2.0 * .pi * pitch * 3.0 * t) * 0.15
            let wave = fundamental + harmonic2 + harmonic3
            
            let progress = t / duration
            // Slower decay for a more resonant, bell-like sound
            let envelope = Float(exp(-progress * 3.0))
            samples[i] = Float(wave) * envelope * 0.2
        }
        playGeneratedBuffer(samples: samples, sampleRate: sampleRate)
    }
    
    private func playGeneratedBuffer(samples: [Float], sampleRate: Double) {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channelData = buffer.floatChannelData {
            for i in 0..<samples.count { channelData[0][i] = samples[i] }
        }
        
        let audioData = bufferToData(buffer: buffer)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("droplet_\(UUID().uuidString).wav")
        tempAudioURLs.insert(tempURL)
        
        do {
            try writeWAVFile(data: audioData, sampleRate: sampleRate, channels: 1, to: tempURL)
            let player = try AVAudioPlayer(contentsOf: tempURL)
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            audioPlayers.append(player)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.audioPlayers.removeAll { $0 == player }
                self?.tempAudioURLs.remove(tempURL)
                try? FileManager.default.removeItem(at: tempURL)
            }
        } catch { breathingEngineLogger.error("Droplet error: \(error.localizedDescription)") }
    }
    
    // MARK: - Audio Helpers
    
    private func playVoiceCue(text: String, filename: String) {
        guard voiceEnabled else { return }
        if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") {
            try? voiceCuePlayer = AVAudioPlayer(contentsOf: url)
            voiceCuePlayer?.play()
            return
        }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        utterance.pitchMultiplier = 0.9
        utterance.volume = 0.7
        synthesizer.speak(utterance)
    }
    
    private func playVoiceCue(for phase: BreathPhase) {
        let filename = "voice_\(phase.displayText.lowercased().replacingOccurrences(of: " ", with: "_"))"
        playVoiceCue(text: phase.displayText, filename: filename)
    }
    
    private func updateBackgroundMusic() {
        if soundEnabled && isRunning {
            startBackgroundMusicIfNeeded()
        } else {
            backgroundPlayer?.stop()
        }
    }
    
    private func startBackgroundMusicIfNeeded() {
        if let player = backgroundPlayer, player.isPlaying { return }
        let extensions = ["mp3", "m4a", "wav"]
        var foundURL: URL?
        for ext in extensions {
            if let url = Bundle.main.url(forResource: "meditation-breath", withExtension: ext) {
                foundURL = url; break
            }
        }
        guard let url = foundURL else { return }
        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundPlayer?.numberOfLoops = -1
            backgroundPlayer?.volume = 0.35
            backgroundPlayer?.prepareToPlay()
            backgroundPlayer?.play()
        } catch { breathingEngineLogger.error("Music error: \(error.localizedDescription)") }
    }
    
    private func fadeBackgroundMusic(duration: TimeInterval) {
        guard let player = backgroundPlayer, player.isPlaying else { return }
        let steps = 30
        let stepDuration = duration / Double(steps)
        let volStep = player.volume / Float(steps)
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(i))) {
                if i == steps { player.stop() } else { player.volume -= volStep }
            }
        }
        // Also fade Ambient
        if let ambient = ambientPlayer, ambient.isPlaying {
            let ambientVolStep = ambient.volume / Float(steps)
            for i in 0...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(i))) {
                    if i == steps { ambient.stop() } else { ambient.volume -= ambientVolStep }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func bufferToData(buffer: AVAudioPCMBuffer) -> Data {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        guard let mData = audioBuffer.mData else {
            return Data()
        }
        return Data(bytes: mData, count: Int(audioBuffer.mDataByteSize))
    }
    
    private func writeWAVFile(data: Data, sampleRate: Double, channels: Int, to url: URL) throws {
        var wavData = Data()
        wavData.append("RIFF".data(using: .ascii)!)
        var fileSize = UInt32(36 + data.count)
        wavData.append(Data(bytes: &fileSize, count: 4))
        wavData.append("WAVE".data(using: .ascii)!)
        wavData.append("fmt ".data(using: .ascii)!)
        var fmtSize: UInt32 = 16
        wavData.append(Data(bytes: &fmtSize, count: 4))
        var format: UInt16 = 3
        wavData.append(Data(bytes: &format, count: 2))
        var numChannels: UInt16 = UInt16(channels)
        wavData.append(Data(bytes: &numChannels, count: 2))
        var sr = UInt32(sampleRate)
        wavData.append(Data(bytes: &sr, count: 4))
        var byteRate: UInt32 = UInt32(sampleRate * Double(channels) * 4)
        wavData.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: UInt16 = UInt16(channels * 4)
        wavData.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: UInt16 = 32
        wavData.append(Data(bytes: &bitsPerSample, count: 2))
        wavData.append("data".data(using: .ascii)!)
        var dataSize = UInt32(data.count)
        wavData.append(Data(bytes: &dataSize, count: 4))
        wavData.append(data)
        try wavData.write(to: url)
    }
    
    private func complete() {
        isFinished = true
        isRunning = false
        isCoolingDown = false
        stopAllAudio()
        if hapticEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            playSoftDroplet(pitch: 523.25)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.playSoftDroplet(pitch: 659.25)
            }
        }
        if voiceEnabled { playVoiceCue(text: "Session Complete", filename: "voice_complete") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.deactivateAudioSession()
        }
    }
    
    nonisolated private func stopAllAudio() {
        voiceCuePlayer?.stop()
        backgroundPlayer?.stop()
        ambientPlayer?.stop() // ✨
        audioPlayers.forEach { $0.stop() }
        audioPlayers.removeAll()
        for url in tempAudioURLs { try? FileManager.default.removeItem(at: url) }
        tempAudioURLs.removeAll()
    }
    
    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    nonisolated private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
