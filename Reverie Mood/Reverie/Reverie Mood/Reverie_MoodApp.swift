import SwiftUI
import SwiftData

@main
struct Reverie_MoodApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [MoodEntry.self])  // ← ADD THIS LINE
    }
}
