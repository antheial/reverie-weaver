//
// ArchiveView.swift
// Reverie Weaver
//
// Main Archive container with default Weekly view
// - Matches The Loom's header spacing and typography
// - Adaptive black/white trophy icon
// - Native dropdown menu and achievements sheet
// - Smooth page transitions with slide and fade effects
//

import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Queries
    @Query private var completions: [HabitCompletion]

    // MARK: - State
    @State private var selectedSection: ArchiveSection = .weekly
    @State private var showAchievements = false
    @Namespace private var animation

    @StateObject private var achievementManager = AchievementManager.shared

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                VStack(spacing: 16) {
                    // MARK: - Header (matched Loom style)
                    headerSection

                    // MARK: - Active Section with Smooth Transitions
                    ZStack {
                        ForEach(ArchiveSection.allCases, id: \.self) { section in
                            if selectedSection == section {
                                sectionView(for: section)
                                    .transition(transitionForSection(section))
                                    .zIndex(1)
                            }
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedSection)
                }
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
                    .presentationDetents([.medium])
                    .presentationCornerRadius(24)
            }
        }
    }

    // MARK: - Section View Builder
    @ViewBuilder
    private func sectionView(for section: ArchiveSection) -> some View {
        switch section {
        case .weekly:
            WeeklyArchiveView()
                .id("weekly")
        case .monthly:
            MonthlyArchiveView()
                .id("monthly")
        case .favorites:
            FavoritesTimelineView()
                .id("favorites")
        case .reflections:
            ReflectionNoteView()
                .id("reflections")
        }
    }

    // MARK: - Transition Logic
    private func transitionForSection(_ section: ArchiveSection) -> AnyTransition {
        let direction: Edge = section.rawValue > selectedSection.rawValue ? .trailing : .leading

        return AnyTransition.asymmetric(
            insertion: .opacity
                .combined(with: .move(edge: direction))
                .combined(with: .scale(scale: 0.95, anchor: .center)),
            removal: .opacity
                .combined(with: .move(edge: direction == .trailing ? .leading : .trailing))
                .combined(with: .scale(scale: 0.95, anchor: .center))
        )
    }

    // MARK: - Header (Loom-style spacing and alignment)
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                // Title + date
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selectedSection = .weekly
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("Archive")
                            .font(.system(size: 23, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Right icons (menu + trophy)
                HStack(spacing: 14) {
                    sectionMenuButton
                    achievementsButton
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4) // âœ… identical top offset as The Loom
        }
    }

    // MARK: - Section Menu (Native iOS style)
    private var sectionMenuButton: some View {
        Menu {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedSection = .weekly
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("Weekly Archive", systemImage: "calendar.badge.clock")
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedSection = .monthly
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("Monthly Archive", systemImage: "calendar")
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedSection = .favorites
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("Favorite Moments", systemImage: "heart.fill")
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedSection = .reflections
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("Reflections", systemImage: "book.pages")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.shadowColor.opacity(0.1), radius: 4, y: 2)

                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dynamicLabel)
            }
        }
    }

    // MARK: - Achievements Button (adaptive black/white icon)
    private var achievementsButton: some View {
        Button {
            showAchievements = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.shadowColor.opacity(0.1), radius: 4, y: 2)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        colorScheme == .dark ? Color.white : Color.black
                    )

                // Badge indicator for new achievements
                if hasRecentUnlocks {
                    Circle()
                        .fill(Color.terracottaRose)
                        .frame(width: 8, height: 8)
                        .offset(x: 12, y: -12)
                }
            }
        }
    }

    // MARK: - Week Range Formatter
    private var currentWeekRange: String {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return "" }
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }

    // MARK: - Computed Properties
    private var hasRecentUnlocks: Bool {
        achievementManager.unlockedAchievements.count > 0
    }
}

// MARK: - Enum
enum ArchiveSection: Int, CaseIterable {
    case weekly = 0
    case monthly = 1
    case favorites = 2
    case reflections = 3
}

// MARK: - Preview
#Preview {
    ArchiveView()
        .preferredColorScheme(.light)
}
