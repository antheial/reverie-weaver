//
//  MainTabView.swift (PRODUCTION READY)
//  ReverieWeaver
//
//  ✅ PRODUCTION ENHANCEMENTS:
//  - Proper safe area handling for all devices
//  - Haptic feedback on tab changes
//  - State persistence (remembers last tab)
//  - Accessibility labels and hints
//  - Time-adaptive tab bar colors
//  - iPad optimization
//  - Smooth animations
//  - Proper z-index management
//  - Integrated onboarding flow
//

import SwiftUI
import SwiftData
import UserNotifications

struct MainTabView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("hasRequestedNotificationPermission") private var hasRequestedPermission = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ FIX: Query habits and completions for Project 50 tracking
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    
    @State private var showOnboarding = false
    
    init() {
        // Hide default tab bar
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // ✅ Beautiful time-based background
            ReverieWeaverBackground()
            
            // Main content with proper tab animation
            TabView(selection: $selectedTab) {
                DeskView()
                    .tag(0)
                
                LoomView()
                    .tag(1)
                
                ArchiveView()
                    .tag(2)
                
                ProfileView()
                    .tag(3)
            }
            .onChange(of: selectedTab) { _, newValue in
                // ✅ PRODUCTION: Haptic feedback on tab change
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
            
            // Custom floating tab bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, bottomPadding)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .task {
            // Check if onboarding should be shown
            if !hasCompletedOnboarding {
                // Small delay to ensure smooth transition
                try? await Task.sleep(for: .milliseconds(100))
                showOnboarding = true
            }
            
            // ⚡️ OPTIMIZED: Run expensive operations in background
            await initializeMainTab()
        }
    }
    
    // MARK: - Initialization
    
    /// ⚡️ OPTIMIZED: Centralized async initialization
    private func initializeMainTab() async {
        // Run all initialization tasks concurrently
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Notification permission (only if onboarding is complete and not yet requested)
            // Note: Onboarding now handles the first request
            if hasCompletedOnboarding && !hasRequestedPermission {
                group.addTask {
                    // Mark as requested since onboarding should have handled it
                    await MainActor.run {
                        self.hasRequestedPermission = true
                    }
                }
            }
            
            // Task 2: Project50 tracking setup (no await needed, synchronous)
            group.addTask { @MainActor in
                self.setupProject50CompletionTracking()
            }
        }
    }
    
    // MARK: - Project 50 Completion Tracking Setup
    // ✅ FIX: This must run on app launch to prevent crashes
    private func setupProject50CompletionTracking() {
        let manager = Project50ProgressManager.shared
        
        manager.completionProvider = { [self] level, levelStartDate in
            // Filter Project 50 habits for this specific level
            let levelHabits = habits.filter { habit in
                guard let tag = habit.programTag else { return false }
                return tag == "P50" && habit.programLevel == level
            }
            
            let activeHabitsCount = levelHabits.count
            
            // Validate inputs
            guard activeHabitsCount > 0 else {
                return (activeHabitsCount: 0, totalCompletions: 0, daysSinceLevelStartCapped: 0)
            }
            
            guard let startDate = levelStartDate else {
                return (activeHabitsCount: 0, totalCompletions: 0, daysSinceLevelStartCapped: 0)
            }
            
            // Calculate elapsed days
            let calendar = Calendar.current
            let daysSinceStart = max(0, calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0)
            
            // Cap based on level
            let daysCap: Int
            switch level {
            case 1: daysCap = 21
            case 2: daysCap = 29
            case 3: daysCap = 29
            default: daysCap = 21
            }
            
            let windowStart = startDate
            let windowEnd = Date()
            
            // Get relevant completions
            let habitIds = Set(levelHabits.map { $0.id })
            let relevantCompletions = completions.filter { completion in
                habitIds.contains(completion.habitId) &&
                completion.completedAt >= windowStart &&
                completion.completedAt <= windowEnd
            }
            
            // Group by day
            let groupedByDay = Dictionary(grouping: relevantCompletions) { completion in
                calendar.startOfDay(for: completion.completedAt)
            }
            
            // Count successful days (≥80% completion)
            let successfulDays = groupedByDay.values.filter { dayCompletions in
                let uniqueHabits = Set(dayCompletions.map { $0.habitId }).count
                return uniqueHabits >= Int(Double(activeHabitsCount) * 0.80)
            }.count
            
            let cappedDays = min(daysSinceStart + 1, daysCap)
            
            return (
                activeHabitsCount: activeHabitsCount,
                totalCompletions: successfulDays,
                daysSinceLevelStartCapped: cappedDays
            )
        }
        
        print("✅ [P50] Completion tracking initialized")
    }
    
    // ✅ PRODUCTION: Adaptive padding for different devices
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 80 : 24
    }
    
    private var bottomPadding: CGFloat {
        // Account for home indicator on devices without home button
        let baseBottomPadding: CGFloat = 20
        let hasHomeIndicator = UIDevice.current.userInterfaceIdiom == .phone &&
                               UIScreen.main.bounds.height > 800
        return hasHomeIndicator ? baseBottomPadding : baseBottomPadding - 10
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ PRODUCTION: Time-adaptive colors for subtle visual harmony
    private var tabBarIconColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Subtle time-based tinting while maintaining black base
        switch hour {
        case 6..<12:   // Morning - slightly cooler
            return Color.black.opacity(0.95)
        case 12..<17:  // Afternoon - pure black
            return Color.black
        case 17..<20:  // Evening - slightly warmer
            return Color(red: 0.1, green: 0.08, blue: 0.06)
        default:       // Night - softer
            return Color.black.opacity(0.9)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            CustomTabButton(
                icon: "house.fill",
                label: "Desk",
                isSelected: selectedTab == 0,
                iconColor: tabBarIconColor
            ) {
                selectedTab = 0
            }
            .accessibilityLabel("Desk tab")
            .accessibilityHint("Shows today's habits and intentions")
            
            CustomTabButton(
                icon: "water.waves",
                label: "Loom",
                isSelected: selectedTab == 1,
                iconColor: tabBarIconColor
            ) {
                selectedTab = 1
            }
            .accessibilityLabel("Loom tab")
            .accessibilityHint("View your daily timeline and reflections")
            
            CustomTabButton(
                icon: "archivebox.fill",
                label: "Archive",
                isSelected: selectedTab == 2,
                iconColor: tabBarIconColor
            ) {
                selectedTab = 2
            }
            .accessibilityLabel("Archive tab")
            .accessibilityHint("Review your progress and history")
            
            CustomTabButton(
                icon: "person.circle",
                label: "Profile",
                isSelected: selectedTab == 3,
                iconColor: tabBarIconColor
            ) {
                selectedTab = 3
            }
            .accessibilityLabel("Profile tab")
            .accessibilityHint("Manage settings and preferences")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 25)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Custom Tab Button
struct CustomTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? iconColor : iconColor.opacity(0.4))
                    .frame(height: 22)
                
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? iconColor : iconColor.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Circle()
                    .fill(iconColor.opacity(isSelected ? 0.08 : 0))
                    .frame(width: 45, height: 45)
                    .blur(radius: isSelected ? 8 : 0)
            )
            .contentShape(Rectangle()) // ✅ PRODUCTION: Better tap target
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(TabButtonStyle()) // ✅ PRODUCTION: Custom button style for better interaction
    }
}

// MARK: - Custom Button Style
struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview("MainTabView") {
    MainTabView()
}

#Preview("MainTabView - iPad", traits: .landscapeLeft) {
    MainTabView()
}
