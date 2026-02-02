//
//  RadioTunerView.swift
//  Reverie Mood
//
//

import SwiftUI
import OSLog

private let radioTunerLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "RadioTuner")

// MARK: - Radio Tuner View

struct RadioTunerView: View {
    let sounds: [AmbientSound]
    @Binding var selectedSound: AmbientSound?
    @Binding var selectedCategory: SoundCategory?
    let onPlay: (AmbientSound) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Tuner state
    @State private var tunerOffset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var lastTickedStation: String? = nil
    
    // Animation
    @State private var indicatorGlow = false
    @State private var isInitialized = false
    
    // Tuner dimensions
    private let tunerHeight: CGFloat = 140
    private let bandHeight: CGFloat = 100
    
    // FM band range
    private let minFrequency: Double = 86.0
    private let maxFrequency: Double = 110.0
    private let pixelsPerMHz: CGFloat = 40
    
    private var bandWidth: CGFloat {
        CGFloat(maxFrequency - minFrequency) * pixelsPerMHz
    }
    
    private var filteredSounds: [AmbientSound] {
        if let category = selectedCategory {
            return sounds.filter { $0.category == category }
        }
        return sounds
    }
    
    var body: some View {
        VStack(spacing: ReverieLayout.spacing16) {
            categoryTabs
            
            if !filteredSounds.isEmpty {
                tunerDisplay
                
                if let sound = selectedSound {
                    stationInfoCard(sound)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: selectedSound?.id)
                }
            } else {
                // Fallback for empty state
                emptyStateView
            }
        }
        .onAppear {
            if !isInitialized {
                initializeTuner()
                isInitialized = true
            }
            startGlowAnimation()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Radio tuner interface")
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ReverieLayout.spacing8) {
                categoryTab(nil, label: "ALL", icon: "radio.fill")
                
                ForEach(SoundCategory.allCases, id: \.self) { category in
                    categoryTab(category, label: shortLabel(for: category), icon: category.icon)
                }
            }
            .padding(.horizontal, ReverieLayout.spacing8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sound category filters")
    }
    
    private func categoryTab(_ category: SoundCategory?, label: String, icon: String) -> some View {
        let isSelected = selectedCategory == category
        
        return Button {
            ReverieHaptics.light()
            
            // Update category immediately without animation for tuner offset
            selectedCategory = category
            
            if let current = selectedSound {
                let newFiltered = category == nil ? sounds : sounds.filter { $0.category == category }
                if !newFiltered.contains(where: { $0.id == current.id }) {
                    selectedSound = newFiltered.first
                    if let sound = selectedSound {
                        updateTunerOffset(for: sound)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.5)
            }
            .foregroundColor(isSelected ? .white : ReverieColors.textSecondary(colorScheme))
            .padding(.horizontal, ReverieLayout.spacing10)
            .padding(.vertical, ReverieLayout.spacing6)
            .background(
                Capsule()
                    .fill(isSelected
                        ? ReverieColors.accentTeal(colorScheme)
                        : ReverieColors.surfaceRecessed(colorScheme))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected
                        ? ReverieColors.accentTeal(colorScheme)
                        : ReverieColors.border(colorScheme),
                        lineWidth: 1)
            )
        }
        .accessibilityLabel("\(label) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Selected" : "Double tap to filter by \(label)")
    }
    
    private func shortLabel(for category: SoundCategory) -> String {
        switch category {
        case .nature: return "NATURE"
        case .focus: return "FOCUS"
        case .ambient: return "AMBIENT"
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: ReverieLayout.spacing16) {
            Image(systemName: "radio")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
            
            Text("No stations available")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
            
            Text("Try selecting a different category")
                .font(.system(size: 12))
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(ReverieLayout.spacing32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No stations available. Try selecting a different category")
    }
    
    // MARK: - Tuner Display
    
    private var tunerDisplay: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1a1a1a"),
                                Color(hex: "2d2d2d"),
                                Color(hex: "1a1a1a")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.8),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                
                GeometryReader { geometry in
                    let width = geometry.size.width
                    
                    if width > 50 {
                        let centerX = width / 2
                        
                        ZStack {
                            frequencyBand
                                .offset(x: -tunerOffset + centerX)
                            
                            tunerIndicator
                                .position(x: centerX, y: bandHeight / 2 + 10)
                            
                            scanLines
                        }
                        .gesture(dragGesture(centerX: centerX))
                    }
                }
                .frame(height: bandHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(6)
            }
            .frame(height: tunerHeight)
            
            HStack {
                Text("FM TUNER")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))
                
                Spacer()
                
                if isDragging {
                    Text("TUNING...")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(ReverieColors.accentGold(colorScheme))
                }
            }
            .padding(.horizontal, ReverieLayout.spacing4)
            .padding(.top, ReverieLayout.spacing4)
        }
    }
    
    // MARK: - Frequency Band
    
    private var frequencyBand: some View {
        ZStack(alignment: .top) {
            Canvas { context, size in
                for freq in stride(from: minFrequency, through: maxFrequency, by: 0.5) {
                    let x = CGFloat(freq - minFrequency) * pixelsPerMHz
                    let isMajor = freq.truncatingRemainder(dividingBy: 2) == 0
                    let isLabel = freq.truncatingRemainder(dividingBy: 4) == 0 && freq >= 88 && freq <= 108
                    
                    let tickHeight: CGFloat = isMajor ? 16 : 8
                    let tickPath = Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: tickHeight))
                    }
                    context.stroke(
                        tickPath,
                        with: .color(Color.white.opacity(isMajor ? 0.6 : 0.3)),
                        lineWidth: isMajor ? 1.5 : 1
                    )
                    
                    if isLabel {
                        let text = Text("\(Int(freq))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        context.draw(text, at: CGPoint(x: x, y: 28))
                    }
                }
            }
            .frame(width: bandWidth, height: 40)
            
            // FM/MHZ labels
            HStack {
                Text("FM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(x: 20)
                
                Spacer()
                
                Text("MHZ")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(x: -20)
            }
            .frame(width: bandWidth)
            .offset(y: 6)
            
            stationIcons
                .offset(y: 45)
        }
        .frame(width: bandWidth, height: bandHeight)
    }
    
    // MARK: - Station Icons
    
    private var stationIcons: some View {
        ZStack(alignment: .leading) {
            ForEach(filteredSounds) { sound in
                let freq = Double(sound.frequency) ?? 91.7
                let xPos = CGFloat(freq - minFrequency) * pixelsPerMHz
                let isSelected = selectedSound?.id == sound.id
                
                stationIcon(sound: sound, isSelected: isSelected)
                    .position(x: xPos, y: 25)
            }
        }
        .frame(width: bandWidth, height: 50)
    }
    
    private func stationIcon(sound: AmbientSound, isSelected: Bool) -> some View {
        VStack(spacing: 2) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(sound.themeColor.opacity(0.4))
                        .frame(width: 40, height: 40)
                        .blur(radius: 8)
                }
                
                Circle()
                    .fill(isSelected ? sound.themeColor : Color(hex: "3a3a3a"))
                    .frame(width: isSelected ? 36 : 30, height: isSelected ? 36 : 30)
                
                Image(systemName: sound.icon)
                    .font(.system(size: isSelected ? 16 : 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : sound.themeColor)
            }
            
            Text(sound.frequency)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? sound.themeColor : .white.opacity(0.5))
        }
        .onTapGesture {
            selectStation(sound)
        }
        .accessibilityLabel("\(sound.name), \(sound.frequency) FM")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Tuner Indicator
    
    private var tunerIndicator: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "DC2626").opacity(indicatorGlow ? 0.6 : 0.3))
                .frame(width: 8, height: max(1, bandHeight - 20))
                .blur(radius: 6)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "DC2626").opacity(0.8),
                            Color(hex: "FF4444"),
                            Color(hex: "DC2626").opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 3, height: max(1, bandHeight - 20))
            
            Triangle()
                .fill(Color(hex: "DC2626"))
                .frame(width: 12, height: 8)
                .offset(y: -max(1, (bandHeight - 20) / 2) - 4)
        }
    }
    
    // MARK: - Scan Lines
    
    private var scanLines: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 3) {
                let linePath = Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(linePath, with: .color(Color.black.opacity(0.15)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Station Info Card (Editorial Style - Matches Listener's Guide)
    
    private func stationInfoCard(_ sound: AmbientSound) -> some View {
        VStack(alignment: .leading, spacing: ReverieLayout.spacing12) {
            HStack(spacing: ReverieLayout.spacing8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 12, weight: .semibold))
                Text("STATION SELECTED")
                    .font(ReverieTypography.labelSmall)
                    .tracking(2)
            }
            .foregroundColor(ReverieColors.accentGold(colorScheme))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Station selected")
            
            Rectangle()
                .fill(ReverieColors.divider(colorScheme))
                .frame(height: 1)
                .accessibilityHidden(true)
            
            HStack(alignment: .top, spacing: ReverieLayout.spacing12) {
                Image(systemName: sound.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(sound.themeColor)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(sound.name)
                            .font(.custom("Georgia-Bold", size: 15))
                            .foregroundColor(ReverieColors.textPrimary(colorScheme))
                        
                        Spacer()
                        
                        Text(sound.frequency)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(ReverieColors.textPrimary(colorScheme))
                        Text("FM")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(ReverieColors.textTertiary(colorScheme))
                    }
                    
                    HStack(spacing: ReverieLayout.spacing6) {
                        Text(sound.callLetters)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(sound.themeColor)
                        
                        Text("\u{2022}")
                            .font(.system(size: 8))
                            .foregroundColor(ReverieColors.textTertiary(colorScheme))
                        
                        Text(sound.category.rawValue.capitalized)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(ReverieColors.textTertiary(colorScheme))
                    }
                    
                    Text("\"\(sound.description)\"")
                        .font(.custom("Georgia-Italic", size: 12))
                        .foregroundColor(ReverieColors.textSecondary(colorScheme))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 2)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(sound.name), \(sound.frequency) FM, \(sound.callLetters), \(sound.category.rawValue.capitalized). \(sound.description)")
            
            Button {
                ReverieHaptics.success()
                onPlay(sound)
            } label: {
                HStack(spacing: ReverieLayout.spacing6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("TUNE IN")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                }
                .foregroundColor(.white)
                .padding(.horizontal, ReverieLayout.spacing20)
                .padding(.vertical, ReverieLayout.spacing8)
                .background(
                    Capsule()
                        .fill(sound.themeColor)
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, ReverieLayout.spacing4)
            .accessibilityLabel("Tune in to \(sound.name)")
            .accessibilityHint("Double tap to start playing this station")
        }
        .padding(ReverieLayout.spacing16)
        .background(cardBackground())
        .accessibilityElement(children: .contain)
    }
    
    @ViewBuilder
    private func cardBackground() -> some View {
        ReverieCardSurface()
    }
    
    // MARK: - Drag Gesture
    
    private func dragGesture(centerX: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    lastOffset = tunerOffset
                }
                
                let newOffset = lastOffset - value.translation.width
                let minOffset = offsetForFrequency(88.0) - 50
                let maxOffset = offsetForFrequency(108.0) + 50
                tunerOffset = max(minOffset, min(maxOffset, newOffset))
                
                checkStationCrossing()
            }
            .onEnded { _ in
                isDragging = false
                snapToNearestStation()
            }
    }
    
    // MARK: - Helpers
    
    private func checkStationCrossing() {
        guard !filteredSounds.isEmpty else { return }
        
        let currentFreq = frequencyAtOffset(tunerOffset)
        
        var closestSound: AmbientSound? = nil
        var closestDistance: Double = .infinity
        
        for sound in filteredSounds {
            guard let freq = Double(sound.frequency) else {
                radioTunerLogger.warning("Invalid frequency for sound: \(sound.name)")
                continue
            }
            let distance = abs(freq - currentFreq)
            if distance < closestDistance {
                closestDistance = distance
                closestSound = sound
            }
        }
        
        let snapThreshold: Double = 1.5
        
        if let sound = closestSound, closestDistance < snapThreshold {
            if lastTickedStation != sound.id {
                ReverieHaptics.light()
                lastTickedStation = sound.id
                selectedSound = sound
            }
        }
    }
    
    private func snapToNearestStation() {
        guard !filteredSounds.isEmpty else {
            radioTunerLogger.warning("Cannot snap: no filtered sounds available")
            return
        }
        
        guard let sound = selectedSound,
              let freq = Double(sound.frequency) else {
            findAndSelectNearest()
            return
        }
        
        // Animate only the tuner offset
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            tunerOffset = offsetForFrequency(freq)
        }
        ReverieHaptics.medium()
    }
    
    private func findAndSelectNearest() {
        guard !filteredSounds.isEmpty else {
            radioTunerLogger.warning("Cannot find nearest: no filtered sounds available")
            return
        }
        
        let currentFreq = frequencyAtOffset(tunerOffset)
        var closestSound: AmbientSound? = nil
        var closestDistance: Double = .infinity
        
        for s in filteredSounds {
            guard let f = Double(s.frequency) else {
                radioTunerLogger.warning("Invalid frequency for sound: \(s.name)")
                continue
            }
            let distance = abs(f - currentFreq)
            if distance < closestDistance {
                closestDistance = distance
                closestSound = s
            }
        }
        
        if let closest = closestSound, let closestFreq = Double(closest.frequency) {
            // Update selected sound immediately
            selectedSound = closest
            
            // Animate only the tuner offset
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                tunerOffset = offsetForFrequency(closestFreq)
            }
            ReverieHaptics.medium()
        } else {
            radioTunerLogger.error("Failed to find nearest station")
        }
    }
    
    private func selectStation(_ sound: AmbientSound) {
        guard let freq = Double(sound.frequency) else {
            radioTunerLogger.error("Cannot select station: invalid frequency for \(sound.name)")
            return
        }
        
        ReverieHaptics.medium()
        
        // Update immediately to prevent animation conflicts
        selectedSound = sound
        
        // Animate only the tuner offset smoothly
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            tunerOffset = offsetForFrequency(freq)
        }
    }
    
    private func offsetForFrequency(_ freq: Double) -> CGFloat {
        let clampedFreq = max(minFrequency, min(maxFrequency, freq))
        return CGFloat(clampedFreq - minFrequency) * pixelsPerMHz
    }
    
    private func frequencyAtOffset(_ offset: CGFloat) -> Double {
        let freq = minFrequency + Double(offset) / Double(pixelsPerMHz)
        return max(minFrequency, min(maxFrequency, freq))
    }
    
    private func updateTunerOffset(for sound: AmbientSound) {
        if let freq = Double(sound.frequency) {
            tunerOffset = offsetForFrequency(freq)
        } else {
            radioTunerLogger.warning("Cannot update tuner offset: invalid frequency for \(sound.name)")
        }
    }
    
    private func initializeTuner() {
        guard !filteredSounds.isEmpty else {
            radioTunerLogger.warning("Cannot initialize tuner: no filtered sounds available")
            return
        }
        
        let initialSound = selectedSound ?? filteredSounds.first
        
        if let sound = initialSound,
           let freq = Double(sound.frequency) {
            selectedSound = sound
            tunerOffset = offsetForFrequency(freq)
            lastTickedStation = sound.id
            radioTunerLogger.info("Tuner initialized to \(sound.name) at \(freq) FM")
        } else {
            radioTunerLogger.error("Failed to initialize tuner: no valid frequency found")
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            indicatorGlow = true
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Radio Tuner") {
    ZStack {
        Color(hex: "F5EDE3").ignoresSafeArea()
        
        RadioTunerView(
            sounds: AmbientSound.allSounds,
            selectedSound: .constant(AmbientSound.allSounds[0]),
            selectedCategory: .constant(nil),
            onPlay: { _ in }
        )
        .padding()
    }
}
