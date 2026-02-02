//
// LandscapeTimerView.swift
// ReverieWeaver
//
// - Resume button calls resumeTimer() instead of startTimer()
// - Break state indicators (SHORT BREAK / LONG BREAK / PAUSED)
// - Session progress display (Quick Focus vs Session 2/4)
// - Auto-hide controls after 5s inactivity
// - Completion pulse animation
// - Skip break button
// - Swipe to dismiss gesture
// - Smooth state transition animations
// - Proper timer cleanup on dismiss
// - Soundscape picker handles selection changes correctly
//

import SwiftUI
import AVFoundation
import Combine

struct LandscapeTimerView: View {
    @Bindable var timerManager: PomodoroTimerManager
    @Bindable var soundscapePlayer: SoundscapePlayer
    @Environment(\.dismiss) private var dismiss
    
    // UI State
    @State private var showControls = true
    @State private var showSettings = false
    @State private var showVolumeControl = false
    @State private var showCategoryPicker = false
    
    // Breathing Animation State
    @State private var breathScale: CGFloat = 1.0
    @State private var breathOpacity: Double = 1.0
    
    @State private var breathingTimerCancellable: AnyCancellable?
    @State private var autoHideWorkItem: DispatchWorkItem?
    
    @State private var completionPulseScale: CGFloat = 1.0
    @State private var completionPulseOpacity: Double = 0.0
    
    @State private var stateTransitionOpacity: Double = 1.0
    
    private let autoHideDelay: TimeInterval = 5.0
    
    var body: some View {
        ZStack {
            // 1. Pure Black Background
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    handleBackgroundTap()
                }
           
            completionPulseOverlay
            
            VStack(spacing: 0) {
                // Top Bar
                if showControls {
                    topBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.horizontal, 48)
                        .padding(.top, 24)
                }
                
                Spacer()
                
                // Center Timer
                centerTimer
                    .opacity(stateTransitionOpacity)
                
                Spacer()
                
                // Bottom Bar
                if showControls {
                    bottomBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 48)
                        .padding(.bottom, 24)
                }
            }
        }
        .persistentSystemOverlays(.hidden)
        .statusBar(hidden: true)
        // Swipe down to dismiss
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
        .sheet(isPresented: $showSettings) {
            DarkLandscapeSettingsSheet(timerManager: timerManager)
        }
        .onAppear {
                    startBreathingAnimation()
                    resetAutoHideTimer()
                    completionPulseOpacity = 0.0
                    completionPulseScale = 1.0
                    
                    if soundscapePlayer.selectedSoundscape != .none &&
                       !soundscapePlayer.isCurrentlyPlaying &&
                       timerManager.timerState != .idle {
                        soundscapePlayer.play()
                    }
                }
        .onDisappear {
                    breathingTimerCancellable?.cancel()
                    breathingTimerCancellable = nil
                    autoHideWorkItem?.cancel()
                    autoHideWorkItem = nil
                }
                .onChange(of: timerManager.chimeEnabled) { _, _ in
                    timerManager.updateAudioState()
                }
                .onChange(of: timerManager.backgroundMusicVolume) { _, newVolume in
                    timerManager.setBackgroundMusicVolume(newVolume)
                }
        .onChange(of: timerManager.timerState) { oldState, newState in
            handleStateChange(from: oldState, to: newState)
        }
        .onChange(of: timerManager.showCompletionToast) { _, showToast in
            if showToast {
                triggerCompletionPulse()
            }
        }
    }
    
    // MARK: - Background Tap Handler
    private func handleBackgroundTap() {
        if showVolumeControl {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showVolumeControl = false
            }
        } else if showCategoryPicker {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showCategoryPicker = false
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
            
            if showControls {
                resetAutoHideTimer()
            }
        }
    }
    
    // MARK: - Timer Management
    
    private func startBreathingAnimation() {
        breathingTimerCancellable = Timer.publish(every: 4, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                animateBreath()
            }
    }
    
    private func resetAutoHideTimer() {
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil
        
        guard timerManager.timerState == .running ||
              timerManager.timerState == .shortBreak ||
              timerManager.timerState == .longBreak else {
            return
        }
        
        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.5)) {
                showControls = false
            }
        }
        
        autoHideWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + autoHideDelay, execute: workItem)
    }
    
    // MARK: - State Change Handler
    
    private func handleStateChange(from oldState: TimerState, to newState: TimerState) {
        // Animate state transition
        withAnimation(.easeInOut(duration: 0.3)) {
            stateTransitionOpacity = 0.7
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.3)) {
                stateTransitionOpacity = 1.0
            }
        }
        
        if newState != .running {
            breathScale = 1.0
            breathOpacity = 1.0
        } else {
            animateBreath()
        }
        
        resetAutoHideTimer()
    }
    
    private func triggerCompletionPulse() {
        completionPulseScale = 1.0
        completionPulseOpacity = 0.6
        
        withAnimation(.easeOut(duration: 1.5)) {
            completionPulseScale = 2.5
            completionPulseOpacity = 0.0
        }
    }
    
    // MARK: - Completion Pulse Overlay
    
    private var completionPulseOverlay: some View {
        Circle()
            .fill(timerManager.timerState.color.opacity(0.3))
            .frame(width: 200, height: 200)
            .scaleEffect(completionPulseScale)
            .opacity(completionPulseOpacity)
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 24) {
            // 1. Soundscape Menu (Left)
            Menu {
                Picker("Soundscape", selection: $soundscapePlayer.selectedSoundscape) {
                    ForEach(Soundscape.allCases, id: \.self) { soundscape in
                        Label(soundscape.displayName, systemImage: soundscape.icon)
                            .tag(soundscape)
                    }
                }
            } label: {
                GlassCircleButton(
                    icon: soundscapePlayer.selectedSoundscape.icon,
                    isActive: soundscapePlayer.selectedSoundscape != .none
                )
            }
            .onChange(of: soundscapePlayer.selectedSoundscape) { oldValue, newValue in
                            // Only trigger playback when selection actually changes
                            guard oldValue != newValue else { return }
                            
                            if newValue == .none {
                                soundscapePlayer.stop()
                            } else {
                                soundscapePlayer.play()
                            }
                            resetAutoHideTimer()
                        }
            if soundscapePlayer.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else if soundscapePlayer.hasError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 14))
            }
            
            Spacer()
            
            // 2. Settings Button
            Button {
                showSettings = true
                resetAutoHideTimer()
            } label: {
                GlassCircleButton(icon: "gearshape.fill", isActive: false)
            }
            
            // 3. Background Music Control
            ZStack(alignment: .top) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    
                    if !showVolumeControl && !timerManager.chimeEnabled {
                        timerManager.chimeEnabled = true
                    }
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showVolumeControl.toggle()
                    }
                    resetAutoHideTimer()
                } label: {
                    GlassCircleButton(
                        icon: timerManager.chimeEnabled ? "music.note" : "music.note.slash",
                        isActive: timerManager.chimeEnabled
                    )
                }
                
                if showVolumeControl {
                    CustomVerticalSlider(
                        volume: $timerManager.backgroundMusicVolume,
                        isEnabled: $timerManager.chimeEnabled
                    )
                    .offset(y: 54)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                    .zIndex(100)
                }
            }
        }
    }
    
    // MARK: - Center Timer
    
    private var centerTimer: some View {
        VStack(spacing: 4) {
            Text(timerManager.formattedTime)
                .font(.system(size: 160, weight: .thin, design: .rounded))
                .foregroundStyle(currentStateColor)
                .monospacedDigit()
                .scaleEffect(timerManager.timerState == .running ? breathScale : 1.0)
                .opacity(timerManager.timerState == .running ? breathOpacity : 1.0)
                .animation(.easeInOut(duration: 2.0), value: breathScale)
                .animation(.easeInOut(duration: 2.0), value: breathOpacity)
                .animation(.easeInOut(duration: 0.5), value: currentStateColor)
            
            stateInfoView
        }
    }
    
    private var currentStateColor: Color {
        switch timerManager.timerState {
        case .idle, .paused:
            return .white
        case .running:
            return .white
        case .shortBreak:
            return Color.dustyBlue.opacity(0.9)
        case .longBreak:
            return Color.paleMauve.opacity(0.9)
        }
    }
    
    @ViewBuilder
    private var stateInfoView: some View {
        VStack(spacing: 4) {
            // State indicator
            HStack(spacing: 8) {
                // State icon
                Image(systemName: stateIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(stateIndicatorColor)
                
                // State text
                Text(stateIndicatorText)
                    .font(.system(size: 13, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(stateIndicatorColor)
            }
            .animation(.easeInOut(duration: 0.3), value: timerManager.timerState)
            
            // Category (shown for all active states)
            if timerManager.timerState != .idle {
                Text(timerManager.selectedCategory.rawValue.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .tracking(1.5)
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            
            // Subject (if specified)
            if !timerManager.sessionNote.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(timerManager.sessionNote)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .lineLimit(1)
            }
        }
        .padding(.top, 8)
    }
    
    private var stateIcon: String {
        switch timerManager.timerState {
        case .idle: return "circle"
        case .running: return "circle.fill"
        case .paused: return "pause.circle.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }
    
    private var stateIndicatorText: String {
        switch timerManager.timerState {
        case .idle: return "READY"
        case .running: return "FOCUSING"
        case .paused: return "PAUSED"
        case .shortBreak: return "SHORT BREAK"
        case .longBreak: return "LONG BREAK"
        }
    }
    
    private var stateIndicatorColor: Color {
        switch timerManager.timerState {
        case .idle: return .white.opacity(0.5)
        case .running: return .sageGreen.opacity(0.8)
        case .paused: return .white.opacity(0.5)
        case .shortBreak: return .dustyBlue.opacity(0.8)
        case .longBreak: return .paleMauve.opacity(0.8)
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            // 1. Category Info with Quick Picker
            ZStack(alignment: .bottom) {
                HStack(spacing: 12) {
                    // Tappable category icon
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCategoryPicker.toggle()
                        }
                        resetAutoHideTimer()
                    } label: {
                        Image(systemName: timerManager.selectedCategory.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(timerManager.selectedCategory.color)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Session progress based on mode
                    Text(sessionProgressText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                // Category Quick Picker
                if showCategoryPicker {
                    CategoryQuickPicker(
                        selectedCategory: $timerManager.selectedCategory,
                        onSelect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCategoryPicker = false
                            }
                            resetAutoHideTimer()
                        }
                    )
                    .offset(y: -70)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
                }
            }
            
            Spacer()
            
            // 2. Controls
            HStack(spacing: 16) {
                // Skip Break Button (during breaks only)
                if timerManager.timerState == .shortBreak || timerManager.timerState == .longBreak {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        timerManager.skipToBreak()
                        resetAutoHideTimer()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 14))
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Main control button
                mainControlButton
                
                // Stop button (only visible when PAUSED)
                if timerManager.timerState == .paused {
                    Button {
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.warning)
                        timerManager.stopTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: timerManager.timerState)
        }
    }
    
    private var sessionProgressText: String {
        switch timerManager.sessionMode {
        case .quickFocus:
            return "Quick Focus"
        case .fullPomodoro:
            let current = timerManager.currentCyclePosition
            let total = timerManager.totalCycles
            return "Session \(current)/\(total)"
        }
    }
    
    private var mainControlButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            switch timerManager.timerState {
            case .running:
                timerManager.pauseTimer()
            case .paused:
                timerManager.resumeTimer()
            case .shortBreak, .longBreak:
                timerManager.pauseTimer()
            case .idle:
                timerManager.startTimer()
            }
            resetAutoHideTimer()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: controlButtonIcon)
                    .font(.system(size: 20))
                
                Text(controlButtonText)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .frame(width: 140, height: 56)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
            )
        }
    }
    
    private var controlButtonIcon: String {
        switch timerManager.timerState {
        case .running, .shortBreak, .longBreak:
            return "pause.fill"
        case .paused, .idle:
            return "play.fill"
        }
    }
    
    private var controlButtonText: String {
        switch timerManager.timerState {
        case .running, .shortBreak, .longBreak:
            return "Pause"
        case .paused:
            return "Resume"
        case .idle:
            return "Start"
        }
    }
    
    // MARK: - Breathing Animation
    
    private func animateBreath() {
        guard timerManager.timerState == .running else {
            breathScale = 1.0
            breathOpacity = 1.0
            return
        }
        withAnimation(.easeInOut(duration: 2.0)) {
            breathScale = 1.02
            breathOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 2.0)) {
                breathScale = 1.0
                breathOpacity = 0.75
            }
        }
    }
}

// MARK: - Helper Views

struct GlassCircleButton: View {
    let icon: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isActive ? Color.sageGreen.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
            
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(isActive ? Color.sageGreen : Color.white.opacity(0.8))
        }
    }
}

// MARK: - Custom Vertical Slider

struct CustomVerticalSlider: View {
    @Binding var volume: Float
    @Binding var isEnabled: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                
                Capsule()
                    .fill(Color.sageGreen)
                    .frame(height: height * CGFloat(volume))
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: volume)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let dragY = value.location.y
                        let percentage = 1.0 - (dragY / height)
                        let newVolume = Float(min(max(percentage, 0), 1))
                        
                        self.volume = newVolume
                        
                        if newVolume > 0.05 && !isEnabled {
                            isEnabled = true
                            #if DEBUG
                            print("🎚️ Volume slider enabled music: \(Int(newVolume * 100))%")
                            #endif
                        } else if newVolume <= 0.05 && isEnabled {
                            isEnabled = false
                            #if DEBUG
                            print("🎚️ Volume slider disabled music")
                            #endif
                        }
                    }
            )
        }
        .frame(width: 28, height: 160)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

// MARK: - Category Quick Picker

struct CategoryQuickPicker: View {
    @Binding var selectedCategory: FocusCategory
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(FocusCategory.allCases.filter { $0 != .uncategorized }, id: \.self) { category in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    
                    selectedCategory = category
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onSelect()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedCategory == category
                                            ? Color.sageGreen.opacity(0.6)
                                            : Color.white.opacity(0.1),
                                        lineWidth: selectedCategory == category ? 2 : 1
                                    )
                            )
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(
                                selectedCategory == category
                                    ? Color.sageGreen
                                    : Color.white.opacity(0.8)
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                .shadow(color: Color.black.opacity(0.4), radius: 20, y: 10)
        )
    }
}

// MARK: - Dark Settings Sheet

struct DarkLandscapeSettingsSheet: View {
    @Bindable var timerManager: PomodoroTimerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 24) {
                Text("Settings")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        subjectInputSection
                        
                        HStack {
                            Text("Enable Long Breaks")
                                .foregroundStyle(.white.opacity(0.6))
                                .font(.system(size: 13))
                                .tracking(1)
                            Spacer()
                            Toggle("", isOn: $timerManager.isLongBreakEnabled)
                                .labelsHidden()
                                .tint(Color.sageGreen)
                        }
                        
                        darkSettingRow("Short Break", value: $timerManager.shortBreakDuration, options: [3, 5, 10])
                        darkSettingRow("Focus Cycles", value: $timerManager.totalCycles, options: [2, 3, 4, 5])
                        
                        if timerManager.isLongBreakEnabled {
                            darkSettingRow("Long Break", value: $timerManager.longBreakDuration, options: [10, 15, 20, 25])
                            darkSettingRow("Long Break After", value: $timerManager.longBreakInterval, options: [2, 3, 4, 5, 6])
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Button("Done") { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 120, height: 44)
                    .background(Capsule().fill(Color.white))
                    .padding(.bottom, 20)
            }
        }
    }
    
    private var subjectInputSection: some View {
        VStack(spacing: 10) {
            Text("SUBJECT")
                .foregroundStyle(.white.opacity(0.6))
                .font(.system(size: 13))
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack(alignment: .leading) {
                if timerManager.sessionNote.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("What are you focusing on?")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.3))
                }
                
                TextField("", text: $timerManager.sessionNote)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .tint(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .frame(maxWidth: 400)
    }
    
    private func darkSettingRow(_ title: String, value: Binding<Int>, options: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .foregroundStyle(.white.opacity(0.6))
                .font(.system(size: 13))
                .tracking(1)
            
            HStack {
                ForEach(options, id: \.self) { opt in
                    Button {
                        withAnimation { value.wrappedValue = opt }
                    } label: {
                        Text("\(opt)")
                            .font(.system(size: 14, weight: value.wrappedValue == opt ? .bold : .regular))
                            .foregroundStyle(value.wrappedValue == opt ? .black : .white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(value.wrappedValue == opt ? Color.white : Color.white.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
