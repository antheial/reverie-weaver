import SwiftUI
import SwiftData

/// ✅ BULLETPROOF: Removed audioFileName - audio files use deterministic naming
/// Files are named: "moodmemo_<year>_<day>_morning.m4a" or "moodmemo_<year>_<day>_evening.m4a"
/// This prevents database corruption from breaking audio file references
@Model
final class MoodEntry {
    var dayOfYear: Int
    var moodId: String
    var moodName: String
    var moodColor: String
    var reflection: String
    var date: Date
    var year: Int
    
    init(dayOfYear: Int, moodId: String, moodName: String, moodColor: String, reflection: String, date: Date, year: Int) {
        self.dayOfYear = dayOfYear
        self.moodId = moodId
        self.moodName = moodName
        self.moodColor = moodColor
        self.reflection = reflection
        self.date = date
        self.year = year
    }
}
