import type { FamilyProfile } from '../model/FamilyProfile';
import type { HealthSignal } from '../model/HealthSignal';
import type { FoodLabel } from '../model/FoodLabel';
import type { DailyBudget } from '../model/DailyBudget';
import { Recommendation, RecommendLevel, LevelColor } from "@bundle:com.familyfood.helper/entry/ets/model/Recommendation";
// 过敏原关键词映射（内置默认，可从JSON加载扩展）
const ALLERGEN_KEYWORDS: Record<string, string[]> = {
    '坚果': ['花生', '核桃', '杏仁', '腰果', '开心果', '坚果', '巴旦木', '榛子', '松子'],
    '乳制品': ['牛奶', '乳粉', '奶粉', '奶油', '黄油', '芝士', '奶酪', '乳清', '炼乳'],
    '麸质': ['小麦', '大麦', '面粉', '面筋', '麦麸'],
    '鸡蛋': ['鸡蛋', '蛋清', '蛋黄', '蛋粉'],
    '海鲜': ['虾', '蟹', '贝', '牡蛎', '鱿鱼', '三文鱼', '金枪鱼', '鳕鱼'],
    '大豆': ['大豆', '黄豆', '豆粕', '大豆蛋白', '酱油'],
    '芝麻': ['芝麻', '芝麻酱'],
    '花生': ['花生', '花生酱', '花生油']
};
export class RuleEngine {
    // 检查过敏原红线
    checkAllergenRedline(profile: FamilyProfile, food: FoodLabel): string[] {
        const hits: string[] = [];
        const ingredientsText = food.ingredientsText().toLowerCase();
        for (const allergen of profile.allergens) {
            const keywords = ALLERGEN_KEYWORDS[allergen] || [allergen];
            for (const keyword of keywords) {
                if (ingredientsText.includes(keyword.toLowerCase())) {
                    hits.push(allergen);
                    break;
                }
            }
        }
        // 也检查食品自带的致敏原提示
        for (const hint of food.allergenHints) {
            for (const allergen of profile.allergens) {
                if (hint.includes(allergen) && !hits.includes(allergen)) {
                    hits.push(allergen);
                }
            }
        }
        return hits;
    }
    // 计算今日可吃量
    calculateMaxAmount(remainingBudget: number, nutritionPer100g: number): number {
        if (nutritionPer100g <= 0) {
            return Infinity; // 无该营养素数据，不限制
        }
        return Math.max(0, (remainingBudget / nutritionPer100g) * 100);
    }
    // 计算动态修正因子
    calculateDynamicModifiers(signal: HealthSignal): DynamicModifiers {
        const modifiers: DynamicModifiers = {
            highCalorieFactor: 1.0,
            highFatFactor: 1.0,
            highSodiumFactor: 1.0,
            highSugarFactor: 1.0,
            sodiumBudgetFactor: 1.0
        };
        // 步数低/活动热量低 → 高热量、高脂更严格
        if (signal.isLowActivity()) {
            modifiers.highCalorieFactor *= 0.7;
            modifiers.highFatFactor *= 0.7;
        }
        // 运动较多 → 能量/碳水可略放宽
        if (signal.isHighActivity()) {
            modifiers.highCalorieFactor *= 1.2;
        }
        // 睡眠差 → 高糖更严格
        if (signal.isPoorSleep()) {
            modifiers.highSugarFactor *= 0.8;
        }
        // 体重趋势上升 → 高热量高脂更严格
        if (signal.isWeightUp()) {
            modifiers.highCalorieFactor *= 0.8;
            modifiers.highFatFactor *= 0.8;
        }
        // 手动血压偏高 → 钠预算下调
        if (signal.isHighBp()) {
            modifiers.sodiumBudgetFactor *= 0.8;
        }
        // 今天已经吃过偏咸食物 → 高钠再吃更严格
        if (signal.isHighSodiumToday()) {
            modifiers.sodiumBudgetFactor *= 0.7;
            modifiers.highSodiumFactor *= 0.85;
        }
        // 今天已经吃过偏甜食物 → 高糖再吃更严格
        if (signal.isHighSugarToday()) {
            modifiers.highSugarFactor *= 0.75;
        }
        return modifiers;
    }
    // 计算适配结论
    calculate(params: RuleEngineParams): Recommendation {
        const profile = params.profile;
        const healthSignal = params.healthSignal;
        const foodLabel = params.foodLabel;
        const dailyBudget = params.dailyBudget;
        const rec = new Recommendation();
        rec.memberId = profile.memberId;
        rec.foodId = foodLabel.foodId;
        rec.generatedAt = Date.now();
        const reasons: string[] = [];
        const reminders: string[] = [];
        // 1. 过敏原红线检查
        const allergenHits = this.checkAllergenRedline(profile, foodLabel);
        if (allergenHits.length > 0) {
            rec.level = RecommendLevel.AVOID;
            rec.levelColor = LevelColor.RED;
            rec.maxAmount = 0;
            reasons.push(`含过敏原：${allergenHits.join('、')}，建议避免`);
            rec.reasons = reasons;
            rec.reminders = reminders;
            return rec; // 过敏原直接返回，不再计算
        }
        // 2. 动态修正
        const modifiers = this.calculateDynamicModifiers(healthSignal);
        // 3. 计算各营养素可吃量
        const adjustedSodiumRemaining = dailyBudget.sodiumRemaining * modifiers.sodiumBudgetFactor;
        const maxBySodium = this.calculateMaxAmount(adjustedSodiumRemaining, foodLabel.nutrition.sodium);
        const maxBySugar = this.calculateMaxAmount(dailyBudget.sugarRemaining, foodLabel.nutrition.sugar);
        const maxByCalorie = this.calculateMaxAmount(dailyBudget.calorieRemaining, foodLabel.nutrition.calories);
        const maxByFat = this.calculateMaxAmount(dailyBudget.fatRemaining, foodLabel.nutrition.fat);
        // 取最小值作为建议最大食用量
        let maxAmount = Math.min(maxBySodium, maxBySugar, maxByCalorie, maxByFat);
        if (maxAmount === Infinity) {
            maxAmount = 100; // 无营养数据时默认100g
        }
        maxAmount = Math.round(maxAmount);
        // 4. 应用动态修正
        if (foodLabel.isHighCalorie()) {
            maxAmount *= modifiers.highCalorieFactor;
        }
        if (foodLabel.isHighFat()) {
            maxAmount *= modifiers.highFatFactor;
        }
        if (foodLabel.isHighSodium()) {
            maxAmount *= modifiers.highSodiumFactor;
        }
        if (foodLabel.isHighSugar()) {
            maxAmount *= modifiers.highSugarFactor;
        }
        maxAmount = Math.round(Math.max(0, maxAmount));
        rec.maxAmount = maxAmount;
        // 5. 生成原因
        if (profile.isControlBp() && foodLabel.isHighSodium()) {
            reasons.push('控压模式下钠含量较高');
            if (healthSignal.isLowActivity()) {
                reasons.push('今日活动量偏低，钠预算剩余较少');
            }
        }
        if (profile.isControlSugar() && foodLabel.isHighSugar()) {
            reasons.push('控糖模式下糖含量较高');
        }
        if (healthSignal.isHighSodiumToday() && foodLabel.isHighSodium()) {
            reasons.push('今天已经吃过偏咸食物，再吃高钠更容易超额');
        }
        if (healthSignal.isHighSugarToday() && foodLabel.isHighSugar()) {
            reasons.push('今天已经吃过偏甜食物，再吃高糖更容易超额');
        }
        if (profile.isLoseFat() && foodLabel.isHighCalorie()) {
            reasons.push('减脂模式下热量较高');
            if (healthSignal.isWeightUp()) {
                reasons.push('体重趋势上升，建议更严格控制');
            }
        }
        if (profile.isControlFat() && foodLabel.isHighFat()) {
            reasons.push('控脂模式下脂肪含量较高');
        }
        if (profile.isChild()) {
            if (foodLabel.isHighSugar()) {
                reasons.push('儿童模式下糖含量偏高');
            }
            if (foodLabel.isHighSodium()) {
                reasons.push('儿童模式下钠含量偏高');
            }
        }
        // 6. 生成提醒
        if (healthSignal.isLowActivity() && (foodLabel.isHighCalorie() || foodLabel.isHighFat())) {
            reminders.push('今日活动量偏低，高热量/高脂食品建议减少');
        }
        if (healthSignal.isPoorSleep() && foodLabel.isHighSugar()) {
            reminders.push('睡眠较差，高糖食品可能影响睡眠质量');
        }
        if (healthSignal.isHighSodiumToday()) {
            reminders.push('今天盐分已经偏多，后续尽量选择清淡搭配');
        }
        if (healthSignal.isHighSugarToday()) {
            reminders.push('今天甜食已经偏多，后续尽量减少含糖饮料和甜点');
        }
        if (dailyBudget.isSodiumExhausted()) {
            reminders.push('今日钠预算已用完，建议不再摄入高钠食品');
        }
        if (dailyBudget.isSugarExhausted()) {
            reminders.push('今日糖预算已用完，建议不再摄入高糖食品');
        }
        // 7. 四级映射
        if (maxAmount === 0) {
            rec.level = RecommendLevel.AVOID;
            rec.levelColor = LevelColor.RED;
        }
        else if (maxAmount <= 15) {
            rec.level = RecommendLevel.CAUTIOUS;
            rec.levelColor = LevelColor.ORANGE;
            reasons.length === 0 && reasons.push('今日预算剩余较少，建议谨慎');
        }
        else if (maxAmount <= 50) {
            rec.level = RecommendLevel.SMALL_OK;
            rec.levelColor = LevelColor.YELLOW;
            reasons.length === 0 && reasons.push('少量可以，注意控制份量');
        }
        else {
            rec.level = RecommendLevel.SUITABLE;
            rec.levelColor = LevelColor.GREEN;
        }
        rec.reasons = reasons.length > 0 ? reasons : ['当前情况下可以适量食用'];
        rec.reminders = reminders;
        return rec;
    }
    // 批量计算家庭对比
    calculateFamily(paramsList: RuleEngineParams[]): Recommendation[] {
        return paramsList.map(params => this.calculate(params));
    }
}
// 规则引擎参数
export interface RuleEngineParams {
    profile: FamilyProfile;
    healthSignal: HealthSignal;
    foodLabel: FoodLabel;
    dailyBudget: DailyBudget;
}
// 动态修正因子
export interface DynamicModifiers {
    highCalorieFactor: number;
    highFatFactor: number;
    highSodiumFactor: number;
    highSugarFactor: number;
    sodiumBudgetFactor: number;
}
