import { MealScenario, RiskTag } from "@bundle:com.familyfood.helper/entry/ets/model/MealBalance";
import type { FamilyProfile } from '../model/FamilyProfile';
// 正向补足建议
export interface PositiveAdvice {
    whatToSupplement: string[]; // 建议补什么
    whyToSupplement: string[]; // 为什么补
    howToSupplement: string[]; // 怎么补（具体做法）
}
export class PositiveAdviceEngine {
    /**
     * 根据美食场景生成正向补足建议
     * V4核心升级：不只说"少吃"，还告诉用户"补什么"
     */
    generateForScenario(scenario: MealScenario, profile: FamilyProfile): PositiveAdvice {
        const advice: PositiveAdvice = {
            whatToSupplement: [],
            whyToSupplement: [],
            howToSupplement: []
        };
        switch (scenario) {
            case MealScenario.BBQ:
                advice.whatToSupplement = ['深色蔬菜', '菌菇类', '水分'];
                advice.whyToSupplement = ['烧烤蔬菜和膳食纤维不足', '高盐高油后需要蔬菜帮助平衡'];
                advice.howToSupplement = ['下一餐做凉拌或清炒蔬菜', '搭配菌菇汤', '多喝白开水或淡茶'];
                break;
            case MealScenario.HOTPOT:
                advice.whatToSupplement = ['蔬菜', '清淡蛋白', '水分'];
                advice.whyToSupplement = ['火锅蔬菜可能不足', '汤底和蘸料高钠需要稀释'];
                advice.howToSupplement = ['下一餐增加绿叶蔬菜', '选择蒸蛋、豆腐等清淡蛋白', '多喝水帮助排钠'];
                break;
            case MealScenario.FRIED_CHICKEN:
                advice.whatToSupplement = ['蔬菜', '清淡蛋白', '水果'];
                advice.whyToSupplement = ['油炸食品蔬菜不足', '高油后需要清淡搭配'];
                advice.howToSupplement = ['下一餐补蔬菜沙拉或清炒时蔬', '搭配水煮蛋或蒸鱼', '餐后吃水果代替甜饮'];
                break;
            case MealScenario.MILK_TEA:
            case MealScenario.DESSERT:
                advice.whatToSupplement = ['无糖饮品', '蛋白质', '蔬菜'];
                advice.whyToSupplement = ['高糖后需要减少今日糖摄入', '甜食容易影响正餐食欲'];
                advice.howToSupplement = ['喝白开水、无糖茶或黑咖啡', '下一餐保证蛋白质摄入', '正餐多吃蔬菜增加饱腹感'];
                break;
            case MealScenario.LUWEI:
                advice.whatToSupplement = ['新鲜蔬菜', '水分', '清淡蛋白'];
                advice.whyToSupplement = ['卤味高盐且加工肉较多', '蔬菜和蛋白结构不均衡'];
                advice.howToSupplement = ['下一餐做清炒或凉拌蔬菜', '多喝水帮助排钠', '选择蒸煮类蛋白替代加工肉'];
                break;
            case MealScenario.INSTANT_NOODLE:
                advice.whatToSupplement = ['蛋白质', '蔬菜', '水分'];
                advice.whyToSupplement = ['方便面营养单一', '蛋白和蔬菜不足'];
                advice.howToSupplement = ['加鸡蛋和蔬菜一起煮', '下一餐补蛋白质和蔬菜', '多喝水'];
                break;
            case MealScenario.LATE_NIGHT:
                advice.whatToSupplement = ['水分', '早餐营养'];
                advice.whyToSupplement = ['夜宵影响睡眠和次日食欲', '需要保证次日早餐营养'];
                advice.howToSupplement = ['睡前喝少量温水', '次日早餐适量，保证蛋白质和蔬菜', '避免连续夜宵'];
                break;
        }
        // 结合成员健康目标补充
        if (profile.isControlBp()) {
            advice.whatToSupplement.push('低钾高蔬菜');
            advice.howToSupplement.push('增加新鲜蔬菜帮助排钠，但肾功能问题不自行补钾');
        }
        if (profile.isControlSugar()) {
            advice.whatToSupplement.push('低GI食物');
            advice.howToSupplement.push('选择全谷物、豆类等低GI食物稳定血糖');
        }
        if (profile.isLoseFat()) {
            advice.whatToSupplement.push('优质蛋白');
            advice.howToSupplement.push('选择鸡胸肉、鱼、蛋、豆制品等低脂高蛋白食物');
        }
        return advice;
    }
    /**
     * 根据风险标签生成补足建议
     */
    generateForRiskTags(riskTags: RiskTag[]): PositiveAdvice {
        const advice: PositiveAdvice = {
            whatToSupplement: [],
            whyToSupplement: [],
            howToSupplement: []
        };
        if (riskTags.includes(RiskTag.LOW_VEGGIE)) {
            advice.whatToSupplement.push('深色蔬菜', '菌菇');
            advice.whyToSupplement.push('蔬菜和膳食纤维不足');
            advice.howToSupplement.push('下一餐补深色蔬菜、菌菇或凉拌/清炒蔬菜');
        }
        if (riskTags.includes(RiskTag.TOO_MUCH_MEAT)) {
            advice.whatToSupplement.push('清淡蛋白');
            advice.whyToSupplement.push('肉类偏多，蛋白来源单一');
            advice.howToSupplement.push('补鸡蛋、鱼、豆腐、牛奶等清淡蛋白');
        }
        if (riskTags.includes(RiskTag.HIGH_SALT)) {
            advice.whatToSupplement.push('水分', '蔬菜');
            advice.whyToSupplement.push('高盐后需要稀释和排钠');
            advice.howToSupplement.push('下一餐少盐少汤，多喝水和蔬菜');
        }
        if (riskTags.includes(RiskTag.HIGH_OIL)) {
            advice.whatToSupplement.push('蔬菜', '清淡烹饪');
            advice.whyToSupplement.push('高油后需要清淡搭配');
            advice.howToSupplement.push('下一餐选择清蒸或水煮，增加蔬菜');
        }
        if (riskTags.includes(RiskTag.HIGH_SUGAR)) {
            advice.whatToSupplement.push('无糖饮品', '蛋白质');
            advice.whyToSupplement.push('高糖后需要减少今日糖摄入');
            advice.howToSupplement.push('喝白开水代替含糖饮料，下一餐保证蛋白质');
        }
        return advice;
    }
}
