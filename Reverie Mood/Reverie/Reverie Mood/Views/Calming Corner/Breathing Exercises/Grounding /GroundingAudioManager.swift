//
//  GroundingAudioManager.swift
//  Reverie Mood
//
//  Audio guidance manager for grounding exercises with AVSpeechSynthesizer
//

import Foundation
import AVFoundation
import Combine

@MainActor
class GroundingAudioManager: ObservableObject {
    static let shared = GroundingAudioManager()

    @Published var isPlaying = false
    @Published var isMuted = false
    @Published var currentStep: Int = 0
    @Published var totalSteps: Int = 1
    @Published var elapsedTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0

    private var speechSynthesizer = AVSpeechSynthesizer()
    private var stepTimer: Timer?
    private var elapsedTimer: Timer?
    private var onCompletionCallback: (() -> Void)?
    private var currentTechnique: GroundingTechnique?

    // Natural male voice - prefer enhanced voices for more natural sound
    private var preferredVoice: AVSpeechSynthesisVoice? {
        // Try to get a high-quality male voice
        // Aaron (en-US) is a natural-sounding male voice
        // Daniel (en-GB) is another good option
        let voiceIdentifiers = [
            "com.apple.voice.enhanced.en-US.Aaron",      // Enhanced Aaron (most natural)
            "com.apple.voice.premium.en-US.Aaron",       // Premium Aaron
            "com.apple.ttsbundle.siri_male_en-US_compact", // Siri male
            "com.apple.voice.enhanced.en-GB.Daniel",     // Enhanced Daniel (British)
            "com.apple.voice.compact.en-US.Aaron",       // Compact Aaron
            "com.apple.ttsbundle.Aaron-compact"          // Legacy Aaron
        ]

        for identifier in voiceIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                return voice
            }
        }

        // Fallback: find any male-sounding en-US voice
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        if let maleVoice = allVoices.first(where: {
            $0.language.hasPrefix("en") && $0.name.contains("Aaron")
        }) {
            return maleVoice
        }

        // Last resort: default en-US voice
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - Voice Guidance Playback

    func playGuide(for technique: GroundingTechnique) {
        guard !isMuted else { return }

        currentTechnique = technique
        isPlaying = true

        // Speak introduction
        let intro = getIntroduction(for: technique)
        speak(intro)
    }

    /// Speak a specific text with the natural male voice
    func speakText(_ text: String, rate: Float = 0.42, completion: (() -> Void)? = nil) {
        guard !isMuted else {
            completion?()
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice
        utterance.rate = rate
        utterance.pitchMultiplier = 0.95 // Slightly lower for calm, grounding tone
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.3  // Small pause before speaking
        utterance.postUtteranceDelay = 0.5 // Pause after speaking

        isPlaying = true
        speechSynthesizer.speak(utterance)
    }

    private func speak(_ text: String, rate: Float = 0.42) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice
        utterance.rate = rate
        utterance.pitchMultiplier = 0.95 // Slightly lower for calm, grounding tone
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.5

        speechSynthesizer.speak(utterance)
    }

    private func getIntroduction(for technique: GroundingTechnique) -> String {
        switch technique {
        case .boxBreathing:
            return "Let's begin box breathing. Follow my voice. Breathe in for four, hold for four, breathe out for four, hold for four."
        case .fiveFourThreeTwoOne:
            return "Let's begin the five senses grounding exercise. We'll go through each sense together."
        case .threeTrueThings:
            return "Let's notice three true things about this moment. Simple observations that ground us in the present."
        case .gentleSelfSoothe:
            return "Let's practice gentle self-soothing with kind touch. Follow along with me."
        case .safePlace:
            return "Let's create a safe place in your mind. Close your eyes if that feels comfortable."
        case .selfCompassion:
            return "Let's practice self-compassion together. Repeat these phrases silently or aloud."
        case .categoriesGame:
            return "Let's play the categories grounding game. Name things in each category to shift your focus."
        case .progressiveMuscleRelaxation:
            return "Let's practice progressive muscle relaxation. We'll tense and release different muscle groups."
        case .butterflyHug:
            return "Let's do the butterfly hug. Cross your arms over your chest and gently tap alternately."
        case .coldWaterReset:
            return "Let's use cold water to reset your nervous system. This quick technique can help shift your state."
        case .groundingWalk:
            return "Let's take a grounding walk together. Focus on the sensations of each step."
        case .shakeItOut:
            return "Let's shake out the tension. Movement helps release stress from your body."
        case .alphabetGrounding:
            return "Let's go through the alphabet grounding exercise. Name something for each letter."
        case .orienting:
            return "Let's practice orienting together. Slowly look around to signal safety to your nervous system."
        case .quickThreeTwoOne:
            return "Quick ground. Three things you see, two you hear, one you feel."
        case .quickTenBreaths:
            return "Just ten slow breaths. Count each exhale."
        case .quickPalmsPress:
            return "Press your palms together firmly, hold, then release."
        case .quickOneTruth:
            return "Name one simple true thing about right now."
        }
    }

    func toggleMute() {
        isMuted.toggle()

        if isMuted {
            speechSynthesizer.stopSpeaking(at: .immediate)
            isPlaying = false
        } else {
            isPlaying = true
            // Resume speaking if there's a current technique
            if let technique = currentTechnique {
                playGuide(for: technique)
            }
        }
    }

    func pause() {
        speechSynthesizer.pauseSpeaking(at: .word)
        isPlaying = false
        elapsedTimer?.invalidate()
    }

    func resume() {
        guard !isMuted else { return }
        speechSynthesizer.continueSpeaking()
        isPlaying = true
        startElapsedTimer()
    }

    func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        stopAllTimers()
        currentTechnique = nil
    }

    // MARK: - Progress Tracking

    func startStepTimer(totalSteps: Int, duration: TimeInterval, onComplete: @escaping () -> Void) {
        self.totalSteps = totalSteps
        self.totalDuration = duration
        self.currentStep = 0
        self.elapsedTime = 0
        self.onCompletionCallback = onComplete

        let stepDuration = duration / Double(totalSteps)

        // Speak first step guidance
        speakStepGuidance(step: 0)

        // Step progression timer
        stepTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.currentStep += 1

                // Speak guidance for this step
                self.speakStepGuidance(step: self.currentStep)

                if self.currentStep >= totalSteps {
                    self.stepTimer?.invalidate()
                    self.onCompletionCallback?()
                }
            }
        }

        // Elapsed time timer (updates every second)
        startElapsedTimer()
    }

    private func speakStepGuidance(step: Int) {
        guard !isMuted, let technique = currentTechnique else { return }

        let guidance = getStepGuidance(for: technique, step: step)
        if !guidance.isEmpty {
            speak(guidance)
        }
    }

    private func getStepGuidance(for technique: GroundingTechnique, step: Int) -> String {
        switch technique {
        case .boxBreathing:
            let cycle = step / 4
            let phase = step % 4
            switch phase {
            case 0: return "Breathe in, two, three, four"
            case 1: return "Hold, two, three, four"
            case 2: return "Breathe out, two, three, four"
            case 3: return cycle < 11 ? "Hold, two, three, four" : "Hold. Well done."
            default: return ""
            }

        case .fiveFourThreeTwoOne:
            switch step {
            case 0: return "Name five things you can see around you. Take your time."
            case 1: return "Now, four things you can touch or feel. Notice the textures."
            case 2: return "Three things you can hear. Listen carefully."
            case 3: return "Two things you can smell. Even subtle scents."
            case 4: return "And one thing you can taste. Excellent work."
            default: return ""
            }

        case .threeTrueThings:
            switch step {
            case 0: return "Notice one true thing about right now. Something simple and undeniable."
            case 1: return "Now another true thing. Maybe about your body, or the space around you."
            case 2: return "And one more truth about this moment. You're doing great."
            default: return ""
            }

        case .gentleSelfSoothe:
            switch step {
            case 0: return "Place your hand gently on your chest or heart."
            case 1: return "Feel the warmth of your own touch. Notice the pressure."
            case 2: return "Breathe slowly and gently beneath your hand."
            case 3: return "Let this touch remind you that you're here, and you're okay."
            default: return ""
            }

        case .safePlace:
            switch step {
            case 0: return "Close your eyes if that feels comfortable."
            case 1: return "Picture a place where you feel completely safe and at peace."
            case 2: return "Notice the colors, the light, the textures in this place."
            case 3: return "What sounds do you hear? What do you smell?"
            case 4: return "Feel the peace of this place surrounding you. You can return here anytime."
            default: return ""
            }

        case .selfCompassion:
            switch step {
            case 0: return "This is a moment of difficulty. Suffering is part of life."
            case 1: return "Difficulty is part of being human. You're not alone."
            case 2: return "May I be kind to myself in this moment."
            case 3: return "May I give myself the compassion I need. You deserve kindness."
            default: return ""
            }

        case .categoriesGame:
            switch step {
            case 0: return "Name five fruits you can think of."
            case 1: return "Now, name five animals."
            case 2: return "Name five colors you like."
            case 3: return "Think of five songs you enjoy."
            case 4: return "Excellent work. Your mind is more focused now."
            default: return ""
            }

        case .progressiveMuscleRelaxation:
            switch step {
            case 0: return "Start with your hands. Make tight fists for five seconds."
            case 1: return "Now release. Feel the tension melt away."
            case 2: return "Tense your shoulders. Raise them up toward your ears."
            case 3: return "Release and let them drop. Notice the relief."
            case 4: return "Tense your face. Scrunch it up tightly."
            case 5: return "Release. Let your face soften completely."
            case 6: return "Your body is more relaxed now. Well done."
            default: return ""
            }

        case .butterflyHug:
            switch step {
            case 0: return "Cross your arms over your chest."
            case 1: return "Gently tap your shoulders alternately."
            case 2: return "Continue tapping. Left, right, left, right."
            case 3: return "Keep breathing slowly as you tap."
            case 4: return "You're doing great. Let the rhythm soothe you."
            default: return ""
            }

        case .coldWaterReset:
            switch step {
            case 0: return "Find a source of cold water."
            case 1: return "Splash cold water on your face."
            case 2: return "Or hold something cold in your hands."
            case 3: return "Focus on the sensation. Let it bring you back."
            default: return ""
            }

        case .groundingWalk:
            switch step {
            case 0: return "Begin walking slowly and mindfully."
            case 1: return "Notice how your feet connect with the ground."
            case 2: return "Feel each step. Heel, then toe."
            case 3: return "Continue walking. Stay present with each movement."
            case 4: return "Wonderful. Each step grounds you more."
            default: return ""
            }

        case .shakeItOut:
            switch step {
            case 0: return "Start shaking your hands loosely."
            case 1: return "Now shake your arms. Let them be loose."
            case 2: return "Shake your whole body gently."
            case 3: return "Keep shaking. Release any tension."
            case 4: return "Slowly come to stillness. Notice how you feel."
            default: return ""
            }

        case .alphabetGrounding:
            switch step {
            case 0: return "Think of something that starts with A."
            case 1: return "Now B. Keep going through the alphabet."
            case 2: return "Continue at your own pace."
            case 3: return "If you get stuck, move to the next letter."
            case 4: return "Great job. Your mind is more focused now."
            default: return ""
            }

        case .orienting:
            switch step {
            case 0: return "Slowly turn your head to the right."
            case 1: return "Notice what you see. Name one thing and its color."
            case 2: return "Return to center. Take a breath."
            case 3: return "Now slowly turn your head to the left."
            case 4: return "Notice what you see. Name one thing."
            case 5: return "Return to center. Notice how your neck feels."
            default: return ""
            }

        case .quickThreeTwoOne:
            switch step {
            case 0: return "Three things you can see."
            case 1: return "Two things you can hear."
            case 2: return "One thing you can feel."
            default: return ""
            }

        case .quickTenBreaths:
            return "" // Minimal audio for quick exercises

        case .quickPalmsPress:
            switch step {
            case 0: return "Press your palms together firmly."
            case 1: return "Hold and notice the pressure."
            case 2: return "Slowly release. Notice the difference."
            default: return ""
            }

        case .quickOneTruth:
            return "" // User-driven, minimal audio
        }
    }

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.elapsedTime += 1

                if self.elapsedTime >= self.totalDuration {
                    self.elapsedTimer?.invalidate()
                }
            }
        }
    }

    private func stopAllTimers() {
        stepTimer?.invalidate()
        stepTimer = nil
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    // MARK: - Voice Guidance Helpers

    var progressPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return min(elapsedTime / totalDuration, 1.0)
    }

    var remainingTime: TimeInterval {
        max(totalDuration - elapsedTime, 0)
    }

    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedTotalTime: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Cleanup

    deinit {
        stepTimer?.invalidate()
        elapsedTimer?.invalidate()
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - Technique Step Count Extension

extension GroundingTechnique {
    // Note: durationInSeconds is already defined in the main enum in GroundingView.swift
    
    var stepCount: Int {
        switch self {
        case .boxBreathing:
            return 12 // 12 breath cycles (4 steps per cycle × 3 cycles)
        case .fiveFourThreeTwoOne:
            return 5 // 5 senses (5+4+3+2+1 = 15 items total)
        case .threeTrueThings:
            return 3 // 3 truths
        case .gentleSelfSoothe:
            return 4 // 4 steps of gentle touch
        case .safePlace:
            return 5 // 5 visualization stages
        case .selfCompassion:
            return 4 // 4 compassion phrases
        case .categoriesGame:
            return 5 // 5 categories
        case .progressiveMuscleRelaxation:
            return 7 // 7 muscle group steps
        case .butterflyHug:
            return 5 // 5 tapping steps
        case .coldWaterReset:
            return 4 // 4 steps
        case .groundingWalk:
            return 5 // 5 walking awareness steps
        case .shakeItOut:
            return 5 // 5 shaking steps
        case .alphabetGrounding:
            return 5 // 5 alphabet steps (simplified)
        case .orienting:
            return 6 // 6 orienting steps
        case .quickThreeTwoOne:
            return 3 // 3 quick senses
        case .quickTenBreaths:
            return 10 // 10 breaths
        case .quickPalmsPress:
            return 3 // 3 quick steps
        case .quickOneTruth:
            return 1 // 1 truth
        }
    }
}
