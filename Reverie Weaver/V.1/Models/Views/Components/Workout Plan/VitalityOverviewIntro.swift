//
//  VitalityOverviewIntro.swift
//  Reverie Weaver
//
//

import SwiftUI
import SwiftData
import Combine

struct VitalityDetailNavigation: Identifiable, Equatable {
    // Use program.id as stable identifier instead of random UUID
    // This prevents SwiftUI from treating it as a different item when parent re-renders
    var id: String { program.id }
    let program: VitalityProgram
    let previewPhase: VitalityPhase
    let initialWeek: Int

    static func == (lhs: VitalityDetailNavigation, rhs: VitalityDetailNavigation) -> Bool {
        lhs.program.id == rhs.program.id &&
        lhs.previewPhase == rhs.previewPhase &&
        lhs.initialWeek == rhs.initialWeek
    }
}

// Observable state holder for VitalityOverviewIntro to survive parent view re-renders
@MainActor
private class VitalityOverviewState: ObservableObject {
    @Published var detailNavigation: VitalityDetailNavigation?
    @Published var isDetailSheetActive = false
}

struct VitalityOverviewIntro: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query private var progressRecords: [VitalityProgress]
    @Query private var habits: [Habit]
    
    private var activeVitalityProgress: VitalityProgress? {
        progressRecords.first { $0.programID == "vitality-arc-8week" && !$0.isCompleted && !$0.isPaused }
    }
    
    private var activeFeiProgress: VitalityProgress? {
        progressRecords.first { $0.programID == "fei-strength-arc-4week" && !$0.isCompleted && !$0.isPaused }
    }
    
    private var isVitalityActive: Bool {
        activeVitalityProgress != nil ||
        habits.contains { $0.programTag == "VA-vitality-arc-8week" && !$0.isArchived }
    }
    
    private var isFeiActive: Bool {
        activeFeiProgress != nil ||
        habits.contains { $0.programTag == "VA-fei-strength-arc-4week" && !$0.isArchived }
    }
    
    @State private var selectedPhase: VitalityPhase = .activation
    @State private var showFeiArc = false
    @State private var selectedFeiWeek: Int = 1
    @State private var addedToDesk = false

    // Use StateObject to hold detail navigation state - survives parent @Query re-renders
    @StateObject private var viewState = VitalityOverviewState()

    var currentProgram: VitalityProgram {
        showFeiArc ? VitalityData.feiProgram : VitalityData.program
    }
    
    var isCurrentProgramActive: Bool {
        showFeiArc ? isFeiActive : isVitalityActive
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        programSwitcher
                        heroSection
                        
                        if isCurrentProgramActive {
                            activeProgressCard
                        }
                        
                        phasesPreviewSection
                        philosophySection
                        schedulePreviewSection
                    }
                    .padding(.bottom, 120)
                    .padding(.top, 60)
                }
                
                HStack {
                    Spacer()
                    closeButton
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                VStack {
                    Spacer()
                    viewProgramButton
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $viewState.detailNavigation, onDismiss: {
                // Only clear active state when sheet is truly dismissed by user
                viewState.isDetailSheetActive = false
            }) { nav in
                VitalityDetailView(
                    program: nav.program,
                    previewPhase: nav.previewPhase,
                    initialWeek: nav.initialWeek
                )
                .id(nav.id) // Stable identity based on program.id
                .onAppear {
                    viewState.isDetailSheetActive = true
                }
                .presentationDetents([.large, .fraction(0.75)])
                .presentationDragIndicator(.visible)
            }
            // Prevent parent sheet from dismissing when child detail view is active
            .interactiveDismissDisabled(viewState.isDetailSheetActive)
            .onAppear {
                if isVitalityActive || isFeiActive {
                    addedToDesk = true
                }
            }
            .onChange(of: showFeiArc) { _, newValue in
                if newValue {
                    selectedPhase = .strength
                    selectedFeiWeek = 1
                } else {
                    selectedPhase = .activation
                }
            }
        }
    }
}

// MARK: - Sections
private extension VitalityOverviewIntro {
    
    // MARK: Program Switcher
    var programSwitcher: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring()) { showFeiArc = false }
            } label: {
                HStack(spacing: 6) {
                    Text("Vitality Arc")
                        .font(.system(size: 13, weight: .semibold))
                    
                    if isVitalityActive {
                        Text("Active")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.sageGreen)
                            .cornerRadius(4)
                    }
                }
                .foregroundStyle(showFeiArc ? .secondary : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    showFeiArc ? Color.clear : Color.adaptiveSectionBackground(colorScheme: colorScheme)
                )
                .cornerRadius(8)
            }
            
            Button {
                withAnimation(.spring()) { showFeiArc = true }
            } label: {
                HStack(spacing: 6) {
                    Text("Fei Strength")
                        .font(.system(size: 13, weight: .semibold))
                    
                    if isFeiActive {
                        Text("Active")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.sageGreen)
                            .cornerRadius(4)
                    }
                }
                .foregroundStyle(showFeiArc ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    showFeiArc ? Color.adaptiveSectionBackground(colorScheme: colorScheme) : Color.clear
                )
                .cornerRadius(8)
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
    
    var activeProgressCard: some View {
        let progress = showFeiArc ? activeFeiProgress : activeVitalityProgress
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: showFeiArc ? "9BB5CE" : "D4B896"))
                
                Text("Your Journey")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
                
                Spacer()
                
                if let p = progress {
                    Text("Day \(p.currentDayNumber)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            if let p = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: showFeiArc ? "9BB5CE" : "D4B896"))
                            .frame(width: geo.size.width * p.progressPercent, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(p.daysCompleted) days completed")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(p.progressPercent * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: showFeiArc ? "9BB5CE" : "D4B896"))
                }
            }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal, 24)
    }
    
    // MARK: Hero Section
    var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Show badge for Fei Strength (sample program)
            if showFeiArc {
                SampleProgramBadge()
                    .padding(.horizontal, 24)
            }
            
            Group {
                if showFeiArc {
                    HybridEditorialChallengeHeader(
                        icon: "dumbbell.fill",
                        title: "Fei Strength Arc",
                        categoryLabel: "4-Week Program",
                        subtitle: "Linear hypertrophy block for glutes, core, and confidence.",
                        accentColor: Color(hex: "9BB5CE")
                    )
                } else {
                    HybridEditorialChallengeHeader(
                        icon: "figure.mind.and.body",
                        title: "The Vitality Arc",
                        categoryLabel: "Body Recomposition · 8-Week",
                        subtitle: "Phased program: awaken, ignite, sculpt, and flow.",
                        accentColor: Color(hex: "C8B8DB")
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 20)
    }
    
    // MARK: Philosophy Section
    var philosophySection: some View {
        VStack(spacing: 20) {
            OpenEditorialSection(
                icon: showFeiArc ? "dumbbell.fill" : "sparkles",
                iconColor: Color(hex: showFeiArc ? "9BB5CE" : "D4B896"),
                title: showFeiArc ? "FEI STRENGTH · THE PHILOSOPHY" : "THE PHILOSOPHY",
                content: currentProgram.description
            )
            
            VStack(spacing: 12) {
                TierLegendRow(
                    icon: "leaf.fill",
                    color: "B8D4C8",
                    title: "Seed",
                    desc: "Low energy rescue"
                )
                TierLegendRow(
                    icon: "leaf.circle.fill",
                    color: "9BB5CE",
                    title: "Sprout",
                    desc: "Standard workout"
                )
                TierLegendRow(
                    icon: "sparkles",
                    color: "D4B896",
                    title: "Bloom",
                    desc: "High energy push"
                )
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: Phases Preview Section
    var phasesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(showFeiArc ? "WEEKLY ROADMAP" : "THE JOURNEY")
                .font(.system(size: 12, weight: .bold))
                .tracking(1)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if showFeiArc {
                        ForEach(1...4, id: \.self) { week in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Week \(week)")
                                    .font(.system(size: 14, weight: .bold))
                                    .fontDesign(.serif)
                                    .foregroundStyle(
                                        selectedFeiWeek == week ? .white : Color(hex: "9BB5CE")
                                    )
                                
                                Text(feiWeekTitle(week))
                                    .font(.system(size: 11))
                                    .lineLimit(2)
                                    .foregroundStyle(
                                        selectedFeiWeek == week ? .white.opacity(0.9) : .secondary
                                    )
                            }
                            .frame(width: 100, height: 70)
                            .padding(12)
                            .background(
                                selectedFeiWeek == week
                                ? Color(hex: "9BB5CE")
                                : Color.adaptiveSectionBackground(colorScheme: colorScheme)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        Color(hex: "9BB5CE").opacity(selectedFeiWeek == week ? 0 : 0.5),
                                        lineWidth: 1
                                    )
                            )
                            .onTapGesture {
                                withAnimation { selectedFeiWeek = week }
                            }
                        }
                    } else {
                        ForEach(VitalityPhase.allCases, id: \.self) { phase in
                            PhaseCard(phase: phase, isSelected: selectedPhase == phase)
                                .onTapGesture {
                                    withAnimation { selectedPhase = phase }
                                }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    func feiWeekTitle(_ week: Int) -> String {
        switch week {
        case 1: return "Foundation & Pattern"
        case 2: return "Volume Building"
        case 3: return "Intensity Peak"
        case 4: return "Deload & Recovery"
        default: return "Week \(week)"
        }
    }
    
    var previewDaysToShow: [VitalityDay] {
        if showFeiArc {
            return Array(currentProgram.schedule.filter { day in
                let week = (day.dayNumber - 1) / 7 + 1
                return week == selectedFeiWeek
            }.prefix(7))
        } else {
            return Array(currentProgram.schedule.filter { $0.phase == selectedPhase }.prefix(7))
        }
    }
    
    // MARK: Schedule Preview Section
    var schedulePreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(showFeiArc ? "WEEK \(selectedFeiWeek) PREVIEW" : "\(selectedPhase.displayName.uppercased()) PREVIEW")
                .font(.system(size: 12, weight: .bold))
                .tracking(1)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 10) {
                ForEach(previewDaysToShow) { day in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: showFeiArc ? "9BB5CE" : day.phase.colorHex).opacity(0.15))
                                .frame(width: 32, height: 32)
                            Text("\(day.dayNumber)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: showFeiArc ? "9BB5CE" : day.phase.colorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cleanTitle(day.title))
                                .font(.system(size: 13, weight: .semibold))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            Text(day.focusArea)
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                        
                        Spacer()
                        
                        if day.isRestDay {
                            Image(systemName: "moon.zzz.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(day.duration) min")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Color.adaptiveSectionBackground(colorScheme: colorScheme)
                                )
                                .cornerRadius(4)
                        }
                    }
                    .padding(12)
                    .reverieCardStyle(colorScheme: colorScheme)
                }
                
                HStack {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11))
                    Text(showFeiArc ? "+ 4 more days this week" : "+ more days in this phase")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color(hex: showFeiArc ? "9BB5CE" : selectedPhase.colorHex))
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
    }
    
    func cleanTitle(_ title: String) -> String {
        if let range = title.range(
            of: "Fei Strength · Week \\d+ ",
            options: .regularExpression
        ) {
            return title.replacingCharacters(in: range, with: "")
        }
        return title
    }
    
    // MARK: View Program Button
    var viewProgramButton: some View {
        Button {
            viewState.detailNavigation = VitalityDetailNavigation(
                program: currentProgram,
                previewPhase: showFeiArc ? .strength : selectedPhase,
                initialWeek: showFeiArc ? selectedFeiWeek : 1
            )
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isCurrentProgramActive ? "arrow.right.circle.fill" : "play.circle.fill")
                    .font(.system(size: 18))
                
                Text(buttonLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: showFeiArc ? "9BB5CE" : "D4B896"),
                        Color(hex: showFeiArc ? "7A9BB8" : "BFA586")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.shadowColor.opacity(0.25), radius: 4, y: 3)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 24)
        .padding(.bottom, 32)
    }
    
    var buttonLabel: String {
        if isCurrentProgramActive {
            return "Continue Arc"
        }
        if showFeiArc {
            return "View Week \(selectedFeiWeek) Details"
        }
        return "View \(selectedPhase.displayName) Details"
    }
    
    var closeButton: some View {
        GlassCloseButton {
            dismiss()
        }
    }
    
    // MARK: - Actions (kept for potential direct use)
    func startProgram() {
        let habitTag = "VA-\(currentProgram.id)"
        
        #if DEBUG
        print("🌿 [Vitality] startProgram → creating progress for tag=\(habitTag)")
        #endif
        
        let newProgress = VitalityProgress(
            programID: currentProgram.id,
            programTag: habitTag,
            programTitle: currentProgram.title
        )
        modelContext.insert(newProgress)
        
        let habit = Habit(
            name: currentProgram.title,
            description: currentProgram.subtitle,
            category: "Health",
            categoryIcon: currentProgram.icon,
            icon: currentProgram.icon,
            colorHex: showFeiArc ? "9BB5CE" : "D4B896",
            completionMessage: "Vitality is a practice. Well done.",
            frequency: "daily",
            order: habits.count,
            programTag: habitTag,
            programLevel: nil,
            scheduledDays: nil
        )
        modelContext.insert(habit)
        
        do {
            try modelContext.save()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                addedToDesk = true
            }
            
            ReverieHaptics.successFeedback()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } catch {
            print("Failed to start program: \(error)")
        }
    }
}

// MARK: - Helper Views

struct BadgeView: View {
    let text: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.adaptiveSectionBackground(colorScheme: colorScheme))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
        )
    }
}

struct TierLegendRow: View {
    let icon: String
    let color: String
    let title: String
    let desc: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Text(desc)
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            Spacer()
        }
    }
}

struct PhaseCard: View {
    let phase: VitalityPhase
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isSelected {
                Text(phase.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundStyle(.white)

                Text(phase.focus)
                    .font(.system(size: 11))
                    .lineLimit(2)
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Text(phase.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundStyle(Color(hex: phase.colorHex))

                Text(phase.focus)
                    .font(.system(size: 11))
                    .lineLimit(2)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
        }
        .frame(width: 140, height: 80)
        .padding(12)
        .background(
            isSelected
            ? Color(hex: phase.colorHex)
            : Color.adaptiveSectionBackground(colorScheme: colorScheme)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    Color(hex: phase.colorHex).opacity(isSelected ? 0 : 0.5),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isSelected ? Color(hex: phase.colorHex).opacity(0.3) : .clear,
            radius: 5,
            y: 3
        )
    }
}

// MARK: - Preview

#Preview {
    VitalityOverviewIntro()
        .modelContainer(for: [VitalityProgress.self, Habit.self], inMemory: true)
}
