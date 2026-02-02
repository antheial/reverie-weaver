//
// NotificationDebugView.swift
// Reverie Weaver
//
// Debug tool for testing notification system
// ✅ Helps verify categories, permissions, and action buttons
//

import SwiftUI
import UserNotifications

struct NotificationDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var authStatus: String = "Checking..."
    @State private var pendingCount: Int = 0
    @State private var categoryCount: Int = 0
    @State private var categoryDetails: String = ""
    @State private var testResult: String = ""
    @State private var isSendingTest: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Permission Status
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Permission Status", systemImage: "bell.badge")
                                .font(.headline)
                            
                            Text(authStatus)
                                .font(.system(size: 14, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // MARK: - Category Status
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Registered Categories", systemImage: "square.stack.3d.up")
                                .font(.headline)
                            
                            Text("Count: \(categoryCount)")
                                .font(.system(size: 14))
                            
                            if !categoryDetails.isEmpty {
                                Text(categoryDetails)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // MARK: - Pending Notifications
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Pending Notifications", systemImage: "calendar.badge.clock")
                                .font(.headline)
                            
                            Text("Count: \(pendingCount)")
                                .font(.system(size: 14))
                        }
                        
                        // MARK: - Test Notification
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Test Notification", systemImage: "testtube.2")
                                .font(.headline)
                            
                            Button {
                                sendTestNotification()
                            } label: {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text(isSendingTest ? "Sending..." : "Send Test (5 sec)")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.sageGreen)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isSendingTest)
                            
                            if !testResult.isEmpty {
                                Text(testResult)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(testResult.contains("✅") ? .green : .red)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // MARK: - Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Test Instructions", systemImage: "info.circle")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1. Verify categories show 2 actions")
                                Text("2. Tap 'Send Test' button")
                                Text("3. Lock device or switch apps")
                                Text("4. Wait 5 seconds for notification")
                                Text("5. Verify 'Mark Done ✓' and 'Snooze 15m' buttons appear")
                            }
                            .font(.system(size: 13))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Notification Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await refreshStatus()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                Task {
                    await refreshStatus()
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func refreshStatus() async {
        // Check permission
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .notDetermined:
                authStatus = "❓ Not Determined\nPermission not yet requested"
            case .denied:
                authStatus = "❌ Denied\nEnable in Settings > Notifications"
            case .authorized:
                authStatus = "✅ Authorized\nNotifications enabled"
            case .provisional:
                authStatus = "📝 Provisional\nQuiet notifications enabled"
            case .ephemeral:
                authStatus = "⏰ Ephemeral\nTemporary authorization"
            @unknown default:
                authStatus = "⚠️ Unknown"
            }
        }
        
        // Check categories
        let categories = await UNUserNotificationCenter.current().notificationCategories()
        await MainActor.run {
            categoryCount = categories.count
            
            var details = ""
            for category in categories {
                details += "\(category.identifier)\n"
                details += "  Actions: \(category.actions.count)\n"
                for action in category.actions {
                    details += "  • \(action.identifier): \(action.title)\n"
                    let options = action.options
                    if options.contains(.foreground) {
                        details += "    [foreground]\n"
                    }
                    if options.contains(.destructive) {
                        details += "    [destructive]\n"
                    }
                    if options.contains(.authenticationRequired) {
                        details += "    [auth required]\n"
                    }
                }
            }
            categoryDetails = details.isEmpty ? "No categories registered" : details
        }
        
        // Check pending notifications
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        await MainActor.run {
            pendingCount = pending.count
        }
    }
    
    private func sendTestNotification() {
        isSendingTest = true
        testResult = "Sending test notification...\nWait 5 seconds and lock device"
        
        Task {
            let content = UNMutableNotificationContent()
            content.title = "Test Notification · Day 5"
            content.subtitle = "Keep your streak going! 🔥"
            content.body = "This is a test notification with action buttons"
            content.sound = .default
            
            // ✅ CRITICAL: Set the category identifier
            content.categoryIdentifier = "HABIT_REMINDER"
            
            content.userInfo = [
                "habitId": UUID().uuidString,
                "habitName": "Test Habit",
                "streak": 4,
                "isTest": true
            ]
            
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
                content.relevanceScore = 1.0
            }
            
            // Trigger in 5 seconds
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "test-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                
                await MainActor.run {
                    testResult = """
                    ✅ Test notification scheduled!
                    
                    Category: \(content.categoryIdentifier)
                    Trigger: 5 seconds
                    
                    Lock device now and wait...
                    """
                    isSendingTest = false
                }
                
                // Refresh pending count
                await refreshStatus()
                
            } catch {
                await MainActor.run {
                    testResult = "❌ Failed to schedule: \(error.localizedDescription)"
                    isSendingTest = false
                }
            }
        }
    }
}

#Preview {
    NotificationDebugView()
}
