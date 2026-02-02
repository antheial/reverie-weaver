//  FeiFanClassLibrary.swift
//  ReverieWeaver
//
//  Rich content + Fei/Fan class library for Vitality Fei Strength Arc
//  ⚠️ SAMPLE PROGRAM: This is example content based on Keep app classes.
//
//  ⚠️ HEALTH DISCLAIMER:
//  This program is for informational purposes only and is not intended as medical advice.
//  Consult with a healthcare professional before beginning any exercise program.
//  Users assume all risks for any injury arising from use of these workouts.
//

import Foundation
import SwiftUI

// MARK: - Core Template

struct CoachClassTemplate: Identifiable, Hashable {
    enum Coach: String {
        case fei = "费教练"
        case fan = "范李猿"
    }

    enum Modality: String {
        case mobility
        case stretch
        case core
        case boxing
        case pilates
        case yoga
        case mixed
        case warmup
        case strength
        case cardio
        
        /// Returns a user-friendly display name for the modality
        var displayName: String {
            switch self {
            case .mobility: return "Mobility"
            case .stretch: return "Stretch"
            case .core: return "Core"
            case .boxing: return "Boxing"
            case .pilates: return "Pilates"
            case .yoga: return "Yoga"
            case .mixed: return "Mixed"
            case .warmup: return "Warm Up"
            case .strength: return "Strength"
            case .cardio: return "Cardio"
            }
        }
    }

    let id: UUID
    let coach: Coach
    let code: String
    let title: String
    let focusBodyPart: String
    let durationMinutes: Int
    let modality: Modality
    let notes: String
    let isSampleContent: Bool
    
    // Convenience initializer for user-created content (defaults to false)
    init(
        coach: Coach,
        code: String,
        title: String,
        focusBodyPart: String,
        durationMinutes: Int,
        modality: Modality,
        notes: String,
        isSampleContent: Bool = false
    ) {
        self.id = UUID()
        self.coach = coach
        self.code = code
        self.title = title
        self.focusBodyPart = focusBodyPart
        self.durationMinutes = durationMinutes
        self.modality = modality
        self.notes = notes
        self.isSampleContent = isSampleContent
    }
}


// MARK: - Phase Tags

enum FeiStrengthPhaseTag: Equatable {
    case aa   // Week 1: Anatomical Adaptation
    case hf   // Week 2: Hypertrophy Foundation
    case `in` // Week 3: Intensification
    case dl   // Week 4: Deload
    
    init(week: Int) {
        // Support cycling for programs that extend beyond 4 weeks
        let normalizedWeek = ((week - 1) % 4) + 1
        
        switch normalizedWeek {
        case 1: self = .aa
        case 2: self = .hf
        case 3: self = .in
        default: self = .dl // case 4 and fallback
        }
    }
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .aa: return "Anatomical Adaptation"
        case .hf: return "Hypertrophy Foundation"
        case .in: return "Intensification"
        case .dl: return "Deload"
        }
    }
    
    /// Week number in the cycle (1-4)
    var weekNumber: Int {
        switch self {
        case .aa: return 1
        case .hf: return 2
        case .in: return 3
        case .dl: return 4
        }
    }
}

// MARK: - Fei + Fan Course Library

enum FeiFanCourseLibrary {
    
    // 费教练 40min 主线力量课（你给的 6 节，全部保留）
    static let feiStrengthClasses: [CoachClassTemplate] = [
        CoachClassTemplate(
            coach: .fei,
            code: "fei-mon-shoulder-core",
            title: "6.30 周一 肩部核心",
            focusBodyPart: "肩部 + 核心",
            durationMinutes: 43,
            modality: .strength,
            notes: "【肩部】俯身上提、坐姿飞鸟、站姿推举、前平举、哑铃侧平举、哑铃提拉 + 【腹部】卷腹 + 坐姿举腿",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fei,
            code: "fei-tue-back-arms",
            title: "7.1 周二 背部手臂",
            focusBodyPart: "背部 + 手臂",
            durationMinutes: 40,
            modality: .strength,
            notes: "【背部】俯身飞鸟、划船、单臂划船、反向划船、山羊挺身 + 【手臂】仰卧臂屈伸 + 弯举",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fei,
            code: "fei-wed-glutes-legs-a",
            title: "7.2 周三 臀腿",
            focusBodyPart: "臀部 + 下肢",
            durationMinutes: 42,
            modality: .strength,
            notes: "臀桥、硬拉、保加利亚蹲、单腿硬拉为主，偏基础臀腿训练",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fei,
            code: "fei-thu-shoulder-chest",
            title: "7.3 周四 肩胸",
            focusBodyPart: "肩部 + 胸部",
            durationMinutes: 40,
            modality: .strength,
            notes: "跪姿俯卧撑 + 哑铃卧推配合站姿推举、前平举、侧平举和提拉，偏上肢推训练",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fei,
            code: "fei-fri-back-core",
            title: "7.4 周五 背部核心",
            focusBodyPart: "背部 + 核心",
            durationMinutes: 42,
            modality: .strength,
            notes: "背部划船、山羊挺身配合负重卷腹 + 坐姿举腿，兼顾背伸与腹部稳定",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fei,
            code: "fei-sat-glutes-legs-b",
            title: "7.5 周六 臀腿加强",
            focusBodyPart: "臀部 + 下肢",
            durationMinutes: 43,
            modality: .strength,
            notes: "臀桥、硬拉、保加利亚蹲 + 相扑深蹲，偏稍强一点的臀腿量",
            isSampleContent: true
        )
    ]
    
    // 范李猿课：从你给的 28 天计划中，选出覆盖面尽量全的一批课程
    // （可以后续按同样格式继续补充）
    static let fanClasses: [CoachClassTemplate] = [
        // 预备期 / 热身 & 拉伸
        CoachClassTemplate(
            coach: .fan,
            code: "fan-warmup-15",
            title: "15min 热身激活",
            focusBodyPart: "全身关节激活",
            durationMinutes: 15,
            modality: .warmup,
            notes: "适合作为任何力量/燃脂课前的全身动态热身",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-stretch-7-full",
            title: "7min 全身拉伸",
            focusBodyPart: "全身柔韧",
            durationMinutes: 7,
            modality: .stretch,
            notes: "短版全身拉伸，适合早晚或者训练后",
            isSampleContent: true
        ),
        // Day 1
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day1-3-vitality-wake",
            title: "13min 活力唤醒",
            focusBodyPart: "全身唤醒",
            durationMinutes: 13,
            modality: .warmup,
            notes: "偏基础的早晨唤醒课，RPE 3–4/10",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day1-4-back-pilates",
            title: "16min 背部普拉提",
            focusBodyPart: "背部 + 核心",
            durationMinutes: 16,
            modality: .pilates,
            notes: "温和加强背部、肩带和核心稳定",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day1-5-anti-anxiety",
            title: "10min 解郁操",
            focusBodyPart: "情绪舒缓 + 上肢活动",
            durationMinutes: 10,
            modality: .mobility,
            notes: "偏情绪舒缓和轻柔动作，适合压力大或经期前后",
            isSampleContent: true
        ),
        // 泰拳燃脂 & 套路
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day2-7-muaythai-burn",
            title: "15min 泰拳燃脂",
            focusBodyPart: "全身心肺 + 下肢",
            durationMinutes: 15,
            modality: .boxing,
            notes: "无器械搏击风格燃脂，RPE 6–7/10",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day3-9-muaythai-combo",
            title: "17min 泰拳套路",
            focusBodyPart: "全身心肺 + 核心",
            durationMinutes: 17,
            modality: .boxing,
            notes: "较完整的搏击套路，训练协调与心肺",
            isSampleContent: true
        ),
        // 动物流
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day3-10-animal-flow",
            title: "15min 动物流",
            focusBodyPart: "肩带 + 核心 + 髋",
            durationMinutes: 15,
            modality: .mobility,
            notes: "四足位移动为主，提升身体控制与灵活性",
            isSampleContent: true
        ),
        // 心肺提升 / 畅快暴汗 / 极限挑战 / 多阶燃脂 / 律动燃脂
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day4-11-cardio-easy",
            title: "15min 心肺提升（无跑跳）",
            focusBodyPart: "心肺耐力（低冲击）",
            durationMinutes: 16,
            modality: .cardio,
            notes: "无跑跳版本，适合膝盖不太好的日子",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day8-20-sweat-nonimpact",
            title: "25min 畅快暴汗（无跑跳）",
            focusBodyPart: "全身燃脂（低冲击）",
            durationMinutes: 30,
            modality: .cardio,
            notes: "中等时长、低冲击高出汗的燃脂课",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day9-23-max-nonimpact",
            title: "25min 极限挑战（无跑跳）",
            focusBodyPart: "中高强度全身燃脂（低冲击）",
            durationMinutes: 27,
            modality: .cardio,
            notes: "偏强烈的全身心肺，但仍然无跑跳",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day6-17-multi-step-cardio",
            title: "30min 多阶燃脂操",
            focusBodyPart: "全身阶梯燃脂",
            durationMinutes: 35,
            modality: .cardio,
            notes: "使用多阶步伐的有氧燃脂课，RPE 7/10 左右",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day5-14-rhythm-cardio",
            title: "20min 律动燃脂操",
            focusBodyPart: "音乐节奏 + 全身有氧",
            durationMinutes: 22,
            modality: .cardio,
            notes: "以律动跟拍为主的有氧课",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day5-15-combat-cardio",
            title: "30min 搏击操",
            focusBodyPart: "全身搏击风燃脂",
            durationMinutes: 30,
            modality: .boxing,
            notes: "搏击元素 + 有氧，适合作为偏爽感的暴汗日",
            isSampleContent: true
        ),
        // 柔韧 / 拉伸 / 恢复
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day7-18-leg-stretch",
            title: "腿部拉伸",
            focusBodyPart: "腿部柔韧",
            durationMinutes: 13,
            modality: .stretch,
            notes: "较完整的腿后侧、大腿前侧和臀部拉伸",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day7-19-upper-sitting",
            title: "久坐上肢拉伸",
            focusBodyPart: "颈肩 + 上背",
            durationMinutes: 13,
            modality: .stretch,
            notes: "针对久坐引起的上背紧张",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day22-63-sitting-stretch",
            title: "13min 坐姿拉伸",
            focusBodyPart: "全身温和拉伸",
            durationMinutes: 13,
            modality: .stretch,
            notes: "椅子上即可完成，适合作为 Deload 或休息日",
            isSampleContent: true
        ),
        // 塑形专项：核心/胸/肩/臀/腿/手臂
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day15-41-core-beginner",
            title: "18min 核心塑形（入门）",
            focusBodyPart: "腹部 + 核心",
            durationMinutes: 19,
            modality: .core,
            notes: "较友好的入门核心练习，适合腹线打基础",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day15-42-chest-beginner",
            title: "16min 胸部塑形（入门）",
            focusBodyPart: "胸大肌 + 上肢推",
            durationMinutes: 17,
            modality: .strength,
            notes: "温和的胸型塑形过渡课",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day16-45-shoulder-beginner",
            title: "17min 肩部塑形（入门）",
            focusBodyPart: "肩部线条",
            durationMinutes: 17,
            modality: .strength,
            notes: "提高肩部耐力和线条",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day16-46-back-beginner",
            title: "16min 背部塑形（入门）",
            focusBodyPart: "背部线条",
            durationMinutes: 16,
            modality: .strength,
            notes: "改善含胸、圆肩的背部塑形课",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day17-48-glutes-beginner",
            title: "15min 臀部塑形（入门）",
            focusBodyPart: "臀部",
            durationMinutes: 16,
            modality: .strength,
            notes: "基础臀桥、后踢等，适合配合 Fei 臀腿日一起用",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day18-51-legs-beginner",
            title: "16min 腿部塑形（入门）",
            focusBodyPart: "大腿前后 + 小腿",
            durationMinutes: 17,
            modality: .strength,
            notes: "低冲击腿部塑形，更偏耐力",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day19-53-arms-beginner",
            title: "16min 手臂塑形（入门）",
            focusBodyPart: "手臂线条",
            durationMinutes: 16,
            modality: .strength,
            notes: "手臂拜拜肉、三头肌和二头肌练习",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day22-60-core-standard",
            title: "18min 核心塑形（标准）",
            focusBodyPart: "腹线 + 腹横肌",
            durationMinutes: 19,
            modality: .core,
            notes: "强度略高，更靠近你想要的腹线",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day22-61-chest-standard",
            title: "16min 胸部塑形（标准）",
            focusBodyPart: "胸型 + 上躯干",
            durationMinutes: 16,
            modality: .strength,
            notes: "结合俯卧撑变化和哑铃推举的胸部塑形",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day23-64-shoulder-standard",
            title: "17min 肩部塑形（标准）",
            focusBodyPart: "肩线雕刻",
            durationMinutes: 17,
            modality: .strength,
            notes: "更高 RPE 的肩部塑形，适合第 3 周以后",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day23-65-back-standard",
            title: "16min 背部塑形（标准）",
            focusBodyPart: "背部线条 + 体态",
            durationMinutes: 16,
            modality: .strength,
            notes: "配合 Fei 背部日使用，增强立体感",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day24-67-glutes-standard",
            title: "15min 臀部塑形（标准）",
            focusBodyPart: "臀线提升",
            durationMinutes: 16,
            modality: .strength,
            notes: "偏中等强度，提高臀部紧致度和上翘感",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day25-70-legs-standard",
            title: "16min 腿部塑形（标准）",
            focusBodyPart: "腿部线条",
            durationMinutes: 16,
            modality: .strength,
            notes: "配合 Fei 下肢力量日，修饰腿部轮廓",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day26-72-arms-standard",
            title: "16min 手臂塑形（标准）",
            focusBodyPart: "手臂紧致",
            durationMinutes: 16,
            modality: .strength,
            notes: "更高重复与张力，针对手臂线条",
            isSampleContent: true
        ),
        // 其他：瑜伽 / 古法养生 / 拜日 A
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day19-55-yoga-sun-a",
            title: "30min 瑜伽拜日 A",
            focusBodyPart: "全身 + 呼吸",
            durationMinutes: 31,
            modality: .yoga,
            notes: "偏流动串联的瑜伽，适合恢复或轻有氧",
            isSampleContent: true
        ),
        CoachClassTemplate(
            coach: .fan,
            code: "fan-day26-74-gufa-health",
            title: "30min 古法养生操",
            focusBodyPart: "温和全身活动",
            durationMinutes: 32,
            modality: .mixed,
            notes: "节奏舒缓，适合 Deload 周和养生日",
            isSampleContent: true
        )
    ]
    
    // MARK: - Helper: 主线 Fei 课（根据周期 + 第几天，返回今天建议的 40min 力量课）
    
    static func feiMainClass(forWeek week: Int, cycleDay: Int) -> CoachClassTemplate? {
        // 简单规则：1/3/5/6 天为主线力量日，其它天为恢复或可选日
        switch cycleDay {
        case 1:
            // 上肢推 + 肩胸 为主
            return feiStrengthClasses.first { $0.code == "fei-thu-shoulder-chest" }
                ?? feiStrengthClasses.first { $0.code == "fei-mon-shoulder-core" }
                ?? feiStrengthClasses.first // Fallback to any Fei class
        case 3:
            // 臀腿 A
            return feiStrengthClasses.first { $0.code == "fei-wed-glutes-legs-a" }
                ?? feiStrengthClasses.first // Fallback
        case 5:
            // 背部 + 手臂 或 背核心轮换
            if week % 2 == 1 {
                return feiStrengthClasses.first { $0.code == "fei-tue-back-arms" }
                    ?? feiStrengthClasses.first // Fallback
            } else {
                return feiStrengthClasses.first { $0.code == "fei-fri-back-core" }
                    ?? feiStrengthClasses.first // Fallback
            }
        case 6:
            // 臀腿 B
            return feiStrengthClasses.first { $0.code == "fei-sat-glutes-legs-b" }
                ?? feiStrengthClasses.first // Fallback
        default:
            return nil
        }
    }
    
    // MARK: - Helper: 非 Fei 日，提供至少 4 节范李猿可选课（按周+日和周期强度筛选）
    
    static func fanOptionalClasses(forWeek week: Int, cycleDay: Int) -> [CoachClassTemplate] {
        let phase = FeiStrengthPhaseTag(week: week)
        
        // 基于周期的强度池子
        let aaPool = fanClasses.filter {
            // Week 1: 以 warmup / mobility / stretch / beginner 塑形 为主
            [.warmup, .mobility, .stretch, .pilates, .yoga].contains($0.modality)
        }
        
        let hfPool = fanClasses.filter {
            // Week 2: 适度增加核心 + 入门塑形
            [.warmup, .core, .strength, .cardio, .pilates].contains($0.modality)
        }
        
        let inPool = fanClasses.filter {
            // Week 3: 更多心肺/搏击 + 标准塑形
            [.cardio, .boxing, .core, .strength].contains($0.modality)
        }
        
        let dlPool = fanClasses.filter {
            // Week 4: 以拉伸、瑜伽、轻塑形为主
            [.stretch, .yoga, .mobility, .mixed, .core].contains($0.modality)
        }
        
        let basePool: [CoachClassTemplate]
        switch phase {
        case .aa: basePool = aaPool
        case .hf: basePool = hfPool
        case .in: basePool = inPool
        case .dl: basePool = dlPool
        }
        
        // 根据当天角色再微调一点
        let filtered: [CoachClassTemplate]
        switch cycleDay {
        case 1, 3, 5, 6:
            // 力量日：加一些核心 / 塑形 / 短有氧
            filtered = basePool.filter {
                [.core, .strength, .cardio, .warmup].contains($0.modality)
            }
        case 2, 4:
            // 关节灵活 / 轻有氧日
            filtered = basePool.filter {
                [.warmup, .mobility, .stretch, .pilates, .yoga].contains($0.modality)
            }
        case 7:
            // 恢复日：拉伸 + 瑜伽 + 古法养生
            filtered = basePool.filter {
                [.stretch, .yoga, .mixed, .mobility].contains($0.modality)
            }
        default:
            filtered = basePool
        }
        
        // 最少返回 4 节（如果不够就从 fanClasses 里补）
        var result = Array(filtered.prefix(4))
        
        // First fallback: try basePool if filtered is insufficient
        if result.count < 4 {
            let fromBase = basePool
                .filter { !result.contains($0) }
                .prefix(4 - result.count)
            result.append(contentsOf: fromBase)
        }
        
        // Final fallback: use any fanClasses to guarantee 4+ results
        if result.count < 4 {
            let filler = fanClasses
                .filter { !result.contains($0) }
                .prefix(4 - result.count)
            result.append(contentsOf: filler)
        }
        
        return result
    }
}

// MARK: - Rich Daily Script Builder
// 把「科学周期 + 课程信息 + 营养提示」拼成 Seed / Sprout / Bloom 文案

struct FeiStrengthRichContent {
    let title: String
    let focusArea: String
    let durationMinutes: Int
    let seed: String
    let sprout: String
    let bloom: String
    
    // MARK: - Structured Nutrition Guidance
    
    /// Returns structured nutrition advice for the given tier
    func nutritionGuidance(for tier: CompletionTier) -> NutritionGuidance {
        switch tier {
        case .seed:
            return NutritionGuidance(
                protein: "至少 1 餐有「手掌大小」的蛋白质（鸡蛋、豆腐、牛奶、酸奶等）",
                hydration: "至少 1 大杯水",
                timing: nil,
                recovery: "保证基础营养摄入"
            )
        case .sprout:
            return NutritionGuidance(
                protein: "今天尽量有 2 餐带蛋白（每餐 20–30g）",
                hydration: "充足水分摄入",
                timing: "睡前 2 小时减少重油重辣",
                recovery: "有助恢复和睡眠"
            )
        case .bloom:
            return NutritionGuidance(
                protein: "目标蛋白 ≈ 1.2–1.6g/kg 体重",
                hydration: "保持充足水分",
                timing: "训练后 2 小时内补一餐含蛋白 + 适量碳水",
                recovery: "多吃蔬菜水果，注意恢复"
            )
        }
    }
}

/// Structured nutrition guidance model
struct NutritionGuidance {
    let protein: String
    let hydration: String
    let timing: String?
    let recovery: String
    
    var formattedText: String {
        var text = "• 蛋白质：\(protein)\n• 水分：\(hydration)"
        if let timing = timing {
            text += "\n• 时机：\(timing)"
        }
        text += "\n• 恢复：\(recovery)"
        return text
    }
}

// MARK: - CompletionTier Extension

/// Extension to provide RPE (Rate of Perceived Exertion) guidance for workout tiers
extension CompletionTier {
    /// Returns the RPE range as a formatted string
    var rpeRange: String {
        switch self {
        case .seed: return "RPE 3–5/10"
        case .sprout: return "RPE 5–7/10"
        case .bloom: return "RPE 7–8/10"
        }
    }
    
    /// Returns user-friendly description of how the workout should feel
    var intensityDescription: String {
        switch self {
        case .seed:
            return "偏轻，主要是熟悉动作，让身体「上线」就好。"
        case .sprout:
            return "出汗、肌肉有点酸，但不会累到崩溃。"
        case .bloom:
            return "专注、干脆，但仍然可以自己踩刹车。"
        }
    }
}

enum FeiStrengthRichContentFactory {
    
    static func make(forWeek week: Int, cycleDay: Int) -> FeiStrengthRichContent {
        let phase = FeiStrengthPhaseTag(week: week)
        let fei = FeiFanCourseLibrary.feiMainClass(forWeek: week, cycleDay: cycleDay)
        let fanOptions = FeiFanCourseLibrary.fanOptionalClasses(forWeek: week, cycleDay: cycleDay)
        
        // 1) 标题 & focus
        let (title, focus, baseDuration) = titleFocusDuration(for: phase, week: week, cycleDay: cycleDay, fei: fei)
        
        // 2) 课程菜单文本
        let courseBlock = buildCourseBlock(fei: fei, fanOptions: fanOptions)
        
        // 3) 营养/恢复提示（按周期）
        let nutritionSeed   = nutritionHint(for: phase, level: "Seed")
        let nutritionSprout = nutritionHint(for: phase, level: "Sprout")
        let nutritionBloom  = nutritionHint(for: phase, level: "Bloom")
        
        // 4) Seed / Sprout / Bloom 主体文案（结合 RPE + 课程菜单 + 营养）
        let seed = """
        周\(week) · Day \(cycleDay) · \(phaseLabel(phase))（Seed）

        训练感觉：RPE 4–5/10，偏轻，主要是熟悉动作，让身体「上线」就好。

        \(courseBlock.seedIntro)

        \(courseBlock.sharedMenu)

        营养与恢复（Seed）：
        \(nutritionSeed)
        """
        
        let sprout = """
        周\(week) · Day \(cycleDay) · \(phaseLabel(phase))（Sprout）

        训练感觉：RPE 6–7/10，出汗、肌肉有点酸，但不会累到崩溃。

        \(courseBlock.sproutIntro)

        \(courseBlock.sharedMenu)

        营养与恢复（Sprout）：
        \(nutritionSprout)
        """
        
        let bloom = """
        周\(week) · Day \(cycleDay) · \(phaseLabel(phase))（Bloom）

        训练感觉：上限 RPE 7–8/10，专注、干脆，但仍然可以自己踩刹车。

        \(courseBlock.bloomIntro)

        \(courseBlock.sharedMenu)

        营养与恢复（Bloom）：
        \(nutritionBloom)
        """
        
        return FeiStrengthRichContent(
            title: title,
            focusArea: focus,
            durationMinutes: baseDuration,
            seed: seed.trimmingCharacters(in: .whitespacesAndNewlines),
            sprout: sprout.trimmingCharacters(in: .whitespacesAndNewlines),
            bloom: bloom.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    // MARK: - Phase Labels
    
    private static func phaseLabel(_ phase: FeiStrengthPhaseTag) -> String {
        switch phase {
        case .aa: return "Week 1 · 解锁身体（Anatomical Adaptation）"
        case .hf: return "Week 2 · 肌肉基础（Hypertrophy Foundation）"
        case .in: return "Week 3 · 强度加强（Intensification）"
        case .dl: return "Week 4 · 减量整合（Deload & Supercompensation）"
        }
    }
    
    // MARK: - Title / Focus / Duration
    
    private static func titleFocusDuration(
        for phase: FeiStrengthPhaseTag,
        week: Int,
        cycleDay: Int,
        fei: CoachClassTemplate?
    ) -> (String, String, Int) {
        switch phase {
        case .aa:
            switch cycleDay {
            case 1, 3, 5:
                return (
                    "Fei Strength · Week \(week) Full Body",
                    "动作学习 + 关节唤醒",
                    35
                )
            case 2, 4:
                return (
                    "Fei Strength · Week \(week) Active Recovery",
                    "循环 + 关节灵活",
                    20
                )
            case 6:
                return (
                    "Fei Strength · Week \(week) Glutes & Legs Prep",
                    "臀腿激活 + 体态调整",
                    fei?.durationMinutes ?? 35
                )
            case 7:
                return (
                    "Fei Strength · Week \(week) Recovery & Sleep",
                    "恢复 + 睡眠节律",
                    15
                )
            default:
                // 安全兜底（理论上不会走到）
                return (
                    "Fei Strength · Week \(week)",
                    "全身激活 + 关节灵活",
                    fei?.durationMinutes ?? 30
                )
            }
            
        case .hf:
            switch cycleDay {
            case 1, 3:
                return (
                    "Fei Strength · Week \(week) Upper Sculpt",
                    "肩胸背线条 + 核心稳定",
                    fei?.durationMinutes ?? 40
                )
            case 2, 4:
                return (
                    "Fei Strength · Week \(week) Lower Sculpt",
                    "臀腿力量 + 下肢耐力",
                    fei?.durationMinutes ?? 40
                )
            case 5, 6:
                return (
                    "Fei Strength · Week \(week) Core & Glutes",
                    "核心张力 + 臀部激活",
                    30
                )
            case 7:
                return (
                    "Fei Strength · Week \(week) Recovery & Protein",
                    "恢复 + 蛋白质摄入",
                    20
                )
            default:
                return (
                    "Fei Strength · Week \(week)",
                    "肌肉基础 + 线条塑形",
                    fei?.durationMinutes ?? 30
                )
            }
            
        case .in:
            switch cycleDay {
            case 1, 3:
                return (
                    "Fei Strength · Week \(week) Upper Intensification",
                    "上肢力量 + 推拉平衡",
                    fei?.durationMinutes ?? 40
                )
            case 2, 4:
                return (
                    "Fei Strength · Week \(week) Lower Intensification",
                    "臀腿力量 + 稍高负荷",
                    fei?.durationMinutes ?? 40
                )
            case 5:
                return (
                    "Fei Strength · Week \(week) Core & Rotation",
                    "旋转核心 + 反复张力",
                    25
                )
            case 6:
                return (
                    "Fei Strength · Week \(week) Glutes Focus",
                    "臀线打造 + 提升感",
                    fei?.durationMinutes ?? 40
                )
            case 7:
                return (
                    "Fei Strength · Week \(week) Recovery & HRV",
                    "恢复 + 自我疲劳监测",
                    20
                )
            default:
                return (
                    "Fei Strength · Week \(week)",
                    "强度加强 + 疲劳管理",
                    fei?.durationMinutes ?? 30
                )
            }
            
        case .dl:
            switch cycleDay {
            case 1, 3:
                return (
                    "Fei Strength · Week \(week) Light Full Body",
                    "轻量全身 + 技术整合",
                    30
                )
            case 2, 4:
                return (
                    "Fei Strength · Week \(week) Light Lower/Upper",
                    "轻量上下肢交替",
                    25
                )
            case 5:
                return (
                    "Fei Strength · Week \(week) Easy Core & Mobility",
                    "核心唤醒 + 灵活度",
                    20
                )
            case 6:
                return (
                    "Fei Strength · Week \(week) Gentle Glutes/Legs",
                    "低负荷臀腿 + 循环",
                    20
                )
            case 7:
                return (
                    "Fei Strength · Week \(week) Reflection & Planning",
                    "总结 + 规划下一轮",
                    15
                )
            default:
                return (
                    "Fei Strength · Week \(week) Deload",
                    "减量恢复 + 超量补偿",
                    20
                )
            }
        }
    }

    
    // MARK: - Course Block (Fei + Fan 菜单)
    
    private static func buildCourseBlock(
        fei: CoachClassTemplate?,
        fanOptions: [CoachClassTemplate]
    ) -> (seedIntro: String, sproutIntro: String, bloomIntro: String, sharedMenu: String) {
        
        let feiLine: String
        if let fei = fei {
            feiLine = """
            今天主线力量课（Fei）：
            • \(fei.coach.rawValue)《\(fei.title)》 · \(fei.durationMinutes)min · \(fei.focusBodyPart)
              \(fei.notes)
            """
        } else {
            feiLine = "今天没有必须完成的 40min Fei 主线课，你可以把重点放在「轻量动作 + 范李猿短课」上。"
        }
        
        let fanLines = fanOptions.map { option in
            "• \(option.coach.rawValue)《\(option.title)》 · \(option.durationMinutes)min · \(option.focusBodyPart)"
        }.joined(separator: "\n")
        
        let sharedMenu = """
        今日可选范李猿小课（任意选 1–2 节即可，加到今天的训练组合里）：
        \(fanLines)
        """
        
        // Seed / Sprout / Bloom 对 Fei 要求不同
        let seedIntro: String
        let sproutIntro: String
        let bloomIntro: String
        
        if fei == nil {
            seedIntro = """
            今天是「轻负荷/恢复」为主的日子。

            \(feiLine)

            建议：
            • Seed：只需要完成 1 节范李猿短课（或 10–15min 步行）即可打卡。
            """
            
            sproutIntro = """
            今天可以做一个「轻微出汗」的小组合。

            \(feiLine)

            建议：
            • Sprout：完成 1 节稍有强度的范李猿课 + 10min 拉伸/步行。
            """
            
            bloomIntro = """
            如果状态不错，可以稍微拉长一点时间，但仍保持低冲击。

            \(feiLine)

            建议：
            • Bloom：完成 1–2 节范李猿课（合计 20–30min）+ 5–10min 额外拉伸。
            """
        } else {
            seedIntro = """
            \(feiLine)

            建议：
            • Seed：完成 Fei 主课的 50–70% 即可（比如做到 20–25min），
              再根据体力加 0–1 节范李猿短课。
            """
            
            sproutIntro = """
            \(feiLine)

            建议：
            • Sprout：完整跟完 Fei 主课（40min 左右），
              如果还有余力，再从范李猿列表中加 1 节核心/拉伸课。
            """
            
            bloomIntro = """
            \(feiLine)

            建议：
            • Bloom：完整跟完 Fei 主课，
              再根据当天精力，从范李猿列表中加 1 节燃脂/塑形课（总时长控制在 60min 以内）。
            """
        }
        
        return (seedIntro: seedIntro,
                sproutIntro: sproutIntro,
                bloomIntro: bloomIntro,
                sharedMenu: sharedMenu)
    }
    
    // MARK: - Nutrition & Recovery Hints
    
    private static func nutritionHint(for phase: FeiStrengthPhaseTag, level: String) -> String {
        switch phase {
        case .aa:
            switch level {
            case "Seed":
                return "保证 1 餐有「手掌大小」的蛋白质（鸡蛋、豆腐、牛奶、酸奶等）+ 至少 1 大杯水。"
            case "Sprout":
                return "今天尽量有 2 餐带蛋白（每餐 20–30g），睡前 2 小时减少重油重辣，有助恢复和睡眠。"
            default:
                return "目标蛋白 ≈ 1.2–1.6g/kg 体重，多吃蔬菜水果，训练后 2 小时内补一餐含蛋白 + 适量碳水。"
            }
        case .hf:
            switch level {
            case "Seed":
                return "至少 2 餐带蛋白，训练前 1–2 小时小份碳水（米饭、面条、面包或水果）做「能量垫」。"
            case "Sprout":
                return "蛋白目标 ≈ 1.6–2.0g/kg，训练后 1 小时内吃一餐：主食 + 蛋白 + 蔬菜，减少奶茶和油炸。"
            default:
                return "今天可以安排 3 个「蛋白锚点」（早餐 / 午餐 / 训练后或睡前），每次 20–30g，保证肌肉修复所需原料。"
            }
        case .in:
            switch level {
            case "Seed":
                return "维持 2 餐蛋白 + 足量水，避免完全空腹上高强度课。"
            case "Sprout":
                return "可以在 Fei 主课前吃一小份易消化碳水（香蕉/面包），课后补蛋白 + 碳水，帮助恢复。"
            default:
                return "注意观察疲劳：如果连续几天很累、起床困难，可以适当减少 Bloom 级别的课，将一天降级成 Seed。"
            }
        case .dl:
            switch level {
            case "Seed":
                return "减量周不必刻意控得太严，只要维持基本蛋白 + 多喝水即可。"
            case "Sprout":
                return "稍微关注优质碳水（粗粮、根茎类）和蔬菜，多做温和饮食选择，让消化系统也一起休假。"
            default:
                return "可以趁这一周尝试调整作息和三餐时间，为下一轮周期建立更稳定的节奏。"
            }
        }
    }
}

// MARK: - Sample Program Badge UI

/// A badge indicating sample/demo content with multiple visual styles
struct SampleProgramBadge: View {
    var style: BadgeStyle = .default
    @Environment(\.colorScheme) private var colorScheme

    enum BadgeStyle {
        case `default`
        case compact
        case prominent
    }

    var body: some View {
        Group {
            switch style {
            case .default:
                defaultBadge
            case .compact:
                compactBadge
            case .prominent:
                prominentBadge
            }
        }
    }

    // Matches the "4-WEEK PROGRAM" category capsule style from HybridEditorialChallengeHeader
    private var defaultBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 11, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

            Text("SAMPLE PROGRAM")
                .font(.custom("Georgia", size: 10.5))
                .tracking(1.0)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.dynamicSecondaryLabel.opacity(colorScheme == .dark ? 0.08 : 0.05))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.dynamicSecondaryLabel.opacity(colorScheme == .dark ? 0.2 : 0.15), lineWidth: 0.5)
        )
    }
    
    private var compactBadge: some View {
        Text("Sample")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.orange.opacity(0.15))
            )
    }
    
    private var prominentBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle.fill")
                .font(.caption)
            Text("Example Content")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.orange.gradient)
        )
    }
}

// MARK: - View Extension for Sample Badge

extension View {
    /// Adds a "Sample Program" badge to the view if the content is marked as sample
    /// - Parameters:
    ///   - isSample: Whether to show the badge
    ///   - style: The visual style of the badge (default: .default)
    func sampleBadge(isSample: Bool, style: SampleProgramBadge.BadgeStyle = .default) -> some View {
        self.modifier(SampleBadgeModifier(isSample: isSample, style: style))
    }
}

private struct SampleBadgeModifier: ViewModifier {
    let isSample: Bool
    let style: SampleProgramBadge.BadgeStyle
    
    func body(content: Content) -> some View {
        if isSample {
            VStack(alignment: .leading, spacing: 4) {
                SampleProgramBadge(style: style)
                    .accessibilityLabel("This is example content from the Keep app")
                    .accessibilityAddTraits(.isStaticText)
                content
            }
        } else {
            content
        }
    }
}
