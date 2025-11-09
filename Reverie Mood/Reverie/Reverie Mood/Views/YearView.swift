import SwiftUI
import SwiftData

// MARK: - YearView (✅ FIXED: Removed audioFileName parameters at lines ~655 & ~773)

struct YearView: View {
    // ✅ FIXED: Use @Query instead of passing entries as parameter
    @Query private var allEntries: [MoodEntry]
    
    let currentYear: Int
    let currentDayOfYear: Int
    @Binding var showQuickAdd: Bool
    @Binding var selectedDay: Int?
    @Binding var currentScreen: ContentView.ScreenType
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ Filter entries for viewed year
    private var entries: [MoodEntry] {
        allEntries.filter { $0.year == viewedYear }
    }
    
    // Quick Add / Carousel state
    @State private var showSuccess = false
    @State private var qaMoodIndex: Int = Mood.allMoods.count / 2
    @State private var qaScrollOffset: CGFloat = 0
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date()) - 1

    // Light-mode entrance drift
    @State private var lightDrift = false
    
    // Year navigation
    @State private var viewedYear: Int
    @State private var dragOffset: CGFloat = 0
    
    // ✅ NEW: Error handling
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(currentYear: Int, currentDayOfYear: Int, showQuickAdd: Binding<Bool>, selectedDay: Binding<Int?>, currentScreen: Binding<ContentView.ScreenType>) {
        self.currentYear = currentYear
        self.currentDayOfYear = currentDayOfYear
        self._showQuickAdd = showQuickAdd
        self._selectedDay = selectedDay
        self._currentScreen = currentScreen
        self._viewedYear = State(initialValue: currentYear)
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
                VStack(spacing: 18) {
                    header
                    if let insight = weeklyInsight {
                        weeklyInsights(insight)
                    }

                    compactProgress
                    yearGrid

                    if !showQuickAdd {
                        statsAndEncouragement
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.25), value: showQuickAdd)
                    }
                }
                .padding(.horizontal)
            }
            // Floating Add Button (only for current year)
            if viewedYear == currentYear && entriesDict[currentDayOfYear] == nil {
                addButton
            }
            
            // Quick Add Overlay
            if showQuickAdd {
                quickAddOverlay
            }
            
            // Success Animation
            if showSuccess { successPuff }
        }
        // ✅ NEW: Error alert
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if colorScheme == .light {
                withAnimation(.easeInOut(duration: 8.0)) { lightDrift = true }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: colorScheme)
    }

    // MARK: - Core Logic & Computed Helpers
    
    private var entriesDict: [Int: MoodEntry] {
        Dictionary(uniqueKeysWithValues: entries.map { ($0.dayOfYear, $0) })
    }
    
    private var weeklyInsight: (mood: Mood, count: Int)? {
        let weekAgo = currentDayOfYear - 7
        let weekEntries = entries.filter { $0.dayOfYear > weekAgo && $0.dayOfYear <= currentDayOfYear }
        guard !weekEntries.isEmpty else { return nil }
        let moodCounts = Dictionary(grouping: weekEntries, by: { $0.moodId })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        guard let top = moodCounts.first,
              let mood = Mood.allMoods.first(where: { $0.id == top.key }) else { return nil }
        return (mood, top.value)
    }
    
    private var encouragementText: String {
        switch entries.count {
        case ..<5: "Every day is a new beginning"
        case ..<20: "You're creating something beautiful ✨"
        case ..<50: "Look how far you've come!"
        default: "Your year is blossoming"
        }
    }
    
    // MARK: - Year Navigation Helpers
    
    /// Check if previous year has any entries
    private func hasPreviousYearData() -> Bool {
        let previousYear = viewedYear - 1
        return allEntries.contains { $0.year == previousYear }
    }
    
    /// Check if we can swipe left (go to next year)
    private var canSwipeLeft: Bool {
        viewedYear < currentYear
    }
    
    /// Check if we can swipe right (go to previous year)
    private var canSwipeRight: Bool {
        hasPreviousYearData()
    }
    
    /// Handle year navigation with swipe gesture
    private func handleYearSwipe(direction: SwipeDirection) {
        switch direction {
        case .left:
            if canSwipeLeft {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    viewedYear += 1
                }
            } else {
                // Haptic feedback for boundary
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        case .right:
            if canSwipeRight {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    viewedYear -= 1
                }
            } else {
                // Haptic feedback for boundary
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }
    
    private enum SwipeDirection {
        case left, right
    }
    
    // MARK: - Header (Updated with Settings Button)
    
    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                // Settings button (top left)
                Button {
                    currentScreen = .settings
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            colorScheme == .dark
                            ? .white.opacity(0.7)
                            : Color(hex: "2D3748").opacity(0.7)
                        )
                        .padding(10)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.5 : 0.7))
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            Text(String(viewedYear))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "2D3748"))
                .shadow(color: colorScheme == .dark ? .purple.opacity(0.25) : .clear, radius: 8, y: 4)
                .offset(x: dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            // Only show visual feedback, don't navigate yet
                            let translation = value.translation.width
                            // Limit drag offset to ±30 for subtle feedback
                            dragOffset = max(-30, min(30, translation * 0.5))
                        }
                        .onEnded { value in
                            let translation = value.translation.width
                            let velocity = value.predictedEndTranslation.width
                            
                            // Reset drag offset
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                            
                            // Determine swipe direction based on translation and velocity
                            if abs(translation) > 50 || abs(velocity) > 100 {
                                if translation < 0 {
                                    // Swiped left → go to next year
                                    handleYearSwipe(direction: .left)
                                } else {
                                    // Swiped right → go to previous year
                                    handleYearSwipe(direction: .right)
                                }
                            }
                        }
                )

            Text("\(entries.count) days captured\(viewedYear < currentYear ? " in \(viewedYear)" : " this year") ✨")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "718096"))
        }
    }

    private func safeAreaTopPadding() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
            .first ?? 16
    }

    private func weeklyInsights(_ insight: (mood: Mood, count: Int)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                Text("This Week's Pattern")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "2D3748"))
            
            HStack(spacing: 10) {
                MoodBlob(mood: insight.mood, size: 40)
                    .shadow(color: colorScheme == .dark ? .white.opacity(0.25) : .clear, radius: 10, y: 3)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Mostly \(insight.mood.name.lowercased())")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "2D3748"))
                    
                    Text("\(insight.count) days this week")
                        .font(.system(size: 11))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "718096"))
                }
            }
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
    
    private var compactProgress: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(entries.count) / 365 days")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "2D3748"))
                Spacer()
                Text("\(Int(Double(entries.count) / 365.0 * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.55) : Color(hex: "718096"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.purple, .blue, .pink], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * (Double(entries.count) / 365.0))
                        .shadow(color: .purple.opacity(0.25), radius: 6, y: 2)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.5 : 0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(colorScheme == .dark ? .white.opacity(0.06) : .white.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(14)
        .padding(.horizontal)
    }
    
    // MARK: - Year Grid (Balanced focus + visible glow)
    private var yearGrid: some View {
        VStack(spacing: 8) {
            // 🌸 Scrollable month selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(Calendar.current.shortMonthSymbols.enumerated()), id: \.offset) { index, month in
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                selectedMonth = index
                            }
                        } label: {
                            VStack(spacing: 3) {
                                Text(month.uppercased())
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(
                                        selectedMonth == index
                                        ? (colorScheme == .dark ? .white : Color(hex: "2D3748"))
                                        : (colorScheme == .dark ? .white.opacity(0.5) : Color(hex: "718096").opacity(0.7))
                                    )
                                    .frame(minWidth: 36)

                                // Underline glow instead of solid bar
                                if selectedMonth == index {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    seasonalGlowColor(for: selectedMonth).opacity(0.5),
                                                    seasonalGlowColor(for: selectedMonth).opacity(0.25)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(height: 3)
                                        .blur(radius: 1)
                                        .shadow(color: seasonalGlowColor(for: selectedMonth).opacity(0.4), radius: 4, y: 1)
                                } else {
                                    Capsule()
                                        .fill(Color.clear)
                                        .frame(height: 3)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .frame(height: 28)

            // 🌙 Background halo under grid
            ZStack {
                if let halo = monthGlow(selectedMonth) {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .dark
                                ? Color.white.opacity(0.10)
                                : seasonalGlowColor(for: selectedMonth).opacity(0.22),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: halo.radius
                    )
                    .frame(height: halo.height)
                    .blur(radius: 80)
                    .offset(y: halo.offset)
                    .animation(.easeInOut(duration: 0.7), value: selectedMonth)
                    .zIndex(0)
                }

                // 🌿 Mood dots grid (balanced spacing)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 26),
                    spacing: 5
                ) {
                    ForEach(1...365, id: \.self) { day in
                        let entry = entriesDict[day]
                        let isToday = day == currentDayOfYear
                        let isPast = day <= currentDayOfYear
                        let dotMonth = monthForDay(day)
                        let isSelected = dotMonth == selectedMonth

                        Button {
                            if isPast {
                                selectedDay = day
                                // ⬇️ If you have a `.viewEntry` case, swap this back to `entry != nil ? .viewEntry : .entry`
                                currentScreen = .entry
                            }
                        } label: {
                            Circle()
                                .fill(entry != nil
                                      ? Color(hex: entry!.moodColor)
                                      : (isPast
                                         ? (colorScheme == .dark ? .white.opacity(0.15) : Color(hex: "E2E8F0"))
                                         : (colorScheme == .dark ? .white.opacity(0.06) : Color(hex: "F7FAFC"))))
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            isToday && entry == nil
                                            ? (colorScheme == .dark ? Color.pink.opacity(0.85) : Color.pink.opacity(0.6))
                                            : .clear,
                                            lineWidth: 1
                                        )
                                )
                                .frame(width: 14, height: 14)
                                .shadow(color: isSelected ? seasonalGlowColor(for: dotMonth).opacity(0.5) : .clear,
                                        radius: isSelected ? 5 : 0)
                                .opacity(isSelected ? 1.0 : 0.6)
                                .animation(.easeInOut(duration: 0.35), value: selectedMonth)
                        }
                        .disabled(!isPast)
                    }
                }
                .padding(.horizontal)
                .zIndex(1)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Month Helpers
    private func monthForDay(_ day: Int) -> Int {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: day - 1,
            to: calendar.date(from: DateComponents(year: currentYear))!)!
        return calendar.component(.month, from: date) - 1
    }

    private func monthGlow(_ month: Int) -> (offset: CGFloat, height: CGFloat, radius: CGFloat)? {
        let monthOffsets: [CGFloat] = [0, 80, 155, 230, 310, 385, 460, 540, 615, 690, 770, 850]
        guard month < monthOffsets.count else { return nil }
        return (offset: monthOffsets[month], height: 140, radius: 500)
    }

    // MARK: - Adaptive Seasonal Glow Color
    private func seasonalGlowColor(for month: Int) -> Color {
        switch month {
        // ❄️ Winter (Dec–Feb)
        case 11, 0, 1:
            return colorScheme == .dark
                ? Color(red: 150/255, green: 190/255, blue: 255/255)  // moonlit ice blue
                : Color(red: 175/255, green: 205/255, blue: 255/255)  // frosty daylight blue

        // 🌸 Spring (Mar–May)
        case 2, 3, 4:
            return colorScheme == .dark
                ? Color(red: 255/255, green: 190/255, blue: 220/255)  // rose dusk
                : Color(red: 255/255, green: 200/255, blue: 225/255)  // morning blush pink

        // ☀️ Summer (Jun–Aug)
        case 5, 6, 7:
            return colorScheme == .dark
                ? Color(red: 255/255, green: 215/255, blue: 180/255)  // candlelight gold
                : Color(red: 255/255, green: 230/255, blue: 180/255)  // bright golden peach

        // 🍂 Autumn (Sep–Nov)
        case 8, 9, 10:
            return colorScheme == .dark
                ? Color(red: 210/255, green: 175/255, blue: 255/255)  // violet dusk
                : Color(red: 220/255, green: 185/255, blue: 255/255)  // lilac haze

        default:
            return colorScheme == .dark
                ? Color(red: 200/255, green: 200/255, blue: 255/255)
                : Color(red: 255/255, green: 210/255, blue: 230/255)
        }
    }

    // MARK: - Stats and Encouragement
    private var statsAndEncouragement: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statRow(value: "\(365 - currentDayOfYear)", label: "Days Ahead", icon: "moonphase.first.quarter", iconColor: .purple)
                
                // 👇 Add your day/year line (compact, same style)
                Text(" \(currentDayOfYear) / 365")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(14)
            .background(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.45 : 0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(colorScheme == .dark ? .white.opacity(0.06) : .white.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(18)
            
            if !entries.isEmpty {
                Text(encouragementText)
                    .font(.system(size: 12))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .gray)
                    .italic()
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 40)
    }
    
    // MARK: - Add Button (✨ Enhanced with Long Press)
    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .shadow(color: .purple.opacity(0.55), radius: 12, y: 6)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                }
                .onTapGesture {
                    // Single tap → Quick add
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showQuickAdd = true
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    // Long press → Full entry view
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedDay = currentDayOfYear
                    currentScreen = .entry
                }
                .padding(.trailing, 20)
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Quick Add Overlay
        
    private var quickAddOverlay: some View {
        ZStack {
            // Blur veil + drifting fog
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.pink.opacity(0.08),
                            Color.purple.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .hueRotation(.degrees(showQuickAdd ? 15 : 0))
                    .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: showQuickAdd)
                )
                .blur(radius: 12)
                .ignoresSafeArea()
                .zIndex(0)
            
            // Aurora wash halo
            RadialGradient(
                colors: [
                    Color.purple.opacity(0.25),
                    Color.pink.opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 60,
                endRadius: 600
            )
            .blendMode(.softLight)
            .ignoresSafeArea()
            .zIndex(1)
            
            // Floating sparkle mist
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    ForEach(0..<12, id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(Double.random(in: 0.15...0.45)))
                            .frame(width: CGFloat.random(in: 1.5...3.5))
                            .blur(radius: CGFloat.random(in: 1...2))
                            .offset(
                                x: CGFloat.random(in: -w/2...w/2),
                                y: CGFloat.random(in: -h/2...h/2)
                            )
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 3...6))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0...2)),
                                value: showQuickAdd
                            )
                    }
                }
                .frame(width: w, height: h)
            }
            .allowsHitTesting(false)
            .zIndex(2)
            
            // Dim layer + dismiss tap
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showQuickAdd = false
                    }
                }
                .zIndex(3)
            
            // Crystal Orb content
            CrystalOrbQuickAdd(
                moods: Mood.allMoods,
                qaMoodIndex: $qaMoodIndex,
                qaScrollOffset: $qaScrollOffset,
                quickSave: { mood in quickSave(mood: mood) },
                dismiss: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showQuickAdd = false
                    }
                },
                openNote: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showQuickAdd = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        selectedDay = currentDayOfYear
                        if let neutralMood = Mood.allMoods.first(where: { $0.name.lowercased() == "okay" }) {
                            // ✅ FIXED: Removed audioFileName: nil parameter (was around line 655)
                            let entry = MoodEntry(
                                dayOfYear: currentDayOfYear,
                                moodId: neutralMood.id,
                                moodName: neutralMood.name,
                                moodColor: neutralMood.color.toHex(),
                                reflection: "",
                                date: Date(),
                                year: currentYear
                            )
                            modelContext.insert(entry)
                        }
                        currentScreen = .entry
                    }
                }
            )
            .zIndex(4)
            .transition(.scale(scale: 0.98).combined(with: .opacity))
            .onAppear {
                qaMoodIndex = Mood.allMoods.count / 2
                qaScrollOffset = 0
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showQuickAdd)
    }

    // MARK: - Success Puff
        
    private var successPuff: some View {
        ZStack {
            // Soft expanding halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.pink.opacity(0.4),
                            Color.purple.opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 15)
                .opacity(showSuccess ? 1 : 0)
                .scaleEffect(showSuccess ? 1.0 : 0.6)
                .animation(.easeOut(duration: 0.6), value: showSuccess)
            
            // Gentle crystal glow core
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 70, height: 70)
                .blur(radius: 8)
                .opacity(showSuccess ? 0.9 : 0)
                .animation(.easeOut(duration: 0.5), value: showSuccess)
            
            // Tiny drifting sparkles
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ForEach(0..<5, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.7)))
                        .frame(width: CGFloat.random(in: 1.2...2.0))
                        .offset(
                            x: CGFloat.random(in: -w/6...w/6),
                            y: CGFloat.random(in: -h/6...h/6)
                        )
                        .opacity(showSuccess ? 1 : 0)
                        .scaleEffect(showSuccess ? 1 : 0.6)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1.0...1.5))
                                .repeatCount(1, autoreverses: true)
                                .delay(Double.random(in: 0...0.2)),
                            value: showSuccess
                        )
                }
            }
            .allowsHitTesting(false)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.purple.opacity(0.3), radius: 6, y: 2)
                .scaleEffect(showSuccess ? 1.0 : 0.3)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSuccess)
        }
        .frame(width: 160, height: 160)
        .opacity(showSuccess ? 1.0 : 0)
        .transition(.opacity)
    }
    
    // MARK: - Helper Components
       
    private func statRow(value: String, label: String, icon: String? = nil, iconColor: Color? = nil) -> some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "2D3748"))
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor ?? (colorScheme == .dark ? .white.opacity(0.7) : .gray))
                        .font(.system(size: 11))
                }
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "718096"))
        }
    }
    
    // MARK: - ✅ FIXED: Actions (removed audioFileName parameter)
    
    private func quickSave(mood: Mood) {
        // ✅ FIXED: Removed audioFileName: nil parameter (was around line 773)
        let entry = MoodEntry(
            dayOfYear: currentDayOfYear,
            moodId: mood.id,
            moodName: mood.name,
            moodColor: mood.color.toHex(),
            reflection: "",
            date: Date(),
            year: currentYear
        )
        modelContext.insert(entry)
        
        // ✅ IMPROVED: Better error handling
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            print("✅ Entry saved successfully!")
            
            showQuickAdd = false
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showSuccess = false
            }
        } catch {
            errorMessage = "Failed to save entry. Please try again."
            showError = true
            print("❌ Failed to save entry: \(error)")
        }
    }
}

// MARK: - COMPLETE REPLACEMENT for CrystalOrbQuickAdd
// This is the "Floating Mood Garden" approach - beautiful and conflict-free!

private struct CrystalOrbQuickAdd: View {
    let moods: [Mood]
    @Binding var qaMoodIndex: Int
    @Binding var qaScrollOffset: CGFloat
    let quickSave: (Mood) -> Void
    let dismiss: () -> Void
    let openNote: () -> Void
    
    private let orbSize: CGFloat = 280
    
    @State private var selectedMood: Mood?
    @State private var breathe = false
    @State private var sparkles: [Sparkle] = []
    private let sparkleCount = 20
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 26) {
                floatingGarden
                hintLine
                Spacer().frame(height: 8)
                actions
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            if sparkles.isEmpty {
                sparkles = (0..<sparkleCount).map { _ in Sparkle.random(in: orbSize) }
            }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
    
    private var floatingGarden: some View {
        ZStack {
            ambientGlow
            sparkleLayer
            moodCircle
            centerLabel
        }
        .frame(width: orbSize, height: orbSize)
        .animation(.interpolatingSpring(stiffness: 180, damping: 20), value: selectedMood?.id)
    }
    
    private var ambientGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.24), Color.purple.opacity(0.18), .clear],
                    center: .center, startRadius: 10, endRadius: 200
                )
            )
            .blur(radius: 22)
            .scaleEffect(breathe ? 1.03 : 1.0)
            .frame(width: orbSize, height: orbSize)
    }
    
    private var sparkleLayer: some View {
        ZStack {
            ForEach(sparkles.indices, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(sparkles[i].intensity))
                    .frame(width: sparkles[i].size, height: sparkles[i].size)
                    .blur(radius: sparkles[i].blur)
                    .offset(x: sparkles[i].x, y: sparkles[i].y)
                    .onAppear { animateSparkle(index: i) }
            }
        }
        .allowsHitTesting(false)
    }
    
    private var moodCircle: some View {
        ForEach(Array(moods.enumerated()), id: \.element.id) { index, mood in
            moodOrb(mood: mood, index: index)
        }
    }
    
    private func moodOrb(mood: Mood, index: Int) -> some View {
        let angle = (Double(index) / Double(moods.count)) * 2 * .pi - .pi / 2
        let radius: CGFloat = selectedMood?.id == mood.id ? 0 : 95
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        let isSelected = selectedMood?.id == mood.id
        let size: CGFloat = isSelected ? 60 : 36
        
        return VStack(spacing: 4) {
            MoodBlob(mood: mood, size: size)
                .shadow(
                    color: isSelected ? .white.opacity(0.5) : .white.opacity(0.2),
                    radius: isSelected ? 20 : 8,
                    y: isSelected ? 4 : 2
                )
            
            if !isSelected {
                Text(mood.name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .offset(x: x, y: y)
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .zIndex(isSelected ? 10 : 1)
        .onTapGesture {
            handleTap(mood: mood)
        }
    }
    
    @ViewBuilder
    private var centerLabel: some View {
        if let selected = selectedMood {
            VStack(spacing: 8) {
                Spacer().frame(height: 75)
                Text(selected.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                
                Text("Tap again to save")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .transition(.opacity)
        }
    }
    
    private var hintLine: some View {
        Text(selectedMood == nil ? "Tap a mood to select" : "Tap again to confirm")
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.65))
            .padding(.top, 6)
            .padding(.bottom, 10)
    }
    
    private var actions: some View {
        VStack(spacing: 10) {
            Button(action: { openNote() }) {
                Text("Quick thought?")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)
            Button("Cancel") { dismiss() }
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
    
    private func handleTap(mood: Mood) {
        if selectedMood?.id == mood.id {
            // Already selected → Save
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            quickSave(mood)
        } else {
            // Select this mood
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) {
                selectedMood = mood
            }
        }
    }
    
    private func animateSparkle(index i: Int) {
        let period = Double.random(in: 3.0...6.0)
        withAnimation(.easeInOut(duration: period).repeatForever(autoreverses: true)) {
            sparkles[i].drift()
        }
    }
    
    struct Sparkle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var blur: CGFloat
        var intensity: Double
        var dx: CGFloat
        var dy: CGFloat
        
        mutating func drift() { x += dx; y += dy }
        
        static func random(in orb: CGFloat) -> Sparkle {
            Sparkle(
                x: CGFloat.random(in: -orb * 0.35 ... orb * 0.35),
                y: CGFloat.random(in: -orb * 0.35 ... orb * 0.35),
                size: CGFloat.random(in: 1.6...3.4),
                blur: CGFloat.random(in: 1.2...3.2),
                intensity: Double.random(in: 0.35...0.9),
                dx: CGFloat.random(in: -6...6) / 10,
                dy: CGFloat.random(in: -6...6) / 10
            )
        }
    }
}
