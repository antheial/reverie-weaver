//
//  CompletionTier+Points.swift
//  Reverie Weaver
//
//  Extension to add points system to CompletionTier
//  (Optional - can be used for gamification if desired)
//

import Foundation

extension CompletionTier {
    var points: Int {
        switch self {
        case .seed:   return 1
        case .sprout: return 2
        case .bloom:  return 3
        }
    }

    var sfSymbol: String {
        switch self {
        case .seed:   return "leaf.fill"
        case .sprout: return "leaf.circle.fill"
        case .bloom:  return "sparkles"
        }
    }
}
