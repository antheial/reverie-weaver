//
// LocalizationManager.swift
// ReverieWeaver
//
// Manages app language localization - Reorganized and Error-Free
//

import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .english
    }
    
    func localize(_ key: String) -> String {
        return translations[key]?[currentLanguage] ?? key
    }
    
    // MARK: - Translations Dictionary
    
    private let translations: [String: [AppLanguage: String]] = [
        
        // MARK: - Tab Bar
        "tab.today": [.english: "Today", .chinese: "今天"],
        "tab.archive": [.english: "Archive", .chinese: "回顾"],
        "tab.profile": [.english: "Profile", .chinese: "我的"],
        
        // MARK: - Days of Week
        "day.monday": [.english: "Monday", .chinese: "周一"],
        "day.tuesday": [.english: "Tuesday", .chinese: "周二"],
        "day.wednesday": [.english: "Wednesday", .chinese: "周三"],
        "day.thursday": [.english: "Thursday", .chinese: "周四"],
        "day.friday": [.english: "Friday", .chinese: "周五"],
        "day.saturday": [.english: "Saturday", .chinese: "周六"],
        "day.sunday": [.english: "Sunday", .chinese: "周日"],
        
        // MARK: - DeskView - Greetings
        "desk.greeting.morning": [.english: "Good Morning", .chinese: "早上好"],
        "desk.greeting.afternoon": [.english: "Good Afternoon", .chinese: "下午好"],
        "desk.greeting.evening": [.english: "Good Evening", .chinese: "晚上好"],
        "desk.greeting.night": [.english: "Good Night", .chinese: "晚安"],
        
        // MARK: - DeskView - Intention
        "desk.intention.prompt": [.english: "What will you weave today?", .chinese: "今天想做点什么？"],
        "desk.intention.placeholder": [.english: "Set your intention for the day... what matters most to you today?", .chinese: "写下今天的小目标吧...今天最想完成什么？"],
        "desk.intention.tapToExpand": [.english: "Tap to expand", .chinese: "点击展开"],
        
        // MARK: - DeskView - Quick Actions
        "quickAction.title": [.english: "Quick Actions", .chinese: "快速行动"],
        "quickAction.completions": [.english: "completions", .chinese: "次"],
        "quickAction.readyToAdd": [.english: "You've completed this 3 times!", .chinese: "已经完成3次啦！"],
        "quickAction.suggestHabit": [.english: "Ready to make this a daily habit?", .chinese: "要把它加入每日习惯吗？"],
        "quickAction.addHabit": [.english: "Yes, Add to My Daily Habits", .chinese: "好的，加入每日习惯"],
        "quickAction.maybeLater": [.english: "Maybe Later", .chinese: "下次再说"],
        "quickAction.congratulations": [.english: "Congratulations!", .chinese: "太棒了！"],
        "quickAction.keepGoing": [.english: "Keep going!", .chinese: "继续加油！"],
        
        // MARK: - DeskView - Daily Habits
        "desk.habits.title": [.english: "Daily Habits", .chinese: "每日习惯"],
        "desk.habits.add": [.english: "Add", .chinese: "添加"],
        "desk.habits.empty": [.english: "Begin your journey by creating your first habit", .chinese: "创建第一个习惯，开启你的旅程"],
        "desk.habits.createFirst": [.english: "Create First Habit", .chinese: "创建第一个习惯"],
        
        // MARK: - DeskView - Progress
        "desk.progress.title": [.english: "Today's Weave", .chinese: "今日进度"],
        "desk.progress.habitsWoven": [.english: "%d/%d Habits Woven", .chinese: "已完成 %d/%d 个习惯"],
        "desk.progress.percentage": [.english: "You're %d%% there! Keep going 🔥", .chinese: "已完成 %d%%，继续加油 🔥"],
        "desk.progress.allComplete": [.english: "Perfect day woven! ⭐", .chinese: "今天全部完成！⭐"],
        
        // MARK: - DeskView - Celebrations
        "desk.celebration.first": [.english: "🌱 First thread woven!", .chinese: "🌱 完成第一个！"],
        "desk.celebration.momentum": [.english: "🔥 Momentum building!", .chinese: "🔥 状态正佳！"],
        "desk.celebration.perfect": [.english: "⭐ Perfect day woven!", .chinese: "⭐ 今天全部完成！"],
        
        // Reminder Section
        "habit.reminders": [.english: "Reminders", .chinese: "提醒"],
        "habit.reminderOn": [.english: "Receive Gentle Nudge", .chinese: "开启提醒"],
        "habit.reminderOff": [.english: "No Notification", .chinese: "不提醒"],
        "habit.atTime": [.english: "At time:", .chinese: "提醒时间："],
        "habit.enableNotificationsInSettings": [.english: "Please enable notifications in Settings to receive reminders.", .chinese: "请在系统设置中开启通知权限"],
        "habit.openSettings": [.english: "Settings", .chinese: "去设置"],

        // Schedule/Frequency (if not already present)
        "habit.custom": [.english: "Custom", .chinese: "自定义"],
        "habit.selectDays": [.english: "Select days:", .chinese: "选择日期："],
        "habit.dayPerWeek": [.english: "day per week", .chinese: "天/周"],
        "habit.daysPerWeek": [.english: "days per week", .chinese: "天/周"],
        "habit.selectAtLeastOneDay": [.english: "Select at least one day", .chinese: "请至少选择一天"],

        // Edit/Create prompts (if not already present)
        "habit.editPrompt": [.english: "Refine the thread in your tapestry", .chinese: "调整这个习惯"],
        "habit.createPrompt": [.english: "What will you weave into your daily tapestry?", .chinese: "想养成什么新习惯？"],
        "habit.edit": [.english: "Edit Habit", .chinese: "编辑习惯"],
        "habit.save": [.english: "Save", .chinese: "保存"],
        "habit.close": [.english: "Close", .chinese: "关闭"],

        // Protected habit messages
        "habit.cannotEditProgram": [.english: "Cannot Edit Program Habit", .chinese: "无法编辑挑战习惯"],
        "habit.programHabitInfo": [.english: "Theme Week habits update automatically and can only be deleted from their program detail view.", .chinese: "主题周习惯会自动更新，只能在挑战详情页删除"],
        "habit.programEditInfo": [.english: "This habit is part of a program. You can edit its details, but it will remain tracked in the challenge.", .chinese: "这个习惯属于某个挑战，可以编辑详情，但会继续在挑战中追踪"],
        
        // MARK: - Project 50 Overview
        "project50.title": [.english: "✨ Project 50", .chinese: "✨ 50天挑战"],
        "project50.subtitle": [.english: "8 Core Habits to Rebuild Momentum", .chinese: "8个核心习惯，重拾生活节奏"],
        "project50.subtitle2": [.english: "Easy-Start Design for Sustainable Growth", .chinese: "从小事做起，稳步成长"],

        "project50.section.philosophyTitle": [.english: "The Philosophy", .chinese: "核心理念"],
        "project50.section.philosophyDesc": [.english: "Based on the classic Project 50 challenge, this version focuses on small, repeatable wins. Discipline grows from structure, not rigidity — progress over perfection.", .chinese: "基于经典的50天挑战，专注于积累小胜利。自律来自好的习惯结构，而不是死板的规定——进步比完美更重要。"],

        "project50.section.scienceTitle": [.english: "The Science Behind Project 50", .chinese: "背后的科学原理"],
        "project50.section.scienceDesc": [.english: "Every habit here is designed to work with your brain, not against it. We start small to lower activation energy, repeat to strengthen neural pathways, and celebrate progress to boost dopamine feedback.", .chinese: "每个习惯都顺应大脑的运作方式。从小事开始降低启动难度，通过重复强化神经通路，庆祝进步来激活多巴胺奖励。"],

        "project50.section.easyStartTitle": [.english: "Easy-Start Design", .chinese: "轻松上手"],
        "project50.feature.lowActivation": [.english: "Lower activation energy — start tiny", .chinese: "降低启动难度，从小事做起"],
        "project50.feature.multiplePaths": [.english: "Multiple completion paths", .chinese: "多种完成方式可选"],
        "project50.feature.flexibleTime": [.english: "Flexible time ranges (not rigid)", .chinese: "时间灵活，不死板"],
        "project50.feature.progressTracking": [.english: "Built-in progress tracking", .chinese: "自动记录进度"],
        "project50.feature.encouragement": [.english: "Encouragement, not guilt", .chinese: "鼓励为主，不制造焦虑"],

        "project50.section.tipsTitle": [.english: "Tips for Success", .chinese: "成功秘诀"],
        "project50.tip.blockTime": [.english: "Block consistent time each day", .chinese: "每天固定一个时间段"],
        "project50.tip.reflect": [.english: "Reflect briefly each night", .chinese: "每晚花几分钟回顾"],
        "project50.tip.momentum": [.english: "Don't chase perfect streaks — chase momentum", .chinese: "别追求完美打卡，保持势头更重要"],
        "project50.tip.pairRoutines": [.english: "Pair new habits with existing routines", .chinese: "把新习惯和已有的日常绑定"],

        "project50.button.start": [.english: "Start 50-Day Journey", .chinese: "开始50天挑战"],

        // MARK: - Project 50 Habits
        "project50.habit.rise": [.english: "Rise with Intention", .chinese: "有规律地起床"],
        "project50.habit.rise.desc": [.english: "Choose YOUR consistent wake time - not a rigid hour. Even 15 minutes earlier counts as progress.", .chinese: "选择适合自己的起床时间，不必太死板。哪怕提前15分钟也是进步。"],
        "project50.habit.rise.time": [.english: "Discipline Builder", .chinese: "自律养成"],

        "project50.habit.anchor": [.english: "Morning Anchor Ritual", .chinese: "晨间固定仪式"],
        "project50.habit.anchor.desc": [.english: "Pick 1-3 actions: make bed, journal, stretch, or plan your day. Start small and build momentum.", .chinese: "选1-3个动作：整理床铺、写日记、拉伸或规划一天。从小事开始，慢慢建立节奏。"],
        "project50.habit.anchor.time": [.english: "10-30 min", .chinese: "10-30分钟"],

        "project50.habit.move": [.english: "Move Your Body", .chinese: "动起来"],
        "project50.habit.move.desc": [.english: "20 min minimum — walk, dance, yoga, or gym. Move however you can.", .chinese: "至少20分钟：散步、跳舞、瑜伽或健身。用你喜欢的方式动起来。"],
        "project50.habit.move.time": [.english: "20-60 min", .chinese: "20-60分钟"],

        "project50.habit.hydrate": [.english: "Hydration Habit", .chinese: "多喝水"],
        "project50.habit.hydrate.desc": [.english: "Drink 6–8 glasses throughout the day. Keep water visible.", .chinese: "每天喝6-8杯水，把水杯放在看得见的地方。"],
        "project50.habit.hydrate.time": [.english: "Throughout day", .chinese: "全天"],

        "project50.habit.feedmind": [.english: "Feed Your Mind (10 Pages)", .chinese: "每天读10页书"],
        "project50.habit.feedmind.desc": [.english: "Read 10 pages daily — non-fiction or self-growth. Audiobooks count!", .chinese: "每天读10页，成长类或非虚构都行。听书也算！"],
        "project50.habit.feedmind.time": [.english: "10-15 min", .chinese: "10-15分钟"],

        "project50.habit.deepwork": [.english: "Deep Work Hour", .chinese: "深度专注1小时"],
        "project50.habit.deepwork.desc": [.english: "1 hour on a skill or goal. Study, write, code — focus time that matters.", .chinese: "专注1小时提升技能或推进目标。学习、写作、编程都可以。"],
        "project50.habit.deepwork.time": [.english: "60 min (flexible)", .chinese: "60分钟（可灵活调整）"],

        "project50.habit.eatintent": [.english: "Eat with Intention", .chinese: "好好吃饭"],
        "project50.habit.eatintent.desc": [.english: "Not strict dieting — just mindful eating. Avoid ultra-processed foods today.", .chinese: "不用严格节食，只是用心吃饭。尽量少吃加工食品。"],
        "project50.habit.eatintent.time": [.english: "Ongoing mindset", .chinese: "贯穿全天"],

        "project50.habit.eveningdump": [.english: "Evening Brain Dump", .chinese: "晚间清空思绪"],
        "project50.habit.eveningdump.desc": [.english: "Reflect in 3+ sentences. What worked? What’s next? Build awareness and gratitude.", .chinese: "写3句以上：今天哪些做得好？明天做什么？培养觉察和感恩。"],
        "project50.habit.eveningdump.time": [.english: "5-10 min", .chinese: "5-10分钟"],

        "project50.section.morning": [.english: "Morning Anchors", .chinese: "晨间习惯"],
        "project50.section.energy": [.english: "Body & Energy", .chinese: "身体与能量"],
        "project50.section.cognitive": [.english: "Cognitive Anchors", .chinese: "思维习惯"],
        "project50.section.reflection": [.english: "Reflection", .chinese: "反思时刻"],

        
        // MARK: - Micro Habits - Morning (Energy & Intention Setting)
        "micro.morning.curtains": [.english: "Open curtains + 3 deep breaths", .chinese: "拉开窗帘，深呼吸3次"],
        "micro.morning.water": [.english: "Drink 1 glass of water", .chinese: "喝一杯水"],
        "micro.morning.sunlight": [.english: "View morning sunlight", .chinese: "晒晒早晨的阳光"],
        "micro.morning.coldsplash": [.english: "Cold water face splash", .chinese: "用冷水洗把脸"],
        "micro.morning.stretch": [.english: "Stretch for 5 minutes", .chinese: "拉伸5分钟"],
        "micro.morning.quickstretch": [.english: "30-second full body stretch", .chinese: "30秒全身拉伸"],
        "micro.morning.yoga": [.english: "Do 5 minutes of gentle yoga", .chinese: "做5分钟轻瑜伽"],
        "micro.morning.meditate": [.english: "2-minute morning meditation", .chinese: "晨间冥想2分钟"],
        "micro.morning.gratitude": [.english: "Write 1 gratitude sentence", .chinese: "写一句感恩的话"],
        "micro.morning.intention": [.english: "Set daily intention", .chinese: "定下今日目标"],
        "micro.morning.braindump": [.english: "Mental declutter", .chinese: "清空脑中杂念"],
        "micro.morning.affirmations": [.english: "Speak positive affirmations", .chinese: "对自己说句鼓励的话"],
        "micro.morning.bed": [.english: "Make bed + smile at yourself", .chinese: "整理床铺，对自己微笑"],
        "micro.morning.tidy": [.english: "Tidy one surface", .chinese: "整理一处台面"],
        "micro.morning.breakfast": [.english: "Protein-rich breakfast", .chinese: "吃顿高蛋白早餐"],
        "micro.morning.write": [.english: "Write morning intention", .chinese: "写下晨间意图"],
        "micro.morning.message": [.english: "Send a thoughtful message", .chinese: "给在乎的人发条消息"],
        "micro.morning.plant": [.english: "Water a plant", .chinese: "给植物浇浇水"],
        // Ultra-low-friction morning habits (ADHD-friendly)
        "micro.morning.threebreaths": [.english: "Take 3 deep breaths", .chinese: "深呼吸3次"],
        "micro.morning.wiggle": [.english: "Wiggle your toes for 10 seconds", .chinese: "动动脚趾10秒"],
        "micro.morning.seethree": [.english: "Name 3 things you can see", .chinese: "说出眼前3样东西"],
        "micro.morning.onepillow": [.english: "Straighten one pillow", .chinese: "整理一个枕头"],
        "micro.morning.emoji": [.english: "Send one emoji to someone", .chinese: "给朋友发个表情"],
        "micro.morning.window": [.english: "Look out the window for 30 sec", .chinese: "看窗外30秒"],
        "micro.morning.outfit": [.english: "Pick today's outfit", .chinese: "选好今天穿什么"],
        "micro.morning.onething": [.english: "Put away one thing", .chinese: "收好一样东西"],
        
        // MARK: - Micro Habits - Afternoon (Sustained Energy & Productivity)
        "micro.afternoon.walk": [.english: "5-minute walk outside", .chinese: "出去走5分钟"],
        "micro.afternoon.jumping": [.english: "10 jumping jacks", .chinese: "做10个开合跳"],
        "micro.afternoon.stretch": [.english: "3-minute desk stretching", .chinese: "办公桌前拉伸3分钟"],
        "micro.afternoon.stand": [.english: "Just stand up", .chinese: "站起来动一动"],
        "micro.afternoon.fruit": [.english: "Eat 1 piece of fruit", .chinese: "吃个水果"],
        "micro.afternoon.nuts": [.english: "Energy-boosting snack", .chinese: "来点坚果补充能量"],
        "micro.afternoon.mindful_lunch": [.english: "Mindful lunch (away from screen)", .chinese: "专心吃饭，放下手机"],
        "micro.afternoon.meditate": [.english: "3-minute meditation", .chinese: "冥想3分钟"],
        "micro.afternoon.breathwork": [.english: "Practice breathwork exercises", .chinese: "做几组呼吸练习"],
        "micro.afternoon.posture": [.english: "Check and correct your posture", .chinese: "调整一下坐姿"],
        "micro.afternoon.eyes": [.english: "Rest eyes (20-20-20 rule)", .chinese: "让眼睛休息一下"],
        "micro.afternoon.declutter": [.english: "Clear physical desktop", .chinese: "清理一下桌面"],
        "micro.afternoon.workspace": [.english: "Refresh workspace", .chinese: "整理工作区"],
        "micro.afternoon.learn": [.english: "Learn 1 new word/fact", .chinese: "学一个新知识"],
        "micro.afternoon.language": [.english: "Practice a new language", .chinese: "练习外语"],
        "micro.afternoon.sketch": [.english: "Sketch or draw for 3 minutes", .chinese: "画画涂鸦3分钟"],
        "micro.afternoon.doodle": [.english: "Doodle for 3 minutes", .chinese: "随手涂鸦3分钟"],
        "micro.afternoon.music": [.english: "Play music or sing", .chinese: "弹琴唱歌放松下"],
        "micro.afternoon.progress": [.english: "Review goals progress", .chinese: "看看目标完成得怎样"],
        "micro.afternoon.text": [.english: "Text someone you appreciate", .chinese: "给想感谢的人发条消息"],
        "micro.afternoon.call": [.english: "Make a quick call to connect", .chinese: "打个电话问候一下"],
        
        // MARK: - Micro Habits - Evening (Wind-Down & Reflection)
        "micro.evening.journal": [.english: "Journal 3 minutes", .chinese: "写3分钟日记"],
        "micro.evening.gratitude": [.english: "Write 3 things you're grateful for", .chinese: "写下今天感恩的3件事"],
        "micro.evening.wins": [.english: "Celebrate small wins", .chinese: "回顾今天的小成就"],
        "micro.evening.read": [.english: "Read before bed (5 min)", .chinese: "睡前读5分钟书"],
        "micro.evening.article": [.english: "Read an interesting article", .chinese: "读一篇有意思的文章"],
        "micro.evening.putaway": [.english: "Put away 5 items", .chinese: "收拾5样东西"],
        "micro.evening.plan": [.english: "Plan tomorrow (3 min)", .chinese: "花3分钟计划明天"],
        "micro.evening.clothes": [.english: "Prepare clothes for tomorrow", .chinese: "准备好明天的衣服"],
        "micro.evening.digital_sunset": [.english: "Turn off work notifications", .chinese: "关掉工作通知"],
        "micro.evening.dim_lights": [.english: "Warmer lighting", .chinese: "把灯光调暖"],
        "micro.evening.hygiene": [.english: "Wash face + brush teeth", .chinese: "洗脸刷牙"],
        "micro.evening.stretch": [.english: "Gentle stretching", .chinese: "轻柔地拉伸一下"],
        "micro.evening.selfmassage": [.english: "Give yourself a hand/foot massage", .chinese: "给自己按摩手脚"],
        "micro.evening.visualization": [.english: "Visualize tomorrow's success", .chinese: "想象明天顺利的样子"],
        "micro.evening.draw": [.english: "Draw or paint for 5 minutes", .chinese: "画5分钟画"],
        "micro.evening.family": [.english: "Spend quality time with family", .chinese: "陪家人聊聊天"],
        "micro.evening.share": [.english: "Share one thing from day", .chinese: "分享今天的一件事"],
        
        // MARK: - Micro Habits - Pre-Sleep (Sleep Preparation & Recovery)
        "micro.presleep.breathing": [.english: "Deep breathing exercise", .chinese: "做几次深呼吸"],
        "micro.presleep.bodyscan": [.english: "Body scan meditation", .chinese: "身体扫描冥想"],
        "micro.presleep.progressive_relaxation": [.english: "Progressive muscle relaxation", .chinese: "渐进式放松肌肉"],
        "micro.presleep.neck": [.english: "Gentle neck rolls", .chinese: "轻轻转动脖子"],
        "micro.presleep.eyerelax": [.english: "Relax your eyes", .chinese: "放松眼睛"],
        "micro.presleep.charge": [.english: "Phone away from bed", .chinese: "把手机放远一点"],
        "micro.presleep.temp": [.english: "Lower room temperature", .chinese: "把室温调低一些"],
        "micro.presleep.sounds": [.english: "White noise/silence", .chinese: "播放白噪音或保持安静"],
        "micro.presleep.dim": [.english: "Dim all lights", .chinese: "把灯都调暗"],
        "micro.presleep.aromatherapy": [.english: "Lavender/calming scents", .chinese: "点一点薰衣草香薰"],
        "micro.presleep.write": [.english: "Write down 1 thought", .chinese: "写下一个想法"],
        "micro.presleep.dreamjournal": [.english: "Write in dream journal", .chinese: "写梦境日记"],
        "micro.presleep.reflect": [.english: "Reflect on today (2 min)", .chinese: "花2分钟回顾今天"],
        "micro.presleep.sleep_gratitude": [.english: "3 things from today", .chinese: "想想今天3件开心的事"],
        "micro.presleep.friction": [.english: "Prep water/book for morning", .chinese: "床头放好水和书"],
        "micro.presleep.tea": [.english: "Drink herbal tea", .chinese: "喝杯花草茶"],
        
        // MARK: - Legacy Night Habits (for backwards compatibility)
        "micro.night.breathing": [.english: "Square breathing (4-4-4-4)", .chinese: "方形呼吸法（4-4-4-4）"],
        "micro.night.write": [.english: "Write down 1 thought", .chinese: "写下一个想法"],
        "micro.night.neck": [.english: "Gentle neck rolls", .chinese: "轻轻转动脖子"],
        "micro.night.tea": [.english: "Drink herbal tea", .chinese: "喝杯花草茶"],
        "micro.night.reflect": [.english: "Reflect on today (2 min)", .chinese: "花2分钟回顾今天"],
        "micro.night.bodyscan": [.english: "Do a body scan meditation", .chinese: "做身体扫描冥想"],
        "micro.night.eyerelax": [.english: "Relax your eyes", .chinese: "放松眼睛"],
        "micro.night.dreamjournal": [.english: "Write in your dream journal", .chinese: "写梦境日记"],
        "micro.night.charge": [.english: "Charge phone far from bed", .chinese: "把手机放远充电"],
        "micro.night.temp": [.english: "Cool down the room", .chinese: "把室温调低一些"],
        "micro.night.sounds": [.english: "Set sleep environment", .chinese: "营造睡眠环境"],
        "micro.night.friction": [.english: "Prep one morning item", .chinese: "准备一件明早要用的东西"],
        
        // MARK: - Duration Labels
        "micro.duration.30sec": [.english: "30 sec", .chinese: "30秒"],
        "micro.duration.1min": [.english: "1 min", .chinese: "1分钟"],
        "micro.duration.2min": [.english: "2 min", .chinese: "2分钟"],
        "micro.duration.3min": [.english: "3 min", .chinese: "3分钟"],
        "micro.duration.5min": [.english: "5 min", .chinese: "5分钟"],
        
        // MARK: - Archive
        "archive.title": [.english: "Archive", .chinese: "回顾"],
        "archive.weekly": [.english: "Weekly", .chinese: "本周"],
        "archive.monthly": [.english: "Monthly", .chinese: "本月"],
        "archive.achievements": [.english: "Achievements", .chinese: "成就"],
        "archive.weekSummary": [.english: "Week Summary", .chinese: "本周总结"],
        "archive.threadsWoven": [.english: "Threads Woven", .chinese: "已完成"],
        "archive.completion": [.english: "Completion", .chinese: "完成率"],
        "archive.favorites": [.english: "Favorites", .chinese: "收藏"],
        "archive.topHabits": [.english: "Top Habits This Week", .chinese: "本周最佳"],
        "archive.topHabitsMonth": [.english: "Top Habits This Month", .chinese: "本月最佳"],
        "archive.timesCompleted": [.english: "times completed", .chinese: "次"],
        "archive.dailyIntentions": [.english: "Daily Intentions", .chinese: "每日目标"],
        "archive.noIntentions": [.english: "No intentions set this week", .chinese: "本周还没设定目标"],
        "archive.monthSummary": [.english: "Summary", .chinese: "总结"],
        "archive.totalThreads": [.english: "Total Threads", .chinese: "总完成数"],
        "archive.perfectDays": [.english: "Perfect Days", .chinese: "全勤天数"],
        "archive.activityHeatmap": [.english: "Activity Heatmap", .chinese: "活动热图"],
        "archive.noAchievements": [.english: "No achievements yet", .chinese: "还没有成就"],
        "archive.achievementHint": [.english: "Complete all your habits in one day to earn your first achievement!", .chinese: "一天内完成所有习惯就能获得第一个成就！"],
        "archive.earned": [.english: "Earned", .chinese: "获得于"],
        
        // MARK: - Profile
        "profile.title": [.english: "Profile", .chinese: "我的"],
        "profile.displayName": [.english: "Display Name", .chinese: "昵称"],
        "profile.namePlaceholder": [.english: "Your name", .chinese: "你的名字"],
        "profile.yourJourney": [.english: "Your Journey", .chinese: "我的旅程"],
        "profile.dayStreak": [.english: "Day Streak", .chinese: "连续天数"],
        "profile.completed": [.english: "Completed", .chinese: "已完成"],
        "profile.achievements": [.english: "Achievements", .chinese: "成就"],
        "profile.perfectDays": [.english: "Perfect Days", .chinese: "全勤天数"],
        "profile.activeHabits": [.english: "Active Habits", .chinese: "进行中的习惯"],
        "profile.personalIntention": [.english: "Personal Intention", .chinese: "个人目标"],
        "profile.intentionPrompt": [.english: "What drives your journey?", .chinese: "是什么在驱动你前进？"],
        "profile.mottoPlaceholder": [.english: "Enter your personal motto or intention...", .chinese: "写下你的座右铭或目标..."],
        "profile.preferences": [.english: "Preferences", .chinese: "设置"],
        "profile.weekStartSunday": [.english: "Week Starts on Sunday", .chinese: "每周从周日开始"],
        "profile.weekStartDesc": [.english: "Changes how weekly stats are calculated", .chinese: "影响周统计的计算方式"],
        "profile.language": [.english: "Language", .chinese: "语言"],
        "profile.languageDesc": [.english: "Choose your preferred language", .chinese: "选择显示语言"],
        "profile.dataManagement": [.english: "Data Management", .chinese: "数据管理"],
        "profile.exportData": [.english: "Export Reflections", .chinese: "导出数据"],
        "profile.icloudBackup": [.english: "iCloud Backup: Enabled", .chinese: "iCloud 备份：已开启"],
        "profile.icloudDesc": [.english: "Your data is automatically backed up to iCloud and will sync across your devices.", .chinese: "数据会自动备份到 iCloud，并在你的设备间同步。"],
        "profile.dataExported": [.english: "Data Exported", .chinese: "导出成功"],
        "profile.exportSuccess": [.english: "Your habit data has been exported successfully.", .chinese: "习惯数据已成功导出。"],
        "profile.ok": [.english: "OK", .chinese: "好的"],
        "profile.support": [.english: "Support & Feedback", .chinese: "帮助与反馈"],
        "profile.rateApp": [.english: "Rate ReverieWeaver", .chinese: "给我们评分"],
        "profile.sendFeedback": [.english: "Send Feedback", .chinese: "意见反馈"],
        "profile.version": [.english: "Version", .chinese: "版本"],

        // MARK: - Profile Stats
        "profile.daysInRhythm": [.english: "Days in Rhythm", .chinese: "连续天数"],
        "profile.threadsWoven": [.english: "Threads Woven", .chinese: "完成次数"],
        "profile.fullPatterns": [.english: "Full Patterns", .chinese: "全勤天数"],
        "profile.activeThreads": [.english: "Active Threads", .chinese: "进行中"],
        "profile.moreToNextLevel": [.english: "more to next level", .chinese: "距下一等级"],
        "profile.level": [.english: "Level", .chinese: "等级"],
        "profile.transcendentReached": [.english: "Transcendent Level Reached", .chinese: "已达超越境界"],

        // MARK: - Profile Grimoire
        "profile.grimoire": [.english: "The Weaver's Grimoire", .chinese: "织梦者魔典"],
        "profile.chapterReached": [.english: "Your journey thread has reached Chapter", .chinese: "你的旅程之线已到达第"],
        "profile.nextThread": [.english: "The next thread", .chinese: "下一条线索"],
        "profile.chapter": [.english: "Chapter", .chinese: "章"],
        "profile.storyBeginning": [.english: "Your story is just beginning. Start weaving your first thread.", .chinese: "你的故事刚刚开始。开始编织你的第一条线吧。"],

        // MARK: - Profile Hidden Threads
        "profile.hiddenThreads": [.english: "Hidden Threads", .chinese: "隐秘之线"],
        "profile.hiddenThreadsDesc": [.english: "Quietly discovered moments in your journey", .chinese: "旅途中悄然发现的时刻"],

        // MARK: - Profile Personal Intention
        "profile.myWhy": [.english: "My Why", .chinese: "我的初心"],
        "profile.setIntention": [.english: "Set your intention in settings...", .chinese: "在设置中写下你的初心..."],

        // MARK: - Profile Alerts
        "profile.locked": [.english: "Locked", .chinese: "未解锁"],
        "profile.keepWeaving": [.english: "I will keep weaving", .chinese: "继续编织"],
        "profile.hiddenThreadRevealed": [.english: "A Hidden Thread Revealed", .chinese: "发现隐秘之线"],
        "profile.beautiful": [.english: "Beautiful", .chinese: "太美了"],

        // MARK: - Settings
        "settings.title": [.english: "Settings", .chinese: "设置"],

        // MARK: - iCloud & Export
        "icloud.active": [.english: "Active", .chinese: "已启用"],
        "icloud.notSignedIn": [.english: "Not Signed In", .chinese: "未登录"],
        "icloud.restricted": [.english: "Restricted", .chinese: "受限"],
        "icloud.error": [.english: "Error", .chinese: "错误"],
        "icloud.offline": [.english: "Offline", .chinese: "离线"],
        "icloud.unknown": [.english: "Unknown", .chinese: "未知"],
        "icloud.checking": [.english: "Checking...", .chinese: "检查中..."],
        "icloud.syncingDesc": [.english: "Your data is automatically syncing with your iCloud account.", .chinese: "数据正在自动同步到你的 iCloud 账户。"],
        "icloud.notSignedInDesc": [.english: "Please log into iCloud in iOS Settings to enable backup.", .chinese: "请在系统设置中登录 iCloud 以启用备份。"],
        "export.reflections": [.english: "Export Reflections", .chinese: "导出反思笔记"],
        "export.reflectionsDesc": [.english: "Create a PDF of this month's reflection notes", .chinese: "将本月的反思笔记导出为PDF"],
        "export.noData": [.english: "No Data to Export", .chinese: "没有可导出的数据"],
        "export.noDataDesc": [.english: "There are no reflection notes for this month yet.", .chinese: "本月还没有反思笔记。"],

        // MARK: - Storage Management
        "storage.title": [.english: "Storage Management", .chinese: "存储管理"],
        "storage.dataSize": [.english: "App Data Size", .chinese: "应用数据大小"],
        "storage.textData": [.english: "Text Data", .chinese: "文字数据"],
        "storage.photos": [.english: "Photos", .chinese: "照片"],
        "storage.completions": [.english: "Completions", .chinese: "完成记录"],
        "storage.clearOld": [.english: "Clear Data Older Than 1 Year", .chinese: "清除一年前的数据"],
        "storage.clearDesc": [.english: "Clearing old data removes reflections and photos from over a year ago.", .chinese: "这会删除一年前的反思和照片。"],
        
        // MARK: - Create/Edit Habit
        "habit.create": [.english: "Create New Habit", .chinese: "创建新习惯"],
        "habit.name": [.english: "Habit Name", .chinese: "习惯名称"],
        "habit.namePlaceholder": [.english: "e.g., Morning Meditation", .chinese: "例如：晨间冥想"],
        "habit.description": [.english: "Description (optional)", .chinese: "描述（选填）"],
        "habit.descPlaceholder": [.english: "What does this habit mean to you?", .chinese: "这个习惯对你有什么意义？"],
        "habit.completionMessage": [.english: "Completion Message (optional)", .chinese: "完成提示（选填）"],
        "habit.messagePlaceholder": [.english: "e.g., Thread woven - you've honored your morning", .chinese: "例如：做得好，又是元气满满的一天"],
        "habit.category": [.english: "Category", .chinese: "分类"],
        "habit.icon": [.english: "Icon", .chinese: "图标"],
        "habit.threadColor": [.english: "Thread Color", .chinese: "颜色"],
        "habit.frequency": [.english: "Frequency", .chinese: "频率"],
        "habit.daily": [.english: "Daily", .chinese: "每天"],
        "habit.weekly": [.english: "Weekly", .chinese: "每周"],
        "habit.cancel": [.english: "Cancel", .chinese: "取消"],
        "habit.create.button": [.english: "Create", .chinese: "创建"],
        
        // MARK: - Categories (Old - for HabitFormSheet)
        "category.wellbeing": [.english: "Wellbeing", .chinese: "健康"],
        "category.growth": [.english: "Growth", .chinese: "成长"],
        "category.creativity": [.english: "Creativity", .chinese: "创造力"],
        "category.connection": [.english: "Connection", .chinese: "连结"],
        "category.rest": [.english: "Rest", .chinese: "休息"],
        
        // MARK: - Categories (New - for HabitLibrary)
        "category.MorningRituals": [.english: "Morning Rituals", .chinese: "晨间仪式"],
        "category.HealthFoundations": [.english: "Health Foundations", .chinese: "健康基础"],
        "category.MindfulLiving": [.english: "Mindful Living", .chinese: "正念生活"],
        "category.CreativePractice": [.english: "Creative Practice", .chinese: "创意实践"],
        "category.Connection": [.english: "Connection", .chinese: "人际连接"],
        
        // MARK: - Category Descriptions
        "category.morningRituals.desc": [.english: "Start your day with intention", .chinese: "有仪式感地开启一天"],
        "category.healthFoundations.desc": [.english: "Build physical & mental wellness", .chinese: "打好身心健康基础"],
        "category.mindfulLiving.desc": [.english: "Cultivate presence & awareness", .chinese: "活在当下，保持觉察"],
        "category.creativePractice.desc": [.english: "Nurture your creative spirit", .chinese: "滋养创造力"],
        "category.connection.desc": [.english: "Strengthen relationships", .chinese: "增进人际关系"],
        
        // MARK: - Habit Library
        "library.title": [.english: "Habit Library", .chinese: "习惯库"],
        "library.subtitle": [.english: "Discover habits to weave into your life", .chinese: "发现适合你的习惯"],
        "library.browse": [.english: "Browse Library", .chinese: "浏览习惯库"],
        "library.addToDesk": [.english: "Add", .chinese: "添加"],
        "library.benefits": [.english: "Benefits", .chinese: "好处"],
        "library.tips": [.english: "Tips", .chinese: "小贴士"],
        "library.frequency": [.english: "Suggested Frequency", .chinese: "建议频率"],
        "library.estimatedTime": [.english: "Estimated Time", .chinese: "预计时长"],
        "library.description": [.english: "Description", .chinese: "描述"],
        "library.allCategories": [.english: "All Categories", .chinese: "全部分类"],
        "library.habitAdded": [.english: "Habit Added!⭐️", .chinese: "添加成功！⭐️"],
        "library.habitAddedDesc": [.english: "You can find it on your Daily Habits", .chinese: "可以在每日习惯中找到它"],
        
        // MARK: - Reflection
        "reflection.title": [.english: "Reflect on", .chinese: "反思"],
        "reflection.prompt": [.english: "How are you different after completing this?", .chinese: "完成之后有什么感受？"],
        "reflection.howFeel": [.english: "How did it feel?", .chinese: "感觉如何？"],
        "reflection.thoughts": [.english: "Your Thoughts", .chinese: "写点什么"],
        "reflection.thoughtsPlaceholder": [.english: "Write what comes to mind...", .chinese: "随便写写..."],
        "reflection.addPhoto": [.english: "Add a Photo (optional)", .chinese: "添加照片（选填）"],
        "reflection.photoPrompt": [.english: "Tap to add photo", .chinese: "点击添加"],
        "reflection.favorite": [.english: "Mark as favorite for archive", .chinese: "收藏到回顾"],
        "reflection.skip": [.english: "Skip", .chinese: "跳过"],
        "reflection.save": [.english: "Save Reflection", .chinese: "保存"],
        
        // MARK: - Moods
        "mood.energized": [.english: "Energized", .chinese: "精力充沛"],
        "mood.calm": [.english: "Calm", .chinese: "平静"],
        "mood.neutral": [.english: "Neutral", .chinese: "一般"],
        "mood.tired": [.english: "Tired", .chinese: "有点累"],
        "mood.stressed": [.english: "Stressed", .chinese: "有压力"],
        "mood.peaceful": [.english: "Peaceful", .chinese: "平和"],
        "mood.focused": [.english: "Focused", .chinese: "专注"],
        "mood.grateful": [.english: "Grateful", .chinese: "感恩"],
        "mood.hopeful": [.english: "Hopeful", .chinese: "充满希望"],
        "mood.action": [.english: "Action", .chinese: "想行动"],
        
        // MARK: - Frequency Options
        "frequency.daily": [.english: "Daily", .chinese: "每日"],
        "frequency.weekly": [.english: "3x per week", .chinese: "每周3次"],
        "frequency.twiceWeekly": [.english: "2x per week", .chinese: "每周2次"],
        "frequency.weekdays": [.english: "Weekdays", .chinese: "工作日"],
        "frequency.thriceDaily": [.english: "3x daily", .chinese: "每日3次"],
        
        // MARK: - Floating Add Button
        "floatingAdd.quickAdd": [.english: "Quick Add", .chinese: "快速添加"],
        "floatingAdd.createHabit": [.english: "Create Habit", .chinese: "创建习惯"],
        "floatingAdd.browseLibrary": [.english: "Browse Library", .chinese: "浏览习惯库"],
        "floatingAdd.title": [.english: "Add a Habit", .chinese: "添加习惯"],
        
        // MARK: - Common
        "common.of": [.english: "of", .chinese: "/"],
        "common.weekOf": [.english: "Week of", .chinese: "周"],
        "common.done": [.english: "Done", .chinese: "完成"],
        "common.cancel": [.english: "Cancel", .chinese: "取消"],
        "common.save": [.english: "Save", .chinese: "保存"],
        "common.delete": [.english: "Delete", .chinese: "删除"],
        "common.ok": [.english: "OK", .chinese: "好的"],
        "common.clear": [.english: "Clear", .chinese: "清除"],
        "common.continueAnyway": [.english: "Continue Anyway", .chinese: "仍然继续"],

        // MARK: - PDF Import
        "pdf.library.title": [.english: "Task Library", .chinese: "任务库"],
        "pdf.import": [.english: "Import PDF", .chinese: "导入PDF"],
        "pdf.empty.title": [.english: "No PDFs imported yet", .chinese: "还没有导入PDF"],
        "pdf.empty.subtitle": [.english: "Import a PDF to extract your task lists", .chinese: "导入PDF来提取任务列表"],
        "pdf.pages": [.english: "pages", .chinese: "页"],
        "pdf.lists": [.english: "lists", .chinese: "列表"],
        "pdf.pdfs": [.english: "PDFs", .chinese: "个PDF"],
        "pdf.tasks": [.english: "Tasks", .chinese: "任务"],

        // PDF Actions
        "pdf.extractNewList": [.english: "Extract New List", .chinese: "提取新列表"],
        "pdf.deletePDF": [.english: "Delete PDF", .chinese: "删除PDF"],
        "pdf.viewTasks": [.english: "View Tasks", .chinese: "查看任务"],
        "pdf.rename": [.english: "Rename", .chinese: "重命名"],

        // PDF Confirmation Dialogs
        "pdf.delete.title": [.english: "Delete PDF?", .chinese: "删除PDF？"],
        "pdf.delete.message": [.english: "This will delete the PDF and all associated task lists. This cannot be undone.", .chinese: "这将删除PDF及其所有关联的任务列表，此操作无法撤销。"],
        "pdf.deleteList.title": [.english: "Delete Task List?", .chinese: "删除任务列表？"],
        "pdf.deleteList.message": [.english: "This will delete the task list and all its tasks. This cannot be undone.", .chinese: "这将删除任务列表及其所有任务，此操作无法撤销。"],

        // PDF Error Messages
        "pdf.error.importFailed": [.english: "Import Failed", .chinese: "导入失败"],
        "pdf.error.accessDenied": [.english: "Unable to access this file. Please try again or choose a different file.", .chinese: "无法访问此文件，请重试或选择其他文件。"],
        "pdf.error.copyFailed": [.english: "Failed to save the PDF", .chinese: "保存PDF失败"],
        "pdf.error.directoryFailed": [.english: "Unable to create storage directory. Please check available storage space.", .chinese: "无法创建存储目录，请检查可用存储空间。"],
        "pdf.error.invalidPDF": [.english: "This file doesn't appear to be a valid PDF document.", .chinese: "此文件似乎不是有效的PDF文档。"],
        "pdf.error.insufficientStorage": [.english: "Not enough storage space to import this PDF. Please free up some space and try again.", .chinese: "存储空间不足，请清理空间后重试。"],
        "pdf.error.tooLarge": [.english: "This PDF is too large. Please use a smaller file.", .chinese: "PDF文件过大，请使用较小的文件。"],
        "pdf.error.tooManyPages": [.english: "This PDF has too many pages. Please use a smaller PDF.", .chinese: "PDF页数过多，请使用页数较少的PDF。"],

        // Large PDF Warning
        "pdf.warning.largePDF": [.english: "Large PDF Detected", .chinese: "检测到大型PDF"],
        "pdf.warning.largePDFMessage": [.english: "This PDF has %d pages. Large PDFs may take longer to process and use more storage. Continue?", .chinese: "此PDF有%d页，大型PDF可能需要更长的处理时间和更多存储空间。是否继续？"],

        // PDF Page Browser
        "pdf.selectPage": [.english: "Select Page", .chinese: "选择页面"],
        "pdf.loadingPages": [.english: "Loading pages...", .chinese: "正在加载页面..."],
        "pdf.loadingProgress": [.english: "Loading pages (%d/%d)...", .chinese: "正在加载页面 (%d/%d)..."],
        "pdf.tapToExtract": [.english: "Tap a page to extract tasks", .chinese: "点击页面提取任务"],
        "pdf.selectAreaOrFull": [.english: "You can select a specific area or extract the full page", .chinese: "可以选择特定区域或提取整页"],
        "pdf.page": [.english: "Page", .chinese: "第"],
        "pdf.pageNumber": [.english: "Page %d", .chinese: "第%d页"],

        // PDF Selection
        "pdf.selectArea": [.english: "Select Area", .chinese: "选择区域"],
        "pdf.drawRectangle": [.english: "Draw a rectangle to select the area with todos", .chinese: "画框选择包含任务的区域"],
        "pdf.selectionReady": [.english: "Selection ready! Tap Extract or select Full Page", .chinese: "选择完成！点击提取或选择整页"],
        "pdf.fullPage": [.english: "Full Page", .chinese: "整页"],
        "pdf.extractSelected": [.english: "Extract Selected", .chinese: "提取选中"],
        "pdf.unableToLoadPage": [.english: "Unable to load page", .chinese: "无法加载页面"],
        "pdf.unableToLoadPDF": [.english: "Unable to load PDF", .chinese: "无法加载PDF"],

        // Task List Naming
        "pdf.nameTaskList": [.english: "Name this task list", .chinese: "命名任务列表"],
        "pdf.extractingFromSelection": [.english: "Extracting from selection", .chinese: "从选区提取"],
        "pdf.extractingFullPage": [.english: "Extracting full page", .chinese: "提取整页"],
        "pdf.taskListPlaceholder": [.english: "e.g., Week 1 Tasks", .chinese: "例如：第1周任务"],
        "pdf.extract": [.english: "Extract", .chinese: "提取"],

        // Rename Task List
        "pdf.renameTaskList": [.english: "Rename Task List", .chinese: "重命名任务列表"],
        "pdf.taskListName": [.english: "Task list name", .chinese: "任务列表名称"],

        // Filter Status
        "pdf.filter.all": [.english: "All", .chinese: "全部"],
        "pdf.filter.backlog": [.english: "Backlog", .chinese: "待办"],
        "pdf.filter.active": [.english: "Active", .chinese: "进行中"],
        "pdf.filter.archived": [.english: "Archived", .chinese: "已归档"],

        // Sort Options
        "pdf.sortBy": [.english: "Sort:", .chinese: "排序:"],

        // Archive Prompt
        "pdf.archivePrompt.title": [.english: "All Done!", .chinese: "全部完成！"],
        "pdf.archivePrompt.message": [.english: "Would you like to archive this task list?", .chinese: "是否归档此任务列表？"],
        "pdf.archivePrompt.archive": [.english: "Archive", .chinese: "归档"],
        "pdf.archivePrompt.keepActive": [.english: "Keep Active", .chinese: "保持进行中"],

        // Task List Editor
        "pdf.task.delete": [.english: "Delete Task?", .chinese: "删除任务？"],
        "pdf.task.addPlaceholder": [.english: "Add a task...", .chinese: "添加任务..."],
        "pdf.task.task": [.english: "Task", .chinese: "任务"],
        "pdf.addToToday": [.english: "Add to Today's Weaves", .chinese: "添加到今日织梦"],
        "pdf.tasksWillBeAdded": [.english: "%d task(s) will be added to your Priority Tasks for today.", .chinese: "将%d个任务添加到今日优先任务。"],
        "pdf.andMore": [.english: "... and %d more", .chinese: "... 还有%d个"],
        "pdf.addToTodayButton": [.english: "Add to Today", .chinese: "添加到今日"],
        "pdf.addedToToday.title": [.english: "Added to Today's Weaves", .chinese: "已添加到今日织梦"],
        "pdf.addedToToday.message": [.english: "%d task(s) added to your daily priorities", .chinese: "已添加%d个任务到今日优先"],

        // Extraction Preview
        "pdf.preview.title": [.english: "Extracted Tasks", .chinese: "提取的任务"],
        "pdf.preview.tasksFound": [.english: "%d tasks found", .chinese: "找到%d个任务"],
        "pdf.preview.noTasksFound": [.english: "No tasks found", .chinese: "未找到任务"],
        "pdf.preview.noTasksMessage": [.english: "Try selecting a different area or check if the PDF contains readable text.", .chinese: "尝试选择其他区域，或检查PDF是否包含可读文本。"],
        "pdf.preview.editHint": [.english: "Tap to edit • Swipe to remove", .chinese: "点击编辑 • 滑动删除"],
        "pdf.preview.saveList": [.english: "Save List", .chinese: "保存列表"],
        "pdf.preview.tryAgain": [.english: "Try Again", .chinese: "重试"],
        "pdf.preview.extracting": [.english: "Extracting tasks...", .chinese: "正在提取任务..."],
        "pdf.preview.subtasks": [.english: "subtasks", .chinese: "子任务"],
        "pdf.preview.completed": [.english: "completed", .chinese: "已完成"],
        "pdf.noTasks": [.english: "No tasks in this list", .chinese: "此列表中没有任务"],
        "pdf.scanNextPage": [.english: "Scan Next Page", .chinese: "扫描下一页"],
        "pdf.selectFromPDF": [.english: "Select from PDF", .chinese: "从PDF选择"],
        "pdf.selectFromPDF.hint": [.english: "Select a page, then draw a rectangle to extract tasks", .chinese: "选择页面，然后画框提取任务"],
        "pdf.addToList": [.english: "Add to List", .chinese: "添加到列表"],
        "pdf.importPDF": [.english: "Import PDF", .chinese: "导入PDF"],

        // MARK: - Image Scan/Import
        "image.scanTitle": [.english: "Scan Image", .chinese: "扫描图片"],
        "image.scanImage": [.english: "Scan Image", .chinese: "扫描图片"],
        "image.selectPrompt": [.english: "Select an Image", .chinese: "选择图片"],
        "image.selectDescription": [.english: "Choose an image containing your task list, notes, or to-do items", .chinese: "选择包含任务列表、笔记或待办事项的图片"],
        "image.selectButton": [.english: "Select from Photos", .chinese: "从相册选择"],
        "image.tipText": [.english: "Tip: Clear, well-lit images work best for text extraction", .chinese: "提示：清晰、光线充足的图片更易于提取文本"],
        "image.drawRectangle": [.english: "Draw a rectangle to select the area with tasks", .chinese: "画框选择包含任务的区域"],
        "image.selectionReady": [.english: "Selection ready! Tap Extract or use Full Image", .chinese: "选择完成！点击提取或使用整张图片"],
        "image.fullImage": [.english: "Full Image", .chinese: "整张图片"],
        "image.extractSelected": [.english: "Extract Selected", .chinese: "提取选中"],
        "image.defaultListName": [.english: "Image Tasks", .chinese: "图片任务"],
        "image.nameTaskList": [.english: "Name this task list", .chinese: "命名任务列表"],
        "image.taskListPlaceholder": [.english: "e.g., Meeting Notes", .chinese: "例如：会议笔记"],
        "image.section.title": [.english: "From Images", .chinese: "图片来源"],
        "image.sourceLabel": [.english: "From image", .chinese: "来自图片"],

        // Image Preview
        "image.preview.title": [.english: "Extracted Tasks", .chinese: "提取的任务"],
        "image.preview.tasksFound": [.english: "%d tasks found", .chinese: "找到%d个任务"],
        "image.preview.noTasksFound": [.english: "No tasks found", .chinese: "未找到任务"],
        "image.preview.noTasksMessage": [.english: "Try selecting a different area or use a clearer image.", .chinese: "尝试选择其他区域或使用更清晰的图片。"],
        "image.preview.editHint": [.english: "Tap to edit • Swipe to remove", .chinese: "点击编辑 • 滑动删除"],
        "image.preview.saveList": [.english: "Save List", .chinese: "保存列表"],
        "image.preview.tryAgain": [.english: "Try Again", .chinese: "重试"]
    ]
}

// MARK: - Helper Extension
extension View {
    func localized(_ key: String) -> String {
        LocalizationManager.shared.localize(key)
    }
}
