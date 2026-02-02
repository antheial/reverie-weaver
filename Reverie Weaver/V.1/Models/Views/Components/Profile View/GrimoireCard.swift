//
//  GrimoireCard.swift
//  Reverie Weaver
//
//  Refined Tarot Style: "The Midnight Esoteric"
//  FINAL POLISH:
//  - Custom "Sharp" North Star Graphic
//  - Refined "Celestial Compass" Card Back
//  - Restored Date on Front
//

import SwiftUI


// MARK: - Motion Glow Component (Subtle Pulse)
struct MagicalUnlockGlow: View {
    @State private var isPulsing = false
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                // Gold color that fades between transparent and visible
                Color(hex: "FFD700").opacity(isPulsing ? 0.8 : 0.2),
                lineWidth: 2
            )
            .shadow(
                // The glow radius expands and contracts
                color: Color(hex: "FFD700").opacity(isPulsing ? 0.6 : 0.1),
                radius: isPulsing ? 8 : 2
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct GrimoireCard: View {
    let constellation: ConstellationBadge
    let colorScheme: ColorScheme
    
    // Dimensions for 2-Column Grid
    private let width: CGFloat = 160
    private let height: CGFloat = 240
    private let cornerRadius: CGFloat = 16
    
    // Palette
    private let goldColor = Color(hex: "D4AF37") // Antique Gold
    private let midnightStart = Color(hex: "0F172A") // Deep Slate
    private let midnightEnd = Color(hex: "151515")   // Near Black
    
    var body: some View {
            ZStack {
                // 1. PHYSICAL CARD BASE
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [midnightStart, midnightEnd],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        // Subtle Noise/Texture
                        Image(systemName: "circle.fill")
                            .resizable(resizingMode: .tile)
                            .foregroundStyle(.white)
                            .opacity(0.02)
                            .blendMode(.overlay)
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 6, y: 4)
                
                // 2. CONTENT LAYER
                if constellation.isUnlocked {
                    unlockedFace
                } else {
                    lockedBack
                }
                
                // 3. EDGE HIGHLIGHT (Standard Border)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [goldColor.opacity(0.1), goldColor.opacity(0.4), goldColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                // 4. MAGICAL UNLOCK GLOW (New Location: Overlay)
                if constellation.isUnlocked && !constellation.hasBeenViewed {
                    MagicalUnlockGlow(cornerRadius: cornerRadius)
                }
            }
            .frame(width: width, height: height)
        }
    
    // MARK: - UNLOCKED FACE
    private var unlockedFace: some View {
        ZStack {
            // A. BORDER SYSTEM
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(goldColor.opacity(0.5), lineWidth: 1)
                    .padding(6)
                
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        goldColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                    )
                    .padding(10)
                
                // Corner Stars
                VStack {
                    HStack {
                        Image(systemName: "star.fill").font(.system(size: 6)).foregroundStyle(goldColor)
                        Spacer()
                        Image(systemName: "moon.stars.fill").font(.system(size: 6)).foregroundStyle(goldColor)
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "moon.fill").font(.system(size: 6)).foregroundStyle(goldColor)
                        Spacer()
                        Image(systemName: "star.fill").font(.system(size: 6)).foregroundStyle(goldColor)
                    }
                }
                .padding(8)
            }
            
            // B. MAIN CONTENT
            VStack(spacing: 0) {
                // Roman Numeral
                Text(constellation.chapter.romanNumeral)
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(goldColor.opacity(0.8))
                    .padding(.top, 18)
                
                Spacer()
                
                // C. CENTRAL ART
                ZStack {
                    // Sunburst
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(LinearGradient(colors: [goldColor.opacity(0), goldColor.opacity(0.15)], startPoint: .bottom, endPoint: .top))
                            .frame(width: 1, height: 50)
                            .offset(y: -35)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                    
                    // Diamond Frame
                    Rectangle()
                        .stroke(goldColor.opacity(0.4), lineWidth: 1)
                        .frame(width: 65, height: 65)
                        .rotationEffect(.degrees(45))
                    
                    // Inner Glow
                    Circle()
                        .fill(Color(hex: constellation.colorHex).opacity(0.2))
                        .frame(width: 60, height: 60)
                        .blur(radius: 12)
                    
                    // Icon
                    Image(systemName: constellation.iconName)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color(hex: constellation.colorHex))
                        .shadow(color: Color(hex: constellation.colorHex).opacity(0.8), radius: 6)
                }
                
                Spacer()
                
                // D. TITLE & DATE
                VStack(spacing: 4) {
                    Text(constellation.name.uppercased())
                        .font(.system(size: 11, weight: .black, design: .serif))
                        .tracking(1)
                        .foregroundStyle(Color(hex: "E5E5E5"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 10)
                    
                    // Divider
                    HStack(spacing: 4) {
                        Rectangle().fill(goldColor.opacity(0.4)).frame(height: 0.5)
                        Image(systemName: "diamond.fill").font(.system(size: 4)).foregroundStyle(goldColor)
                        Rectangle().fill(goldColor.opacity(0.4)).frame(height: 0.5)
                    }
                    .frame(width: 60)
                    
                    if let date = constellation.unlockedDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 11, weight: .regular, design: .serif))
                            .foregroundStyle(goldColor.opacity(0.6))
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 18)
            }
        }
    }
    
    // MARK: - LOCKED BACK (Complicated "Astrolabe" Style)
        private var lockedBack: some View {
            ZStack {
                // 1. Double Border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(goldColor.opacity(0.4), lineWidth: 1)
                    .padding(5)
                
                // 2. Complex Geometry Layer
                ZStack {
                    // Ring 1: Dotted Orbit
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [1, 4]))
                        .foregroundStyle(goldColor.opacity(0.3))
                        .frame(width: 130, height: 130)
                    
                    // Ring 2: Solid Orbit
                    Circle()
                        .strokeBorder(goldColor.opacity(0.15), lineWidth: 0.5)
                        .frame(width: 110, height: 110)
                    
                    // Ring 3: Inner Dashed
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [6, 3]))
                        .foregroundStyle(goldColor.opacity(0.2))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(30))
                    
                    // Planetary Dots
                    ForEach(0..<4) { i in
                        Circle()
                            .fill(goldColor.opacity(0.6))
                            .frame(width: 3, height: 3)
                            .offset(y: -55) // On Ring 2
                            .rotationEffect(.degrees(Double(i) * 90 + 45))
                    }
                }
                
                // 3. The Magical Burst North Star
                NorthStarGraphic(color: goldColor)
                
                // 4. Lock Icon
                VStack {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(goldColor.opacity(0.4))
                        .padding(.bottom, 16)
                }
            }
            .drawingGroup()
        }
}

// MARK: - CUSTOM NORTH STAR GRAPHIC (Magical Burst)
struct NorthStarGraphic: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // 1. Radiating "Magical" Burst Lines
            // Shoots thin arrays of light out from the center
            ForEach(0..<16) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.5), color.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 0.5, height: 50)
                    .offset(y: -25)
                    .rotationEffect(.degrees(Double(i) * 22.5))
            }
            
            // 2. Secondary Glow Halo
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)
                .blur(radius: 5)

            // 3. Main vertical/horizontal points (Long & Sharp)
            Image(systemName: "rhombus.fill")
                .resizable()
                .frame(width: 5, height: 65)
                .foregroundStyle(color.opacity(1.0))
                .shadow(color: color.opacity(0.8), radius: 4)
            
            Image(systemName: "rhombus.fill")
                .resizable()
                .frame(width: 5, height: 65)
                .rotationEffect(.degrees(90))
                .foregroundStyle(color.opacity(1.0))
                .shadow(color: color.opacity(0.8), radius: 4)
            
            // 4. Diagonal Rays
            ZStack {
                Image(systemName: "rhombus.fill")
                    .resizable()
                    .frame(width: 4, height: 35)
                    .rotationEffect(.degrees(45))
                
                Image(systemName: "rhombus.fill")
                    .resizable()
                    .frame(width: 4, height: 35)
                    .rotationEffect(.degrees(-45))
            }
            .foregroundStyle(color.opacity(0.7))
            
            // 5. Central Diamond Core
            Image(systemName: "rhombus.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.white)
                .shadow(color: .white, radius: 3)
                .overlay(
                    Image(systemName: "sparkle")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .scaleEffect(0.5)
                )
        }
    }
}
