//
//  ReadyToFocusSheet.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/26/25.
//
//
//

import SwiftUI

struct ReadyToFocusSheet: View {
    @Bindable var timerManager: PomodoroTimerManager
    @Bindable var soundscapePlayer: SoundscapePlayer
    let onStart: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var showLocalCategoryPicker = false
    @State private var isStartingSession = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Main Background
            ReverieWeaverBackground()
                .ignoresSafeArea()
            
            // 2. Scrolling Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Top Spacer
                    Color.clear.frame(height: 60)
                    
                    // Time Section
                    timeSelectionSection
                    
                    // Soundscape Section
                    soundscapeSection
                    
                    // Session Settings
                    sessionConfigurationSection
                    
                    // Category
                    categorySection
                    
                    // Bottom Spacer
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 24)
            }
            
            // 3. Fixed Header (Transparent)
            VStack {
                headerView
                Spacer()
            }
            .allowsHitTesting(false)
            
            // 4. Fixed Bottom Buttons
            bottomButtons
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onDisappear {
                    // Only stop soundscape if we're truly canceling
                    // Don't stop if:
                    // 1. Session is being started
                    // 2. Timer is already running (rotation case)
                    // 3. A soundscape was intentionally selected
                    let timerIsActive = timerManager.timerState != .idle
                    
                    if !isStartingSession && !timerIsActive {
                        // User canceled without starting - stop preview
                        soundscapePlayer.stop()
                    }
                    // If session started or timer is running, let soundscape continue
                }
        .sheet(isPresented: $showLocalCategoryPicker) {
            FocusCategoryPicker(
                timerManager: timerManager,
                onStart: { showLocalCategoryPicker = false },
                onCancel: { showLocalCategoryPicker = false }
            )
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(24)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Text("Ready to Focus")
                .font(.system(size: 16, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Time Section
    private var timeSelectionSection: some View {
        VStack(spacing: 24) {
            Text("\(timerManager.workDuration) min")
                .font(.system(size: 22, weight: .medium))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .contentTransition(.numericText(value: Double(timerManager.workDuration)))
                .animation(.snappy, value: timerManager.workDuration)

            RulerView(
                value: $timerManager.workDuration,
                range: 1...90,
                centerColor: Color.sageGreen
            )
            .frame(height: 50)
            .mask(
                LinearGradient(
                    colors: [.clear, .black, .black, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Soundscape Section
    private var soundscapeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("SOUNDSCAPE")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 20) {
                ForEach(Soundscape.allCases, id: \.self) { soundscape in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            soundscapePlayer.selectSoundscape(soundscape)
                        }
                    } label: {
                        SoundscapeCircle(soundscape: soundscape, isSelected: soundscapePlayer.selectedSoundscape == soundscape)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Session Settings
        private var sessionConfigurationSection: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("SESSION SETTINGS")
                
                VStack(spacing: 0) {
                    // 1. Short Break (Always Visible)
                    settingRow(icon: "cup.and.saucer", title: "Short Break") {
                        Menu {
                            Picker("Duration", selection: $timerManager.shortBreakDuration) {
                                ForEach([3, 5, 10, 15, 20, 25], id: \.self) { m in Text("\(m) m").tag(m) }
                            }
                        } label: {
                            Text("\(timerManager.shortBreakDuration) m")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.sageGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.sageGreen.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    
                    Divider().padding(.leading, 36).opacity(0.5)
                    
                    // 2. Focus Cycles
                    settingRow(icon: "arrow.triangle.2.circlepath", title: "Focus Cycles") {
                        Menu {
                            Picker("Cycles", selection: $timerManager.totalCycles) {
                                ForEach(2...6, id: \.self) { c in Text("\(c)").tag(c) }
                            }
                        } label: {
                            Text("\(timerManager.totalCycles)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.sageGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.sageGreen.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    
                    Divider().padding(.leading, 36).opacity(0.5)
                    
                    // 3. Enable Long Break Toggle
                    HStack {
                        Image(systemName: "moon.stars")
                            .font(.system(size: 14))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .frame(width: 24)

                        Text("Enable Long Breaks")
                            .font(.system(size: 14))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                        Spacer()

                        Toggle("", isOn: $timerManager.isLongBreakEnabled)
                            .labelsHidden()
                            .tint(Color.sageGreen)
                            .scaleEffect(0.8)
                    }
                    .padding(.vertical, 8)
                    
                    // 4. Conditional Long Break Settings
                    if timerManager.isLongBreakEnabled {
                        Divider().padding(.leading, 36).opacity(0.5)
                        
                        // Long Break Duration
                        settingRow(icon: "hourglass", title: "Long Break Duration") {
                            Menu {
                                Picker("Duration", selection: $timerManager.longBreakDuration) {
                                    ForEach([10, 15, 20, 25, 30, 35], id: \.self) { m in Text("\(m) m").tag(m) }
                                }
                            } label: {
                                Text("\(timerManager.longBreakDuration) m")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.sageGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.sageGreen.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        
                        Divider().padding(.leading, 36).opacity(0.5)
                        
                        // Long Break Interval (Optional redundant setting)
                        settingRow(icon: "stopwatch", title: "Long Break After") {
                            Menu {
                                Picker("Interval", selection: $timerManager.longBreakInterval) {
                                    ForEach(2...6, id: \.self) { i in Text("\(i) sessions").tag(i) }
                                }
                            } label: {
                                Text("\(timerManager.longBreakInterval)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.sageGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.sageGreen.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .padding(16)
                .reverieCardStyle(colorScheme: colorScheme)
            }
        }
    
    // MARK: - Category Section
        private var categorySection: some View {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("CATEGORY")
                
                // 1. The Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 20) {
                    // Filter out 'uncategorized' if you want to force a choice, otherwise keep all
                    ForEach(FocusCategory.allCases, id: \.self) { category in
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                timerManager.selectedCategory = category
                            }
                        } label: {
                            CategoryCircle(category: category, isSelected: timerManager.selectedCategory == category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // 2. Interactive Note Footer
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 14))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                    .padding(.top, 2)

                                ZStack(alignment: .topLeading) {
                                    // Smart Placeholder: Shows description if note is empty
                                    if timerManager.sessionNote.isEmpty {
                                        Text(timerManager.selectedCategory.description)
                                            .font(.system(size: 12, weight: .regular))
                                            .fontDesign(.serif)
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                            .allowsHitTesting(false)
                                    }

                                    // Actual Input
                                    TextField("", text: $timerManager.sessionNote, axis: .vertical)
                                        .font(.system(size: 13, weight: .medium))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                        .tint(Color.sageGreen)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
                                    )
                            )
                            .animation(.snappy, value: timerManager.selectedCategory)
            }
        }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .opacity(0.3)
            
            HStack(spacing: 12) {
                // Cancel
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    soundscapePlayer.stop()
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)
                
                // Start
                Button {
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                    isStartingSession = true
                    timerManager.timeRemaining = timerManager.workDuration * 60
                    timerManager.totalTime = timerManager.timeRemaining
                    onStart()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                        Text("Start Focus")
                            .font(.system(size: 14, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.sageGreen)
                            .shadow(color: Color.sageGreen.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .background(Color.clear)
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.0)
            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
    }
    
    private func settingRow<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

            Spacer()

            content()
        }
        .padding(.vertical, 8)
    }
}
// MARK: - Ruler View

struct RulerView: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let centerColor: Color

    @Environment(\.colorScheme) private var colorScheme

    private var adaptiveTickColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay = TimeOfDay(hour: hour)

        // Use isVisuallyDark to determine if we need light or dark tick marks
        if colorScheme == .dark || timeOfDay.isVisuallyDark {
            // Dark mode or visually dark time periods - use lighter tick marks
            switch timeOfDay {
            case .dusk, .goldenHour:
                return Color.white.opacity(0.45)
            case .deepNight, .evening:
                return Color.white.opacity(0.5)
            default:
                return Color.white.opacity(0.4)
            }
        } else {
            // Light mode with light backgrounds - use darker tick marks
            return Color.primary.opacity(0.3)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let itemWidth: CGFloat = 10

            let centerMargin = (width - itemWidth) / 2

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(range, id: \.self) { i in
                        VStack(alignment: .center, spacing: 0) {
                            Rectangle()
                                .fill(i % 5 == 0 ? adaptiveTickColor : adaptiveTickColor.opacity(0.4))
                                .frame(width: 1, height: i % 5 == 0 ? 20 : 10)
                                .frame(height: 30, alignment: .bottom)
                        }
                        .frame(width: itemWidth)
                        .id(i)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, centerMargin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding(
                get: { value },
                set: { newValue in
                    if let newValue = newValue, newValue != value {
                        value = newValue
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
            ))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Duration Slider")
            .accessibilityValue("\(value) minutes")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: if value < range.upperBound { value += 1 }
                case .decrement: if value > range.lowerBound { value -= 1 }
                @unknown default: break
                }
            }
            
            Rectangle()
                .fill(centerColor)
                .frame(width: 2.5, height: 32)
                .clipShape(Capsule())
                .position(x: width / 2, y: 35)
        }
    }
}

// MARK: - Soundscape Circle

struct SoundscapeCircle: View {
    let soundscape: Soundscape
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected
                          ? AnyShapeStyle(Color.sageGreen.opacity(0.15))
                          : AnyShapeStyle(.ultraThinMaterial))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? Color.sageGreen : Color.primary.opacity(0.05), lineWidth: 1)
                    )

                Image(systemName: soundscape.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.sageGreen : Color.secondary)
            }

            soundscapeLabel
        }
    }

    @ViewBuilder
    private var soundscapeLabel: some View {
        if isSelected {
            Text(soundscape.displayName)
                .font(.system(size: 11, weight: .medium))
                .fontDesign(.serif)
                .foregroundStyle(Color.sageGreen)
                .multilineTextAlignment(.center)
        } else {
            Text(soundscape.displayName)
                .font(.system(size: 11, weight: .medium))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Category Circle

struct CategoryCircle: View {
    let category: FocusCategory
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected
                          ? AnyShapeStyle(category.color.opacity(0.15))
                          : AnyShapeStyle(.ultraThinMaterial))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? category.color : Color.primary.opacity(0.05), lineWidth: 1)
                    )

                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? category.color : Color.secondary)
            }

            categoryLabel
        }
    }

    @ViewBuilder
    private var categoryLabel: some View {
        if isSelected {
            Text(category.rawValue)
                .font(.system(size: 11, weight: .medium))
                .fontDesign(.serif)
                .foregroundStyle(category.color)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(width: 70)
        } else {
            Text(category.rawValue)
                .font(.system(size: 11, weight: .medium))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}
