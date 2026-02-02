//
//  VitalityArcRichContentFactory.swift
//  ReverieWeaver
//
//  Rich, beginner-friendly home workouts for the 8-week Vitality Arc.
//  Mirrors the structure of FeiStrengthRichContentFactory, but for
//  the standard Vitality program (Awaken → Ignite → Sculpt → Flow).
//
//  Usage (inside VitalityData.createDay):
//    let rich = VitalityArcRichContentFactory.make(forDay: number, phase: phase)
//    return VitalityDay(
//       dayNumber: number,
//       phase: phase,
//       title: rich.title,
//       focusArea: rich.focusArea,
//       duration: rich.durationMinutes,
//       seedOption: rich.seed,
//       sproutOption: rich.sprout,
//       bloomOption: rich.bloom
//    )
//

import Foundation

// MARK: - Script Model

struct VitalityArcDayScript {
    let title: String
    let focusArea: String
    let durationMinutes: Int
    let seed: String
    let sprout: String
    let bloom: String
}

// MARK: - Factory

enum VitalityArcRichContentFactory {
    
    static func make(forDay dayNumber: Int, phase: VitalityPhase) -> VitalityArcDayScript {
        let cycleDay = ((dayNumber - 1) % 7) + 1 // 1…7 within week
        
        switch phase {
        case .activation:
            return activationScript(for: cycleDay)
        case .endurance:
            return enduranceScript(for: cycleDay)
        case .strength:
            return strengthScript(for: cycleDay)
        case .integration:
            return integrationScript(for: cycleDay)
        }
    }
}

// MARK: - PHASE 1 · AWAKEN (Weeks 1–2)

private extension VitalityArcRichContentFactory {
    
    static func activationScript(for cycleDay: Int) -> VitalityArcDayScript {
        switch cycleDay {
        // LOWER BODY FOUNDATION – GLUTES & HIPS
        case 1, 5:
            return VitalityArcDayScript(
                title: "Lower Body Foundation",
                focusArea: "Glutes & Hips",
                durationMinutes: 22,
                seed: """
                Who it's for:
                Days when you feel low energy, stiff from sitting, or just getting started again.

                The Plan (8–10 min):
                · 2～3 轮：
                  · 徒手深蹲 8～10 次（可坐椅子再站起来）
                  · 臀桥 10～12 次（仰卧，脚踩地，卷尾骨抬臀）
                · 每轮之间休息 45～60 秒。

                How it should feel:
                RPE 3～4/10。关节被温柔唤醒，腿和屁股有轻微热感，不会累到崩溃。
                """,
                sprout: """
                Who it's for:
                标准训练日。想让腿和屁股线条更紧致，又不想太极限。

                The Plan (15～18 min):
                · 热身 2 分钟：原地踏步 + 轻微摆臂
                · 3 轮：
                  · 徒手深蹲 10～12 次
                  · 臀桥 12～15 次
                  · 站姿侧抬腿 每侧 10 次
                · 每轮之间休息 45 秒。

                How it should feel:
                RPE 5～6/10。最后一轮有明显酸胀，但第二天还能正常走路上下楼。
                """,
                bloom: """
                Who it's for:
                精力比较好，想多练一点臀腿，让线条更明显。

                The Plan (18～22 min):
                · 热身 3 分钟：髋关节绕圈、腿部摆动
                · 3～4 轮：
                  · 高脚杯深蹲 10～12 次（抱水瓶或哑铃于胸前）
                  · 行走弓步 每腿 10 步
                  · 单腿臀桥 每侧 10 次
                · 每轮休息 60 秒，注意呼吸和动作深度。

                How it should feel:
                RPE 7/10 左右。臀部和大腿有扎实的疲劳感，但膝盖安全、腰部没有不适。
                """
            )
            
        // UPPER BODY FOUNDATION – PUSH & POSTURE
        case 2, 6:
            return VitalityArcDayScript(
                title: "Upper Body Foundation",
                focusArea: "胸肩手臂 + 体态",
                durationMinutes: 22,
                seed: """
                Who it's for:
                小白、手臂没什么力气、或者驼背严重的人。

                The Plan (8～10 min):
                · 2～3 轮：
                  · 墙上俯卧撑 6～8 次（身体呈一条直线）
                  · 站姿划船 10 次（弹力带或装水的购物袋）
                  · 坐姿肩胛骨挤压 10～12 次（双手放大腿，想象夹一支笔）
                · 每轮休息 45～60 秒。

                How it should feel:
                RPE 3～4/10。上背有轻微收紧感，肩颈反而更放松。
                """,
                sprout: """
                Who it's for:
                想认真练上肢力量，又怕动作太难撑不住的人。

                The Plan (15～18 min):
                · 热身 2 分钟：手臂绕圈、肩部前后绕环
                · 3 轮：
                  · 斜板俯卧撑 8～10 次（靠桌子/台面）
                  · 站姿划船 12 次
                  · 哑铃或水瓶侧平举 10 次
                · 每轮休息 45 秒，保持动作控制，不要借力甩手。

                How it should feel:
                RPE 5～6/10。最后一轮俯卧撑会有点抖，但还能保持挺胸收紧腹部。
                """,
                bloom: """
                Who it's for:
                想要一点“上身训练日”的感觉，练出更挺的胸和更直的背。

                The Plan (18～22 min):
                · 热身 3 分钟：猫牛式、胸椎旋转
                · 3～4 轮：
                  · 跪姿俯卧撑 10～12 次（或标准俯卧撑 6～8 次）
                  · 俯身哑铃划船 每侧 10 次
                  · 哑铃或水瓶肩推 10 次
                · 每轮休息 60 秒，专注缓慢下放，感受肌肉控制。

                How it should feel:
                RPE 7/10。胸肩手臂有明显充血感，体态更挺拔，心情也会被拉直一点。
                """
            )
            
        // GENTLE CARDIO & MOBILITY – WAKE THE SYSTEM
        case 3:
            return VitalityArcDayScript(
                title: "Gentle Cardio & Mobility",
                focusArea: "全身循环 + 关节活动度",
                durationMinutes: 20,
                seed: """
                Who it's for:
                睡不醒、身体僵硬，但又不想完全躺平的日子。

                The Plan (8～10 min):
                · 轻度热身：原地踏步 2 分钟
                · 2～3 轮舒展流动：
                  · 猫牛式 6 次
                  · 世界上最棒的拉伸 每侧 4 次
                  · 髋关节绕圈 每侧 6 圈
                · 全程保持顺畅鼻吸口呼。

                How it should feel:
                RPE 3/10。像慢慢被“解冻”，身体更轻一点，脑子也清醒一点。
                """,
                sprout: """
                Who it's for:
                想稍微出点汗，又不想做太难动作的人。

                The Plan (15～18 min):
                · 原地快走/小步跑 3 分钟
                · 3 轮：
                  · 开合跳 15～20 次（或低冲击左右点步）
                  · 空气深蹲 12 次
                  · 手臂绕圈 前后各 10 次
                · 每轮之间原地慢走 45 秒。

                How it should feel:
                RPE 5/10。心率温和上升，脸颊微微发红，结束后有“血液流动起来了”的感觉。
                """,
                bloom: """
                Who it's for:
                想明显提高心率，让整个人“上线”的日子。

                The Plan (18～22 min):
                · 3 分钟动态热身：高抬腿、后踢腿、侧弓步
                · 4 轮简单 HIIT：
                  · 30 秒 开合跳或低冲击跳
                  · 30 秒 空气深蹲
                  · 30 秒 快走或小跑恢复
                · 轮与轮之间额外休息 30 秒，根据心率调整。

                How it should feel:
                RPE 7/10。呼吸明显加快，但仍能说短句；结束后有畅快、舒展的疲惫感。
                """
            )
            
        // CORE ACTIVATION – DEEP CORE
        case 4:
            return VitalityArcDayScript(
                title: "Core Activation",
                focusArea: "Deep Core",
                durationMinutes: 15,
                seed: """
                Who it's for:
                腰容易酸、核心很弱，或者刚重新开始运动的人。

                The Plan (5～8 min):
                · 3～4 轮：
                  · Dead bug 6～8 次（慢慢换脚换手）
                  · Bird-dog 每侧 6～8 次（四点跪姿伸手伸腿）
                · 全程保持下背轻轻贴向地面或稳定。

                How it should feel:
                RPE 3～4/10。感觉腹部深处在工作，但没有腰痛或颈部紧绷。
                """,
                sprout: """
                Who it's for:
                想认真练一点核心，让腹部有“在练”的感觉。

                The Plan (12～15 min):
                · 3 轮：
                  · Dead bug 10 次（交替）
                  · Bird-dog 每侧 10 次
                  · 前平板支撑 20～30 秒（可以膝盖着地）
                · 每轮休息 30 秒。

                How it should feel:
                RPE 5～6/10。腹部有稳定、持续的酸胀，结束时姿势仍然干净。
                """,
                bloom: """
                Who it's for:
                想要腹部更紧致、对核心训练有一点基础的人。

                The Plan (15～18 min):
                · 3～4 轮：
                  · Dead bug 10～12 次
                  · Bird-dog 每侧 10～12 次
                  · 前平板 30 秒 + 侧平板 每侧 30 秒
                · 结束加收尾：空心支撑 3 组，每组 20～30 秒。

                How it should feel:
                RPE 7～8/10。腹部有明显疲劳感，但关节安全、呼吸仍然可控。
                """
            )
            
        // REST & RESET
        default:
            return restScript()
        }
    }
}

// MARK: - PHASE 2 · IGNITE (Weeks 3–4)

private extension VitalityArcRichContentFactory {
    
    static func enduranceScript(for cycleDay: Int) -> VitalityArcDayScript {
        switch cycleDay {
        // LOWER BODY BURN – LEGS & ENDURANCE
        case 1, 5:
            return VitalityArcDayScript(
                title: "Lower Body Burn",
                focusArea: "Legs & Endurance",
                durationMinutes: 30,
                seed: """
                Who it's for:
                想保持习惯、但今天状态一般的你。

                The Plan (10～12 min):
                · 热身：原地踏步 2 分钟 + 10 次空气深蹲
                · 2～3 轮：
                  · 徒手深蹲 10～12 次
                  · 低台阶踩踏 每腿 10 次（可用楼梯第一阶）
                · 轮与轮之间慢走恢复 45 秒。

                How it should feel:
                RPE 4/10。腿有工作感，呼吸稍微加快，但不会累垮。
                """,
                sprout: """
                Who it's for:
                标准下肢耐力训练，想让腿更紧实、有线条。

                The Plan (20～25 min):
                · 热身 3 分钟：侧弓步、腿摆动
                · 3～4 轮：
                  · 徒手深蹲 12～15 次
                  · 行走弓步 每腿 12 步
                  · 靠墙坐 30 秒
                · 每轮休息 45～60 秒。

                How it should feel:
                RPE 6/10。下肢有持续灼烧感，心率维持在可对话但略喘的范围。
                """,
                bloom: """
                Who it's for:
                想让腿彻底“被点燃”，但仍然以安全为前提。

                The Plan (22～26 min):
                · 热身 3 分钟：动态拉伸 + 小步跑
                · 3～4 轮：
                  · 高脚杯深蹲 10～12 次
                  · 反向弓步 每腿 10 次
                  · 跨步登台 每腿 10 次（可抱水瓶增加负重）
                · 每轮休息 60～75 秒，保持深呼吸。

                How it should feel:
                RPE 7～8/10。大腿和臀部很烧，但关节仍然舒适、动作可控。
                """
            )
            
        // UPPER ENDURANCE – PUSH, PULL & POSTURE
        case 2, 6:
            return VitalityArcDayScript(
                title: "Upper Body Endurance",
                focusArea: "Push, Pull & Posture",
                durationMinutes: 28,
                seed: """
                Who it's for:
                肩颈紧张但又不想完全不动的人。

                The Plan (10～12 min):
                · 2～3 轮：
                  · 墙上俯卧撑 8 次
                  · 站姿划船 10 次
                  · 站姿 Y 字上举 10 次（双手空握，感受肩胛骨上提）
                · 轮与轮之间做 20 秒肩部绕圈和轻轻点头放松颈部。

                How it should feel:
                RPE 4/10。上背和手臂有微酸感，结束时肩颈比之前更放松。
                """,
                sprout: """
                Who it's for:
                想提升上肢耐力，改善含胸驼背的人。

                The Plan (18～22 min):
                · 热身 2 分钟：手臂前后环绕
                · 3 轮：
                  · 斜板俯卧撑 10～12 次
                  · 哑铃/水瓶划船 每侧 12 次
                  · 侧平举 12 次
                · 每轮休息 45 秒，注意保持核心轻微收紧。

                How it should feel:
                RPE 6/10。胸、背、肩都有扎实工作感，结束后站得更挺。
                """,
                bloom: """
                Who it's for:
                想让上肢有“泵感”的训练日。

                The Plan (22～26 min):
                · 热身 3 分钟：弹力带拉伸、俯身摆臂
                · 3～4 轮：
                  · 跪姿俯卧撑 12～15 次（或标准俯卧撑 8～10 次）
                  · 俯身哑铃划船 每侧 12 次
                  · 肩推 10～12 次
                · 每轮休息 60 秒，专注缓慢下放和完全伸展。

                How it should feel:
                RPE 7～8/10。手臂和肩膀充血，洗澡时会感觉到“哇，最近有在练”。
                """
            )
            
        // CARDIO CORE – HEART & ABS
        case 3:
            return VitalityArcDayScript(
                title: "Cardio Core",
                focusArea: "心肺 + 腹部耐力",
                durationMinutes: 25,
                seed: """
                Who it's for:
                想动一下核心和心肺，但今天不适合高强度的人。

                The Plan (10～12 min):
                · 3 轮：
                  · 原地踏步或小步走 40 秒
                  · 站姿侧屈触膝 每侧 8 次
                  · 站姿旋转卷腹 每侧 8 次
                · 轮与轮之间深呼吸 30 秒。

                How it should feel:
                RPE 4/10。心率轻轻上来，腹部有温柔的参与感。
                """,
                sprout: """
                Who it's for:
                想要一点燃脂感，又想照顾关节的人。

                The Plan (18～20 min):
                · 热身 3 分钟：原地慢跑或高抬腿
                · 4 轮：
                  · 低冲击开合步 30 秒
                  · 站姿卷腹 12 次
                  · 仰卧卷腹 12 次
                · 轮之间走动 30～45 秒。

                How it should feel:
                RPE 6/10。微微出汗，腹部和心肺同时“被提醒在工作”。
                """,
                bloom: """
                Who it's for:
                想要更明显的“出汗 + 核心”训练。

                The Plan (22～25 min):
                · 热身 3 分钟
                · 4 轮：
                  · 开合跳或低冲击跳 30 秒
                  · 登山跑 20 秒（可改为慢版本抬腿）
                  · 仰卧卷腹 15 次
                · 每轮休息 45～60 秒，根据心率调整。

                How it should feel:
                RPE 7/10。心率明显升高，腹部也有疲劳，但仍然能控制呼吸。
                """
            )
            
        // CORE ENDURANCE – ROTATION & STABILITY
        case 4:
            return VitalityArcDayScript(
                title: "Core Endurance",
                focusArea: "Rotation & Stability",
                durationMinutes: 20,
                seed: """
                Who it's for:
                想加强“腰腹支撑力”，但不适合做太激烈转体的人。

                The Plan (8～10 min):
                · 2～3 轮：
                  · 坐姿侧向转体 每侧 10 次（可抱枕头）
                  · Bird-dog 每侧 8 次
                  · 前平板 20 秒
                · 每轮休息 30 秒，保持动作缓慢。

                How it should feel:
                RPE 4/10。腰腹像一条稳稳的“腰带”，没有刺痛或不适。
                """,
                sprout: """
                Who it's for:
                想让腹部线条更明显、转体力量更好的人。

                The Plan (18～20 min):
                · 3 轮：
                  · 俄罗斯转体 每侧 12 次（可抱水瓶）
                  · 前平板 30 秒
                  · 侧平板 每侧 20～30 秒
                · 每轮休息 30～45 秒。

                How it should feel:
                RPE 6～7/10。腹斜肌和核心有持久灼烧感。
                """,
                bloom: """
                Who it's for:
                想体验更“运动员感”的核心训练日。

                The Plan (20～22 min):
                · 3～4 轮：
                  · 站姿木劈 每侧 10～12 次（弹力带或水瓶）
                  · 旋转俄罗斯转体 每侧 12 次
                  · 侧平板髋部上下点地 每侧 10 次
                · 每轮休息 45～60 秒。

                How it should feel:
                RPE 7～8/10。整个腰腹“被包裹住”的感觉更明显，动作仍然干净可控。
                """
            )
            
        default:
            return restScript()
        }
    }
}

// MARK: - PHASE 3 · SCULPT (Weeks 5–6)

private extension VitalityArcRichContentFactory {
    
    static func strengthScript(for cycleDay: Int) -> VitalityArcDayScript {
        switch cycleDay {
        // LOWER BODY STRENGTH – GLUTES & QUADS
        case 1, 5:
            return VitalityArcDayScript(
                title: "Lower Body Strength",
                focusArea: "Glutes & Quads",
                durationMinutes: 32,
                seed: """
                Who it's for:
                想维持力量但今天精力普通的人。

                The Plan (12～15 min):
                · 2～3 轮：
                  · 高脚杯深蹲 8～10 次（轻重量）
                  · 臀桥 12 次
                  · 靠墙坐 20～30 秒
                · 每轮休息 60 秒。

                How it should feel:
                RPE 5/10。臀腿有扎实发力感，但不像“爆炸腿日”那么累。
                """,
                sprout: """
                Who it's for:
                正常状态下的下肢力量训练日。

                The Plan (22～25 min):
                · 热身 3 分钟：动态腿部拉伸
                · 3 轮：
                  · 高脚杯深蹲 10～12 次
                  · 反向弓步 每腿 10 次
                  · 罗马尼亚硬拉 10～12 次（哑铃或水瓶）
                · 每轮休息 60 秒，专注缓慢下放。

                How it should feel:
                RPE 6～7/10。最后一轮大腿和臀部都很有存在感。
                """,
                bloom: """
                Who it's for:
                想要“今天真的练到了腿和臀”的你。

                The Plan (26～30 min):
                · 热身 3 分钟 + 轻度臀桥激活
                · 3～4 轮：
                  · 高脚杯深蹲 8～10 次（中等重量）
                  · 行走弓步 每腿 10～12 步
                  · 罗马尼亚硬拉 10 次
                · 每轮休息 75～90 秒。

                How it should feel:
                RPE 8/10。肌肉明显疲劳，但动作始终可控，无膝或腰的不适。
                """
            )
            
        // UPPER BODY STRENGTH – PUSH & PULL
        case 2, 6:
            return VitalityArcDayScript(
                title: "Upper Body Strength",
                focusArea: "Push & Pull",
                durationMinutes: 30,
                seed: """
                Who it's for:
                想练上肢，但更希望是“稳稳练一点”的日子。

                The Plan (12～15 min):
                · 2～3 轮：
                  · 斜板俯卧撑 8～10 次
                  · 单臂俯身划船 每侧 10 次
                  · 停顿式侧平举 10 次（顶部停 2 秒）
                · 每轮休息 60 秒。

                How it should feel:
                RPE 5/10。胸、背、肩都有轻微充血感。
                """,
                sprout: """
                Who it's for:
                想让上肢线条更明显、力量更稳定的人。

                The Plan (20～22 min):
                · 热身 3 分钟
                · 3 轮：
                  · 跪姿俯卧撑 10～12 次（或标准 6～8 次）
                  · 单臂俯身划船 每侧 12 次
                  · 肩推 10～12 次
                · 每轮休息 60 秒，保持核心收紧。

                How it should feel:
                RPE 6～7/10。最后一轮俯卧撑会有明显挑战，但仍可控制节奏。
                """,
                bloom: """
                Who it's for:
                真正想在“雕刻期”把上半身练出来的人。

                The Plan (24～28 min):
                · 热身 3 分钟 + 弹力带拉伸
                · 3～4 轮：
                  · 标准俯卧撑 8～10 次（必要时改跪姿）
                  · 单臂划船 每侧 10～12 次（略重一点）
                  · 肩推 10 次
                  · 二头弯举 10～12 次
                · 每轮休息 75 秒。

                How it should feel:
                RPE 8/10。手臂和肩膀每一组都认真在“烧”，但关节稳定、没有痛感。
                """
            )
            
        // GLUTE FOCUS – HINGE & BOOTY
        case 3:
            return VitalityArcDayScript(
                title: "Glute Focus",
                focusArea: "Hinge & Booty",
                durationMinutes: 28,
                seed: """
                Who it's for:
                想重点照顾臀部，但又不想太狠的人。

                The Plan (10～12 min):
                · 2～3 轮：
                  · 臀桥 12～15 次
                  · 髋铰链轻硬拉 10 次（手扶大腿滑到膝盖附近再起来）
                  · 站姿后踢腿 每侧 12 次
                · 每轮休息 45～60 秒。

                How it should feel:
                RPE 4～5/10。臀部明显参与，但整体感觉温和。
                """,
                sprout: """
                Who it's for:
                想要更翘的屁股和更有力的髋部的人。

                The Plan (18～20 min):
                · 热身 3 分钟
                · 3 轮：
                  · 哑铃或水瓶硬拉 10～12 次
                  · 臀桥 15 次
                  · 单腿臀桥 每侧 10 次
                · 每轮休息 60 秒，专注顶端挤臀。

                How it should feel:
                RPE 6～7/10。臀部有明显泵感，走路都有一点“练过”的感觉。
                """,
                bloom: """
                Who it's for:
                臀部是你优先级第一名的塑形目标。

                The Plan (22～25 min):
                · 热身 3 分钟 + 轻弹力带侧步
                · 3～4 轮：
                  · 硬拉 8～10 次（中等重量）
                  · 臀桥 15 次（如果可行在顶端停顿 2 秒）
                  · 弹力带侧走 每侧 12～15 步
                · 每轮休息 75 秒。

                How it should feel:
                RPE 8/10。臀中肌和臀大肌非常有存在感，但腰始终安全。
                """
            )
            
        // CORE STRENGTH – TOTAL CORE
        case 4:
            return VitalityArcDayScript(
                title: "Core Strength",
                focusArea: "Total Core",
                durationMinutes: 20,
                seed: """
                Who it's for:
                想稳一点练核心，而不是拼命卷腹的人。

                The Plan (10～12 min):
                · 2～3 轮：
                  · 前平板 20～30 秒
                  · 侧平板 每侧 15～20 秒
                · 每轮休息 30 秒，保持呼吸流畅。

                How it should feel:
                RPE 5/10。核心工作得很扎实，但没有撑到发抖的极限。
                """,
                sprout: """
                Who it's for:
                想要更稳定、更紧致核心的人。

                The Plan (18～20 min):
                · 3 轮：
                  · 负重俄罗斯转体 每侧 12 次
                  · 前平板 30 秒
                  · 侧平板 每侧 25～30 秒
                · 每轮休息 30～45 秒。

                How it should feel:
                RPE 6～7/10。腹部和腰两侧都很有感觉。
                """,
                bloom: """
                Who it's for:
                想把核心作为“主角肌群”认真训练的你。

                The Plan (18～20 min):
                · 3～4 轮：
                  · 负重俄罗斯转体 每侧 12 次（稍微重一点）
                  · 前平板 40 秒
                  · 侧平板 每侧 30～35 秒
                  · 尝试 10～15 秒 tuck hold 或 L-sit 变式
                · 每轮休息 45 秒。

                How it should feel:
                RPE 7～8/10。腹部有环绕式疲劳，但下背不会被压垮。
                """
            )
            
        default:
            return restScript()
        }
    }
}

// MARK: - PHASE 4 · FLOW (Weeks 7–8)

private extension VitalityArcRichContentFactory {
    
    static func integrationScript(for cycleDay: Int) -> VitalityArcDayScript {
        switch cycleDay {
        // FUNCTIONAL LEGS – BALANCE & STRENGTH
        case 1, 5:
            return VitalityArcDayScript(
                title: "Functional Legs",
                focusArea: "Balance & Strength",
                durationMinutes: 35,
                seed: """
                Who it's for:
                想温柔练腿、顺便练一点平衡感的人。

                The Plan (15～18 min):
                · 3 轮：
                  · 后撤弓步 每腿 8 次（可扶椅子）
                  · 单腿站立平衡 每侧 20 秒
                  · 提踵 12～15 次
                · 每轮休息 45 秒。

                How it should feel:
                RPE 4～5/10。更多是协调和平衡挑战，而不是“爆炸酸”。
                """,
                sprout: """
                Who it's for:
                想让下肢更“实用”，走路更稳、上下楼更轻松。

                The Plan (25～30 min):
                · 热身 3 分钟
                · 3～4 轮：
                  · 多方向弓步 每腿 10 次（前/侧/后）
                  · 交叉弓步 每腿 8～10 次
                  · 单腿罗马尼亚硬拉 每侧 8～10 次（可轻重量）
                · 每轮休息 60 秒。

                How it should feel:
                RPE 6～7/10。脚踝和臀部稳定肌肉参与很多，有“整条腿更聪明”的感觉。
                """,
                bloom: """
                Who it's for:
                想在安全范围内加入一点弹跳元素，练出“灵活的腿”。

                The Plan (28～32 min):
                · 热身 4 分钟（动态拉伸 + 小步跑）
                · 3～4 轮：
                  · 弓步带抬膝 每腿 10 次
                  · 侧弓步 每腿 10 次
                  · 跳跃深蹲 8～10 次（或脚跟离地的小跳）
                · 每轮休息 75 秒，根据膝盖反馈调整弹跳高度。

                How it should feel:
                RPE 7～8/10。腿既累又灵活，结束后要做一点轻拉伸。
                """
            )
            
        // ATHLETIC UPPER – PUSH, PULL & ROTATE
        case 2, 6:
            return VitalityArcDayScript(
                title: "Athletic Upper",
                focusArea: "Push, Pull & Rotate",
                durationMinutes: 32,
                seed: """
                Who it's for:
                想让上肢动作更“流畅”的日子。

                The Plan (12～15 min):
                · 2～3 轮：
                  · 斜板俯卧撑 8 次
                  · 站姿划船 10 次
                  · 站姿木劈转体 每侧 8 次（轻重量）
                · 每轮休息 45～60 秒。

                How it should feel:
                RPE 4～5/10。上肢有温和的工作感，胸口和背部感觉更打开。
                """,
                sprout: """
                Who it's for:
                想让上肢力量和旋转能力都提升一点的人。

                The Plan (22～25 min):
                · 热身 3 分钟：手臂绕圈、胸椎旋转
                · 3 轮：
                  · 跪姿俯卧撑 10～12 次
                  · 单臂划船 每侧 12 次
                  · 站姿木劈 每侧 10 次
                · 每轮休息 60 秒。

                How it should feel:
                RPE 6～7/10。推和拉都有明显发力，转体动作让上半身更“立体”。
                """,
                bloom: """
                Who it's for:
                想要一点“上肢 + 运动协调”的训练日。

                The Plan (26～30 min):
                · 热身 4 分钟
                · 3～4 轮：
                  · 标准或跪姿俯卧撑 10 次
                  · 单臂划船 每侧 10～12 次
                  · 站姿木劈 或 旋转推举 每侧 10 次
                · 每轮休息 75 秒，保持核心参与。

                How it should feel:
                RPE 7～8/10。肩、背、核心同时工作，有“整体上半身训练”的感觉。
                """
            )
            
        // WHOLE BODY FLOW – CIRCUIT
        case 3:
            return VitalityArcDayScript(
                title: "Whole Body Flow",
                focusArea: "Full-Body Circuit",
                durationMinutes: 28,
                seed: """
                Who it's for:
                想温柔地从头到脚都动一动、像做一小段“生活版体适能”。

                The Plan (12～15 min):
                · 2～3 轮：
                  · 徒手深蹲 8～10 次
                  · 斜板俯卧撑 8 次
                  · Bird-dog 每侧 8 次
                · 每轮休息 45 秒，动作保持顺畅。

                How it should feel:
                RPE 4～5/10。全身都有参与，但没有任何一个部位被“虐待”。
                """,
                sprout: """
                Who it's for:
                想通过一套动作同时照顾心肺、力量和协调性的人。

                The Plan (20～22 min):
                · 3 轮：
                  · 徒手深蹲 12 次
                  · 跪姿俯卧撑 10 次
                  · Bird-dog 每侧 10 次
                  · 站姿侧屈触膝 每侧 10 次
                · 每轮休息 45～60 秒。

                How it should feel:
                RPE 6/10。全身暖暖的，有“浑身通畅”的感觉。
                """,
                bloom: """
                Who it's for:
                想让全身有明确“workout 完成了”的满足感。

                The Plan (24～28 min):
                · 热身 3 分钟
                · 3～4 轮：
                  · 高脚杯深蹲 10～12 次
                  · 俯卧撑 8～10 次（必要时跪姿）
                  · 俯身划船 每侧 10～12 次
                  · 俄罗斯转体 每侧 12 次
                · 每轮休息 60～75 秒。

                How it should feel:
                RPE 7～8/10。全身都“上线”，但仍可控制动作质量。
                """
            )
            
        // POWER CORE & CARRY – REAL-LIFE STRENGTH
        case 4:
            return VitalityArcDayScript(
                title: "Power Core & Carry",
                focusArea: "Real-Life Strength",
                durationMinutes: 24,
                seed: """
                Who it's for:
                想提升“日常搬东西的底气”，但今天只想轻轻练的人。

                The Plan (10～12 min):
                · 2～3 轮：
                  · 农夫行走 每手提一水瓶 20～30 步
                  · 站姿木劈 每侧 8 次
                  · 前平板 20 秒
                · 每轮休息 45 秒。

                How it should feel:
                RPE 4～5/10。像在练“生活力量”，而不是纯健身房动作。
                """,
                sprout: """
                Who it's for:
                想让核心更稳定、拿东西时更有安全感的人。

                The Plan (18～20 min):
                · 3 轮：
                  · 农夫行走 30～40 步（略重一点）
                  · 站姿木劈 每侧 10～12 次
                  · 前平板 30 秒
                · 每轮休息 45～60 秒。

                How it should feel:
                RPE 6～7/10。腹部、前臂、肩膀都有扎实参与。
                """,
                bloom: """
                Who it's for:
                想要“人生搬家日也能打得过”的实用力量。

                The Plan (20～22 min):
                · 3～4 轮：
                  · 农夫行走 40～50 步（中等重量水瓶/购物袋）
                  · 站姿木劈 或 斜向推举 每侧 12 次
                  · 前平板 40 秒
                · 每轮休息 60 秒。

                How it should feel:
                RPE 7～8/10。核心和握力都有挑战，但动作始终可控。
                """
            )
            
        default:
            return restScript()
        }
    }
}

// MARK: - Shared Rest Script

private extension VitalityArcRichContentFactory {
    static func restScript() -> VitalityArcDayScript {
        VitalityArcDayScript(
            title: "Rest & Restore",
            focusArea: "Recovery",
            durationMinutes: 0,
            seed: """
            Who it's for:
            Everyone. 真正的进步发生在恢复日。

            The Plan (2～5 min):
            · 喝一大口水。
            · 做 5 次深呼吸：鼻吸 4 秒，停 2 秒，口呼 6 秒。
            · 今天允许自己“少一点要求，多一点善意”。

            How it should feel:
            像是按下一个小小的重置键，不用“完成任务”，只是在照顾自己。
            """,
            sprout: """
            Who it's for:
            想通过轻运动恢复血液循环的人。

            The Plan (10～20 min):
            · 10～20 分钟自然散步（最好有一点阳光或绿色）。
            · 不放音乐也没关系，感受脚步和呼吸。
            · 回家后做 3 个简单拉伸：小腿、前腿、大腿后侧，各 20 秒。

            How it should feel:
            RPE 2～3/10。身体被温柔舒展开，心情更平。
            """,
            bloom: """
            Who it's for:
            你习惯活动，但今天想把强度留给恢复。

            The Plan (20～30 min):
            · 20 分钟轻快步行。
            · 10 分钟全身拉伸或简单瑜伽流动。
            · 睡前多喝一小杯温水，早点上床，给自己一个加分睡眠。

            How it should feel:
            像是给这周的努力做一个“收尾仪式”，身心都被安放好。
            """
        )
    }
}
