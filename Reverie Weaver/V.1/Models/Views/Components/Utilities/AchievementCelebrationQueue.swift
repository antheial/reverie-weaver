//
//  AchievementCelebrationQueue.swift
//  Reverie Weaver
//
//  Queues achievements during a session and shows them in a consolidated celebration modal
//  instead of interrupting the user immediately.
//

import SwiftUI
import Combine

// MARK: - Celebration Item

struct AchievementCelebration: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let colorHex: String
    let isHidden: Bool           // For invisible achievements (show "Hidden Thread" badge)
    let isConstellation: Bool    // For constellation badges
    let isLevelUp: Bool          // For level-up celebrations
    let timestamp: Date

    init(
        title: String,
        icon: String,
        colorHex: String,
        isHidden: Bool = false,
        isConstellation: Bool = false,
        isLevelUp: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.colorHex = colorHex
        self.isHidden = isHidden
        self.isConstellation = isConstellation
        self.isLevelUp = isLevelUp
        self.timestamp = Date()
    }

    static func == (lhs: AchievementCelebration, rhs: AchievementCelebration) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Achievement Celebration Queue

@MainActor
@Observable
final class AchievementCelebrationQueue {
    static let shared = AchievementCelebrationQueue()

    // MARK: - State
    var pendingCelebrations: [AchievementCelebration] = []
    var showCelebrationModal: Bool = false

    /// Maximum achievements to queue before auto-showing
    private let autoShowThreshold = 5

    /// Key for persisting pending celebrations across app launches
    private let pendingKey = "pendingAchievementCelebrations"

    // MARK: - Initialization

    private init() {
        loadPendingCelebrations()

        // Listen for app going to background to save pending
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let strongSelf = self else { return }
            Task { @MainActor in
                strongSelf.savePendingCelebrations()
            }
        }
    }

    // MARK: - Queue Management

    /// Add an achievement to the celebration queue
    func queue(_ celebration: AchievementCelebration) {
        // Avoid duplicates (same title within last 5 seconds)
        let isDuplicate = pendingCelebrations.contains { existing in
            existing.title == celebration.title &&
            abs(existing.timestamp.timeIntervalSince(celebration.timestamp)) < 5
        }

        guard !isDuplicate else { return }

        pendingCelebrations.append(celebration)

        #if DEBUG
        print("🎉 Queued celebration: \(celebration.title) (total: \(pendingCelebrations.count))")
        #endif

        // Auto-show if threshold reached (rare edge case of many achievements at once)
        if pendingCelebrations.count >= autoShowThreshold {
            showCelebrationModal = true
        }
    }

    /// Queue a standard achievement
    func queueStandardAchievement(title: String, icon: String) {
        queue(AchievementCelebration(
            title: title,
            icon: icon,
            colorHex: "A8B5A0"  // Sage green
        ))
    }

    /// Queue a hidden/invisible achievement
    func queueHiddenAchievement(title: String, icon: String, colorHex: String) {
        queue(AchievementCelebration(
            title: title,
            icon: icon,
            colorHex: colorHex,
            isHidden: true
        ))
    }

    /// Queue a constellation badge unlock
    func queueConstellationUnlock(name: String, icon: String, colorHex: String) {
        queue(AchievementCelebration(
            title: name,
            icon: icon,
            colorHex: colorHex,
            isConstellation: true
        ))
    }

    /// Queue a level-up celebration
    func queueLevelUp(levelTitle: String) {
        queue(AchievementCelebration(
            title: levelTitle,
            icon: "sparkles",
            colorHex: "D4AF37",  // Gold
            isLevelUp: true
        ))
    }

    // MARK: - Display Control

    /// Show pending celebrations (call when user opens Profile or session ends)
    func showPendingCelebrations() {
        guard !pendingCelebrations.isEmpty else { return }
        showCelebrationModal = true
    }

    /// Check if there are pending celebrations
    var hasPendingCelebrations: Bool {
        !pendingCelebrations.isEmpty
    }

    /// Number of pending celebrations
    var pendingCount: Int {
        pendingCelebrations.count
    }

    /// Clear the queue after showing
    func clearQueue() {
        pendingCelebrations.removeAll()
        showCelebrationModal = false
        clearSavedCelebrations()
    }

    /// Dismiss modal without clearing (user can see them later)
    func dismissModal() {
        showCelebrationModal = false
    }

    // MARK: - Persistence

    private func savePendingCelebrations() {
        guard !pendingCelebrations.isEmpty else { return }

        let data = pendingCelebrations.map { celebration -> [String: Any] in
            [
                "title": celebration.title,
                "icon": celebration.icon,
                "colorHex": celebration.colorHex,
                "isHidden": celebration.isHidden,
                "isConstellation": celebration.isConstellation,
                "isLevelUp": celebration.isLevelUp,
                "timestamp": celebration.timestamp.timeIntervalSince1970
            ]
        }

        UserDefaults.standard.set(data, forKey: pendingKey)

        #if DEBUG
        print("💾 Saved \(pendingCelebrations.count) pending celebrations")
        #endif
    }

    private func loadPendingCelebrations() {
        guard let data = UserDefaults.standard.array(forKey: pendingKey) as? [[String: Any]] else {
            return
        }

        pendingCelebrations = data.compactMap { dict -> AchievementCelebration? in
            guard let title = dict["title"] as? String,
                  let icon = dict["icon"] as? String,
                  let colorHex = dict["colorHex"] as? String else {
                return nil
            }

            return AchievementCelebration(
                title: title,
                icon: icon,
                colorHex: colorHex,
                isHidden: dict["isHidden"] as? Bool ?? false,
                isConstellation: dict["isConstellation"] as? Bool ?? false,
                isLevelUp: dict["isLevelUp"] as? Bool ?? false
            )
        }

        #if DEBUG
        if !pendingCelebrations.isEmpty {
            print("📂 Loaded \(pendingCelebrations.count) pending celebrations from previous session")
        }
        #endif
    }

    private func clearSavedCelebrations() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
    }
}

// MARK: - Celebration Modal View

struct CelebrationModalView: View {
    @Environment(\.colorScheme) private var colorScheme
    let celebrations: [AchievementCelebration]
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "D4AF37"), Color(hex: "FFD700")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .opacity(showContent ? 1 : 0)

                    Text("Threads Revealed")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                }

                // Achievement cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(celebrations.enumerated()), id: \.element.id) { index, celebration in
                            CelebrationCard(celebration: celebration)
                                .scaleEffect(showContent ? 1.0 : 0.8)
                                .opacity(showContent ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.1),
                                    value: showContent
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxHeight: 200)

                // Summary text
                Text(summaryText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(showContent ? 1 : 0)

                // Continue button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue Weaving")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.sageGreen, Color.dustyBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1.0 : 0.9)
            }
            .padding(.vertical, 32)

            // Confetti overlay
            if showConfetti {
                ConfettiView(isActive: .constant(true))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }

            // Trigger confetti after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }

            // Play sound if there are celebrations
            if !celebrations.isEmpty {
                if celebrations.contains(where: { $0.isLevelUp }) {
                    AchievementAudioManager.shared.playLevelUp()
                } else if celebrations.contains(where: { $0.isConstellation }) {
                    AchievementAudioManager.shared.playConstellationUnlock()
                } else if celebrations.contains(where: { $0.isHidden }) {
                    AchievementAudioManager.shared.playHiddenReveal()
                } else {
                    AchievementAudioManager.shared.playStandardUnlock()
                }
            }
        }
    }

    private var summaryText: String {
        let count = celebrations.count
        if count == 1 {
            return "You've woven a new thread into your tapestry."
        } else {
            return "You've woven \(count) new threads into your tapestry."
        }
    }
}

// MARK: - Celebration Card

struct CelebrationCard: View {
    let celebration: AchievementCelebration
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            // Badge indicator
            if celebration.isHidden {
                Text("HIDDEN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color(hex: celebration.colorHex))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .stroke(Color(hex: celebration.colorHex).opacity(0.5), lineWidth: 1)
                    )
            } else if celebration.isConstellation {
                Text("CONSTELLATION")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "D4AF37"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .stroke(Color(hex: "D4AF37").opacity(0.5), lineWidth: 1)
                    )
            } else if celebration.isLevelUp {
                Text("LEVEL UP")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "FFD700"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .stroke(Color(hex: "FFD700").opacity(0.5), lineWidth: 1)
                    )
            }

            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: celebration.colorHex).opacity(0.2))
                    .frame(width: 60, height: 60)

                Circle()
                    .stroke(Color(hex: celebration.colorHex).opacity(0.5), lineWidth: 1)
                    .frame(width: 60, height: 60)

                Image(systemName: celebration.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: celebration.colorHex))
            }

            // Title
            Text(celebration.title)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 120, height: 160)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: celebration.colorHex).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - View Modifier for Easy Integration

struct CelebrationModalModifier: ViewModifier {
    @State private var queue = AchievementCelebrationQueue.shared

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: Binding(
                get: { queue.showCelebrationModal },
                set: { queue.showCelebrationModal = $0 }
            )) {
                CelebrationModalView(
                    celebrations: queue.pendingCelebrations,
                    onDismiss: {
                        queue.clearQueue()
                    }
                )
                .background(Color.clear)
            }
    }
}

extension View {
    /// Adds the achievement celebration modal to this view
    func withCelebrationModal() -> some View {
        modifier(CelebrationModalModifier())
    }
}
