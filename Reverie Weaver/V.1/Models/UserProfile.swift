//
// User profile and settings
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var personalMotto: String
    var weekStartsOnSunday: Bool
    var weeklyRestDayLimit: Int
    var createdAt: Date
    
    init(
        displayName: String = "Weaver",
        personalMotto: String = "",
        weekStartsOnSunday: Bool = true,
        weeklyRestDayLimit: Int = 2
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.personalMotto = personalMotto
        self.weekStartsOnSunday = weekStartsOnSunday
        self.weeklyRestDayLimit = weeklyRestDayLimit
        self.createdAt = Date()
    }
}
