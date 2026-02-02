//
//  VitalityDetailView.swift
//  Reverie Weaver
//
//   Aligned with ThemeWeekDetailView pattern
//  - Added proper error handling with user feedback
//  - Added success animation with Task management
//  - Added delete journey functionality
//  - Fixed habit creation with proper programTag
//  - Added robust progress fetching
//

import SwiftUI
import SwiftData

struct VitalityDetailView: View {
    
    // MARK: - Properties
    let program: VitalityProgram
    let previewPhase: VitalityPhase
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allProgressRecords: [VitalityProgress]
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @Query private var reflections: [DailyReflection]
    
    // MARK: - Initialization
    init(program: VitalityProgram, previewPhase: VitalityPhase = .activation, initialWeek: Int = 1) {
        self.program = program
        self.previewPhase = previewPhase
        
        _selectedPreviewWeek = State(initialValue: initialWeek)
        _selectedActiveWeek = State(initialValue: initialWeek)
        
        #if DEBUG
        print("🌿 [VitalityDetailView] init → program.id=\(program.id), isFei=\(program.isFeiProgram), previewPhase=\(previewPhase.displayName), initialWeek=\(initialWeek)")
        #endif
    }
    
    private var habitTag: String {
        "VA-\(program.id)"
    }
    
    private var progress: VitalityProgress? {
        if let local = localProgressOverride {
            return local
        }
        
        let matching = allProgressRecords.filter {
            $0.programTag == habitTag && !$0.isCompleted
        }
        
        if let found = matching.first {
            return found
        }
        
        let descriptor = FetchDescriptor<VitalityProgress>(
            predicate: #Predicate { $0.programTag == habitTag && !$0.isCompleted }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    private var vitalityHabit: Habit? {
        let habitTag = "VA-\(program.id)"
        let habit = habits.first { $0.programTag == habitTag && !$0.isArchived }
        
        #if DEBUG
        if habit == nil {
            print("⚠️ [Vitality] No habit found for tag: \(habitTag)")
        }
        #endif
        
        return habit
    }
    
    // Track when journey was just started (to handle SwiftData query delay)
    @State private var justStartedJourney = false

    private var isAddedToDesk: Bool {
        justStartedJourney || vitalityHabit != nil
    }
    
    private var isFeiProgram: Bool {
        program.isFeiProgram
    }
    
    // MARK: - View State
    @State private var selectedPhase: VitalityPhase = .activation
    @State private var selectedDay: VitalityDay?
    @State private var previewTier: CompletionTier = .sprout
    
    @State private var selectedPreviewWeek: Int = 1
    @State private var selectedActiveWeek: Int = 1
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var showSuccessMessage = false
    @State private var selectedTier: CompletionTier = .sprout
    @State private var successAnimationTask: Task<Void, Never>?
    
    @State private var showDeleteConfirmation = false
    
    @State private var showInfoSheet = false
    
    @State private var showCycleExtensionPrompt = false
    
    @State private var showRPELogger = false
    @State private var pendingRPEDay: Int? = nil
    @State private var selectedRPE: Int = 6
    
    @State private var refreshID = UUID()
    @State private var localProgressOverride: VitalityProgress?

    // Track if progress was updated during session (to notify DeskView on dismiss)
    @State private var needsNotifyDeskViewOnDismiss = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        if isAddedToDesk {
                            // MARK: TRACKER MODE (Active)
                            trackerHeader
                            vitalityScoreCard
                            vitalityProgressBar

                        if let p = progress {
                            // Use rest-day-aware current day calculation
                            let currentDay = p.currentScheduledDay(reflections: reflections)
                            
                            if p.isDayComplete(currentDay) {
                                rpeQuickAccessButton(for: currentDay)
                        }
                            else if currentDay > 1 && p.isDayComplete(currentDay - 1) {
                                rpeQuickAccessButton(for: currentDay - 1)
                            }
                        }
                            
                            if let p = progress, p.daysCompleted >= 7 {
                                tierProgressionCard
                            }
                            
                            if let p = progress, p.completionRecords.contains(where: { $0.actualRPE != nil }) {
                                rpeStatsCard
                            }
                            
                            if isFeiProgram {
                                activeWeekSelector
                            } else {
                                phaseTabs
                            }
                            
                            trackerTierSelector
                            
                            timelineView
                        } else {
                            previewHeader
                            
                            if isFeiProgram {
                                previewWeekSelector
                            }
                            
                            previewTierSelector
                            singlePhaseSyllabusView
                        }
                    }
                    .padding(.bottom, 120)
                    .padding(.top, 60)
                }
                
                HStack {
                    if isAddedToDesk {
                        menuButton
                    }
                    Spacer()
                    closeButton
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if !isAddedToDesk {
                    VStack {
                        Spacer()
                        startJourneyButton
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .center) {
                if showSuccessMessage {
                    successOverlay
                }
            }
            .sheet(item: $selectedDay) { day in
                TierSelectionSheet(
                    themeWeekHabit: convertToThemeHabit(day),
                    dayNumber: day.dayNumber,
                    themeName: cleanTitle(day.title),
                    isVitalityProgram: true,
                    onSelectTier: { tier in
                        completeDay(day, tier: tier)
                    }
                )
                .presentationDetents([.height(520)])
            }
            .alert("Delete Journey?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteJourney()
                }
            } message: {
                Text("This will remove your current progress and the habit from your Desk.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showInfoSheet) {
                programInfoSheet
            }
            .sheet(isPresented: $showCycleExtensionPrompt) {
                cycleExtensionSheet
            }
            .sheet(isPresented: $showRPELogger) {
                rpeLoggerSheet
                    .onAppear {
                        // Pre-populate with existing RPE value when updating
                        if let dayNum = pendingRPEDay,
                           let existingRPE = progress?.completionRecord(for: dayNum)?.actualRPE {
                            selectedRPE = existingRPE
                        } else {
                            selectedRPE = 6 // Default to moderate effort
                        }
                    }
            }
            .onAppear {
                initializeView()
            }
            .onChange(of: habits) { _, _ in
                // Skip re-initialization if we just started the journey (prevents view flickering)
                guard !justStartedJourney else {
                    #if DEBUG
                    print("🌿 [Vitality] Skipping initializeView - justStartedJourney is true")
                    #endif
                    return
                }
                initializeView()
            }
            .onDisappear {
                successAnimationTask?.cancel()

                // Notify DeskView to refresh only when the detail view is dismissed
                // This prevents the cascading dismiss issue when logging completions
                if needsNotifyDeskViewOnDismiss {
                    NotificationCenter.default.post(name: .vitalityProgressUpdated, object: nil)
                    #if DEBUG
                    print("🌿 [Vitality] Posted deferred vitalityProgressUpdated notification on dismiss")
                    #endif
                }

                #if DEBUG
                print("🌿 [Vitality] View dismissed - animation task cancelled")
                #endif
            }
            // Prevent accidental dismissal during the transition to tracker mode
            .interactiveDismissDisabled(justStartedJourney)
        }
    }
    
    // Setup initial state based on progress
    func initializeView() {
        let queryProgress = allProgressRecords.first(where: { p in
            p.programTag == habitTag && !p.isCompleted
        })
        
        let computedProgress = progress
        
        var manualProgress: VitalityProgress?
        let descriptor = FetchDescriptor<VitalityProgress>(
            predicate: #Predicate { $0.programTag == habitTag && !$0.isCompleted }
        )
        manualProgress = try? modelContext.fetch(descriptor).first
        
        let activeProgress = queryProgress ?? computedProgress ?? manualProgress
        
        #if DEBUG
        print("🔍 [Vitality] Progress search: query=\(queryProgress != nil), computed=\(computedProgress != nil), manual=\(manualProgress != nil)")
        if let p = activeProgress {
            print("✅ [Vitality] Found progress: \(p.daysCompleted)/\(p.totalProgramDays), score=\(p.vitalityScore)")
        }
        #endif
        
        if activeProgress == nil, let habit = vitalityHabit {
            #if DEBUG
            print("⚠️ [Vitality] Orphaned habit '\(habit.name)' detected after triple-check - repairing...")
            #endif
            
            let recoveredProgress = VitalityProgress(
                programID: program.id,
                programTag: habitTag,
                programTitle: program.title
            )
            recoveredProgress.startDate = habit.createdAt
            modelContext.insert(recoveredProgress)
            
            do {
                try modelContext.save()
                localProgressOverride = recoveredProgress
                refreshID = UUID()
                
                #if DEBUG
                print("✅ [Vitality] Auto-repair complete: \(recoveredProgress.totalProgramDays) days")
                #endif
            } catch {
                #if DEBUG
                print("❌ [Vitality] Auto-repair failed: \(error)")
                #endif
            }
        } else if let p = activeProgress {
            if isFeiProgram {
                selectedActiveWeek = p.displayWeek
                
                #if DEBUG
                if p.currentCycle == 2 {
                    print("📊 [Vitality] Cycle 2 active - Week \(p.displayWeek), Day \(p.currentDayNumber)")
                }
                #endif
                
                checkForCycleExtensionPrompt()
            } else {
                // Use rest-day-aware current day for phase selection
                let currentDay = p.currentScheduledDay(reflections: reflections)
                selectedPhase = program.phase(for: currentDay)
            }
        } else {
            if !isFeiProgram {
                selectedPhase = previewPhase
            }
        }
    }
    
    private func checkForCycleExtensionPrompt() {
        guard let p = progress else { return }
        
        if p.canExtendToNextCycle {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showCycleExtensionPrompt = true
            }
            
            #if DEBUG
            print("🌿 [Vitality] Triggering cycle extension prompt → daysCompleted=\(p.daysCompleted)")
            #endif
        }
    }
}

// MARK: - Success Overlay
private extension VitalityDetailView {
    
    var successOverlay: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.sageGreen)
                
                Text("Day Complete!")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.serif)
                
                HStack(spacing: 5) {
                    Image(systemName: selectedTier.sfSymbol)
                        .font(.system(size: 13))
                        .foregroundStyle(tierColor(for: selectedTier))
                    Text("\(selectedTier.displayName) Achieved")
                        .font(.system(size: 13, weight: .regular))
                }
                .foregroundStyle(.secondary)
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text("Track effort after workout?")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    // Get the most recently completed day from completion records
                    if let lastCompletedDay = progress?.lastCompletedDayNumber {
                        pendingRPEDay = lastCompletedDay
                        showSuccessMessage = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showRPELogger = true
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                        Text("Record Your Effort (RPE)")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color.dustyBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.dustyBlue.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.dustyBlue.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor.opacity(0.15), radius: 16)
        .transition(.scale.combined(with: .opacity))
    }
    
    func tierColor(for tier: CompletionTier) -> Color {
        switch tier {
        case .seed:   return Color(hex: "B8D4C8")
        case .sprout: return Color(hex: "9BB5CE")
        case .bloom:  return Color(hex: "D4B896")
        }
    }
}

// MARK: - Floating Buttons
private extension VitalityDetailView {
    
    var menuButton: some View {
        Menu {
            Button {
                showInfoSheet = true
            } label: {
                Label("Program Guide", systemImage: "info.circle")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Journey", systemImage: "trash")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.7), location: 0.1),
                                .init(color: .white.opacity(0.1), location: 0.5),
                                .init(color: .white.opacity(0.3), location: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .shadow(color: .white.opacity(0.3), radius: 1, x: -1, y: -1)

                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: 36, height: 36)
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
        }
    }
    
    var closeButton: some View {
        GlassCloseButton {
            dismiss()
        }
    }
}

// MARK: - Program Info Sheet
private extension VitalityDetailView {
    
    var programInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isFeiProgram {
                        feiInfoContent
                    } else {
                        vitalityPhaseInfoContent
                    }
                    
                    tierLegendSection
                }
                .padding(20)
            }
            .background(ReverieWeaverBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showInfoSheet = false }
                        .font(.system(size: 14, weight: .regular))
                }
            }
            .navigationTitle("Program Guide")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
    
    var vitalityPhaseInfoContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(VitalityPhase.allCases, id: \.self) { phase in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle()
                            .fill(Color(hex: phase.colorHex))
                            .frame(width: 10, height: 10)
                        Text(phase.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    
                    Text(phase.weeksRangeLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    Text(phase.overview)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.primary.opacity(0.85))
                        .lineSpacing(2)
                }
                .padding(14)
                .reverieCardStyle(colorScheme: colorScheme)
            }
        }
    }
    
    var feiInfoContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("4-Week Strength Block")
                .font(.system(size: 14, weight: .semibold))
                .fontDesign(.serif)
            
            Text(program.description)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
            
            VStack(alignment: .leading, spacing: 10) {
                infoRow(week: 1, title: "Foundation", desc: "Build movement patterns")
                infoRow(week: 2, title: "Volume", desc: "Increase work capacity")
                infoRow(week: 3, title: "Intensity", desc: "Progressive overload")
                infoRow(week: 4, title: "Deload", desc: "Recovery & supercompensation")
            }
            .padding(14)
            .reverieCardStyle(colorScheme: colorScheme)
        }
    }
    
    func infoRow(week: Int, title: String, desc: String) -> some View {
        HStack(spacing: 10) {
            Text("W\(week)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color(hex: "9BB5CE"))
                .cornerRadius(5)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                Text(desc)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    var tierLegendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMPLETION TIERS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                tierLegendRow(icon: "leaf.fill", color: "B8D4C8", title: "Seed", desc: "Low energy rescue · RPE 1-4")
                tierLegendRow(icon: "leaf.circle.fill", color: "9BB5CE", title: "Sprout", desc: "Standard workout · RPE 5-7")
                tierLegendRow(icon: "sparkles", color: "D4B896", title: "Bloom", desc: "High energy push · RPE 7-9")
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)
        }
    }
    
    func tierLegendRow(icon: String, color: String, title: String, desc: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: color))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                Text(desc)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Tier Progression Card (Feature #3)

private extension VitalityDetailView {
    
    var tierProgressionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GROWTH PATH")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if progress?.isShowingTierProgression == true {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11))
                        Text("Progressing!")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.sageGreen)
                }
            }
            
            HStack(spacing: 8) {
                let totalWeeks = isFeiProgram ? (progress?.currentCycle == 2 ? 8 : 4) : 8
                ForEach(1...totalWeeks, id: \.self) { week in
                    weekTierBadge(week: week)
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                tierLegendItem(icon: "leaf.fill", color: "B8D4C8", label: "Seed")
                tierLegendItem(icon: "leaf.circle.fill", color: "9BB5CE", label: "Sprout")
                tierLegendItem(icon: "sparkles", color: "D4B896", label: "Bloom")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
    }
    
    func weekTierBadge(week: Int) -> some View {
        let dominantTier = progress?.dominantTier(forWeek: week)
        let countsTuple = progress?.tierCounts(forWeek: week) ?? (0, 0, 0)
        let (seedCount, sproutCount, bloomCount) = countsTuple
        let hasData = seedCount + sproutCount + bloomCount > 0
        
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(hasData ? tierBackgroundColor(dominantTier) : Color.adaptiveSectionBackground(colorScheme: colorScheme))
                    .frame(width: 28, height: 28)
                
                if hasData, let tier = dominantTier {
                    Image(systemName: tier.sfSymbol)
                        .font(.system(size: 12))
                        .foregroundStyle(tierIconColor(tier))
                } else {
                    Text("W\(week)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Text("W\(week)")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }
    
    func tierLegendItem(icon: String, color: String, label: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: color))
            Text(label)
        }
    }
    
    func tierBackgroundColor(_ tier: CompletionTier?) -> Color {
        guard let tier = tier else { return Color.adaptiveSectionBackground(colorScheme: colorScheme) }
        switch tier {
        case .seed: return Color(hex: "B8D4C8").opacity(0.2)
        case .sprout: return Color(hex: "9BB5CE").opacity(0.2)
        case .bloom: return Color(hex: "D4B896").opacity(0.2)
        }
    }
    
    func tierIconColor(_ tier: CompletionTier) -> Color {
        switch tier {
        case .seed: return Color(hex: "B8D4C8")
        case .sprout: return Color(hex: "9BB5CE")
        case .bloom: return Color(hex: "D4B896")
        }
    }
}

// MARK: -   RPE Stats Card (Feature #4)
private extension VitalityDetailView {
    
    var rpeStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EFFORT TRACKING")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let trend = progress?.rpeTrend {
                    HStack(spacing: 4) {
                        Image(systemName: trend > 0 ? "arrow.up.right" : (trend < 0 ? "arrow.down.right" : "arrow.right"))
                            .font(.system(size: 11))
                        Text(trend > 0 ? "Building" : (trend < 0 ? "Recovering" : "Steady"))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(trend > 0 ? Color(hex: "D4B896") : (trend < 0 ? Color(hex: "B8D4C8") : Color(hex: "9BB5CE")))
                }
            }
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Avg RPE")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    if let avg = progress?.averageRPE {
                        Text(String(format: "%.1f", avg))
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundStyle(rpeColor(avg))
                    } else {
                        Text("-")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider().frame(height: 32)
                
                VStack(spacing: 4) {
                    Text("Logged")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    let logCount = progress?.completionRecords.filter { $0.actualRPE != nil }.count ?? 0
                    Text("\(logCount)")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.dustyBlue)
                }
                .frame(maxWidth: .infinity)
                
                Divider().frame(height: 32)
                
                VStack(spacing: 4) {
                    Text("This Week")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    if let weekAvg = progress?.averageRPE(forWeek: progress?.currentWeek ?? 1) {
                        Text(String(format: "%.1f", weekAvg))
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundStyle(rpeColor(weekAvg))
                    } else {
                        Text("-")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            HStack(spacing: 4) {
                Text("Scale:")
                    .foregroundStyle(.tertiary)
                Text("1-4 Easy")
                    .foregroundStyle(Color(hex: "B8D4C8"))
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("5-6 Moderate")
                    .foregroundStyle(Color(hex: "9BB5CE"))
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("7-9 Hard")
                    .foregroundStyle(Color(hex: "D4B896"))
            }
            .font(.system(size: 11, weight: .regular))
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
    }
    
    func rpeColor(_ rpe: Double) -> Color {
        if rpe < 5 { return Color(hex: "B8D4C8") }
        else if rpe < 7 { return Color(hex: "9BB5CE") }
        else { return Color(hex: "D4B896") }
    }
}

// MARK: -   Cycle Extension Sheet (Feature #1)
private extension VitalityDetailView {
    
    var cycleExtensionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Celebration
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: "D4B896"))
                    
                    Text("Week 4 Complete!")
                        .font(.system(size: 20, weight: .semibold))
                        .fontDesign(.serif)
                    
                    Text("You've finished the foundation block. Your body is adapted and ready for more.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                if let p = progress {
                    HStack(spacing: 24) {
                        statItem(value: "\(p.daysCompleted)", label: "Days")
                        statItem(value: "\(p.vitalityScore)", label: "Score")
                        if let avg = p.averageRPE {
                            statItem(value: String(format: "%.1f", avg), label: "Avg RPE")
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Ready to Level Up?")
                        .font(.system(size: 14, weight: .semibold))
                        .fontDesign(.serif)
                    
                    Text("Continue to Weeks 5-8 with progressive overload. Same structure, higher intensity. Add resistance bands or heavier weights.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Button {
                        progress?.extendToNextCycle()
                        try? modelContext.save()

                        // 🔧 FIX: Defer notification to onDisappear to prevent cascading dismissal
                        needsNotifyDeskViewOnDismiss = true

                        localProgressOverride = progress
                        refreshID = UUID()
                        selectedActiveWeek = 5

                        showCycleExtensionPrompt = false
                        ReverieHaptics.successFeedback()

                        #if DEBUG
                        print("🌿 [Vitality] Extended to cycle 2 → now showing week 5")
                        #endif
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 14))
                            Text("Continue to Week 5-8")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "9BB5CE"), Color(hex: "7A9BB8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                   
                    Button {
                        progress?.declineExtension()
                        try? modelContext.save()

                        // 🔧 FIX: Defer notification to onDisappear (dismiss() will trigger it)
                        needsNotifyDeskViewOnDismiss = true

                        showCycleExtensionPrompt = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }

                        #if DEBUG
                        print("🌿 [Vitality] Journey completed, user declined extension")
                        #endif
                    } label: {
                        Text("Complete Journey")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .background(ReverieWeaverBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCycleExtensionPrompt = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }
    
    func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "9BB5CE"))
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: -   RPE Logger Sheet
private extension VitalityDetailView {
    
    var rpeLoggerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 8) {
                    // Dynamic title based on whether RPE exists for pending day
                    let hasExistingRPE = pendingRPEDay != nil && progress?.completionRecord(for: pendingRPEDay!)?.actualRPE != nil
                    
                    Text(hasExistingRPE ? "Update Your Effort" : "How Hard Was That?")
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(.serif)
                    
                    if let dayNum = pendingRPEDay, hasExistingRPE,
                       let existingRPE = progress?.completionRecord(for: dayNum)?.actualRPE {
                        Text("Day \(dayNum) · Current RPE: \(existingRPE)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Rate your perceived exertion (RPE)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(spacing: 16) {
                    Text("\(selectedRPE)")
                        .font(.system(size: 48, weight: .semibold, design: .serif))
                        .foregroundStyle(rpeColor(Double(selectedRPE)))
                    
                    Text(rpeDescription(selectedRPE))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(1...10, id: \.self) { value in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedRPE = value
                                }
                            } label: {
                                Circle()
                                    .fill(selectedRPE == value ? rpeColor(Double(value)) : Color.adaptiveSectionBackground(colorScheme: colorScheme))
                                    .frame(width: selectedRPE == value ? 32 : 24, height: selectedRPE == value ? 32 : 24)
                                    .overlay(
                                        Group {
                                            if selectedRPE == value {
                                                Text("\(value)")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            } else {
                                                Text("\(value)")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        if let day = pendingRPEDay {
                            #if DEBUG
                            print("🎯 [VitalityDetailView] Recording RPE \(selectedRPE) for day \(day)")
                            #endif
                            progress?.updateRPE(forDay: day, rpe: selectedRPE)
                            try? modelContext.save()

                            // 🔧 FIX: Defer notification to onDisappear to prevent cascading dismissal
                            needsNotifyDeskViewOnDismiss = true
                        }
                        showRPELogger = false
                        pendingRPEDay = nil
                    } label: {
                        let hasExistingRPE = pendingRPEDay != nil && progress?.completionRecord(for: pendingRPEDay!)?.actualRPE != nil
                        
                        Text(hasExistingRPE ? "Update RPE" : "Save RPE")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(rpeColor(Double(selectedRPE)))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        showRPELogger = false
                        pendingRPEDay = nil
                    } label: {
                        Text("Skip")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .background(ReverieWeaverBackground())
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(420)])
    }
    
    func rpeDescription(_ rpe: Int) -> String {
        switch rpe {
        case 1...2: return "Very Easy · Could do this all day"
        case 3...4: return "Easy · Light effort, conversational"
        case 5...6: return "Moderate · Breathing harder, focused"
        case 7...8: return "Hard · Challenging, need to push"
        case 9: return "Very Hard · Near maximum effort"
        case 10: return "Maximum · Absolute limit"
        default: return ""
        }
    }
}

// MARK: - PREVIEW COMPONENTS

private extension VitalityDetailView {
    
    var previewHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHAPTER OVERVIEW")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.secondary)
            
            Text(isFeiProgram ? "Fei Strength Arc" : previewPhase.displayName)
                .font(.system(size: 22, weight: .semibold))
                .fontDesign(.serif)
                .foregroundStyle(Color(hex: isFeiProgram ? "9BB5CE" : previewPhase.colorHex))
            
            Text(isFeiProgram ? "Week \(selectedPreviewWeek) Focus" : previewPhase.weeksRangeLabel)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
            
            Text(isFeiProgram ? program.description : previewPhase.overview)
                .font(.system(size: 12, weight: .regular))
                .lineSpacing(3)
                .foregroundStyle(.primary.opacity(0.8))
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    var previewWeekSelector: some View {
        HStack(spacing: 10) {
            ForEach(1...4, id: \.self) { week in
                Button {
                    withAnimation { selectedPreviewWeek = week }
                } label: {
                    if selectedPreviewWeek == week {
                        Text("Week \(week)")
                            .font(.system(size: 12, weight: .regular))
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color(hex: "9BB5CE"))
                            .foregroundStyle(.white)
                            .cornerRadius(6)
                    } else {
                        Text("Week \(week)")
                            .font(.system(size: 12, weight: .regular))
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .cornerRadius(6)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    var previewTierSelector: some View {
        
            HStack(spacing: 0) {
                ForEach(CompletionTier.allCases, id: \.self) { tier in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            previewTier = tier
                        }
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                let style: (icon: String, color: String) = {
                                    switch tier {
                                    case .seed:   return ("leaf.fill", "B8D4C8")
                                    case .sprout: return ("leaf.circle.fill", "9BB5CE")
                                    case .bloom:  return ("sparkles", "D4B896")
                                    }
                                }()
                                
                                Image(systemName: style.icon)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: style.color))
                                
                                Text(tier.displayName)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(previewTier == tier ? Color.primary : Color.secondary)
                            }
                            
                            Rectangle()
                                .fill(previewTier == tier
                                      ? Color(hex: isFeiProgram ? "9BB5CE" : previewPhase.colorHex)
                                      : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    
    var singlePhaseSyllabusView: some View {
        let daysToShow: [VitalityDay]
        
        if isFeiProgram {
            daysToShow = program.schedule.filter { day in
                let week = (day.dayNumber - 1) / 7 + 1
                return week == selectedPreviewWeek
            }
        } else {
            daysToShow = Array(program.schedule.filter { $0.phase == previewPhase }.prefix(7))
        }
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(isFeiProgram ? "WEEK \(selectedPreviewWeek) SCHEDULE" : "WEEKLY RHYTHM")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if !isFeiProgram {
                    Text("Repeats for 2 weeks")
                        .font(.system(size: 11, weight: .regular))
                        .italic()
                        .foregroundStyle(.secondary.opacity(0.7))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            VStack(spacing: 16) {
                if daysToShow.isEmpty {
                    Text("No sessions found for this week.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(daysToShow) { day in
                        ExpandableSyllabusCard(
                            day: day,
                            tier: previewTier,
                            colorHex: isFeiProgram ? "9BB5CE" : previewPhase.colorHex
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    var startJourneyButton: some View {
        Button {
            startJourney()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "figure.run")
                    .font(.system(size: 14))
                
                Text("Start \(isFeiProgram ? "Fei Arc" : previewPhase.displayName)")
                    .font(.system(size: 13, weight: .semibold))
                    .fontDesign(.serif)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: isFeiProgram ? "9BB5CE" : "D4B896"), Color(hex: isFeiProgram ? "7A9BB8" : "BFA586")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.shadowColor.opacity(0.25), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 24)
        .padding(.bottom, 28)
    }
}

// MARK: - TRACKER COMPONENTS

private extension VitalityDetailView {
    
    var trackerHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("My Arc")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    if progress?.isExtendedFeiProgram == true {
                        Text("PROGRESSIVE")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "D4B896"))
                            .clipShape(Capsule())
                    }
                }
                
                Text(program.title)
                    .font(.system(size: 18, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            Spacer()
            
            if isFeiProgram {
                Text("WEEK \(selectedActiveWeek)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "9BB5CE"))
                    .clipShape(Capsule())
            } else {
                Text(selectedPhase.displayName.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: selectedPhase.colorHex))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    func rpeQuickAccessButton(for dayNumber: Int) -> some View {
        let hasRPE = progress?.completionRecord(for: dayNumber)?.actualRPE != nil
        
        return Button {
            pendingRPEDay = dayNumber
            showRPELogger = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: hasRPE ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(hasRPE ? Color.sageGreen : Color.dustyBlue)
                
                Text(hasRPE ? "Update RPE" : "+ Log RPE")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(hasRPE ? Color.sageGreen : Color.dustyBlue)
                
                if let rpe = progress?.completionRecord(for: dayNumber)?.actualRPE {
                    Text("(\(rpe))")
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill((hasRPE ? Color.sageGreen : Color.dustyBlue).opacity(colorScheme == .dark ? 0.15 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder((hasRPE ? Color.sageGreen : Color.dustyBlue).opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
    }
    
    var vitalityScoreCard: some View {
            HStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("SCORE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(progress?.vitalityScore ?? 0)")
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.sageGreen)
                            .contentTransition(.numericText(value: Double(progress?.vitalityScore ?? 0)))
                        Text("pts")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.sageGreen.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider().frame(height: 32)
                
                VStack(spacing: 6) {
                    Text("DAY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    // Use rest-day-aware current day
                    Text("\(progress?.currentScheduledDay(reflections: reflections) ?? 1)")
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(Color.dustyBlue)
                }
                .frame(maxWidth: .infinity)
                
                Divider().frame(height: 32)
                
                // 3. Done Section (Terracotta Rose)
                VStack(spacing: 6) {
                    Text("DONE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(.secondary)
                    
                    Text("\(progress?.daysCompleted ?? 0)/\(progress?.totalProgramDays ?? 56)")
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(Color.terracottaRose)
                        .contentTransition(.numericText(value: Double(progress?.daysCompleted ?? 0)))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
            .padding(.horizontal, 24)
            .id(refreshID)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress?.daysCompleted)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress?.vitalityScore)
        }

    // MARK: - Progress Bar
    var vitalityProgressBar: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dynamicSecondaryLabel.opacity(0.15))

                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.sageGreen, Color.sageGreen.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (progress?.progressPercent ?? 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress?.daysCompleted)
                }
            }
            .frame(height: 8)

            // Progress label
            HStack {
                Text("\(progress?.daysCompleted ?? 0) of \(progress?.totalProgramDays ?? 56) days")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int((progress?.progressPercent ?? 0) * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.sageGreen)
            }
        }
        .padding(.horizontal, 24)
    }

    var phaseTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VitalityPhase.allCases, id: \.self) { phase in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPhase = phase
                        }
                    } label: {
                        if selectedPhase == phase {
                            Text(phase.displayName)
                                .font(.system(size: 13, weight: .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color(hex: phase.colorHex))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        } else {
                            Text(phase.displayName)
                                .font(.system(size: 13, weight: .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(
                                        Color.secondary.opacity(0.3),
                                        lineWidth: 1
                                    )
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    var activeWeekSelector: some View {
        let weekRange: ClosedRange<Int>
        if progress?.currentCycle == 2 {
            weekRange = 5...8
        } else {
            weekRange = 1...4
        }
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(weekRange), id: \.self) { week in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedActiveWeek = week
                        }
                    } label: {
                        if selectedActiveWeek == week {
                            Text("Week \(week)")
                                .font(.system(size: 13, weight: .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color(hex: "9BB5CE"))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        } else {
                            Text("Week \(week)")
                                .font(.system(size: 13, weight: .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(
                                        Color.secondary.opacity(0.3),
                                        lineWidth: 1
                                    )
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    var trackerTierSelector: some View {
        HStack(spacing: 0) {
            ForEach(CompletionTier.allCases, id: \.self) { tier in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        previewTier = tier
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            let style: (icon: String, color: String) = {
                                switch tier {
                                case .seed:   return ("leaf.fill", "B8D4C8")
                                case .sprout: return ("leaf.circle.fill", "9BB5CE")
                                case .bloom:  return ("sparkles", "D4B896")
                                }
                            }()
                            
                            Image(systemName: style.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: style.color))
                            
                            Text(tier.displayName)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(previewTier == tier ? Color.primary : Color.secondary)
                        }
                        
                        Rectangle()
                            .fill(previewTier == tier
                                  ? Color(hex: isFeiProgram ? "9BB5CE" : selectedPhase.colorHex)
                                  : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

        
    // MARK: - TIMELINE VIEW
    //   4 STATES:
    // 1. COMPLETED: Day has been logged → Show checkmark, allow viewing details
    // 2. LOCKED: Day is too far in the future → Show lock icon, no interaction
    // 3. CURRENT: Day matches currentDayNumber → Show "Log Completion" button
    // 4. PREVIEW: Unlocked but not current → Show content without completion button
    
    var timelineView: some View {
            LazyVStack(spacing: 16) {
                ForEach(activeDaysToDisplay) { day in
                    let locked = isLocked(day)
                    let completed = isDayComplete(day.dayNumber)
                    let isCurrent = isCurrentDay(day)
                    
                    let record = progress?.completionRecord(for: day.dayNumber)
                    let tier = record?.tier
                    let rpe = record?.actualRPE
                    
                    if completed {
                        VitalityDayCard(
                            day: day,
                            isComplete: true,
                            completedTier: tier,
                            rpe: rpe,
                            isLocked: false,
                            onTap: {
                                selectedDay = day
                            },
                            onLongPress: {
                                // Long press opens RPE logger for this specific day
                                pendingRPEDay = day.dayNumber
                                showRPELogger = true
                            }
                        )
                    } else if locked {
                        VitalityDayCard(
                            day: day,
                            isComplete: false,
                            completedTier: nil,
                            rpe: nil,
                            isLocked: true,
                            onTap: {},
                            onLongPress: {}
                        )
                    } else if isCurrent {
                        VStack(spacing: 0) {
                            ExpandableSyllabusCard(
                                day: day,
                                tier: previewTier,
                                colorHex: isFeiProgram ? "9BB5CE" : selectedPhase.colorHex
                            )
                            
                            Button {
                                completeDay(day, tier: previewTier)
                            } label: {
                                HStack {
                                    Text("Log Completion")
                                        .font(.system(size: 13, weight: .semibold))
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 13))
                                }
                                .foregroundStyle(Color.primary.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundStyle(Color.secondary.opacity(0.1)),
                                    alignment: .top
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .reverieCardStyle(colorScheme: colorScheme)
                    } else {
                        ExpandableSyllabusCard(
                            day: day,
                            tier: previewTier,
                            colorHex: isFeiProgram ? "9BB5CE" : selectedPhase.colorHex
                        )
                        .opacity(0.7)
                    }
                }
            }
            .padding(.horizontal, 24)
            .id(refreshID)
        }
    
       func isDayComplete(_ dayNumber: Int) -> Bool {
           progress?.isDayComplete(dayNumber) ?? false
       }
       
       func isLocked(_ day: VitalityDay) -> Bool {
           guard let p = progress else {
               return isAddedToDesk ? day.dayNumber > 3 : true
           }
           // Use rest-day-aware current day calculation
           let currentDay = p.currentScheduledDay(reflections: reflections)
           return day.dayNumber > currentDay + 2
       }
    
    func isCurrentDay(_ day: VitalityDay) -> Bool {
        guard let p = progress else {
            return isAddedToDesk && day.dayNumber == 1
        }
        // Use rest-day-aware current day calculation
        let currentDay = p.currentScheduledDay(reflections: reflections)
        return day.dayNumber == currentDay
    }
    
    private var activeDaysToDisplay: [VitalityDay] {
        if isFeiProgram {
            let displayWeek = selectedActiveWeek  // 1-4 for cycle 1, 5-8 for cycle 2
            let scheduleWeek: Int
            
            if displayWeek > 4 {
                scheduleWeek = displayWeek - 4  // weeks 5-8 map to pattern 1-4
            } else {
                scheduleWeek = displayWeek      // weeks 1-4 use pattern 1-4
            }
            
            let baseDays = program.schedule.filter { day in
                let week = (day.dayNumber - 1) / 7 + 1
                return week == scheduleWeek
            }
            
            // For cycle 2 weeks 5-8, create modified days with offset day numbers (days 29-56)
            if progress?.currentCycle == 2 && displayWeek > 4 {
                let dayOffset = 28  // Start from day 29
                
                return baseDays.map { day in
                    let offsetDayNumber = day.dayNumber + dayOffset
                    
                    return VitalityDay(
                        dayNumber: offsetDayNumber,
                        phase: day.phase,
                        title: day.title.replacingOccurrences(
                            of: "Week \(scheduleWeek)",
                            with: "Week \(displayWeek)"
                        ),
                        focusArea: day.focusArea,
                        duration: day.duration,
                        seedOption: day.seedOption + "\n\n💪 Progressive Block: Consider adding resistance or increasing time under tension.",
                        sproutOption: day.sproutOption + "\n\n💪 Progressive Block: Add 1-2 extra reps or use heavier resistance.",
                        bloomOption: day.bloomOption + "\n\n💪 Progressive Block: Push intensity - you've earned the capacity for more."
                    )
                }
            }
            
            return baseDays
        } else {
            return program.schedule.filter { $0.phase == selectedPhase }
        }
    }
}

// MARK: - LOGIC HELPERS
private extension VitalityDetailView {
    
    func convertToThemeHabit(_ day: VitalityDay) -> ThemeWeekHabit {
        ThemeWeekHabit(
            name: cleanTitle(day.title),
            icon: isFeiProgram ? "dumbbell.fill" : "figure.mind.and.body",
            colorHex: isFeiProgram ? "9BB5CE" : day.phase.colorHex,
            seedTier: day.seedOption,
            sproutTier: day.sproutOption,
            bloomTier: day.bloomOption,
            dayNumber: day.dayNumber,
            tag: "VA-\(program.id)"
        )
    }
    
    func cleanTitle(_ title: String) -> String {
        if let range = title.range(of: "Fei Strength · Week \\d+ ", options: .regularExpression) {
            return title.replacingCharacters(in: range, with: "")
        }
        return title
    }
    
    func startJourney() {
           #if DEBUG
           print("🌿 [Vitality] startJourney → creating progress for tag=\(habitTag)")
           #endif
           
           var activeProgress: VitalityProgress?
           
           if let existing = progress {
               activeProgress = existing
               #if DEBUG
               print("🌿 [Vitality] Using existing progress: daysCompleted=\(existing.daysCompleted), totalDays=\(existing.totalProgramDays)")
               #endif
           } else {
               let newProgress = VitalityProgress(
                   programID: program.id,
                   programTag: habitTag,
                   programTitle: program.title
               )
               modelContext.insert(newProgress)
               activeProgress = newProgress
               
               #if DEBUG
               print("🌿 [Vitality] Created NEW progress: programID=\(program.id), cycle=\(newProgress.currentCycle), totalDays=\(newProgress.totalProgramDays)")
               #endif
           }
           
           if !habits.contains(where: { $0.programTag == habitTag && !$0.isArchived }) {
               let habit = Habit(
                   name: program.title,
                   description: program.subtitle,
                   category: "Health",
                   categoryIcon: program.icon,
                   icon: program.icon,
                   colorHex: isFeiProgram ? "9BB5CE" : "D4B896",
                   completionMessage: "Vitality is a practice. Well done.",
                   frequency: "daily",
                   order: habits.count,
                   programTag: habitTag,
                   programLevel: nil,
                   scheduledDays: nil
               )
               modelContext.insert(habit)
               
               #if DEBUG
               print("🌿 [Vitality] Created habit: \(habit.name), tag=\(habitTag)")
               #endif
           }
           
           do {
               try modelContext.save()
               
               #if DEBUG
               print("🌿 [Vitality] First save complete, verifying persistence...")
               
               let verifyDescriptor = FetchDescriptor<VitalityProgress>()
               if let allRecords = try? modelContext.fetch(verifyDescriptor) {
                   print("🌿 [Vitality] Total VitalityProgress records after save: \(allRecords.count)")
                   if let found = allRecords.first(where: { $0.programTag == habitTag }) {
                       print("✅ [Vitality] Verified: Found progress with tag \(found.programTag), days=\(found.daysCompleted)")
                   } else {
                       print("❌ [Vitality] ERROR: Progress not found after save!")
                       allRecords.forEach { print("  - Found record: \($0.programTag)") }
                   }
               }
               #endif
               
               if let p = activeProgress {
                   self.localProgressOverride = p
                   
                   #if DEBUG
                   print("🌿 [Vitality] UI Override set: daysCompleted=\(p.daysCompleted), totalDays=\(p.totalProgramDays)")
                   #endif
               }
               
               withAnimation(.spring(response: 0.5)) {
                   self.refreshID = UUID()
                   // Switch to "My Arc" tracker view immediately
                   self.justStartedJourney = true

                   #if DEBUG
                   print("🌿 [Vitality] justStartedJourney set to TRUE, isAddedToDesk should now be: \(self.justStartedJourney || self.vitalityHabit != nil)")
                   #endif
               }

               ReverieHaptics.successFeedback()

               // NOTE: Do NOT post vitalityProgressUpdated notification here.
               // Starting a journey creates new top-level objects (VitalityProgress, Habit)
               // which @Query detects automatically. The notification causes DeskView's
               // refreshID to change, which recreates the view and dismisses all sheets
               // (including HabitLibrary → VitalityOverview → this detail view).
               // The notification is only needed for day completions (nested array updates).

               #if DEBUG
               print("🌿 [Vitality] Journey started successfully with tag=\(habitTag)")
               print("🌿 [Vitality] Display check: \(activeProgress?.daysCompleted ?? -1)/\(activeProgress?.totalProgramDays ?? -1)")
               #endif
           } catch {
               #if DEBUG
               print("❌ [Vitality] Save failed with error: \(error)")
               #endif
               errorMessage = "Unable to start journey. Please try again."
               showError = true
           }
       }
    
    func completeDay(_ day: VitalityDay, tier: CompletionTier) {
           guard !isDayComplete(day.dayNumber) else {
               errorMessage = "You've already logged Day \(day.dayNumber). Each day can only be logged once."
               showError = true
               return
           }
           
           //   PREVENT COMPLETING FUTURE DAYS
           guard isCurrentDay(day) else {
               // Use rest-day-aware current day in error message
               let currentDay = progress?.currentScheduledDay(reflections: reflections) ?? 1
               errorMessage = "You can only log completion for the current day (Day \(currentDay))."
               showError = true
               return
           }
           
           let progressRecord: VitalityProgress
           
           let descriptor = FetchDescriptor<VitalityProgress>(
               predicate: #Predicate { $0.programTag == habitTag && !$0.isCompleted }
           )
           
           if let fetched = try? modelContext.fetch(descriptor).first {
               progressRecord = fetched
           } else {
               AppLog.info("No active progress found, creating new record", category: "vitality")
               progressRecord = VitalityProgress(
                   programID: program.id,
                   programTag: habitTag,
                   programTitle: program.title
               )
               modelContext.insert(progressRecord)
           }
           
           guard let habitModel = vitalityHabit else {
               AppLog.error("Vitality Habit not found", category: "vitality")
               errorMessage = "Habit not found. Please restart the journey."
               showError = true
               return
           }
           
           let completion = HabitCompletion(
               habitId: habitModel.id,
               completedAt: Date()
           )
           modelContext.insert(completion)
           
           progressRecord.completeDay(
               day.dayNumber,
               tier: tier,
               habitID: habitModel.id
           )
           
           #if DEBUG
           AppLog.info("completeDay → day=\(day.dayNumber) tier=\(tier.displayName)", category: "vitality")
           AppLog.info("Progress BEFORE save: daysCompleted=\(progressRecord.daysCompleted), score=\(progressRecord.vitalityScore)", category: "vitality")
           #endif
           
           do {
               try modelContext.save()
               
               #if DEBUG
               // Re-fetch to verify persistence
               if let verified = try? modelContext.fetch(descriptor).first {
                   AppLog.info("Progress AFTER save: daysCompleted=\(verified.daysCompleted), score=\(verified.vitalityScore), totalDays=\(verified.totalProgramDays)", category: "vitality")
               }
               #endif
               
               self.localProgressOverride = progressRecord

               // 🔧 FIX: Defer notification to onDisappear to prevent cascading sheet dismissal
               // The local @Query will pick up changes immediately via modelContext.save()
               // DeskView will be notified when user closes this detail view
               needsNotifyDeskViewOnDismiss = true

               withAnimation(.spring(response: 0.5)) {
                   refreshID = UUID()
               }
               
               selectedTier = tier
               withAnimation(.spring(response: 0.5)) {
                   showSuccessMessage = true
               }
               
               ReverieHaptics.successFeedback()
               
               successAnimationTask?.cancel()
               
               let shouldOfferExtension = (isFeiProgram && 
                                          day.dayNumber == 28 && 
                                          progressRecord.currentCycle == 1 &&
                                          !progressRecord.hasOfferedCycleExtension)
               
               successAnimationTask = Task { @MainActor in
                   do {
                       try await Task.sleep(nanoseconds: 3_500_000_000)
                       
                       guard !Task.isCancelled else { return }
                       
                       withAnimation {
                           showSuccessMessage = false
                       }
                       
                       try await Task.sleep(nanoseconds: 300_000_000)
                       guard !Task.isCancelled else { return }
                       
                       //   Check if day 28 completion for Fei program (show extension prompt)
                       if shouldOfferExtension {
                           showCycleExtensionPrompt = true
                           
                           #if DEBUG
                           print("🌿 [Vitality] Day 28 completed → showing cycle extension prompt")
                           #endif
                           
                           progressRecord.hasOfferedCycleExtension = true
                           try? modelContext.save()
                       }
                   } catch {
                      
                   }
               }
           } catch {
               AppLog.error("Failed to complete day: \(error)", category: "vitality")
               errorMessage = "Unable to save completion. Please try again."
               showError = true
           }
       }
    
    func deleteJourney() {
        let habitTag = "VA-\(program.id)"
        
        #if DEBUG
        AppLog.info("deleteJourney → \(habitTag)", category: "vitality")
        #endif
        
        if let habit = vitalityHabit {
            habit.prepareForDeletion()
            modelContext.delete(habit)
        }
        
        if let progressRecord = progress {
            modelContext.delete(progressRecord)
        }
        
        #if DEBUG
        let hadHabit = (vitalityHabit != nil)
        let hadProgress = (progress != nil)
        print("🌿 [Vitality] Deletion summary → habitRemoved=\(hadHabit) progressRemoved=\(hadProgress)")
        #endif
        
        do {
            try modelContext.save()
            ReverieHaptics.lightFeedback()
            withAnimation(.spring()) {
                dismiss()
            }
        } catch {
            print("Failed to delete journey: \(error)")
            errorMessage = "Unable to delete journey. Please try again."
            showError = true
        }
    }
}

// MARK: - SUBVIEWS

struct VitalityDayCard: View {
    let day: VitalityDay
    let isComplete: Bool
    let completedTier: CompletionTier?
    let rpe: Int?
    let isLocked: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isComplete ?
                        Color.sageGreen.opacity(0.15) :
                            Color.adaptiveSectionBackground(colorScheme: colorScheme)
                    )
                    .frame(width: 38, height: 38)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isComplete ? Color.sageGreen.opacity(0.3) : Color.adaptiveBorder(colorScheme: colorScheme),
                                lineWidth: 1
                            )
                    )
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.sageGreen)
                } else {
                    // Show Day Number if pending
                    VStack(spacing: 0) {
                        Text("DAY")
                            .font(.system(size: 11, weight: .semibold))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        Text("\(day.dayNumber)")
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    }
                }
            }
            .opacity(isLocked ? 0.5 : 1)
         
            VStack(alignment: .leading, spacing: 3) {
                Text(cleanTitle(day.title))
                    .font(.system(size: 13, weight: .regular))
                    .strikethrough(isComplete)
                    .foregroundStyle(isLocked || isComplete ? .secondary : .primary)
                
                if isComplete, let tier = completedTier {
                    HStack(spacing: 4) {
                        Image(systemName: tier.sfSymbol)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.sageGreen)
                        
                        Text(tier.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.sageGreen)
                        
                        //   NEW: RPE Display
                        if let rpeVal = rpe {
                            Text("·")
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            
                            Text("RPE \(rpeVal)")
                                .font(.system(size: 12, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                } else {
                    HStack(spacing: 5) {
                        if day.isRestDay {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.purple.opacity(0.7))
                            Text("Rest Day")
                                .font(.system(size: 12, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        } else {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("\(day.duration) min")
                                .font(.system(size: 12, weight: .regular))
                            
                            Text("·")
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            
                            Text(day.focusArea)
                                .font(.system(size: 12, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            
            Spacer()
            
            if isComplete {
                // Show hint for long press on completed days
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dustyBlue.opacity(0.5))
            } else if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
        }
        .padding(14)
        .reverieCardStyle(colorScheme: colorScheme)
        .opacity(isComplete ? 0.6 : (isLocked ? 0.5 : 1.0))
        .contentShape(Rectangle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if isComplete {
                        ReverieHaptics.lightFeedback()
                        onLongPress()
                    }
                }
        )
        .onTapGesture {
            if !isLocked {
                onTap()
            }
        }
    }
    
    func cleanTitle(_ title: String) -> String {
        if let range = title.range(of: "Fei Strength · Week \\d+ ", options: .regularExpression) {
            return title.replacingCharacters(in: range, with: "")
        }
        return title
    }
}

struct ExpandableSyllabusCard: View {
    let day: VitalityDay
    let tier: CompletionTier
    let colorHex: String
    
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var contentParts: (teaser: String, details: String) {
        let fullText = descriptionForTier(day: day, tier: tier)
        let components = fullText.components(separatedBy: "\n\n")
        let teaser = components.first ?? "Tap to see details"
        let details = components.dropFirst().joined(separator: "\n\n")
        return (teaser, details)
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: colorHex).opacity(0.15))
                            .frame(width: 28, height: 28)
                        Text("\(day.dayNumber)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: colorHex))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cleanTitle(day.title))
                            .font(.system(size: 13, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        
                        Text("Day \(day.dayNumber)")
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                    
                    Spacer()
                    
                    if !day.isRestDay {
                        Text("\(day.duration) min")
                            .font(.system(size: 11, weight: .regular))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                            .cornerRadius(4)
                    }
                }
                
                Divider()
                
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: tier.sfSymbol)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: colorHex))
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(contentParts.teaser)
                            .font(.system(size: 12, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .lineLimit(isExpanded ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if isExpanded && !contentParts.details.isEmpty {
                            Text(contentParts.details)
                                .font(.system(size: 12, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .padding(.top, 2)
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .buttonStyle(.plain)
    }
    
    func cleanTitle(_ title: String) -> String {
        if let range = title.range(of: "Fei Strength · Week \\d+ ", options: .regularExpression) {
            return title.replacingCharacters(in: range, with: "")
        }
        return title
    }
    
    func descriptionForTier(day: VitalityDay, tier: CompletionTier) -> String {
        switch tier {
        case .seed: return day.seedOption
        case .sprout: return day.sproutOption
        case .bloom: return day.bloomOption
        }
    }
}

// MARK: - Preview

#Preview {
    VitalityDetailView(program: VitalityData.program)
        .modelContainer(for: [VitalityProgress.self, Habit.self, HabitCompletion.self], inMemory: true)
}
