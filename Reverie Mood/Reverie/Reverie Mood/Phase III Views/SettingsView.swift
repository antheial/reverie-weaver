//
//  SettingsView.swift
//  Reverie Mood
//
//  Created by Antheia Li
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import OSLog

private let settingsLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "SettingsView")

// MARK: - SettingsView

struct SettingsView: View {
    @Binding var currentScreen: ContentView.ScreenType
    let entries: [MoodEntry]
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var recoveryManager: DataRecoveryManager
    
    @State private var showExportSheet = false
    @State private var showValidationSheet = false
    @State private var showCleanupAlert = false
    @State private var showAppearanceSheet = false
    @State private var showDailyDispatchSheet = false
    @State private var showImportPicker = false
    @State private var showBackupManager = false
    @State private var showConflictResolution = false
    @State private var exportURL: URL?
    @State private var validationResult: ValidationResult?
    @State private var availableBackups: [BackupFile] = []
    @State private var lastBackupDate: Date?
    @State private var pendingImportURL: URL?
    @State private var importAnalysis: ImportConflictResolver.ConflictAnalysis?
    @State private var showSmartArchive = false
    @State private var storageBreakdown: StorageMonitor.StorageBreakdown = StorageMonitor.StorageBreakdown(
        totalAppUsageMB: 0, photosMB: 0, audioMB: 0, backupsMB: 0, databaseMB: 0
    )
    @State private var yearlyStorageInfo: [StorageMonitor.YearlyStorageInfo] = []
    
    init(currentScreen: Binding<ContentView.ScreenType>, entries: [MoodEntry], modelContext: ModelContext) {
        self._currentScreen = currentScreen
        self.entries = entries
        self._recoveryManager = StateObject(wrappedValue: DataRecoveryManager(modelContext: modelContext))
    }
    
    // MARK: - Computed Properties
    
    private var totalDays: Int {
        entries.count
    }
    
    private var totalNotesWithReflection: Int {
        entries.filter { !$0.reflection.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
    
    private var totalVoiceMemos: Int {
        var count = 0
        for entry in entries {
            if AudioFileManager.memoExists(year: entry.year, day: entry.dayOfYear, slot: .morning) {
                count += 1
            }
            if AudioFileManager.memoExists(year: entry.year, day: entry.dayOfYear, slot: .evening) {
                count += 1
            }
        }
        return count
    }
    
    private var dominantMoodName: String {
        let counts = Dictionary(grouping: entries, by: { $0.moodId }).mapValues { $0.count }
        guard let top = counts.sorted(by: { $0.value > $1.value }).first else { return "—" }
        return (MoodCategory(rawValue: top.key) ?? .neutral).displayName.uppercased()
    }
    
    private var archiveYearRange: String {
        let years = entries.map { $0.year }
        guard let minYear = years.min(), let maxYear = years.max() else { return "—" }
        return minYear == maxYear ? "\(minYear)" : "\(minYear)–\(maxYear)"
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            ReverieBackground()
            
            VStack(spacing: 0) {
                mastheadHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ReverieLayout.spacing24) {
                        archiveSection
                        storageDashboardSection
                        operationsDeskSection
                        preferencesSection
                        footerSection
                    }
                    .padding(.horizontal, ReverieLayout.spacing16)
                    .padding(.top, ReverieLayout.spacing20)
                    .padding(.bottom, 60)
                }
                .onAppear {
                    refreshStorageData()
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheet
        }
        .sheet(isPresented: $showValidationSheet) {
            validationSheet
        }
        .sheet(isPresented: $showAppearanceSheet) {
            AppearanceSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showDailyDispatchSheet) {
            DailyDispatchSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                performImport(from: url)
            case .failure(let error):
                settingsLogger.error("File picker error: \(error.localizedDescription)")
            }
        }
        .alert(L("alert.purge_archives.title"), isPresented: $showCleanupAlert) {
            Button(L("common.abort"), role: .cancel) { }
            Button(L("common.proceed"), role: .destructive) {
                performCleanup()
            }
        } message: {
            Text(L("alert.purge_archives.message"))
        }
        .sheet(isPresented: $showBackupManager) {
            BackupManagerSheet(
                availableBackups: $availableBackups,
                lastBackupDate: $lastBackupDate,
                onCreateBackup: {
                    Task {
                        await DataMigrationManager.shared.createPeriodicBackup(modelContext: modelContext)
                        // Clean up old backups after manual backup creation
                        DataMigrationManager.shared.cleanupOldBackups()
                        loadBackups()
                    }
                },
                onRestoreBackup: { backup in
                    performImport(from: backup.url)
                    showBackupManager = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showConflictResolution) {
            if let analysis = importAnalysis, let url = pendingImportURL {
                ImportConflictSheet(
                    analysis: analysis,
                    onProceed: { strategy, manualDecisions in
                        showConflictResolution = false
                        executeImport(url: url, strategy: strategy, manualDecisions: manualDecisions)
                    },
                    onCancel: {
                        showConflictResolution = false
                        pendingImportURL = nil
                        importAnalysis = nil
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
        .sheet(isPresented: $showSmartArchive) {
            SmartArchiveSheet(
                yearlyInfo: yearlyStorageInfo,
                onBackupRequested: {
                    // Trigger backup flow
                    showSmartArchive = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        loadBackups()
                        showBackupManager = true
                    }
                },
                onArchiveYear: { year in
                    performYearArchive(year: year)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Masthead Header
    
    private var mastheadHeader: some View {
        VStack(spacing: ReverieLayout.spacing12) {
            HStack {
                Button {
                    currentScreen = .year
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 10, weight: .bold))
                        Text(L("common.return"))
                            .font(ReverieTypography.labelTiny)
                            .tracking(1)
                    }
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
                }
                .accessibilityLabel(L("accessibility.back_to_calendar"))
                .accessibilityHint(L("accessibility.back_hint"))
                
                Spacer()
            }
            .padding(.top, 12)
            
            VStack(spacing: 4) {
                Text(L("settings.the"))
                    .font(ReverieTypography.labelTiny)
                    .tracking(4)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))
                
                Text(L("settings.title"))
                    .font(ReverieTypography.headline)
                    .tracking(2)
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
                
                Text(L("settings.bureau"))
                    .font(ReverieTypography.labelTiny)
                    .tracking(4)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L("accessibility.settings"))
            
            VStack(spacing: 2) {
                Rectangle().frame(height: 2)
                Rectangle().frame(height: 0.5)
            }
            .foregroundColor(ReverieColors.borderStrong(colorScheme))
            .accessibilityHidden(true)
        }
        .padding(.horizontal, ReverieLayout.spacing16)
        .padding(.bottom, ReverieLayout.spacing8)
        .background(ReverieColors.background(colorScheme).ignoresSafeArea())
    }

    // MARK: - The Archive Section
    
    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: ReverieLayout.spacing16) {
            sectionHeader(title: L("settings.archive"), subtitle: L("settings.archive_subtitle"))
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    archiveStatCell(
                        value: "\(totalDays)",
                        label: L("archive.entries_filed"),
                        icon: "doc.text.fill"
                    )
                    
                    verticalDivider
                    
                    archiveStatCell(
                        value: "\(totalNotesWithReflection)",
                        label: L("archive.reflections"),
                        icon: "pencil.line"
                    )
                }
                
                horizontalDivider
                
                HStack(spacing: 0) {
                    archiveStatCell(
                        value: totalVoiceMemos > 0 ? "\(totalVoiceMemos)" : "—",
                        label: L("archive.voice_memos"),
                        icon: "mic.fill"
                    )
                    
                    verticalDivider
                    
                    archiveStatCell(
                        value: dominantMoodName,
                        label: L("archive.prevailing_mood"),
                        icon: "heart.fill",
                        isText: true
                    )
                }
            }
            .background(ReverieCardSurface())
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .stroke(ReverieColors.border(colorScheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium))
            
            if !entries.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 10))
                    Text(String(format: L("archive.span"), archiveYearRange))
                        .font(ReverieTypography.labelTiny)
                        .tracking(1)
                }
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: L("accessibility.archive_span"), archiveYearRange))
            }
        }
    }

    // MARK: - Storage Dashboard Section

    private var storageDashboardSection: some View {
        StorageDashboardSection(
            breakdown: storageBreakdown,
            onManageStorage: {
                refreshStorageData()
                showSmartArchive = true
            }
        )
    }

    private func archiveStatCell(value: String, label: String, icon: String, isText: Bool = false) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(ReverieColors.accent(colorScheme))
                .accessibilityHidden(true)
            
            Text(value)
                .font(isText ? ReverieTypography.labelSmall : .custom("Georgia", size: 24).bold())
                .foregroundColor(ReverieColors.textPrimary(colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(ReverieTypography.labelTiny)
                .tracking(0.5)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
    
    // MARK: - Operations Desk Section
    
    private var operationsDeskSection: some View {
        VStack(alignment: .leading, spacing: ReverieLayout.spacing16) {
            sectionHeader(title: L("settings.operations"), subtitle: L("settings.operations_subtitle"))
            
            VStack(spacing: 0) {
                operationRow(
                    icon: "shield.lefthalf.filled.badge.checkmark",
                    title: "BACKUP MANAGER",
                    subtitle: "Auto-backups, iCloud sync, and recovery",
                    action: {
                        loadBackups()
                        showBackupManager = true
                    }
                )

                horizontalDivider

                operationRow(
                    icon: "tray.and.arrow.down.fill",
                    title: "MANUAL IMPORT",
                    subtitle: "Import from external JSON backup file",
                    action: { showImportPicker = true }
                )

                horizontalDivider

                operationRow(
                    icon: "tray.and.arrow.up.fill",
                    title: L("operations.dispatch_backup"),
                    subtitle: L("operations.dispatch_backup.subtitle"),
                    action: { showExportSheet = true }
                )

                horizontalDivider
                
                operationRow(
                    icon: "checkmark.shield.fill",
                    title: L("operations.verify_records"),
                    subtitle: L("operations.verify_records.subtitle"),
                    action: { performValidation() }
                )
                
                horizontalDivider
                
                operationRow(
                    icon: "archivebox.fill",
                    title: L("operations.purge_orphans"),
                    subtitle: L("operations.purge_orphans.subtitle"),
                    isDestructive: true,
                    action: { showCleanupAlert = true }
                )
            }
            .background(ReverieCardSurface())
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .stroke(ReverieColors.border(colorScheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium))
            
            VStack(spacing: 8) {
                if !recoveryManager.exportStatus.isEmpty {
                    statusBadge(recoveryManager.exportStatus)
                }
                if !recoveryManager.validationStatus.isEmpty {
                    statusBadge(recoveryManager.validationStatus)
                }
                if !recoveryManager.cleanupStatus.isEmpty {
                    statusBadge(recoveryManager.cleanupStatus)
                }
            }
        }
    }
    
    private func operationRow(icon: String, title: String, subtitle: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? ReverieColors.warning(colorScheme) : ReverieColors.accent(colorScheme))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ReverieTypography.labelSmall)
                        .tracking(0.5)
                        .foregroundColor(ReverieColors.textPrimary(colorScheme))
                    
                    Text(subtitle)
                        .font(ReverieTypography.labelTiny)
                        .foregroundColor(ReverieColors.textTertiary(colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: ReverieLayout.spacing16) {
            sectionHeader(title: L("settings.preferences"), subtitle: L("settings.preferences_subtitle"))
            
            VStack(spacing: 0) {
                preferenceRow(
                    icon: "paintbrush.fill",
                    title: L("preferences.appearance"),
                    subtitle: L("preferences.appearance.subtitle"),
                    isImplemented: true,
                    action: { showAppearanceSheet = true }
                )
                
                horizontalDivider
                
                preferenceRow(
                    icon: "bell.fill",
                    title: L("preferences.daily_dispatch"),
                    subtitle: L("preferences.daily_dispatch.subtitle"),
                    isImplemented: true,
                    action: { showDailyDispatchSheet = true }
                )
            }
            .background(ReverieCardSurface())
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .stroke(ReverieColors.border(colorScheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium))
        }
    }
    
    private func preferenceRow(icon: String, title: String, subtitle: String, isImplemented: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ReverieColors.accentGold(colorScheme))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ReverieTypography.labelSmall)
                        .tracking(0.5)
                        .foregroundColor(ReverieColors.textPrimary(colorScheme))
                    
                    Text(subtitle)
                        .font(ReverieTypography.labelTiny)
                        .foregroundColor(ReverieColors.textTertiary(colorScheme))
                }
                
                Spacer()
                
                if isImplemented {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ReverieColors.textTertiary(colorScheme))
                } else {
                    Text(L("settings.soon"))
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(ReverieColors.textTertiary(colorScheme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ReverieColors.surfaceRecessed(colorScheme))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .disabled(!isImplemented)
        .opacity(isImplemented ? 1 : 0.7)
        .accessibilityLabel(title)
        .accessibilityHint(isImplemented ? subtitle : L("settings.coming_soon"))
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            ReverieDivider(.ornamental)
            
            VStack(spacing: 4) {
                Text(L("settings.app_name"))
                    .font(ReverieTypography.labelTiny)
                    .tracking(3)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text(L("settings.tagline"))
                    .font(.custom("Georgia-Italic", size: 11))
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text(L("settings.established"))
                    .font(ReverieTypography.labelTiny)
                    .tracking(2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme).opacity(0.6))
                    .padding(.top, 2)
                
                // Privacy Policy Link (Required for App Store)
                Button {
                    if let url = URL(string: "https://reveriearchive-studio.github.io/-reverie-mood-privacy/") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(L("settings.privacy_policy"))
                        .font(ReverieTypography.labelTiny)
                        .tracking(1)
                        .foregroundColor(ReverieColors.accent(colorScheme))
                        .underline()
                }
                .padding(.top, 8)
                .accessibilityLabel(L("accessibility.privacy_policy"))
                .accessibilityHint(L("accessibility.privacy_policy_hint"))
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Reusable Components
    
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ReverieTypography.headlineSmall)
                .tracking(1.5)
                .foregroundColor(ReverieColors.textPrimary(colorScheme))
            
            Text(subtitle)
                .font(ReverieTypography.labelTiny)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
        }
    }
    
    private var verticalDivider: some View {
        Rectangle()
            .fill(ReverieColors.border(colorScheme))
            .frame(width: 1)
    }
    
    private var horizontalDivider: some View {
        Rectangle()
            .fill(ReverieColors.border(colorScheme))
            .frame(height: 1)
    }
    
    private func statusBadge(_ message: String) -> some View {
        let isSuccess = message.hasPrefix("✅")
        let isWarning = message.hasPrefix("⚠️")
        
        return HStack(spacing: 6) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : (isWarning ? "exclamationmark.triangle.fill" : "xmark.circle.fill"))
                .font(.system(size: 12))
            
            Text(message.replacingOccurrences(of: "✅ ", with: "").replacingOccurrences(of: "⚠️ ", with: "").replacingOccurrences(of: "❌ ", with: ""))
                .font(ReverieTypography.labelTiny)
        }
        .foregroundColor(isSuccess ? ReverieColors.success(colorScheme) : (isWarning ? ReverieColors.warning(colorScheme) : ReverieColors.accent(colorScheme)))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ReverieColors.surfaceRecessed(colorScheme))
        )
    }
    
    // MARK: - Export Sheet
    
    private var exportSheet: some View {
        ZStack {
            ReverieColors.surface(colorScheme).ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Capsule()
                        .fill(ReverieColors.border(colorScheme))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .accessibilityHidden(true)
                    
                    Text(L("operations.dispatch_backup"))
                        .font(ReverieTypography.headlineSmall)
                        .tracking(2)
                        .foregroundColor(ReverieColors.textPrimary(colorScheme))
                    
                    ReverieDivider(.solid)
                }
                
                ZStack {
                    Circle()
                        .fill(ReverieColors.accent(colorScheme).opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "tray.and.arrow.up.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(ReverieColors.accent(colorScheme))
                }
                .padding(.top, 8)
                .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    Text(L("operations.dispatch_backup.description"))
                        .font(ReverieTypography.body)
                        .foregroundColor(ReverieColors.textSecondary(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 12) {
                    exportInfoRow(icon: "doc.text.fill", text: "\(entries.count) entries")
                    exportInfoRow(icon: "calendar", text: "Archive: \(archiveYearRange)")
                    exportInfoRow(icon: "mic.fill", text: "Audio references included")
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ReverieColors.surfaceRecessed(colorScheme))
                )
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: performExport) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .bold))
                            Text(L("operations.dispatch_now"))
                                .font(ReverieTypography.buttonPrimary)
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ReverieColors.accent(colorScheme))
                        )
                    }
                    .accessibilityLabel(L("operations.dispatch_backup"))
                    .accessibilityHint(L("operations.dispatch_backup.subtitle"))

                    Button {
                        showExportSheet = false
                    } label: {
                        Text(L("common.cancel"))
                            .font(ReverieTypography.labelSmall)
                            .tracking(1)
                            .foregroundColor(ReverieColors.textSecondary(colorScheme))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
    
    private func exportInfoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(ReverieColors.accent(colorScheme))
                .frame(width: 24)
            
            Text(text)
                .font(ReverieTypography.labelSmall)
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
            
            Spacer()
        }
    }
    
    // MARK: - Validation Sheet
    
    private var validationSheet: some View {
        ZStack {
            ReverieColors.surface(colorScheme).ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Capsule()
                        .fill(ReverieColors.border(colorScheme))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .accessibilityHidden(true)
                    
                    Text(L("operations.verification_report"))
                        .font(ReverieTypography.headlineSmall)
                        .tracking(2)
                        .foregroundColor(ReverieColors.textPrimary(colorScheme))
                    
                    ReverieDivider(.solid)
                }
                
                if let result = validationResult {
                    ZStack {
                        Circle()
                            .fill((result.isAllValid ? ReverieColors.success(colorScheme) : ReverieColors.warning(colorScheme)).opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: result.isAllValid ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(result.isAllValid ? ReverieColors.success(colorScheme) : ReverieColors.warning(colorScheme))
                    }
                    .accessibilityHidden(true)
                    
                    VStack(spacing: 8) {
                        Text(result.isAllValid ? "ALL RECORDS VERIFIED" : "ANOMALIES DETECTED")
                            .font(ReverieTypography.labelLarge)
                            .tracking(1)
                            .foregroundColor(ReverieColors.textPrimary(colorScheme))
                        
                        Text(result.summary)
                            .font(ReverieTypography.body)
                            .foregroundColor(ReverieColors.textSecondary(colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    if !result.issues.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(result.issues, id: \.self) { issue in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(ReverieColors.warning(colorScheme))
                                            .font(.system(size: 12))
                                            .accessibilityHidden(true)
                                        
                                        Text(issue)
                                            .font(ReverieTypography.labelTiny)
                                            .foregroundColor(ReverieColors.textSecondary(colorScheme))
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(ReverieColors.surfaceRecessed(colorScheme))
                            )
                            .padding(.horizontal, 24)
                        }
                        .frame(maxHeight: 150)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        if result.corruptedEntries > 0 {
                            Button(action: performRepair) {
                                HStack(spacing: 8) {
                                    Image(systemName: "wrench.and.screwdriver")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(L("operations.attempt_repair"))
                                        .font(ReverieTypography.buttonPrimary)
                                        .tracking(1)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(ReverieColors.warning(colorScheme))
                                )
                            }
                        }

                        Button {
                            showValidationSheet = false
                        } label: {
                            Text(L("operations.dismiss"))
                                .font(ReverieTypography.labelSmall)
                                .tracking(1)
                                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Actions
    
    private func performExport() {
        // Haptic feedback
        ReverieHaptics.medium()
        
        // Guard against empty exports
        guard !entries.isEmpty else {
            showExportSheet = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Show error after sheet dismisses
                settingsLogger.warning("Export aborted: no entries to export")
            }
            return
        }
        
        // Attempt to create export file
        guard let url = recoveryManager.exportToFile(entries: entries) else {
            showExportSheet = false
            ReverieHaptics.error()
            settingsLogger.error("Export failed: recoveryManager.exportToFile returned nil")
            return
        }
        
        // Store URL for reference
        exportURL = url
        
        // IMPORTANT: Dismiss the sheet FIRST to avoid "already presenting" error
        showExportSheet = false
        
        // Success haptic
        ReverieHaptics.success()
        
        // Wait for sheet to fully dismiss before presenting activity controller
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Create activity view controller
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            // Get the root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootVC = window.rootViewController else {
                ReverieHaptics.error()
                settingsLogger.error("Export failed: Could not get root view controller")
                return
            }
            
            // iPad Support: Configure popover presentation to prevent crash
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            
            // Completion handler to clean up temporary file
            activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                if let error = error {
                    settingsLogger.error("Share sheet error: \(error.localizedDescription)")
                } else if completed {
                    settingsLogger.info("Export completed successfully via \(activityType?.rawValue ?? "unknown")")
                } else {
                    settingsLogger.debug("Export cancelled by user")
                }
                
                // Clean up temporary file after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    try? FileManager.default.removeItem(at: url)
                    settingsLogger.debug("Cleaned up temporary export file")
                }
            }
            
            // Present the share sheet
            rootVC.present(activityVC, animated: true) {
                settingsLogger.info("Activity view controller presented")
            }
        }
    }
    
    private func performValidation() {
        validationResult = recoveryManager.validateEntries(entries: entries)
        showValidationSheet = true
    }
    
    private func performRepair() {
        _ = recoveryManager.repairCorruptedEntries(entries: entries)
        validationResult = recoveryManager.validateEntries(entries: entries)
    }
    
    private func performCleanup() {
        _ = recoveryManager.cleanupOrphanedFiles(entries: entries)
    }
    
    private func loadBackups() {
        availableBackups = DataMigrationManager.shared.getAvailableBackups()
        if let lastBackup = UserDefaults.standard.object(forKey: "lastBackupDate") as? Double {
            lastBackupDate = Date(timeIntervalSince1970: lastBackup)
        }
    }

    private func performImport(from url: URL) {
        // Try to access security-scoped resource (needed for external files from document picker)
        // For local backup files, this will return false but file is still accessible
        let needsSecurityScope = url.startAccessingSecurityScopedResource()

        defer {
            if needsSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Verify file is readable
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            settingsLogger.error("Could not access file at path: \(url.path)")
            return
        }

        // Analyze import for conflicts
        if let analysis = recoveryManager.analyzeImportFile(fileURL: url) {
            if analysis.hasConflicts {
                // Show conflict resolution UI
                pendingImportURL = url
                importAnalysis = analysis
                showConflictResolution = true
            } else {
                // No conflicts - import directly
                executeImport(url: url, strategy: .replaceWithImported, manualDecisions: [:])
            }
        } else {
            settingsLogger.error("Failed to analyze import file")
        }
    }

    private func executeImport(
        url: URL,
        strategy: ImportConflictResolver.ResolutionStrategy,
        manualDecisions: [UUID: ImportConflictResolver.ResolutionDecision.ConflictAction]
    ) {
        // Note: URL is already accessed in performImport, don't access again

        // Perform import with conflict resolution
        if let result = recoveryManager.importWithConflictResolution(
            fileURL: url,
            strategy: strategy,
            manualDecisions: manualDecisions
        ) {
            if result.errors.isEmpty {
                ReverieHaptics.success()
                settingsLogger.info("Import successful: \(result.imported) new, \(result.replaced) replaced, \(result.skipped) skipped")
            } else {
                ReverieHaptics.warning()
                settingsLogger.warning("Import completed with errors: \(result.errors.joined(separator: ", "))")
            }
        } else {
            ReverieHaptics.error()
            settingsLogger.error("Import failed")
        }
    }

    // MARK: - Storage Management

    private func refreshStorageData() {
        // Get storage breakdown
        storageBreakdown = StorageMonitor.shared.getStorageBreakdown()

        // Get yearly info
        yearlyStorageInfo = StorageMonitor.shared.getYearlyStorageInfo(entries: entries)

        settingsLogger.debug("Storage data refreshed: \(storageBreakdown.totalFormatted) total")
    }

    private func performYearArchive(year: Int) {
        settingsLogger.info("Archiving year \(year)")

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            settingsLogger.error("Could not access documents directory")
            return
        }

        let recordingsURL = documentsURL.appendingPathComponent("Recordings")
        let archiveURL = documentsURL.appendingPathComponent("Archives/\(year)")

        // Create archive directory
        try? FileManager.default.createDirectory(at: archiveURL, withIntermediateDirectories: true)

        // Get entries for this year
        let yearEntries = entries.filter { $0.year == year }

        var archivedMemos = 0
        var freedBytes: Int64 = 0

        for entry in yearEntries {
            // Archive morning memo
            let morningMemoPath = recordingsURL.appendingPathComponent("moodmemo_\(entry.year)_\(String(format: "%03d", entry.dayOfYear))_morning.m4a")
            if FileManager.default.fileExists(atPath: morningMemoPath.path) {
                do {
                    // Get original size
                    let attrs = try FileManager.default.attributesOfItem(atPath: morningMemoPath.path)
                    if let size = attrs[.size] as? Int64 {
                        freedBytes += size
                    }

                    // Move to archive
                    let archivePath = archiveURL.appendingPathComponent(morningMemoPath.lastPathComponent)
                    try FileManager.default.moveItem(at: morningMemoPath, to: archivePath)
                    archivedMemos += 1
                } catch {
                    settingsLogger.error("Failed to archive morning memo: \(error.localizedDescription)")
                }
            }

            // Archive evening memo
            let eveningMemoPath = recordingsURL.appendingPathComponent("moodmemo_\(entry.year)_\(String(format: "%03d", entry.dayOfYear))_evening.m4a")
            if FileManager.default.fileExists(atPath: eveningMemoPath.path) {
                do {
                    let attrs = try FileManager.default.attributesOfItem(atPath: eveningMemoPath.path)
                    if let size = attrs[.size] as? Int64 {
                        freedBytes += size
                    }

                    let archivePath = archiveURL.appendingPathComponent(eveningMemoPath.lastPathComponent)
                    try FileManager.default.moveItem(at: eveningMemoPath, to: archivePath)
                    archivedMemos += 1
                } catch {
                    settingsLogger.error("Failed to archive evening memo: \(error.localizedDescription)")
                }
            }
        }

        // Mark year as archived in UserDefaults
        var archivedYears = UserDefaults.standard.array(forKey: "archivedYears") as? [Int] ?? []
        if !archivedYears.contains(year) {
            archivedYears.append(year)
            UserDefaults.standard.set(archivedYears, forKey: "archivedYears")
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        let freedFormatted = formatter.string(fromByteCount: freedBytes)

        settingsLogger.info("Archived \(archivedMemos) memos for \(year), freed \(freedFormatted)")

        // Refresh storage data
        refreshStorageData()
    }
}

// MARK: - Preview

#Preview("Settings - Light") {
    SettingsView(
        currentScreen: .constant(.settings),
        entries: [],
        modelContext: try! ModelContainer(for: MoodEntry.self).mainContext
    )
    .preferredColorScheme(.light)
}

#Preview("Settings - Dark") {
    SettingsView(
        currentScreen: .constant(.settings),
        entries: [],
        modelContext: try! ModelContainer(for: MoodEntry.self).mainContext
    )
    .preferredColorScheme(.dark)
}
