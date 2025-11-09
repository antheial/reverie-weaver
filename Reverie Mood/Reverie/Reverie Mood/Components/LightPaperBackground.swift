//
//  LightPaperBackground.swift
//  Reverie Mood
//
//  Created by Antheia Li on 10/19/25.
//


import SwiftUI

// 🌅 Light dreamy "paper" background
struct LightPaperBackground: View {
    let drift: Bool
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.96, blue: 0.93), // cream
                        Color(red: 1.00, green: 0.92, blue: 0.96), // pink
                        Color(red: 0.95, green: 0.94, blue: 1.00)  // lavender
                    ],
                    startPoint: UnitPoint(x: 0.1 + (drift ? 0.08 : 0.0), y: 0.0),
                    endPoint: UnitPoint(x: 0.9, y: 1.0)
                )
                Ellipse()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: w * 0.9, height: h * 0.6)
                    .blur(radius: 60)
                    .offset(x: drift ? w * 0.06 : 0, y: -h * 0.28)
                Ellipse()
                    .fill(Color.pink.opacity(0.12))
                    .frame(width: w * 0.85, height: h * 0.7)
                    .blur(radius: 80)
                    .offset(x: drift ? -w * 0.04 : -w * 0.08, y: h * 0.35)
            }
            .animation(.easeInOut(duration: 8), value: drift)
        }
        .ignoresSafeArea()
    }
}

// 🌌 Dark ethereal "Dreamfield" night background
struct DarkEtherealBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.06, green: 0.03, blue: 0.10),
                    Color(red: 0.05, green: 0.02, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.purple.opacity(0.16), .clear],
                center: .top,
                startRadius: 40,
                endRadius: 600
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}
