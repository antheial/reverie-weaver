import SwiftUI

struct GlassCloseButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 1. The "Glass" Base
                // Highly transparent fill, just enough to catch light
                Circle()
                    .fill(LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                // 2. The "Refraction" / Edge Shine
                // A crisp, thin border that is brighter at the top-left
                // to simulate light hitting the edge of glass.
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.7), location: 0.1),
                                .init(color: .white.opacity(0.1), location: 0.5),
                                .init(color: .white.opacity(0.3), location: 0.9)  
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    // An subtle inner glow to suggest curvature
                    .shadow(color: .white.opacity(0.3), radius: 1, x: -1, y: -1)

                // 3. The Icon
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    // Slightly off-white so it doesn't compete with the glass shine
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: 36, height: 36)
            // 4. Depth Shadow
            // Lifts the glass off the background
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
        }
    }
}

// MARK: - Preview
// Previewing against a dark, textured background similar to your app
struct GlassCloseButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.25, green: 0.22, blue: 0.20).ignoresSafeArea()
            
            VStack {
                Text("Tap the glass")
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom)
                
                GlassCloseButton {
                    print("Closed tapped")
                }
            }
        }
    }
}
