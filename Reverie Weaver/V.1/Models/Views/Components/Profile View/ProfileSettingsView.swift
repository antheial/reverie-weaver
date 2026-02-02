//
// ProfileSettingsView.swift
// Reverie Weaver
//
//

import SwiftUI
import SwiftData
import StoreKit
import CoreText
import UIKit
import CloudKit

// MARK: - PDF Data Transfer Object
struct ReflectionPDFData: Sendable {
    let title: String
    let content: String
    let startDate: Date
    let endDate: Date?
    let type: String
    let label: String
    let author: String?
    let lastEdited: Date
}

struct ProfileSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // Queries
    @Query private var profiles: [UserProfile]
    @Query private var reflections: [Reflection]
    @Query private var completions: [HabitCompletion]
    @Query(sort: \ReflectionNote.startDate, order: .reverse)
    private var reflectionNotes: [ReflectionNote]

    // Local Editing State
    @State private var displayName: String = ""
    @State private var personalMotto: String = ""
    @State private var weekStartsOnSunday: Bool = true

    // Export & Storage State
    @State private var isExportingPDF = false
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @State private var showExportSuccess = false
    @State private var showNoDataAlert = false
    @State private var showMailUnavailable = false
    @State private var showClearDataAlert = false
    
    // Cache State
    @State private var cachedStorageSize: String = "Calculating..."
    @State private var cachedTextSize: String = "..."
    @State private var cachedPhotoSize: String = "..."
    @State private var lastStorageUpdate: Date?
    
    // iCloud State
    @State private var iCloudStatus: String = "Checking..."
    @State private var isICloudAvailable: Bool = false
    @State private var iCloudIcon: String = "icloud"
    @State private var iCloudColor: Color = .secondary

    @ObservedObject private var localization = LocalizationManager.shared
    
    private var profile: UserProfile? { profiles.first }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            ReverieWeaverBackground()

            VStack(spacing: 0) {
                // Custom header with back button
                settingsHeaderSection

                ScrollView {
                    VStack(spacing: 24) {
                        editProfileSection
                        personalSection
                        preferencesSection
                        dataManagementSection
                        storageSection
                        supportSection
                    }
                    .padding(24)
                }
            }

            if isExportingPDF {
                pdfExportOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadProfile() }
        .dismissKeyboardOnBackgroundTap()
        // Alerts
        .alert(localization.localize("profile.dataExported"), isPresented: $showExportSuccess) { Button(localization.localize("profile.ok")) { } } message: { Text(localization.localize("profile.exportSuccess")) }
        .alert("Mail Not Available", isPresented: $showMailUnavailable) { Button(localization.localize("profile.ok")) { } } message: { Text("Please send your feedback to:\nreveriearchive.studio@gmail.com") }
        .alert("No Reflections to Export", isPresented: $showNoDataAlert) { Button("OK") { } } message: { Text("You haven't created any reflection notes this month yet.") }
        .alert("Export Failed", isPresented: $showExportError) { Button("OK") { } } message: { Text(exportErrorMessage) }
        .alert("Clear Old Data?", isPresented: $showClearDataAlert) { Button(localization.localize("habit.cancel"), role: .cancel) { }; Button("Clear", role: .destructive) { clearOldData() } } message: { Text("This will permanently delete reflections and photos older than 1 year.") }
        .task { await recalculateStorage() }
    }
    
    // MARK: - Settings Header (Custom - No Toolbar)
    private var settingsHeaderSection: some View {
        HStack {
            Button {
                ReverieHaptics.lightFeedback()
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.shadowColor.opacity(0.1), radius: 4, y: 2)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                }
            }

            Spacer()

            Text(localization.localize("settings.title"))
                .font(.system(size: 17, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Spacer()

            // Empty spacer to balance the back button
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Sections

    private var editProfileSection: some View {
        VStack(spacing: 12) {
            Text(localization.localize("profile.displayName"))
                .font(.system(size: 13, weight: .regular, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                if displayName.isEmpty {
                    Text(localization.localize("profile.namePlaceholder"))
                        .font(.system(size: 15, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .allowsHitTesting(false)
                }
                TextField("", text: $displayName)
                    .multilingualTextField()
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .tint(Color.sageGreen)
            }
            .padding(11)
            .reverieCardStyle(colorScheme: colorScheme)
            .onChange(of: displayName) { _, _ in saveProfile() }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    private var personalSection: some View {
        VStack(spacing: 16) {
            Text(localization.localize("profile.personalIntention"))
                .font(.system(size: 13, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.terracottaRose)
                        .font(.system(size: 13))
                    Text(localization.localize("profile.intentionPrompt"))
                        .font(.system(size: 13, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }

                ZStack(alignment: .topLeading) {
                    if personalMotto.isEmpty {
                        Text(localization.localize("profile.mottoPlaceholder"))
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $personalMotto, axis: .vertical)
                        .multilingualTextField()
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .tint(Color.sageGreen)
                        .lineLimit(3...5)
                }
                .padding(16)
                .reverieCardStyle(colorScheme: colorScheme)
                .onChange(of: personalMotto) { _, newValue in
                    saveProfile()
                }
            }
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
    
    private var preferencesSection: some View {
        VStack(spacing: 12) {
            Text(localization.localize("profile.preferences"))
                .font(.system(size: 13, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle(isOn: $weekStartsOnSunday) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localize("profile.weekStartSunday"))
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Text(localization.localize("profile.weekStartDesc"))
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)
            .onChange(of: weekStartsOnSunday) { _, newValue in
                saveProfile()
            }

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localize("profile.language"))
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Text(localization.localize("profile.languageDesc"))
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }

                Picker(localization.localize("profile.language"), selection: $localization.currentLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    private var dataManagementSection: some View {
            // 🔒 Toggle this to true only when you have a Paid Developer Account & CloudKit Enabled
            let enableCloudKit = false
            
            return VStack(spacing: 12) {
                Text(localization.localize("profile.dataManagement"))
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 1. Export Button (Always Visible)
                Button {
                    exportData()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            Text(localization.localize("export.reflections"))
                                .font(.system(size: 13, weight: .medium))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                        Text(localization.localize("export.reflectionsDesc"))
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .padding(.leading, 26)
                    }
                    .padding(12)
                    .reverieCardStyle(colorScheme: colorScheme)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                // 2. iCloud Status (Hidden until paid account enabled)
                if enableCloudKit {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: iCloudIcon)
                                .foregroundStyle(iCloudColor)
                                .font(.system(size: 14))
                                .symbolEffect(.pulse, isActive: iCloudStatus == localization.localize("icloud.checking"))

                            Text(localization.localize("profile.icloudBackup"))
                                .font(.system(size: 13, weight: .medium))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                            Spacer()

                            Text(iCloudStatus)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(iCloudColor)
                        }

                        Text(isICloudAvailable ? localization.localize("icloud.syncingDesc") : localization.localize("icloud.notSignedInDesc"))
                            .font(.system(size: 12, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .reverieCardStyle(colorScheme: colorScheme)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onAppear {
                        checkICloudStatus()
                    }
                }
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }
    
    private var storageSection: some View {
        VStack(spacing: 12) {
            Text(localization.localize("storage.title"))
                .font(.system(size: 13, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.localize("storage.dataSize"))
                            .font(.system(size: 13, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text(cachedStorageSize)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.sageGreen)
                            .shadow(color: Color.sageGreen.opacity(0.6), radius: 3, y: 1)
                    }

                    Spacer()

                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.dustyBlue.opacity(0.75))
                }

                Divider()

                VStack(spacing: 6) {
                    StorageRow(icon: "text.alignleft", label: localization.localize("storage.textData"), value: cachedTextSize)
                    StorageRow(icon: "photo", label: localization.localize("storage.photos"), value: cachedPhotoSize)
                    StorageRow(icon: "checkmark.circle", label: localization.localize("storage.completions"), value: "\(completions.count)")
                }
            }
            .padding(13)
            .reverieCardStyle(colorScheme: colorScheme)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                showClearDataAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                    Text(localization.localize("storage.clearOld"))
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .foregroundStyle(Color.red.opacity(0.8))
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Text(localization.localize("storage.clearDesc"))
                .font(.system(size: 12, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    private var supportSection: some View {
        VStack(spacing: 12) {
            Text(localization.localize("profile.support"))
                .font(.system(size: 13, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                requestReview()
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.sageGreen)
                    Text(localization.localize("profile.rateApp"))
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(12)
                .reverieCardStyle(colorScheme: colorScheme)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Button {
                sendFeedback()
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dustyBlue)
                    Text(localization.localize("profile.sendFeedback"))
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(12)
                .reverieCardStyle(colorScheme: colorScheme)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            HStack {
                Text(localization.localize("profile.version"))
                    .font(.system(size: 13, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                Spacer()
                Text(appVersion)
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    private var pdfExportOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Weaving your story...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 10)
        }
        .zIndex(100)
        .transition(.opacity)
    }

    // MARK: - Logic Implementation

    private func loadProfile() {
        if let existingProfile = profile {
            displayName = existingProfile.displayName
            personalMotto = existingProfile.personalMotto
            weekStartsOnSunday = existingProfile.weekStartsOnSunday
        } else {
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save new profile: \(error)")
            }
            displayName = newProfile.displayName
            personalMotto = newProfile.personalMotto
            weekStartsOnSunday = newProfile.weekStartsOnSunday
        }
    }

    private func saveProfile() {
        // 1. Try to use the Query result first
        if let existingProfile = profile {
            existingProfile.displayName = displayName
            existingProfile.personalMotto = personalMotto
            existingProfile.weekStartsOnSunday = weekStartsOnSunday
        }
        // 2. Fallback: If Query hasn't updated, try to fetch explicitly to avoid duplicates
        else {
            let descriptor = FetchDescriptor<UserProfile>()
            if let fetchedProfile = try? modelContext.fetch(descriptor).first {
                fetchedProfile.displayName = displayName
                fetchedProfile.personalMotto = personalMotto
                fetchedProfile.weekStartsOnSunday = weekStartsOnSunday
            } else {
                // 3. Truly no profile exists, create new
                let newProfile = UserProfile(
                    displayName: displayName,
                    personalMotto: personalMotto,
                    weekStartsOnSunday: weekStartsOnSunday
                )
                modelContext.insert(newProfile)
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
    
    // MARK: - iCloud Logic
    private func checkICloudStatus() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self.iCloudStatus = self.localization.localize("icloud.active")
                    self.isICloudAvailable = true
                    self.iCloudIcon = "icloud.fill"
                    self.iCloudColor = .sageGreen
                case .noAccount:
                    self.iCloudStatus = self.localization.localize("icloud.notSignedIn")
                    self.isICloudAvailable = false
                    self.iCloudIcon = "icloud.slash"
                    self.iCloudColor = .terracottaRose
                case .restricted:
                    self.iCloudStatus = self.localization.localize("icloud.restricted")
                    self.isICloudAvailable = false
                    self.iCloudIcon = "lock.icloud"
                    self.iCloudColor = .terracottaRose
                case .couldNotDetermine:
                    self.iCloudStatus = self.localization.localize("icloud.error")
                    self.isICloudAvailable = false
                    self.iCloudIcon = "exclamationmark.icloud"
                    self.iCloudColor = .gray
                case .temporarilyUnavailable:
                    self.iCloudStatus = self.localization.localize("icloud.offline")
                    self.isICloudAvailable = false
                    self.iCloudIcon = "icloud.slash"
                    self.iCloudColor = .gray
                @unknown default:
                    self.iCloudStatus = self.localization.localize("icloud.unknown")
                    self.isICloudAvailable = false
                    self.iCloudIcon = "questionmark.icloud"
                    self.iCloudColor = .gray
                }
            }
        }
    }
    
    // MARK: - Export Logic
    private func exportData() {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date())),
              let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else {
            exportErrorMessage = "Failed to calculate date range"
            showExportError = true
            return
        }
        
        let weekly = reflectionNotes.filter { $0.type.lowercased() == "weekly" && $0.startDate >= monthStart && $0.startDate < monthEnd }
        let monthly = reflectionNotes.first { $0.type.lowercased() == "monthly" && $0.startDate >= monthStart && $0.startDate < monthEnd }
        
        guard !weekly.isEmpty || monthly != nil else {
            print("ℹ️ No ReflectionNotes found for this month.")
            showNoDataAlert = true
            ReverieHaptics.lightFeedback()
            return
        }
        
        exportReflectionNewspaper(for: Date())
    }
    
    private func exportReflectionNewspaper(for month: Date = Date()) {
        isExportingPDF = true
        
        // 1. Prepare Data on Main Actor (SwiftData Safe)
        // Convert SwiftData objects to Sendable structs (DTOs)
        let dataToExport = reflectionNotes.map { note in
            ReflectionPDFData(
                title: note.title,
                content: note.content,
                startDate: note.startDate,
                endDate: note.endDate,
                type: note.type,
                label: note.label,
                author: note.author,
                lastEdited: note.lastEdited
            )
        }
        
        Task {
            do {
                // 2. Pass structs to background thread
                let pdfURL = try await generatePDFInBackground(notes: dataToExport, month: month)
                
                // 3. Update UI on Main Actor
                await MainActor.run {
                    ReverieHaptics.successFeedback()
                    presentShareSheet(for: pdfURL)
                    isExportingPDF = false
                }
            } catch {
                await MainActor.run {
                    print("❌ PDF export failed: \(error)")
                    exportErrorMessage = "Failed to create PDF: \(error.localizedDescription)"
                    showExportError = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    isExportingPDF = false
                }
            }
        }
    }
    
    // MARK: - PDF ENGINE
    private func generatePDFInBackground(notes: [ReflectionPDFData], month: Date) async throws -> URL {
        return try await Task.detached(priority: .userInitiated) {
            // Month bounds
            let cal = Calendar.current
            guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month)),
                  let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else {
                throw NSError(domain: "ProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate month bounds"])
            }

            // Filter data using the structs
            let weekly = notes
                .filter { $0.type.lowercased() == "weekly" && $0.startDate >= monthStart && $0.startDate < monthEnd }
                .sorted { $0.startDate < $1.startDate }
            let monthly = notes
                .first { $0.type.lowercased() == "monthly" && $0.startDate >= monthStart && $0.startDate < monthEnd }

            guard !weekly.isEmpty || monthly != nil else {
                throw NSError(domain: "ProfileView", code: 2, userInfo: [NSLocalizedDescriptionKey: "No reflection notes found"])
            }

            // PDF Context Setup
            let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
            let margin: CGFloat = 40
            let contentRect = pageRect.insetBy(dx: margin, dy: margin)

            let headerFont = UIFont(name: "Georgia-Bold", size: 24) ?? .boldSystemFont(ofSize: 24)
            let sectionTitleFont = UIFont(name: "Georgia-Bold", size: 16) ?? .boldSystemFont(ofSize: 16)
            let metaFont = UIFont(name: "Georgia-Italic", size: 12) ?? .italicSystemFont(ofSize: 11)
            let bodyFont = UIFont(name: "Georgia", size: 13) ?? .systemFont(ofSize: 12)
            let monthNameFmt = DateFormatter(); monthNameFmt.dateFormat = "MMMM yyyy"
            let dayFmt = DateFormatter(); dayFmt.dateFormat = "MMM d"
            let stampFmt = DateFormatter(); stampFmt.dateFormat = "yyyy-MM-dd HH:mm"

            let pdfName = "Reverie_\(monthNameFmt.string(from: monthStart))_Reflections.pdf"
            let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent(pdfName)

            func drawLine(_ ctx: CGContext, x1: CGFloat, y: CGFloat, x2: CGFloat) {
                ctx.saveGState()
                ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.12).cgColor)
                ctx.setLineWidth(0.5)
                ctx.move(to: CGPoint(x: x1, y: y))
                ctx.addLine(to: CGPoint(x: x2, y: y))
                ctx.strokePath()
                ctx.restoreGState()
            }

            func drawText(_ text: String, at rect: CGRect, font: UIFont, color: UIColor = .black) -> CGFloat {
                let style = NSMutableParagraphStyle(); style.lineSpacing = 2; style.alignment = .left
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
                let attributed = NSAttributedString(string: text, attributes: attrs)
                let framesetter = CTFramesetterCreateWithAttributedString(attributed)
                let path = CGMutablePath(); path.addRect(rect)
                let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
                let context = UIGraphicsGetCurrentContext()!

                context.saveGState()
                context.textMatrix = .identity
                context.translateBy(x: 0, y: rect.origin.y * 2 + rect.height)
                context.scaleBy(x: 1.0, y: -1.0)
                CTFrameDraw(frame, context)
                context.restoreGState()

                let suggested = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, rect.size, nil)
                return min(suggested.height, rect.height)
            }

            func heightFor(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
                let style = NSMutableParagraphStyle(); style.lineSpacing = 2
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: style]
                let bounding = (text as NSString).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs, context: nil
                )
                return ceil(bounding.height)
            }

            func beginPage(_ renderer: UIGraphicsPDFRendererContext) -> CGFloat {
                renderer.beginPage()
                let ctx = UIGraphicsGetCurrentContext()!
                let brand = "Reverie Archive — Reflection Notes"
                let brandRect = CGRect(x: contentRect.minX, y: contentRect.minY - 4, width: contentRect.width, height: 16)
                _ = drawText(brand, at: brandRect, font: metaFont, color: UIColor(white: 0.1, alpha: 1))
                
                let title = monthNameFmt.string(from: monthStart)
                let titleRect = CGRect(x: contentRect.minX, y: brandRect.maxY + 8, width: contentRect.width, height: 28)
                _ = drawText(title, at: titleRect, font: headerFont)
                
                drawLine(ctx, x1: contentRect.minX, y: titleRect.maxY + 8, x2: contentRect.maxX)
                return titleRect.maxY + 16
            }

            func drawFooter(pageIndex: Int) {
                let footerY = pageRect.maxY - margin + 12
                let rect = CGRect(x: contentRect.minX, y: footerY, width: contentRect.width, height: 12)
                _ = drawText("Page \(pageIndex)", at: rect, font: metaFont, color: .darkGray)
            }

            var sections: [ReflectionPDFData] = weekly
            if let m = monthly { sections.append(m) }

            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
            
            try renderer.writePDF(to: pdfURL) { ctx in
                var pageIndex = 1
                var cursorY = beginPage(ctx)

                for (idx, note) in sections.enumerated() {
                    let headerLabel = note.type.lowercased() == "weekly" ? (note.label.isEmpty ? "Weekly" : note.label) : (note.label.isEmpty ? "Monthly" : note.label)
                    let dateSpan: String = {
                        let s = dayFmt.string(from: note.startDate)
                        if let e = note.endDate { return "\(s) – \(dayFmt.string(from: e))" }
                        return s
                    }()
                    let sectionTitle = note.title.isEmpty ? "Untitled" : note.title
                    let sectionHeader = "\(headerLabel)  ·  \(dateSpan)"
                    let metaLine = (note.author?.isEmpty == false ? "By \(note.author!) • Last edited \(stampFmt.string(from: note.lastEdited))" : "Last edited \(stampFmt.string(from: note.lastEdited))")

                    let titleH = heightFor(sectionTitle, width: contentRect.width, font: sectionTitleFont)
                    let metaH = heightFor(metaLine, width: contentRect.width, font: metaFont)
                    let bodyH = heightFor(note.content, width: contentRect.width, font: bodyFont)
                    let needed = 6 + titleH + 6 + metaH + 8 + bodyH + 18

                    if cursorY + needed > contentRect.maxY {
                        drawFooter(pageIndex: pageIndex)
                        pageIndex += 1
                        cursorY = beginPage(ctx)
                    }

                    let shRect = CGRect(x: contentRect.minX, y: cursorY, width: contentRect.width, height: 13)
                    _ = drawText(sectionHeader, at: shRect, font: metaFont, color: .darkGray)
                    cursorY = shRect.maxY + 6

                    let tRect = CGRect(x: contentRect.minX, y: cursorY, width: contentRect.width, height: titleH)
                    _ = drawText(sectionTitle, at: tRect, font: sectionTitleFont)
                    cursorY = tRect.maxY + 6

                    let mRect = CGRect(x: contentRect.minX, y: cursorY, width: contentRect.width, height: metaH)
                    _ = drawText(metaLine, at: mRect, font: metaFont, color: .darkGray)
                    cursorY = mRect.maxY + 8

                    var remaining = note.content
                    while !remaining.isEmpty {
                        let spaceLeft = contentRect.maxY - cursorY
                        if spaceLeft < 40 {
                            drawFooter(pageIndex: pageIndex)
                            pageIndex += 1
                            cursorY = beginPage(ctx)
                        }
                        let maxRect = CGRect(x: contentRect.minX, y: cursorY, width: contentRect.width, height: contentRect.maxY - cursorY)
                        let style = NSMutableParagraphStyle(); style.lineSpacing = 2
                        let attrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .paragraphStyle: style]
                        
                        var low = 0, high = remaining.count, fit = 0
                        while low <= high {
                            let mid = (low + high) / 2
                            let test = String(remaining.prefix(mid))
                            let h = (test as NSString).boundingRect(with: CGSize(width: maxRect.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil).height
                            if h <= maxRect.height { fit = mid; low = mid + 1 } else { high = mid - 1 }
                        }

                        // Safety: Ensure we make progress to avoid infinite loop
                        if fit == 0 {
                            fit = min(1, remaining.count)
                        }

                        let chunk = String(remaining.prefix(fit))
                        _ = drawText(chunk, at: maxRect, font: bodyFont)
                        cursorY = maxRect.origin.y + heightFor(chunk, width: maxRect.width, font: bodyFont)
                        remaining.removeFirst(fit)

                        if !remaining.isEmpty {
                            drawFooter(pageIndex: pageIndex)
                            pageIndex += 1
                            cursorY = beginPage(ctx)
                        }
                    }

                    let lineY = cursorY + 8
                    drawLine(ctx.cgContext, x1: contentRect.minX, y: lineY, x2: contentRect.maxX)
                    cursorY = lineY + 10
                    if idx < sections.count - 1 { cursorY += 2 }
                }
                drawFooter(pageIndex: pageIndex)
            }
            
            return pdfURL
        }.value
    }
    
    // In ProfileSettingsView
        private func presentShareSheet(for pdfURL: URL) {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first,
                  let root = window.rootViewController else { return }
            
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = root.view
                popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            root.present(activityVC, animated: true)
        }

    // MARK: - Storage Logic
    @MainActor
    private func recalculateStorage() async {
        if let lastUpdate = lastStorageUpdate, Date().timeIntervalSince(lastUpdate) < 300 { return }
        let completionsCount = completions.count
        let reflectionsData = reflections
        
        let (storage, text, photo) = await Task.detached(priority: .utility) {
            let textBytes = completionsCount * 200 + reflectionsData.count * 500
            let photoBytes = reflectionsData.reduce(0) { totalBytes, reflection in
                let reflectionPhotoBytes = reflection.photosData.reduce(0) { $0 + $1.count }
                return totalBytes + reflectionPhotoBytes
            }
            let totalBytes = textBytes + photoBytes
            let totalMB = Double(totalBytes) / 1_024_000
            let storageSize = totalMB < 1 ? String(format: "%.1f KB", Double(totalBytes) / 1024) : String(format: "%.1f MB", totalMB)
            let textSize = String(format: "%.1f KB", Double(textBytes) / 1024)
            let photoSize = photoBytes < 1_024_000 ? String(format: "%.1f KB", Double(photoBytes) / 1024) : String(format: "%.1f MB", Double(photoBytes) / 1_024_000)
            return (storageSize, textSize, photoSize)
        }.value
        
        cachedStorageSize = storage
        cachedTextSize = text
        cachedPhotoSize = photo
        lastStorageUpdate = Date()
    }

    private func clearOldData() {
        guard let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) else { return }
        let oldReflections = reflections.filter { $0.createdAt < oneYearAgo }
        let oldCompletions = completions.filter { $0.completedAt < oneYearAgo }
        
        for reflection in oldReflections { modelContext.delete(reflection) }
        for completion in oldCompletions { modelContext.delete(completion) }
        
        do {
            try modelContext.save()
            ReverieHaptics.successFeedback()
            Task { await recalculateStorage() }
        } catch {
            print("Failed to clear old data: \(error)")
            exportErrorMessage = "Failed to clear data"
            showExportError = true
        }
    }
    
    // MARK: - Support Logic
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func sendFeedback() {
        let email = "reveriearchive.studio@gmail.com"
        let subject = "ReverieWeaver Feedback"
        let body = """
        
        
        ---
        App Version: \(appVersion)
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        """

        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showMailUnavailable = true
            }
        } else {
            showMailUnavailable = true
        }
    }
}

// MARK: - Helpers

struct StorageRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
    }
}
