import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [MoodEntry]
    
    @State private var currentScreen: ScreenType = .year
    @State private var selectedDay: Int?
    @State private var showQuickAdd = false
    
    enum ScreenType {
        case year, entry, view, settings
    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    private var currentDayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    }
    
    private var yearEntries: [MoodEntry] {
        allEntries.filter { $0.year == currentYear }
    }
    
    var body: some View {
        Group {
            switch currentScreen {
            case .year:
                YearView(
                    // ❌ REMOVED: entries: yearEntries,
                    currentYear: currentYear,
                    currentDayOfYear: currentDayOfYear,
                    showQuickAdd: $showQuickAdd,
                    selectedDay: $selectedDay,
                    currentScreen: $currentScreen
                )
            case .entry:
                EntryView(
                    selectedDay: $selectedDay,
                    currentScreen: $currentScreen,
                    currentYear: currentYear
                    // ❌ REMOVED: entries: yearEntries
                )
            case .view:
                ViewEntryView(
                    selectedDay: $selectedDay,
                    currentScreen: $currentScreen,
                    currentYear: currentYear
                    // ❌ REMOVED: entries: yearEntries
                )
            case .settings:
                SettingsView(
                    currentScreen: $currentScreen,
                    entries: yearEntries,
                    modelContext: modelContext
                )
            }
        }
    }
}

