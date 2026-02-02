//
//  ONBOARDING_GUIDE.md
//  Reverie Weaver
//
//  Created by Xcode Assistant on 1/15/26.
//

/*

# Reverie Weaver Onboarding System

## Overview

The onboarding system provides a beautiful, multi-screen introduction to Reverie Weaver that matches the app's sophisticated aesthetic. It introduces users to core concepts like habit tracking, completion tiers, guided programs, and daily reflections.

## Features

✨ **5 Beautifully Designed Screens**
- Welcome screen with app philosophy
- Habit tracking introduction
- Completion tiers explanation
- Guided programs overview
- Daily intentions & reflections

🔔 **Integrated Notification Permission**
- Contextual notification request after onboarding
- Optional - users can skip
- Beautiful, branded UI

🎨 **Fully Adaptive Design**
- Time-adaptive backgrounds (dawn, day, dusk, night)
- Dark mode support
- Respects system color scheme
- Consistent with app aesthetic

📱 **Production Ready**
- Uses AppStorage for persistence
- Cannot be dismissed accidentally
- Smooth animations
- Haptic feedback
- Accessibility support

## Implementation

### 1. Main Integration (Already Done)

The onboarding is automatically integrated into `MainTabView.swift`:

```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
@State private var showOnboarding = false

// In body:
.fullScreenCover(isPresented: $showOnboarding) {
    OnboardingView()
}
.task {
    if !hasCompletedOnboarding {
        try? await Task.sleep(for: .milliseconds(100))
        showOnboarding = true
    }
}
```

### 2. Files Created

- **OnboardingView.swift** - Main onboarding flow (5 screens + notification prompt)
- **OnboardingResetButton.swift** - Settings button to view onboarding again
- **ONBOARDING_GUIDE.md** - This documentation file

## Usage

### For Users

On first launch:
1. Users see 5 onboarding screens explaining core features
2. Swipe or tap "Next" to advance
3. Tap "Skip" to jump to the end
4. Final screen shows "Get Started" button
5. Notification permission prompt (can be skipped)
6. App loads normally

### For Developers

#### Reset Onboarding (Testing)

**Option 1: Using the Reset Button**
Add this to ProfileView or a settings screen:

```swift
import SwiftUI

struct ProfileView: View {
    var body: some View {
        List {
            Section("Developer") {
                OnboardingResetButton()
            }
        }
    }
}
```

**Option 2: Manual Reset**
In Xcode:
1. Go to the app container
2. Delete app data, or
3. Run this in a button/debug menu:

```swift
UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
```

**Option 3: Preview**
Use SwiftUI previews to test:

```swift
#Preview("Onboarding") {
    OnboardingView()
}

#Preview("Notification Permission") {
    NotificationPermissionView {
        print("Completed")
    }
}
```

#### Customize Content

Edit the `pages` array in `OnboardingView.swift`:

```swift
private let pages: [OnboardingPage] = [
    OnboardingPage(
        icon: "custom.icon",
        iconColor: Color(hex: "ABC123"),
        title: "Your Title",
        subtitle: "Your subtitle",
        description: "Your description",
        features: [
            ("icon.name", "Feature description"),
            ("icon.name2", "Another feature")
        ]
    ),
    // ... more pages
]
```

#### Disable Onboarding (Testing)

Temporarily disable onboarding:

```swift
// In MainTabView.swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true  // Set to true
```

Or use command line:

```bash
# For simulator
xcrun simctl spawn booted defaults write com.yourapp.ReverieWeaver hasCompletedOnboarding -bool true
```

## Technical Details

### State Management

Uses `@AppStorage` for persistence:

```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
```

This key is stored in `UserDefaults` and persists across app launches.

### Flow Control

1. **MainTabView** checks `hasCompletedOnboarding` on launch
2. If `false`, shows `OnboardingView` in `.fullScreenCover`
3. **OnboardingView** has 5 pages users can swipe through
4. Last page shows "Get Started" button
5. Tapping "Get Started" shows **NotificationPermissionView**
6. After notification prompt (approve or skip), onboarding completes
7. `hasCompletedOnboarding` set to `true`
8. View dismisses and app loads normally

### Notification Handling

The notification permission is now handled by onboarding:

- **Before**: MainTabView requested permission after 500ms delay
- **After**: OnboardingView requests permission at end of flow
- The `hasRequestedNotificationPermission` AppStorage key is set by onboarding

### Animations

All animations match Reverie Weaver style:

```swift
.spring(response: 0.4, dampingFraction: 0.8)  // Page transitions
.spring(response: 0.3, dampingFraction: 0.7)  // Page indicators
```

### Accessibility

- All pages use `.accessibilityLabel()` and `.accessibilityHint()`
- Skip button for users who want to get started quickly
- Readable fonts and high contrast
- VoiceOver friendly

## Design Philosophy

The onboarding follows Reverie Weaver's core design principles:

1. **Classy & Sophisticated**
   - Elegant gradient icons
   - Serif fonts for titles
   - Premium card styling
   - Subtle animations

2. **Breathing Room**
   - Generous spacing between elements
   - Not cramped or cluttered
   - Clear visual hierarchy

3. **Time-Adaptive**
   - Background changes with time of day
   - Text colors adapt for readability
   - Consistent with main app experience

4. **Mindful & Welcoming**
   - Gentle language
   - Not overwhelming
   - Focuses on philosophy and values
   - Encourages sustainable habits

## Color Palette

Uses existing Reverie Weaver colors:

- **Welcome**: `#9BB5CE` (Soft blue - water.waves)
- **Habits**: `#8FBC8F` (Sage green - checkmark)
- **Tiers**: `#B8D4C8` (Mint - leaf)
- **Programs**: `#9B7EBD` (Purple - book)
- **Reflections**: `#E8927C` (Coral - heart)
- **Notifications**: `#FFB347` (Warm gold - bell)

## Gradients

All buttons use the app's signature gradients:

```swift
// Primary action (Get Started, Next)
LinearGradient(
    colors: [Color(hex: "9B7EBD"), Color(hex: "7A9CC6")],
    startPoint: .leading,
    endPoint: .trailing
)

// Notification permission
LinearGradient(
    colors: [Color(hex: "FFB347"), Color(hex: "FFCC33")],
    startPoint: .leading,
    endPoint: .trailing
)
```

## Future Enhancements

Potential improvements:

1. **Animated Illustrations**
   - Add Lottie animations to each page
   - Showcase habit completion flow
   - Demonstrate tier selection

2. **Interactive Tutorial**
   - Let users complete a sample habit
   - Show how tier selection works
   - Practice setting an intention

3. **Personalization**
   - Ask for user's name
   - Select favorite habit categories
   - Choose initial programs

4. **Progressive Onboarding**
   - Show mini-tutorials on first use of features
   - "Discover" moments throughout app
   - Tooltips for advanced features

5. **Localization**
   - Support multiple languages
   - Adapt imagery for different cultures
   - Right-to-left layout support

## Troubleshooting

### Onboarding Not Showing

Check:
1. Is `hasCompletedOnboarding` set to `false`?
2. Is `.fullScreenCover` properly attached to the view?
3. Does `showOnboarding` state get set to `true`?

### Onboarding Shows Every Launch

Check:
1. Is `hasCompletedOnboarding` being set to `true` properly?
2. Is AppStorage key spelled correctly?
3. Are you testing on simulator (data persists between builds)?

### Notification Permission Not Requesting

Check:
1. Has permission already been granted/denied?
2. Reset permission: Settings > Privacy > Notifications
3. On simulator, reset content and settings
4. Check `HabitNotificationManager` is working

### Styling Issues

Check:
1. Is `ReverieWeaverBackground` accessible?
2. Are color extensions (`Color(hex:)`) imported?
3. Is `timeAdaptiveText` modifier working?
4. Is `reverieCardStyle` modifier available?

## Testing Checklist

Before shipping:

- [ ] Test on iPhone SE (small screen)
- [ ] Test on iPhone Pro Max (large screen)
- [ ] Test on iPad (if supported)
- [ ] Test in Light Mode
- [ ] Test in Dark Mode
- [ ] Test at different times of day (time-adaptive)
- [ ] Test VoiceOver
- [ ] Test with notification permission already granted
- [ ] Test with notification permission already denied
- [ ] Test skip button
- [ ] Test page swiping
- [ ] Test "Maybe Later" on notifications
- [ ] Verify haptic feedback
- [ ] Verify animations are smooth
- [ ] Verify onboarding doesn't show again after completion

## Support

For questions or issues:
1. Check this guide
2. Review `OnboardingView.swift` implementation
3. Test with SwiftUI previews
4. Use the `OnboardingResetButton` for testing

---

**Last Updated**: January 15, 2026
**Version**: 1.0
**Author**: Xcode Assistant

*/
