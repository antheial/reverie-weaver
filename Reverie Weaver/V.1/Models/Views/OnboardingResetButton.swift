//
//  OnboardingResetButton.swift
//  Reverie Weaver
//
//  Created by Xcode Assistant on 1/15/26.
//

import SwiftUI

/// A debug/settings button to reset onboarding state
/// Useful for testing or allowing users to view onboarding again
struct OnboardingResetButton: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showConfirmation = false
    
    var body: some View {
        Button {
            showConfirmation = true
        } label: {
            HStack {
                Text("View Onboarding Again")
                    .font(.system(size: 15, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Spacer()
                
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .buttonStyle(.plain)
        .alert("View Onboarding Again?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset") {
                resetOnboarding()
            }
        } message: {
            Text("This will show the onboarding screens again when you restart the app.")
        }
    }
    
    private func resetOnboarding() {
        hasCompletedOnboarding = false
        ReverieHaptics.lightFeedback()
        
        // Optionally, you could restart the app or show onboarding immediately
        // For now, user needs to kill and restart the app
    }
}

#Preview {
    ZStack {
        ReverieWeaverBackground()
        
        OnboardingResetButton()
            .padding()
    }
}
