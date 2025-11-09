// ✅ ENHANCED SettingsView with Priority 3: Data Recovery Features
// Implements:
// 1. Data export to JSON (backup/share)
// 2. Orphaned file cleanup
// 3. Data validation and repair
// 4. Import from backup

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var currentScreen: ContentView.ScreenType
    let entries: [MoodEntry]
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var lightDrift = false
    
    // Data recovery manager
    @StateObject private var recoveryManager: DataRecoveryManager
    
    // UI state
    @State private var showExportSheet = false
    @State private var showValidationSheet = false
    @State private var showCleanupAlert = false
    @State private var exportURL: URL?
    @State private var validationResult: ValidationResult?
    
    init(currentScreen: Binding<ContentView.ScreenType>, entries: [MoodEntry], modelContext: ModelContext) {
        self._currentScreen = currentScreen
        self.entries = entries
        self._recoveryManager = StateObject(wrappedValue: DataRecoveryManager(modelContext: modelContext))
    }
    
    // Computed properties
    private var totalDays: Int {
        entries.count
    }
    
    private var totalNotesWithReflection: Int {
        entries.filter { !$0.reflection.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
    
    var body: some View {
        ZStack {
            // Background
            if colorScheme == .dark {
                DarkEtherealBackground()
            } else {
                LightPaperBackground(drift: lightDrift)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    header
                    
                    VStack(spacing: 16) {
                        // Your Journey
                        yourJourneyCard
                        
                        // ✅ NEW: Data Management (Priority 3)
                        dataManagementCard
                        
                        // Customize Appearance (placeholder for Phase 2)
                        settingsCard(
                            icon: "paintbrush.fill",
                            title: "Customize Appearance",
                            subtitle: "Backgrounds, effects, animations",
                            action: { /* Phase 2 */ }
                        )
                        
                        // Daily Reminder (placeholder)
                        settingsCard(
                            icon: "bell.fill",
                            title: "Daily Reminder",
                            subtitle: "Set notification preferences",
                            action: { /* Future feature */ }
                        )
                        
                        // Accessibility (placeholder for Phase 4)
                        settingsCard(
                            icon: "accessibility",
                            title: "Accessibility",
                            subtitle: "Battery saving, reduce motion",
                            action: { /* Phase 4 */ }
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheet
        }
        .sheet(isPresented: $showValidationSheet) {
            validationSheet
        }
        .alert("Clean Up Storage", isPresented: $showCleanupAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clean Up", role: .destructive) {
                performCleanup()
            }
        } message: {
            Text("This will remove audio files that don't have matching journal entries. This action cannot be undone.")
        }
        .onAppear {
            if colorScheme == .light {
                withAnimation(.easeInOut(duration: 8)) {
                    lightDrift = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: colorScheme)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                currentScreen = .year
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(colorScheme == .dark ? Color(hex: "E2E8F0") : Color(hex: "2D3748"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "2D3748"))
            
            Spacer()
            
            Color.clear.frame(width: 70)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Your Journey Card
    
    private var yourJourneyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(colorScheme == .dark ? Color.purple.opacity(0.8) : Color.purple)
                
                Text("Your Journey")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "2D3748"))
            }
            
            Divider()
                .background(colorScheme == .dark ? .white.opacity(0.1) : .gray.opacity(0.2))
            
            // Stats
            VStack(spacing: 12) {
                statRow(
                    icon: "calendar",
                    value: "\(totalDays)",
                    label: totalDays == 1 ? "day captured this year" : "days captured this year",
                    color: .pink
                )
                
                statRow(
                    icon: "note.text",
                    value: "\(totalNotesWithReflection)",
                    label: totalNotesWithReflection == 1 ? "thought recorded" : "thoughts recorded",
                    color: .blue
                )
            }
            
            // Milestones section (placeholder for Phase 3)
            VStack(alignment: .leading, spacing: 8) {
                Text("Milestones")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .gray)
                    .padding(.top, 8)
                
                Text("Keep capturing your moments to unlock milestones! ✨")
                    .font(.system(size: 12))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .gray.opacity(0.8))
                    .italic()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.5 : 0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(colorScheme == .dark ? .white.opacity(0.06) : .white.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
    }
    
    // MARK: - ✅ NEW: Data Management Card (Priority 3)
    
    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.blue)
                
                Text("Data Management")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "2D3748"))
            }
            
            Divider()
                .background(colorScheme == .dark ? .white.opacity(0.1) : .gray.opacity(0.2))
            
            VStack(spacing: 10) {
                // Export Data
                dataManagementButton(
                    icon: "square.and.arrow.up",
                    title: "Export Backup",
                    subtitle: "Save your journal as JSON",
                    color: .blue,
                    action: { showExportSheet = true }
                )
                
                // Validate Data
                dataManagementButton(
                    icon: "checkmark.shield.fill",
                    title: "Validate Data",
                    subtitle: "Check for corrupted entries",
                    color: .green,
                    action: { performValidation() }
                )
                
                // Clean Up Files
                dataManagementButton(
                    icon: "trash.fill",
                    title: "Clean Up Storage",
                    subtitle: "Remove orphaned audio files",
                    color: .orange,
                    action: { showCleanupAlert = true }
                )
            }
            
            // Status messages
            if !recoveryManager.exportStatus.isEmpty {
                statusMessage(recoveryManager.exportStatus)
            }
            if !recoveryManager.validationStatus.isEmpty {
                statusMessage(recoveryManager.validationStatus)
            }
            if !recoveryManager.cleanupStatus.isEmpty {
                statusMessage(recoveryManager.cleanupStatus)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.5 : 0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(colorScheme == .dark ? .white.opacity(0.06) : .white.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
    }
    
    private func dataManagementButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "2D3748"))
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.4) : .gray.opacity(0.5))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private func statusMessage(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(
                message.hasPrefix("✅") ? .green :
                message.hasPrefix("⚠️") ? .orange : .red
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
            )
    }
    
    // MARK: - Export Sheet
    
    private var exportSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)
                
                VStack(spacing: 12) {
                    Text("Export Your Journal")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Save a backup of all your entries in JSON format. This includes all moods, reflections, and metadata.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 16) {
                    infoRow(icon: "doc.text.fill", text: "\(entries.count) entries")
                    infoRow(icon: "calendar", text: "All years included")
                    infoRow(icon: "mic.fill", text: "Audio file references")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: performExport) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Now")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarItems(trailing: Button("Close") { showExportSheet = false })
        }
    }
    
    // MARK: - Validation Sheet
    
    private var validationSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let result = validationResult {
                    Image(systemName: result.isAllValid ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(result.isAllValid ? .green : .orange)
                        .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text(result.isAllValid ? "All Valid!" : "Issues Found")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(result.summary)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    if !result.issues.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(result.issues, id: \.self) { issue in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundStyle(.orange)
                                            .font(.system(size: 12))
                                        Text(issue)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer()
                    
                    if result.corruptedEntries > 0 {
                        Button(action: performRepair) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver")
                                Text("Attempt Repair")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationBarItems(trailing: Button("Close") { showValidationSheet = false })
        }
    }
    
    // MARK: - Actions
    
    private func performExport() {
        if let url = recoveryManager.exportToFile(entries: entries) {
            exportURL = url
            // Share the file
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
        showExportSheet = false
    }
    
    private func performValidation() {
        validationResult = recoveryManager.validateEntries(entries: entries)
        showValidationSheet = true
    }
    
    private func performRepair() {
        _ = recoveryManager.repairCorruptedEntries(entries: entries)
        // Re-validate after repair
        validationResult = recoveryManager.validateEntries(entries: entries)
    }
    
    private func performCleanup() {
        _ = recoveryManager.cleanupOrphanedFiles(entries: entries)
    }
    
    // MARK: - Reusable Components
    
    private func settingsCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(colorScheme == .dark ? Color.purple.opacity(0.8) : Color.purple)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "2D3748"))
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.4) : .gray.opacity(0.5))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.5 : 0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(colorScheme == .dark ? .white.opacity(0.06) : .white.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
    
    private func statRow(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "2D3748"))
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

