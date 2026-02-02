//
// MiniChallengeData.swift
// Reverie Weaver
//
// Enhanced with identity statements, if-then plans, and anchor moments
// 7-day Mini Challenges (3 habits each)
//

import Foundation
import SwiftUI

// MARK: - Challenge Tier Enum

enum ChallengeTier: String, Codable, CaseIterable {
    case foundation = "Foundation"
    case core = "Core"
    case specialized = "Specialized"
    case program = "Programs"
    
    var description: String {
        switch self {
        case .foundation:
            return "Gentle practices to start building habits"
        case .core:
            return "Essential wellbeing practices"
        case .specialized:
            return "Targeted challenges for specific goals"
        case .program:
            return "Multi-week programs for deep transformation"
        }
    }
    
    var icon: String {
        switch self {
        case .foundation: return "leaf.fill"
        case .core: return "heart.fill"
        case .specialized: return "target"
        case .program: return "calendar"
        }
    }
    
    var color: String {
        switch self {
        case .foundation: return "8BA888"  // Sage green
        case .core: return "9B7EBD"         // Lavender
        case .specialized: return "E8927C"  // Terracotta
        case .program: return "A3C7D6"      // Dusty blue
        }
    }
}

// MARK: - Challenge Tag Enum

enum ChallengeTag: String, Codable, CaseIterable {
    // Wellbeing Domains
    case mental = "Mental"
    case physical = "Physical"
    case emotional = "Emotional"
    case social = "Social"
    case spiritual = "Spiritual"
    
    // Focus Areas
    case stress = "Stress & Calm"
    case sleep = "Sleep & Energy"
    case movement = "Movement"
    case nutrition = "Nutrition"
    case creativity = "Creativity"
    case focus = "Focus & Productivity"
    case connection = "Relationships"
    case selfCompassion = "Self-Compassion"
    case boundaries = "Boundaries"
    case digital = "Digital Wellness"
    case nature = "Nature"
    case gratitude = "Gratitude"
    case nervous = "Nervous System"
    case body = "Body Image"
    case financial = "Financial"
    
    // Special Categories
    case beginner = "Beginner-Friendly"
    case neurodivergent = "Neurodivergent-Friendly"
    case strengthTraining = "Strength Training"
    case tcm = "Traditional Chinese Medicine"
    case scienceBacked = "Science-Backed"
}

// MARK: - Mini Challenge Model

struct MiniChallenge: Identifiable, Codable {
    var id: String { tag }
    let title: String
    let tagline: String
    let description: String
    let tag: String
    let colorHex: String
    let icon: String
    let identityStatement: String
    let habits: [Project50Habit]
    
    // MARK: - Metadata for Organization & Composition
    let tier: ChallengeTier
    let tags: [ChallengeTag]
    let durationWeeks: Int
    let programGroup: String?
}

// MARK: - Mini Challenge Catalog

struct MiniChallengeData {
    static let challenges: [MiniChallenge] = [
        
        // MARK: - 1. CIRCADIAN RESET
        
        MiniChallenge(
            title: "Circadian Reset",
            tagline: "Sync your inner clock",
            description: "A 7-day challenge to align your biology with natural light cycles—the foundation for better sleep, energy, mood, and focus. Morning light + evening dimming + consistent timing.",
            tag: "CircadianReset",
            colorHex: "F4C896",
            icon: "sun.horizon.fill",
            identityStatement: "Become someone whose body knows when to wake, when to focus, and when to rest",
            habits: [
                Project50Habit(
                    name: "Sunlight Within 60",
                    description: """
                    Get 10+ minutes of outdoor light within 1 hour of waking.

                    • Core: Step outside (no sunglasses) or sit by an open window. Even cloudy days provide bright natural light.
                    • Timing Note: Within 1 hour of waking is ideal. 10-20 minutes is a good target. Outdoor light is more effective than indoor.
                    • Anchor: Pair with morning coffee/tea on porch, or walk around the block.
                    • If-then: After I wake up and brush my teeth, I will step outside with my morning drink for 10 minutes.
                    
                                                            •
                    💡 [Stack Tip]: Wake -> Bathroom -> Coffee/tea -> Step outside with your drink -> Sit or walk for 10 minutes while soaking in light -> Write 3 gratitudes (Gratitude Glow) while still outside. This single 15-minute morning ritual hits circadian reset, gratitude practice, and outdoor connection—three wellness goals in one seamless flow. Your coffee becomes the bridge that makes morning light irresistible.
                                        
                    • Why It Works: Morning light exposure supports your body's natural daily rhythms and can help with alertness and sleep timing.
                    • Rescue: 
                      - Can't go outside? Sit by brightest window for 20 min
                      - Cloudy day? Still go out—natural light helps even when overcast
                      - Missed morning? Get bright midday light instead
                    """,
                    icon: "sunrise.fill",
                    colorHex: "F6D5A8",
                    category: "Circadian Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CircadianReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Sunset Mode",
                    description: """
                    Dim all lights 2-3 hours before target sleep time.

                    • Core: 
                      - Turn off overhead lights, use lamps/candles instead
                      - Enable Night Shift/blue light filters on all screens
                      - Wear blue light blocking glasses if using screens
                      - Keep lights below eye level
                      - Why Evening Dimming Matters: Lower light levels in the evening help support your natural wind-down process.
                    • Anchor: Set alarm for 2 hours before target bedtime → "Begin sunset mode"
                    • If-then: When my sunset alarm goes off at 9 PM, I will dim all lights and enable Night Shift.
                    
                                                                                •
                    💡 [Stack Tip]: Set "sunset alarm" for 9 PM -> Dim ALL lights in home (overhead off, lamps on) -> Enable Night Shift on devices -> Begin wind-down activities (tea, reading, gentle stretching, connection time) -> This naturally flows into sleep prep. By linking light dimming with evening activities, your brain learns "dim lights = day is ending," making the transition to sleep feel automatic rather than forced.
                    
                    • Why It Works: Evening dimming creates a psychological wind-down cue. Supports your body's natural preparation for rest. Helps separate day activities from sleep time.
                    • Rescue:
                      - Can't control all lights? At least dim bedroom
                      - Must use screens? Night Shift + 30% brightness + blue blockers
                      - Even 1 hour of dimming helps
                    """,
                    icon: "sunset.fill",
                    colorHex: "F5C08C",
                    category: "Circadian Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CircadianReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Same Time Waking",
                    description: """
                    Wake up at the same time every day (±30 min), even weekends.

                    • Core: 
                      - Choose realistic wake time based on current pattern
                      - Set alarm for same time 7 days/week
                      - Get up within 30 min of target, even if you slept poorly
                      - Try to keep a similar schedule on weekends when possible
                    • Timing Notes:
                      - Consistent wake time can be a helpful daily anchor
                      - Many people find this more manageable than strict bedtimes
                      - Within 30 minutes of your target time is a reasonable goal
                      - Weekend: Try to stay within an hour of your weekday wake time
                    • Anchor: Set alarm + place phone across room so you must stand to turn it off.
                    • If-then: When my alarm goes off at [chosen time], I will get up within 30 minutes, even if I'm tired.
                    
                                                                                •
                    💡 [Stack Tip]: Alarm rings -> Stand immediately (no snooze) -> Bathroom -> Splash face with water -> Get morning light (Habit 1: step outside or sit by window) -> Return feeling awake. This automatic sequence eliminates decision-making when willpower is lowest. Each step physically leads to the next—standing gets you to bathroom, bathroom leads you outside for light. By the time you've completed the chain, you're fully awake and on time.
                    
                    • Why It Works:
                      - Helps your body develop consistent wake patterns
                      - Consistency supports better sleep patterns over time
                      - Many people find this helps with daily energy and mood
                    • Week-by-Week:
                      - Week 1: Lock in current time (give or take 30 minutes)
                      - Can shift 15-30 min earlier gradually if desired
                    • Rescue:
                      - Slept terribly? Still wake at target time when possible
                      - Weekend: Try to stay within 30 minutes of your usual time
                    """,
                    icon: "alarm.fill",
                    colorHex: "F2BB80",
                    category: "Circadian Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CircadianReset",
                    durationDays: 7
                )
            ],
            tier: .foundation,
            tags: [.sleep, .physical, .mental, .scienceBacked, .beginner],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 2. GRATITUDE GLOW
        
        MiniChallenge(
            title: "Gratitude Glow",
            tagline: "Notice the good",
            description: "A 7-day practice in savoring what's already here—people, moments, small joys.",
            tag: "GratitudeGlow",
            colorHex: "F4B183",
            icon: "heart.fill",
            identityStatement: "Become someone who sees beauty in ordinary moments",
            habits: [
                Project50Habit(
                    name: "3 Grateful Moments",
                    description: """
                    Each morning, write down 3 specific things you're grateful for.

                    • Core: Be specific—not "my family" but "my daughter's laugh this morning."
                    • Anchor: With your first coffee or tea, before checking your phone.
                    • If-then: After I pour my morning drink, I will write 3 grateful moments.
                    
                                                                                •
                    💡 [Stack Tip]: Pour morning coffee/tea -> Step outside or sit by bright window (Circadian Reset) -> Write 3 gratitudes in notebook while sipping -> Savor one more moment before starting your day. This 10-minute ritual makes gratitude practice effortless by pairing it with something you already love (your morning drink) and natural light. The sensory pleasure of your beverage + sunlight creates a positive reinforcement loop that makes the practice sticky.
                    
                    • Consistency supports better sleep patterns over time
                    • Rescue: Just write 1 specific thing. Quality over quantity.
                    """,
                    icon: "sunrise.fill",
                    colorHex: "EDB892",
                    category: "Gratitude Glow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GratitudeGlow",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Gratitude Text",
                    description: """
                    Send one genuine thank-you message to someone each day.

                    • Core: Tell someone why they matter or what they did that helped you.
                    • Anchor: Mid-afternoon break or during lunch.
                    • If-then: When I take my afternoon break, I will send one gratitude text.
                    
                                                                                •
                    💡 [Stack Tip]: Feel urge to check phone -> Pause -> Go to bathroom first -> While washing hands, send gratitude text -> THEN allow yourself to scroll if you still want to. This "urge surfing" approach uses your phone-checking impulse as a reminder, then delays gratification just long enough to insert the positive behavior. Often, after sending the text, the urge to scroll mindlessly fades—you've already gotten the social connection hit your brain wanted.
                    
                    • Why It Works: Expressing gratitude strengthens relationships and can support positive feelings.
                    • Rescue: A simple "Thank you for being you" is enough.
                    """,
                    icon: "text.bubble.fill",
                    colorHex: "F0C5A6",
                    category: "Gratitude Glow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GratitudeGlow",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Savor One Moment",
                    description: """
                    Pause once daily to fully experience something good.

                    • Core: Notice all the sensory details—what you see, hear, feel, smell, taste.
                    • Anchor: During a meal, morning coffee, or sunset walk.
                    • If-then: When I notice something pleasant, I will pause and savor it for 10 seconds.
                    
                                                                                •
                    💡 [Stack Tip]: After writing 3 gratitudes (Habit 1) -> Set down pen -> Pick up your coffee/tea -> Close your eyes -> Take one slow sip, noticing temperature, taste, aroma, texture -> Breathe -> Open eyes. This 10-second savoring pause transforms a routine sip into a mindfulness practice. By stacking it immediately after gratitude journaling, you're already in a reflective state—savoring becomes the natural next step, not an extra effort.
                    
                    • Why It Works: Savoring can help extend positive feelings beyond just a quick moment of noticing.
                    • Rescue: Just pause for 3 seconds and take one deep breath while noticing something good.
                    """,
                    icon: "sparkle",
                    colorHex: "F5D4B8",
                    category: "Gratitude Glow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GratitudeGlow",
                    durationDays: 7
                )
            ],
            tier: .foundation,
            tags: [.gratitude, .mental, .emotional, .beginner],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 2. BREATH & CALM
        MiniChallenge(
            title: "Breath & Calm",
            tagline: "Anchor in your breath",
            description: "A 7-day exploration of simple breathing practices to find calm in chaos.",
            tag: "BreathCalm",
            colorHex: "A3C7D6",
            icon: "wind",
            identityStatement: "Become someone who can find their center anywhere",
            habits: [
                Project50Habit(
                    name: "5-5-5 Breathing",
                    description: """
                    Do 5 breaths (5 sec in, 5 sec hold, 5 sec out) 3x daily.

                    • Core: Morning, midday, evening—set alarms if needed.
                    • Anchor: With your morning coffee, lunch break, and before bed.
                    • If-then: When my breathing alarm goes off, I will do 5 full breaths.
                    • Why It Works:  Controlled breathing helps create a sense of calm and centeredness.
                    • Rescue: Even 2 full breaths can help you feel more centered.
                    """,
                    icon: "wind.circle.fill",
                    colorHex: "B2D3E2",
                    category: "Breath & Calm",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BreathCalm",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Stress Response Breathing",
                    description: """
                    When stress hits, pause for 3 conscious breaths.

                    • Core: Notice stress → pause → 3 slow breaths before reacting.
                    • Anchor: When you notice tension, frustration, or overwhelm.
                    • If-then: When I feel stress rising, I will pause for 3 breaths before responding.
                    • Why It Works: Creates space between stimulus and response.
                    • Rescue: One deep breath is better than none.
                    """,
                    icon: "exclamationmark.triangle.fill",
                    colorHex: "C0DEEC",
                    category: "Breath & Calm",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BreathCalm",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Bedtime Breath Ritual",
                    description: """
                    End your day with 10 slow, conscious breaths in bed.

                    • Core: In bed, lights off, just breathing slowly.
                    • Anchor: After you get into bed and turn off the lights.
                    • If-then: After I turn off my light, I will do 10 slow breaths.
                    • Why It Works: Evening breathing supports your wind-down routine.
                    • Rescue: 3 breaths is enough to start the relaxation response.
                    """,
                    icon: "moon.stars.fill",
                    colorHex: "CFEAF6",
                    category: "Breath & Calm",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BreathCalm",
                    durationDays: 7
                )
            ],
            tier: .foundation,
            tags: [.stress, .nervous, .mental, .beginner, .scienceBacked],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 3. NATURE THREAD
        MiniChallenge(
            title: "Nature Thread",
            tagline: "Step outside, breathe",
            description: "A 7-day practice of connecting with the natural world, even in small doses.",
            tag: "NatureThread",
            colorHex: "8FA584",
            icon: "leaf.circle.fill",
            identityStatement: "Become someone who seeks nature as restoration",
            habits: [
                Project50Habit(
                    name: "Morning Sunlight",
                    description: """
                    Get 10 minutes of natural light within 1 hour of waking.

                    • Core: Step outside or sit by a window—no sunglasses.
                    • Anchor: Right after waking up or with your morning coffee.
                    • If-then: After I wake up, I will step outside for 10 minutes.
                    • Why It Works: Morning light supports your body's natural daily rhythms and can help with mood.
                    • Rescue: Even 3 minutes of morning light helps.
                    """,
                    icon: "sun.max.fill",
                    colorHex: "9FB393",
                    category: "Nature Thread",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NatureThread",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Touch Something Living",
                    description: """
                    Physically connect with nature once daily.

                    • Core: Touch a tree, feel grass, water a plant, pet an animal.
                    • Anchor: During your walk or when you step outside.
                    • If-then: When I'm outside, I will touch something living.
                    • Why It Works: Physical contact with nature supports a sense of calm.
                    • Rescue: Water one plant or touch one leaf.
                    """,
                    icon: "hand.raised.fill",
                    colorHex: "ADC1A2",
                    category: "Nature Thread",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NatureThread",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Notice One Natural Thing",
                    description: """
                    Find something in nature to observe for 2 minutes.

                    • Core: A cloud, bird, tree, flower—watch it change or move.
                    • Anchor: During any time you're outside.
                    • If-then: When I'm outside, I will pause to observe one natural element.
                    • Why It Works: Nature observation supports present-moment awareness.
                    • Rescue: Look at the sky for 30 seconds.
                    """,
                    icon: "eye.fill",
                    colorHex: "BCD0B1",
                    category: "Nature Thread",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NatureThread",
                    durationDays: 7
                )
            ],
            tier: .foundation,
            tags: [.nature, .stress, .physical, .mental, .beginner],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 4. ENERGY RECHARGE
        MiniChallenge(
            title: "Energy Recharge",
            tagline: "Sleep better, rest deeper",
            description: "A 7-day sleep optimization challenge that helps you wind down naturally and wake up refreshed.",
            tag: "EnergyRecharge",
            colorHex: "7A9CC6",
            icon: "moon.stars.fill",
            identityStatement: "Become someone who prioritizes rest as fuel, not guilt",
            habits: [
                Project50Habit(
                    name: "Screen Sunset",
                    description: """
                    Dim screens 1 hour before bed to let your brain prepare for sleep.

                    • Core: Turn on Night Shift/blue light filter at sunset. No bright screens 1 hour before bed.
                    • Anchor: Set an alarm for 1 hour before your target bedtime.
                    • If-then: When my sunset alarm goes off, I will enable Night Shift and dim my screen.
                    
                                                                                •
                    💡 [Stack Tip]: Sunset alarm (9 PM) -> Enable Night Shift + dim screens to 30% brightness -> Put phone on "Do Not Disturb" -> Begin wind-down ritual (Habit 2: dim lights, warm drink, light stretch, skincare) -> Brain dump worries (Habit 3: 5-min journal) -> Place phone on charger in another room -> Into bed by 10:30 PM. This 90-minute sequence transforms evening chaos into a sleep preparation system. Each habit naturally flows into the next, and by removing your phone at the END (not the beginning), you avoid the "just one more check" trap.
                    
                    • Why It Works: Blue light from screens can interfere with your natural sleep readiness.
                    • Rescue: If you must use screens, at least enable Night Shift and dim brightness to 50%.
                    """,
                    icon: "sunset.fill",
                    colorHex: "96B0D5",
                    category: "Energy Recharge",
                    program: "miniChallenge",
                    level: nil,
                    tag: "EnergyRecharge",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Wind-Down Ritual",
                    description: """
                    Create a 15-min evening routine to signal bedtime to your body.

                    • Core: Same sequence nightly—dim lights, tea/water, light stretch, skin care, journal.
                    • Anchor: Right after dinner or 30 minutes before target bedtime.
                    • If-then: After I finish dinner, I will begin my wind-down sequence.
                    
                                                                                •
                    💡 [Stack Tip]: Finish dinner -> Clear table together (builds connection) -> Dim lights to warm glow -> Make herbal tea or warm water -> Light stretch or gentle yoga (5 min) -> Skincare ritual -> Brain dump journal (Habit 3: release day's worries) -> Get into bed. This 15-20 minute sequence happens in the same order every night, training your body to recognize "dinner complete = sleep preparation begins." The consistency is what makes it automatic—your body starts relaxing the moment you clear the table.
                    
                    • Why It Works: Consistent routines train your body to recognize sleep cues.
                    • Rescue: Just dim the lights and do 2 deep breaths. The ritual can be 2 minutes.
                    """,
                    icon: "sparkles",
                    colorHex: "A5C0E3",
                    category: "Energy Recharge",
                    program: "miniChallenge",
                    level: nil,
                    tag: "EnergyRecharge",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Brain Dump Before Bed",
                    description: """
                    Write down tomorrow's worries so they don't keep you awake.

                    • Core: Spend 5 minutes listing any worries, to-dos, or racing thoughts. Close the notebook.
                    • Anchor: Right before you get into bed or after brushing teeth.
                    • If-then: When I notice my mind racing, I will write it down and close the notebook.
                    
                                                                                •
                    💡 [Stack Tip]: Complete wind-down ritual (Habit 2) -> Sit in comfortable spot with journal -> Spend 5 minutes writing worries, to-dos, racing thoughts -> Close notebook physically -> Take 3 deep breaths -> Brush teeth -> Get into bed -> Optional: 5-5-5 breathing (Breath & Calm) to finish the transition. This naturally closes your day and transitions to sleep. The physical act of closing the notebook + the breath work create a psychological "period" at the end of your day's sentence.
                    
                    • Why It Works: Externalizing worries helps you let go and settle into rest more easily.
                    • Rescue: Just write 3 words or one sentence. Any amount helps.
                    """,
                    icon: "book.closed.fill",
                    colorHex: "B5CFED",
                    category: "Energy Recharge",
                    program: "miniChallenge",
                    level: nil,
                    tag: "EnergyRecharge",
                    durationDays: 7
                )
            ],
            tier: .core,
            tags: [.sleep, .physical, .mental, .scienceBacked],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 5. MOVEMENT MAGIC
        MiniChallenge(
            title: "Movement Magic",
            tagline: "Gentle daily motion",
            description: "A 7-day invitation to move your body in ways that feel good, not punishing.",
            tag: "MovementMagic",
            colorHex: "B8A0C6",
            icon: "figure.walk",
            identityStatement: "Become someone who moves for joy, not obligation",
            habits: [
                Project50Habit(
                    name: "10-Min Morning Movement",
                    description: """
                    Wake up your body with gentle stretching or movement.

                    • Core: Yoga, stretching, tai chi, dance in your kitchen—anything that feels good.
                    • Anchor: Right after you get out of bed or after your morning drink.
                    • If-then: After I get out of bed, I will do 10 minutes of gentle movement.
                    
                                                                                •
                    💡 [Stack Tip]: Wake -> Bathroom -> Morning light (10 min outside, Circadian Reset) -> Return inside -> 10-min movement while coffee brews -> Drink & gratitude. This 25-minute sequence naturally wakes your body and mind while hitting multiple wellness goals.
                    
                    • Why It Works: Morning movement can support energy and mood for the day ahead.
                    • Rescue: Just 2 minutes of stretching in bed counts.
                    """,
                    icon: "sunrise",
                    colorHex: "C4AED2",
                    category: "Movement Magic",
                    program: "miniChallenge",
                    level: nil,
                    tag: "MovementMagic",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Walk & Notice",
                    description: """
                    Take a 15-minute walk and notice what you see, hear, feel.

                    • Core: No podcast, no agenda—just walking and observing.
                    • Anchor: Lunch break or after-work transition time.
                    • If-then: During my lunch break, I will take a 15-minute observation walk.
                    
                                                                                •
                    💡 [Stack Tip]: Close laptop -> Leave phone at desk -> 15-min mindful walk outside -> Touch something living (Nature Thread) -> Return refreshed for afternoon work. This midday reset prevents the 3 PM energy crash and naturally combines movement with nature connection.
                    
                    • Why It Works: Walking meditation supports mental clarity and present-moment awareness.
                    • Rescue: A 5-minute walk around the block is enough.
                    """,
                    icon: "figure.walk.motion",
                    colorHex: "CFBDDE",
                    category: "Movement Magic",
                    program: "miniChallenge",
                    level: nil,
                    tag: "MovementMagic",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Movement Snacks",
                    description: """
                    Do 3 tiny movement breaks throughout the day (2-3 minutes each).

                    • Core: Desk stretches, jumping jacks, dance break, wall push-ups—anything brief.
                    • Anchor: Set 3 alarms or do after bathroom breaks.
                    • If-then: When my movement alarm goes off, I will do 2 minutes of any movement.
                    
                                                                                •
                    💡 [Stack Tip]: Bathroom break -> 2-min movement snack -> Refill water bottle -> Return to work. Using natural bathroom trips as your anchor means you'll never "forget" to move, and hydration + movement compound to keep energy steady all day.
                    
                    • Why It Works: Breaking up sitting time helps maintain energy throughout the day.
                    • Rescue: Stand up and stretch your arms overhead for 30 seconds.
                    """,
                    icon: "figure.flexibility",
                    colorHex: "DACCEB",
                    category: "Movement Magic",
                    program: "miniChallenge",
                    level: nil,
                    tag: "MovementMagic",
                    durationDays: 7
                )
            ],
            tier: .core,
            tags: [.movement, .physical, .mental, .stress],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 6. CONNECTION WEEK
        MiniChallenge(
            title: "Connection Week",
            tagline: "Presence over pixels",
            description: "A 7-day relationship reset focused on quality time and genuine presence with people who matter.",
            tag: "ConnectionWeek",
            colorHex: "D4A5A5",
            icon: "person.2.fill",
            identityStatement: "Become someone who shows up fully for the people they love",
            habits: [
                Project50Habit(
                    name: "15-Min Quality Time",
                    description: """
                    Give someone your full, phone-free attention for 15 minutes.

                    • Core: No phone visible. Make eye contact. Listen more than you talk.
                    • Anchor: After dinner or during your morning routine.
                    • If-then: After I finish dinner, I will put my phone away and connect for 15 minutes.
                    
                                                                                •
                    💡 [Stack Tip]: Finish dinner -> Clear table together (sharing the work builds partnership) -> BOTH put phones on charging station in another room (mutual accountability) -> Sit in comfortable space -> Give 15-min undivided attention -> Ask one real question (Habit 2) -> Listen deeply without interrupting -> Express one specific appreciation. This 25-minute post-dinner sequence naturally extends your meal into meaningful connection without needing to "schedule date night." The key is both people putting phones away simultaneously—it removes temptation and signals "we're both choosing presence right now."
                    
                    • Why It Works: Brief moments of full presence create stronger bonds than hours of distracted time.
                    • Rescue: Even 5 minutes of full attention counts.
                    """,
                    icon: "clock.fill",
                    colorHex: "DCB3B3",
                    category: "Connection Week",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ConnectionWeek",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Ask One Real Question",
                    description: """
                    Ask someone an open-ended question and actually listen to their answer.

                    • Core: Use "How did that feel?" or "What was that like?" instead of "How was your day?"
                    • Anchor: During dinner, car ride, or check-in call.
                    • If-then: When I talk to someone I care about, I will ask one deep question.
                    
                                                                                •
                    💡 [Stack Tip]: During your 15-min quality time (Habit 1) -> After a few minutes of comfortable silence or small talk -> Lead with one real question: "What was challenging today?" or "What are you thinking about?" -> Listen to their full answer without planning your response -> Ask one follow-up question -> Share your own honest answer. This structure gives depth to your connection time. The sequence matters: comfort first, then depth. Rushing to deep questions can feel interrogative; building to them feels natural.
                    
                    • Why It Works: Open questions create intimacy and understanding.
                    • Rescue: "How are you really doing?" is enough if that's all you've got.
                    """,
                    icon: "bubble.left.and.bubble.right.fill",
                    colorHex: "E5C1C1",
                    category: "Connection Week",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ConnectionWeek",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Reach Out First",
                    description: """
                    Message or call someone you've been thinking about.

                    • Core: Don't wait for them to reach out. Be the one who initiates.
                    • Anchor: Morning coffee or evening wind-down time.
                    • If-then: When I think of someone, I will send them a message within 5 minutes.
                    
                                                                                •
                    💡 [Stack Tip]: Pour morning coffee -> Sit by window with phone + notebook -> Ask yourself: "Who came to mind this week? Who have I been meaning to reach out to?" -> Write their name -> Compose message before opening any other apps -> Send -> THEN allow yourself to check notifications. This makes reaching out a morning ritual instead of something you "forget" to do. By doing it BEFORE checking messages, you're leading with intention rather than reacting. The coffee + window light makes it a pleasant ritual, not a chore.
                    
                    • Why It Works: Initiating connection helps strengthen relationships.
                    • Rescue: A simple "Thinking of you" text is perfect.
                    """,
                    icon: "paperplane.fill",
                    colorHex: "EDD0D0",
                    category: "Connection Week",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ConnectionWeek",
                    durationDays: 7
                )
            ],
            tier: .core,
            tags: [.connection, .social, .emotional],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 7. REFLECTION RESET
        MiniChallenge(
            title: "Reflection Reset",
            tagline: "Clarity through writing",
            description: "A 7-day self-awareness journey using gentle writing and self-compassion to process what's on your mind.",
            tag: "ReflectionReset",
            colorHex: "FFD18B",
            icon: "pencil.circle.fill",
            identityStatement: "Become someone who understands their inner world with compassion",
            habits: [
                Project50Habit(
                    name: "Morning Pages (Light)",
                    description: """
                    A small daily brain dump to clear mental clutter.

                    • Core: 3 pages of stream-of-consciousness writing (nonsense allowed).
                    • Anchor: With your morning drink (coffee, tea, or water).
                    • If-then: After I get my morning drink, I will open my notebook and start writing.
                    • Why It Works: Writing bypasses your inner critic and accesses deeper thoughts.
                    • Rescue: If 3 pages feels heavy, write for 1 minutes or one sentence.
                    """,
                    icon: "sun.max.fill",
                    colorHex: "FFE5A3",
                    category: "Reflection Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ReflectionReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Emotion Check",
                    description: """
                    Gently notice what you're feeling without fixing it.

                    • Core: Name 3 emotions and where you feel them in your body.
                    • Anchor: During a transition (after work, before dinner, post-commute).
                    • If-then: When I notice strong feelings, I will pause and name them.
                    • Why It Works: Naming emotions supports emotional awareness and clarity.
                    • Rescue: If that's too much, just name 1 emotion and where it lives.
                    """,
                    icon: "heart.text.square.fill",
                    colorHex: "FFE5A3",
                    category: "Reflection Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ReflectionReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Self-Kindness Moment",
                    description: """
                    A tiny self-compassion break when you're struggling.

                    • Core: Say to yourself: "This is hard. Everyone struggles. May I be kind to myself."
                    • Anchor: Moments when you catch self-criticism or shame.
                    • If-then: If I judge myself harshly, I will pause and use this self-kindness script.
                    • Why It Works: Self-compassion supports a kinder inner dialogue.
                    • Rescue: If the full script feels like too much, just say: "This is hard" and breathe.
                    """,
                    icon: "heart.fill",
                    colorHex: "FFEFC4",
                    category: "Reflection Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ReflectionReset",
                    durationDays: 7
                )
            ],
            tier: .core,
            tags: [.selfCompassion, .emotional, .mental, .stress],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 8. NERVOUS SYSTEM RESET
        MiniChallenge(
            title: "Nervous System Reset",
            tagline: "Build body awareness",
            description: "A 7-day challenge to build awareness of your body's stress signals and learn accessible calming tools. Essential foundation for emotional regulation and stress resilience.",
            tag: "NervousSystemReset",
            colorHex: "D4A5A5",
            icon: "heart.circle.fill",
            identityStatement: "Become someone who can notice and respond to their body's stress signals",
            habits: [
                Project50Habit(
                    name: "Body Scan Check-In",
                    description: """
                    Notice tension in jaw, shoulders, belly, hands 3x daily.

                    • Core: Morning, midday, evening—where are you holding stress?
                    • Anchor: Set 3 daily reminders or link to meals.
                    • If-then: When my body scan alarm goes off, I will check jaw, shoulders, belly, hands.
                    
                                                                                •
                    💡 [Stack Tip]: Alarm goes off -> Pause whatever you're doing -> Close eyes -> Scan jaw (unclench), shoulders (drop), belly (soften), hands (release) -> Take 3 breaths (Breath & Calm) -> Return to activity. This 60-second practice interrupts stress accumulation before it becomes chronic tension. Stack with bathroom breaks for natural frequency: "Every time I wash my hands, I scan my body."
                    
                    • Why It Works: Body awareness supports mindful attention to physical signals.
                    • Rescue: Just notice your jaw tension—that alone is valuable.
                    """,
                    icon: "figure.stand",
                    colorHex: "DCB3B3",
                    category: "Nervous System Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NervousSystemReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Cold Water Splash",
                    description: """
                    Splash cold water on face morning and evening.

                    • Core: 30 seconds of cold water on face (or cold shower for last 30 seconds).
                    • Anchor: Morning wake-up and evening wind-down.
                    • If-then: After I brush my teeth, I will splash cold water on my face.
                    
                                                                                •
                    💡 [Stack Tip]: Morning: Wake -> Bathroom -> Splash cold water on face -> Take 3 deep breaths -> Morning movement (10 min). Evening: Before bed routine -> Brush teeth -> Cold water splash -> Body scan (Habit 1) -> Notice the shift from alert to calm. Cold water activates your nervous system differently morning vs. evening—morning = alertness boost, evening = parasympathetic activation through controlled stress.
                    
                    • Why It Works: Cold exposure supports mental alertness and resilience.
                    • Rescue: Just wet your wrists with cold water for 10 seconds.
                    """,
                    icon: "drop.fill",
                    colorHex: "E5C1C1",
                    category: "Nervous System Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NervousSystemReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Grounding Moment",
                    description: """
                    Use 5-4-3-2-1 grounding when you notice dysregulation.

                    • Core: Name 5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste.
                    • Anchor: When you notice panic, overwhelm, or dissociation.
                    • If-then: When I feel overwhelmed, I will do 5-4-3-2-1 grounding.
                    
                                                                                •
                    💡 [Stack Tip]: Notice dysregulation (racing heart, scattered thoughts, freeze) -> Move to a different space if possible -> 5-4-3-2-1 grounding -> Body scan (Habit 1: release jaw, shoulders) -> 3 slow breaths (Breath & Calm) -> Assess: Do I need more support or can I continue? This sequence moves you from "hijacked nervous system" through sensory anchoring to body awareness to breath—a complete regulation pathway you can do anywhere in 2-3 minutes.
                    
                    • Why It Works: Brings you back to present moment and can help you feel calmer.
                    • Rescue: Just name 3 things you can see right now.
                    """,
                    icon: "hand.point.up.braille.fill",
                    colorHex: "EDD0D0",
                    category: "Nervous System Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NervousSystemReset",
                    durationDays: 7
                )
            ],
            tier: .core,
            tags: [.nervous, .stress, .emotional, .physical, .scienceBacked],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 9. CREATIVE FLOW
        MiniChallenge(
            title: "Creative Flow",
            tagline: "Make something daily",
            description: "A 7-day exploration of daily creative practice—no skill, product, or perfection required.",
            tag: "CreativeFlow",
            colorHex: "E89BA3",
            icon: "paintbrush.fill",
            identityStatement: "Become someone who creates for the joy of creating",
            habits: [
                Project50Habit(
                    name: "15-Min Creation Time",
                    description: """
                    Make something—anything—for 15 minutes daily.

                    • Core: Draw, write, build, cook, photograph, collage. Process over product.
                    • Anchor: Right after breakfast or during your lunch break.
                    • If-then: After I finish breakfast, I will create for 15 minutes.
                    • Why It Works: Daily practice builds creative confidence and bypasses perfectionism.
                    • Rescue: 5 minutes of doodling or free-writing counts as a win.
                    """,
                    icon: "scribble",
                    colorHex: "D4AAAA",
                    category: "Creative Flow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeFlow",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "No-Edit Zone",
                    description: """
                    Create without judging, editing, or fixing while you work.

                    • Core: Make the mess. Judgment happens later (or never).
                    • Anchor: Beginning of your creative session—say "This is a no-edit zone."
                    • If-then: If I start criticizing my work, I will remind myself "Edit later, create now."
                    • Why It Works: Separating creation from criticism unlocks flow states.
                    • Rescue: If perfectionism strikes, remind yourself it's practice, not a portfolio.
                    """,
                    icon: "hand.draw.fill",
                    colorHex: "DDBABA",
                    category: "Creative Flow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeFlow",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Creative Input Daily",
                    description: """
                    Consume something inspiring to feed your creative well.

                    • Core: Watch, read, listen to, or observe something that sparks ideas.
                    • Anchor: Evening wind-down or morning commute.
                    • If-then: Before bed, I will spend 10 minutes consuming inspiring content.
                    • Why It Works: Input fuels output—creativity needs inspiration to draw from.
                    • Rescue: Look at one piece of art or listen to one song mindfully.
                    """,
                    icon: "book.fill",
                    colorHex: "E6CBCB",
                    category: "Creative Flow",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeFlow",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.creativity, .mental, .emotional],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 10. FOCUS SPRINT
        
        MiniChallenge(
            title: "Focus Sprint",
            tagline: "Deep work, clear mind",
            description: "A 7-day challenge to build momentum through protected focus time and discover your peak cognitive windows.",
            tag: "FocusSprint",
            colorHex: "9B7EBD",
            icon: "bolt.fill",
            identityStatement: "Become someone who protects their attention and creates focused time daily",
            habits: [
                Project50Habit(
                    name: "Focus Entry Ritual",
                    description: """
                    2-min ritual to tell your brain "This is focus time."

                    • Core: Same music, same drink, same phrase: "This is my time."
                    • Environment Prep: Before starting, close unnecessary tabs, silence phone (or put in another room), clear desk of distractions. Your environment should make focus the path of least resistance.
                    • Anchor: Beginning of your work session, right after you sit at your desk.
                    • If-then: After I sit at my desk, I will start my focus ritual.

                                                                                •
                    💡 [Stack Tip]: Sit at desk -> Close all unnecessary tabs -> Put phone in drawer -> Start focus music -> Make tea/coffee -> Take 3 deep breaths -> Say "This is my time" -> Begin 45-min deep work. This 5-minute ritual becomes a Pavlovian trigger: your brain learns that THIS sequence means "focus mode activated."

                    • Why It Works: Rituals create neural pathways that trigger focus automatically. Environment design removes friction—when distractions aren't available, focus becomes the default.
                    • Rescue: If energy is low, just play the music for 30 seconds and take one breath.
                    """,
                    icon: "play.circle",
                    colorHex: "C5B0E8",
                    category: "Focus Sprint",
                    program: "miniChallenge",
                    level: nil,
                    tag: "FocusSprint",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "45-Min Deep Work",
                    description: """
                    One protected block of single-task work.

                    • Core: 45 minutes, phone in another room, one task only.
                    • Anchor: Right after your morning ritual or first coffee.
                    • If-then: If 45 min feels impossible, I will do at least 15 minutes and then decide.
                    
                                                                                •
                    💡 [Stack Tip]: Complete Morning Architect routine -> Arrive at peak energy window (usually 9-11 AM) -> Focus Entry Ritual (Habit 1) -> 45-min deep work -> 5-min break (Movement Snack) -> Assess if continuing or stopping. Stack your most important work during your biological peak, right after an energizing morning. This is your cognitive sweet spot.
                    
                    • Why It Works: Working in focused blocks trains your attention muscle.
                    • Rescue: Even a 15-minute sprint counts as a full win today.
                    """,
                    icon: "deskclock",
                    colorHex: "C5B0E8",
                    category: "Focus Sprint",
                    program: "miniChallenge",
                    level: nil,
                    tag: "FocusSprint",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Victory Log",
                    description: """
                    End the day by capturing one tiny win.

                    • Core: Write down one thing you accomplished (tiny or big).
                    • Anchor: Before closing your laptop or turning off your desk lamp.
                    • If-then: Before I end my workday, I will log today's win.
                    
                                                                                •
                    💡 [Stack Tip]: Finish work -> Close all tabs -> Log today's win (1 sentence) -> Shut down laptop -> Transition walk/movement -> Leave work behind mentally. This 5-minute closing ritual creates psychological separation between "work mode" and "life mode," while building momentum through daily wins. Pair with Energy Recharge's evening routine for seamless day-to-night transition.
                    
                    • Why It Works: Recognizing progress builds momentum and motivation.
                    • Rescue: If writing feels hard, just think of one good moment and whisper it to yourself.
                    """,
                    icon: "star.circle",
                    colorHex: "D9C8FF",
                    category: "Focus Sprint",
                    program: "miniChallenge",
                    level: nil,
                    tag: "FocusSprint",
                    durationDays: 7
                )
            ],
            tier: .core,
            tags: [.focus, .mental, .digital],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 11. DIGITAL DETOX
        MiniChallenge(
            title: "Digital Detox",
            tagline: "Reclaim your attention",
            description: "A 7-day experiment in reducing mindless scrolling and reconnecting with the offline world.",
            tag: "DigitalDetox",
            colorHex: "91B4A8",
            icon: "iphone.slash",
            identityStatement: "Become someone who uses technology intentionally, not reactively",
            habits: [
                Project50Habit(
                    name: "No Phone for 1 Hour",
                    description: """
                    Choose 1 hour daily where your phone stays in another room.

                    • Core: Pick the same hour each day (ideally morning or evening).
                    • Notification Audit (Day 1): Before starting this challenge, go to Settings > Notifications and disable all non-essential notifications. Keep only: calls, messages from close contacts, calendar. This one-time setup removes constant digital interruptions for the entire week.
                    • Anchor: Right after waking up or right after dinner.
                    • If-then: After I wake up, I will leave my phone charging for 1 hour.

                                                                                •
                    💡 [Stack Tip]: Wake -> Leave phone charging in another room -> Morning Architect ritual (bathroom, water, movement, gratitude) -> Check phone AFTER 60 minutes. This stacks perfectly with your morning routine and reclaims your first hour from reactive scrolling. Your morning becomes YOURS, not your inbox's.

                    • Why It Works: Breaking the morning phone habit supports a calmer start to your day. Disabling notifications reduces the "pull" even when you do check your phone.
                    • Rescue: Even 30 minutes phone-free is a victory.
                    """,
                    icon: "moon.zzz.fill",
                    colorHex: "A0C2B6",
                    category: "Digital Detox",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DigitalDetox",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Grayscale Mode",
                    description: """
                    Turn your phone screen to grayscale to make it less visually engaging.

                    • Core: Settings > Accessibility > Display > Color Filters > Grayscale.
                    • Anchor: Enable it before bed, keep it on until after breakfast.
                    • If-then: Before I go to sleep, I will turn on grayscale mode.
                    
                                                                                •
                    💡 [Stack Tip]: Evening Sanctuary begins -> Enable grayscale + Night Shift -> Put phone in another room -> Wind-down ritual (reading, tea, stretching) -> Sleep. Morning: Complete morning routine -> Disable grayscale AFTER breakfast. Grayscale bookends your day, protecting both your evening wind-down and morning intention.
                    
                    • Why It Works: Grayscale makes your phone less visually engaging.
                    • Rescue: Use grayscale just during your most vulnerable scroll times.
                    """,
                    icon: "circle.lefthalf.filled",
                    colorHex: "B0D1C5",
                    category: "Digital Detox",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DigitalDetox",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Offline Evening Activity",
                    description: """
                    Do one screen-free activity each evening.

                    • Core: Read physical book, sketch, cook, walk, talk, play music—anything analog.
                    • Anchor: After dinner or right before wind-down routine.
                    • If-then: After dinner, I will choose one offline activity for 20 minutes.
                    
                                                                                •
                    💡 [Stack Tip]: Dinner ends -> Clean up together (Connection Week quality time) -> Both phones on charging station -> 20-min offline activity (reading, crafting, conversation) -> Evening Sanctuary prep -> Bed. This sequence naturally transitions from shared meal to shared presence to individual wind-down, eliminating the "scroll until bedtime" trap.
                    
                    • Why It Works: Replacing scrolling with real activities rewires your reward system.
                    • Rescue: Even 10 minutes of offline time counts.
                    """,
                    icon: "leaf.fill",
                    colorHex: "C0DFD4",
                    category: "Digital Detox",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DigitalDetox",
                    durationDays: 7
                )
            ],
            tier: .core,
            tags: [.digital, .mental, .focus, .sleep],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 12. DOPAMINE DETOX ✨
        MiniChallenge(
            title: "Dopamine Detox",
            tagline: "Reset your reward system",
            description: "A 7-day challenge to build healthier relationships with instant gratification—especially valuable for fast-thinking, novelty-seeking minds.",
            tag: "DopamineDetox",
            colorHex: "7B8FBC",
            icon: "bolt.slash.fill",
            identityStatement: "Become someone who chooses delayed rewards over instant hits",
            habits: [
                Project50Habit(
                    name: "Delay Instant Gratification",
                    description: """
                    Wait 10 minutes before checking social media or news.

                    • Core: When you get the urge to scroll, set a timer for 10 minutes first.
                    • Anchor: When you reach for your phone out of habit.
                    • If-then: When I want to scroll, I will wait 10 minutes and do something else first.
                    • Why It Works: Builds impulse control and supports more intentional choices.
                    • Rescue: Even waiting 2 minutes before checking builds new neural pathways.
                    """,
                    icon: "timer",
                    colorHex: "99AAC9",
                    category: "Dopamine Detox",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DopamineDetox",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "One Analog Activity Daily",
                    description: """
                    Do something that requires sustained attention without instant rewards.

                    • Core: Read physical book, solve puzzle, draw, build, cook from scratch.
                    • Anchor: Evening time or weekend morning.
                    • If-then: After dinner, I will do one analog activity for 20 minutes.
                    • Why It Works: Trains brain to tolerate delayed gratification and build focus.
                    • Rescue: 10 minutes of any analog activity counts.
                    """,
                    icon: "book.closed.fill",
                    colorHex: "A7B7CF",
                    category: "Dopamine Detox",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DopamineDetox",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Boredom Practice",
                    description: """
                    Let yourself be bored for 15 minutes without reaching for stimulation.

                    • Core: Sit, stare, daydream—no phone, book, or distraction.
                    • Anchor: Mid-afternoon or during a natural lull.
                    • If-then: When I feel bored, I will resist the urge to scroll and just sit with it.
                    • Why It Works: Boredom is where creativity lives—especially valuable for minds that crave constant stimulation.
                    • Rescue: 5 minutes of doing absolutely nothing is enough.
                    """,
                    icon: "hourglass",
                    colorHex: "B5C4D5",
                    category: "Dopamine Detox",
                    program: "miniChallenge",
                    level: nil,
                    tag: "DopamineDetox",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.digital, .mental, .focus, .neurodivergent],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 13. FINANCIAL ZEN ✨ NEW
                MiniChallenge(
                    title: "Financial Zen",
                    tagline: "Calm your money mind",
                    description: "A 7-day reset to stop avoiding your finances and start treating money with intentionality and calm.",
                    tag: "FinancialZen",
                    colorHex: "85C7DE", // Serene Blue
                    icon: "banknote.fill",
                    identityStatement: "Become someone who faces their finances with clarity and calm",
                    habits: [
                        Project50Habit(
                            name: "The 1-Minute Money Check",
                            description: """
                            Log into your bank account daily—just to look, not to judge.

                            • Core: Open app. Check balance. Check recent transactions. Close app. Breathe.
                            • Anchor: With your morning coffee or right before starting work.
                            • If-then: Before I open social media, I will check my bank balance.
                            • Why It Works: Regular exposure reduces avoidance. Looking daily removes the "monster in the closet" fear.
                            • Rescue: Open the app. You don't even have to look at the number. Just open it.
                            """,
                            icon: "eye.fill",
                            colorHex: "9AD3E6",
                            category: "Financial Zen",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FinancialZen",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "No-Spend Day (Intentional)",
                            description: """
                            Aim for 0 non-essential spending today.

                            • Core: Spend only on fixed bills/groceries. No coffees, online shopping, or convenience buys.
                            • Anchor: Decide this the night before.
                            • If-then: When I feel the urge to buy something, I will say "Not today" and add it to a list.
                            • Why It Works: Breaks the instant purchase pattern and builds intentional decision-making.
                            • Rescue: If you must spend, pause for 60 seconds before paying.
                            """,
                            icon: "lock.fill",
                            colorHex: "AFDDEB",
                            category: "Financial Zen",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FinancialZen",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "Mindful Purchase Pause",
                            description: """
                            Add a layer of friction between "want" and "buy".

                            • Core: Add items to a "Wait List" instead of a cart. Wait 24 hours.
                            • Anchor: Whenever you browse online or walk through a store.
                            • If-then: If I see something I want, I will take a photo/screenshot and wait 24 hours.
                            • Why It Works: Most impulse buys are emotional regulation. The urge usually fades in hours.
                            • Rescue: Just ask yourself: "Do I actually need this, or am I bored/sad?"
                            """,
                            icon: "cart.badge.minus",
                            colorHex: "C4E7F2",
                            category: "Financial Zen",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FinancialZen",
                            durationDays: 7
                        )
                    ],
                    tier: .specialized,
                    tags: [.financial, .digital, .mental, .stress],
                    durationWeeks: 1,
                    programGroup: nil
                ),
        
        // MARK: - 14. JOY SCAVENGER (Foundation)
        MiniChallenge(
            title: "Joy Scavenger",
            tagline: "Find micro-delights daily",
            description: "A 7-day practice in noticing small moments of joy—a warm cup, a kind word, a perfect song. Train your brain to spot what's already good.",
            tag: "JoyScavenger",
            colorHex: "FFB6C1",
            icon: "sparkle",
            identityStatement: "Become someone who notices beauty in tiny moments",
            habits: [
                Project50Habit(
                    name: "Morning Joy Hunt",
                    description: """
                    Notice 3 small delights before 10 AM.

                    • Core: Actively look for tiny good things—sunlight, a smell, a texture, a sound.
                    • Anchor: During your morning routine (coffee, shower, commute).
                    • If-then: As I move through my morning, I will pause to notice 3 small joys.
                    • Why It Works: Training attention toward positive stimuli rewires negativity bias.
                    • Rescue: Even 1 tiny joy counts as a win.
                    """,
                    icon: "sun.max.fill",
                    colorHex: "FFC1CC",
                    category: "Joy Scavenger",
                    program: "miniChallenge",
                    level: nil,
                    tag: "JoyScavenger",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Joy Capture",
                    description: """
                    Photograph or write down 1 joyful moment daily.

                    • Core: Capture evidence—a photo, a sentence, a voice memo.
                    • Anchor: Whenever you notice something delightful.
                    • If-then: When I feel a spark of joy, I will capture it immediately.
                    • Why It Works: Documenting joy extends its positive emotional impact.
                    • Rescue: A quick phone note saying "warm tea" is enough.
                    """,
                    icon: "camera.fill",
                    colorHex: "FFCCD5",
                    category: "Joy Scavenger",
                    program: "miniChallenge",
                    level: nil,
                    tag: "JoyScavenger",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Evening Joy Share",
                    description: """
                    Share one joy with someone before bed.

                    • Core: Tell a person, text a friend, or post in a group chat.
                    • Anchor: Evening wind-down or right before bed.
                    • If-then: Before I sleep, I will share one small joy with someone.
                    • Why It Works: Sharing joy amplifies it and strengthens social bonds.
                    • Rescue: Send a simple "This made me smile today: ___" message.
                    """,
                    icon: "heart.text.square.fill",
                    colorHex: "FFD7DC",
                    category: "Joy Scavenger",
                    program: "miniChallenge",
                    level: nil,
                    tag: "JoyScavenger",
                    durationDays: 7
                )
            ],
            tier: .foundation,
            tags: [.gratitude, .mental, .emotional, .beginner],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 15. MORNING ARCHITECT (Foundation)
        MiniChallenge(
            title: "Morning Architect",
            tagline: "Design your morning ritual",
            description: "A 7-day experiment in building a morning routine that actually works for your brain, body, and schedule—not someone else's perfect Instagram morning.",
            tag: "MorningArchitect",
            colorHex: "F5DEB3",
            icon: "sunrise.fill",
            identityStatement: "Become someone who starts the day with intention, not reaction",
            habits: [
                Project50Habit(
                    name: "First 15 Minutes Rule",
                    description: """
                    No phone for the first 15 minutes of your day.

                    • Core: Leave phone charging in another room or face-down until after your morning anchor.
                    • Anchor: From the moment you wake up until you complete your first ritual.
                    • If-then: When I wake up, I will not touch my phone for 15 minutes.
                    
                                                                                •
                    💡 [Stack Tip]:  Wake → Bathroom → Water → Coffee → Morning ritual (Habit 2) → THEN check phone. This creates 15-20 min of intentional morning before reactive mode kicks in.
                    
                    • Why It Works: Starting with your own agenda (not others') sets a proactive tone for the day.
                    • Rescue: Even 5 phone-free minutes is a meaningful boundary.
                    """,
                    icon: "iphone.slash",
                    colorHex: "F7E4BE",
                    category: "Morning Architect",
                    program: "miniChallenge",
                    level: nil,
                    tag: "MorningArchitect",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Morning Anchor Ritual",
                    description: """
                    Choose 1-3 non-negotiable morning actions.

                    • Core: Pick simple, doable actions (e.g., drink water, 2-min stretch, write 1 sentence).
                    • Anchor: Immediately after waking or after bathroom.
                    • If-then: After I wake up, I will do [my chosen anchor actions] in the same order.

                                                                                •
                    💡 [Stack Tip]: Wake → Bathroom → Water → Morning light (2 min outside) → 2-min stretch → Write 1 gratitude → Coffee/breakfast. This 10-minute sequence happens automatically because each action leads to the next. After 7 days, your body will crave this flow.

                    • Why It Works: Consistency builds automaticity; small rituals create a sense of control.
                    • Rescue: Even 1 action (like drinking a glass of water) is enough to start.
                    """,
                    icon: "list.bullet.circle.fill",
                    colorHex: "F9EAC9",
                    category: "Morning Architect",
                    program: "miniChallenge",
                    level: nil,
                    tag: "MorningArchitect",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Evening Prep",
                    description: """
                    Set up tomorrow's morning the night before.

                    • Core: Lay out clothes, prep breakfast, charge devices away from bed.
                    • Anchor: Right before your evening wind-down routine.
                    • If-then: Before I start my evening routine, I will prep 1-2 things for tomorrow morning.
                    
                                                                                •
                    💡 [Stack Tip]: Finish dinner → Clean dishes (5 min) → Lay out tomorrow's clothes on chair → Prep breakfast items on counter (coffee, oats, bowl, whatever you need) → Charge phone in another room (not bedroom!) → Place water bottle by bed → Then begin evening wind-down ritual. This 10-minute "future self" prep happens automatically after dinner, when energy is still good. Morning You wakes up to a gift from Evening You—everything ready to go, no decisions required. This single practice eliminates 90% of morning friction.
                    
                    • Why It Works: Reducing morning decisions supports a smoother start to your day.
                    • Rescue: Just laying out your clothes counts as a full win.
                    """,
                    icon: "moon.zzz.fill",
                    colorHex: "FBF0D4",
                    category: "Morning Architect",
                    program: "miniChallenge",
                    level: nil,
                    tag: "MorningArchitect",
                    durationDays: 7
                )
            ],
            tier: .foundation,
            tags: [.focus, .digital, .sleep, .beginner],
            durationWeeks: 1,
            programGroup: nil
        ),

        // MARK: - NOURISH RESET (Foundation)
        MiniChallenge(
            title: "Nourish Reset",
            tagline: "Fuel with intention",
            description: "A 7-day introduction to mindful eating and nutrition fundamentals. Before optimizing macros or following complex diets, master the basics: protein, vegetables, and presence at meals.",
            tag: "NourishReset",
            colorHex: "7CB342",
            icon: "leaf.circle.fill",
            identityStatement: "Become someone who eats to nourish, not just to fill",
            habits: [
                Project50Habit(
                    name: "Protein Anchor",
                    description: """
                    Include protein in your first meal of the day.

                    • Core: Add eggs, Greek yogurt, protein shake, tofu, or leftovers with protein to breakfast or your first meal.
                    • Anchor: First meal of the day, whatever time that is.
                    • If-then: When I prepare my first meal, I will include at least one protein source.
                    • Why It Works: Protein at breakfast supports stable blood sugar and sustained energy. It also reduces cravings later in the day by keeping you satisfied longer.
                    • Rescue: Even a handful of nuts or a glass of milk counts. Something is better than nothing.
                    """,
                    icon: "fork.knife.circle.fill",
                    colorHex: "8BC34A",
                    category: "Nourish Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NourishReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Veggie Volume",
                    description: """
                    Add one extra serving of vegetables to any meal today.

                    • Core: Whatever you're already eating, add vegetables. Side salad, steamed broccoli, spinach in your smoothie, extra veggies on pizza.
                    • Anchor: Lunch or dinner—whichever meal you have most control over.
                    • If-then: When I prepare or order a meal, I will add one extra serving of vegetables.
                    • Why It Works: Adding is easier than subtracting. Instead of restricting, you're crowding out less nutritious foods with more vegetables. Fiber also supports digestion and satiety.
                    • Rescue: Even a few baby carrots or a handful of cherry tomatoes counts as a serving.
                    """,
                    icon: "carrot.fill",
                    colorHex: "9CCC65",
                    category: "Nourish Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NourishReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Mindful First Bite",
                    description: """
                    Pause before eating. Take 3 slow, conscious bites before continuing.

                    • Core: Before eating, take one breath. Look at your food. Then take 3 slow bites, chewing fully and tasting before swallowing.
                    • Anchor: Beginning of each meal, especially your largest meal.
                    • If-then: Before I start eating, I will pause, breathe, and take 3 mindful bites.
                    • Why It Works: Slowing down activates your parasympathetic nervous system (rest-and-digest mode), improves digestion, and helps you notice fullness cues. Most people eat on autopilot—this breaks the pattern.
                    • Rescue: Even one conscious bite before continuing is a win. The pause matters more than perfection.
                    """,
                    icon: "mouth.fill",
                    colorHex: "AED581",
                    category: "Nourish Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "NourishReset",
                    durationDays: 7
                )
            ],
            tier: .foundation,
            tags: [.nutrition, .physical, .beginner, .selfCompassion],
            durationWeeks: 1,
            programGroup: nil
        ),

        // MARK: - 16. EVENING SANCTUARY (Core)
        MiniChallenge(
            title: "Evening Sanctuary",
            tagline: "Wind down with intention",
            description: "A 7-day practice in creating an evening ritual that helps you transition from day to night—protecting your rest, processing your day, and releasing what doesn't serve you.",
            tag: "EveningSanctuary",
            colorHex: "6B4E71",
            icon: "moon.circle.fill",
            identityStatement: "Become someone who ends the day with closure, not collapse",
            habits: [
                Project50Habit(
                    name: "Digital Sunset",
                    description: """
                    Turn off devices 60-90 minutes before bed.

                    • Core: Set a nightly alarm for "digital sunset"—all screens off or in another room.
                    • Anchor: 60-90 minutes before target bedtime.
                    • If-then: When my digital sunset alarm goes off, I will put devices away and switch to analog activities.
                    
                                                                                •
                    💡 [Stack Tip]: Digital sunset alarm (9 PM) → Enable grayscale + Night Shift (Digital Detox) → Put all devices on charging station in another room → Begin Day Release Ritual (Habit 2: journal 5 min) → Wind-down activities (tea, reading, stretching) → Sleep Sanctuary Prep (Habit 3) → Bed by 10:30 PM. This 90-minute sequence creates a complete evening system: digital boundaries → emotional processing → environment preparation → sleep.
                    
                    • Why It Works: Reducing evening screen time supports better sleep preparation.
                    • Rescue: Even 30 minutes screen-free before bed can help.
                    """,
                    icon: "sunset.fill",
                    colorHex: "7D5E83",
                    category: "Evening Sanctuary",
                    program: "miniChallenge",
                    level: nil,
                    tag: "EveningSanctuary",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Day Release Ritual",
                    description: """
                    Spend 5 minutes journaling or reflecting on your day.

                    • Core: Write down wins, worries, or whatever's on your mind. Then close the notebook.
                    • Anchor: Right after dinner or before starting your wind-down routine.
                    • If-then: After dinner, I will spend 5 minutes writing down my day and then closing the page.
                    
                                                                                •
                    💡 [Stack Tip]: Dinner ends → Clear dishes → Sit in a comfortable spot → Day Release journal (5 min: wins, worries, thoughts) → Close notebook physically → Say "I release this day" → Begin offline evening activity (Digital Detox: reading, crafting, conversation). This ritual creates psychological closure—everything on your mind goes onto paper, freeing you to be present for the evening. The physical act of closing the notebook signals "day complete."
                    
                    • Why It Works: Processing the day prevents rumination and creates psychological closure.
                    • Rescue: Writing 3 bullet points is enough to externalize thoughts.
                    """,
                    icon: "book.closed.fill",
                    colorHex: "8E6E95",
                    category: "Evening Sanctuary",
                    program: "miniChallenge",
                    level: nil,
                    tag: "EveningSanctuary",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Sleep Sanctuary Prep",
                    description: """
                    Optimize your bedroom environment for rest.

                    • Core: Dim lights, cool temperature (18-21°C), remove clutter, prep bed.
                    • Anchor: 30 minutes before you want to be asleep.
                    • If-then: 30 minutes before bed, I will dim lights, cool the room, and prep my sleep space.
                    
                                                                                •
                    💡 [Stack Tip]: 30 min before target sleep → Dim all lights to warm glow → Adjust thermostat to 18-21°C → Clear nightstand clutter → Prep bed (fluff pillows, arrange blankets) → Brush teeth + cold water splash (Nervous System Reset) → Final body scan (release tension) → Get into prepared bed → 5-5-5 breathing (Breath & Calm) → Sleep. This 30-minute sequence transforms your bedroom into a true sanctuary while cueing your body for rest at every step.
                    
                    • Why It Works: Environmental cues trigger sleep readiness; a sanctuary space invites rest.
                    • Rescue: Just dimming the lights is a powerful sleep signal.
                    """,
                    icon: "bed.double.fill",
                    colorHex: "9F7EA7",
                    category: "Evening Sanctuary",
                    program: "miniChallenge",
                    level: nil,
                    tag: "EveningSanctuary",
                    durationDays: 7
                )
            ],
            tier: .core,
            tags: [.sleep, .stress, .digital, .selfCompassion],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 17. BOUNDARY BOOTCAMP (Specialized)
        MiniChallenge(
            title: "Boundary Bootcamp",
            tagline: "Protect your energy",
            description: "A 7-day intensive in saying no, setting limits, and protecting your time and energy—without guilt. Essential for people-pleasers, over-givers, and anyone who feels drained by others' demands.",
            tag: "BoundaryBootcamp",
            colorHex: "8B4513",
            icon: "shield.fill",
            identityStatement: "Become someone who honors their limits without apology",
            habits: [
                Project50Habit(
                    name: "The Pause Practice",
                    description: """
                    Use the script: "Let me check my calendar and get back to you."

                    • Core: When asked for time/energy, pause instead of auto-agreeing.
                    • Anchor: Whenever someone makes a request or invitation.
                    • If-then: When someone asks for my time, I will say "Let me check and I'll let you know."
                    • Why It Works: Pausing breaks the people-pleasing reflex and gives you space to decide consciously.
                    • Rescue: Even a simple "I need to think about it" is a complete boundary.
                    """,
                    icon: "pause.circle.fill",
                    colorHex: "9B5A23",
                    category: "Boundary Bootcamp",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BoundaryBootcamp",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "One Daily No",
                    description: """
                    Decline one request, invitation, or obligation each day.

                    • Core: Practice saying no to something—big or small.
                    • Anchor: Look for opportunities throughout the day.
                    • If-then: When I notice a request that doesn't align with my energy/values, I will practice saying no.
                    • Why It Works: Saying no is a skill; practice builds confidence.
                    • Rescue: Declining to answer a non-urgent message counts as a no.
                    """,
                    icon: "hand.raised.fill",
                    colorHex: "A66F33",
                    category: "Boundary Bootcamp",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BoundaryBootcamp",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Energy Audit",
                    description: """
                    Track what drains vs. fills your energy throughout the day.

                    • Core: Note activities/people that energize (+) or deplete (-) you.
                    • Anchor: Evening reflection time.
                    • If-then: At the end of the day, I will list 2-3 things that drained me and 2-3 that filled me.
                    • Why It Works: Awareness of energy patterns reveals where boundaries are needed most.
                    • Rescue: Just noticing "I felt drained after X" is valuable data.
                    """,
                    icon: "battery.100",
                    colorHex: "B18443",
                    category: "Boundary Bootcamp",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BoundaryBootcamp",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.boundaries, .emotional, .social, .selfCompassion],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 18. LEARNING SPRINT (Challenging)
        MiniChallenge(
            title: "Learning Sprint",
            tagline: "Master a micro-skill",
            description: "A 7-day deliberate practice experiment—pick one tiny skill and practice it daily with focus. Not passive learning, but active skill-building through repetition and feedback.",
            tag: "LearningSprint",
            colorHex: "4682B4",
            icon: "brain.head.profile",
            identityStatement: "Become someone who learns through doing, not just consuming",
            habits: [
                Project50Habit(
                    name: "15-Min Focused Practice",
                    description: """
                    Practice your chosen micro-skill with full attention for 15 minutes.

                    • Core: Pick ONE tiny skill (e.g., draw circles, practice a chord, write a headline).
                    • Anchor: Same time daily—morning or evening.
                    • If-then: At [chosen time], I will practice [micro-skill] for 15 focused minutes.
                    • Why It Works: Deliberate practice (focused, repeated, corrected) builds skill faster than passive study.
                    • Rescue: Even 5 minutes of focused practice beats zero.
                    """,
                    icon: "clock.fill",
                    colorHex: "5A92C4",
                    category: "Learning Sprint",
                    program: "miniChallenge",
                    level: nil,
                    tag: "LearningSprint",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Immediate Feedback Loop",
                    description: """
                    Record, review, or get feedback on your practice.

                    • Core: Film yourself, listen back, show someone, or self-critique.
                    • Anchor: Right after your practice session.
                    • If-then: After I practice, I will review my work and note 1 thing to improve.
                    • Why It Works: Feedback accelerates learning by identifying errors and refining technique.
                    • Rescue: Just asking yourself "What could I do better?" is a feedback loop.
                    """,
                    icon: "arrow.triangle.2.circlepath",
                    colorHex: "6FA2D4",
                    category: "Learning Sprint",
                    program: "miniChallenge",
                    level: nil,
                    tag: "LearningSprint",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Micro-Progress Log",
                    description: """
                    Track one small improvement or insight each day.

                    • Core: Write down: "Today I improved at ___" or "Today I learned ___."
                    • Anchor: End of practice session or evening reflection.
                    • If-then: After practice, I will log one micro-improvement I noticed.
                    • Why It Works: Tracking progress builds motivation and helps you see growth that feels invisible.
                    • Rescue: "I showed up" is a valid progress entry.
                    """,
                    icon: "chart.line.uptrend.xyaxis",
                    colorHex: "84B2E4",
                    category: "Learning Sprint",
                    program: "miniChallenge",
                    level: nil,
                    tag: "LearningSprint",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.focus, .mental, .creativity],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 19. BODY TRUST RESET (Specialized)
        MiniChallenge(
            title: "Body Trust Reset",
            tagline: "Reconnect with your body's wisdom",
            description: "A 7-day gentle reset for those healing from diet culture, body image struggles, or disconnection from physical sensations. Focus on intuitive movement, hunger/fullness cues, and self-compassion.",
            tag: "BodyTrustReset",
            colorHex: "DDA0DD",
            icon: "heart.circle",
            identityStatement: "Become someone who trusts their body's signals and treats it with kindness",
            habits: [
                Project50Habit(
                    name: "Hunger-Fullness Check",
                    description: """
                    Tune into body signals before, during, and after eating.

                    • Core: Pause to ask: "How hungry am I? (1-10)" and "How full am I? (1-10)"
                    • Anchor: Before meals, midway through, and after finishing.
                    • If-then: Before I eat, I will pause and rate my hunger. Midway, I'll check in. After, I'll notice fullness.
                    • Why It Works: Reconnecting with internal cues (vs. external rules) rebuilds body trust.
                    • Rescue: Just noticing "I feel hungry" or "I feel satisfied" is enough.
                    """,
                    icon: "heart.text.square.fill",
                    colorHex: "E5B0E5",
                    category: "Body Trust Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BodyTrustReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Joyful Movement",
                    description: """
                    Move in ways that feel good, not punishing.

                    • Core: Choose movement that feels playful, energizing, or soothing—not compensatory.
                    • Anchor: Any time of day when you feel drawn to move.
                    • If-then: When I want to move, I will choose something that feels good in my body right now.
                    • Why It Works: Shifting from "exercise as punishment" to "movement as care" heals body relationship.
                    • Rescue: Gentle stretching or a slow walk counts as joyful movement.
                    """,
                    icon: "figure.walk",
                    colorHex: "EBC0EB",
                    category: "Body Trust Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BodyTrustReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Body Gratitude",
                    description: """
                    Thank one body part daily for what it does (not how it looks).

                    • Core: Focus on function, not appearance. "Thank you, legs, for carrying me."
                    • Anchor: Morning mirror time or evening reflection.
                    • If-then: Each day, I will thank one body part for its function.
                    • Why It Works: Gratitude shifts focus from criticism to appreciation, rebuilding positive body relationship.
                    • Rescue: Even "Thank you, heart, for beating" is a complete practice.
                    """,
                    icon: "heart.fill",
                    colorHex: "F1D0F1",
                    category: "Body Trust Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "BodyTrustReset",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.body, .selfCompassion, .emotional, .movement],
            durationWeeks: 1,
            programGroup: nil
        ),
        
        // MARK: - 20. HAIR & GLOW RESET · 7-Day Repair 养发养颜七日

        MiniChallenge(
            title: "Hair & Glow Reset · 7-Day Repair",
            tagline: "Sleep softer, nourish deeper",
            description: """
            A 7-day realistic self-care journey for 乱作息 (irregular sleep) + concerns about hair vitality + 脸色偏蜡黄 (dull complexion).

            Instead of chasing perfection, we focus on:
            • Slightly earlier, more stable sleep
            • One “real” nourishing meal per day
            • Gentle calm + scalp care ritual

            这是一个偏中医养生 + 生活方式的小挑战，不是医疗治疗方案或专业诊断。
            If you ever feel very worried about sudden or severe changes, a healthcare professional can help.
            """,
            tag: "HairGlowReset",
            colorHex: "C7A78A",  // warm, gentle beige-brown
            icon: "sparkles",
            identityStatement: "Become someone who gently修复作息、养护内在活力，让气色和头发一点点稳下来",
            habits: [
                Project50Habit(
                    name: "Sleep Rhythm Reset · 作息节律微调",
                    description: """
                    A 7-day micro-adjustment for your sleep window — 从 1:00 慢慢往 11:30 靠近。

                    • Core:
                      Choose a “good enough” sleep window and微调 15–30 分钟，而不是一夜之间完美早睡。
                      前 2–3 天先守住 12:45，之后再尝试 12:30、12:15，最后慢慢靠近 11:30–12:00。

                    • Anchor:
                      Set a “soft landing” alarm 30 分钟前（比如 12:00 / 12:15）。
                      闹钟一响 = 停止刷手机 / 不再开始新任务 → 进入洗漱、护肤、收拾床的流程。

                    • If-then:
                      If 我的软着陆闹钟响了，
                      then 我会放下手机，去洗漱、护肤，为睡觉做准备。

                    • 7-Day Flow:
                      Day 1–2: 目标不晚于 12:45 上床关灯。
                      Day 3–4: 稳定在 12:30 左右。
                      Day 5–7: 视状态慢慢向 12:00–12:15 靠近，不强迫。

                    • Why It Works:
                      稳定的入睡节律可以帮助激素和压力系统慢慢「校时」，
                      为头发和皮肤的修复创造更可预测的恢复窗口。

                    • Rescue:
                      如果今天实在很晚，依然可以：
                      1) 开启 10 分钟“紧急关机”流程（洗脸 + 护肤 + 上床），
                      2) 记录一下时间，明天再拉回来。
                    """,
                    icon: "moon.stars.fill",
                    colorHex: "B89C7D",
                    category: "Hair & Glow Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "HairGlowReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Glow Fuel · 养颜活力一餐",
                    description: """
                    每天至少有一餐，真正给「头发工厂」和「气色」送一点砖头和能量。

                    • Core:
                      每天选一餐，刻意做到：
                      1) 有一份优质蛋白（肉 / 蛋 / 鱼 / 豆制品）
                      2) 有一份深色蔬菜或颜色较深的食材
                      可以在这餐里点缀一点黑芝麻 / 核桃 / 枸杞，当作小小养生加分项。

                    • Anchor:
                      优先锁定更容易调整的一餐：比如早餐或晚餐。
                      例：早上固定「碳水 + 蛋白 + 一点坚果」，或晚上加一盘深绿色蔬菜。

                    • If-then:
                      If 我在点/做今天这餐的时候，
                      then 我会确认：有蛋白 + 有一个深色蔬菜/食材出现在盘子里。

                    • 7-Day Flow:
                      Day 1–2: 只要求「有蛋白 + 有蔬菜」，不追求完美。
                      Day 3–5: 尝试固定一顿“代表餐”，让身体记住这个节奏。
                      Day 6–7: 轻轻减少一点“气血偷走者”（比如用一顿正餐替代奶茶当晚饭）。

                    • Why It Works:
                      头发本质上是蛋白 + 微量元素的「奢侈品」。
                      当身体被迫省电时，头发和光泽通常是最先被牺牲的那一批。

                    • Rescue:
                      如果今天全是外卖：
                      点一份多蔬菜的配菜 / 加一杯牛奶 / 豆浆 / 简单坚果，
                      也算对自己多给了一点点支持。
                    """,
                    icon: "fork.knife.circle.fill",
                    colorHex: "D8BFA0",
                    category: "Hair & Glow Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "HairGlowReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Calm & Scalp Ritual · 头皮与情绪放松",
                    description: """
                    用 3–5 分钟，把「压力 + 头皮」同时安顿一下的夜间小仪式。

                    • Core:
                      洗澡或洗头后，用指腹轻轻按摩头皮 + 简单放松肩颈。
                      可以配合一点深呼吸，顺便观察一下今天的头皮状态和情绪状态。

                    • Anchor:
                      放在「晚上洗完澡 / 洗完头 → 护肤之后，躺床之前」这个空档。

                    • If-then:
                      If 我洗完澡 / 洗完头，
                      then 我会花 2–3 分钟用指腹给头皮做一个温柔的小按摩。

                    • 7-Day Flow:
                      Day 1–2: 以「两分钟头皮摸一摸」为主，习惯这个仪式感。
                      Day 3–5: 加入一点肩颈按压 + 5 次深呼吸。
                      Day 6–7: 在按摩后看一眼镜子，轻轻观察：发缝、额角、脸色有没有一点变化。

                    • Why It Works:
                      对头皮的温和机械刺激 + 减压，有助于局部血流和神经系统舒缓，
                      是支持性护理，而不是“立刻长出新头发的魔法”。

                    • Rescue:
                      非常累的时候，只需要做：
                      1 次深呼吸 + 用手掌轻轻按住头顶部 10 秒，
                      告诉自己：「今天也算有照顾到你一点点」。
                    """,
                    icon: "hands.sparkles.fill",
                    colorHex: "CFAF92",
                    category: "Hair & Glow Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "HairGlowReset",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.sleep, .nutrition, .physical, .tcm, .selfCompassion],
            durationWeeks: 1,
            programGroup: nil
        ),

        // MARK: - SOCIAL CONFIDENCE (Specialized)
        MiniChallenge(
            title: "Social Confidence",
            tagline: "Connect with courage",
            description: "A 7-day challenge for anyone who wants to feel more comfortable in social situations. Whether you're introverted, socially anxious, or just out of practice—this is about building connection skills through small, manageable steps.",
            tag: "SocialConfidence",
            colorHex: "5C6BC0",
            icon: "person.wave.2.fill",
            identityStatement: "Become someone who initiates connection rather than waiting for it",
            habits: [
                Project50Habit(
                    name: "One Micro-Interaction",
                    description: """
                    Initiate one small social exchange daily.

                    • Core: Say hello to a neighbor, compliment a stranger, ask a coworker a question, chat with the barista. Keep it brief—under 30 seconds.
                    • Anchor: During a routine outing (coffee shop, grocery store, office).
                    • If-then: When I'm out in the world today, I will initiate one small interaction with another person.
                    • Why It Works: Social confidence is built through repetition, not revelation. Each micro-interaction proves that connection isn't dangerous. The anxiety diminishes with exposure.
                    • Rescue: A smile and "good morning" counts. Eye contact and a nod counts. Any acknowledgment of another human counts.
                    """,
                    icon: "bubble.left.fill",
                    colorHex: "7986CB",
                    category: "Social Confidence",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SocialConfidence",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Curiosity Over Performance",
                    description: """
                    Ask one genuine question instead of worrying about what to say.

                    • Core: In any conversation, shift focus from "What should I say?" to "What am I curious about?" Ask one real question and listen to the answer.
                    • Anchor: Any conversation—with friends, colleagues, or strangers.
                    • If-then: When I'm in a conversation and feel awkward, I will ask a genuine question about the other person.
                    • Why It Works: Social anxiety often comes from self-focus ("Am I being weird?"). Curiosity redirects attention outward, making conversations easier and more enjoyable. People also love talking about themselves.
                    • Rescue: "What's that like for you?" works in almost any context.
                    """,
                    icon: "questionmark.circle.fill",
                    colorHex: "9FA8DA",
                    category: "Social Confidence",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SocialConfidence",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Post-Social Reframe",
                    description: """
                    After social situations, note what went well instead of ruminating on awkwardness.

                    • Core: After any social interaction, ask: "What went okay or well?" Write or speak one positive observation before your brain spirals into criticism.
                    • Anchor: Right after leaving a social situation (party, meeting, conversation).
                    • If-then: After a social interaction, I will identify one thing that went well before analyzing what went wrong.
                    • Why It Works: The brain naturally replays "cringe moments" on loop. Deliberate positive reframing breaks this pattern and builds a more accurate (and kind) memory of social experiences.
                    • Rescue: "I showed up" is a valid positive. "I survived" counts too.
                    """,
                    icon: "arrow.uturn.up.circle.fill",
                    colorHex: "C5CAE9",
                    category: "Social Confidence",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SocialConfidence",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.social, .connection, .emotional, .selfCompassion],
            durationWeeks: 1,
            programGroup: nil
        ),

        // MARK: - INNER CRITIC RESET (Specialized)
        MiniChallenge(
            title: "Inner Critic Reset",
            tagline: "From harsh to kind",
            description: "A 7-day practice in transforming your relationship with self-criticism. This isn't about silencing the inner critic—it's about recognizing it, responding with compassion, and building a kinder inner voice.",
            tag: "InnerCriticReset",
            colorHex: "8E44AD",
            icon: "heart.text.square.fill",
            identityStatement: "Become someone who speaks to themselves like a trusted friend",
            habits: [
                Project50Habit(
                    name: "Catch the Critic",
                    description: """
                    Notice and name one self-critical thought daily.

                    • Core: When you notice harsh self-talk, pause and label it: "There's my inner critic" or "That's a criticism, not a fact."
                    • Anchor: Whenever you notice negative self-talk—often during mistakes, stress, or comparison.
                    • If-then: When I notice harsh self-talk, I will pause and say "That's my inner critic speaking."
                    • Why It Works: Naming the critic creates distance between you and the thought. You're not the criticism—you're the one noticing it. This is the first step to responding differently.
                    • Rescue: Even noticing harsh self-talk once per day is progress. Awareness is the goal.
                    """,
                    icon: "eye.circle.fill",
                    colorHex: "9B59B6",
                    category: "Inner Critic Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "InnerCriticReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Compassionate Reframe",
                    description: """
                    Rewrite one harsh thought as if speaking to a friend.

                    • Core: Take a self-critical thought and ask: "What would I say to a friend in this situation?" Then say that to yourself.
                    • Example: "I'm so stupid" → "That was a mistake, but you're learning. Everyone messes up sometimes."
                    • Anchor: After catching the critic (Habit 1) or during evening reflection.
                    • If-then: After I notice harsh self-talk, I will ask "What would I say to a friend?" and offer myself the same kindness.
                    • Why It Works: We're often far kinder to others than to ourselves. This exercise uses existing compassion skills and redirects them inward.
                    • Rescue: Even saying "That was harsh—let me try again" counts as a reframe.
                    """,
                    icon: "arrow.2.squarepath",
                    colorHex: "A569BD",
                    category: "Inner Critic Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "InnerCriticReset",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Evidence Against",
                    description: """
                    Find one piece of evidence that contradicts a negative belief about yourself.

                    • Core: When the critic says "You always..." or "You never..." or "You're not good enough," find ONE counterexample.
                    • Example: "You're terrible at your job" → "But I got positive feedback on that project last month."
                    • Anchor: Evening reflection or when you notice a strong self-critical belief.
                    • If-then: When I notice a sweeping negative belief, I will find one piece of evidence that contradicts it.
                    • Why It Works: The inner critic speaks in absolutes. Reality is more nuanced. Finding counterevidence builds a more accurate self-image and weakens the critic's authority.
                    • Rescue: Even a tiny counterexample counts. "I'm completely unlovable" → "But my cat likes me."
                    """,
                    icon: "shield.checkered",
                    colorHex: "AF7AC5",
                    category: "Inner Critic Reset",
                    program: "miniChallenge",
                    level: nil,
                    tag: "InnerCriticReset",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.selfCompassion, .emotional, .mental],
            durationWeeks: 1,
            programGroup: nil
        ),

        // MARK: - VALUES COMPASS (Specialized)
        MiniChallenge(
            title: "Values Compass",
            tagline: "Discover what matters",
            description: "A 7-day exploration to clarify your core values and start living by them. Many of us operate on autopilot, driven by inherited expectations or external pressures. This challenge helps you discover what actually matters to YOU.",
            tag: "ValuesCompass",
            colorHex: "16A085",
            icon: "safari.fill",
            identityStatement: "Become someone who lives by chosen values, not inherited defaults",
            habits: [
                Project50Habit(
                    name: "Peak Moment Reflection",
                    description: """
                    Recall one moment you felt truly alive; identify the value present.

                    • Core: Think of a time you felt fulfilled, proud, or deeply engaged. Ask: "What value was I honoring in that moment?" (e.g., creativity, connection, growth, adventure, service)
                    • Anchor: Morning journaling or evening reflection.
                    • If-then: Each day, I will recall one meaningful moment and name the value it represents.
                    • Why It Works: Your peak experiences reveal your values better than abstract lists. When you felt most alive, you were likely living a core value.
                    • Rescue: Even a small moment counts—a satisfying conversation, a completed task, a moment of beauty.
                    """,
                    icon: "sparkles",
                    colorHex: "1ABC9C",
                    category: "Values Compass",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ValuesCompass",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Values Experiment",
                    description: """
                    Choose one value to intentionally embody today; notice how it feels.

                    • Core: Pick one value (connection, creativity, courage, kindness, growth, etc.). Look for one opportunity to live it today. Notice how it feels.
                    • Anchor: Morning intention-setting.
                    • If-then: Each morning, I will choose one value to embody and find one way to express it today.
                    • Why It Works: Values become real through action. Testing a value in daily life reveals whether it's truly yours or just something you think you "should" value.
                    • Rescue: Even a small expression counts—choosing kindness in a text message, curiosity in a conversation, courage in a small decision.
                    """,
                    icon: "flask.fill",
                    colorHex: "48C9B0",
                    category: "Values Compass",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ValuesCompass",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Alignment Audit",
                    description: """
                    Identify one commitment or habit that doesn't serve your values.

                    • Core: Review your current commitments, relationships, or habits. Find one that doesn't align with your values. Consider what to do about it.
                    • Anchor: End of week reflection (Day 5-7) after you've identified some values.
                    • If-then: By the end of the week, I will identify one misaligned commitment and decide whether to reduce, change, or drop it.
                    • Why It Works: Living by values requires both addition (doing more of what matters) and subtraction (doing less of what doesn't). Clarity creates space.
                    • Rescue: You don't have to act on it immediately. Just naming the misalignment is the first step.
                    """,
                    icon: "checklist",
                    colorHex: "76D7C4",
                    category: "Values Compass",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ValuesCompass",
                    durationDays: 7
                )
            ],
            tier: .specialized,
            tags: [.spiritual, .emotional, .selfCompassion, .boundaries],
            durationWeeks: 1,
            programGroup: nil
        ),

        // MARK: - 费教练力量训练 · 4-WEEK MINI CHALLENGE
        // Based on Linear Periodization Model for Novice Lifters
        // Progressive strength training with neurodivergent-friendly design principles
        //
        // SCIENTIFIC FRAMEWORK - LINEAR PERIODIZATION:
        // This program follows evidence-based linear periodization principles
        // specifically designed for novice/intermediate lifters. Each week has a distinct training focus:
        //
        // Week 1: ANATOMICAL ADAPTATION (AA)
        //    - Focus: Movement learning, tissue conditioning, neural patterning
        //    - Volume: Low-Moderate | Intensity: Low (RPE 4-6) | Frequency: 3x/week
        //    - Goal: Prepare connective tissue, establish motor patterns
        //    - Evidence: Tendons adapt more gradually than muscle
        //
        // Week 2: HYPERTROPHY FOUNDATION (HF)
        //    - Focus: Muscle growth through mechanical tension and volume
        //    - Volume: Moderate-High (+15-20%) | Intensity: Moderate (RPE 6-7) | Frequency: 4x/week
        //    - Goal: Increase muscle cross-sectional area, improve work capacity
        //    - Evidence: 2x/week per muscle group is often recommended for muscle growth
        //
        // Week 3: INTENSIFICATION (IN)
        //    - Focus: Neural adaptation through higher loads
        //    - Volume: Moderate (maintained) | Intensity: High (RPE 7-8) | Frequency: 4x/week
        //    - Goal: Maximize motor unit recruitment, increase force production
        //    - Evidence: High intensity supports neural adaptations
        //
        // Week 4: DELOAD & SUPERCOMPENSATION (DL)
        //    - Focus: Strategic recovery and adaptation integration
        //    - Volume: Low (-40-50%) | Intensity: Low-Moderate (RPE 5-6) | Frequency: 3x/week
        //    - Goal: Allow supercompensation, support recovery
        //    - Evidence: Deload weeks support subsequent performance
        //
        // KEY SCIENTIFIC PRINCIPLES APPLIED:
        // 1. Progressive Overload: 10-20% weekly volume increase (Weeks 1→2→3)
        // 2. Undulating Periodization: Alternate volume/intensity emphasis by week
        // 3. Frequency: 2x/week per muscle group commonly recommended for adaptation
        // 4. Recovery: 48-72hr between same muscle groups (Damas et al., 2016)
        // 5. Deload: 40-50% volume reduction every 4th week (Fitness-Fatigue Model)
        // 6. Exercise Selection: Multi-joint movements prioritized for efficiency
        // 7. Time Under Tension: 3-4 second eccentric for muscle development
        // 8. RPE Scale: Rate of Perceived Exertion (1-10) for auto-regulation
        //
        // ADAPTATIONS FOR BEGINNERS:
        // - Cardio-minimal approach: No conditioning work in Weeks 1-2
        // - Flexible class selection: Users can substitute similar 费教练 classes
        // - Neurodivergent-friendly: Multiple rescue protocols, clear if-then statements for varied attention styles
        // - Sleep/nutrition included: Recognition that recovery drives adaptation
        // - Fatigue monitoring: Teaches self-regulation to avoid excessive training
        //
        // WEEKLY STRUCTURE OVERVIEW:
        // Week 1: 3× full-body sessions (AA phase) + 2× active recovery + sleep optimization
        // Week 2: 4× upper/lower split (HF phase) + 2× core work + nutrition timing
        // Week 3: 4× upper/lower split (IN phase) + 3× sculpting + fatigue monitoring
        // Week 4: 3× reduced volume (DL phase) + daily recovery + progress assessment
        //
        // EXPECTED OUTCOMES (4 weeks):
        // - Strength improvements possible with consistent practice
        // - Motor learning: Improvement in movement quality
        // - Body composition changes vary by individual
        // - Fatigue management: Improved recovery capacity
        // - Habit formation: Established 3-4x/week training routine
        //
        // SCIENTIFIC REFERENCES:
        // - ACSM (2009). Progression models in resistance training for healthy adults
        // - Schoenfeld et al. (2019). Resistance training frequency and skeletal muscle hypertrophy
        // - Rhea et al. (2003). A comparison of linear and daily undulating periodized programs
        // - Zatsiorsky & Kraemer (2006). Science and Practice of Strength Training
        // - Damas et al. (2016). Resistance training-induced changes in integrated myofibrillar protein synthesis
        // - Bohm et al. (2015). Human tendon adaptation in response to mechanical loading
        // - Bellenger et al. (2016). Monitoring athletic training status through autonomic heart rate regulation

        // MARK: - WEEK 1 · ANATOMICAL ADAPTATION 解剖适应期
                MiniChallenge(
                    title: "费教练力量 · Week 1",
                    tagline: "三练适应 · 神经募集",
                    description: """
                    Week 1 focuses on anatomical adaptation and neural recruitment.
                    Three full-body sessions teach movement patterns and prepare connective tissue for progressive loading. This is the foundation phase.
                    """,
                    tag: "FeiStrengthW1",
                    colorHex: "F8B79B",
                    icon: "figure.strengthtraining.traditional",
                    identityStatement: "Become someone who builds strength through intelligent progression, not random effort",
                    habits: [
                        Project50Habit(
                            name: "费教练 基础三练 · 3x/Week · 全身适应",
                            description: """
                            Establish movement competency with three foundational full-body sessions.
                            
                            • Core: 每周完成 3 节基础动作学习课程：
                            • Day1【必练】13min 活力唤醒 + 16min 背部普拉提 (上肢推拉)
                            • Day2【必练】13min 关节灵活 (活动度建立)
                            • Day3【必练】13min 节奏掌控 (下肢基础)
                            • Anatomical Adaptation: Week1 目标是组织适应，不是力竭：
                            – 使用极轻重量或徒手（RPE 4-6/10）
                            – 专注动作路径和关节活动范围
                            – 每个动作 2-3 组 × 10-15 次
                            – 组间休息 60-90 秒充分恢复
                            • Anchor: Mon/Wed/Fri 或 Tue/Thu/Sat，固定时间建立习惯。
                            • If-then: If 今天是训练日, I will 在固定时间按播放，把注意力 100% 放在"学习动作"而非"练到力竭"。
                            • Why It Works: 肌腱和韧带适应速度比肌肉慢 6-8 周。Week1 轻负荷高质量训练可以预防伤病，为后续负荷打基础（ACSM Guidelines, 2018）。神经系统需要 3-5 次练习才能建立稳定的动作模式。
                            • Rescue: 任何一节课做到 50% 就停止，第二天继续，比硬撑受伤更明智。
                            """,
                            icon: "brain.head.profile",
                            colorHex: "F7A889",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW1",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "灵活与恢复 · 2x/Week · 主动休息",
                            description: """
                            Active recovery promotes adaptation without adding fatigue.
                            
                            • Core: 在非训练日进行 2 节恢复性活动：
                            • Day1【选修】10min 解郁操（关节润滑）
                            • Day7【必练】全身拉伸 或 久坐上肢拉伸（筋膜放松）
                            • Recovery Science: 主动恢复优于被动休息：
                            – 促进血液流动和代谢废物清除
                            – 不超过最大心率 50%（轻松对话强度）
                            – 时长 10-20 分钟即可
                            • Anchor: 安排在高强度训练后 24 小时进行。
                            • If-then: If 昨天完成了力量训练, I will 今天做 10 分钟轻柔活动促进恢复。
                            • Why It Works: 主动恢复优于被动休息，可促进血液流动和帮助恢复。对初学者，恢复质量比训练强度更重要。
                            • Rescue: 即使只是慢走 10 分钟也有效果，不必完整跟课。
                            """,
                            icon: "figure.walk",
                            colorHex: "F9B598",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW1",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "睡眠优化 · 7-9hr · 适应性恢复",
                            description: """
                            Sleep is where adaptation happens - non-negotiable for strength gains.
                            
                            • Core: 每晚保证 7-9 小时睡眠，建立固定作息：
                            – 设定固定睡眠和起床时间（包括周末）
                            – 睡前 1 小时避免蓝光（屏幕）
                            – 保持室温 18-21°C
                            • Adaptation Window: 训练后 48 小时是关键恢复期：
                            – 肌肉蛋白合成在睡眠中达峰值
                            – 生长激素分泌集中在深度睡眠阶段
                            – 神经系统重新编码动作模式
                            • Anchor: 晚上 10:00 PM 设置"准备睡觉"提醒。
                            • If-then: If 提醒响起, I will 关闭所有屏幕，开始睡前例行（洗漱、拉伸、阅读）。
                            • Why It Works: 充足的睡眠有助于身体恢复和整体健康。对于初学者，7+ 小时睡眠比额外训练更重要。
                            • Rescue: 如果睡不够 7 小时，至少保证固定作息时间，让生物钟稳定。
                            """,
                            icon: "bed.double.fill",
                            colorHex: "F4C1A4",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW1",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "Week 1 Progress Check-In",
                            description: """
                            Reflect on your first week and set adjustments for Week 2.
                            
                            • Core: Spend 10 minutes answering 5 key questions:
                            1. Energy & Recovery: How was your energy this week? (1-10)
                            2. Movement Quality: Are exercises feeling smoother?
                            3. Wins: What's one thing you're proud of?
                            4. Challenges: Where did you struggle most?
                            5. Week 2 Adjustment: What will you refine next week?
                            
                            📊 【Week 1 Milestone】: You've laid the foundation! Neural pathways are forming. Movement should feel 10-20% easier by next week.
                            
                            • Anchor: Sunday evening or Saturday morning (end of week).
                            • If-then: Every Sunday at 7 PM, I will review my week and note adjustments.
                            
                            • Why It Works: Self-monitoring supports better adherence. Early problem-solving can help prevent giving up.
                            • Rescue: Answer just questions 1, 3, and 5 (5 minutes total).
                            """,
                            icon: "chart.bar.fill",
                            colorHex: "F4C1A4",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW1",
                            durationDays: 7,
                            isOptionalForCompletion: true
                        )
                    ],
                    tier: .program,
                    tags: [.strengthTraining, .physical, .neurodivergent, .scienceBacked],
                    durationWeeks: 1,
                    programGroup: "FeiStrength"
                ),

                // MARK: - WEEK 2 · HYPERTROPHY FOUNDATION 肌肥大基础
                MiniChallenge(
                    title: "费教练力量 · Week 2",
                    tagline: "上下分化 · 容量递增",
                    description: """
                    Week 2 introduces upper/lower split for targeted muscle growth.
                    Volume increases by 15-20% through added sets and time under tension. This is where you start building muscle.
                    """,
                    tag: "FeiStrengthW2",
                    colorHex: "F5AA8E",
                    icon: "arrow.up.circle",
                    identityStatement: "Become someone who trains each muscle group 2x/week with progressive intent",
                    habits: [
                        Project50Habit(
                            name: "费教练 上下分化 · 4x/Week · 容量阶段",
                            description: """
                            Progress to upper/lower split for optimal frequency and recovery.
                            
                            • Core: 每周完成 4 节分化训练（2上2下）：
                            • Day1【必练】背部手臂（7.1 或 Day4 背部普拉提）上肢推拉
                            • Day2【必练】臀腿（7.2 或相似）下肢主导
                            • Day4【必练】肩部核心（6.30）上肢+核心
                            • Day5【必练】腿部拉伸 + 节奏掌控 下肢辅助
                            • Progressive Overload: Week2 增加训练容量：
                            – 每个动作增加 1 组（从 2-3 组→3-4 组）
                            – 或在相同组数下增加 2-3 次（12 次→14-15 次）
                            – 或放慢离心 3-4 秒增加 TUT（Time Under Tension）
                            – RPE 提升到 6-7/10（还能再做 3-4 次的感觉）
                            • Anchor: 固定 Mon上/Tue下/Thu上/Fri下 的节奏。
                            • If-then: If 今天是上肢日且上次做了 3×12, I will 今天尝试 3×14 或 4×12。
                            • Why It Works: 上下分化让每个肌群每周训练 2 次，这是常用的有效训练频率。48 小时恢复窗口让肌肉有时间修复和适应。每周容量增加 10-20% 是可持续的渐进方式。
                            • Rescue: 如果太累，保持 Week1 的组数和次数，但提高动作质量。
                            """,
                            icon: "figure.strengthtraining.functional",
                            colorHex: "F39A7E",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW2",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "核心专项 · 2x/Week · 稳定性强化",
                            description: """
                            Add dedicated core work for improved force transfer and injury prevention.
                            
                            • Core: 每周 2 节 12-15 分钟核心训练：
                            • Day15【必练】核心塑形（入门）抗伸展
                            • Day16【必练】背部塑形（入门）抗旋转
                            • Core Science: 核心不是"腹肌"，是整体稳定系统：
                            – 抗伸展（plank 系）保护腰椎
                            – 抗旋转（side plank 系）稳定骨盆
                            – 抗侧屈（pallof press 系）控制侧向力
                            – 每个动作保持 20-40 秒，3-4 组
                            • Anchor: 在下肢训练后进行，或安排在独立日。
                            • If-then: If 今天完成了腿部训练, I will 加 12 分钟核心专项作为收尾。
                            • Why It Works: 核心力量提升可以帮助改善深蹲硬拉等复合动作的表现。强核心是所有力量动作的基础平台。
                            • Rescue: 只做 2-3 个核心动作各 2 组，总共 6-8 分钟也有效。
                            """,
                            icon: "square.grid.3x3",
                            colorHex: "F7AF8C",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW2",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "营养时机 · Protein Timing · 合成窗口",
                            description: """
                            Support your training with strategic nutrition timing.
                            
                            • Core: 训练后 2 小时内摄入 20-40g 蛋白质：
                            – 训练后 30-60 分钟：快速蛋白（乳清、鸡蛋）
                            – 睡前 2-3 小时：缓释蛋白（酪蛋白、酸奶）
                            – 全天总量：体重（kg）× 1.6-2.2g 蛋白质
                            • Anabolic Window: 训练后肌肉对营养高度敏感：
                            – 训练后是补充营养的好时机
                            – 胰岛素敏感性较高，有助于营养吸收
                            – 48 小时内是重要恢复期
                            • Anchor: 训练包里常备蛋白质食物或补剂。
                            • If-then: If 我完成训练, I will 在 1 小时内吃 20-30g 蛋白质（如 2 个鸡蛋或 1 杯希腊酸奶）。
                            • Why It Works: 训练后蛋白质摄入支持肌肉修复和恢复。分散摄入（每餐 20-40g）比集中一餐更容易被身体利用。
                            • Rescue: 即使只是喝一杯牛奶（8g 蛋白）也比空腹好。
                            """,
                            icon: "fork.knife",
                            colorHex: "F2B89E",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW2",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "主动恢复 · 拉伸+散步 · 2-3 Days",
                            description: """
                            Elevate your recovery practice with intentional movement.
                            • Core: 每周 2-3 天进行主动恢复：
                            – 10-15 分钟全身拉伸或肌筋膜放松
                            – 15-30 分钟轻松散步
                            – 或古法养生操等温和课程
                            • Anchor: 优先安排在高强度训练后的第二天。
                            • If-then: If 我昨天完成了高强度训练, I will 今天选择拉伸和散步作为恢复。
                            • Why It Works: 主动恢复比完全静止更有效，可以促进废物清除和营养输送，同时保持训练习惯的连续性。
                            • Rescue: 即使只是 5 分钟拉伸 + 10 分钟慢走，也能达到恢复效果。
                            """,
                            icon: "leaf.fill",
                            colorHex: "F2B89E",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW2",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "Week 2 Progress Check-In",
                            description: """
                            Reflect on volume progression and recovery quality.
                            
                            • Core: Spend 10 minutes answering:
                            1. Training Volume: Was the increased volume manageable? (1-10)
                            2. Recovery: Soreness vs. pain? How's sleep?
                            3. Wins: Which exercises improved most?
                            4. Nutrition: Hit protein targets consistently?
                            5. Week 3 Prep: Ready for intensity increase or need to maintain?
                            
                            📊 【Week 2 Milestone】: Volume phase complete! Muscles are adapting. Week 3 shifts to intensity—heavier weight, same volume.
                            
                            • Anchor: Sunday evening reflection session.
                            • If-then: Every Sunday at 7 PM, I will assess volume tolerance and plan intensity adjustments.
                            
                            • Why It Works: Tracking volume response prevents overtraining and optimizes load progression.
                            • Rescue: Rate soreness (1-10), energy (1-10), confidence for Week 3 (1-10).
                            """,
                            icon: "chart.bar.fill",
                            colorHex: "F2B89E",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW2",
                            durationDays: 7,
                            isOptionalForCompletion: true
                        )
                    ],
                    tier: .program,
                    tags: [.strengthTraining, .physical, .nutrition, .scienceBacked],
                    durationWeeks: 1,
                    programGroup: "FeiStrength"
                ),

                // MARK: - WEEK 3 · INTENSIFICATION 强化阶段
                MiniChallenge(
                    title: "费教练力量 · Week 3",
                    tagline: "强度峰值 · 神经驱动",
                    description: """
                    Week 3 maintains volume but increases intensity through heavier loads and slower tempo.
                    This is the peak week - you'll lift the heaviest weights and challenge your neuromuscular system most.
                    """,
                    tag: "FeiStrengthW3",
                    colorHex: "F4A17E",
                    icon: "bolt.fill",
                    identityStatement: "Become someone who can push intensity intelligently while maintaining perfect form",
                    habits: [
                        Project50Habit(
                            name: "费教练 强度训练 · 4x/Week · 负荷峰值",
                            description: """
                            Peak intensity week with heavier loads and controlled tempo.
                            
                            • Core: 每周 4 节强度训练（维持上下分化）：
                            • Day1: 背部手臂 或 7.1（上肢）RPE 7-8
                            • Day2: 臀腿 7.2 或 7.5（下肢）RPE 7-8
                            • Day4: 肩部核心 6.30（上肢+核心）RPE 7
                            • Day5: 腿部专项（下肢辅助）RPE 6-7
                            • Intensification Protocols: Week3 提高强度而非容量：
                            – 重量增加 5-10%（如 5kg 哑铃→5.5-6kg）
                            – 维持相同组数×次数（不增加）
                            – 离心阶段控制 3-4 秒（增加 TUT）
                            – 组间休息延长到 90-120 秒（充分恢复）
                            – RPE 达到 7-8/10（还能再做 2-3 次）
                            • Anchor: 继续 Mon/Tue/Thu/Fri 节奏，充分休息。
                            • If-then: If 我今天感觉强壮, I will 在主力动作中尝试略重 5-10% 的重量，但只在前 2 组。
                            • Why It Works: 强化阶段通过高强度训练促进神经适应。维持容量而提高强度可避免过度疲劳，同时支持力量发展。
                            • Rescue: 如果当天状态不佳，回到 Week2 重量完成计划即可，不要在疲劳时追求突破。
                            """,
                            icon: "flame.fill",
                            colorHex: "F29170",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW3",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "塑形精修 · 3x/Week · 代谢压力",
                            description: """
                            Add metabolic stress through higher-rep sculpting work.
                            
                            • Core: 每周 3 节塑形课程（15-18 分钟）：
                            • Day22: 核心塑形（标准）+ 胸部塑形
                            • Day23: 肩部塑形（标准）+ 臀部塑形
                            • Day24: 臀部塑形（标准）或手臂塑形
                            • Metabolic Stress: 塑形课补充代谢压力路径：
                            – 使用 15-25 次高次数范围
                            – 组间休息缩短至 30-45 秒
                            – 追求肌肉泵感和灼烧感
                            – 与主力课在同一天完成（作为收尾）
                            • Anchor: 主力训练后立即进行，或间隔 4-6 小时。
                            • If-then: If 今天完成了费教练主力课, I will 休息 5 分钟后进行 15 分钟塑形收尾。
                            • Why It Works: 力量训练后进行高次数塑形可以增加代谢压力和肌肉泵感，这是肌肉发展的重要因素之一。高次数训练还能改善血液循环和营养输送。
                            • Rescue: 太累时减少到 1-2 节塑形课，或只做 10 分钟。
                            """,
                            icon: "wand.and.stars",
                            colorHex: "F6A57A",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW3",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "疲劳监测 · Daily Check · 过度训练预防",
                            description: """
                            Monitor fatigue markers to avoid excessive training in peak week.
                            
                            • Core: 每天早晨进行简单疲劳评估：
                            – 静息心率（比基线高 5+ bpm = 疲劳）
                            – 睡眠质量（1-5 分，<3 分需警惕）
                            – 肌肉酸痛程度（1-5 分，>4 分减量）
                            – 整体精力感（1-5 分，<2 分休息）
                            • Overtraining Prevention: Week3 强度高，需密切监控：
                            – 2 个以上指标异常 = 当天改为轻量训练或休息
                            – 连续 3 天异常 = 提前进入 Week4 减量
                            – 正常波动是可接受的，关注趋势而非单日
                            • Anchor: 起床后、去卫生间时进行 1 分钟快速评估。
                            • If-then: If 我的静息心率比平常高 >5 bpm 且睡眠<3 分, I will 今天将训练强度降低 20% 或改为主动恢复。
                            • Why It Works: 早期疲劳监测可以帮助你避免过度训练。注意身体信号（如静息心率变化）可以提示何时需要休息。及时调整比硬扛更明智。
                            • Rescue: 如果无法测心率，仅凭"整体感觉"也有价值，信任身体信号。
                            """,
                            icon: "waveform.path.ecg",
                            colorHex: "F3B088",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW3",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "灵活与恢复 · 每日轻活动",
                            description: """
                            Integrate daily movement and posture work for optimal recovery and presentation.
                            • Core: 每天安排 10-20 分钟轻活动：
                            – 关节灵活训练（Day2、Day24 的 15min 动物流等）
                            – 或全身拉伸、散步、古法养生操
                            • Anchor: 可在晨起后、工作间隙，或睡前进行。
                            • If-then: If 我今天没有安排高强度训练, I will 做 10-15 分钟关节灵活或拉伸，保持身体活跃度。
                            • Why It Works: 每日轻活动促进血液循环和营养输送，改善关节活动度，并通过姿态优化让训练效果"更显眼"。
                            • Rescue: 即使只是 5 分钟肩颈活动或几个简单拉伸动作，也胜过完全不动。
                            """,
                            icon: "figure.walk",
                            colorHex: "F3B088",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW3",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "Week 3 Progress Check-In",
                            description: """
                            Assess peak intensity tolerance and fatigue markers.
                            
                            • Core: Spend 10 minutes answering:
                            1. Peak Performance: Hit new strength PRs? Form quality maintained?
                            2. Fatigue Check: Resting HR elevated? Sleep disrupted? Mood changes?
                            3. Wins: What weight increases are you celebrating?
                            4. Warning Signs: Any joint pain, excessive soreness, or motivation crashes?
                            5. Deload Readiness: Ready for Week 4 recovery phase?
                            
                            📊 【Week 3 Milestone】: Peak intensity complete! CNS is adapting. Week 4 deload lets supercompensation happen—this is where gains appear.
                            
                            • Anchor: Sunday evening with extra recovery focus.
                            • If-then: Every Sunday at 7 PM, I will assess fatigue levels and celebrate peak week completion.
                            
                            • Why It Works: Peak weeks stress the system; tracking prevents overtraining and validates need for deload.
                            • Rescue: Rate overall fatigue (1-10), biggest win, one concern for recovery week.
                            """,
                            icon: "chart.bar.fill",
                            colorHex: "F3B088",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW3",
                            durationDays: 7,
                            isOptionalForCompletion: true
                        )
                    ],
                    tier: .program,
                    tags: [.strengthTraining, .physical, .nervous, .scienceBacked],
                    durationWeeks: 1,
                    programGroup: "FeiStrength"
                ),

                // MARK: - WEEK 4 · DELOAD & SUPERCOMPENSATION 减量超补偿
                MiniChallenge(
                    title: "费教练力量 · Week 4",
                    tagline: "主动减量 · 适应整合",
                    description: """
                    Week 4 is a strategic deload - reduce volume by 40-50% to allow full recovery and supercompensation.
                    You'll feel lighter, stronger, and ready for the next training cycle. This is where gains are realized.
                    """,
                    tag: "FeiStrengthW4",
                    colorHex: "F39067",
                    icon: "leaf.circle",
                    identityStatement: "Become someone who understands that recovery weeks make you stronger, not weaker",
                    habits: [
                        Project50Habit(
                            name: "费教练 减量训练 · 3x/Week · 技术精修",
                            description: """
                            Reduce volume by 40-50% while maintaining movement quality.
                            
                            • Core: 每周 3 节轻量技术训练：
                            • Day1: 背部手臂（7.1）仅做 2 组，RPE 5-6
                            • Day3: 臀腿（7.2）仅做 2 组，RPE 5-6
                            • Day5: 选择任意轻量课程或拉伸
                            • Deload Principles: Week4 减量不是偷懒，是科学恢复：
                            – 重量减少 20-30%（回到 Week1-2 水平）
                            – 组数减少 40-50%（每个动作 2 组）
                            – 维持动作质量和技术（慢速、控制）
                            – RPE 控制在 5-6/10（轻松完成）
                            – 感觉"我还能做更多"就对了
                            • Anchor: 维持相同训练时间，但强度和容量显著降低。
                            • If-then: If 今天是减量周训练, I will 提醒自己"轻松完成就是成功，不需要练到累"。
                            • Why It Works: 减量周让身体完成超补偿（supercompensation），通过休息支持适应和力量发展。功能性过度负荷需要几天时间才能转化为真正适应。减量周还能让神经系统恢复，为下一周期做准备。
                            • Rescue: 感觉精力充沛也要坚持减量，这是纪律而非软弱。
                            """,
                            icon: "leaf.arrow.triangle.circlepath",
                            colorHex: "F28060",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW4",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "主动恢复 · Daily · 促进再生",
                            description: """
                            Maximize recovery through daily light activity and stress management.
                            
                            • Core: 每天进行 20-30 分钟主动恢复：
                            – 散步、瑜伽、太极、古法养生操
                            – 或任何让你感觉"舒服"的轻量活动
                            – 心率不超过最大心率 60%（轻松对话）
                            • Recovery Modalities: 可选恢复手段：
                            – 泡沫轴筋膜放松 10-15 分钟
                            – 温水浴或蒸汽浴 15-20 分钟
                            – 拉伸或阴瑜伽 20-30 分钟
                            – 呼吸练习或冥想 10-15 分钟
                            • Anchor: 晚饭后或睡前 1-2 小时进行。
                            • If-then: If 今天是减量周, I will 把原本用于训练的精力投入到恢复活动中。
                            • Why It Works: 主动恢复比被动休息更能促进血液循环和恢复。轻量活动还能帮助放松和改善睡眠质量。Week4 是投资恢复的最佳时机。
                            • Rescue: 即使只是慢走 10 分钟也算完成。
                            """,
                            icon: "figure.walk",
                            colorHex: "F4956E",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW4",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "进度评估与庆祝 · Reflection · 成长确认",
                            description: """
                            Assess progress, celebrate gains, and plan the next cycle.
                            
                            • Core: Week4 末进行全面评估：
                            – 重新测试 Week1 的 3 个主要动作（重量/次数）
                            – 拍对比照片（正面、侧面、背面）
                            – 测量围度（胸、臂、腰、臀、腿）
                            – 记录主观感受（力量、精力、信心）
                            • Progress Markers: 4 周后可期待的变化：
                            – 力量增加 10-20%（初学者）
                            – 动作熟练度显著提高
                            – 肌肉酸痛恢复更快
                            – 睡眠和精力改善
                            – 体态和精神状态提升
                            • Anchor: Week4 的最后一天（Day7）进行评估和庆祝。
                            • If-then: If 今天是 Week4 Day7, I will 花 30 分钟记录进步，庆祝自己完成了一个完整训练周期。
                            • Why It Works: 定期评估提供客观反馈，庆祝进步强化正向行为循环。自我监测和进度跟踪是长期行为改变的重要因素。看到真实进步会激发继续训练的动力。
                            • Celebration: 你完成了科学化的 4 周力量训练！这不仅是身体的改变，更是自律和智慧的体现。为下一个周期充满信心！
                            """,
                            icon: "chart.line.uptrend.xyaxis",
                            colorHex: "F5A988",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW4",
                            durationDays: 7
                        ),
                        Project50Habit(
                            name: "Week 4 Final Progress Check-In",
                            description: """
                            Complete 4-week assessment and celebrate transformation.
                            
                            • Core: Spend 20 minutes on comprehensive review:
                            1. Strength Gains: Re-test Week 1 exercises. How much stronger?
                            2. Body Composition: Any visible changes? Measurements?
                            3. Habit Formation: Which habits stuck? Which felt automatic?
                            4. Energy & Recovery: How's your relationship with training now?
                            5. Next Steps: Continue to Week 5+? Take a break? New focus?
                            
                            🎉 【4-Week Program Complete!】 You built a foundation of intelligent strength training. Your body has adapted, your technique improved, and you proved consistency wins.
                            
                            • Anchor: Final day of Week 4 or Sunday evening.
                            • If-then: On the last day of Week 4, I will celebrate my 4-week journey and assess my transformation.
                            
                            • Why It Works: Completion rituals consolidate identity change and motivate next cycles. You are now someone who trains with intention.
                            • Celebration: Share your progress with someone or write a reflection on who you've become.
                            """,
                            icon: "star.circle.fill",
                            colorHex: "F5A988",
                            category: "费教练力量",
                            program: "miniChallenge",
                            level: nil,
                            tag: "FeiStrengthW4",
                            durationDays: 7,
                            isOptionalForCompletion: true
                        )
                    ],
                    tier: .program,
                    tags: [.strengthTraining, .physical, .selfCompassion, .scienceBacked],
                    durationWeeks: 1,
                    programGroup: "FeiStrength"
                ),

        // MARK: - 13. GLOWING JOURNEY · WEEK 1
        MiniChallenge(
            title: "Glowing Journey · Week 1",
            tagline: "清养七日 · Gentle cleansing",
            description: """
            Week 1 lays the foundation by clearing, hydrating, and balancing.
            
            We start with lightness: warm water, fewer burdens, earlier rest.
            """,
            tag: "GlowingJourneyW1",
            colorHex: "FFB3A0",
            icon: "sun.max.fill",
            identityStatement: "Become someone who listens to their body's need for lightness and rest",
            habits: [
                Project50Habit(
                    name: "Warm Water on Waking · 温水启动",
                    description: """
                    Begin the day by supporting digestion and hydration.

                    • Core: Drink one full glass of warm water before coffee or breakfast.
                    • Anchor: Keep water by your bedside or start a kettle first thing.
                    • If-then: After I wake up, I will drink warm water before anything else.
                    • Why It Works: Warms the digestive system and supports lymphatic drainage.
                    • Rescue: Even a few sips of warm water is enough to begin.
                    """,
                    icon: "drop.fill",
                    colorHex: "FFBEA8",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "One Less Burden · 清淡饮食",
                    description: """
                    Reduce something heavy for your system.

                    • Core: Skip fried food, refined sugar, or alcohol for the day.
                    • Anchor: Plan this when making your grocery list or meal prep.
                    • If-then: When I choose my meals, I will pick one lighter option.
                    • Why It Works: Gives your body a break to heal and restore.
                    • Rescue: Even removing one heavy meal element counts.
                    """,
                    icon: "heart.fill",
                    colorHex: "FFC9B0",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Pause After Evening Meal · 晚餐清收",
                    description: """
                    Let your last meal finish by 7 PM when possible.

                    • Core: Give yourself a window of rest before sleep (aim for 12-14 hour fast).
                    • Anchor: Plan your dinner timing to support this rhythm.
                    • If-then: After dinner, I will close the kitchen for the night.
                    • Why It Works: Supports digestion, skin repair, and cellular renewal.
                    • Rescue: Even skipping one late-night snack counts as success.
                    """,
                    icon: "moon.stars.fill",
                    colorHex: "FFC1A8",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 1 Progress Check-In",
                    description: """
                    Reflect on your cleansing foundation week.
                    
                    • Core: Spend 10 minutes answering:
                    1. Lightness: Do you feel lighter in body or mind?
                    2. Digestion: Any changes in how your body feels after meals?
                    3. Sleep Window: Did the earlier evening cutoff help?
                    4. Challenges: What felt hard to maintain?
                    5. Week 2 Readiness: Ready to add nourishing practices?
                    
                    🌱 【Week 1 Milestone】: Cleansing foundation set. Your body is preparing for deeper nourishment in Week 2.
                    
                    • Anchor: Sunday evening or end of Day 7.
                    • If-then: At the end of Week 1, I will reflect on what's shifting.
                    
                    • Why It Works: Tracking subtle body changes builds awareness and motivation for next phase.
                    • Rescue: Note 1 positive change and 1 thing to adjust.
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "FFC1A8",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW1",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.nutrition, .sleep, .physical, .tcm],
            durationWeeks: 1,
            programGroup: "GlowingJourney"
        ),

        // MARK: - 14. GLOWING JOURNEY · WEEK 2
        MiniChallenge(
            title: "Glowing Journey · Week 2",
            tagline: "养护活力七日 · Nourish Energy and Vitality",
            description: """
            Week 2 builds inner radiance by gently nourishing your energy and vitality.
            
            Gentle nutrition and earlier rest support warmth, stable mood, and a more "alive" complexion.
            """,
            tag: "GlowingJourneyW2",
            colorHex: "FF9F89",
            icon: "heart.circle.fill",
            identityStatement: "Become someone who nourishes their energy and vitality instead of running on empty",
            habits: [
                Project50Habit(
                    name: "Add Vitality-Building Foods · 滋养食养",
                    description: """
                    Feed your system a little more deeply.

                    • Core: Add red dates, goji berries, black sesame, or similar to one meal daily.
                    • Anchor: Pair this with breakfast, dessert, or afternoon drink.
                    • If-then: When I prepare a drink or snack, I will add one blood-building ingredient.
                    • Why It Works: Traditional foods support iron, circulation, and vitality.
                    • Rescue: Even sprinkling a tiny handful into oatmeal or congee is enough.
                    """,
                    icon: "leaf.fill",
                    colorHex: "FFA58E",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Beauty Congee Morning · 美颜早粥",
                    description: """
                    Start your day with something easy to digest and nourishing.

                    • Core: Warm congee or oats plus one beauty add-on (dates, goji, Chinese yam).
                    • Anchor: Breakfast time, preferably earlier in the day.
                    • If-then: In the morning, I will choose congee/oats with one nourishing topping.
                    • Why It Works: Warm, gentle breakfasts support digestion and sustained energy.
                    • Rescue: If full congee prep is too much, add toppings to simple oatmeal.
                    """,
                    icon: "cup.and.saucer.fill",
                    colorHex: "FFB099",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Early Rest · 早睡养护",
                    description: """
                    Let your body store and renew.

                    • Core: Aim to be in bed by 11 PM to support your body's natural restoration cycles.
                    • Anchor: Set a 10:30 PM "soft landing" reminder.
                    • If-then: When my 10:30 reminder goes off, I will begin winding down.
                    • Why It Works: Consistent early rest supports deep sleep and recovery processes.
                    • Rescue: If you can't sleep, rest in bed with gentle reading instead of scrolling.
                    """,
                    icon: "bed.double.fill",
                    colorHex: "FF9D88",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 2 Progress Check-In",
                    description: """
                    Assess vitality building and energy shifts.
                    
                    • Core: Spend 10 minutes answering:
                    1. Energy Baseline: Morning energy improving? (1-10)
                    2. Warmth & Vitality: Feeling warmer? More animated?
                    3. Skin & Complexion: Any subtle brightness or changes?
                    4. Nutrition Consistency: Hitting vitality-building foods daily?
                    5. Week 3 Focus: Ready for circulation and movement practices?
                    
                    🌟 【Week 2 Milestone】: Nourishment phase complete! Internal vitality is building. Week 3 brings circulation to move that energy.
                    
                    • Anchor: Sunday evening reflection.
                    • If-then: At the end of Week 2, I will note energy improvements.
                    
                    • Why It Works: Tracking vitality markers motivates continued practice and shows subtle benefits.
                    • Rescue: Rate energy (1-10), note one positive shift, one thing to refine.
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "FF9D88",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW2",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.nutrition, .sleep, .physical, .tcm],
            durationWeeks: 1,
            programGroup: "GlowingJourney"
        ),

        // MARK: - 15. GLOWING JOURNEY · WEEK 3
        MiniChallenge(
            title: "Glowing Journey · Week 3",
            tagline: "焕发七日 · Radiate from within",
            description: """
            Week 3 supports circulation and ease so your natural glow can show up.
            
            Gentle movement, facial massage, and quiet evening rituals help Qi and Blood move more freely.
            """,
            tag: "GlowingJourneyW3",
            colorHex: "FF8A7B",
            icon: "sparkles",
            identityStatement: "Become someone whose glow comes from circulation, calm, and small daily rituals",
            habits: [
                Project50Habit(
                    name: "Facial Massage / Gua Sha · 促进循环",
                    description: """
                    Invite movement and warmth to your face.

                    • Core: 5-10 minutes with gua sha, jade roller, or fingertips to move lymph.
                    • Anchor: Pair this with evening skincare or tea time.
                    • If-then: After I wash my face at night, I will do a few slow upward strokes.
                    • Why It Works: Facial massage supports skin vitality and creates a refreshing ritual.
                    • Rescue: Two minutes of simple upward strokes is still powerful.
                    """,
                    icon: "hands.sparkles.fill",
                    colorHex: "FF9486",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Gentle Movement · 活力流动",
                    description: """
                    Help energy and mood move together.

                    • Core: Light stretching, yoga, or 15-minute walk daily.
                    • Anchor: After dinner, after work, or upon waking.
                    • If-then: When I finish dinner, I will move gently for a few minutes.
                    • Why It Works: Movement helps you feel more energized.
                    • Rescue: If 15 minutes feels too much, stretch in bed for 2 minutes.
                    """,
                    icon: "figure.walk",
                    colorHex: "FF9A8B",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Evening Tea & Reflection · 安神养心",
                    description: """
                    Wind down with warmth and a soft check-in.

                    • Core: Warm drink (rose, chrysanthemum, longan, or plain water) + brief reflection.
                    • Anchor: After skincare or just before bed.
                    • If-then: Before sleep, I will drink something warm and check in with my body.
                    • Why It Works: Warm fluids can support relaxation and a sense of inner peace.
                    • Rescue: If journaling feels heavy, simply note one word to describe today.
                    """,
                    icon: "cup.and.saucer.fill",
                    colorHex: "FF9E91",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 3 Final Progress Check-In",
                    description: """
                    Complete 3-week transformation assessment and celebrate your glow.
                    
                    • Core: Spend 15 minutes on comprehensive review:
                    1. Visible Changes: Skin brightness, eye clarity, overall radiance?
                    2. Energy Quality: More sustained energy throughout day?
                    3. Self-Care Ritual: Which practices became natural habits?
                    4. Inner State: Calmer? More grounded? More connected to body?
                    5. Continue or Adjust: Which habits will you maintain long-term?
                    
                    ✨ 【3-Week Journey Complete!】 You've cleansed, nourished, and circulated. This is holistic wellness—not quick fixes, but sustainable radiance.
                    
                    • Anchor: Final day of Week 3 or Sunday evening.
                    • If-then: On the last day, I will reflect on my transformation and celebrate the glow.
                    
                    • Why It Works: Integration and celebration consolidate new identity as someone who prioritizes inner radiance.
                    • Celebration: Take a photo, write yourself a letter, or share your journey with someone you trust.
                    """,
                    icon: "star.circle.fill",
                    colorHex: "FF9E91",
                    category: "Glowing Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "GlowingJourneyW3",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.movement, .stress, .selfCompassion, .tcm],
            durationWeeks: 1,
            programGroup: "GlowingJourney"
        ),

        // MARK: - EXECUTIVE ENERGY · WEEK 1 - Energy Audit & Boundaries
        MiniChallenge(
            title: "Executive Energy · Week 1",
            tagline: "Audit & Boundaries",
            description: """
            Week 1 of Executive Energy: Map your natural energy peaks and create protective boundaries around your most valuable resource—your attention and vitality.
            
            This week is about awareness: when are you sharpest? Where is energy leaking?
            """,
            tag: "ExecutiveEnergyW1",
            colorHex: "2C5F7C",
            icon: "chart.line.uptrend.xyaxis",
            identityStatement: "Become someone who protects their peak energy like a strategic asset",
            habits: [
                Project50Habit(
                    name: "Peak Energy Mapping",
                    description: """
                    Track when you're sharpest throughout the day for 7 days.

                    • Core: Every 2 hours, rate your energy (1-10) and note what you're doing.
                    • Anchor: Set 5-6 daily alarms (9 AM, 11 AM, 1 PM, 3 PM, 5 PM, 7 PM).
                    • If-then: When my energy alarm goes off, I will rate my energy and note my current activity.
                    • Why It Works: Most people never identify their natural performance windows—this data reveals when to schedule deep work vs. admin tasks.
                    • Rescue: Even tracking morning/afternoon/evening (3x daily) provides valuable patterns.
                    """,
                    icon: "waveform.path.ecg",
                    colorHex: "3A708C",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Calendar Audit",
                    description: """
                    Cut 20% of low-value commitments from your schedule.

                    • Core: Review this week's calendar. Identify 2-3 meetings/commitments that don't align with your core goals. Decline, delegate, or reschedule.
                    • Anchor: Sunday evening planning session or Monday morning.
                    • If-then: During my weekly review, I will identify 2-3 low-value commitments to remove.
                    • Why It Works: High performers often over-commit. Even 20% reduction creates breathing room for strategic work.
                    • Rescue: Start with just 1 commitment—say no to one meeting or task this week.
                    """,
                    icon: "calendar.badge.minus",
                    colorHex: "4A819C",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Strategic Breaks",
                    description: """
                    Take a 5-minute reset between tasks or meetings.

                    • Core: Between every major task/meeting, take 5 minutes to walk, breathe, or stare out a window. No phone.
                    • Anchor: End of each meeting or task block.
                    • If-then: When I finish a meeting or task, I will take 5 minutes before starting the next thing.
                    • Why It Works: Continuous task-switching depletes cognitive resources. Micro-breaks restore focus and prevent decision fatigue.
                    • Rescue: Even 2 minutes of closing your eyes or stretching counts.
                    """,
                    icon: "pause.circle.fill",
                    colorHex: "5A92AC",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 1 Progress Check-In",
                    description: """
                    Reflect on your energy patterns and boundary experiments.
                    
                    • Core: Spend 10 minutes reviewing your week:
                    1. Energy Patterns: What time of day were you most focused? (Review your tracking data)
                    2. Boundary Wins: Which commitment did you decline or delegate?
                    3. Break Quality: Did strategic breaks actually help your focus?
                    4. Challenges: What made energy protection difficult this week?
                    5. Week 2 Prep: Based on your energy data, when will you schedule deep work blocks?
                    
                    📊 【Week 1 Milestone】: You've mapped your natural rhythms. Week 2 uses this data to optimize your schedule for peak performance.
                    
                    • Anchor: Sunday evening reflection or end of Day 7.
                    • If-then: Every Sunday at 7 PM, I will review my energy data and plan next week's focus blocks.
                    
                    • Why It Works: Self-awareness drives optimization. Tracking patterns reveals opportunities you couldn't see before.
                    • Rescue: Just answer: What time am I sharpest? What will I schedule then?
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "5A92AC",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW1",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.focus, .boundaries, .stress, .scienceBacked],
            durationWeeks: 1,
            programGroup: "ExecutiveEnergy"
        ),

        // MARK: - EXECUTIVE ENERGY · WEEK 2 - Peak Performance Windows
        MiniChallenge(
            title: "Executive Energy · Week 2",
            tagline: "Peak Performance Windows",
            description: """
            Week 2: Now that you know your energy patterns, design your schedule around them. Protect your peak hours for deep work. Batch admin tasks during low-energy windows.
            
            This is about optimization: right work, right time.
            """,
            tag: "ExecutiveEnergyW2",
            colorHex: "1F4A5C",
            icon: "bolt.circle.fill",
            identityStatement: "Become someone who architects their day around natural performance rhythms",
            habits: [
                Project50Habit(
                    name: "Deep Work Blocks",
                    description: """
                    Schedule 90-minute focus sessions during your peak energy windows.

                    • Core: Based on Week 1 data, block 90 minutes of uninterrupted time during your sharpest hours. Single task only. Phone off.
                    • Anchor: Your highest-energy window (often 9-11 AM or 2-4 PM).
                    • If-then: During my peak energy block, I will work on my most important task with zero interruptions.
                    • Why It Works: 90 minutes aligns with natural focus cycles many people experience. Peak energy combined with focused work can lead to excellent output.
                    • Rescue: Start with 45 minutes if 90 feels impossible. Build up gradually.
                    """,
                    icon: "clock.badge.checkmark.fill",
                    colorHex: "2A5A6C",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Decision Batching",
                    description: """
                    Group similar decisions/tasks together to reduce cognitive switching costs.

                    • Core: Batch all emails into 2-3 time blocks. Group all calls together. Handle admin tasks in one session.
                    • Anchor: Low-energy windows (often post-lunch or late afternoon).
                    • If-then: During my low-energy window, I will batch all similar tasks together.
                    • Why It Works: Task switching disrupts focus. Batching similar tasks helps maintain concentration.
                    • Rescue: Just batch emails—check only 3x daily instead of continuously.
                    """,
                    icon: "square.stack.3d.up.fill",
                    colorHex: "356B7C",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Energy Replenishment Ritual",
                    description: """
                    Create a non-negotiable 20-minute recovery period daily.

                    • Core: Pick one: walk outside, meditate, nap, stretch, sit in silence. Same time daily.
                    • Anchor: Midday (12-2 PM) or late afternoon (3-4 PM).
                    • If-then: At [chosen time], I will take 20 minutes for energy replenishment, no exceptions.
                    • Why It Works: Strategic rest prevents afternoon crashes and extends sustainable performance hours.
                    • Rescue: 10 minutes counts. Even 5 minutes of intentional rest beats pushing through.
                    """,
                    icon: "leaf.circle.fill",
                    colorHex: "407C8C",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 2 Progress Check-In",
                    description: """
                    Assess your peak performance optimization and energy management.
                    
                    • Core: Spend 10 minutes reflecting on implementation:
                    1. Deep Work Success: Did you protect 90-min blocks consistently? What helped?
                    2. Batching Impact: How did grouping similar tasks affect your focus?
                    3. Recovery Quality: Is your replenishment ritual restoring energy?
                    4. Output Quality: Did work quality improve during peak hours?
                    5. Week 3 Integration: Ready to add weekly planning and delegation?
                    
                    📊 【Week 2 Milestone】: You've tested peak performance protocols. Week 3 builds sustainable systems for long-term excellence.
                    
                    • Anchor: Sunday evening or end of Day 7.
                    • If-then: Every Sunday, I will evaluate my peak performance practices and refine my schedule.
                    
                    • Why It Works: Regular optimization prevents drift. Small weekly adjustments compound into major gains.
                    • Rescue: Rate each practice (1-10), note what's working, adjust one thing.
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "407C8C",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW2",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.focus, .sleep, .mental, .scienceBacked],
            durationWeeks: 1,
            programGroup: "ExecutiveEnergy"
        ),

        // MARK: - EXECUTIVE ENERGY · WEEK 3 - Sustainable Excellence
        MiniChallenge(
            title: "Executive Energy · Week 3",
            tagline: "Sustainable Excellence",
            description: """
            Week 3: Integrate everything into a sustainable system. Add weekly planning, delegation practice, and non-negotiable recovery protocols.
            
            This is about longevity: high performance without burnout.
            """,
            tag: "ExecutiveEnergyW3",
            colorHex: "163A48",
            icon: "infinity.circle.fill",
            identityStatement: "Become someone who sustains peak performance through intelligent recovery and delegation",
            habits: [
                Project50Habit(
                    name: "Sunday Strategy Session",
                    description: """
                    Weekly 30-minute review and planning session.

                    • Core: Review last week's wins/lessons. Plan next week's top 3 priorities. Schedule deep work blocks. Identify what to cut/delegate.
                    • Anchor: Sunday evening (6-8 PM) or Monday morning (before work).
                    • If-then: Every Sunday at 7 PM, I will review my week and plan my priorities.
                    • Why It Works: Weekly planning supports clarity and helps balance urgent and important tasks.
                    • Rescue: 10 minutes to just identify top 3 priorities for the week.
                    """,
                    icon: "calendar.circle.fill",
                    colorHex: "234A58",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Delegation Practice",
                    description: """
                    Hand off 3 tasks this week that don't require your unique expertise.

                    • Core: Identify 3 tasks on your plate that someone else could do 80% as well. Delegate them with clear instructions.
                    • Anchor: During your Sunday strategy session or Monday morning.
                    • If-then: This week, I will delegate 3 tasks that don't require my unique strengths.
                    • Why It Works: Your highest-value work is what only you can do. Everything else is stealing time from leverage.
                    • Rescue: Delegate just 1 task—or even ask for help on one thing.
                    """,
                    icon: "person.2.circle.fill",
                    colorHex: "2E5A68",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Recovery Non-Negotiables",
                    description: """
                    Commit to 3 non-negotiable recovery practices daily.

                    • Core: Choose 3: 7+ hours sleep, 20-min walk, meditation, workout, nature time, social connection.
                    • Anchor: Morning, midday, and evening slots.
                    • If-then: Every day, I will protect time for my 3 recovery practices no matter how busy I am.
                    • Why It Works: Elite performers prioritize recovery as much as performance. Rest is where adaptation happens.
                    • Rescue: Protect just 1 non-negotiable—sleep is the foundation.
                    """,
                    icon: "heart.circle.fill",
                    colorHex: "396A78",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 3 Final Progress Check-In",
                    description: """
                    Complete your 3-week Executive Energy transformation and plan for sustainability.
                    
                    • Core: Spend 15 minutes on comprehensive review:
                    1. System Integration: Are weekly planning + deep work + delegation now automatic?
                    2. Recovery Practices: Which 3 non-negotiables stuck? Which need adjustment?
                    3. Energy ROI: How has optimizing your schedule affected output quality?
                    4. Sustainability Check: Can you maintain this pace long-term?
                    5. Next Phase: Continue refining or take what you've learned into a new focus?
                    
                    🎉 【3-Week Program Complete!】 You've built a sustainable high-performance system. You now protect peak energy, delegate strategically, and recover intentionally.
                    
                    • Anchor: Final day of Week 3 or Sunday evening.
                    • If-then: On the last day, I will reflect on my transformation and celebrate building sustainable excellence.
                    
                    • Why It Works: Completion rituals consolidate new identity. You're now someone who performs without burnout.
                    • Celebration: Review your wins, share your system with a colleague, or write your future self a letter.
                    """,
                    icon: "star.circle.fill",
                    colorHex: "396A78",
                    category: "Executive Energy",
                    program: "miniChallenge",
                    level: nil,
                    tag: "ExecutiveEnergyW3",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.focus, .boundaries, .selfCompassion, .scienceBacked],
            durationWeeks: 1,
            programGroup: "ExecutiveEnergy"
        ),

        // MARK: - RELATIONSHIP RENAISSANCE · WEEK 1 - Presence Practices
        MiniChallenge(
            title: "Relationship Renaissance · Week 1",
            tagline: "Presence Practices",
            description: """
            Week 1: Build the foundation of deep connection—undivided attention, genuine curiosity, and expressed appreciation.
            
            This week focuses on being fully present with the people who matter most.
            """,
            tag: "RelationshipRenaissanceW1",
            colorHex: "C97B84",
            icon: "person.2.circle.fill",
            identityStatement: "Become someone who shows up fully for the people they love",
            habits: [
                Project50Habit(
                    name: "20-Min Undivided Attention",
                    description: """
                    Give someone your complete, phone-free presence daily.

                    • Core: Choose one person daily. Put phone in another room. Make eye contact. Listen without planning your response.
                    • Anchor: After dinner, during morning coffee, or evening wind-down.
                    • If-then: After dinner, I will give someone 20 minutes of phone-free, undivided attention.
                    • Why It Works: Research shows 20 minutes of quality attention creates stronger bonds than hours of distracted time together.
                    • Rescue: Even 10 minutes of full presence beats an hour of partial attention.
                    """,
                    icon: "eye.circle.fill",
                    colorHex: "D18B94",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Curiosity Questions",
                    description: """
                    Ask one deep, open-ended question daily.

                    • Core: Replace "How was your day?" with: "What felt meaningful today?" "What was challenging?" "What are you thinking about?"
                    • Anchor: During quality time, meals, or transition moments.
                    • If-then: When I connect with someone, I will ask one curious, open-ended question.
                    • Why It Works: Open questions invite vulnerability and deeper sharing. Closed questions shut down conversation.
                    • Rescue: "How are you really doing?" is enough to start.
                    """,
                    icon: "bubble.left.and.bubble.right.fill",
                    colorHex: "D99BA4",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Gratitude Expression",
                    description: """
                    Tell someone specifically why you appreciate them.

                    • Core: Not generic "I appreciate you." Say: "I appreciate how you [specific action] because it makes me feel [emotion]."
                    • Anchor: During your 20-min quality time or before bed.
                    • If-then: Each day, I will tell someone one specific thing I appreciate about them.
                    • Why It Works: Specific appreciation strengthens relationships and can encourage positive behaviors. Many relationship experts suggest maintaining more positive than negative interactions.
                    • Rescue: Even "Thank you for [one small thing]" deepens connection.
                    """,
                    icon: "heart.text.square.fill",
                    colorHex: "E1ABB4",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 1 Progress Check-In",
                    description: """
                    Reflect on your presence practices and connection quality.
                    
                    • Core: Spend 10 minutes reviewing your week:
                    1. Presence Quality: How did 20 minutes of undivided attention feel? For you? For them?
                    2. Question Depth: Did open-ended questions spark deeper conversations?
                    3. Appreciation Impact: How did expressing specific gratitude affect your relationships?
                    4. Resistance: What made full presence difficult? (Phone urges? Discomfort with silence?)
                    5. Week 2 Readiness: Ready to deepen communication with emotional vocabulary and repair skills?
                    
                    💝 【Week 1 Milestone】: You've practiced foundational presence. Week 2 adds emotional clarity and conflict navigation.
                    
                    • Anchor: Sunday evening or end of Day 7.
                    • If-then: Every Sunday, I will reflect on connection quality and plan next week's growth.
                    
                    • Why It Works: Awareness of relationship patterns enables intentional improvement. Small shifts compound into transformation.
                    • Rescue: Just answer: What felt good? What was hard? What will I try next week?
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "E1ABB4",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW1",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.connection, .social, .emotional],
            durationWeeks: 1,
            programGroup: "RelationshipRenaissance"
        ),

        // MARK: - RELATIONSHIP RENAISSANCE · WEEK 2 - Communication Depth + Repair
        MiniChallenge(
            title: "Relationship Renaissance · Week 2",
            tagline: "Communication Depth + Repair",
            description: """
            Week 2: Go deeper with emotional vocabulary and repair skills. Learn to name feelings accurately and reconnect after disconnection.
            
            This week focuses on navigating conflict and restoring connection.
            """,
            tag: "RelationshipRenaissanceW2",
            colorHex: "B56B74",
            icon: "arrow.triangle.2.circlepath.circle.fill",
            identityStatement: "Become someone who can repair ruptures and communicate with emotional clarity",
            habits: [
                Project50Habit(
                    name: "Feeling Vocabulary",
                    description: """
                    Name emotions with precision beyond "good" or "bad."

                    • Core: Expand your vocabulary—use words like: tender, overwhelmed, grateful, resentful, anxious, hopeful, lonely, energized.
                    • Anchor: When sharing about your day or during conflict.
                    • If-then: When I talk about feelings, I will use specific emotion words instead of "fine" or "bad."
                    • Why It Works: Precise language helps partners understand what you actually need. "Overwhelmed" invites different support than "frustrated."
                    • Rescue: Keep a feelings wheel nearby. Even naming 2-3 emotions builds emotional literacy.
                    """,
                    icon: "text.bubble.fill",
                    colorHex: "BD7B84",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Repair Attempts",
                    description: """
                    Practice reconnecting after conflict or disconnection.

                    • Core: When you notice tension, try: "Can we try that again?" "I'm sorry, what I meant was..." "I miss feeling connected to you."
                    • Anchor: As soon as you notice disconnection or after a conflict.
                    • If-then: When I feel disconnected, I will make a repair attempt within 24 hours.
                    • Why It Works: Successful relationships aren't conflict-free—they're skilled at repair. Quick repair can help prevent resentment from building up. Many relationship experts see repair attempts as key to relationship success.
                    • Rescue: "I'm sorry" or "Can we talk?" is a complete repair attempt.
                    """,
                    icon: "arrow.uturn.backward.circle.fill",
                    colorHex: "C58B94",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Active Listening",
                    description: """
                    Reflect back what you heard before responding.

                    • Core: Say: "What I'm hearing is [summary]. Did I get that right?" Wait for confirmation before sharing your perspective.
                    • Anchor: During important conversations or conflicts.
                    • If-then: When someone shares something important, I will reflect back what I heard before responding.
                    • Why It Works: Most conflict comes from feeling unheard. Reflection proves you're listening and prevents misunderstandings.
                    • Rescue: Just say "Tell me more" to show you're listening.
                    """,
                    icon: "ear.fill",
                    colorHex: "CD9BA4",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 2 Progress Check-In",
                    description: """
                    Reflect on emotional depth and repair skills.
                    
                    • Core: Spend 10 minutes reviewing communication growth:
                    1. Emotional Vocabulary: Did naming specific emotions help understanding?
                    2. Repair Success: When did you attempt repair? How was it received?
                    3. Listening Quality: Did reflecting back reduce misunderstandings?
                    4. Conflict Patterns: What triggers disconnection? What helps reconnection?
                    5. Week 3 Readiness: Ready to build sustained intimacy through rituals and touch?
                    
                    💝 【Week 2 Milestone】: You've learned to navigate rupture and repair. Week 3 creates lasting rituals for sustained intimacy.
                    
                    • Anchor: Sunday evening reflection.
                    • If-then: Every Sunday, I will assess communication skills and celebrate repair wins.
                    
                    • Why It Works: Conflict navigation is a learnable skill. Progress tracking builds confidence in difficult moments.
                    • Rescue: Just note: One repair that worked, one thing to improve.
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "CD9BA4",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW2",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.connection, .social, .emotional, .selfCompassion],
            durationWeeks: 1,
            programGroup: "RelationshipRenaissance"
        ),

        // MARK: - RELATIONSHIP RENAISSANCE · WEEK 3 - Sustained Intimacy Rituals
        MiniChallenge(
            title: "Relationship Renaissance · Week 3",
            tagline: "Sustained Intimacy Rituals",
            description: """
            Week 3: Build lasting rituals that maintain connection over time. Create sacred weekly time, prioritize non-verbal connection, and dream together about the future.
            
            This week focuses on long-term relationship sustainability.
            """,
            tag: "RelationshipRenaissanceW3",
            colorHex: "A15B64",
            icon: "heart.circle.fill",
            identityStatement: "Become someone who sustains deep intimacy through intentional rituals and shared dreams",
            habits: [
                Project50Habit(
                    name: "Weekly Connection Ritual",
                    description: """
                    Create sacred weekly time for deeper conversation.

                    • Core: 60-90 minutes weekly, no distractions. Talk about: what you're each feeling, what you need, what you appreciate, what's ahead.
                    • Anchor: Same time every week (Sunday morning, Friday evening, etc.).
                    • If-then: Every [chosen day] at [time], we will protect 60 minutes for our connection ritual.
                    • Why It Works: Predictable connection time prevents "We never talk anymore." It's preventative maintenance for relationships, similar to the "State of Our Union" meeting concept.
                    • Rescue: 30 minutes of deeper conversation is enough. Quality over quantity.
                    """,
                    icon: "calendar.badge.clock",
                    colorHex: "A96B74",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Touch & Presence",
                    description: """
                    Daily non-verbal connection through physical touch.

                    • Core: 6-second hug, hand-holding during a walk, forehead touch, back rub—any intentional physical connection.
                    • Anchor: Morning goodbye, evening reunion, or bedtime.
                    • If-then: Every morning before leaving, I will give a 6-second hug.
                    • Why It Works:  Extended physical touch helps create deeper connection.
                    • Rescue: Even holding hands for 30 seconds while sitting together counts.
                    """,
                    icon: "hands.sparkles.fill",
                    colorHex: "B17B84",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Future Dreaming",
                    description: """
                    Share hopes, dreams, and visions for the future together.

                    • Core: Talk about: where do you want to be in 1/5/10 years? What do you want to create together? What excites you about the future?
                    • Anchor: During your weekly connection ritual or a weekend walk.
                    • If-then: This week, I will ask: "What's one thing you're excited about for our future?"
                    • Why It Works: Shared vision creates partnership and forward momentum. Couples who dream together often stay together. Many relationship experts emphasize the importance of shared meaning.
                    • Rescue: Just ask "What's one thing you're looking forward to?" and listen fully.
                    """,
                    icon: "sparkles",
                    colorHex: "B98B94",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 3 Final Progress Check-In",
                    description: """
                    Complete your 3-week Relationship Renaissance and celebrate connection transformation.
                    
                    • Core: Spend 15 minutes on comprehensive review:
                    1. Ritual Integration: Did weekly connection time become natural? Touch rituals?
                    2. Communication Growth: How has emotional vocabulary changed your conversations?
                    3. Connection Quality: Do you feel closer, more understood, more appreciated?
                    4. Conflict Changes: Are repairs faster? More effective?
                    5. Sustainability: Which practices will you maintain long-term?
                    
                    💝 【3-Week Program Complete!】 You've transformed how you connect. Presence, emotional clarity, and intentional rituals are now part of your relationship foundation.
                    
                    • Anchor: Final day of Week 3 or Sunday evening.
                    • If-then: On the last day, I will reflect on our relationship growth and celebrate together.
                    
                    • Why It Works: Relationship transformation comes from consistent small actions. You've proven that presence and intentionality create intimacy.
                    • Celebration: Share your favorite moment from the past 3 weeks with your partner. Recommit to one key practice.
                    """,
                    icon: "star.circle.fill",
                    colorHex: "B98B94",
                    category: "Relationship Renaissance",
                    program: "miniChallenge",
                    level: nil,
                    tag: "RelationshipRenaissanceW3",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.connection, .social, .emotional, .spiritual],
            durationWeeks: 1,
            programGroup: "RelationshipRenaissance"
        ),

        // MARK: - CREATIVE BREAKTHROUGH · WEEK 1 - Creative Foundation
        MiniChallenge(
            title: "Creative Breakthrough · Week 1",
            tagline: "Creative Foundation",
            description: """
            Week 1: Build your creative foundation by establishing a daily practice, silencing your inner critic, and filling your inspiration well.
            
            This week is about permission—permission to create badly, to explore, to play.
            """,
            tag: "CreativeBreakthroughW1",
            colorHex: "E89BA3",
            icon: "paintbrush.fill",
            identityStatement: "Become someone who creates daily, not just when inspiration strikes",
            habits: [
                Project50Habit(
                    name: "Morning Pages",
                    description: """
                    Write 3 pages of stream-of-consciousness every morning.

                    • Core: Write by hand, first thing after waking. No editing, no rereading. Just dump everything out—complaints, dreams, ideas, nonsense.
                    • Anchor: Before checking phone or starting your day.
                    • If-then: After I wake up, I will write 3 pages before doing anything else.
                    • Why It Works: Morning pages can help clear mental clutter and bypass your inner critic, creating space for creativity. This approach is inspired by practices from "The Artist's Way."
                    • Rescue: Even 1 page or 10 minutes of freewriting counts.
                    """,
                    icon: "book.pages.fill",
                    colorHex: "ECA5AD",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "20-Minute Creation Time",
                    description: """
                    Make something—anything—for 20 minutes daily.

                    • Core: Choose your medium (write, draw, photograph, code, cook, build). Set timer. Create until it rings. No judgment allowed.
                    • Anchor: Same time daily—morning coffee or evening wind-down.
                    • If-then: At [chosen time], I will create for 20 minutes without editing or judging.
                    • Why It Works: Daily practice builds creative muscle memory. Consistency matters more than quality at this stage.
                    • Rescue: 10 minutes counts. Even 5 minutes of doodling is creative practice.
                    """,
                    icon: "timer",
                    colorHex: "F0AFB7",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Inspiration Gathering",
                    description: """
                    Consume something inspiring daily to fill your creative well.

                    • Core: Read poetry, visit a gallery, watch a film, listen to music, observe nature—anything that stirs something in you.
                    • Anchor: Evening wind-down or weekend morning.
                    • If-then: Each day, I will spend 15-30 minutes consuming inspiring content with full attention.
                    • Why It Works: You can't create from an empty well. Input fuels output. This concept is inspired by the "Artist's Date" practice from "The Artist's Way."
                    • Rescue: Even 10 minutes with one inspiring piece counts.
                    """,
                    icon: "sparkles",
                    colorHex: "F4B9C1",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 1 Progress Check-In",
                    description: """
                    Reflect on your creative foundation and permission to create.
                    
                    • Core: Spend 10 minutes reviewing:
                    1. Daily Practice: Did morning pages help clear mental clutter?
                    2. Creation Time: What medium felt most natural? What sparked joy?
                    3. Inner Critic: How loud was perfectionism? Did you create despite it?
                    4. Inspiration: What filled your creative well most?
                    5. Week 2 Readiness: Ready to focus on deliberate skill-building?
                    
                    🎨 【Week 1 Milestone】: Permission granted! You've established daily creative practice. Week 2 adds focused skill development.
                    
                    • Anchor: Sunday evening or end of Day 7.
                    • If-then: Every Sunday, I will reflect on creative growth and celebrate showing up.
                    
                    • Why It Works: Creative confidence comes from consistent practice, not perfect output. Tracking builds momentum.
                    • Rescue: Just note: What did I create? What did I learn? What will I practice next week?
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "F4B9C1",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW1",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.creativity, .mental, .emotional],
            durationWeeks: 1,
            programGroup: "CreativeBreakthrough"
        ),

        // MARK: - CREATIVE BREAKTHROUGH · WEEK 2 - Skill Building & Practice
        MiniChallenge(
            title: "Creative Breakthrough · Week 2",
            tagline: "Skill Building & Practice",
            description: """
            Week 2: Move from random creation to deliberate practice. Focus on one specific skill, get feedback, and embrace imperfection as part of the process.
            
            This week is about growth through focused repetition.
            """,
            tag: "CreativeBreakthroughW2",
            colorHex: "D88B93",
            icon: "chart.line.uptrend.xyaxis",
            identityStatement: "Become someone who practices their craft with intention and welcomes imperfection",
            habits: [
                Project50Habit(
                    name: "Focused Skill Practice",
                    description: """
                    Choose ONE micro-skill and practice it deliberately for 30 minutes daily.

                    • Core: Pick something specific (e.g., drawing circles, writing opening lines, color mixing, chord transitions). Practice with full attention. Track progress.
                    • Anchor: Your established creation time from Week 1.
                    • If-then: During my creation time, I will practice [chosen skill] with focused attention.
                    • Why It Works: Deliberate practice (focused, repeated, with feedback) tends to build skill more effectively than unfocused exploration. Many experts in skill acquisition emphasize this approach.
                    • Rescue: 15 minutes of focused practice beats 30 minutes of distracted work.
                    """,
                    icon: "target",
                    colorHex: "DC959D",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Share One Thing",
                    description: """
                    Share your work with at least one person this week.

                    • Core: Post it, send it to a friend, show a family member—just get it out of your head and into the world. Don't explain or apologize.
                    • Anchor: Mid-week (Wednesday or Thursday).
                    • If-then: This week, I will share one piece of my work without apologizing for it.
                    • Why It Works: Sharing breaks perfectionism and builds creative courage. Feedback accelerates growth.
                    • Rescue: Share with just one trusted person, or post anonymously.
                    """,
                    icon: "paperplane.fill",
                    colorHex: "E09FA7",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Study the Masters",
                    description: """
                    Analyze 3 works you admire in your chosen medium.

                    • Core: Don't just consume—study. What techniques did they use? What choices did they make? Try to reverse-engineer one element.
                    • Anchor: Weekend deep-dive session or spread across 3 days.
                    • If-then: This week, I will study 3 pieces I admire and note specific techniques I can learn from.
                    • Why It Works: Studying masters accelerates learning by showing you what's possible and how it's achieved.
                    • Rescue: Study just 1 work deeply. Quality over quantity.
                    """,
                    icon: "eye.fill",
                    colorHex: "E4A9B1",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 2 Progress Check-In",
                    description: """
                    Assess skill development and creative courage.
                    
                    • Core: Spend 10 minutes reviewing growth:
                    1. Skill Focus: Did deliberate practice improve your chosen micro-skill?
                    2. Sharing Experience: How did it feel to share your work? What feedback did you receive?
                    3. Master Study: What techniques did you discover? Which will you try?
                    4. Perfectionism: Did focusing on one skill reduce or increase inner criticism?
                    5. Week 3 Readiness: Ready for volume challenge and iteration?
                    
                    🎨 【Week 2 Milestone】: Skill-building in progress! Week 3 shifts to volume—creating prolifically to discover what works.
                    
                    • Anchor: Sunday evening reflection.
                    • If-then: Every Sunday, I will celebrate skill progress and plan next week's focus.
                    
                    • Why It Works: Feedback and deliberate practice accelerate mastery. Sharing builds confidence.
                    • Rescue: Rate skill improvement (1-10), note one technique learned, one thing to practice more.
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "E4A9B1",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW2",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.creativity, .focus, .mental],
            durationWeeks: 1,
            programGroup: "CreativeBreakthrough"
        ),

        // MARK: - CREATIVE BREAKTHROUGH · WEEK 3 - Output & Iteration
        MiniChallenge(
            title: "Creative Breakthrough · Week 3",
            tagline: "Output & Iteration",
            description: """
            Week 3: Increase volume and embrace iteration. Create multiple versions, seek feedback actively, and learn to revise without attachment.
            
            This week is about quantity leading to quality—and detaching your worth from your work.
            """,
            tag: "CreativeBreakthroughW3",
            colorHex: "C87B83",
            icon: "arrow.triangle.2.circlepath",
            identityStatement: "Become someone who creates prolifically and iterates fearlessly",
            habits: [
                Project50Habit(
                    name: "Volume Challenge",
                    description: """
                    Create 7 complete pieces this week—one per day, no matter how rough.

                    • Core: Finish something daily. It doesn't have to be good—it just has to be done. One poem, one sketch, one photo series, one short piece.
                    • Anchor: Your established creation time—extend to 30-45 minutes if needed.
                    • If-then: Each day, I will create and complete one piece, even if it's imperfect.
                    • Why It Works: Volume teaches you what works faster than perfecting one piece. Quantity breeds quality (pottery class study: weight vs. quality group).
                    • Rescue: Make smaller pieces—haikus instead of poems, 3-minute sketches, 100-word stories.
                    """,
                    icon: "square.stack.3d.up.fill",
                    colorHex: "D0858D",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Revision Practice",
                    description: """
                    Take one piece from earlier and create 3 variations of it.

                    • Core: Choose one piece. Make it 3 different ways—different color palette, different angle, different tone. Don't just tweak—reimagine.
                    • Anchor: Mid-week creative session.
                    • If-then: This week, I will take one piece and create 3 distinct versions of it.
                    • Why It Works: Iteration reveals possibilities you couldn't see in version 1. Detaches ego from "the one right way."
                    • Rescue: Just make 2 versions. Or make 1 version that's radically different from the original.
                    """,
                    icon: "arrow.uturn.backward.circle.fill",
                    colorHex: "D88F97",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Feedback Seeking",
                    description: """
                    Ask 3 people for specific feedback on your work.

                    • Core: Share your work and ask: "What works?" "What's confusing?" "What would you want more of?" Listen without defending.
                    • Anchor: After creating your 7 pieces or mid-week.
                    • If-then: This week, I will ask 3 people for feedback and listen without explaining or defending.
                    • Why It Works: External perspective reveals blind spots and accelerates growth. Learning to receive feedback is a creative superpower.
                    • Rescue: Ask 1 person for feedback. Even one perspective helps.
                    """,
                    icon: "bubble.left.and.bubble.right.fill",
                    colorHex: "E099A1",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 3 Progress Check-In",
                    description: """
                    Reflect on volume, iteration, and feedback integration.
                    
                    • Core: Spend 10 minutes reviewing:
                    1. Volume Challenge: Did creating 7 pieces teach you about your process?
                    2. Iteration Learning: What did multiple versions reveal about possibilities?
                    3. Feedback Reception: How did it feel to receive feedback? What was useful?
                    4. Creative Confidence: Has creating prolifically reduced perfectionism?
                    5. Week 4 Readiness: Ready to synthesize everything into one complete project?
                    
                    🎨 【Week 3 Milestone】: Volume breeds quality! Week 4 integrates all learning into your capstone project.
                    
                    • Anchor: Sunday evening reflection.
                    • If-then: Every Sunday, I will celebrate creative output and prepare for integration week.
                    
                    • Why It Works: Iteration and feedback transform good creators into great ones. Tracking builds creative identity.
                    • Rescue: Just note: How many pieces did I complete? What surprised me? What will I refine?
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "E099A1",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW3",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.creativity, .focus, .emotional, .selfCompassion],
            durationWeeks: 1,
            programGroup: "CreativeBreakthrough"
        ),

        // MARK: - CREATIVE BREAKTHROUGH · WEEK 4 - Integration & Showcase
        MiniChallenge(
            title: "Creative Breakthrough · Week 4",
            tagline: "Integration & Showcase",
            description: """
            Week 4: Synthesize everything into one complete project, share it publicly, and reflect on your creative transformation.
            
            This week is about completion, celebration, and stepping into your identity as a creative person.
            """,
            tag: "CreativeBreakthroughW4",
            colorHex: "B86B73",
            icon: "star.fill",
            identityStatement: "Become someone who completes creative projects and shares them with confidence",
            habits: [
                Project50Habit(
                    name: "Capstone Project",
                    description: """
                    Create one complete, polished piece that synthesizes what you've learned.

                    • Core: Take everything from Weeks 1-3 and create something you're proud to share. Spend 45-60 minutes daily refining it.
                    • Anchor: Your established creation time—extend as needed.
                    • If-then: Each day this week, I will work on my capstone project with intention and care.
                    • Why It Works: Completion builds creative confidence. Finishing is a skill that compounds over time.
                    • Rescue: Make it smaller in scope, but finish it completely.
                    """,
                    icon: "flag.checkered",
                    colorHex: "C0757D",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW4",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Public Sharing",
                    description: """
                    Share your capstone project publicly—social media, portfolio, exhibition, reading, etc.

                    • Core: Post it somewhere visible. Write a caption about your process. Tag it. Let people see it. Don't hide or apologize.
                    • Anchor: End of week or when piece is complete.
                    • If-then: When my capstone is complete, I will share it publicly within 24 hours.
                    • Why It Works: Public sharing cements your identity as a creator. Visibility attracts opportunities and community.
                    • Rescue: Share in a small community group or forum. Start with semi-public.
                    """,
                    icon: "megaphone.fill",
                    colorHex: "C87F87",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW4",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Creative Reflection",
                    description: """
                    Write a reflection on your 4-week journey: what you learned, what surprised you, who you're becoming.

                    • Core: Answer: What did I create? What did I learn? What do I want to continue? Who am I as a creative person now?
                    • Anchor: Final day of Week 4 or after public sharing.
                    • If-then: At the end of Week 4, I will reflect on my creative journey and celebrate my growth.
                    • Why It Works: Reflection consolidates learning and creates narrative of transformation. Celebrating progress fuels future creation.
                    • Rescue: Write 3 bullet points: 1 thing you created, 1 thing you learned, 1 thing you're proud of.
                    """,
                    icon: "book.closed.fill",
                    colorHex: "D08991",
                    category: "Creative Breakthrough",
                    program: "miniChallenge",
                    level: nil,
                    tag: "CreativeBreakthroughW4",
                    durationDays: 7
                )
            ],
            tier: .program,
            tags: [.creativity, .emotional, .selfCompassion, .social],
            durationWeeks: 1,
            programGroup: "CreativeBreakthrough"
        ),

        // MARK: - SELF-MASTERY JOURNEY · 4-WEEK PROGRAM
        // A comprehensive program for building self-discipline, confidence, and sustainable personal systems
        // Week 1: Foundation Reset - Sleep, hydration, movement basics
        // Week 2: Discipline Building - Small promises, eat the frog, temptation pause
        // Week 3: Confidence Cultivation - Victory log, uncomfortable actions, competence reminders
        // Week 4: System Integration - Weekly review, values alignment, future self letter

        // MARK: - SELF-MASTERY JOURNEY · WEEK 1 - Foundation Reset
        MiniChallenge(
            title: "Self-Mastery · Week 1",
            tagline: "Reset the basics",
            description: """
            Week 1 establishes the non-negotiable foundations: sleep, hydration, and movement.
            Before building discipline or confidence, we need a stable base. This week is about showing up for the basics—consistently, not perfectly.
            """,
            tag: "SelfMasteryW1",
            colorHex: "2C3E50",
            icon: "square.stack.3d.down.right.fill",
            identityStatement: "Become someone who masters the fundamentals before chasing complexity",
            habits: [
                Project50Habit(
                    name: "Sleep Anchor",
                    description: """
                    Lock in a consistent wake time (±30 min) every day, including weekends.

                    • Core: Choose a realistic wake time. Set alarm for same time 7 days. Get up within 30 minutes, even if tired.
                    • Anchor: Place phone/alarm across the room so you must stand to turn it off.
                    • If-then: When my alarm goes off, I will stand up immediately—no snooze, no negotiation.
                    • Why It Works: Consistent wake time is the single most powerful lever for sleep quality. Your body learns when to prepare for waking.
                    • Rescue: If you sleep terribly, still wake at target time. One bad night won't break the pattern; sleeping in will.
                    """,
                    icon: "alarm.fill",
                    colorHex: "34495E",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Hydration First",
                    description: """
                    Drink 16oz (500ml) of water within 30 minutes of waking—before coffee, food, or phone.

                    • Core: Keep water by your bed or prepare it the night before. Drink it all before anything else.
                    • Anchor: Between waking and bathroom/coffee.
                    • If-then: After I stand up, I will drink my water before I touch my phone or make coffee.
                    • Why It Works: Overnight dehydration affects cognition and energy. Starting hydrated sets a foundation for the day.
                    • Rescue: Even half a glass counts. The ritual matters more than the volume.
                    """,
                    icon: "drop.fill",
                    colorHex: "3D566E",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Movement Minimum",
                    description: """
                    Move your body for 10 minutes daily—any form, any intensity.

                    • Core: Walk, stretch, dance, yoga, push-ups—anything that gets you moving. The bar is low on purpose.
                    • Anchor: Right after morning water, or immediately after work.
                    • If-then: After my morning water, I will move for 10 minutes before starting my day.
                    • Why It Works: Daily movement builds the identity of "someone who moves" before worrying about fitness goals. Consistency > intensity at this stage.
                    • Rescue: 5 minutes counts. 2 minutes of stretching in bed counts. Show up.
                    """,
                    icon: "figure.walk",
                    colorHex: "4A6785",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW1",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 1 Progress Check-In",
                    description: """
                    Reflect on your foundation habits and prepare for discipline building.

                    • Core: Spend 10 minutes answering:
                      1. Wake Consistency: Did you hit your wake time ±30 min every day?
                      2. Hydration: Did morning water become automatic?
                      3. Movement: What form of movement felt most sustainable?
                      4. Energy Baseline: How's your energy compared to before? (1-10)
                      5. Week 2 Readiness: Ready to add small commitments and accountability?

                    🏗️ [Week 1 Milestone]: Foundations set! You've proven you can show up for basics. Week 2 builds discipline through small promises.

                    • Anchor: Sunday evening or end of Day 7.
                    • If-then: Every Sunday at 7 PM, I will review my week and celebrate consistency.
                    • Why It Works: Self-monitoring improves adherence. Noticing progress builds motivation.
                    • Rescue: Just answer: What worked? What will I adjust?
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "5A7A9A",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW1",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.sleep, .physical, .beginner, .scienceBacked],
            durationWeeks: 1,
            programGroup: "SelfMasteryJourney"
        ),

        // MARK: - SELF-MASTERY JOURNEY · WEEK 2 - Discipline Building
        MiniChallenge(
            title: "Self-Mastery · Week 2",
            tagline: "Small promises, kept",
            description: """
            Week 2 builds self-discipline through small, kept commitments. Discipline isn't about willpower—it's about trust. Every promise you keep to yourself strengthens the belief that you're someone who follows through.
            """,
            tag: "SelfMasteryW2",
            colorHex: "34495E",
            icon: "checkmark.seal.fill",
            identityStatement: "Become someone who keeps promises to themselves",
            habits: [
                Project50Habit(
                    name: "One Tiny Promise",
                    description: """
                    Make and keep one small promise to yourself every day.

                    • Core: Each morning, choose ONE tiny commitment: "Today I will [specific action]." Make it so small you can't fail.
                    • Examples: "I will make my bed." "I will read 1 page." "I will do 5 push-ups." "I will text Mom."
                    • Anchor: Morning routine, right after your foundation habits.
                    • If-then: Each morning after my movement, I will choose and write down today's tiny promise.
                    • Why It Works: Self-discipline is built through repeated evidence that you do what you say. Small promises build the neural pathway of follow-through.
                    • Rescue: If you forget until evening, make a 1-minute promise and keep it before bed.
                    """,
                    icon: "hand.raised.fill",
                    colorHex: "3D566E",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Eat the Frog",
                    description: """
                    Complete your most dreaded task before 10 AM.

                    • Core: Identify the task you're avoiding most. Do it first, before checking email or social media.
                    • Anchor: First thing after morning routine (before 10 AM).
                    • If-then: After my morning routine, I will identify my "frog" and complete it before doing anything else.
                    • Why It Works: Willpower depletes throughout the day. Tackling hard tasks early uses your peak decision-making capacity. Plus, the relief fuels the rest of your day.
                    • Rescue: If the task is too big, do 15 minutes of it. Starting counts.
                    """,
                    icon: "bolt.fill",
                    colorHex: "4A6785",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Temptation Pause",
                    description: """
                    Wait 10 minutes before any impulse action (scroll, snack, purchase, etc.).

                    • Core: When you feel the urge to do something impulsive, set a timer for 10 minutes. Do something else. Then decide.
                    • Anchor: Whenever you notice an urge or craving.
                    • If-then: When I feel the urge to [scroll/snack/buy], I will wait 10 minutes and do something else first.
                    • Why It Works: Most impulses fade within 10 minutes. This practice builds the muscle of conscious choice over reactive behavior.
                    • Rescue: 5 minutes counts. Even 2 minutes of pause before acting builds awareness.
                    """,
                    icon: "pause.circle.fill",
                    colorHex: "5A7A9A",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW2",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 2 Progress Check-In",
                    description: """
                    Assess your discipline building and prepare for confidence cultivation.

                    • Core: Spend 10 minutes reviewing:
                      1. Promise Keeping: How many tiny promises did you keep? (out of 7)
                      2. Frog Eating: Did completing hard tasks early improve your days?
                      3. Impulse Control: What impulses did you pause on? What did you learn?
                      4. Self-Trust: Do you trust yourself more than last week? (1-10)
                      5. Week 3 Readiness: Ready to build confidence through small wins and uncomfortable actions?

                    💪 [Week 2 Milestone]: Discipline muscle building! You've proven you can keep promises to yourself. Week 3 cultivates confidence.

                    • Anchor: Sunday evening reflection.
                    • If-then: Every Sunday, I will count my kept promises and celebrate follow-through.
                    • Why It Works: Tracking promises kept builds identity as a reliable person—to yourself.
                    • Rescue: Note your best kept promise and one thing to improve.
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "6A8AAA",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW2",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.focus, .mental, .boundaries, .scienceBacked],
            durationWeeks: 1,
            programGroup: "SelfMasteryJourney"
        ),

        // MARK: - SELF-MASTERY JOURNEY · WEEK 3 - Confidence Cultivation
        MiniChallenge(
            title: "Self-Mastery · Week 3",
            tagline: "Evidence over affirmations",
            description: """
            Week 3 builds genuine confidence—not through affirmations, but through evidence. Real confidence comes from doing hard things and proving to yourself that you can handle discomfort. This week, we collect evidence of your capability.
            """,
            tag: "SelfMasteryW3",
            colorHex: "5D6D7E",
            icon: "star.circle.fill",
            identityStatement: "Become someone who builds confidence through action, not just positive thinking",
            habits: [
                Project50Habit(
                    name: "Victory Log",
                    description: """
                    Record 3 small wins before bed every night.

                    • Core: Write down 3 things you accomplished today—no matter how small. "Made bed. Sent email. Ate vegetables."
                    • Anchor: Evening wind-down, right before sleep.
                    • If-then: Before I go to sleep, I will write 3 wins from today.
                    • Why It Works: The brain has a negativity bias—it notices failures more than wins. Deliberate win-tracking rewires this pattern and builds a reservoir of evidence that you're capable.
                    • Rescue: 1 win is enough. "I showed up today" counts.
                    """,
                    icon: "trophy.fill",
                    colorHex: "6D7D8E",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Uncomfortable Action",
                    description: """
                    Do one slightly scary or uncomfortable thing daily.

                    • Core: Choose something that makes you nervous but isn't dangerous: speak up in a meeting, send that message, try something new, ask for what you want.
                    • Anchor: Identify it in the morning; complete it before evening.
                    • If-then: Each morning, I will identify one uncomfortable action and complete it today.
                    • Why It Works: Confidence is built by expanding your comfort zone through repeated evidence that discomfort doesn't kill you. Courage is a muscle.
                    • Rescue: "Uncomfortable" can be tiny: making eye contact, saying no to something small, sharing an opinion.
                    """,
                    icon: "flame.fill",
                    colorHex: "7D8D9E",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Competence Reminder",
                    description: """
                    List one skill or strength you have, with evidence.

                    • Core: Write: "I am good at [skill] because [specific evidence]." Use concrete proof, not vague feelings.
                    • Example: "I am good at listening because my friend said I helped her feel heard yesterday."
                    • Anchor: Morning journaling or during your win log.
                    • If-then: Each day, I will identify one competence and write down the evidence for it.
                    • Why It Works: Impostor syndrome thrives on vague self-doubt. Specific evidence of competence counters the narrative that you're not good enough.
                    • Rescue: Even "I am good at making coffee because mine tastes good" counts. Start where you are.
                    """,
                    icon: "sparkles",
                    colorHex: "8D9DAE",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW3",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 3 Progress Check-In",
                    description: """
                    Evaluate confidence growth and prepare for system integration.

                    • Core: Spend 10 minutes reviewing:
                      1. Win Collection: How many wins did you log this week? Notice any patterns?
                      2. Discomfort Tolerance: What uncomfortable actions did you take? How did they feel after?
                      3. Competence Awareness: What strengths did you rediscover or claim?
                      4. Confidence Level: Rate your confidence now vs. Week 1 (1-10)
                      5. Week 4 Readiness: Ready to integrate everything into sustainable systems?

                    ⭐ [Week 3 Milestone]: Confidence through evidence! You've proven you can handle discomfort. Week 4 builds lasting systems.

                    • Anchor: Sunday evening reflection.
                    • If-then: Every Sunday, I will review my wins and uncomfortable actions with pride.
                    • Why It Works: Deliberate reflection on growth cements identity change.
                    • Rescue: Answer: What was my bravest moment? What did I learn about myself?
                    """,
                    icon: "chart.bar.fill",
                    colorHex: "9DADBE",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW3",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.selfCompassion, .emotional, .mental, .scienceBacked],
            durationWeeks: 1,
            programGroup: "SelfMasteryJourney"
        ),

        // MARK: - SELF-MASTERY JOURNEY · WEEK 4 - System Integration
        MiniChallenge(
            title: "Self-Mastery · Week 4",
            tagline: "Sustainable by design",
            description: """
            Week 4 integrates everything into sustainable personal systems. Motivation fades; systems persist. This week, you'll design your weekly review ritual, align your time with your values, and create the operating system for your best life.
            """,
            tag: "SelfMasteryW4",
            colorHex: "D4AC0D",
            icon: "gearshape.2.fill",
            identityStatement: "Become someone who builds systems, not just relies on motivation",
            habits: [
                Project50Habit(
                    name: "Weekly Review Ritual",
                    description: """
                    Conduct a 30-minute weekly planning and reflection session.

                    • Core: Every Sunday, review: What worked? What didn't? What's the #1 priority next week? Schedule your most important tasks.
                    • Structure: 10 min review last week → 10 min plan next week → 10 min schedule deep work blocks
                    • Anchor: Sunday evening (6-8 PM) or Monday morning before work.
                    • If-then: Every Sunday at 7 PM, I will complete my weekly review before doing anything else.
                    • Why It Works: Weekly reviews prevent drift and ensure your weeks align with your intentions, not just your inbox.
                    • Rescue: 10 minutes to identify just your top 3 priorities for the week.
                    """,
                    icon: "calendar.circle.fill",
                    colorHex: "D9B51A",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW4",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Values Alignment Check",
                    description: """
                    Ask: "Did today's actions align with what matters most to me?"

                    • Core: Each evening, review your day against your top 3 values. Note where you lived them and where you drifted.
                    • Anchor: Evening reflection, before or after your victory log.
                    • If-then: Each evening, I will ask: "Did I live my values today?" and note one example.
                    • Why It Works: Without conscious alignment, urgent tasks crowd out important ones. Daily values check keeps you living intentionally.
                    • Rescue: Even noticing one moment of alignment is enough. Awareness precedes change.
                    """,
                    icon: "compass.drawing",
                    colorHex: "DEBE27",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW4",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Future Self Letter",
                    description: """
                    Write a letter to yourself 90 days from now.

                    • Core: Describe who you're becoming, what habits you've built, and what you're proud of. Be specific and aspirational.
                    • Anchor: During Week 4 (any day), spend 15-20 minutes writing.
                    • If-then: This week, I will write a letter to my future self describing who I'm becoming.
                    • Why It Works: Connecting present actions to future identity strengthens motivation and commitment. Your future self becomes real and worth investing in.
                    • Rescue: Write 3 sentences: "In 90 days, I will have [habit]. I will feel [emotion]. I will be proud of [achievement]."
                    """,
                    icon: "envelope.open.fill",
                    colorHex: "E3C734",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW4",
                    durationDays: 7
                ),
                Project50Habit(
                    name: "Week 4 Final Progress Check-In",
                    description: """
                    Complete your 4-week Self-Mastery Journey and celebrate transformation.

                    • Core: Spend 20 minutes on comprehensive review:
                      1. Foundation Habits: Which basics are now automatic?
                      2. Discipline Growth: How has your relationship with promises changed?
                      3. Confidence Shift: What evidence of capability have you collected?
                      4. System Sustainability: Which systems will you maintain long-term?
                      5. Identity Change: Who are you now that you weren't 4 weeks ago?

                    🏆 [4-Week Program Complete!] You've built foundations, discipline, confidence, and systems. You're no longer someone who "wants to" change—you're someone who HAS changed.

                    • Anchor: Final day of Week 4 or Sunday evening.
                    • If-then: On the last day, I will complete my final review and celebrate my transformation.
                    • Why It Works: Completion rituals consolidate identity change. Celebration reinforces the behavior that got you here.
                    • Celebration: Read your future self letter aloud. Share your journey with someone. Mark this milestone.
                    """,
                    icon: "star.circle.fill",
                    colorHex: "E8D041",
                    category: "Self-Mastery Journey",
                    program: "miniChallenge",
                    level: nil,
                    tag: "SelfMasteryW4",
                    durationDays: 7,
                    isOptionalForCompletion: true
                )
            ],
            tier: .program,
            tags: [.focus, .boundaries, .selfCompassion, .scienceBacked],
            durationWeeks: 1,
            programGroup: "SelfMasteryJourney"
        )
    ]
}
