//
//  ConfettiView.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/20/25.
//

import SwiftUI


// MARK: - Confetti View
struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(piece.position)
                    .opacity(piece.opacity)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                generateConfetti()
            } else {
                confettiPieces.removeAll()
            }
        }
    }
    
    private func generateConfetti() {
           let colors: [Color] = [.sageGreen, .dustyBlue, .terracottaRose, .paleMauve]
           confettiPieces = (0..<30).map { _ in
               ConfettiPiece(
                   color: colors.randomElement()!,
                   size: CGFloat.random(in: 6...12),
                   position: CGPoint(
                       x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                       y: -50
                   ),
                   opacity: 1.0
               )
           }
           
           animateConfetti()
       }
    
    private func animateConfetti() {
           for i in 0..<confettiPieces.count {
               withAnimation(.easeOut(duration: Double.random(in: 1...2)).delay(Double(i) * 0.05)) {
                   confettiPieces[i].position.y = UIScreen.main.bounds.height + 50
                   confettiPieces[i].opacity = 0
               }
           }
       }
   }

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

