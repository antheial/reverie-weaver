//
//  ReverieWeaverApp.swift
//  ReverieWeaver
//
//  Main app entry point
//

import SwiftUI
import SwiftData
import Combine   // ✅ Required for ObservableObject & @Published in WeaverJourneyManager

@main
struct ReverieWeaverApp: App {
    // MARK: - Shared SwiftData Container
    var sharedModelContainer: ModelContainer = {
        // Define all SwiftData models
        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            Reflection.self,
            DailyIntention.self,
            Achievement.self,
            UserProfile.self,
            PriorityTask.self,
            SubTask.self,
            PomodoroSession.self,
            MicroHabitCompletion.self,
            MicroHabitProgress.self,
            MiniChallengeProgress.self,  // ✅ NEW - mini challenge progress tracking
            ReflectionNote.self,   // ← ADD THIS LINE
            ConstellationBadge.self,      // ✅ NEW - constellation model
            InvisibleAchievement.self
            // ✅ NEW - hidden achievements
        ])

        // Enable automatic migration and persistent storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            // Create the persistent container
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // NOTE:
            // Removed legacy "default habit seeding"
            // All user habits will be created manually or via curated programs (e.g. Project 50)

            return container
        } catch {
            print("💥 SwiftData container creation failed: \(error)")
            fatalError("❌ Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Main Scene
    var body: some Scene {
        WindowGroup {
            MainTabView()
                // ✅ Correct placement of lifecycle logic
                // The gamification system initializes here (not on Schema)
                .onAppear {
                    WeaverJourneyManager.shared.startJourney()
                    WeaverJourneyManager.shared.refreshJourney()
                }
        }
        // ✅ Attach shared model container
        .modelContainer(sharedModelContainer)
    }
}
