//
//  BreathingWaveAnimation.swift
//  Reverie Mood
//
//  Horizontal scrolling wave visualization with trailing orb.
//  A continuous sine wave flows across the screen, with amplitude that
//  responds to breath phases (grows on inhale, holds, shrinks on exhale).
//  The glowing orb rides smoothly along the wave at center with a comet trail.
//

import SwiftUI

// MARK: - Wave Animation View

struct BreathingWaveAnimation: View {
    var phase: BreathPhase
    var phaseProgress: Double
    var isRunning: Bool
    var color: Color

    // Wave configuration
    private let maxAmplitude: CGFloat = 0.35    // Maximum wave height (% of view height)
    private let minAmplitude: CGFloat = 0.08    // Minimum wave height at rest
    private let waveFrequency: Double = 1.2     // Number of wave cycles across screen
    private let waveSpeed: Double = 0.025       // How fast the wave scrolls
    private let trailLength: Int = 50           // Number of trail points

    // Animation state
    @State private var waveOffset: Double = 0
    @State private var trailPoints: [CGPoint] = []
    @State private var animationTimer: Timer?
    @State private var currentAmplitude: CGFloat = 0.08

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let centerY = height / 2
            let amplitudeRange = height * maxAmplitude
            let minAmp = height * minAmplitude

            // Orb is centered horizontally
            let orbX = width / 2
            let orbY = calculateWaveY(at: orbX, width: width, centerY: centerY, amplitude: currentAmplitude)

            ZStack {
                // Background wave path (subtle guide)
                WavePathShape(
                    waveOffset: waveOffset,
                    frequency: waveFrequency,
                    amplitude: currentAmplitude,
                    centerY: centerY
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.02),
                            .white.opacity(0.06),
                            .white.opacity(0.02)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )

                // Glowing trail behind the orb (outer glow)
                TrailingPath(points: trailPoints)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.05),
                                .white.opacity(0.15),
                                .white.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 3)

                // Inner trail (brighter core)
                TrailingPath(points: trailPoints)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.1),
                                .white.opacity(0.4),
                                .white.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )

                // The glowing orb
                GlowingOrb(phase: phase, isRunning: isRunning)
                    .position(x: orbX, y: orbY)
            }
            .onAppear {
                currentAmplitude = minAmp
                initializeTrail(orbX: orbX, centerY: centerY)
                startAnimation(width: width, centerY: centerY, orbX: orbX, maxAmp: amplitudeRange, minAmp: minAmp)
            }
            .onDisappear {
                stopAnimation()
            }
            .onChange(of: isRunning) { _, running in
                if running {
                    startAnimation(width: width, centerY: centerY, orbX: orbX, maxAmp: amplitudeRange, minAmp: minAmp)
                } else {
                    stopAnimation()
                }
            }
        }
    }

    // MARK: - Wave Calculations

    /// Calculate the Y position on the wave at a given X
    private func calculateWaveY(at x: CGFloat, width: CGFloat, centerY: CGFloat, amplitude: CGFloat) -> CGFloat {
        let normalizedX = x / width
        let wavePosition = (normalizedX * waveFrequency * .pi * 2) + waveOffset
        let waveValue = sin(wavePosition)
        return centerY - (waveValue * amplitude)
    }

    /// Calculate target amplitude based on breath phase
    private func calculateTargetAmplitude(maxAmp: CGFloat, minAmp: CGFloat) -> CGFloat {
        guard isRunning else { return minAmp }

        let easedProgress = easeInOutSine(phaseProgress)
        let range = maxAmp - minAmp

        switch phase {
        case .inhale:
            // Amplitude grows from min to max during inhale
            return minAmp + (range * easedProgress)
        case .hold:
            // Stay at maximum amplitude
            return maxAmp
        case .exhale:
            // Amplitude shrinks from max to min during exhale
            return maxAmp - (range * easedProgress)
        }
    }

    private func easeInOutSine(_ t: Double) -> Double {
        return -(cos(.pi * t) - 1) / 2
    }

    // MARK: - Animation Control

    private func initializeTrail(orbX: CGFloat, centerY: CGFloat) {
        guard trailPoints.isEmpty else { return }

        // Initialize trail as a horizontal line leading to orb position
        trailPoints = (0..<trailLength).map { i in
            let x = orbX - CGFloat(trailLength - i) * 3
            return CGPoint(x: x, y: centerY)
        }
    }

    private func startAnimation(width: CGFloat, centerY: CGFloat, orbX: CGFloat, maxAmp: CGFloat, minAmp: CGFloat) {
        // Stop any existing timer
        animationTimer?.invalidate()

        // Create new animation timer at 60fps
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            // Update wave offset for continuous scrolling
            waveOffset += waveSpeed

            // Smoothly interpolate amplitude toward target
            let targetAmp = calculateTargetAmplitude(maxAmp: maxAmp, minAmp: minAmp)
            let interpolationSpeed: CGFloat = 0.08
            currentAmplitude += (targetAmp - currentAmplitude) * interpolationSpeed

            // Calculate new orb position on the wave
            let orbY = calculateWaveY(at: orbX, width: width, centerY: centerY, amplitude: currentAmplitude)
            let newPoint = CGPoint(x: orbX, y: orbY)

            // Update trail - remove oldest point, add new one
            if trailPoints.count >= trailLength {
                trailPoints.removeFirst()
            }
            trailPoints.append(newPoint)
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - Wave Path Shape

struct WavePathShape: Shape {
    var waveOffset: Double
    var frequency: Double
    var amplitude: CGFloat
    var centerY: CGFloat

    var animatableData: Double {
        get { waveOffset }
        set { waveOffset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let steps = Int(width)

        // Start from left edge
        let startY = centerY - (sin(waveOffset) * amplitude)
        path.move(to: CGPoint(x: 0, y: startY))

        // Draw smooth wave across screen
        for i in 1...steps {
            let x = CGFloat(i)
            let normalizedX = x / width
            let wavePosition = (normalizedX * frequency * .pi * 2) + waveOffset
            let waveValue = sin(wavePosition)
            let y = centerY - (waveValue * amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

// MARK: - Trailing Path Shape

struct TrailingPath: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard points.count >= 2 else { return path }

        path.move(to: points[0])

        // Use smooth quadratic curves through points
        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]

            let midPoint = CGPoint(
                x: (previous.x + current.x) / 2,
                y: (previous.y + current.y) / 2
            )

            if i == 1 {
                path.addLine(to: midPoint)
            } else {
                path.addQuadCurve(to: midPoint, control: previous)
            }
        }

        // Connect to the last point
        if let last = points.last {
            path.addLine(to: last)
        }

        return path
    }
}

// MARK: - Glowing Orb

struct GlowingOrb: View {
    var phase: BreathPhase
    var isRunning: Bool

    // Gentle pulsing
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outermost soft glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.2),
                            .white.opacity(0.06),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)
                .blur(radius: 18)
                .scaleEffect(isPulsing ? 1.08 : 1.0)

            // Medium glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.35),
                            .white.opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 32
                    )
                )
                .frame(width: 64, height: 64)
                .blur(radius: 8)
                .scaleEffect(isPulsing ? 1.05 : 1.0)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.65),
                            .white.opacity(0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 16
                    )
                )
                .frame(width: 32, height: 32)
                .blur(radius: 3)

            // Core orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            .white.opacity(0.85)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 9
                    )
                )
                .frame(width: 16, height: 16)

            // Bright center highlight
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .offset(x: -1.5, y: -1.5)
                .blur(radius: 0.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(hex: "2d3436"),
                Color(hex: "636e72")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack {
            BreathingWaveAnimation(
                phase: .inhale,
                phaseProgress: 0.5,
                isRunning: true,
                color: Color(hex: "A0C4D9")
            )
            .frame(height: 250)
            .padding()

            Text("Breathe In")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
