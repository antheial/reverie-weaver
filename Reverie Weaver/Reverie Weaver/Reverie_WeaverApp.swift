//
//  ReverieWeaverApp.swift
//  Reverie Weaver
//

import SwiftUI
import SwiftData
import Combine
import UserNotifications

// MARK: - Performance Monitoring

#if DEBUG
struct PerformanceTimer: Sendable {
    let name: String
    let startTime: CFAbsoluteTime

    nonisolated init(_ name: String) {
        self.name = name
        self.startTime = CFAbsoluteTimeGetCurrent()
        print("⏱️ [\(name)] Started")
    }

    nonisolated func stop() {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let ms = String(format: "%.3f", elapsed * 1000)
        let icon = elapsed < 0.016 ? "🟢" : elapsed < 0.100 ? "🟡" : "🔴"
        print("\(icon) [\(name)] Completed in \(ms)ms")
    }
}
#endif

// MARK: - Main App

@main
struct ReverieWeaverApp: App {
    @State private var container: ModelContainer?
    @State private var isLoading = true
    private static var notificationsConfigured = false

    // MARK: - Initialization

    init() {
        // Only setup notifications synchronously (fast)
        Self.setupNotifications()
    }
    
    // MARK: - Notification Setup
    
    private static func setupNotifications() {
        guard !notificationsConfigured else { return }
        
        #if DEBUG
        let timer = PerformanceTimer("Notification Setup")
        defer { timer.stop() }
        #endif
        
        let center = UNUserNotificationCenter.current()
        
        let category = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [
                UNNotificationAction(identifier: "MARK_DONE", title: "Mark Done ✓", options: [.foreground]),
                UNNotificationAction(identifier: "SNOOZE_15", title: "Snooze 15m", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([category])
        center.delegate = HabitNotificationManager.shared
        notificationsConfigured = true
        
        #if DEBUG
        print("✅ Notification system initialized")
        #endif
    }
    
    // MARK: - SwiftData Setup

    private nonisolated static func createModelContainer() -> ModelContainer {
        // CloudKit Configuration (local to avoid actor isolation issues)
        // Set to true when you have a paid Apple Developer account and have:
        // 1. Added iCloud capability in Xcode (Signing & Capabilities)
        // 2. Created a CloudKit container: iCloud.com.ReverieArchive.ReverieWeaver
        // 3. Enabled CloudKit in the iCloud capability
        let enableCloudKit = false
        let cloudKitContainerIdentifier = "iCloud.com.ReverieArchive.ReverieWeaver"

        #if DEBUG
        let schemaTimer = PerformanceTimer("SwiftData Schema Creation")
        #endif

        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            UserProfile.self,
            PersonalizedJourney.self,
            Reflection.self,
            DailyIntention.self,
            DailyReflection.self,
            ReflectionNote.self,
            Achievement.self,
            ConstellationBadge.self,
            InvisibleAchievement.self,
            PriorityTask.self,
            SubTask.self,
            PomodoroSession.self,
            MicroHabitCompletion.self,
            MicroHabitProgress.self,
            MiniChallengeProgress.self,
            ThemeWeekProgress.self,
            VitalityProgress.self,
            // PDF Import models
            ImportedPDF.self,
            PDFTaskList.self,
            ExtractedTask.self,
            // Weekly Challenges
            WeeklyChallenge.self
        ])

        #if DEBUG
        schemaTimer.stop()
        let containerTimer = PerformanceTimer("ModelContainer Creation")
        #endif

        // Configure with or without CloudKit based on enableCloudKit flag
        let config: ModelConfiguration
        if enableCloudKit {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
            #if DEBUG
            print("☁️ CloudKit sync enabled with container: \(cloudKitContainerIdentifier)")
            #endif
        } else {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            #if DEBUG
            print("💾 Local storage only (CloudKit disabled)")
            #endif
        }
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])

            #if DEBUG
            containerTimer.stop()
            print("✅ SwiftData container initialized")
            #endif

            return container
        } catch {
            #if DEBUG
            print("💥 SwiftData container creation failed: \(error)")
            print("🔄 Attempting to recover by deleting old database...")
            #endif

            // Try to recover by deleting the old database
            // This happens when schema changes are incompatible
            if let containerURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = containerURL.appendingPathComponent("default.store")
                let shmURL = containerURL.appendingPathComponent("default.store-shm")
                let walURL = containerURL.appendingPathComponent("default.store-wal")

                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: shmURL)
                try? FileManager.default.removeItem(at: walURL)

                #if DEBUG
                print("🗑️ Old database files removed, retrying container creation...")
                #endif

                // Retry container creation
                do {
                    let container = try ModelContainer(for: schema, configurations: [config])
                    #if DEBUG
                    print("✅ SwiftData container initialized after recovery")
                    #endif
                    return container
                } catch {
                    #if DEBUG
                    print("💥 Recovery failed: \(error)")
                    #endif
                }
            }

            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = container {
                    MainTabView()
                        .onAppear(perform: initializeApp)
                        .onReceive(NotificationCenter.default.publisher(for: .habitMarkDoneFromNotification), perform: handleMarkDoneFromNotification)
                        .onReceive(NotificationCenter.default.publisher(for: .habitNotificationTapped), perform: handleNotificationTapped)
                        .modelContainer(container)
                } else {
                    // Splash screen while loading
                    SplashLoadingView()
                        .task {
                            await loadContainer()
                        }
                }
            }
        }
    }

    // MARK: - Async Container Loading

    @MainActor
    private func loadContainer() async {
        #if DEBUG
        let timer = PerformanceTimer("App Initialization (Async)")
        #endif

        // Move heavy work to background thread
        let newContainer = await Task.detached(priority: .userInitiated) {
            Self.createModelContainer()
        }.value

        #if DEBUG
        timer.stop()
        #endif

        self.container = newContainer
        self.isLoading = false
    }
    
    // MARK: - Post-Launch Initialization
    
    private func initializeApp() {
        Task { @MainActor in
            #if DEBUG
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            logNotificationPermissionStatus(settings.authorizationStatus)
            #endif
            
            WeaverJourneyManager.shared.startJourney()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            #if DEBUG
            await printPendingNotifications()
            await verifyNotificationSetup()
            #endif
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleMarkDoneFromNotification(_ notification: Notification) {
        guard let habitId = notification.userInfo?["habitId"] as? UUID else {
            #if DEBUG
            print("⚠️ Could not extract habitId from Mark Done notification")
            #endif
            return
        }
        
        #if DEBUG
        let habitName = notification.userInfo?["habitName"] as? String ?? "Unknown"
        print("✅ Mark Done from notification: \(habitName)")
        #endif
        
        NotificationCenter.default.post(
            name: .habitNeedsCompletion,
            object: nil,
            userInfo: ["habitId": habitId]
        )
    }
    
    private func handleNotificationTapped(_ notification: Notification) {
        #if DEBUG
        if let habitName = notification.userInfo?["habitName"] as? String {
            print("👆 Notification tapped: \(habitName)")
        }
        #endif
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    private func logNotificationPermissionStatus(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: print("📱 Notification permission: Not determined")
        case .denied:        print("❌ Notification permission: Denied")
        case .authorized:    print("✅ Notification permission: Authorized")
        case .provisional:   print("📱 Notification permission: Provisional")
        case .ephemeral:     print("📱 Notification permission: Ephemeral")
        @unknown default:    print("⚠️ Notification permission: Unknown")
        }
    }
    
    private func printPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Pending notifications: \(requests.count)")
        
        for request in requests.prefix(5) {
            print("   - \(request.identifier): \(request.content.title)")
            print("      Category: \(request.content.categoryIdentifier)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("      Trigger: \(trigger.dateComponents)")
            }
        }
        
        if requests.count > 5 {
            print("   ... and \(requests.count - 5) more")
        }
    }
    
    private func verifyNotificationSetup() async {
        let center = UNUserNotificationCenter.current()
        
        let categories = await center.notificationCategories()
        print("📦 Registered categories: \(categories.count)")
        for category in categories {
            print("   - \(category.identifier): \(category.actions.count) actions")
            for action in category.actions {
                print("      • \(action.identifier): \(action.title)")
            }
        }
        
        print(center.delegate != nil ? "✅ Notification delegate is set" : "❌ WARNING: Notification delegate is NOT set!")
        
        let settings = await center.notificationSettings()
        print("🔔 Authorization: \(settings.authorizationStatus.rawValue)")
        print("   Alert: \(settings.alertSetting.rawValue)")
        print("   Badge: \(settings.badgeSetting.rawValue)")
        print("   Sound: \(settings.soundSetting.rawValue)")
    }
    #endif
}

// MARK: - Notification Names

extension Notification.Name {
    static let habitNeedsCompletion = Notification.Name("habitNeedsCompletion")
}

// MARK: - Splash Loading View

struct SplashLoadingView: View {
    @State private var opacity: Double = 0.6

    var body: some View {
        ZStack {
            // Match your app's background
            Color(red: 0.98, green: 0.97, blue: 0.95)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // App icon or logo placeholder
                Image(systemName: "wind")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.66, green: 0.71, blue: 0.63), Color(red: 0.71, green: 0.78, blue: 0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(opacity)

                Text("Reverie Weaver")
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                opacity = 1.0
            }
        }
    }
}
