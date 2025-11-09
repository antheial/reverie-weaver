import SwiftUI

struct MoodBlob: View {
    let mood: Mood
    let size: CGFloat
    
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var rotation: Double = 0
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Middle ground: 4 glow layers
            ForEach(0..<4) { i in
                Circle()
                    .fill(mood.color.opacity(moodGlowOpacity(index: i)))
                    .frame(width: size * (1.6 + CGFloat(i) * 0.35), height: size * (1.6 + CGFloat(i) * 0.35))
                    .blur(radius: 20 + CGFloat(i) * 10)
                    .scaleEffect(pulseAnimation ? 1.25 : 0.88)
                    .opacity(pulseAnimation ? 0.9 : 0.45)
            }
            
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: size, height: size)
                    .offset(y: mood.id == "heavy" ? 10 : 8)
                    .blur(radius: mood.id == "heavy" ? 15 : 12)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: moodGradientColors(),
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.7),
                                        Color.clear,
                                        mood.color.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .scaleEffect(isAnimating ? moodScaleEffect() : 1.0)
                    .rotationEffect(.degrees(rotation))
                    .offset(y: floatOffset)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            center: .init(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size, height: size)
                    .blendMode(.overlay)
                
                // Joyful - Sun rays + sparkles
                if mood.id == "joyful" {
                    ForEach(0..<8) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: size * 0.1)
                            .offset(y: -size * 0.5)
                            .rotationEffect(.degrees(Double(i) * 45 + rotation))
                    }
                    
                    ForEach(0..<6) { i in
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: size * 0.1, height: size * 0.1)
                            .blur(radius: 2)
                            .offset(
                                x: [size * 0.5, -size * 0.5, size * 0.55, -size * 0.55, size * 0.45, -size * 0.45][i],
                                y: [-size * 0.45, -size * 0.4, size * 0.5, size * 0.45, -size * 0.5, size * 0.5][i]
                            )
                            .opacity(pulseAnimation ? 1.0 : 0.3)
                            .scaleEffect(pulseAnimation ? 1.4 : 0.8)
                    }
                } else if mood.id == "good" {
                    ForEach(0..<6) { i in
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: size * 0.08, height: size * 0.08)
                            .blur(radius: 2)
                            .offset(
                                x: [size * 0.45, -size * 0.45, size * 0.5, -size * 0.5, size * 0.4, -size * 0.4][i],
                                y: [-size * 0.4, -size * 0.35, size * 0.45, size * 0.4, -size * 0.45, size * 0.45][i]
                            )
                            .opacity(pulseAnimation ? 1.0 : 0.3)
                            .scaleEffect(pulseAnimation ? 1.3 : 0.7)
                    }
                } else if mood.id == "calm" {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(mood.color.opacity(0.3), lineWidth: 2)
                            .frame(width: size * 0.8, height: size * 0.8)
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                            .opacity(isAnimating ? 0.0 : 0.5)
                            .animation(.easeOut(duration: 2.5).repeatForever(autoreverses: false).delay(Double(i) * 0.8), value: isAnimating)
                    }
                } else if mood.id == "restless" {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(mood.color.opacity(0.6), lineWidth: 2)
                            .frame(width: size * 0.7, height: size * 0.7)
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                            .opacity(isAnimating ? 0.0 : 0.7)
                            .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: isAnimating)
                    }
                }
            }
        }
        .shadow(color: mood.color.opacity(mood.id == "joyful" ? 0.7 : 0.6), radius: 25, x: 0, y: 10)
        .onAppear {
            startAnimations()
        }
    }
    
    private func moodGlowOpacity(index: Int) -> Double {
        switch mood.id {
        case "joyful": return 0.55 - Double(index) * 0.1
        case "good": return 0.45 - Double(index) * 0.09
        case "calm": return 0.38 - Double(index) * 0.07
        case "okay": return 0.28 - Double(index) * 0.055
        case "restless": return 0.45 - Double(index) * 0.09
        case "heavy": return 0.33 - Double(index) * 0.07
        default: return 0.38 - Double(index) * 0.09
        }
    }
    
    private func moodGradientColors() -> [Color] {
        switch mood.id {
        case "joyful":
            return [mood.color.opacity(1.0), mood.color, mood.color.opacity(0.9)]
        case "good":
            return [mood.color.opacity(0.65), mood.color, mood.color.opacity(0.85)]
        case "calm":
            return [mood.color.opacity(0.95), mood.color, mood.color.opacity(0.8)]
        case "heavy":
            return [mood.color.opacity(0.9), mood.color.opacity(0.95), mood.color.opacity(0.7)]
        default:
            return [mood.color.opacity(0.95), mood.color, mood.color.opacity(0.75)]
        }
    }
    
    private func moodScaleEffect() -> CGFloat {
        switch mood.id {
        case "joyful": return 1.2
        case "good": return 1.15
        case "calm": return 1.08
        case "restless": return 1.12
        case "heavy": return 1.03
        default: return 1.1
        }
    }
    
    private func startAnimations() {
        let duration: Double
        switch mood.id {
        case "joyful": duration = 1.0
        case "good": duration = 1.5
        case "calm": duration = 3.5
        case "okay": duration = 2.5
        case "restless": duration = 1.0
        case "heavy": duration = 3.0
        default: duration = 1.8
        }
        
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
        
        let pulseDuration: Double
        switch mood.id {
        case "joyful": pulseDuration = 1.2
        case "good": pulseDuration = 2.0
        case "restless": pulseDuration = 1.0
        case "calm": pulseDuration = 4.0
        case "heavy": pulseDuration = 3.8
        default: pulseDuration = 2.5
        }
        
        withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        if mood.id == "joyful" {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        } else if mood.id == "good" || mood.id == "restless" {
            withAnimation(.linear(duration: mood.id == "restless" ? 3 : 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        
        if mood.id == "calm" || mood.id == "good" || mood.id == "joyful" {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = mood.id == "joyful" ? -8 : -5
            }
        } else if mood.id == "heavy" {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                floatOffset = 3
            }
        }
    }
}
