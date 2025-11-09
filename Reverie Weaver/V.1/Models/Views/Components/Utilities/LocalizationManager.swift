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
        "tab.archive": [.english: "Archive", .chinese: "归档"],
        "tab.profile": [.english: "Profile", .chinese: "个人"],
        
        // MARK: - Days of Week
        "day.monday": [.english: "Monday", .chinese: "星期一"],
        "day.tuesday": [.english: "Tuesday", .chinese: "星期二"],
        "day.wednesday": [.english: "Wednesday", .chinese: "星期三"],
        "day.thursday": [.english: "Thursday", .chinese: "星期四"],
        "day.friday": [.english: "Friday", .chinese: "星期五"],
        "day.saturday": [.english: "Saturday", .chinese: "星期六"],
        "day.sunday": [.english: "Sunday", .chinese: "星期日"],
        
        // MARK: - DeskView - Greetings
        "desk.greeting.morning": [.english: "Good Morning", .chinese: "早上好"],
        "desk.greeting.afternoon": [.english: "Good Afternoon", .chinese: "下午好"],
        "desk.greeting.evening": [.english: "Good Evening", .chinese: "晚上好"],
        "desk.greeting.night": [.english: "Good Night", .chinese: "晚安"],
        
        // MARK: - DeskView - Intention
        "desk.intention.prompt": [.english: "What will you weave today?", .chinese: "今天你想编织什么？"],
        "desk.intention.placeholder": [.english: "Set your intention for the day... what matters most to you today?", .chinese: "设定你今天的意图... 今天对你来说什么最重要？"],
        "desk.intention.tapToExpand": [.english: "Tap to expand", .chinese: "点击展开"],
        
        // MARK: - DeskView - Quick Actions
        "quickAction.title": [.english: "Quick Actions", .chinese: "快速行动"],
        "quickAction.completions": [.english: "completions", .chinese: "次完成"],
        "quickAction.readyToAdd": [.english: "You've completed this 3 times!", .chinese: "你已完成3次！"],
        "quickAction.suggestHabit": [.english: "Ready to make this a daily habit?", .chinese: "准备把这变成日常习惯吗？"],
        "quickAction.addHabit": [.english: "Yes, Add to My Daily Habits", .chinese: "是的，添加到我的桌面"],
        "quickAction.maybeLater": [.english: "Maybe Later", .chinese: "以后再说"],
        "quickAction.congratulations": [.english: "Congratulations!", .chinese: "恭喜！"],
        "quickAction.keepGoing": [.english: "Keep going!", .chinese: "继续加油！"],
        
        // MARK: - DeskView - Daily Habits
        "desk.habits.title": [.english: "Daily Habits", .chinese: "每日习惯"],
        "desk.habits.add": [.english: "Add", .chinese: "添加"],
        "desk.habits.empty": [.english: "Begin your journey by creating your first habit", .chinese: "创建你的第一个习惯，开始你的旅程"],
        "desk.habits.createFirst": [.english: "Create First Habit", .chinese: "创建第一个习惯"],
        
        // MARK: - DeskView - Progress
        "desk.progress.title": [.english: "Today's Weave", .chinese: "今日编织"],
        "desk.progress.habitsWoven": [.english: "%d/%d Habits Woven", .chinese: "%d/%d 个习惯已编织"],
        "desk.progress.percentage": [.english: "You're %d%% there! Keep going 🔥", .chinese: "你已完成 %d%%！继续加油 🔥"],
        "desk.progress.allComplete": [.english: "Perfect day woven! ⭐", .chinese: "完美的一天编织完成！⭐"],
        
        // MARK: - DeskView - Celebrations
        "desk.celebration.first": [.english: "🌱 First thread woven!", .chinese: "🌱 第一条线已编织！"],
        "desk.celebration.momentum": [.english: "🔥 Momentum building!", .chinese: "🔥 势头正盛！"],
        "desk.celebration.perfect": [.english: "⭐ Perfect day woven!", .chinese: "⭐ 完美的一天编织完成！"],
        
        // MARK: - Project 50 Overview
        "project50.title": [.english: "✨ Project 50", .chinese: "✨ Project 50"],
        "project50.subtitle": [.english: "8 Core Habits to Rebuild Momentum", .chinese: "8个核心习惯，重建动力"],
        "project50.subtitle2": [.english: "ADHD & Procrastinator-Friendly", .chinese: "适合注意力缺陷和拖延者"],

        "project50.section.philosophyTitle": [.english: "The Philosophy", .chinese: "理念"],
        "project50.section.philosophyDesc": [.english: "Based on the classic Project 50 challenge, this version focuses on small, repeatable wins. Discipline grows from structure, not rigidity — progress over perfection.", .chinese: "基于经典的Project 50挑战，此版本专注于小而可重复的胜利。自律源于结构，而非僵化——追求进步而非完美。"],

        "project50.section.scienceTitle": [.english: "The Science Behind Project 50", .chinese: "Project 50的科学基础"],
        "project50.section.scienceDesc": [.english: "Every habit here is designed to work with your brain, not against it. We start small to lower activation energy, repeat to strengthen neural pathways, and celebrate progress to boost dopamine feedback.", .chinese: "每个习惯都旨在与大脑协同，而非对抗。我们从小处开始以降低启动能量，通过重复强化神经通路，并通过庆祝进步增强多巴胺反馈。"],

        "project50.section.adhdTitle": [.english: "ADHD-Friendly Features", .chinese: "为 ADHD 思维设计的友好成长机制"],
        "project50.feature.lowActivation": [.english: "Lower activation energy — start tiny", .chinese: "降低启动难度——从微小行动开始"],
        "project50.feature.multiplePaths": [.english: "Multiple completion paths", .chinese: "多种完成路径"],
        "project50.feature.flexibleTime": [.english: "Flexible time ranges (not rigid)", .chinese: "灵活时间范围（不僵化）"],
        "project50.feature.progressTracking": [.english: "Built-in progress tracking", .chinese: "内置进度追踪"],
        "project50.feature.encouragement": [.english: "Encouragement, not guilt", .chinese: "鼓励而非内疚"],

        "project50.section.tipsTitle": [.english: "Tips for Success", .chinese: "成功提示"],
        "project50.tip.blockTime": [.english: "Block consistent time each day", .chinese: "每天预留固定时间"],
        "project50.tip.reflect": [.english: "Reflect briefly each night", .chinese: "每晚简短反思"],
        "project50.tip.momentum": [.english: "Don't chase perfect streaks — chase momentum", .chinese: "不要追求完美连续，而要追求持续动力"],
        "project50.tip.pairRoutines": [.english: "Pair new habits with existing routines", .chinese: "将新习惯与既有习惯配对"],

        "project50.button.start": [.english: "Start 50-Day Journey", .chinese: "开始50天旅程"],

        // MARK: - Project 50 Habits
        "project50.habit.rise": [.english: "Rise with Intention", .chinese: "有意识地起床"],
        "project50.habit.rise.desc": [.english: "Choose YOUR consistent wake time - not a rigid hour. Even 15 minutes earlier counts as progress.", .chinese: "选择适合你的起床时间——不需固定。哪怕提前15分钟都是进步。"],
        "project50.habit.rise.time": [.english: "Discipline Builder", .chinese: "自律养成"],

        "project50.habit.anchor": [.english: "Morning Anchor Ritual", .chinese: "晨间锚定仪式"],
        "project50.habit.anchor.desc": [.english: "Pick 1-3 actions: make bed, journal, stretch, or plan your day. Start small and build momentum.", .chinese: "选择1-3个行动：整理床铺、写日记、伸展或规划一天。从小开始，积累动力。"],
        "project50.habit.anchor.time": [.english: "10-30 min", .chinese: "10-30分钟"],

        "project50.habit.move": [.english: "Move Your Body", .chinese: "动起来"],
        "project50.habit.move.desc": [.english: "20 min minimum — walk, dance, yoga, or gym. Move however you can.", .chinese: "至少20分钟：散步、跳舞、瑜伽或健身。用你喜欢的方式动起来。"],
        "project50.habit.move.time": [.english: "20-60 min", .chinese: "20-60分钟"],

        "project50.habit.hydrate": [.english: "Hydration Habit", .chinese: "补水习惯"],
        "project50.habit.hydrate.desc": [.english: "Drink 6–8 glasses throughout the day. Keep water visible.", .chinese: "每天喝6–8杯水。让水保持在视线内。"],
        "project50.habit.hydrate.time": [.english: "Throughout day", .chinese: "整天"],

        "project50.habit.feedmind": [.english: "Feed Your Mind (10 Pages)", .chinese: "滋养你的思维（10页）"],
        "project50.habit.feedmind.desc": [.english: "Read 10 pages daily — non-fiction or self-growth. Audiobooks count!", .chinese: "每天阅读10页——非虚构或成长类书籍。听书也算！"],
        "project50.habit.feedmind.time": [.english: "10-15 min", .chinese: "10-15分钟"],

        "project50.habit.deepwork": [.english: "Deep Work Hour", .chinese: "深度专注时段"],
        "project50.habit.deepwork.desc": [.english: "1 hour on a skill or goal. Study, write, code — focus time that matters.", .chinese: "专注1小时提升技能或目标。学习、写作、编程——重要的专注时间。"],
        "project50.habit.deepwork.time": [.english: "60 min (flexible)", .chinese: "60分钟（灵活）"],

        "project50.habit.eatintent": [.english: "Eat with Intention", .chinese: "有意识地饮食"],
        "project50.habit.eatintent.desc": [.english: "Not strict dieting — just mindful eating. Avoid ultra-processed foods today.", .chinese: "不需要严格节食——只是有意识地进食。今天尽量避免加工食品。"],
        "project50.habit.eatintent.time": [.english: "Ongoing mindset", .chinese: "持续心态"],

        "project50.habit.eveningdump": [.english: "Evening Brain Dump", .chinese: "夜间清空思绪"],
        "project50.habit.eveningdump.desc": [.english: "Reflect in 3+ sentences. What worked? What’s next? Build awareness and gratitude.", .chinese: "写3句以上反思：今天哪些顺利？下一步是什么？培养觉察与感恩。"],
        "project50.habit.eveningdump.time": [.english: "5-10 min", .chinese: "5-10分钟"],

        "project50.section.morning": [.english: "Morning Anchors", .chinese: "晨间锚点"],
        "project50.section.energy": [.english: "Body & Energy", .chinese: "身体与能量"],
        "project50.section.cognitive": [.english: "Cognitive Anchors", .chinese: "认知锚点"],
        "project50.section.reflection": [.english: "Reflection", .chinese: "反思时刻"],

        
        // MARK: - Micro Habits - Morning
        "micro.morning.curtains": [.english: "Open curtains + 3 deep breaths", .chinese: "拉开窗帘 + 深呼吸3次"],
        "micro.morning.bed": [.english: "Make bed + smile at yourself", .chinese: "整理床铺 + 对自己微笑"],
        "micro.morning.water": [.english: "Drink 1 glass of water", .chinese: "喝一杯水"],
        "micro.morning.stretch": [.english: "Stretch for 2 minutes", .chinese: "伸展2分钟"],
        "micro.morning.gratitude": [.english: "Write 1 gratitude sentence", .chinese: "写一句感恩的话"],
        "micro.morning.read": [.english: "Read 1 page", .chinese: "读1页书"],
        "micro.morning.tidy": [.english: "Tidy one surface", .chinese: "整理一个桌面"],
        "micro.morning.meditate": [.english: "2-minute morning meditation", .chinese: "2分钟晨间冥想"],
        "micro.morning.write": [.english: "Write morning intention (1 sentence)", .chinese: "写晨间意图（一句话）"],
        "micro.morning.yoga": [.english: "Do 5 minutes of gentle yoga", .chinese: "做5分钟温和瑜伽"],
        "micro.morning.affirmations": [.english: "Speak positive affirmations", .chinese: "说积极的肯定语"],
        "micro.morning.podcast": [.english: "Listen to an educational podcast", .chinese: "听教育播客"],
        "micro.morning.sketch": [.english: "Sketch or draw for 3 minutes", .chinese: "素描或画画3分钟"],
        "micro.morning.message": [.english: "Send a thoughtful message", .chinese: "发送一条温馨的消息"],
        
        // MARK: - Micro Habits - Afternoon
        "micro.afternoon.walk": [.english: "5-minute walk outside", .chinese: "户外散步5分钟"],
        "micro.afternoon.jumping": [.english: "10 jumping jacks", .chinese: "开合跳10次"],
        "micro.afternoon.fruit": [.english: "Eat 1 piece of fruit", .chinese: "吃一个水果"],
        "micro.afternoon.meditate": [.english: "2-minute meditation", .chinese: "冥想2分钟"],
        "micro.afternoon.text": [.english: "Text someone you appreciate", .chinese: "给你感激的人发消息"],
        "micro.afternoon.learn": [.english: "Learn 1 new word/fact", .chinese: "学习一个新词/事实"],
        "micro.afternoon.doodle": [.english: "Doodle for 3 minutes", .chinese: "涂鸦3分钟"],
        "micro.afternoon.stretch": [.english: "3-minute desk stretching", .chinese: "3分钟办公桌伸展"],
        "micro.afternoon.posture": [.english: "Check and correct your posture", .chinese: "检查和纠正姿势"],
        "micro.afternoon.breathwork": [.english: "Practice breathwork exercises", .chinese: "练习呼吸法"],
        "micro.afternoon.language": [.english: "Practice a new language", .chinese: "练习一门新语言"],
        "micro.afternoon.music": [.english: "Play music or sing", .chinese: "演奏音乐或唱歌"],
        "micro.afternoon.call": [.english: "Make a quick call to connect", .chinese: "打电话联系他人"],
        
        // MARK: - Micro Habits - Evening
        "micro.evening.putaway": [.english: "Put away 5 items", .chinese: "收拾5样东西"],
        "micro.evening.plan": [.english: "Plan tomorrow (3 min)", .chinese: "计划明天（3分钟）"],
        "micro.evening.journal": [.english: "Journal 1 sentence", .chinese: "写一句日记"],
        "micro.evening.hygiene": [.english: "Wash face + brush teeth", .chinese: "洗脸 + 刷牙"],
        "micro.evening.stretch": [.english: "Gentle stretching", .chinese: "温和伸展"],
        "micro.evening.clothes": [.english: "Prepare clothes for tomorrow", .chinese: "准备明天的衣服"],
        "micro.evening.read": [.english: "Read before bed (5 min)", .chinese: "睡前阅读（5分钟）"],
        "micro.evening.gratitude": [.english: "Write 3 things you're grateful for", .chinese: "写下3件感恩的事"],
        "micro.evening.selfmassage": [.english: "Give yourself a hand or foot massage", .chinese: "给自己做手部或足部按摩"],
        "micro.evening.visualization": [.english: "Visualize tomorrow's success", .chinese: "想象明天的成功"],
        "micro.evening.draw": [.english: "Draw or paint for 5 minutes", .chinese: "画画或涂色5分钟"],
        "micro.evening.article": [.english: "Read an interesting article", .chinese: "阅读一篇有趣的文章"],
        "micro.evening.family": [.english: "Spend quality time with family", .chinese: "与家人共度美好时光"],
        
        // MARK: - Micro Habits - Night
        "micro.night.breathing": [.english: "Square breathing (4-4-4-4)", .chinese: "方形呼吸（4-4-4-4）"],
        "micro.night.write": [.english: "Write down 1 thought", .chinese: "写下一个想法"],
        "micro.night.neck": [.english: "Gentle neck rolls", .chinese: "温和的颈部转动"],
        "micro.night.tea": [.english: "Drink herbal tea", .chinese: "喝茶"],
        "micro.night.reflect": [.english: "Reflect on today (2 min)", .chinese: "反思今天（2分钟）"],
        "micro.night.bodyscan": [.english: "Do a body scan meditation", .chinese: "做身体扫描冥想"],
        "micro.night.eyerelax": [.english: "Relax your eyes", .chinese: "放松眼睛"],
        "micro.night.dreamjournal": [.english: "Write in your dream journal", .chinese: "写梦境日记"],
        
        // MARK: - Duration Labels
        "micro.duration.1min": [.english: "1 min", .chinese: "1分钟"],
        "micro.duration.2min": [.english: "2 min", .chinese: "2分钟"],
        "micro.duration.3min": [.english: "3 min", .chinese: "3分钟"],
        "micro.duration.5min": [.english: "5 min", .chinese: "5分钟"],
        
        // MARK: - Archive
        "archive.title": [.english: "Archive", .chinese: "归档"],
        "archive.weekly": [.english: "Weekly", .chinese: "每周"],
        "archive.monthly": [.english: "Monthly", .chinese: "每月"],
        "archive.achievements": [.english: "Achievements", .chinese: "成就"],
        "archive.weekSummary": [.english: "Week Summary", .chinese: "本周总结"],
        "archive.threadsWoven": [.english: "Threads Woven", .chinese: "已编织"],
        "archive.completion": [.english: "Completion", .chinese: "完成率"],
        "archive.favorites": [.english: "Favorites", .chinese: "收藏"],
        "archive.topHabits": [.english: "Top Habits This Week", .chinese: "本周最佳习惯"],
        "archive.topHabitsMonth": [.english: "Top Habits This Month", .chinese: "本月最佳习惯"],
        "archive.timesCompleted": [.english: "times completed", .chinese: "次完成"],
        "archive.dailyIntentions": [.english: "Daily Intentions", .chinese: "每日意图"],
        "archive.noIntentions": [.english: "No intentions set this week", .chinese: "本周没有设定意图"],
        "archive.monthSummary": [.english: "Summary", .chinese: "总结"],
        "archive.totalThreads": [.english: "Total Threads", .chinese: "总编织数"],
        "archive.perfectDays": [.english: "Perfect Days", .chinese: "完美天数"],
        "archive.activityHeatmap": [.english: "Activity Heatmap", .chinese: "活动热图"],
        "archive.noAchievements": [.english: "No achievements yet", .chinese: "暂无成就"],
        "archive.achievementHint": [.english: "Complete all your habits in one day to earn your first achievement!", .chinese: "完成一天内所有习惯来获得你的第一个成就！"],
        "archive.earned": [.english: "Earned", .chinese: "获得于"],
        
        // MARK: - Profile
        "profile.title": [.english: "Profile", .chinese: "个人资料"],
        "profile.displayName": [.english: "Display Name", .chinese: "显示名称"],
        "profile.namePlaceholder": [.english: "Your name", .chinese: "你的名字"],
        "profile.yourJourney": [.english: "Your Journey", .chinese: "你的旅程"],
        "profile.dayStreak": [.english: "Day Streak", .chinese: "连续天数"],
        "profile.completed": [.english: "Completed", .chinese: "已完成"],
        "profile.achievements": [.english: "Achievements", .chinese: "成就"],
        "profile.perfectDays": [.english: "Perfect Days", .chinese: "完美天数"],
        "profile.activeHabits": [.english: "Active Habits", .chinese: "活跃习惯"],
        "profile.personalIntention": [.english: "Personal Intention", .chinese: "个人意图"],
        "profile.intentionPrompt": [.english: "What drives your journey?", .chinese: "是什么驱动着你的旅程？"],
        "profile.mottoPlaceholder": [.english: "Enter your personal motto or intention...", .chinese: "输入你的个人座右铭或意图..."],
        "profile.preferences": [.english: "Preferences", .chinese: "偏好设置"],
        "profile.weekStartSunday": [.english: "Week Starts on Sunday", .chinese: "周从星期日开始"],
        "profile.weekStartDesc": [.english: "Changes how weekly stats are calculated", .chinese: "改变每周统计的计算方式"],
        "profile.language": [.english: "Language", .chinese: "语言"],
        "profile.languageDesc": [.english: "Choose your preferred language", .chinese: "选择你的首选语言"],
        "profile.dataManagement": [.english: "Data Management", .chinese: "数据管理"],
        "profile.exportData": [.english: "Export Reflections", .chinese: "导出数据"],
        "profile.icloudBackup": [.english: "iCloud Backup: Enabled", .chinese: "iCloud 备份：已启用"],
        "profile.icloudDesc": [.english: "Your data is automatically backed up to iCloud and will sync across your devices.", .chinese: "你的数据会自动备份到 iCloud 并在你的设备间同步。"],
        "profile.dataExported": [.english: "Data Exported", .chinese: "数据已导出"],
        "profile.exportSuccess": [.english: "Your habit data has been exported successfully.", .chinese: "你的习惯数据已成功导出。"],
        "profile.ok": [.english: "OK", .chinese: "确定"],
        "profile.support": [.english: "Support & Feedback", .chinese: "支持与反馈"],
        "profile.rateApp": [.english: "Rate ReverieWeaver", .chinese: "评价 ReverieWeaver"],
        "profile.sendFeedback": [.english: "Send Feedback", .chinese: "发送反馈"],
        "profile.version": [.english: "Version", .chinese: "版本"],
        
        // MARK: - Storage Management
        "storage.title": [.english: "Storage Management", .chinese: "存储管理"],
        "storage.dataSize": [.english: "App Data Size", .chinese: "应用数据大小"],
        "storage.textData": [.english: "Text Data", .chinese: "文本数据"],
        "storage.photos": [.english: "Photos", .chinese: "照片"],
        "storage.completions": [.english: "Completions", .chinese: "完成记录"],
        "storage.clearOld": [.english: "Clear Data Older Than 1 Year", .chinese: "清除一年前的数据"],
        "storage.clearDesc": [.english: "Clearing old data removes reflections and photos from over a year ago.", .chinese: "清除旧数据会删除一年前的反思和照片。"],
        
        // MARK: - Create/Edit Habit
        "habit.create": [.english: "Create New Habit", .chinese: "创建新习惯"],
        "habit.name": [.english: "Habit Name", .chinese: "习惯名称"],
        "habit.namePlaceholder": [.english: "e.g., Morning Meditation", .chinese: "例如：早晨冥想"],
        "habit.description": [.english: "Description (optional)", .chinese: "描述（可选）"],
        "habit.descPlaceholder": [.english: "What does this habit mean to you?", .chinese: "这个习惯对你意味着什么？"],
        "habit.completionMessage": [.english: "Completion Message (optional)", .chinese: "完成消息（可选）"],
        "habit.messagePlaceholder": [.english: "e.g., Thread woven - you've honored your morning", .chinese: "例如：线已织入 - 你尊重了你的早晨"],
        "habit.category": [.english: "Category", .chinese: "类别"],
        "habit.icon": [.english: "Icon", .chinese: "图标"],
        "habit.threadColor": [.english: "Thread Color", .chinese: "线的颜色"],
        "habit.frequency": [.english: "Frequency", .chinese: "频率"],
        "habit.daily": [.english: "Daily", .chinese: "每日"],
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
        "category.morningRituals.desc": [.english: "Start your day with intention", .chinese: "有意识地开始你的一天"],
        "category.healthFoundations.desc": [.english: "Build physical & mental wellness", .chinese: "建立身心健康"],
        "category.mindfulLiving.desc": [.english: "Cultivate presence & awareness", .chinese: "培养当下与觉察"],
        "category.creativePractice.desc": [.english: "Nurture your creative spirit", .chinese: "滋养你的创造精神"],
        "category.connection.desc": [.english: "Strengthen relationships", .chinese: "加强人际关系"],
        
        // MARK: - Habit Library
        "library.title": [.english: "Habit Library", .chinese: "习惯库"],
        "library.subtitle": [.english: "Discover habits to weave into your life", .chinese: "发现编织进你生活的习惯"],
        "library.browse": [.english: "Browse Library", .chinese: "浏览库"],
        "library.addToDesk": [.english: "Add", .chinese: "添加"],
        "library.benefits": [.english: "Benefits", .chinese: "好处"],
        "library.tips": [.english: "Tips", .chinese: "提示"],
        "library.frequency": [.english: "Suggested Frequency", .chinese: "建议频率"],
        "library.estimatedTime": [.english: "Estimated Time", .chinese: "预计时间"],
        "library.description": [.english: "Description", .chinese: "描述"],
        "library.allCategories": [.english: "All Categories", .chinese: "所有类别"],
        "library.habitAdded": [.english: "Habit Added!", .chinese: "习惯已添加！"],
        "library.habitAddedDesc": [.english: "You can find it on your Daily Habits", .chinese: "你可以在桌面找到它"],
        
        // MARK: - Reflection
        "reflection.title": [.english: "Reflect on", .chinese: "反思"],
        "reflection.prompt": [.english: "How are you different after completing this?", .chinese: "完成后你有什么不同？"],
        "reflection.howFeel": [.english: "How did it feel?", .chinese: "感觉如何？"],
        "reflection.thoughts": [.english: "Your Thoughts", .chinese: "你的想法"],
        "reflection.thoughtsPlaceholder": [.english: "Write what comes to mind...", .chinese: "写下你的想法..."],
        "reflection.addPhoto": [.english: "Add a Photo (optional)", .chinese: "添加照片（可选）"],
        "reflection.photoPrompt": [.english: "Tap to add photo", .chinese: "点击添加照片"],
        "reflection.favorite": [.english: "Mark as favorite for archive", .chinese: "标记为收藏以便归档"],
        "reflection.skip": [.english: "Skip", .chinese: "跳过"],
        "reflection.save": [.english: "Save Reflection", .chinese: "保存反思"],
        
        // MARK: - Moods
        "mood.energized": [.english: "Energized", .chinese: "充满活力"],
        "mood.calm": [.english: "Calm", .chinese: "平静"],
        "mood.neutral": [.english: "Neutral", .chinese: "中性"],
        "mood.tired": [.english: "Tired", .chinese: "疲倦"],
        "mood.stressed": [.english: "Stressed", .chinese: "有压力"],
        "mood.peaceful": [.english: "Peaceful", .chinese: "平和"],
        "mood.focused": [.english: "Focused", .chinese: "专注"],
        "mood.grateful": [.english: "Grateful", .chinese: "感恩"],
        "mood.hopeful": [.english: "Hopeful", .chinese: "充满希望"],
        "mood.action": [.english: "Action", .chinese: "行动"],
        
        // MARK: - Frequency Options
        "frequency.daily": [.english: "Daily", .chinese: "每日"],
        "frequency.weekly": [.english: "3x per week", .chinese: "每周3次"],
        "frequency.twiceWeekly": [.english: "2x per week", .chinese: "每周2次"],
        "frequency.weekdays": [.english: "Weekdays", .chinese: "工作日"],
        "frequency.thriceDaily": [.english: "3x daily", .chinese: "每日3次"],
        
        // MARK: - Floating Add Button
        "floatingAdd.quickAdd": [.english: "Quick Add", .chinese: "快速添加"],
        "floatingAdd.createHabit": [.english: "Create Habit", .chinese: "创建习惯"],
        "floatingAdd.browseLibrary": [.english: "Browse Library", .chinese: "浏览库"],
        "floatingAdd.title": [.english: "Add a Habit", .chinese: "添加习惯"],
        
        // MARK: - Common
        "common.of": [.english: "of", .chinese: "共"],
        "common.weekOf": [.english: "Week of", .chinese: "周"]
    ]
}

// MARK: - Helper Extension
extension View {
    func localized(_ key: String) -> String {
        LocalizationManager.shared.localize(key)
    }
}
