import type { FoodNutrition, FamilyMember } from '../model/FoodAdapterTypes';
import { NutriScoreEngine, NutriScoreResult, NutriScoreGrade } from "@bundle:com.familyfood.helper/entry/ets/engine/NutriScoreEngine";
import { ShanghaiGradeEngine, ShanghaiGradeResult } from "@bundle:com.familyfood.helper/entry/ets/engine/ShanghaiGradeEngine";
import { SmartChoiceEngine, SmartChoiceResult } from "@bundle:com.familyfood.helper/entry/ets/engine/SmartChoiceEngine";
// 重新导出子引擎的类型，方便外部统一引用
export { ShanghaiGradeResult, SmartChoiceResult, NutriScoreResult, NutriScoreGrade };
// ==================== 类型定义 ====================
/**
 * 家庭适配分扣分明细
 */
export class FamilyAdaptDeduction {
    /** 扣分原因 */
    reason: string = '';
    /** 扣分数值 */
    points: number = 0;
    /** 扣分类型：allergen（过敏）/ sodium_weight（钠权重）/ sugar_weight（糖权重）/
     *  fat_weight（脂肪权重）/ energy_weight（热量权重）/ satfat_weight（饱和脂肪权重） */
    type: string = '';
}
/**
 * 家庭适配分计算结果
 */
export class FamilyAdaptScoreResult {
    /** 家庭适配分（0-100），null表示未传入成员 */
    score: number | null = null;
    /** 基础分（Nutri-Score分数） */
    baseScore: number = 0;
    /** 扣分明细列表 */
    deductions: FamilyAdaptDeduction[] = [];
    /** 是否因过敏红线归零 */
    isAllergenZero: boolean = false;
    /** 过敏原信息 */
    allergenInfo: string = '';
}
/**
 * 统一评分结果
 */
export class UnifiedScoreResult {
    /** Nutri-Score 综合健康评分结果 */
    nutriScore: NutriScoreResult = new NutriScoreResult();
    /** 上海"营养选择"饮料分级结果（仅饮料类返回） */
    shanghaiGrade: ShanghaiGradeResult | null = null;
    /** 中国营养学会"智慧选择"规范解读结果 */
    smartChoice: SmartChoiceResult = new SmartChoiceResult();
    /** 家庭适配分（0-100），若未传入member则为null */
    familyAdaptScore: FamilyAdaptScoreResult = new FamilyAdaptScoreResult();
}
// ==================== 权重常量 ====================
/**
 * 家庭适配分权重配置
 * TODO: 经营养学专家校准
 *
 * 权重值含义：倍数因子，乘以Nutri-Score中对应营养素的扣分
 * 例如 sodiumWeightMultiplier = 2 表示控压人群的钠扣分加倍
 */
class FamilyAdaptWeights {
    /** 控压（blood_pressure）：钠权重倍数 */
    static readonly BP_SODIUM_MULTIPLIER: number = 2;
    /** 控糖（sugar_control）：糖权重倍数 */
    static readonly SC_SUGAR_MULTIPLIER: number = 2;
    /** 减脂（fat_loss）：脂肪权重倍数 */
    static readonly FL_FAT_MULTIPLIER: number = 2;
    /** 减脂（fat_loss）：热量权重倍数 */
    static readonly FL_ENERGY_MULTIPLIER: number = 2;
    /** 儿童（children）：糖权重倍数 */
    static readonly CHILD_SUGAR_MULTIPLIER: number = 2;
    /** 儿童（children）：饱和脂肪权重倍数 */
    static readonly CHILD_SATFAT_MULTIPLIER: number = 2;
}
// ==================== 统一评分服务 ====================
/**
 * 整合国内外评分体系的统一评分服务
 *
 * 功能：
 * 1. 计算 Nutri-Score 综合健康评分（国际体系）
 * 2. 计算上海"营养选择"饮料分级（国内地方标准，仅饮料类）
 * 3. 计算中国营养学会"智慧选择"规范解读（国内行业标准）
 * 4. 计算家庭适配分（个性化评分，需传入家庭成员画像）
 */
export class NutritionScoreService {
    /**
     * 获取统一评分结果
     * 同时计算 Nutri-Score、上海分级、智慧选择、家庭适配分
     *
     * @param food - 食品营养数据
     * @param member - 家庭成员画像（可选，传入则计算家庭适配分）
     * @returns UnifiedScoreResult 统一评分结果
     */
    static getUnifiedScore(food: FoodNutrition, member?: FamilyMember): UnifiedScoreResult {
        const result = new UnifiedScoreResult();
        // ===== 1. 计算 Nutri-Score =====
        result.nutriScore = NutriScoreEngine.calculateFromFoodNutrition(food);
        // ===== 2. 计算上海"营养选择"饮料分级 =====
        const shanghaiResult = ShanghaiGradeEngine.calculateShanghaiGrade(food);
        if (shanghaiResult.isApplicable) {
            result.shanghaiGrade = shanghaiResult;
        }
        else {
            result.shanghaiGrade = null;
        }
        // ===== 3. 计算中国营养学会"智慧选择"规范解读 =====
        result.smartChoice = SmartChoiceEngine.checkSmartChoice(food);
        // ===== 4. 计算家庭适配分 =====
        if (member !== undefined && member !== null) {
            result.familyAdaptScore = NutritionScoreService.calculateFamilyAdaptScore(food, member, result.nutriScore);
        }
        else {
            result.familyAdaptScore = new FamilyAdaptScoreResult();
            result.familyAdaptScore.score = null;
        }
        return result;
    }
    /**
     * 计算家庭适配分（0-100）
     *
     * 算法说明：
     * - 基础分 = Nutri-Score分数
     * - 若成员有过敏红线且食品含对应过敏原，直接归零
     * - 根据成员健康目标，对特定营养素权重加倍，加大扣分力度
     *
     * TODO: 经营养学专家校准
     * - 权重倍数需要营养学专家根据中国居民膳食指南校准
     * - 后续版本可引入更多个性化因子（年龄、性别、BMI等）
     *
     * @param food - 食品营养数据
     * @param member - 家庭成员画像
     * @param nutriScore - Nutri-Score计算结果
     * @returns 家庭适配分计算结果
     */
    private static calculateFamilyAdaptScore(food: FoodNutrition, member: FamilyMember, nutriScore: NutriScoreResult): FamilyAdaptScoreResult {
        const adaptResult = new FamilyAdaptScoreResult();
        const deductions: FamilyAdaptDeduction[] = [];
        // 基础分 = Nutri-Score分数
        let baseScore = nutriScore.score;
        adaptResult.baseScore = baseScore;
        // ===== 步骤1：过敏红线检查（最高优先级） =====
        if (member.allergenRedline.length > 0 && food.allergens.length > 0) {
            const matchedAllergens: string[] = [];
            for (const allergen of member.allergenRedline) {
                const lowerAllergen = allergen.toLowerCase();
                for (const foodAllergen of food.allergens) {
                    if (foodAllergen.toLowerCase().includes(lowerAllergen) ||
                        lowerAllergen.includes(foodAllergen.toLowerCase())) {
                        matchedAllergens.push(allergen);
                        break;
                    }
                }
            }
            if (matchedAllergens.length > 0) {
                adaptResult.isAllergenZero = true;
                adaptResult.allergenInfo = `含过敏原：${matchedAllergens.join('、')}`;
                adaptResult.score = 0;
                adaptResult.deductions = [{
                        reason: `含过敏原（${matchedAllergens.join('、')}），根据成员健康档案，适配分归零`,
                        points: baseScore,
                        type: 'allergen'
                    }];
                return adaptResult;
            }
        }
        // ===== 步骤2：根据健康目标调整权重 =====
        let adjustedScore = baseScore;
        const healthGoal = member.healthGoal;
        // 从NutriScore的扣分明细中提取各营养素扣分
        const nutrientPoints = NutritionScoreService.extractNutrientPoints(nutriScore);
        if (healthGoal === 'blood_pressure') {
            // 控压：钠权重×2
            const sodiumDeduction = nutrientPoints.sodiumPoints;
            const extraDeduction = sodiumDeduction * (FamilyAdaptWeights.BP_SODIUM_MULTIPLIER - 1);
            if (extraDeduction > 0) {
                adjustedScore -= extraDeduction;
                deductions.push({
                    reason: `控压目标：钠权重加倍，额外扣${extraDeduction.toFixed(0)}分`,
                    points: extraDeduction,
                    type: 'sodium_weight'
                });
            }
        }
        if (healthGoal === 'sugar_control') {
            // 控糖：糖权重×2
            const sugarDeduction = nutrientPoints.sugarPoints;
            const extraDeduction = sugarDeduction * (FamilyAdaptWeights.SC_SUGAR_MULTIPLIER - 1);
            if (extraDeduction > 0) {
                adjustedScore -= extraDeduction;
                deductions.push({
                    reason: `控糖目标：糖权重加倍，额外扣${extraDeduction.toFixed(0)}分`,
                    points: extraDeduction,
                    type: 'sugar_weight'
                });
            }
        }
        if (healthGoal === 'fat_loss') {
            // 减脂：脂肪和热量权重×2
            const fatDeduction = nutrientPoints.fatPoints;
            const energyDeduction = nutrientPoints.energyPoints;
            const extraFatDeduction = fatDeduction * (FamilyAdaptWeights.FL_FAT_MULTIPLIER - 1);
            const extraEnergyDeduction = energyDeduction * (FamilyAdaptWeights.FL_ENERGY_MULTIPLIER - 1);
            if (extraFatDeduction > 0) {
                adjustedScore -= extraFatDeduction;
                deductions.push({
                    reason: `减脂目标：脂肪权重加倍，额外扣${extraFatDeduction.toFixed(0)}分`,
                    points: extraFatDeduction,
                    type: 'fat_weight'
                });
            }
            if (extraEnergyDeduction > 0) {
                adjustedScore -= extraEnergyDeduction;
                deductions.push({
                    reason: `减脂目标：热量权重加倍，额外扣${extraEnergyDeduction.toFixed(0)}分`,
                    points: extraEnergyDeduction,
                    type: 'energy_weight'
                });
            }
        }
        if (healthGoal === 'children') {
            // 儿童：糖和饱和脂肪权重×2
            const sugarDeduction = nutrientPoints.sugarPoints;
            const satFatDeduction = nutrientPoints.satFatPoints;
            const extraSugarDeduction = sugarDeduction * (FamilyAdaptWeights.CHILD_SUGAR_MULTIPLIER - 1);
            const extraSatFatDeduction = satFatDeduction * (FamilyAdaptWeights.CHILD_SATFAT_MULTIPLIER - 1);
            if (extraSugarDeduction > 0) {
                adjustedScore -= extraSugarDeduction;
                deductions.push({
                    reason: `儿童保护：糖权重加倍，额外扣${extraSugarDeduction.toFixed(0)}分`,
                    points: extraSugarDeduction,
                    type: 'sugar_weight'
                });
            }
            if (extraSatFatDeduction > 0) {
                adjustedScore -= extraSatFatDeduction;
                deductions.push({
                    reason: `儿童保护：饱和脂肪权重加倍，额外扣${extraSatFatDeduction.toFixed(0)}分`,
                    points: extraSatFatDeduction,
                    type: 'satfat_weight'
                });
            }
        }
        // 确保分数在0-100范围内
        const finalScore = Math.max(0, Math.min(100, Math.round(adjustedScore)));
        adaptResult.score = finalScore;
        adaptResult.deductions = deductions;
        return adaptResult;
    }
    /**
     * 从Nutri-Score扣分明细中提取各营养素的扣分值
     *
     * @param nutriScore - Nutri-Score计算结果
     * @returns 各营养素扣分映射
     */
    private static extractNutrientPoints(nutriScore: NutriScoreResult): NutrientPointsMap {
        const map = new NutrientPointsMap();
        for (const detail of nutriScore.details) {
            switch (detail.name) {
                case '能量':
                    map.energyPoints = detail.points;
                    break;
                case '饱和脂肪':
                    map.satFatPoints = detail.points;
                    break;
                case '糖':
                    map.sugarPoints = detail.points;
                    break;
                case '钠':
                    map.sodiumPoints = detail.points;
                    break;
                default:
                    break;
            }
        }
        // 从NutriScore的负向分中提取脂肪扣分
        // 注意：Nutri-Score中没有直接的"脂肪"扣分项，只有饱和脂肪
        // 这里用饱和脂肪扣分作为脂肪相关扣分的参考
        map.fatPoints = map.satFatPoints;
        return map;
    }
    /**
     * 获取可读的评分文字说明
     * 包含 Nutri-Score、上海分级、智慧选择 的综合解读
     *
     * @param food - 食品营养数据
     * @returns 可读的文字说明
     */
    static getScoreExplanation(food: FoodNutrition): string {
        const parts: string[] = [];
        // ===== 1. Nutri-Score 说明 =====
        const nutriResult = NutriScoreEngine.calculateFromFoodNutrition(food);
        const nutriGradeLabel = NutritionScoreService.getNutriGradeChineseLabel(nutriResult.grade);
        parts.push(`国际 Nutri-Score 评级：${nutriResult.gradeLabel}（${nutriResult.score}分）`);
        parts.push(`  说明：${nutriGradeLabel}`);
        // ===== 2. 上海"营养选择"分级说明 =====
        const shanghaiResult = ShanghaiGradeEngine.calculateShanghaiGrade(food);
        if (shanghaiResult.isApplicable) {
            parts.push(`符合上海营养选择分级：${shanghaiResult.grade}级（${shanghaiResult.gradeText}）`);
            // 添加四项指标详情
            for (const detail of shanghaiResult.details) {
                parts.push(`  ${detail.name}：${detail.grade}级 - ${detail.reason}`);
            }
        }
        else {
            parts.push('非饮料类，不适用上海营养选择分级');
        }
        // ===== 3. 中国营养学会"智慧选择"说明 =====
        const smartResult = SmartChoiceEngine.checkSmartChoice(food);
        if (smartResult.isApplicable) {
            if (smartResult.eligible) {
                parts.push('符合中国营养学会智慧选择标准');
            }
            else {
                parts.push('暂未达到智慧选择标准');
                // 添加未达标原因（最多显示3条）
                const failReasons = smartResult.reasons.filter(r => r.includes('未达标'));
                for (let i = 0; i < Math.min(failReasons.length, 3); i++) {
                    parts.push(`  ${failReasons[i]}`);
                }
            }
            // 显示匹配到的食品类别
            if (smartResult.foodCategory.categoryName !== '未分类') {
                parts.push(`  食品类别：${smartResult.foodCategory.categoryName} > ${smartResult.foodCategory.subCategoryName}`);
            }
        }
        else {
            parts.push('该产品为特殊膳食用食品或保健食品，不适用智慧选择标准');
        }
        // ===== 4. 信息来源说明 =====
        parts.push('');
        parts.push('--- 评分信息来源 ---');
        parts.push('Nutri-Score：欧洲FOPNL（Front-of-Pack Nutrition Labelling）体系');
        parts.push('上海营养选择：上海市疾病预防控制中心研制，2024年3月试行');
        parts.push('智慧选择：中国营养学会 T/CNSS 001-2025，联合中国疾控中心营养与健康所、农业农村部食物与营养发展研究所制定');
        parts.push('家庭适配分：本App自研算法（需传入家庭成员画像）');
        return parts.join('\n');
    }
    /**
     * 获取家庭适配分的可读说明
     *
     * @param food - 食品营养数据
     * @param member - 家庭成员画像
     * @returns 可读的家庭适配分说明
     */
    static getFamilyAdaptExplanation(food: FoodNutrition, member: FamilyMember): string {
        const unifiedResult = NutritionScoreService.getUnifiedScore(food, member);
        const adaptResult = unifiedResult.familyAdaptScore;
        if (adaptResult.score === null) {
            return '未传入家庭成员信息，无法计算家庭适配分';
        }
        const parts: string[] = [];
        parts.push(`【${member.name}】的家庭适配分：${adaptResult.score}分`);
        parts.push(`基础分（Nutri-Score）：${adaptResult.baseScore}分`);
        parts.push(`健康目标：${NutritionScoreService.getHealthGoalLabel(member.healthGoal)}`);
        if (adaptResult.isAllergenZero) {
            parts.push(`⚠️ ${adaptResult.allergenInfo}`);
            parts.push('因含过敏原，适配分归零');
            return parts.join('\n');
        }
        if (adaptResult.deductions.length > 0) {
            parts.push('扣分明细：');
            for (const deduction of adaptResult.deductions) {
                parts.push(`  - ${deduction.reason}`);
            }
        }
        else {
            parts.push('无额外扣分，适配分等于基础分');
        }
        parts.push('');
        parts.push('--- 说明 ---');
        parts.push('家庭适配分 = Nutri-Score基础分 - 个性化权重扣分');
        parts.push('权重值当前为初步设定，待经营养学专家校准');
        parts.push('TODO: 经营养学专家校准');
        return parts.join('\n');
    }
    /**
     * 获取Nutri-Score等级的中文说明
     */
    private static getNutriGradeChineseLabel(grade: NutriScoreGrade): string {
        switch (grade) {
            case NutriScoreGrade.A:
                return '非常健康，推荐选择';
            case NutriScoreGrade.B:
                return '较为健康，可以食用';
            case NutriScoreGrade.C:
                return '中等水平，注意适量';
            case NutriScoreGrade.D:
                return '健康度较低，谨慎食用';
            case NutriScoreGrade.E:
                return '健康度低，建议避免';
            default:
                return '未知等级';
        }
    }
    /**
     * 获取健康目标的中文标签
     */
    private static getHealthGoalLabel(healthGoal: string): string {
        switch (healthGoal) {
            case 'blood_pressure':
                return '控压';
            case 'sugar_control':
                return '控糖';
            case 'fat_loss':
                return '减脂';
            case 'children':
                return '儿童';
            default:
                return healthGoal;
        }
    }
}
/**
 * 营养素扣分映射（内部辅助类）
 */
class NutrientPointsMap {
    energyPoints: number = 0;
    satFatPoints: number = 0;
    sugarPoints: number = 0;
    sodiumPoints: number = 0;
    fatPoints: number = 0;
}
