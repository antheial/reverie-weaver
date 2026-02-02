# Info.plist Requirements for Notifications

## Required Key

Your `Info.plist` file MUST contain this key for notifications to work:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>Reverie Weaver sends gentle reminders to help you build consistent habits and maintain your daily practice.</string>
```

## How to Add in Xcode

### Method 1: Using Info.plist file directly
1. Open `Info.plist` in your project navigator
2. Right-click → Add Row
3. Key: `NSUserNotificationsUsageDescription`
4. Type: `String`
5. Value: `Reverie Weaver sends gentle reminders to help you build consistent habits and maintain your daily practice.`

### Method 2: Using Target Settings
1. Select your app target
2. Go to "Info" tab
3. Under "Custom iOS Target Properties"
4. Click "+" button
5. Select "Privacy - User Notifications Usage Description"
6. Enter: `Reverie Weaver sends gentle reminders to help you build consistent habits and maintain your daily practice.`

## Verification

After adding, rebuild your app. When you toggle "Reminder" in HabitFormSheet, you should see a system alert:

```
"Reverie Weaver" Would Like to Send You Notifications

Reverie Weaver sends gentle reminders to help you 
build consistent habits and maintain your daily practice.

[Don't Allow]  [Allow]
```

## If Missing

If this key is missing:
- ❌ Permission alert will show generic text
- ❌ App may be rejected from App Store
- ⚠️ Users won't understand why you need notifications

## Alternative Descriptions

You can customize the description text. Good examples:

**Short & Simple:**
```
Get gentle reminders for your daily habits
```

**Feature-focused:**
```
Receive timely notifications to complete your habits and maintain your streaks
```

**Benefit-oriented (Current):**
```
Reverie Weaver sends gentle reminders to help you build consistent habits and maintain your daily practice.
```

**Emotional:**
```
Let us remind you of the rituals that weave your days with intention and meaning
```

Choose one that matches your app's tone and clearly explains the value to users.

---

## Optional: Time-Sensitive Notifications

If you want notifications to break through Focus modes (iOS 15+), you need:

### Entitlement File
Request from Apple: https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/

Add to your entitlements file:
```xml
<key>com.apple.developer.usernotifications.time-sensitive</key>
<true/>
```

**Note:** This requires Apple approval and justification. Your app currently falls back gracefully if this isn't available.

---

**Status:** ✅ Required key should already be in your Info.plist (mentioned in NOTIFICATION_DEBUG_GUIDE.md)
