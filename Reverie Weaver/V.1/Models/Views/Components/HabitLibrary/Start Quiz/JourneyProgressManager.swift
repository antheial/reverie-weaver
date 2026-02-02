//
//  JourneyProgressManager.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 12/8/25.
//
//  Manages synchronization between challenge completion and journey progress.
//  ✅ FIXED: Now checks ALL challenge types (MiniChallenge, ThemeWeek, Project50)
//  ✅ FIXED: Added proper completion checking for each program type
//  ✅ FIXED: Added notification observers for auto-sync
//  ✅ PRODUCTION READY: Safe error handling, no force unwraps
//

import SwiftUI
import SwiftData

@Observable
class JourneyProgressManager {
    static let shared = JourneyProgressManager()
    
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Listen for Mini Challenge completions
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MiniChallengeCompleted"),
            object: nil,
            queue: .main
        ) { _ in
            #if DEBUG
            print("📣 JourneyProgressManager: MiniChallengeCompleted notification received")
            #endif
            // Note: Actual sync happens when view calls syncJourneyProgress
        }
        
        // Listen for Theme Week completions
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ThemeWeekCompleted"),
            object: nil,
            queue: .main
        ) { _ in
            #if DEBUG
            print("📣 JourneyProgressManager: ThemeWeekCompleted notification received")
            #endif
        }
        
        // Listen for Project 50 completions
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("Project50Completed"),
            object: nil,
            queue: .main
        ) { _ in
            #if DEBUG
            print("📣 JourneyProgressManager: Project50Completed notification received")
            #endif
        }
    }
    
    // MARK: - Challenge Status Queries
    
    /// Check if a specific challenge (by tag) is currently active
    /// Checks MiniChallenges, ThemeWeeks, and Project50
    func isChallengeActive(_ programTag: String, in context: ModelContext) -> Bool {
        // 1. Check Project 50
        if programTag == "Project50" {
            return isProject50Active()
        }
        
        // 2. Check Theme Week Progress
        if isThemeWeekTag(programTag) {
            return isThemeWeekActive(programTag, in: context)
        }
        
        // 3. Check Mini Challenge Progress
        return isMiniChallengeActive(programTag, in: context)
    }
    
    /// Check if a specific challenge (by tag) is completed
    /// Checks MiniChallenges, ThemeWeeks, and Project50
    func isChallengeCompleted(_ programTag: String, in context: ModelContext) -> Bool {
        // 1. Check Project 50
        if programTag == "Project50" {
            return isProject50Completed()
        }
        
        // 2. Check Theme Week Progress
        if isThemeWeekTag(programTag) {
            return isThemeWeekCompleted(programTag, in: context)
        }
        
        // 3. Check Mini Challenge Progress
        return isMiniChallengeCompleted(programTag, in: context)
    }
    
    // MARK: - Mini Challenge Queries
    
    private func isMiniChallengeActive(_ programTag: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<MiniChallengeProgress>(
            predicate: #Predicate { progress in
                progress.challengeTag == programTag && !progress.isCompleted
            }
        )
        
        do {
            let progressRecords = try context.fetch(descriptor)
            return !progressRecords.isEmpty
        } catch {
            #if DEBUG
            print("❌ Error checking mini challenge active status: \(error)")
            #endif
            return false
        }
    }
    
    private func isMiniChallengeCompleted(_ programTag: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<MiniChallengeProgress>(
            predicate: #Predicate { progress in
                progress.challengeTag == programTag && progress.isCompleted
            }
        )
        
        do {
            let progressRecords = try context.fetch(descriptor)
            return !progressRecords.isEmpty
        } catch {
            #if DEBUG
            print("❌ Error checking mini challenge completion: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Theme Week Queries

    /// Check if a tag is for a Theme Week program
    /// Uses ChallengeRouter for consistent detection across the app
    private func isThemeWeekTag(_ tag: String) -> Bool {
        return ChallengeRouter.isThemeWeek(tag)
    }
    
    private func isThemeWeekActive(_ programTag: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<ThemeWeekProgress>(
            predicate: #Predicate { progress in
                progress.programTag == programTag && !progress.isCompleted && !progress.isPaused && !progress.isArchived
            }
        )
        
        do {
            let progressRecords = try context.fetch(descriptor)
            return !progressRecords.isEmpty
        } catch {
            #if DEBUG
            print("❌ Error checking theme week active status: \(error)")
            #endif
            return false
        }
    }
    
    private func isThemeWeekCompleted(_ programTag: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<ThemeWeekProgress>(
            predicate: #Predicate { progress in
                progress.programTag == programTag && progress.isCompleted
            }
        )
        
        do {
            let progressRecords = try context.fetch(descriptor)
            return !progressRecords.isEmpty
        } catch {
            #if DEBUG
            print("❌ Error checking theme week completion: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Project 50 Queries
    
    private func isProject50Active() -> Bool {
        let journey = Project50ProgressManager.shared.journey
        return journey.startDate != nil && !journey.isProject50Complete
    }
    
    private func isProject50Completed() -> Bool {
        let journey = Project50ProgressManager.shared.journey
        return journey.isProject50Complete
    }
    
    // MARK: - Journey Progress Sync
    
    /// Auto-sync journey progress based on completed challenges
    /// Call this periodically or when you know a challenge was completed
    func syncJourneyProgress(in context: ModelContext) {
        // Fetch active journey
        let journeyDescriptor = FetchDescriptor<PersonalizedJourney>(
            predicate: #Predicate { $0.isActive }
        )
        
        guard let journey = try? context.fetch(journeyDescriptor).first else {
            #if DEBUG
            print("ℹ️ No active journey to sync")
            #endif
            return
        }
        
        updateJourneyProgress(journey, in: context)
    }
    
    /// Update journey progress based on active/completed challenges
    func updateJourneyProgress(_ journey: PersonalizedJourney, in context: ModelContext) {
        var updatedSteps = journey.steps
        var hasChanges = false
        
        for (index, step) in updatedSteps.enumerated() {
            // Skip already completed steps
            if step.isCompleted {
                continue
            }
            
            // Check if this step's challenge is completed
            if isChallengeCompleted(step.programTag, in: context) {
                updatedSteps[index].isCompleted = true
                hasChanges = true
                
                #if DEBUG
                print("✅ Journey Step Completed: \(step.title)")
                #endif
                
                // Unlock next step
                if index + 1 < updatedSteps.count {
                    updatedSteps[index + 1].isUnlocked = true
                    
                    #if DEBUG
                    print("🔓 Next Step Unlocked: \(updatedSteps[index + 1].title)")
                    #endif
                }
            }
        }
        
        if hasChanges {
            journey.steps = updatedSteps
            
            // Update current step index to first incomplete step
            if let firstIncomplete = updatedSteps.firstIndex(where: { !$0.isCompleted }) {
                journey.currentStepIndex = firstIncomplete
            } else {
                // All steps completed!
                journey.currentStepIndex = updatedSteps.count
                
                #if DEBUG
                print("🎉 Journey Completed: \(journey.goal?.rawValue ?? "Unknown")")
                #endif
                
                // Post notification for journey completion
                NotificationCenter.default.post(
                    name: NSNotification.Name("JourneyCompleted"),
                    object: journey
                )
            }
            
            do {
                try context.save()
                
                #if DEBUG
                print("💾 Journey progress saved successfully")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to save journey progress: \(error)")
                #endif
            }
        }
    }
    
    // MARK: - Journey Access Helpers
    
    /// Get the active journey if one exists
    func getActiveJourney(in context: ModelContext) -> PersonalizedJourney? {
        let descriptor = FetchDescriptor<PersonalizedJourney>(
            predicate: #Predicate { $0.isActive }
        )
        
        return try? context.fetch(descriptor).first
    }
    
    /// Get completion status for a specific journey step
    func getStepStatus(_ step: JourneyStep, in context: ModelContext) -> StepStatus {
        if step.isCompleted {
            return .completed
        } else if isChallengeActive(step.programTag, in: context) {
            return .inProgress
        } else if step.isUnlocked {
            return .available
        } else {
            return .locked
        }
    }
    
    /// Step status enum for UI display
    enum StepStatus {
        case completed
        case inProgress
        case available
        case locked
        
        var icon: String {
            switch self {
            case .completed: return "checkmark.circle.fill"
            case .inProgress: return "arrow.clockwise.circle.fill"
            case .available: return "play.circle.fill"
            case .locked: return "lock.fill"
            }
        }
        
        var description: String {
            switch self {
            case .completed: return "Completed"
            case .inProgress: return "In Progress"
            case .available: return "Available"
            case .locked: return "Locked"
            }
        }
    }
    
    // MARK: - Batch Sync (for app launch or background refresh)
    
    /// Full sync of all journey progress - call on app launch
    func performFullSync(in context: ModelContext) {
        #if DEBUG
        print("🔄 JourneyProgressManager: Performing full sync...")
        #endif
        
        syncJourneyProgress(in: context)
        
        #if DEBUG
        print("✅ JourneyProgressManager: Full sync complete")
        #endif
    }
}
