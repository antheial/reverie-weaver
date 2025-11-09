import SwiftUI

struct Mood: Identifiable {
    let id: String
    let name: String
    let color: Color
    let prompts: [String]
    
    static let allMoods: [Mood] = [
        Mood(id: "joyful", name: "Joyful", color: Color(hex: "FFDA66"),
             prompts: ["What made you feel amazing today?", "What are you celebrating?", "What gave you energy?"]),
        Mood(id: "good", name: "Good", color: Color(hex: "A8CF82"),
             prompts: ["What's a small win from today?", "What made you smile?", "What are you proud of?"]),
        Mood(id: "calm", name: "Calm", color: Color(hex: "8BC6F8"),
             prompts: ["What made you feel peaceful today?", "What helped you slow down?", "Who or what brought you comfort?"]),
        Mood(id: "okay", name: "Okay", color: Color(hex: "FFD38D"),
             prompts: ["How would you describe today in one word?", "What took up most of your energy?", "What did you need more of?"]),
        Mood(id: "restless", name: "Restless", color: Color(hex: "FFAF8C"),
             prompts: ["What's been on your mind?", "What do you need right now?", "What made you feel uneasy?"]),
        Mood(id: "heavy", name: "Heavy", color: Color(hex: "BFAEDF"),
             prompts: ["What's weighing on you?", "What would help lighten the load?", "What did you need today that you didn't get?"])
    ]
}
