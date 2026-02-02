//
//  OnboardingView.swift
//  Reverie Weaver
//
//  Guided onboarding - consistent layout, narrative flow, comprehensive intro
//

import SwiftUI

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var currentPage = 0
    @State private var showNotificationPrompt = false
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            ReverieWeaverBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    // Page 1: Special Welcome Page
                    WelcomePageView()
                        .tag(0)
                    
                    // Page 2: Your Daily Rhythm
                    OnboardingPageTemplate(
                        icon: "clock.fill",
                        iconColor: Color(hex: "8FBC8F"),
                        title: "Your Daily Rhythm",
                        subtitle: "Three spaces to organize your day"
                    ) {
                        DailyRhythmContent()
                    }
                    .tag(1)
                    
                    // Page 3: Gentle Progress
                    OnboardingPageTemplate(
                        icon: "leaf.fill",
                        iconColor: Color(hex: "B8D4C8"),
                        title: "Gentle Progress",
                        subtitle: "Every effort counts toward growth"
                    ) {
                        GentleProgressContent()
                    }
                    .tag(2)
                    
                    // Page 4: Guided Programs
                    OnboardingPageTemplate(
                        icon: "book.fill",
                        iconColor: Color(hex: "9B7EBD"),
                        title: "Guided Programs",
                        subtitle: "Structured paths to build new habits"
                    ) {
                        GuidedProgramsContent()
                    }
                    .tag(3)
                    
                    // Page 5: Your Journey
                    OnboardingPageTemplate(
                        icon: "sparkles",
                        iconColor: Color(hex: "CBA4F7"),
                        title: "Your Journey Awaits",
                        subtitle: "Celebrate progress as you grow"
                    ) {
                        JourneyContent()
                    }
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                
                // Bottom Controls
                bottomControls
            }
        }
        .sheet(isPresented: $showNotificationPrompt) {
            NotificationPermissionView {
                completeOnboarding()
            }
        }
        .interactiveDismissDisabled()
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Page Indicators
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index
                              ? Color.dynamicLabel
                              : Color.dynamicLabel.opacity(0.2))
                        .frame(width: currentPage == index ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            
            // Action Buttons - hide on welcome page (page 0)
            if currentPage == 0 {
                // Swipe prompt for welcome page
                VStack(spacing: 8) {
                    Text("SWIPE TO CONTINUE")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.5)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .opacity(0.5)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .light))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .opacity(0.3)
                }
                .padding(.vertical, 8)
            } else if currentPage < totalPages - 1 {
                HStack(spacing: 12) {
                    Button {
                        withAnimation { currentPage = totalPages - 1 }
                        ReverieHaptics.lightFeedback()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.dynamicLabel.opacity(0.06))
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        withAnimation { currentPage += 1 }
                        ReverieHaptics.lightFeedback()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Next")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "9B7EBD"), Color(hex: "7A9CC6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            } else {
                Button {
                    showNotificationPrompt = true
                    ReverieHaptics.successFeedback()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Get Started")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "9B7EBD"), Color(hex: "7A9CC6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color(hex: "9B7EBD").opacity(0.3), radius: 10, y: 4)
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        ReverieHaptics.successFeedback()
        dismiss()
    }
}

// MARK: - Welcome Page (Page 1)

private struct WelcomePageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Small label above title
            Text("WELCOME TO")
                .font(.system(size: 11, weight: .medium))
                .tracking(3)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .opacity(0.6)
            
            Spacer()
                .frame(height: 12)
            
            // "THE DAILY" subtitle
            Text("THE DAILY")
                .font(.system(size: 13, weight: .semibold))
                .tracking(3)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .opacity(0.8)
            
            Spacer()
                .frame(height: 16)
            
            // App name split into lines
            VStack(spacing: 2) {
                Text("REVERIE")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .tracking(2)
                Text("WEAVER")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .tracking(2)
            }
            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Spacer()
                .frame(height: 20)
            
            // Horizontal line
            Rectangle()
                .fill(Color.dynamicLabel.opacity(0.2))
                .frame(width: 180, height: 1)
            
            Spacer()
                .frame(height: 40)
            
            // Description text
            Text("Track habits, build habit systems,\nfocus with timers, and follow guided\nprograms in a beautiful, mindful experience.")
                .font(.system(size: 16, weight: .regular, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Consistent Page Template

private struct OnboardingPageTemplate<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            // More breathing room at top
            Spacer()
                .frame(height: 100)
            
            // Icon - ALWAYS same size, same position
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 64, height: 64)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Fixed spacing after icon
            Spacer()
                .frame(height: 20)
            
            // Title - ALWAYS same style
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .multilineTextAlignment(.center)
            
            // Subtitle - ALWAYS same style
            Text(subtitle)
                .font(.system(size: 14))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            
            // Fixed spacing before content
            Spacer()
                .frame(height: 32)
            
            // Content area - flexible but contained, centered vertically
            VStack {
                Spacer()
                content
                    .padding(.horizontal, 24)
                Spacer()
            }
            
            // Bottom spacer
            Spacer()
                .frame(height: 40)
        }
    }
}

// MARK: - Page 2: Daily Rhythm Content

private struct DailyRhythmContent: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            // The Desk
            FeatureCard(
                icon: "house.fill",
                title: "Your Desk",
                description: "Today's habits at a glance. Tap to complete and build streaks.",
                color: Color(hex: "8FBC8F")
            )
            
            // The Loom
            FeatureCard(
                icon: "water.waves",
                title: "The Loom",
                description: "Daily timeline with Pomodoro timer, priority tasks, micro habits, and reflections.",
                color: Color(hex: "7A9CC6")
            )
            
            // The Archive
            FeatureCard(
                icon: "archivebox.fill",
                title: "Archive",
                description: "Weekly & monthly views, favorite moments, and reflections—your journey documented.",
                color: Color(hex: "9BB5CE")
            )
            
            // Quick insight
            InsightText(text: "Three spaces working together to make habit-building feel natural.")
        }
    }
}

// MARK: - Page 3: Gentle Progress Content

private struct GentleProgressContent: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Explanation
            InfoCard(
                text: "Not every day is 100%. Reverie Weaver lets you log partial progress so you stay motivated instead of giving up.",
                style: .secondary
            )
            
            // Tiers visual
            HStack(spacing: 0) {
                TierItem(icon: "leaf.fill", name: "Seed", example: "5 min walk", color: Color(hex: "B8D4C8"))
                
                TierArrow()
                
                TierItem(icon: "leaf.circle.fill", name: "Sprout", example: "15 min walk", color: Color(hex: "8FBC8F"))
                
                TierArrow()
                
                TierItem(icon: "sparkles", name: "Bloom", example: "30 min walk", color: Color(hex: "9B7EBD"))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .reverieCardStyle(colorScheme: colorScheme, cornerRadius: 12, shadowRadius: 3, shadowYOffset: 1)
            
            // Insight
            InsightText(text: "A Seed day still counts. Consistency beats intensity.")
        }
    }
}

// MARK: - Page 4: Guided Programs Content

private struct GuidedProgramsContent: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            ProgramCard(
                icon: "50.circle.fill",
                title: "Project 50",
                description: "50-day program with 3 mastery levels. Build one habit deeply over 150 days total.",
                duration: "50 × 3",
                color: Color(hex: "7A9CC6")
            )
            
            ProgramCard(
                icon: "calendar.badge.clock",
                title: "Theme Weeks",
                description: "7-day explorations of specific habits. Great for trying something new.",
                duration: "7 days",
                color: Color(hex: "B8D4C8")
            )
            
            ProgramCard(
                icon: "star.circle.fill",
                title: "Mini Challenges",
                description: "Focused 7-day sprints with daily guidance. Quick wins to build momentum.",
                duration: "7 days",
                color: Color(hex: "E8927C")
            )
            
            // Quote - centered at bottom
            VStack(spacing: 4) {
                Text("\"Start where you are. Use what you have.")
                Text("Do what you can.\"")
                Text("— Arthur Ashe")
                    .padding(.top, 2)
            }
            .font(.system(size: 13, weight: .regular, design: .serif))
            .italic()
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            .multilineTextAlignment(.center)
            .opacity(0.6)
            .padding(.top, 16)
        }
    }
}

// MARK: - Page 5: Journey Content

private struct JourneyContent: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            FeatureCard(
                icon: "star.fill",
                title: "Constellation Badges",
                description: "12 themed chapters with 9 badges each. Unlock them as you build consistency.",
                color: Color(hex: "FFB347")
            )
            
            FeatureCard(
                icon: "eye.slash.fill",
                title: "Hidden Achievements",
                description: "Secret milestones waiting to be discovered through your unique journey.",
                color: Color(hex: "9B7EBD")
            )
            
            FeatureCard(
                icon: "arrow.up.circle.fill",
                title: "Weaver Level",
                description: "Your overall progress across all habits and programs, always growing.",
                color: Color(hex: "7A9CC6")
            )
            
            // Quote - centered at bottom
            VStack(spacing: 2) {
                Text("\"Not every thread needs to be perfect.")
                Text("The tapestry still holds.\"")
            }
            .font(.system(size: 13, weight: .regular, design: .serif))
            .italic()
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            .multilineTextAlignment(.center)
            .opacity(0.6)
            .padding(.top, 16)
        }
    }
}

// MARK: - Reusable Components

private struct InfoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    let style: InfoCardStyle
    
    enum InfoCardStyle {
        case primary, secondary
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: style == .primary ? .medium : .regular))
            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dynamicLabel.opacity(0.04))
            )
    }
}

private struct PhilosophyRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 18)
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.06))
        )
    }
}

private struct FeatureCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Text(description)
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .reverieCardStyle(colorScheme: colorScheme, cornerRadius: 12, shadowRadius: 3, shadowYOffset: 1)
    }
}

private struct ProgramCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let description: String
    let duration: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Spacer()
                    
                    Text(duration)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(color.opacity(0.12)))
                }
                
                Text(description)
                    .font(.system(size: 11))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .reverieCardStyle(colorScheme: colorScheme, cornerRadius: 12, shadowRadius: 3, shadowYOffset: 1)
    }
}

private struct TierItem: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let name: String
    let example: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Text(example)
                .font(.system(size: 9))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TierArrow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .bold))
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            .opacity(0.3)
    }
}

private struct InsightText: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .serif))
            .italic()
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .opacity(0.7)
    }
}

// MARK: - Notification Permission View

private struct NotificationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onComplete: () -> Void

    @State private var isRequesting = false

    var body: some View {
        ZStack {
            ReverieWeaverBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Match OnboardingPageTemplate: more breathing room at top
                Spacer()
                    .frame(height: 100)

                // Icon - same size and position as other pages
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFB347").opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFB347"), Color(hex: "FFCC33")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Fixed spacing after icon (matching template)
                Spacer()
                    .frame(height: 20)

                // Title - same style as other pages
                Text("Stay on Track")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                // Subtitle - same style as other pages
                Text("Gentle reminders help build consistency")
                    .font(.system(size: 14))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .padding(.top, 4)

                // Fixed spacing before content (matching template)
                Spacer()
                    .frame(height: 32)

                // Content area - matching other onboarding pages with richer content
                VStack(spacing: 10) {
                    FeatureCard(
                        icon: "clock.fill",
                        title: "Per-Habit Reminders",
                        description: "Set unique reminder times for each habit based on your daily rhythm.",
                        color: Color(hex: "9BB5CE")
                    )

                    FeatureCard(
                        icon: "sun.horizon.fill",
                        title: "Flexible Timing",
                        description: "Choose morning, afternoon, or evening—whatever works for you.",
                        color: Color(hex: "FFB347")
                    )

                    FeatureCard(
                        icon: "moon.fill",
                        title: "Respectful & Quiet",
                        description: "Automatically honors Do Not Disturb and Focus modes.",
                        color: Color(hex: "B8D4C8")
                    )

                    FeatureCard(
                        icon: "hand.raised.fill",
                        title: "Full Control",
                        description: "Adjust or disable notifications anytime in settings.",
                        color: Color(hex: "E8927C")
                    )

                    // Insight quote at bottom (matching other pages)
                    InsightText(text: "A gentle nudge at the right moment makes all the difference.")
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)

                // Bottom spacer (matching template)
                Spacer()
                    .frame(height: 24)

                // Buttons
                VStack(spacing: 10) {
                    Button {
                        requestNotificationPermission()
                    } label: {
                        HStack(spacing: 6) {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Text("Enable Notifications")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFB347"), Color(hex: "FFCC33")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRequesting)

                    Button {
                        skipNotifications()
                    } label: {
                        Text("Maybe Later")
                            .font(.system(size: 14, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRequesting)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func requestNotificationPermission() {
        isRequesting = true
        ReverieHaptics.lightFeedback()
        
        Task {
            let granted = await HabitNotificationManager.shared.requestAuthorization()
            
            await MainActor.run {
                isRequesting = false
                if granted {
                    ReverieHaptics.successFeedback()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
    
    private func skipNotifications() {
        ReverieHaptics.lightFeedback()
        onComplete()
    }
}

private struct NotificationFeatureRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.06))
        )
    }
}

// MARK: - Onboarding Container

struct OnboardingContainer<Content: View>: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                content
            } else {
                OnboardingView()
            }
        }
    }
}

// MARK: - Button Styles

private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView()
}

#Preview("Welcome Page") {
    ZStack {
        ReverieWeaverBackground()
            .ignoresSafeArea()
        WelcomePageView()
    }
}

#Preview("Notification") {
    NotificationPermissionView { }
}
