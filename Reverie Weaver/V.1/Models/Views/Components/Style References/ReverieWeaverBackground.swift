import SwiftUI

// MARK: - Reverie Weaver Background Component
struct ReverieWeaverBackground: View {
    @State private var currentHour: Int = Calendar.current.component(.hour, from: Date())
    @State private var hourUpdateTimer: Timer?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Time-based gradient
            LinearGradient(
                colors: timeBasedColors(),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Real paper texture overlay
            Image("paper-texture")
                .resizable(resizingMode: .tile)
                .contrast(1.15)   // boosts paper fibers
                .brightness(-0.03)
                .blendMode(colorScheme == .dark ? .overlay : .multiply)
                .opacity(colorScheme == .dark ? 0.33 : 0.33)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            // Film grain overlay
            NoiseOverlayView()
                .opacity(colorScheme == .dark ? 0.15 : 0.15)
                .blendMode(.softLight)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            // Adaptive header scrim for text readability (3-9 PM, light mode only)
            if colorScheme == .light && needsHeaderScrim() {
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(headerScrimOpacity()), location: 0),
                        .init(color: Color.black.opacity(headerScrimOpacity() * 0.5), location: 0.3),
                        .init(color: Color.clear, location: 0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Immediately update to current hour when view appears
            currentHour = Calendar.current.component(.hour, from: Date())

            // Only create timer if one doesn't exist
            guard hourUpdateTimer == nil else { return }

            // Update hour every minute
            hourUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentHour = Calendar.current.component(.hour, from: Date())
            }
        }
        .onDisappear {
            // Invalidate timer to prevent memory leak
            hourUpdateTimer?.invalidate()
            hourUpdateTimer = nil
        }
    }
    
    // MARK: - Header Scrim (for text readability during bright periods)

    /// Determines if a header scrim should be shown (3-9 PM)
    private func needsHeaderScrim() -> Bool {
        switch currentHour {
        case 15..<17, 17..<19, 19..<21:
            return true
        default:
            return false
        }
    }

    /// Returns the appropriate scrim opacity based on time period
    private func headerScrimOpacity() -> Double {
        switch currentHour {
        case 15..<17:
            return 0.06  // Late Afternoon - subtle
        case 17..<19:
            return 0.08  // Golden Hour - slightly stronger for warm amber
        case 19..<21:
            return 0.05  // Dusk - lighter, already has better contrast
        default:
            return 0
        }
    }

    // MARK: - Time-Based Colors

    private func timeBasedColors() -> [Color] {
           // OVERRIDE: If system is in dark mode, use dark palette regardless of time
        if colorScheme == .dark {
            // Use the same currentHour state as light mode for consistency
            let hour = currentHour
            
            switch hour {
            case 0..<5:
                // Deep Night - Warm dark tones
                return [
                    Color(hex: "1A1612"),  // Deep warm near-black
                    Color(hex: "2C2520"),  // Deep warm grey
                    Color(hex: "3D3530"),  // Muted warm slate
                    Color(hex: "4A3F35")   // Subtle warm brown
                ]
                
            case 21..<24:
                // Evening - Warm transition
                return [
                    Color(hex: "2C2520"),  // Warm charcoal
                    Color(hex: "3A2F28"),  // Deep coffee
                    Color(hex: "4A3830"),  // Warm slate
                    Color(hex: "5C4A3D")   // Subtle brown
                ]
                
            default:
                // General dark mode (when system dark mode is on during day)
                return [
                    Color(hex: "1C1816"),  // Warm near-black
                    Color(hex: "2A2520"),  // Deep warm grey
                    Color(hex: "38322D"),  // Muted warm brown
                    Color(hex: "463F38")   // Soft earth tone
                ]
            }
        }
           
           // ENHANCED: More authentic time-of-day gradients
           switch currentHour {
           case 0..<5:
               // Deep Night - Darkest hours (Midnight to pre-dawn)
               return [
                   Color(hex: "0D1B2A"), // Deep midnight blue
                   Color(hex: "1B263B"), // Dark slate
                   Color(hex: "415A77")  // Muted steel blue
               ]
               
           case 5..<7:
               // Dawn - Magical twilight transition (5-7 AM)
               return [
                   Color(hex: "2B4162"), // Deep twilight blue
                   Color(hex: "73628A"), // Lavender grey
                   Color(hex: "E8B4B8"), // Soft rose dawn
                   Color(hex: "FFD5C2")  // Peach morning light
               ]
               
           case 7..<9:
               // Early Morning - Fresh awakening (7-9 AM)
               return [
                   Color(hex: "FFE5D4"), // Warm cream
                   Color(hex: "FFF4E6"), // Soft butter
                   Color(hex: "E8F4F8"), // Fresh morning blue
                   Color(hex: "FFF8DC")  // Cornsilk
               ]
               
           case 9..<12:
               // Late Morning - Bright and energized (9 AM-Noon)
               return [
                   Color(hex: "FFF9F0"), // Bright cream
                   Color(hex: "E3F2FD"), // Clear sky blue
                   Color(hex: "FFFEF7"), // Pure light
                   Color(hex: "F0F8FF")  // Alice blue
               ]
               
           case 12..<15:
               // Early Afternoon - Peak sunlight (Noon-3 PM)
               return [
                   Color(hex: "FFFDF7"), // Brilliant white
                   Color(hex: "FFF8E1"), // Sunny cream
                   Color(hex: "E1F5FE"), // Bright sky
                   Color(hex: "FFFEF9")  // Peak light
               ]
               
           case 15..<17:
               // Late Afternoon - Warmth softening (3-5 PM)
               return [
                   Color(hex: "FFF4E0"), // Warm afternoon
                   Color(hex: "FFE9C5"), // Golden cream
                   Color(hex: "E8EAF6"), // Softening sky
                   Color(hex: "FFF0D4")  // Amber glow
               ]
               
           case 17..<19:
               // Golden Hour - Magical warm light (5-7 PM)
               return [
                   Color(hex: "FFD4A3"), // Golden amber
                   Color(hex: "FFB88C"), // Warm peach
                   Color(hex: "D4A5A5"), // Dusty rose
                   Color(hex: "9B8B9F")  // Purple dusk begins
               ]
               
           case 19..<21:
               // Dusk - Twilight descends (7-9 PM)
               return [
                   Color(hex: "E89E7C"), // Coral sunset
                   Color(hex: "B58FAD"), // Mauve twilight
                   Color(hex: "8B7BA8"), // Purple dusk
                   Color(hex: "5E6FA3")  // Evening blue
               ]
               
           case 21..<24:
               // Evening - Night settles (9 PM-Midnight)
               // Uses warm dark tones to support wind-down/rest period
               // Same palette as deep night (0-5 AM) for sleep preparation
               return [
                   Color(hex: "1A1612"),  // Deep warm near-black
                   Color(hex: "2C2520"),  // Deep warm grey
                   Color(hex: "3D3530"),  // Muted warm slate
                   Color(hex: "4A3F35")   // Subtle warm brown
               ]
               
           default:
               // Fallback (should never hit)
               return [
                   Color(hex: "1B2845"),
                   Color(hex: "2D3E5C"),
                   Color(hex: "3A4A63")
               ]
           }
       }
   }

// MARK: - Noise Overlay (Core Image Film Grain)
struct NoiseOverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            if let noiseImage = generateNoiseImage(size: geometry.size) {
                Image(uiImage: noiseImage)
                    .resizable(resizingMode: .tile)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func generateNoiseImage(size: CGSize) -> UIImage? {
        // Create small tileable noise pattern (more performant)
        let tileSize = CGSize(width: 128, height: 128)
        
        guard let filter = CIFilter(name: "CIRandomGenerator") else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        // Crop to tile size
        let croppedImage = outputImage.cropped(to: CGRect(origin: .zero, size: tileSize))
        
        // Create grayscale noise
        let context = CIContext()
        guard let cgImage = context.createCGImage(croppedImage, from: CGRect(origin: .zero, size: tileSize)) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Seeded Random Number Generator (for consistent pattern)
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Example Usage
struct WeaverExampleView: View {
    var body: some View {
        ZStack {
            ReverieWeaverBackground()
            
            VStack(spacing: 20) {
                Text("Good Morning")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Wednesday")
                    .font(.system(size: 36, weight: .bold))
                
                Text("Wednesday, October 22, 2025")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                // Your cards with refined styling
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Every small step weaves the fabric of your journey.")
                            .font(.system(size: 14))
                            .italic()
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
}

// MARK: - Preview
#Preview("Light Mode") {
    WeaverExampleView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    WeaverExampleView()
        .preferredColorScheme(.dark)
}
