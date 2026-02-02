//
//  SmartArchiveSheet.swift
//  Reverie Mood
//
//  Created by Antheia Li on 1/30/26.
//
//  Smart Archive System for managing yearly data storage.
//  Prompts users to archive past years with backup integration.
//

import SwiftUI
import SwiftData
import OSLog

private let archiveLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "SmartArchive")

struct SmartArchiveSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let yearlyInfo: [StorageMonitor.YearlyStorageInfo]
    let onBackupRequested: () -> Void
    let onArchiveYear: (Int) -> Void

    @State private var selectedYear: Int?
    @State private var showBackupPrompt = false
    @State private var isArchiving = false
    @State private var archiveComplete = false

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var archivableYears: [StorageMonitor.YearlyStorageInfo] {
        yearlyInfo.filter { $0.year < currentYear && $0.entryCount > 0 }
    }

    var body: some View {
        ZStack {
            ReverieColors.surface(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Explanation
                        explanationCard

                        // Year cards
                        if !archivableYears.isEmpty {
                            yearsList
                        } else {
                            noArchivesCard
                        }

                        // Current year info
                        currentYearCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Create Backup First?", isPresented: $showBackupPrompt) {
            Button("Skip Backup") {
                if let year = selectedYear {
                    performArchive(year: year)
                }
            }
            Button("Backup First", role: .cancel) {
                onBackupRequested()
                dismiss()
            }
        } message: {
            Text("We recommend creating a backup before archiving. Archived data will be compressed and older voice memos may be removed to save space.")
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(ReverieColors.border(colorScheme))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            VStack(spacing: 4) {
                Text("THE")
                    .font(ReverieTypography.labelTiny)
                    .tracking(4)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text("ARCHIVE VAULT")
                    .font(ReverieTypography.headline)
                    .tracking(2)
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))

                Text("YEARLY STORAGE MANAGER")
                    .font(ReverieTypography.labelTiny)
                    .tracking(4)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))
            }

            VStack(spacing: 2) {
                Rectangle().frame(height: 2)
                Rectangle().frame(height: 0.5)
            }
            .foregroundColor(ReverieColors.borderStrong(colorScheme))
            .padding(.top, 8)
        }
    }

    // MARK: - Explanation Card

    private var explanationCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ReverieColors.accentGold(colorScheme))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Archive System")
                        .font(ReverieTypography.labelSmall)
                        .foregroundColor(ReverieColors.textPrimary(colorScheme))

                    Text("Optimize storage for past years")
                        .font(ReverieTypography.labelTiny)
                        .foregroundColor(ReverieColors.textTertiary(colorScheme))
                }

                Spacer()
            }

            Text("Archiving a year will compress voice memos and optimize photos, reducing storage while preserving your memories. Journal entries remain fully accessible.")
                .font(ReverieTypography.body)
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(ReverieCardSurface())
        .overlay(
            RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                .stroke(ReverieColors.accentGold(colorScheme).opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium))
    }

    // MARK: - Years List

    private var yearsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AVAILABLE FOR ARCHIVE")
                .font(ReverieTypography.labelTiny)
                .tracking(2)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))

            VStack(spacing: 0) {
                ForEach(archivableYears, id: \.year) { yearInfo in
                    yearRow(yearInfo)

                    if yearInfo.year != archivableYears.last?.year {
                        Rectangle()
                            .fill(ReverieColors.border(colorScheme))
                            .frame(height: 1)
                    }
                }
            }
            .background(ReverieCardSurface())
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .stroke(ReverieColors.border(colorScheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium))
        }
    }

    private func yearRow(_ info: StorageMonitor.YearlyStorageInfo) -> some View {
        HStack(spacing: 14) {
            // Year badge
            VStack(spacing: 2) {
                Text(String(info.year))
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
            }
            .frame(width: 60)

            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("\(info.entryCount) entries")
                    .font(ReverieTypography.labelSmall)
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))

                HStack(spacing: 12) {
                    Label("\(info.photoCount)", systemImage: "photo.fill")
                    Label("\(info.audioCount)", systemImage: "mic.fill")
                    Text("•")
                    Text(info.totalFormatted)
                        .fontWeight(.medium)
                }
                .font(ReverieTypography.labelTiny)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
            }

            Spacer()

            // Archive button
            Button {
                selectedYear = info.year
                showBackupPrompt = true
            } label: {
                Text("ARCHIVE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(ReverieColors.accent(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ReverieColors.accent(colorScheme), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - No Archives Card

    private var noArchivesCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(ReverieColors.success(colorScheme))

            Text("All Caught Up!")
                .font(ReverieTypography.labelLarge)
                .foregroundColor(ReverieColors.textPrimary(colorScheme))

            Text("No previous years available for archiving. Past years will appear here when the calendar turns.")
                .font(ReverieTypography.body)
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(ReverieCardSurface())
        .overlay(
            RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                .stroke(ReverieColors.border(colorScheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium))
    }

    // MARK: - Current Year Card

    private var currentYearCard: some View {
        let currentYearInfo = yearlyInfo.first(where: { $0.year == currentYear })

        return VStack(alignment: .leading, spacing: 12) {
            Text("CURRENT YEAR")
                .font(ReverieTypography.labelTiny)
                .tracking(2)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ReverieColors.accent(colorScheme).opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(ReverieColors.accent(colorScheme))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(currentYear))
                        .font(.custom("Georgia-Bold", size: 18))
                        .foregroundColor(ReverieColors.textPrimary(colorScheme))

                    if let info = currentYearInfo {
                        Text("\(info.entryCount) entries • \(info.photoCount) photos • \(info.audioCount) memos")
                            .font(ReverieTypography.labelTiny)
                            .foregroundColor(ReverieColors.textTertiary(colorScheme))
                    } else {
                        Text("No entries yet")
                            .font(ReverieTypography.labelTiny)
                            .foregroundColor(ReverieColors.textTertiary(colorScheme))
                    }
                }

                Spacer()

                Text("ACTIVE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(ReverieColors.success(colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ReverieColors.success(colorScheme).opacity(0.1))
                    )
            }
            .padding(16)
            .background(ReverieCardSurface())
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .stroke(ReverieColors.border(colorScheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium))
        }
    }

    // MARK: - Actions

    private func performArchive(year: Int) {
        isArchiving = true
        archiveLogger.info("Starting archive for year \(year)")

        // Call the archive callback
        onArchiveYear(year)

        // Show completion after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isArchiving = false
            archiveComplete = true
            ReverieHaptics.success()
            archiveLogger.info("Archive complete for year \(year)")

            // Dismiss after showing completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        }
    }
}

// MARK: - Storage Dashboard Section

struct StorageDashboardSection: View {
    @Environment(\.colorScheme) private var colorScheme

    let breakdown: StorageMonitor.StorageBreakdown
    let onManageStorage: () -> Void

    private var totalBytes: Int64 {
        (breakdown.photosMB + breakdown.audioMB + breakdown.databaseMB + breakdown.backupsMB) * 1024 * 1024
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader

            VStack(spacing: 0) {
                // Total storage header
                storageHeader

                Rectangle()
                    .fill(ReverieColors.border(colorScheme))
                    .frame(height: 1)

                // Storage bars
                VStack(spacing: 12) {
                    storageBar(
                        icon: "mic.fill",
                        label: "Voice Memos",
                        count: breakdown.audioCount,
                        size: breakdown.audioFormatted,
                        percentage: breakdown.audioMB > 0 ? Double(breakdown.audioMB) / Double(max(1, breakdown.totalAppUsageMB)) : 0,
                        color: ReverieColors.accent(colorScheme)
                    )

                    storageBar(
                        icon: "photo.fill",
                        label: "Photos",
                        count: breakdown.photoCount,
                        size: breakdown.photosFormatted,
                        percentage: breakdown.photosMB > 0 ? Double(breakdown.photosMB) / Double(max(1, breakdown.totalAppUsageMB)) : 0,
                        color: ReverieColors.accentGold(colorScheme)
                    )

                    storageBar(
                        icon: "doc.text.fill",
                        label: "Journal Data",
                        count: nil,
                        size: breakdown.databaseFormatted,
                        percentage: breakdown.databaseMB > 0 ? Double(breakdown.databaseMB) / Double(max(1, breakdown.totalAppUsageMB)) : 0,
                        color: ReverieColors.success(colorScheme)
                    )

                    if breakdown.backupCount > 0 {
                        storageBar(
                            icon: "arrow.clockwise.circle.fill",
                            label: "Backups",
                            count: breakdown.backupCount,
                            size: breakdown.backupsFormatted,
                            percentage: breakdown.backupsMB > 0 ? Double(breakdown.backupsMB) / Double(max(1, breakdown.totalAppUsageMB)) : 0,
                            color: ReverieColors.textSecondary(colorScheme)
                        )
                    }
                }
                .padding(16)

                Rectangle()
                    .fill(ReverieColors.border(colorScheme))
                    .frame(height: 1)

                // Manage storage button
                Button(action: onManageStorage) {
                    HStack {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ReverieColors.accent(colorScheme))

                        Text("MANAGE YEARLY ARCHIVES")
                            .font(ReverieTypography.labelSmall)
                            .tracking(0.5)
                            .foregroundColor(ReverieColors.textPrimary(colorScheme))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ReverieColors.textTertiary(colorScheme))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .background(ReverieCardSurface())
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .stroke(ReverieColors.border(colorScheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium))
        }
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("STORAGE DASHBOARD")
                .font(ReverieTypography.headlineSmall)
                .tracking(1.5)
                .foregroundColor(ReverieColors.textPrimary(colorScheme))

            Text("Monitor your archive's footprint")
                .font(ReverieTypography.labelTiny)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
        }
    }

    private var storageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL USAGE")
                    .font(ReverieTypography.labelTiny)
                    .tracking(1)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text(breakdown.totalFormatted)
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
            }

            Spacer()

            // Visual indicator
            ZStack {
                Circle()
                    .stroke(ReverieColors.border(colorScheme), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: min(1, Double(breakdown.totalAppUsageMB) / 1000)) // Show relative to 1GB
                    .stroke(ReverieColors.accent(colorScheme), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
            }
        }
        .padding(16)
    }

    private func storageBar(
        icon: String,
        label: String,
        count: Int?,
        size: String,
        percentage: Double,
        color: Color
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                    .frame(width: 20)

                Text(label)
                    .font(ReverieTypography.labelSmall)
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))

                if let count = count {
                    Text("(\(count))")
                        .font(ReverieTypography.labelTiny)
                        .foregroundColor(ReverieColors.textTertiary(colorScheme))
                }

                Spacer()

                Text(size)
                    .font(ReverieTypography.labelSmall)
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ReverieColors.surfaceRecessed(colorScheme))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: max(4, geo.size.width * min(1, percentage)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Preview

#Preview("Smart Archive Sheet") {
    SmartArchiveSheet(
        yearlyInfo: [
            StorageMonitor.YearlyStorageInfo(
                year: 2024,
                photoCount: 120,
                audioCount: 200,
                entryCount: 250,
                photoSizeBytes: 35_000_000,
                audioSizeBytes: 100_000_000
            ),
            StorageMonitor.YearlyStorageInfo(
                year: 2025,
                photoCount: 300,
                audioCount: 500,
                entryCount: 365,
                photoSizeBytes: 90_000_000,
                audioSizeBytes: 250_000_000
            ),
            StorageMonitor.YearlyStorageInfo(
                year: 2026,
                photoCount: 30,
                audioCount: 50,
                entryCount: 30,
                photoSizeBytes: 9_000_000,
                audioSizeBytes: 25_000_000
            )
        ],
        onBackupRequested: {},
        onArchiveYear: { _ in }
    )
}

#Preview("Storage Dashboard") {
    StorageDashboardSection(
        breakdown: StorageMonitor.StorageBreakdown(
            totalAppUsageMB: 450,
            photosMB: 120,
            audioMB: 280,
            backupsMB: 15,
            databaseMB: 35,
            photoCount: 250,
            audioCount: 500,
            backupCount: 3
        ),
        onManageStorage: {}
    )
    .padding()
}
