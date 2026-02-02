//
// ArchiveView.swift
// Reverie Weaver
//
//

import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query private var completions: [HabitCompletion]

    @State private var selectedSection: ArchiveSection = .weekly
    @State private var previousSection: ArchiveSection = .weekly
    @State private var showAchievements = false
    @StateObject private var achievementManager = AchievementManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                VStack(spacing: 16) {
                    headerSection

                    ZStack {
                        Group {
                            switch selectedSection {
                            case .weekly:
                                WeeklyArchiveView()
                                    .id(ArchiveSection.weekly)
                            case .monthly:
                                MonthlyArchiveView()
                                    .id(ArchiveSection.monthly)
                            case .favorites:
                                FavoritesTimelineView()
                                    .id(ArchiveSection.favorites)
                            case .reflections:
                                ReflectionNoteView()
                                    .id(ArchiveSection.reflections)
                            }
                        }
                        .transition(activeTransition)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedSection)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
                    .presentationDetents([.medium])
                    .presentationCornerRadius(24)
            }
        }
        .onChange(of: selectedSection) { oldValue, newValue in
            previousSection = oldValue
        }
        // Prevents duplicate attachments
        .onAppear {
            achievementManager.attachContext(modelContext)
        }
    }

    // MARK: - Transition Logic
    
    private var activeTransition: AnyTransition {
        let isMovingForward = selectedSection.rawValue > previousSection.rawValue
        
        return AnyTransition.asymmetric(
            insertion: .opacity
                .combined(with: .move(edge: isMovingForward ? .trailing : .leading))
                .combined(with: .scale(scale: 0.98, anchor: .center)),
            removal: .opacity
                .combined(with: .move(edge: isMovingForward ? .leading : .trailing))
                .combined(with: .scale(scale: 0.98, anchor: .center))
        )
    }

    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                Button {
                    changeSection(to: .weekly)
                } label: {
                    Text("Archive")
                        .font(.system(size: 23, weight: .regular))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 14) {
                    sectionMenuButton
                    achievementsButton
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }

    // MARK: - Helper Actions
    
    private func changeSection(to section: ArchiveSection) {
        guard selectedSection != section else { return }
        
        previousSection = selectedSection
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            selectedSection = section
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Section Menu
    
    private var sectionMenuButton: some View {
        Menu {
            Button { changeSection(to: .weekly) } label: {
                Label("Weekly Archive", systemImage: "calendar.badge.clock")
            }

            Button { changeSection(to: .monthly) } label: {
                Label("Monthly Archive", systemImage: "calendar")
            }

            Button { changeSection(to: .favorites) } label: {
                Label("Favorite Moments", systemImage: "heart.fill")
            }

            Button { changeSection(to: .reflections) } label: {
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

    // MARK: - Achievements Button
    
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

                // Check ready state before showing badge
                if achievementManager.isReady && hasRecentUnlocks {
                    Circle()
                        .fill(Color.terracottaRose)
                        .frame(width: 8, height: 8)
                        .offset(x: 12, y: -12)
                }
            }
        }
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

#Preview {
    ArchiveView()
        .preferredColorScheme(.light)
}
