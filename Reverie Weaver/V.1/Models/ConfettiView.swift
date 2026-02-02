//
//  ConfettiView.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/20/25.
//
//  ENHANCED:
//  - 3D Rotation (Flutter effect)
//  - Horizontal Drift
//  - GPU Rendering (.drawingGroup)
//  - Mixed Shapes (Confetti + Dots)
//

import SwiftUI

// MARK: - Confetti View
struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var confettiPieces: [ConfettiPiece] = []
    
    // Configuration
    private let particleCount = 50
    private let colors: [Color] = [
        .sageGreen,
        .dustyBlue,
        .terracottaRose,
        .paleMauve,
        .sageGreen.opacity(0.7), // Add depth with opacity variants
        .terracottaRose.opacity(0.8)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiShapeView(piece: piece)
                        .position(piece.position)
                        .offset(x: piece.drift, y: 0) // Horizontal sway
                        .rotationEffect(.degrees(piece.rotation2D))
                        .rotation3DEffect(
                            .degrees(piece.rotation3D),
                            axis: (x: piece.anchorX, y: piece.anchorY, z: 0)
                        )
                        .opacity(piece.opacity)
                }
            }
            .drawingGroup() // 🚀 GPU Acceleration: Critical for performance
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, active in
                if active {
                    generateConfetti(in: geometry.size)
                } else {
                    // Fade out gracefully before removing?
                    // For now, instant removal to reset state is cleaner for re-triggering
                    confettiPieces.removeAll()
                }
            }
        }
    }
    
    private func generateConfetti(in size: CGSize) {
        // Reset
        confettiPieces = []
        
        // Generate new batch
        for _ in 0..<particleCount {
            let randomX = CGFloat.random(in: 0...size.width)
            
            // Randomize start height slightly so they don't all fall in a flat line
            let randomStartY = CGFloat.random(in: -100 ... -20)
            
            let piece = ConfettiPiece(
                color: colors.randomElement() ?? .sageGreen,
                shape: Bool.random() ? .circle : .capsule,
                size: CGFloat.random(in: 6...10),
                position: CGPoint(x: randomX, y: randomStartY),
                drift: 0,
                rotation2D: Double.random(in: 0...360),
                rotation3D: Double.random(in: 0...360),
                anchorX: CGFloat.random(in: 0...1),
                anchorY: CGFloat.random(in: 0...1),
                opacity: 1.0,
                destY: size.height + 100 // Target is below screen
            )
            confettiPieces.append(piece)
        }
        
        // Trigger Animation Frame
        // Slight delay ensures the view renders the initial state before moving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateConfetti()
        }
    }
    
    private func animateConfetti() {
        for i in 0..<confettiPieces.count {
            // Randomize duration for organic feel (some fall fast, some slow)
            let duration = Double.random(in: 1.5...2.5)
            let delay = Double.random(in: 0...0.2) // Shorter delay spread
            
            withAnimation(.easeOut(duration: duration).delay(delay)) {
                // 1. Fall down
                confettiPieces[i].position.y = confettiPieces[i].destY
                
                // 2. Drift horizontally (Wind effect)
                confettiPieces[i].drift = CGFloat.random(in: -50...50)
                
                // 3. Spin 2D
                confettiPieces[i].rotation2D += Double.random(in: 180...360)
                
                // 4. Flutter 3D (The paper effect)
                confettiPieces[i].rotation3D += Double.random(in: 360...720)
                
                // 5. Fade out at the very end
                // Note: We use a separate animation for opacity usually,
                // but linear fading works fine here.
            }
            
            // Separate opacity animation to make them disappear before hitting absolute bottom
            withAnimation(.linear(duration: 0.5).delay(duration - 0.5)) {
                confettiPieces[i].opacity = 0
            }
        }
    }
}

// MARK: - Supporting Models & Views

enum ConfettiShape {
    case circle
    case capsule
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let shape: ConfettiShape
    let size: CGFloat
    
    // Animation States
    var position: CGPoint
    var drift: CGFloat
    var rotation2D: Double
    var rotation3D: Double
    
    // Physics properties
    let anchorX: CGFloat // For 3D rotation axis
    let anchorY: CGFloat // For 3D rotation axis
    var opacity: Double
    let destY: CGFloat   // Where it lands
}

struct ConfettiShapeView: View {
    let piece: ConfettiPiece
    
    var body: some View {
        Group {
            switch piece.shape {
            case .circle:
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
            case .capsule:
                Capsule()
                    .fill(piece.color)
                    // Capsules are rectangular bits of confetti
                    .frame(width: piece.size * 0.6, height: piece.size * 1.5)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        ConfettiView(isActive: .constant(true))
    }
}
