//
//  ConnectionClarityPrompts.swift
//  Reverie Weaver
//
//  Day-specific and tier-specific journal prompts for Connection Clarity Week
//  Uses only text prompts - no emoji
//

import Foundation

struct ConnectionClarityPrompts {
    
    /// Get enriched, context-aware prompt based on day and tier completed
    static func prompt(for day: Int, tier: CompletionTier) -> String {
        let prompts: [Int: [CompletionTier: String]] = [
            1: [  // Day 1: Communication Patterns
                .seed: "You noticed a communication pattern today. What feelings came up when you observed it? There's no need to change anything yet—just noticing is enough.",
                .sprout: "What communication pattern did you track today? How might this pattern serve you, and where might it hold you back?",
                .bloom: "After tracking multiple patterns throughout the day, which one felt most significant? What does it reveal about your deeper needs in relationships?"
            ],
            2: [  // Day 2: Deep Listening
                .seed: "You practiced a moment of quiet presence today. What was that like for you? Did any part of it feel uncomfortable?",
                .sprout: "What changed when you truly listened without preparing your response? What did you notice about the other person or the conversation?",
                .bloom: "How did active listening shift the dynamic of your conversation? What did you learn about the other person that you might have missed otherwise?"
            ],
            3: [  // Day 3: "I" Statements
                .seed: "You chose a moment to try an 'I' statement today. How did it feel to frame your needs that way, even in a small situation?",
                .sprout: "When you used 'I feel... because... I need...' today, how did the other person respond? How did their reaction affect you?",
                .bloom: "Which 'I' statement felt most authentic or vulnerable? How did it change the dynamic of the conversation? What surprised you?"
            ],
            4: [  // Day 4: Boundary Practice
                .seed: "You said 'no' or set a small boundary today. What sensations did you notice in your body before, during, and after?",
                .sprout: "What boundary did you set today? How did the other person react, and how did their response affect your feelings about the boundary?",
                .bloom: "After practicing multiple boundaries, which one felt hardest? What fear or belief was underneath that difficulty? How did you navigate it?"
            ],
            5: [  // Day 5: Healthy Disagreement
                .seed: "You stayed present during a disagreement instead of shutting down or escalating. What helped you do that?",
                .sprout: "How did you navigate conflict differently today? What felt new, uncomfortable, or surprisingly effective?",
                .bloom: "Looking back on the disagreement, what would you do the same? What would you change next time? What did this reveal about your conflict style?"
            ],
            6: [  // Day 6: Conversation Scaffolding
                .seed: "You used a script or phrase when words felt hard to find. How did having that structure help you stay present?",
                .sprout: "Which social script felt most useful today? Did you adapt it to match your own voice and style?",
                .bloom: "After trying multiple scripts, which moments still feel challenging? What custom phrases or structures could you create to support yourself?"
            ],
            7: [  // Day 7: Integration & Compassion
                .seed: "This week, you showed up for yourself—even on the hard days. What's one moment of growth you want to acknowledge?",
                .sprout: "Looking back at the whole week, which day surprised you the most? What does that teach you about yourself and your communication?",
                .bloom: "How has your relationship with communication shifted this week? What practices do you want to carry forward? What feels different now?"
            ]
        ]
        
        return prompts[day]?[tier] ?? "How did today's practice feel for you? What stands out?"
    }
    
    /// Get the final week review prompt (shown in completion summary sheet)
    static var weekReviewPrompt: String {
        """
        Looking back at your Connection Clarity Week:
        
        • Which day felt most significant?
        • What surprised you about your communication patterns?
        • How has your relationship with speaking up or setting boundaries shifted?
        • What practice do you want to keep as you move forward?
        
        Take a moment to honor the courage it took to show up for yourself this week.
        """
    }
}
