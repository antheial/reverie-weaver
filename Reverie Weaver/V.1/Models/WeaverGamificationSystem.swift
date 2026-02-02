//
//  WeaverGamificationSystem.swift
//  Reverie Weaver
//

import SwiftUI
import SwiftData
import Foundation
import Combine
import UserNotifications

// MARK: - 1. Constellation Badge Model (Grimoire)

@Model
final class ConstellationBadge {
    // Identity
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var category: String
    
    // Lore
    var story: String
    var hintText: String
    
    // Seasonal lore slices
    var seasonalSpringLore: String?
    var seasonalSummerLore: String?
    var seasonalAutumnLore: String?
    var seasonalWinterLore: String?
        
    // Visual / state
    var artifactImageName: String?
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var completionsRequired: Int = 21
        
    // Narrative Elements
        var whisper: String = ""
        var chapter: Int = 0

    // Tracks if the user has tapped the card to clear the "New" glow
        var hasBeenViewed: Bool = false

    // Year-round discovery: minimum days since journey start before badge becomes visible
        var minDaysForVisibility: Int = 0

        init(
            name: String,
            iconName: String,
            colorHex: String,
            category: String,
            story: String,
            hintText: String = "",
            seasonalSpringLore: String? = nil,
            seasonalSummerLore: String? = nil,
            seasonalAutumnLore: String? = nil,
            seasonalWinterLore: String? = nil,
            completionsRequired: Int = 21,
            artifactImageName: String? = nil,
            whisper: String = "",
            chapter: Int = 0,
            minDaysForVisibility: Int = 0
        ) {
            self.id = UUID()
            self.name = name
            self.iconName = iconName
            self.colorHex = colorHex
            self.category = category
            self.story = story
            self.hintText = hintText
            self.seasonalSpringLore = seasonalSpringLore
            self.seasonalSummerLore = seasonalSummerLore
            self.seasonalAutumnLore = seasonalAutumnLore
            self.seasonalWinterLore = seasonalWinterLore
            self.artifactImageName = artifactImageName
            self.completionsRequired = completionsRequired
            self.whisper = whisper
            self.chapter = chapter
            self.minDaysForVisibility = minDaysForVisibility

            // Auto-unlock logic for the Prologue (The First Loom)
            if completionsRequired <= 0 {
                self.isUnlocked = true
                self.unlockedDate = Date()
            } else {
                self.isUnlocked = false
                self.unlockedDate = nil
            }
        }
    
    func currentStory(for seasonName: String) -> String {
        let normalized = seasonName.lowercased()
        switch normalized {
        case "spring":
            return seasonalSpringLore ?? story
        case "summer":
            return seasonalSummerLore ?? story
        case "autumn", "fall":
            return seasonalAutumnLore ?? story
        case "winter":
            return seasonalWinterLore ?? story
        default:
            return story
        }
    }
}

// MARK: - 2. Constellation Data

struct ConstellationData {
    static let allConstellations: [ConstellationBadge] = [
        // MARK: - 0. Prequel · The First Loom
        
        ConstellationBadge(
            name: "The First Loom",
            iconName: "sparkles.square.filled.on.square",
            colorHex: "F5E6D3",
            category: "Origin",
            story: """
            Before the Age of Unspun Thread, there were no Weavers at all—only scattered moments, loose and unfinished, slipping through mortal hands. People woke and slept and hurried and hoped, but nothing held their days together. The elders say even the stars looked frayed at the edges.

            In those early nights, a wanderer began to gather what others cast aside: half-kept promises, forgotten mornings, tiny acts of courage no one had noticed. She carried them in a rough-woven satchel until it grew too heavy to bear.

            At the edge of the world, where sea meets sky, she emptied the satchel onto the ground. There, she drove four stakes into the earth—dawn, noon, dusk, and midnight—and stretched a frame between them. This, she called the First Loom. One by one, she threaded the moments she had collected across it, turning scraps into pattern, accident into arc.

            The work was clumsy at first. Threads snapped. Patterns collapsed. Yet the wanderer returned each day, choosing not perfection but persistence. That choice—the courage to keep weaving through uncertainty—was the first true magic of her craft.

            When she was finished, the story goes, the world looked up and realized that a day could be shaped instead of endured. Those who learned from her became the first Weavers, each adding their own small courage to the loom.

            Each time you choose one small thing to repeat, to honor, to return to, you are standing beside that wanderer at the world’s edge, helping her build the loom all over again.
            """,
            hintText: "Every tapestry begins with a first, imperfect frame.",
            seasonalSpringLore: nil,
            seasonalSummerLore: nil,
            seasonalAutumnLore: nil,
            seasonalWinterLore: nil,
            completionsRequired: 0,
            artifactImageName: nil,
            whisper: "Every tapestry begins with one honest thread.",
            chapter: 0,
            minDaysForVisibility: 0  // Immediate
        ),

        // MARK: - 1. The Morning Star

        ConstellationBadge(
            name: "The Morning Star",
            iconName: "sun.max.fill",
            colorHex: "FFD18B",
            category: "Morning Rituals",
            story: """
            In the Age of Unspun Thread, when days slid past like fog and no one knew where one ended and the next began, there lived a Weaver who grew weary of drifting. One night she rose while the sky was still iron-dark and walked beyond the sleeping town, carrying only her spindle.

            There, at the very rim of the world, she waited in the frost and silence. When the first spear of light breached the horizon, the elders say it did not simply rise—it struck her spindle like a bell. She caught that ray and drew it down, spinning it into a single golden strand.

            With that thread she marked the first hour of the day upon her loom and called it the Morning Star. From then on, the wise said, the first thread decides the pattern of all that follows.

            She did not become a new person overnight. Some mornings she overslept. Some dawns were cloudy and gray. But each time she chose to rise again, she strengthened the path between her bed and the loom, until courage itself felt like a habit.

            You, who rise before the world begins to shout, walk in her lineage. Each time you greet the day with intention, you are not merely waking up; you are laying down the golden warp that holds the rest of your hours in place.
            """,
            hintText: "To find this star, one must greet the day before the world rushes in.",
            seasonalSpringLore: nil,
            seasonalSummerLore: "The Morning Star burns brightest when the days are long. Your energy mirrors the sun's abundance—seize the light.",
            seasonalAutumnLore: nil,
            seasonalWinterLore: "Even when the sun sleeps late in winter, the Morning Star reminds us that light always returns. Your consistency creates warmth in the cold.",
            completionsRequired: 21,
            artifactImageName: nil,
            whisper: "The first light you greet shapes the whole day.",
            chapter: 1,
            minDaysForVisibility: 0  // Immediate - foundational badge
        ),

        // MARK: - 2. The Tranquil Moon
        
        ConstellationBadge(
            name: "The Tranquil Moon",
            iconName: "moon.fill",
            colorHex: "9B7EBD",
            category: "Mindful Living",
            story: """
            Old records tell of a Weaver whose hands moved so quickly that her loom never stilled. Her cloth was flawless, but those who touched it felt nothing. She had mastered the Morning Star but not the quiet that must answer it. Her days were all warp and no space between.

            One night, as the story goes, a moon so round and bright rose that it poured a silver road across her workshop floor and up onto her restless loom.

            Dazzled, she paused. It was the first stillness she had tasted in many years. In that held breath, beneath the pale light, she heard something she had forgotten—the low, steady hum of the world itself, the pattern behind all patterns. She saw that it was not only the threads that mattered, but the quiet spaces between them.

            At first, the stillness frightened her more than any storm. But slowly, she let her shoulders drop. She set the shuttle down. She stepped back and learned to look at what she had made.

            From then on, she became the keeper of the Tranquil Moon, teaching that true weaving requires not only motion, but deliberate rest. Cloth made in this way was said to calm even the most troubled heart.

            You have found that silver silence. When you choose to stop, to breathe, to simply notice, you are standing in the same moonlit workshop, letting stillness do the work your hurry never could.
            """,
            hintText: "This luminary appears only to those who stop moving and start seeing.",
            seasonalSpringLore: "Like the moon pulling the tides, your quiet practice is pulling new life from the earth beneath you.",
            seasonalSummerLore: nil,
            seasonalAutumnLore: nil,
            seasonalWinterLore: "The winter moon is sharp, clear, and distant. Your mind has found a similar clarity in the cold silence of this season.",
            completionsRequired: 21,
            artifactImageName: nil,
            whisper: "Stillness between threads holds the quiet pattern.",
            chapter: 2,
            minDaysForVisibility: 0  // Immediate - foundational badge
        ),

        // MARK: - 3. The Verdant Leaf
        
        ConstellationBadge(
            name: "The Verdant Leaf",
            iconName: "leaf.fill",
            colorHex: "A8B5A0",
            category: "Health Foundations",
            story: """
            The elders speak of a master of the Loom whose tapestries were so intricate that kings quarreled to possess them. Yet the Weaver herself grew thin and brittle, her back bowed like a broken shuttle. One day, her body failed her, and she collapsed beneath an ancient oak on the hill outside the city.

            As she lay there, too weak to rise, she heard the tree murmuring in the wind. “I do not weave,” the oak was said to whisper, “yet I stand through storm and drought. I drink the rain. I turn toward the sun. I sleep in winter so that I may leaf again.” The Weaver understood then that while she had tended every thread, she had neglected the loom that held them.

            At first, she raged at the slowness of healing. The world was still demanding, and the tapestries still unfinished. But the oak only stood, year after year, teaching her that survival itself is a kind of courage.

            She drank from the stream and ate the acorns that fell at her side. Slowly, season by season, her strength returned. When she finally sat at her loom again, she carved a leaf into the frame as a vow: never again would the work outrun the body that carried it.

            You, who choose to rest, to nourish, to move with care, are inheriting that vow. You are not only the maker of the tapestry—you are the living loom. When you honor your body, you give every future thread a place to belong.
            """,
            hintText: "Tend to the roots, and the leaves will appear on their own.",
            seasonalSpringLore: "Green returns to the branch. Your vitality is rising with the sap of the world. The body remembers how to bloom.",
            seasonalSummerLore: nil,
            seasonalAutumnLore: "Leaves fall to feed the roots. Your self-care now is not visible growth, but deep nourishment for the seasons ahead.",
            seasonalWinterLore: nil,
            completionsRequired: 21,
            artifactImageName: nil,
            whisper: "Tend the loom of your body before the work.",
            chapter: 3,
            minDaysForVisibility: 0  // Immediate - foundational badge
        ),

        // MARK: - 4. The Sacred Flame
        
        ConstellationBadge(
            name: "The Sacred Flame",
            iconName: "flame.fill",
            colorHex: "D4A5A5",
            category: "Creative Practice",
            story: """
            In the cold age before color, the threads of the world were woven from nothing but ash and smoke. It is said that a Weaver named Ignis grew tired of grey. No dye in the markets satisfied her; no pigment from berry or stone would catch the kind of light she sought.

            So she climbed to the highest, loneliest peak, where the sky comes close to touching the earth. There, she lifted a lantern into the darkness until a wandering ember from the celestial fire fell into it. That small spark did not accept ordinary fuel—it flared only when fed with questions, risks, and half-formed ideas.

            Ignis returned and dipped her threads into that living blaze. Color leapt into them—dangerous, shifting, impossible to predict. Those who wore her cloth felt their own buried stories stir and burn.

            On many days the flame was small and hard to tend. Some nights she thought of letting it go out, of returning to safe, grey cloth. But each time she chose to shield a tiny coal with her hands, she proved that creativity is less about talent and more about brave, repeated tending.

            You, who put pen to paper, brush to canvas, hand to instrument, are Keeper of that same fire. Creativity is not a trinket handed down; it is a Sacred Flame that asks, again and again, “Will you feed me today?”
            """,
            hintText: "This fire cannot be found; it must be made from nothing.",
            seasonalSpringLore: nil,
            seasonalSummerLore: "The fire dances high. Your creative spirit is wild and untamed this season. Let it burn.",
            seasonalAutumnLore: nil,
            seasonalWinterLore: "A hearth fire keeps the home alive. Your creativity is the warmth in the dark, the story told against the cold.",
            completionsRequired: 21,
            artifactImageName: nil,
            whisper: "Feed the small fire that colors your days.",
            chapter: 4,
            minDaysForVisibility: 30  // Reveals after 1 month
        ),

        // MARK: - 5. The Gentle Wind
        
        ConstellationBadge(
            name: "The Gentle Wind",
            iconName: "wind",
            colorHex: "B8C5D6",
            category: "Focus Flow",
            story: """
            In the scrolls of the guild there is a tale of a young Weaver who prided herself on stubbornness. Faced with a knot in her thread, she pulled harder and harder until her hands were raw and the strand snapped in fury. Ashamed, she carried the ruined thread outside and flung it into the open air.

            A breeze rose from the valley and caught the tangle, turning it over and over. The fibers loosened, not with force, but with patient motion, until the knot fell open of its own accord. Watching this, the Weaver understood what no master had been able to teach her: not every problem yields to pressure.

            She began to notice how the wind moved the world: how birds angled their wings, how sails shifted, how trees bent without breaking. She arranged her days the way sailors trim their sails—reading the currents, respecting the weather, using the smallest effort to move the farthest.

            This did not mean giving up on effort. It meant choosing courage over punishment, adapting instead of attacking herself every time focus faltered.

            You, too, are learning to weave with the wind instead of against it. When you build gentle structure around your focus instead of attacking yourself, you are listening to the same invisible teacher that once untied a hopeless knot.
            """,
            hintText: "Force nothing. To catch the wind, you must first raise the sail.",
            seasonalSpringLore: "The spring breeze carries seeds to new soil. Your gentle focus scatters possibility across the days ahead.",
            seasonalSummerLore: "Even in summer's heat, a steady wind brings relief. Your rhythm is the cool current that keeps you moving.",
            seasonalAutumnLore: "Autumn winds carry what must be released. Your focus clears the clutter, leaving only what matters.",
            seasonalWinterLore: "Winter winds are sharp but honest. Your discipline cuts through distraction like cold air through fog.",
            completionsRequired: 21,
            artifactImageName: nil,
            whisper: "Raise your sail; let effort move with the wind.",
            chapter: 5,
            minDaysForVisibility: 30  // Reveals after 1 month
        ),

        // MARK: - 6. The Crystal Drop
        
        ConstellationBadge(
            name: "The Crystal Drop",
            iconName: "drop.fill",
            colorHex: "A3C9D9",
            category: "Connection",
            story: """
            In the first days, say the old songs, every thread drifted alone in a dark and endless sky. They did not know they were threads; they thought themselves small, cold stars, each burning in isolation. Then came the Weaver of Waters, whose heart ached for their distance.

            She climbed above the firmament and wept. Her tears passed through the sky like comets and became Crystal Drops. Wherever a drop fell, it softened two lonely threads and drew them gently toward one another—not in knots of obligation, but in quiet, shimmering bonds.

            At first the threads resisted, afraid of tangling, afraid of needing and being needed. Yet the Crystal Drops kept falling: in shared meals, in awkward first messages, in the simple bravery of saying, “I thought of you today.”

            Over time, the drifting strands learned a new truth: that strength is not in how tightly one holds, but in how bravely one reaches. Rivers formed, nets of support shimmered into being, and the empty sky grew rich with woven constellations of companionship.

            Every message you send, every listening ear you offer, every small kindness—these are modern Crystal Drops. Through them, you are helping separate lives remember that they were always meant to be part of the same vast ocean.
            """,
            hintText: "One drop alone evaporates; many drops make an ocean.",
            seasonalSpringLore: "Spring rains nourish new growth. Each connection you tend is a seed that will bloom into something beautiful.",
            seasonalSummerLore: "In summer's abundance, we gather together. Your bonds are the shade trees that shelter weary travelers.",
            seasonalAutumnLore: "Autumn mists soften the edges between us. The connections you've made hold warmth against the coming cold.",
            seasonalWinterLore: "Winter draws us closer to the hearth. The bonds you've woven are the warmth that makes the darkness bearable.",
            completionsRequired: 21,
            artifactImageName: nil,
            whisper: "Each small kindness binds separate lives together.",
            chapter: 6,
            minDaysForVisibility: 60  // Reveals after 2 months
        ),

        // MARK: - 7. The Steady Mountain
        
        ConstellationBadge(
            name: "The Steady Mountain",
            iconName: "mountain.2.fill",
            colorHex: "8B7E74",
            category: "Tiny Anchors",
            story: """
            Long before the guild halls were built, a young apprentice climbed to sit at the foot of an ancient mountain. “Tell me how you became so great,” she demanded. The mountain, as mountains do, offered no reply. It simply stood.

            The apprentice waited through a day, then another. Snow gathered and melted on the crags. Clouds came and went. Villages in the valley rose and vanished. Still the mountain remained, changing only by grains and inches no human could see.

            Impatient, she tried to scramble up in a single day and failed, again and again, sliding down loose stone. Only when her hands were blistered did she notice that each failed attempt had left a faint track, a small ledge carved by her own persistence.

            Humbled, the apprentice returned to her loom and tried a different approach. Each day she added one small, honest thread to her work—no more, no less. Seasons turned. Empires shifted. Her tapestries slowly grew so vast and sturdy that travelers said you could sleep beneath them and dream of never falling.

            You carry a shard of that same patience. Every tiny habit you repeat is a stone laid at your own foundations. You may not see the summit yet, but the mountain is already rising beneath your feet.
            """,
            hintText: "Stone by stone, the mountain is built. Do not look at the summit.",
            seasonalSpringLore: "Even mountains were once valleys. Spring reminds you that steady rising is the oldest form of growth.",
            seasonalSummerLore: "The mountain stands unmoved by summer storms. Your anchors hold firm when the world grows loud.",
            seasonalAutumnLore: "The mountain wears autumn's colors without changing its shape. Constancy beneath the seasons is your gift.",
            seasonalWinterLore: "Snow gathers on the peak, but the mountain does not falter. Your small anchors have become unshakeable ground.",
            completionsRequired: 21,
            artifactImageName: nil,
            whisper: "Tiny anchors, laid daily, become a mountain.",
            chapter: 7,
            minDaysForVisibility: 60  // Reveals after 2 months
        ),

        // MARK: - 8. The Wandering Cloud
        
        ConstellationBadge(
            name: "The Wandering Cloud",
            iconName: "cloud.fill",
            colorHex: "E5E5E5",
            category: "Dopamine Design",
            story: """
            Not all Weavers were solemn. Among the pages of the Archive, there is mention of one called Miris, who whistled at her loom and changed her pattern as often as the sky. The elders frowned at her restless feet and scolded, “Discipline means sitting still.”

            Miris only pointed upward. “Do you see those clouds?” she asked. “They have no fixed shape, yet they carry rain to the fields and shade to the weary. They drift, but they still arrive.”

            Instead of fighting her own nature, she built her craft around it. She wove in short, playful bursts, changed tools when she grew bored, and rewarded each finished section with a small joy—a song, a walk, a cup of something warm. Her cloth was light, strong, and strangely comforting; people said it felt like lying on your back watching the sky.

            There were days when guilt pressed heavy on her shoulders, telling her that “real” Weavers suffered more. But her tapestries endured while many stern masters quietly burned out.

            You, too, are allowed to be a wandering cloud. When you design your habits so that they delight you instead of draining you, you are not being frivolous. You are learning Miris’s secret: that joy is not the opposite of discipline, but the fuel that lets it last.
            """,
            hintText: "To hold a cloud, you must open your hand, not close it.",
            seasonalSpringLore: "Spring clouds carry the promise of rain and growth. Your playful practice waters the seeds you've planted.",
            seasonalSummerLore: "Summer clouds drift lazily across endless blue. Your joy-filled habits float through the longest days with ease.",
            seasonalAutumnLore: "Autumn clouds move swiftly, changing shape. Your adaptable spirit finds delight in the dance of transformation.",
            seasonalWinterLore: "Winter clouds rest low and quiet. Even in stillness, your gentle discipline holds space for unexpected wonder.",
            completionsRequired: 21,
            artifactImageName: nil,
            whisper: "Design discipline that drifts with your joy.",
            chapter: 8,
            minDaysForVisibility: 90  // Reveals after 3 months
        ),

        // MARK: - 9. The Mended Thread
        
        ConstellationBadge(
            name: "The Mended Thread",
            iconName: "bandage.fill",
            colorHex: "E8A87C",
            category: "Resilience",
            story: """
            There is a myth among the Weavers that a perfect cloth has no knots. This is false. The strongest tapestries in the Archive are those that were torn and stitched back together.

            Once, a devoted Weaver walked away from her loom. She had risen with the Morning Star, sat with the Tranquil Moon, tended the Verdant Leaf and fed the Sacred Flame. But a season of storms came—illness, grief, exhaustion—and one day she simply did not show up. Then another. And another.

            Dust gathered on the frame. Threads sagged. She told herself the story that all was lost now, that absence had erased every prior effort. The shame of that belief kept her farther away than any distance.

            Many months later, on a small and ordinary morning, she did the bravest thing she had ever done: she walked back. Her hands shook as she picked up a single loose strand and tied a careful knot where the break had been. It was not invisible. It was not neat. But it held.

            From then on, she wove the flaw into the pattern on purpose—small bands of repair-colored thread running through her work like quiet lightning scars. Travelers who ran their fingers along these seams said they felt steadier, not weaker.

            The Novice thinks the path must be unbroken. The Master knows that the gap is part of the pattern. You stepped away. You let the threads hang loose. And then, with quiet courage, you picked them up again.

            This badge honors the repair, which is more noble than the perfection. You have learned the Weaver's greatest secret: the return is the victory.
            """,
            hintText: "To find this star, one must lose the path and have the courage to return.",
            seasonalSpringLore: "The vine that was cut grows back stronger. Your return is the new growth.",
            seasonalSummerLore: nil,
            seasonalAutumnLore: nil,
            seasonalWinterLore: "The fire went out, but you relit it. That warmth is sweeter than the first.",
            completionsRequired: 1,
            artifactImageName: nil,
            whisper: "The strongest thread is the one that was broken and mended.",
            chapter: 9,
            minDaysForVisibility: 90  // Reveals after 3 months - requires time to experience gap
        ),

        // MARK: - 10. The Silent Deep
        
        ConstellationBadge(
            name: "The Silent Deep",
            iconName: "water.waves.and.arrow.down",
            colorHex: "2C3E50",
            category: "Deep Work",
            story: """
            On the surface of the ocean, the waves are chaotic—tossed by every wind, responding to every storm. This is the mind of the world: reactive, loud, and endless. For a long time, the Weavers thought this was the only way to live—skimming from distraction to distraction, never sinking beneath the noise.

            But the Weaver of the Deep suspected otherwise. She built herself a weighted belt of rituals: a cleared table, a silenced device, a timer lit like a small lantern. Wearing these, she stepped away from the chatter of the shore and into her work as though into the sea.

            At first, every sound from above called her back. Her lungs burned with the urge to rise, to check, to escape. Yet she stayed, counting her breaths, letting the first minutes feel unbearably slow. Slowly, the roar of the surface softened to a distant murmur.

            Below the churn, she discovered a place where the water was still and heavy. This was the Silent Deep. Here, in the crushing pressure of focus, carbon turns to diamond and thoughts turn to reality. Time behaved differently there; an hour of true immersion outshone days of scattered effort.

            She returned to this depth again and again, not because it was easy, but because it built a quiet kind of courage—the bravery to be alone with one’s own mind.

            You have learned to turn away from the surface noise. You have unplugged the constant signal to find your own frequency. You are no longer floating; you are diving.
            """,
            hintText: "This star is found only by those who turn off the noise to hear the signal.",
            seasonalSpringLore: nil,
            seasonalSummerLore: "The surface is hot and loud. You have found the cool sanctuary beneath.",
            seasonalAutumnLore: nil,
            seasonalWinterLore: "In the dark of winter, the deep silence is where true vision is born.",
            completionsRequired: 10,
            artifactImageName: nil,
            whisper: "Below the waves of distraction lies the silence of power.",
            chapter: 10,
            minDaysForVisibility: 120  // Reveals after 4 months
        ),

        // MARK: - 11. The Iron Spindle
        
        ConstellationBadge(
            name: "The Iron Spindle",
            iconName: "dumbbell.fill",
            colorHex: "8B7E74",
            category: "Structure",
            story: """
            Soft threads are beautiful, but they cannot hold the weight of the world. For that, you need the Iron Spindle.

            There was once a circle of Weavers who loved inspiration but distrusted structure. They followed only their feelings—working in bursts, abandoning patterns halfway through, promising themselves that “someday” the great masterpiece would emerge. Their cloth was dazzling to look at but tore the moment any real strain was placed upon it.

            Watching this, an older Weaver quietly forged a spindle from iron. While others chased new colors, she did her repetitions: the same lifts, the same lines of numbers, the same carefully logged days. Her friends pitied her at first, thinking she had traded magic for routine.

            Years later, when the city’s bridges frayed and the storm banners ripped from the towers, it was her fabric alone that held. Her tapestries had a spine. Underneath every wild design was a simple, disciplined weave—row after row of unglamorous strength.

            The Elders tell of a time when Weavers refused structure, wanting only flow. Their tapestries collapsed. They learned that freedom requires a spine. Discipline—the heavy lifting, the cold math, the hard reps—is not a cage. It is the skeleton that holds the dream upright.

            You have engaged with the iron. You have respected the numbers, the sets, the limits. You have shown the courage to keep showing up when no one is watching. You are building a vessel strong enough to carry your wildest colors.
            """,
            hintText: "Softness needs a spine. Complete a full cycle of discipline to find this.",
            seasonalSpringLore: "Spring forges new iron from winter's rest. Your discipline emerges fresh, ready to shape the year ahead.",
            seasonalSummerLore: "Summer heat tempers the blade. Your structure holds strong even when the days grow long and will falters.",
            seasonalAutumnLore: "Autumn harvests what discipline has built. The iron frame you've forged now holds the weight of your ambitions.",
            seasonalWinterLore: "Winter tests every spine. Your iron discipline is the skeleton that keeps you upright when the world grows cold.",
            completionsRequired: 1,
            artifactImageName: nil,
            whisper: "Discipline is the iron spine that holds the dream upright.",
            chapter: 11,
            minDaysForVisibility: 150  // Reveals after 5 months
        ),

        // MARK: - 12. The Golden Solstice
        
        ConstellationBadge(
            name: "The Golden Solstice",
            iconName: "sun.haze.fill",
            colorHex: "FFD700",
            category: "Cycles",
            story: """
            The novice Weaver tries to force the bloom in winter and harvest in spring. They fight the wheel of time. The Master Weaver turns with it.

            In the early days of the guild, apprentices panicked when their energy waned. A quiet season made them fear they had “lost” their calling. They clung to endless summer as the only proof of worth.

            One Elder invited them to a hilltop and asked them to stay for a full year. They watched the grass rise and fall, the trees bud and bare, the sun climb high and sink low. Some days were made for sprinting; others were made for mending, for mulling, for sleep.

            Slowly, the apprentices realized that the garden was not failing when it rested—it was preparing. The sap pulled inward before it rose again. The soil went still before it burst with life.

            You have been here long enough to see the light change. You have woven through the energy of the uprising Spring, the fullness of Summer, and the release of Autumn. You have known the hush of Winter and found that you did not disappear in the dark.

            You understand now that you are not a machine that runs flat; you are a garden that cycles. You no longer curse your low seasons or demand that your body burn like noon every day of the year. Instead, you adjust, you listen, you turn with the wheel.

            You have stopped fighting the seasons of your own body. You rest when the sun is low; you rise when the energy is high. You have become the Golden Solstice—the living center point around which the seasons turn.
            """,
            hintText: "One cannot chase the sun; one must wait for the seasons to turn.",
            seasonalSpringLore: "Spring returns, and with it your courage to begin again. This time, you plant with wisdom.",
            seasonalSummerLore: "At your brightest, you remember: this light is a season, not a demand. You enjoy it without gripping.",
            seasonalAutumnLore: "You learn to let go on purpose—releasing leaves, projects, and identities that have run their course.",
            seasonalWinterLore: "In the quiet dark, your roots deepen. You are not failing; you are gathering strength for the next dawn.",
            completionsRequired: 3,
            artifactImageName: nil,
            whisper: "You are not a machine; you are a garden that cycles.",
            chapter: 12,
            minDaysForVisibility: 180  // Reveals after 6 months - requires experiencing all 4 seasons
        )
    ]
}

// MARK: - 3. Invisible Achievement Model

@Model
final class InvisibleAchievement {
    var id: UUID
    var name: String
    var story: String
    var iconName: String
    var colorHex: String
    var discoveredDate: Date
    var triggerType: String
    
    init(
        name: String,
        story: String,
        iconName: String,
        colorHex: String,
        triggerType: String
    ) {
        self.id = UUID()
        self.name = name
        self.story = story
        self.iconName = iconName
        self.colorHex = colorHex
        self.discoveredDate = Date()
        self.triggerType = triggerType
    }
}

private struct HiddenTrigger {
    let id: String
    let name: String
    let story: String
    let icon: String
    let color: String
    let condition: ([HabitCompletion]) -> Bool
}

// MARK: - 4. Anniversary Milestone

struct AnniversaryMilestone {
    let title: String
    let message: String
    let icon: String
    let days: Int
    
    static func milestone(for days: Int) -> AnniversaryMilestone? {
        switch days {
        case 7:
            return AnniversaryMilestone(
                title: "First Week",
                message: "Seven days of showing up. Not perfect, not grand—just present. This is how all great journeys begin.",
                icon: "star.fill",
                days: 7
            )
        case 30:
            return AnniversaryMilestone(
                title: "First Moon",
                message: "You've been weaving for one lunar cycle. The moon teaches us that growth has phases—waxing, waning, and waxing again. You're learning the rhythm.",
                icon: "moon.fill",
                days: 30
            )
        case 90:
            return AnniversaryMilestone(
                title: "First Season",
                message: "A full season has passed since you began. Ninety days of choices, each one a thread. Your tapestry is no longer just potential—it's becoming real.",
                icon: "leaf.fill",
                days: 90
            )
        case 180:
            return AnniversaryMilestone(
                title: "Two Seasons",
                message: "Half a year of practice. You've seen your habits through different weather—literal and metaphorical. What remains steady through change is true foundation.",
                icon: "sun.max.fill",
                days: 180
            )
        case 365:
            return AnniversaryMilestone(
                title: "Full Year",
                message: "One complete orbit around the sun. You've experienced every season of this practice. The person who started this journey is different from who reads this now. That difference is your tapestry.",
                icon: "sparkles",
                days: 365
            )
        case 500:
            return AnniversaryMilestone(
                title: "Beyond Seasons",
                message: "Five hundred days. You're past milestones now—this is simply who you are. A weaver. Someone who tends their life with intention. The practice has become the path.",
                icon: "figure.walk",
                days: 500
            )
        case 730:
            return AnniversaryMilestone(
                title: "Two Years",
                message: "Two full revolutions. What once took effort now happens naturally. This is mastery—not perfection, but integration. Your habits have become part of your breath.",
                icon: "infinity",
                days: 730
            )
        default:
            return nil
        }
    }
}

// MARK: - 5. Season Model

struct Season: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let colorHex: String
    let description: String
    let dayRange: ClosedRange<Int>
    
    static var spring: Season { allSeasons[0] }
    static var summer: Season { allSeasons[1] }
    static var autumn: Season { allSeasons[2] }
    static var winter: Season { allSeasons[3] }
    
    static let allSeasons: [Season] = [
        Season(
            name: "Spring",
            subtitle: "Season of Awakening",
            icon: "leaf.fill",
            colorHex: "A8D5BA",
            description: "New beginnings bloom. Everything feels possible. You're planting seeds—some will grow, others won't, and that's the nature of spring.",
            dayRange: 1...90
        ),
        Season(
            name: "Summer",
            subtitle: "Season of Growth",
            icon: "sun.max.fill",
            colorHex: "FFD18B",
            description: "Your practice flourishes under consistent attention. This is the season of expansion, where small habits reveal their compound power.",
            dayRange: 91...180
        ),
        Season(
            name: "Autumn",
            subtitle: "Season of Harvest",
            icon: "wind",
            colorHex: "D4A5A5",
            description: "You're reaping what you've sown. Some harvests are abundant, others modest. Both teach. This season asks: what was worth the tending?",
            dayRange: 181...270
        ),
        Season(
            name: "Winter",
            subtitle: "Season of Reflection",
            icon: "moon.stars.fill",
            colorHex: "B8C5D6",
            description: "Rest and integrate. Not all growth is visible. Winter teaches that dormancy is not death—it's preparation. Reflect on your year before the cycle begins again.",
            dayRange: 271...365
        )
    ]
    
    static func current(for date: Date = Date(), isNorthernHemisphere: Bool = true) -> Season {
        let month = Calendar.current.component(.month, from: date)
        
        if isNorthernHemisphere {
            switch month {
            case 3, 4, 5:   return spring   // March-May
            case 6, 7, 8:   return summer   // June-Aug
            case 9, 10, 11: return autumn   // Sept-Nov
            default:        return winter   // Dec-Feb
            }
        } else {
            // Southern Hemisphere Flip
            switch month {
            case 9, 10, 11: return spring   // Sept-Nov
            case 12, 1, 2:  return summer   // Dec-Feb
            case 3, 4, 5:   return autumn   // March-May
            default:        return winter   // June-Aug
            }
        }
    }
}

// MARK: - 6. Weaver Level System

struct WeaverLevel: Identifiable, Hashable {
    let id = UUID()
    let level: Int
    let title: String
    let minCompletions: Int
    let maxCompletions: Int?
    let description: String
    
    var next: Int? { maxCompletions }
    
    static let levels: [WeaverLevel] = [
        WeaverLevel(
            level: 1,
            title: "Apprentice Weaver",
            minCompletions: 0,
            maxCompletions: 50,
            description: "Every master begins here. You're learning the basic motions—thread over thread, habit over habit."
        ),
        WeaverLevel(
            level: 2,
            title: "Mindful Weaver",
            minCompletions: 50,
            maxCompletions: 150,
            description: "You're no longer just going through motions. There's awareness now—you feel the texture of each practice."
        ),
        WeaverLevel(
            level: 3,
            title: "Devoted Weaver",
            minCompletions: 150,
            maxCompletions: 300,
            description: "Devotion means returning even when inspiration fades. You've proven this truth through action."
        ),
        WeaverLevel(
            level: 4,
            title: "Master Weaver",
            minCompletions: 300,
            maxCompletions: 500,
            description: "Mastery is not perfection—it's the ability to begin again, even after unraveling. You embody this."
        ),
        WeaverLevel(
            level: 5,
            title: "Luminous Weaver",
            minCompletions: 500,
            maxCompletions: 1000,
            description: "Your practice radiates now. Others sense it without knowing why. This is what consistent devotion becomes—light."
        ),
        WeaverLevel(
            level: 6,
            title: "Transcendent Weaver",
            minCompletions: 1000,
            maxCompletions: nil,
            description: "You've moved beyond counting threads. The tapestry and the weaver are one. This is not an ending—it's a homecoming."
        )
    ]
    
    // This correctly finds the highest level where the user meets the minimum requirement.
    static func level(for completions: Int) -> WeaverLevel {
            levels.last { $0.minCompletions <= completions } ?? levels[0]
    }
    
    func progress(totalCompletions: Int) -> Double {
            guard let upperLimit = maxCompletions else { return 1.0 }
            
            let range = Double(upperLimit - minCompletions)
            let current = Double(totalCompletions - minCompletions)
            
            return min(max(current / range, 0.0), 1.0)
    }
}

// MARK: - 7. Weaver Journey Manager

@MainActor
final class WeaverJourneyManager: ObservableObject {
    static let shared = WeaverJourneyManager()
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    @AppStorage("weaverJourneyStartDate") private var journeyStartDateString: String = ""
    
    @Published private(set) var currentSeason: Season = Season.allSeasons[0]
    @Published private(set) var currentLevel: WeaverLevel = WeaverLevel.levels[0]
    @Published private(set) var daysSinceStart: Int = 0
    
    private var journeyStartDate: Date? {
        get {
            guard !journeyStartDateString.isEmpty else { return nil }
            return Self.dateFormatter.date(from: journeyStartDateString)
        }
        set {
            if let date = newValue {
                journeyStartDateString = Self.dateFormatter.string(from: date)
            } else {
                journeyStartDateString = ""
            }
        }
    }
    
    private init() {
        Task { @MainActor in
            refreshJourney()
        }
    }
    
    func initialize() {
        refreshJourney()
    }
    
    func startJourney() {
        if journeyStartDate == nil {
            journeyStartDate = Date()
            refreshJourney()
            
            ReverieHaptics.successFeedback()
        }
    }
    
    func refreshJourney() {
        guard let startDate = journeyStartDate else {
            daysSinceStart = 0
            currentSeason = Season.current(for: Date())
            currentLevel = WeaverLevel.levels[0]
            return
        }
        
        // Use calendar to get accurate day difference (Midnight to Midnight)
        let calendar = Calendar.current
        let startOfJourney = calendar.startOfDay(for: startDate)
        let startOfToday = calendar.startOfDay(for: Date())
        
        // Calculate days passed
        let components = calendar.dateComponents([.day], from: startOfJourney, to: startOfToday)
        let days = components.day ?? 0
        
        // Logic: Day 0 (Today) counts as Day 1 of the journey
        daysSinceStart = max(1, days + 1)
        
        // Update Season based on REAL WORLD date
        currentSeason = Season.current(for: Date())
    }
    
    func updateLevel(totalCompletions: Int) {
        let newLevel = WeaverLevel.level(for: totalCompletions)
        if newLevel.level != currentLevel.level {
            let didLevelUp = newLevel.level > currentLevel.level
            currentLevel = newLevel

            if didLevelUp {
                // Play level-up sound
                AchievementAudioManager.shared.playLevelUp()

                // Post notification for UI celebration
                NotificationCenter.default.post(
                    name: NSNotification.Name("WeaverLevelUp"),
                    object: newLevel
                )

                ReverieHaptics.successFeedback()
            }
        }
    }
    
    func checkAnniversary() -> AnniversaryMilestone? {
        AnniversaryMilestone.milestone(for: daysSinceStart)
    }
}

// MARK: - 8. Invisible Achievement Manager

@MainActor
final class InvisibleAchievementManager: ObservableObject {
    private let modelContext: ModelContext
    private var checkedCache: Set<String> = []
    
    private let triggers: [HiddenTrigger] = [
        HiddenTrigger(
            id: "moonlight_weaver",
            name: "Moonlight Weaver",
            story: "You completed 10 habits after 9pm, when most of the world sleeps. There's magic in the quiet hours—you've discovered it. Night weavers know something day weavers don't: darkness makes the threads glow brighter.",
            icon: "moon.stars.fill",
            color: "9B7EBD",
            condition: { completions in
                let calendar = Calendar.current
                let nightCompletions = completions.filter { completion in
                    let hour = calendar.component(.hour, from: completion.completedAt)
                    return hour >= 21 || hour < 6
                }
                return nightCompletions.count >= 10
            }
        ),
        HiddenTrigger(
            id: "dawn_composer",
            name: "Dawn Composer",
            story: "Five consecutive mornings, you greeted the day intentionally. The sunrise witnessed your commitment. Morning people aren't born—they're made through quiet, repeated choices. You've composed a new beginning.",
            icon: "sunrise.fill",
            color: "FFD18B",
            condition: { completions in
                InvisibleAchievementManager.hasFiveConsecutiveMorningDays(completions: completions)
            }
        ),
        HiddenTrigger(
            id: "weekend_warrior",
            name: "Weekend Warrior",
            story: "Eight weekend habits completed when others rest. You've learned that rest and practice can coexist—weekends aren't for abandoning intention, but for weaving it differently. Balance found.",
            icon: "figure.run",
            color: "A8B5A0",
            condition: { completions in
                let calendar = Calendar.current
                let weekendCompletions = completions.filter { completion in
                    let weekday = calendar.component(.weekday, from: completion.completedAt)
                    return weekday == 1 || weekday == 7
                }
                return weekendCompletions.count >= 8
            }
        ),
        HiddenTrigger(
            id: "consistent_companion",
            name: "Consistent Companion",
            story: "One habit, thirty times. This is devotion made visible. While others chase novelty, you've discovered the depth available in repetition. Mastery lives here.",
            icon: "heart.fill",
            color: "D4A5A5",
            condition: { completions in
                guard !completions.isEmpty else { return false }
                let habitFrequency = Dictionary(grouping: completions, by: { $0.habitId })
                return habitFrequency.values.contains { $0.count >= 30 }
            }
        ),
        HiddenTrigger(
            id: "quiet_revolution",
            name: "Quiet Revolution",
            story: "One hundred completions. No one threw you a parade. You didn't need one. This is the quiet revolution—changing yourself changes the world. Thread by thread, you're rewriting your story.",
            icon: "leaf.fill",
            color: "A8B5A0",
            condition: { completions in
                completions.count >= 100
            }
        ),
        HiddenTrigger(
            id: "seasonal_sage",
            name: "Seasonal Sage",
            story: "You've woven through all four seasons. Spring's enthusiasm, summer's consistency, autumn's harvest, winter's rest—you've known them all. This is wisdom: understanding that practice adapts to life's cycles.",
            icon: "snowflake",
            color: "B8C5D6",
            condition: { completions in
                    InvisibleAchievementManager.hasCompletionsInAllSeasons(completions: completions)
            }
        ),
        HiddenTrigger(
            id: "gentle_rebel",
            name: "Gentle Rebel",
            story: "After a 3-day pause, you returned with just one habit. Not grand, but courageous. This is resilience—not never falling, but always rising. You've proven that setbacks are not endings, just pauses in the rhythm.",
            icon: "sparkles",
            color: "FFD18B",
            condition: { completions in
                InvisibleAchievementManager.hasThreeDayGapAndReturn(completions: completions)
            }
        ),

        // MARK: - New Invisible Achievements (v2.0)

        HiddenTrigger(
            id: "rhythm_keeper",
            name: "Rhythm Keeper",
            story: "For seven days straight, you completed the same habit within the same hour. The universe notices when you sync with its clock. You've found your rhythm—a personal beat that plays beneath the noise of ordinary time.",
            icon: "metronome.fill",
            color: "9BB5CE",
            condition: { completions in
                InvisibleAchievementManager.hasConsistentTimePattern(completions: completions)
            }
        ),
        HiddenTrigger(
            id: "balance_seeker",
            name: "Balance Seeker",
            story: "In a single week, your morning and evening completions balanced perfectly. Not too much dawn, not too much dusk—you've discovered the equilibrium that eludes most weavers. This is the art of the middle path.",
            icon: "scale.3d",
            color: "B8A9C9",
            condition: { completions in
                InvisibleAchievementManager.hasMorningEveningBalance(completions: completions)
            }
        ),
        HiddenTrigger(
            id: "first_light",
            name: "The First Light",
            story: "You completed a habit before 6am—while the world still slept. There's a magic in those pre-dawn hours that only early risers know. The silence holds secrets, and you've learned to listen.",
            icon: "sun.horizon.fill",
            color: "FFB74D",
            condition: { completions in
                let calendar = Calendar.current
                return completions.contains { completion in
                    let hour = calendar.component(.hour, from: completion.completedAt)
                    return hour < 6
                }
            }
        ),
        HiddenTrigger(
            id: "last_ember",
            name: "The Last Ember",
            story: "When the day was almost done, you found one more thread to weave. Past 11pm, when most have surrendered to sleep, you chose to honor your practice. The last ember burns brightest.",
            icon: "moon.haze.fill",
            color: "5C4B8A",
            condition: { completions in
                let calendar = Calendar.current
                return completions.contains { completion in
                    let hour = calendar.component(.hour, from: completion.completedAt)
                    return hour >= 23
                }
            }
        ),
        HiddenTrigger(
            id: "fibonacci_weaver",
            name: "The Fibonacci Weaver",
            story: "Your completions followed nature's hidden sequence: 1, 1, 2, 3, 5... The spiral of growth is woven into everything from seashells to galaxies. Without knowing, you've traced this ancient pattern with your habits.",
            icon: "hurricane",
            color: "A8D5BA",
            condition: { completions in
                InvisibleAchievementManager.hasFibonacciPattern(completions: completions)
            }
        ),
        HiddenTrigger(
            id: "triple_thread",
            name: "The Triple Thread",
            story: "Three habits, completed within a single hour. You've discovered the power of stacking—weaving multiple threads at once. Efficiency becomes art when practiced with intention.",
            icon: "square.stack.3d.up.fill",
            color: "E8A87C",
            condition: { completions in
                InvisibleAchievementManager.hasTripleStack(completions: completions)
            }
        ),
        HiddenTrigger(
            id: "century_weaver",
            name: "Century Weaver",
            story: "Two hundred threads woven into your tapestry. You've passed a milestone most never reach. This isn't about perfection—it's about persistence. Each thread is a choice to show up, and you've made that choice two hundred times.",
            icon: "star.circle.fill",
            color: "D4AF37",
            condition: { completions in
                completions.count >= 200
            }
        )
    ]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func checkForNewAchievements(habits: [Habit], completions: [HabitCompletion]) {
        guard !completions.isEmpty else { return }
        
        // 1. Fetch ALL existing IDs once to avoid N+1 queries
        let descriptor = FetchDescriptor<InvisibleAchievement>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let existingTypes = Set(existing.map { $0.triggerType })
        
        // 2. Run Rules
        for trigger in triggers {
            // Check cache OR database
            if !checkedCache.contains(trigger.id) && !existingTypes.contains(trigger.id) {
                if trigger.condition(completions) {
                    createAchievement(trigger: trigger)
                    checkedCache.insert(trigger.id)
                }
            }
        }
        
    }

    // MARK: - Static Helpers

    static func hasThreeDayGapAndReturn(completions: [HabitCompletion]) -> Bool {
        let sortedCompletions = completions.sorted { $0.completedAt < $1.completedAt }
        guard sortedCompletions.count > 1 else { return false }

        for i in 1..<sortedCompletions.count {
            let previous = sortedCompletions[i - 1].completedAt
            let current = sortedCompletions[i].completedAt
            let daysBetween = Calendar.current.dateComponents([.day], from: previous, to: current).day ?? 0

            if daysBetween >= 3 {
                return true
            }
        }
        return false
    }
    
    private static func hasFiveConsecutiveMorningDays(completions: [HabitCompletion]) -> Bool {
        guard completions.count > 1 else { return false }
        let calendar = Calendar.current
        
        // Filter for morning hours (5 AM - 9 AM)
        let morningCompletions = completions.filter { completion in
            let hour = calendar.component(.hour, from: completion.completedAt)
            return hour >= 5 && hour < 9
        }
        guard morningCompletions.count > 1 else { return false }
        
        // Sort by date
        let sortedMornings = morningCompletions.sorted { $0.completedAt < $1.completedAt }
        
        var consecutiveDays = 1
        var lastDate: Date = sortedMornings[0].completedAt
        
        for i in 1..<sortedMornings.count {
            let currentComp = sortedMornings[i]
            
            let day1 = calendar.startOfDay(for: lastDate)
            let day2 = calendar.startOfDay(for: currentComp.completedAt)
            
            let daysBetween = calendar.dateComponents([.day], from: day1, to: day2).day ?? 0
            
            if daysBetween == 1 {
                consecutiveDays += 1
                lastDate = currentComp.completedAt
            } else if daysBetween == 0 {
                continue
            } else {
                consecutiveDays = 1
                lastDate = currentComp.completedAt
            }
            
            if consecutiveDays >= 5 {
                return true
            }
        }
        return false
    }
    
    private static func hasCompletionsInAllSeasons(completions: [HabitCompletion]) -> Bool {
        guard !completions.isEmpty else { return false }
        let calendar = Calendar.current

        let seasons = Set(completions.map { completion -> String in
            let month = calendar.component(.month, from: completion.completedAt)
            switch month {
            case 3...5:  return "spring"
            case 6...8:  return "summer"
            case 9...11: return "autumn"
            default:     return "winter"
            }
        })

        return seasons.count >= 4
    }

    // MARK: - Pattern Detection Helpers

    static func hasConsistentTimePattern(completions: [HabitCompletion]) -> Bool {
        let calendar = Calendar.current
        let habitGroups = Dictionary(grouping: completions, by: { $0.habitId })

        for (_, habitCompletions) in habitGroups {
            guard habitCompletions.count >= 7 else { continue }

            // Get hour and minute for each completion
            let timeSlots = habitCompletions.map { completion -> (date: Date, hour: Int, minute: Int) in
                let hour = calendar.component(.hour, from: completion.completedAt)
                let minute = calendar.component(.minute, from: completion.completedAt)
                return (completion.completedAt, hour, minute)
            }.sorted { $0.date < $1.date }

            // Check for 7 consecutive days with similar times
            var consecutiveCount = 1
            var lastDate = timeSlots[0].date
            let referenceHour = timeSlots[0].hour
            let referenceMinute = timeSlots[0].minute

            for i in 1..<timeSlots.count {
                let slot = timeSlots[i]
                let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: slot.date)).day ?? 0

                // Check if consecutive day
                guard daysDiff == 1 else {
                    consecutiveCount = 1
                    lastDate = slot.date
                    continue
                }

                // Check if within 30 minutes of reference time
                let totalMinutesRef = referenceHour * 60 + referenceMinute
                let totalMinutesCurrent = slot.hour * 60 + slot.minute
                let diff = abs(totalMinutesRef - totalMinutesCurrent)

                if diff <= 30 || diff >= (24 * 60 - 30) { // Handle midnight wrap
                    consecutiveCount += 1
                    lastDate = slot.date

                    if consecutiveCount >= 7 {
                        return true
                    }
                } else {
                    consecutiveCount = 1
                    lastDate = slot.date
                }
            }
        }
        return false
    }

    static func hasMorningEveningBalance(completions: [HabitCompletion]) -> Bool {
        let calendar = Calendar.current

        // Group by week
        let weekGroups = Dictionary(grouping: completions) { completion in
            calendar.dateInterval(of: .weekOfYear, for: completion.completedAt)?.start
        }

        for (_, weekCompletions) in weekGroups {
            guard weekCompletions.count >= 4 else { continue }

            let morningCount = weekCompletions.filter { completion in
                let hour = calendar.component(.hour, from: completion.completedAt)
                return hour >= 6 && hour < 12
            }.count

            let eveningCount = weekCompletions.filter { completion in
                let hour = calendar.component(.hour, from: completion.completedAt)
                return hour >= 18 && hour < 24
            }.count

            // Balance: both >= 2 and difference <= 1
            if morningCount >= 2 && eveningCount >= 2 && abs(morningCount - eveningCount) <= 1 {
                return true
            }
        }
        return false
    }

    static func hasTripleStack(completions: [HabitCompletion]) -> Bool {
        let calendar = Calendar.current

        // Group by hour
        let hourGroups = Dictionary(grouping: completions) { completion -> DateComponents in
            calendar.dateComponents([.year, .month, .day, .hour], from: completion.completedAt)
        }

        return hourGroups.values.contains { $0.count >= 3 }
    }

    static func hasFibonacciPattern(completions: [HabitCompletion]) -> Bool {
        let calendar = Calendar.current

        // Group by day and count
        let dailyCounts = Dictionary(grouping: completions) { completion in
            calendar.startOfDay(for: completion.completedAt)
        }.mapValues { $0.count }

        let sortedDays = dailyCounts.keys.sorted()
        guard sortedDays.count >= 5 else { return false }

        // Look for 1,1,2,3,5 pattern in any 5 consecutive days
        for i in 0..<(sortedDays.count - 4) {
            let day0 = sortedDays[i]
            let day1 = sortedDays[i + 1]
            let day2 = sortedDays[i + 2]
            let day3 = sortedDays[i + 3]
            let day4 = sortedDays[i + 4]

            // Check if days are consecutive
            let diff1 = calendar.dateComponents([.day], from: day0, to: day1).day ?? 0
            let diff2 = calendar.dateComponents([.day], from: day1, to: day2).day ?? 0
            let diff3 = calendar.dateComponents([.day], from: day2, to: day3).day ?? 0
            let diff4 = calendar.dateComponents([.day], from: day3, to: day4).day ?? 0

            guard diff1 == 1 && diff2 == 1 && diff3 == 1 && diff4 == 1 else { continue }

            let counts = [
                dailyCounts[day0] ?? 0,
                dailyCounts[day1] ?? 0,
                dailyCounts[day2] ?? 0,
                dailyCounts[day3] ?? 0,
                dailyCounts[day4] ?? 0
            ]

            if counts == [1, 1, 2, 3, 5] {
                return true
            }
        }
        return false
    }

    // MARK: - Helpers
    
    private func createAchievement(trigger: HiddenTrigger) {
        createAchievement(
            name: trigger.name,
            story: trigger.story,
            iconName: trigger.icon,
            colorHex: trigger.color,
            triggerType: trigger.id
        )
    }
    
    private func createAchievement(
        name: String,
        story: String,
        iconName: String,
        colorHex: String,
        triggerType: String
    ) {
        let achievement = InvisibleAchievement(
            name: name,
            story: story,
            iconName: iconName,
            colorHex: colorHex,
            triggerType: triggerType
        )

        modelContext.insert(achievement)
        try? modelContext.save()

        NotificationCenter.default.post(
            name: NSNotification.Name("InvisibleAchievementDiscovered"),
            object: achievement
        )

        // Play hidden reveal sound
        Task { @MainActor in
            AchievementAudioManager.shared.playHiddenReveal()
        }

        ReverieHaptics.successFeedback()
    }
}

// MARK: - Constellation Progress Context

fileprivate struct ConstellationProgressContext {
    let categoryDays: [String: Set<Date>]
    let deepWorkSessions: Int
    let allActiveDays: Set<Date>
    let seasonsTouched: Set<String>
    
    init(habits: [Habit], completions: [HabitCompletion]) {
        var categoryDays: [String: Set<Date>] = [:]
        var deepWorkCount = 0
        var allDays: Set<Date> = []
        var seasons: Set<String> = []
        
        let calendar = Calendar.current
        let habitById = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        
        for completion in completions {
            let day = calendar.startOfDay(for: completion.completedAt)
            allDays.insert(day)
            
            // 1. Resolve Data Points
            let habit = habitById[completion.habitId]
            
            // Fallback chain: Snapshot -> Live Habit -> Default
            let habitName = completion.snapshotName ?? habit?.name ?? ""
            let programTag = completion.snapshotProgramTag ?? habit?.programTag ?? ""
            let rawCategory = (completion.snapshotCategory ?? habit?.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 2. Map to Badge Categories (The "Brain" that finds your new challenges)
            let effectiveCategories = Self.mapToBadgeCategories(
                rawCategory: rawCategory,
                programTag: programTag,
                habitName: habitName
            )
            
            for cat in effectiveCategories {
                categoryDays[cat, default: []].insert(day)
            }
            
            // 3. "The Silent Deep" Detection - Enhanced for inclusive detection
            // Detects deep focus work from multiple sources:
            // - Explicit Deep Work habits
            // - Focus-related program completions
            // - Long Pomodoro sessions (45+ minutes)
            // - Focus Mastery Theme Week
            let isDeepWorkSession = habitName.contains("Deep Work") ||
                                   habitName.lowercased().contains("focus block") ||
                                   habitName.lowercased().contains("flow state") ||
                                   programTag.contains("FocusSprint") ||
                                   programTag.contains("DopamineDetox") ||
                                   programTag.contains("FocusMastery") ||
                                   programTag.contains("ExecutiveEnergy") ||
                                   rawCategory == "Deep Work" ||
                                   rawCategory == "Focus Flow" ||
                                   // Pomodoro sessions that indicate deep work (category or name hint)
                                   (habitName.lowercased().contains("pomodoro") && habitName.contains("45")) ||
                                   (habitName.lowercased().contains("pomodoro") && habitName.contains("90"))

            if isDeepWorkSession {
                deepWorkCount += 1
            }
            
            // 4. Season Logic
            let month = calendar.component(.month, from: completion.completedAt)
            let seasonName: String
            switch month {
            case 3...5:  seasonName = "Spring"
            case 6...8:  seasonName = "Summer"
            case 9...11: seasonName = "Autumn"
            default:     seasonName = "Winter"
            }
            seasons.insert(seasonName)
        }
        
        self.categoryDays = categoryDays
        self.deepWorkSessions = deepWorkCount
        self.allActiveDays = allDays
        self.seasonsTouched = seasons
    }
    
    // MARK: - Category Mapping Configuration

    private static let programTagToCategoryMap: [String: String] = [
        // Health Foundations
        "FeiStrength": "Health Foundations",
        "MovementMagic": "Health Foundations",
        "HairGlowReset": "Health Foundations",
        "VitalityArc": "Health Foundations",
        "EnergyRecharge": "Health Foundations",
        "NourishReset": "Health Foundations",
        "BodyTrustReset": "Health Foundations",
        "VA-": "Health Foundations",

        // Mindful Living
        "GlowingJourney": "Mindful Living",
        "ReflectionReset": "Mindful Living",
        "NervousSystemReset": "Mindful Living",
        "BreathCalm": "Mindful Living",
        "EveningSanctuary": "Mindful Living",
        "GratitudeGlow": "Mindful Living",
        "GentleRhythm": "Mindful Living",
        "BurnoutRecovery": "Mindful Living",
        "SlowDown": "Mindful Living",
        "InnerCriticReset": "Mindful Living",
        "ValuesCompass": "Mindful Living",
        "SelfMastery": "Mindful Living",

        // Creative Practice
        "CreativeFlow": "Creative Practice",
        "LearningSprint": "Creative Practice",
        "CreativeBreakthrough": "Creative Practice",

        // Connection
        "ConnectionWeek": "Connection",
        "ConnectionClarity": "Connection",
        "RelationshipRenaissance": "Connection",
        "BoundaryBootcamp": "Connection",
        "SocialConfidence": "Connection",

        // Focus Flow
        "FocusSprint": "Focus Flow",
        "DopamineDetox": "Focus Flow",
        "DigitalDetox": "Focus Flow",
        "FocusMastery": "Focus Flow",
        "ExecutiveEnergy": "Focus Flow",
        "MorningArchitect": "Focus Flow",

        // Dopamine Design
        "JoyScavenger": "Dopamine Design",
        "NatureThread": "Dopamine Design",

        // Morning Rituals
        "CircadianReset": "Morning Rituals",

        // Structure
        "FinancialZen": "Structure"
    ]

    private static let habitNameKeywordMap: [String: [String]] = [
        "Morning Rituals": ["morning", "wake", "sunrise", "dawn", "breakfast", "am routine"],
        "Mindful Living": ["meditat", "breath", "calm", "mindful", "journal", "reflect", "gratitude", "yoga", "stretch"],
        "Health Foundations": ["workout", "exercise", "gym", "walk", "run", "sleep", "water", "vitamin", "health", "fitness", "strength"],
        "Creative Practice": ["write", "draw", "paint", "music", "create", "art", "design", "craft", "learn", "read", "study", "practice"],
        "Focus Flow": ["focus", "deep work", "pomodoro", "concentrate", "productive", "work session"],
        "Connection": ["call", "text", "friend", "family", "social", "connect", "reach out", "check in"],
        "Dopamine Design": ["fun", "play", "hobby", "reward", "break", "relax", "enjoy", "leisure", "game"]
    ]

    private static func mapToBadgeCategories(rawCategory: String, programTag: String, habitName: String) -> [String] {
        var keys: [String] = []

        // A. Direct Match (from Habit Category)
        if !rawCategory.isEmpty {
            keys.append(rawCategory)
        }

        // B. Program Tag Mapping (data-driven)
        for (tagFragment, category) in programTagToCategoryMap {
            if programTag.contains(tagFragment) && !keys.contains(category) {
                keys.append(category)
            }
        }

        // C. Morning Rituals (special case: checks habit name and category)
        if (habitName.contains("Morning") || rawCategory.contains("Morning")) && !keys.contains("Morning Rituals") {
            keys.append("Morning Rituals")
        }

        // D. Keyword Detection in Habit Name (NEW - catches custom habits)
        let lowercaseName = habitName.lowercased()
        for (category, keywords) in habitNameKeywordMap {
            if !keys.contains(category) {
                for keyword in keywords {
                    if lowercaseName.contains(keyword) {
                        keys.append(category)
                        break  // Found match for this category, move to next
                    }
                }
            }
        }

        return keys
    }
}

// MARK: - 5. Constellation Manager

final class ConstellationManager: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func initializeConstellations() {
        let descriptor = FetchDescriptor<ConstellationBadge>()
        let existingBadges = (try? modelContext.fetch(descriptor)) ?? []
        let existingNames = Set(existingBadges.map { $0.name })
        
        for c in ConstellationData.allConstellations where !existingNames.contains(c.name) {
            let newBadge = ConstellationBadge(
                name: c.name,
                iconName: c.iconName,
                colorHex: c.colorHex,
                category: c.category,
                story: c.story,
                hintText: c.hintText,
                seasonalSpringLore: c.seasonalSpringLore,
                seasonalSummerLore: c.seasonalSummerLore,
                seasonalAutumnLore: c.seasonalAutumnLore,
                seasonalWinterLore: c.seasonalWinterLore,
                completionsRequired: c.completionsRequired,
                artifactImageName: c.artifactImageName,
                whisper: c.whisper,
                chapter: c.chapter
            )
            modelContext.insert(newBadge)
        }
        try? modelContext.save()
    }


        // MARK: - Notification Helper
    
        private func triggerUnlockNotification(for badge: ConstellationBadge) {
            let content = UNMutableNotificationContent()
            content.title = "✨ A New Thread Revealed"
            content.body = "The stars have aligned. You have unlocked '\(badge.name)'."
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }

        @MainActor
        func checkUnlocks(habits: [Habit], completions: [HabitCompletion]) {
            guard !completions.isEmpty else { return }

            let descriptor = FetchDescriptor<ConstellationBadge>()
            guard let allConstellations = try? modelContext.fetch(descriptor) else { return }

            // Build Context
            let context = ConstellationProgressContext(habits: habits, completions: completions)
            
            var didChange = false

            for constellation in allConstellations where !constellation.isUnlocked {
                guard let key = constellation.journeyKey else { continue }
                
                if shouldUnlock(key: key, constellation: constellation, context: context, completions: completions) {
                    // 1. Unlock State
                    constellation.isUnlocked = true
                    constellation.unlockedDate = Date()

                    // 2. Set "New/Glowing" State (Requires Step 1 Model Update)
                    constellation.hasBeenViewed = false

                    didChange = true

                    // 3. Trigger The "Magical Chime" Notification
                    triggerUnlockNotification(for: constellation)

                    // 4. Play constellation unlock sound
                    AchievementAudioManager.shared.playConstellationUnlock()

                    NotificationCenter.default.post(
                        name: NSNotification.Name("ConstellationUnlocked"),
                        object: constellation
                    )
                    ReverieHaptics.successFeedback()
                }
            }

            if didChange { try? modelContext.save() }
        }
    
    // MARK: - Rules Engine

    private func shouldUnlock(
        key: ConstellationJourneyKey,
        constellation: ConstellationBadge,
        context: ConstellationProgressContext,
        completions: [HabitCompletion]
    ) -> Bool {

        // 1. Check revelation window - badge must be visible before it can be unlocked
        if !isRevealedYet(constellation: constellation) {
            return false
        }

        // 2. Check unlock criteria based on badge type
        switch key {
        case .firstLoom:
            return false // Already unlocked

        case .morningStar, .tranquilMoon, .verdantLeaf, .sacredFlame,
             .gentleWind, .crystalDrop, .wanderingCloud:
            // Use the Category map from Context
            let validDays = context.categoryDays[constellation.category] ?? []
            return validDays.count >= constellation.completionsRequired

        case .steadyMountain:
            return context.allActiveDays.count >= constellation.completionsRequired

        case .mendedThread:
            return hasGapAndReturn(completions: completions, minGapDays: 5, minReturnDays: 2)

        case .silentDeep:
            return context.deepWorkSessions >= constellation.completionsRequired

        case .ironSpindle:
            // Broadened: Any structured multi-week program (3+ weeks) demonstrates discipline
            return hasCompletedStructuredProgram(completions: completions)

        case .goldenSolstice:
            return context.seasonsTouched.count >= constellation.completionsRequired
        }
    }

    // MARK: - Revelation Window Check

    private func isRevealedYet(constellation: ConstellationBadge) -> Bool {
        let journeyStartDate = UserDefaults.standard.object(forKey: "journeyStartDate") as? Date ?? Date()
        let daysSinceStart = Calendar.current.dateComponents([.day], from: journeyStartDate, to: Date()).day ?? 0
        return daysSinceStart >= constellation.minDaysForVisibility
    }

    // MARK: - Complex Rules

    private func hasCompletedStructuredProgram(completions: [HabitCompletion]) -> Bool {
        let userTags = completions.compactMap { $0.snapshotProgramTag }

        let multiWeekProgramPrefixes = [
            "FeiStrength",
            "GlowingJourney",
            "ExecutiveEnergy",
            "RelationshipRenaissance",
            "CreativeBreakthrough",
            "SelfMastery"
        ]

        // Count unique weeks touched per program
        for prefix in multiWeekProgramPrefixes {
            var uniqueWeeks: Set<String> = []
            for tag in userTags {
                if tag.contains(prefix) {
                    // Extract the week identifier (e.g., "W1", "W2", etc.)
                    if let weekRange = tag.range(of: "W\\d+", options: .regularExpression) {
                        uniqueWeeks.insert(String(tag[weekRange]))
                    }
                }
            }
            // 3+ weeks of any program demonstrates Iron Spindle discipline
            if uniqueWeeks.count >= 3 {
                return true
            }
        }

        return false
    }

    private func hasGapAndReturn(completions: [HabitCompletion], minGapDays: Int, minReturnDays: Int) -> Bool {
        guard completions.count > 1 else { return false }
        let calendar = Calendar.current
        let sorted = completions.map { calendar.startOfDay(for: $0.completedAt) }.sorted()
        let uniqueDays = Array(Set(sorted)).sorted()

        for i in 1..<uniqueDays.count {
            let prev = uniqueDays[i-1]
            let curr = uniqueDays[i]
            let gap = calendar.dateComponents([.day], from: prev, to: curr).day ?? 0
            
            if gap >= minGapDays {
                // Check return
                let subsequentDays = uniqueDays.filter { $0 > curr }
                if subsequentDays.count >= (minReturnDays - 1) {
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - 6. Semantic Keys

enum ConstellationJourneyKey {
    case firstLoom, morningStar, tranquilMoon, verdantLeaf, sacredFlame, gentleWind, crystalDrop, steadyMountain, wanderingCloud, mendedThread, silentDeep, ironSpindle, goldenSolstice
}

extension ConstellationBadge {
    var journeyKey: ConstellationJourneyKey? {
        switch name {
        case "The First Loom": return .firstLoom
        case "The Morning Star": return .morningStar
        case "The Tranquil Moon": return .tranquilMoon
        case "The Verdant Leaf": return .verdantLeaf
        case "The Sacred Flame": return .sacredFlame
        case "The Gentle Wind": return .gentleWind
        case "The Crystal Drop": return .crystalDrop
        case "The Steady Mountain": return .steadyMountain
        case "The Wandering Cloud": return .wanderingCloud
        case "The Mended Thread": return .mendedThread
        case "The Silent Deep": return .silentDeep
        case "The Iron Spindle": return .ironSpindle
        case "The Golden Solstice": return .goldenSolstice
        default: return nil
        }
    }
    
    func lore(for season: Season) -> String {
        switch season.name {
        case "Spring": return seasonalSpringLore ?? story
        case "Summer": return seasonalSummerLore ?? story
        case "Autumn": return seasonalAutumnLore ?? story
        case "Winter": return seasonalWinterLore ?? story
        default: return story
        }
    }

    var isRevealed: Bool {
        let journeyStartDate = UserDefaults.standard.object(forKey: "journeyStartDate") as? Date ?? Date()
        let daysSinceStart = Calendar.current.dateComponents([.day], from: journeyStartDate, to: Date()).day ?? 0
        return daysSinceStart >= minDaysForVisibility
    }
}

// MARK: - 10. The Whisper System (Lore Provider)

struct WeaverLoreManager {
    static func getDailyWhisper(unlockedConstellations: [ConstellationBadge]) -> String {
        let defaultWhisper = "Every thread counts."
        
        guard !unlockedConstellations.isEmpty else { return defaultWhisper }
        guard Double.random(in: 0...1) < 0.3 else { return defaultWhisper }
        
        if let randomBadge = unlockedConstellations.randomElement() {
            let trimmed = randomBadge.whisper.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            } else {
                return extractWhisper(from: randomBadge.story)
            }
        }
        
        return defaultWhisper
    }
    
    private static func extractWhisper(from story: String) -> String {
        let sentences = story
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let first = sentences.first {
            return first.hasSuffix(".") ? first : first + "."
        }
        return "Weave your story."
    }
}

// MARK: - Constellation Convenience Extension

extension ConstellationBadge {

    var chapterLabel: String {
        switch chapter {
        case ..<0:
            return ""
        case 0:
            return "Prologue"
        default:
            return "Chapter \(chapter.romanNumeral)"
        }
    }

    func lore(for season: Season?) -> String {
        guard let season else { return story }

        switch season.name {
        case "Spring":
            return seasonalSpringLore ?? story
        case "Summer":
            return seasonalSummerLore ?? story
        case "Autumn":
            return seasonalAutumnLore ?? story
        case "Winter":
            return seasonalWinterLore ?? story
        default:
            return story
        }
    }

    var displayWhisper: String {
        if !whisper.isEmpty {
            return whisper
        }

        let trimmed = story.trimmingCharacters(in: .whitespacesAndNewlines)
        if let dotIndex = trimmed.firstIndex(of: ".") {
            let firstSentence = trimmed[..<dotIndex]
            return String(firstSentence)
                .trimmingCharacters(in: .whitespacesAndNewlines) + "."
        }
        return trimmed
    }
}


