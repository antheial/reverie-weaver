//
//  ConstellationStar.swift
//  Reverie Weaver
//
//  Model representing a completed challenge as a star in the achievement constellation
//

import SwiftUI

struct ConstellationStar: Identifiable {
    let id: String
    let type: ChallengeType
    let name: String
    let completedDate: Date
    let icon: String
    let color: Color
    /// Optional subtitle (e.g., "85%" for partial challenge completion)
    var subtitle: String?

    init(
        id: String,
        type: ChallengeType,
        name: String,
        completedDate: Date,
        icon: String,
        color: Color,
        subtitle: String? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.completedDate = completedDate
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }

    enum ChallengeType {
        case miniChallenge
        case themeWeek
        case project50
        case restWeek  // Intentional rest days (1-2 per week)
        
        var starSize: CGFloat {
            switch self {
            case .project50: return 32
            case .miniChallenge: return 26
            case .themeWeek: return 22
            case .restWeek: return 18  // Smaller, gentler presence
            }
        }
        
        var glowRadius: CGFloat {
            switch self {
            case .project50: return 10
            case .miniChallenge: return 8
            case .themeWeek: return 6
            case .restWeek: return 4  // Softer, moonlight glow
            }
        }
    }
}
