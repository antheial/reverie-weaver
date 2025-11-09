import SwiftData
import Foundation

extension Habit {
    static func fromTemplate(_ template: Project50Habit, order: Int) -> Habit {
        Habit(
            name: template.name,
            description: template.description,
            category: template.category,
            categoryIcon: template.icon,
            icon: template.icon,
            colorHex: template.colorHex,
            order: order
        )
    }
}
