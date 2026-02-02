//
//  CelebrationAnimations.swift
//  Reverie Weaver
//
//  Enhanced celebration animations for level-up and badge unlocks
//

import SwiftUI

// MARK: - Starburst Particles

struct StarburstParticles: View {
    let color: Color
    let particleCount: Int

    @State private var particles: [StarParticle] = []

    struct StarParticle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
        let angle: Double
        let distance: CGFloat
    }

    init(color: Color, particleCount: Int = 20) {
        self.color = color
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundStyle(color)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                }
            }
            .onAppear {
                generateParticles(center: center)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(center: CGPoint) {
        particles = []

        for i in 0..<particleCount {
            let angle = Double(i) * (360.0 / Double(particleCount))
            let distance: CGFloat = CGFloat.random(in: 100...180)

            let particle = StarParticle(
                position: center,
                scale: 0.3,
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                angle: angle,
                distance: distance
            )
            particles.append(particle)
        }

        // Animate particles outward
        for i in 0..<particles.count {
            let radians = particles[i].angle * .pi / 180
            let targetX = center.x + cos(radians) * particles[i].distance
            let targetY = center.y + sin(radians) * particles[i].distance

            withAnimation(.easeOut(duration: 0.8).delay(Double(i) * 0.02)) {
                particles[i].position = CGPoint(x: targetX, y: targetY)
                particles[i].scale = CGFloat.random(in: 0.5...1.2)
            }

            // Fade out
            withAnimation(.easeIn(duration: 0.4).delay(0.5 + Double(i) * 0.02)) {
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Level Up Celebration View

struct LevelUpCelebrationView: View {
    let level: WeaverLevel
    let onDismiss: () -> Void

    @State private var showTitle = false
    @State private var showDetails = false
    @State private var showConfetti = false
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Radial gradient
            RadialGradient(
                colors: [
                    Color.paleMauve.opacity(0.3),
                    Color.sageGreen.opacity(0.2),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Sparkle icon with pulse
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { ring in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "D4AF37").opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                            .frame(width: CGFloat(80 + ring * 40), height: CGFloat(80 + ring * 40))
                            .scaleEffect(pulseScale)
                            .opacity(showTitle ? 0.6 : 0)
                    }

                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "D4AF37"), Color(hex: "FFD700")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showTitle ? 1.0 : 0.3)
                        .opacity(showTitle ? 1 : 0)
                        .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 20)
                }

                // Level number
                Text("Level \(level.level)")
                    .font(.system(size: 56, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "E5E5E5")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "D4AF37").opacity(0.5), radius: 10)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 30)

                // Level title
                Text(level.title)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(Color(hex: "D4AF37"))
                    .textCase(.uppercase)
                    .tracking(2)
                    .opacity(showDetails ? 1 : 0)
                    .offset(y: showDetails ? 0 : 10)

                // Description
                Text(level.description)
                    .font(.system(size: 15, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 40)
                    .opacity(showDetails ? 1 : 0)
                    .offset(y: showDetails ? 0 : 10)

                Spacer()

                // Continue button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "D4AF37"), Color(hex: "B8860B")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: "D4AF37").opacity(0.5), radius: 10)
                        )
                }
                .opacity(showDetails ? 1 : 0)
                .scaleEffect(showDetails ? 1.0 : 0.9)
                .padding(.bottom, 60)
            }

            // Confetti
            if showConfetti {
                ConfettiView(isActive: .constant(true))
            }

            // Starburst particles
            if showTitle {
                StarburstParticles(color: Color(hex: "FFD700"))
            }
        }
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        // Phase 1: Show title with scale animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showTitle = true
        }

        // Start pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }

        // Phase 2: Show details
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.5)) {
                showDetails = true
            }
        }

        // Phase 3: Confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showConfetti = true
        }

        // Play sound
        AchievementAudioManager.shared.playLevelUp()
        ReverieHaptics.successFeedback()
    }
}

// MARK: - Constellation Unlock Animation View

struct ConstellationUnlockAnimationView: View {
    let constellation: ConstellationBadge
    let onDismiss: () -> Void

    @State private var phase: AnimationPhase = .hidden
    @Environment(\.colorScheme) private var colorScheme

    enum AnimationPhase: Int {
        case hidden = 0
        case glowing = 1
        case revealed = 2
        case settled = 3
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(phase == .hidden ? 0 : 0.9)
                .ignoresSafeArea()
                .animation(.easeIn(duration: 0.3), value: phase)
                .onTapGesture {
                    if phase == .settled {
                        onDismiss()
                    }
                }

            VStack(spacing: 24) {
                // The card
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color(hex: constellation.colorHex).opacity(phase == .glowing ? 0.4 : 0))
                        .frame(width: 250, height: 250)
                        .blur(radius: 40)
                        .scaleEffect(phase == .glowing ? 1.2 : 0.8)

                    // Card representation
                    VStack(spacing: 16) {
                        // Icon container
                        ZStack {
                            // Background glow
                            Circle()
                                .fill(Color(hex: constellation.colorHex).opacity(0.3))
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)

                            // Icon circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: constellation.colorHex).opacity(0.8),
                                            Color(hex: constellation.colorHex).opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            // Icon
                            Image(systemName: constellation.iconName)
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(phase.rawValue >= AnimationPhase.revealed.rawValue ? 1.0 : 0.5)
                        .opacity(phase.rawValue >= AnimationPhase.revealed.rawValue ? 1 : 0)

                        // Name
                        Text(constellation.name)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .opacity(phase.rawValue >= AnimationPhase.revealed.rawValue ? 1 : 0)
                            .offset(y: phase.rawValue >= AnimationPhase.revealed.rawValue ? 0 : 20)

                        // Category
                        Text(constellation.category.uppercased())
                            .font(.system(size: 12, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(Color(hex: constellation.colorHex))
                            .opacity(phase == .settled ? 1 : 0)
                    }
                }

                // "Constellation Unlocked" badge
                if phase == .settled {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("Constellation Unlocked")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color(hex: "D4AF37"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .stroke(Color(hex: "D4AF37").opacity(0.5), lineWidth: 1)
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Continue button
                if phase == .settled {
                    Button {
                        onDismiss()
                    } label: {
                        Text("View in Grimoire")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color(hex: constellation.colorHex).opacity(0.8))
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Starburst particles
            if phase == .revealed {
                StarburstParticles(color: Color(hex: constellation.colorHex), particleCount: 24)
            }
        }
        .onAppear {
            animateSequence()
        }
    }

    private func animateSequence() {
        // Phase 1: Glow (0.5s)
        withAnimation(.easeIn(duration: 0.5)) {
            phase = .glowing
        }

        // Phase 2: Reveal (0.6s after)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                phase = .revealed
            }

            // Play sound
            AchievementAudioManager.shared.playConstellationUnlock()
            ReverieHaptics.successFeedback()
        }

        // Phase 3: Settle (1.5s after)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                phase = .settled
            }
        }
    }
}

// MARK: - View Modifiers for Level Up

struct LevelUpCelebrationModifier: ViewModifier {
    @Binding var showLevelUp: Bool
    let level: WeaverLevel

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showLevelUp) {
                LevelUpCelebrationView(level: level) {
                    showLevelUp = false
                }
                .background(Color.clear)
            }
    }
}

extension View {
    func levelUpCelebration(isPresented: Binding<Bool>, level: WeaverLevel) -> some View {
        modifier(LevelUpCelebrationModifier(showLevelUp: isPresented, level: level))
    }
}

// MARK: - Preview

#Preview("Level Up") {
    LevelUpCelebrationView(
        level: WeaverLevel(level: 3, title: "Devoted Weaver", minCompletions: 200, maxCompletions: 300, description: "Your dedication deepens.")
    ) {
        print("Dismissed")
    }
}

#Preview("Starburst") {
    ZStack {
        Color.black.ignoresSafeArea()
        StarburstParticles(color: .yellow)
    }
}
