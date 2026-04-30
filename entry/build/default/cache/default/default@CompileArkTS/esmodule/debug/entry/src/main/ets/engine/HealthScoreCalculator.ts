import { RecommendationLevel } from "@bundle:com.familyfood.helper/entry/ets/model/FoodAdapterTypes";
import type { FoodNutrition, FamilyMemberSimple, HealthScoreResult, HealthScoreDeduction, DislikedAdditive } from "@bundle:com.familyfood.helper/entry/ets/model/FoodAdapterTypes";
import { FoodParser } from "@bundle:com.familyfood.helper/entry/ets/engine/FoodParser";
export class HealthScoreCalculator {
    /**
     * 计算综合健康评分
     * @param food - 食品营养数据
     * @param member - 家庭成员画像
     * @param riskFlags - 核心引擎已标记的风险列表
     * @param maxIntake_g - 建议最大食用量
     * @returns 综合健康评分结果
     */
    static calculate(food: FoodNutrition, member: FamilyMemberSimple, riskFlags: string[], maxIntake_g: number): HealthScoreResult {
        const deductions: HealthScoreDeduction[] = [];
        let score = 100;
        // ===== 1. 过敏红线检查（最高优先级，触发则归零） =====
        const allergenHit = HealthScoreCalculator.checkAllergen(food.allergens, member.allergenRedline);
        if (allergenHit !== null) {
            deductions.push({
                reason: `含过敏原「${allergenHit}」`,
                points: 100,
                type: 'allergen'
            });
            score = 0;
            return HealthScoreCalculator.buildResult(score, deductions);
        }
        // ===== 2. 特殊禁忌检查（触发则归零） =====
        const forbiddenReason = HealthScoreCalculator.checkForbidden(food, member);
        if (forbiddenReason !== null) {
            deductions.push({
                reason: forbiddenReason,
                points: 100,
                type: 'forbidden'
            });
            score = 0;
            return HealthScoreCalculator.buildResult(score, deductions);
        }
        // ===== 3. 偏好与价值观检查（厌恶成分） =====
        if (member.dislikedAdditives && member.dislikedAdditives.length > 0) {
            const additiveDeductions = HealthScoreCalculator.checkDislikedAdditives(food, member.dislikedAdditives);
            for (const d of additiveDeductions) {
                deductions.push(d);
                score -= d.points;
            }
        }
        // ===== 4. 营养限制扣分（累进扣分） =====
        const nutrientDeductions = HealthScoreCalculator.calculateNutrientDeductions(food, riskFlags);
        for (const d of nutrientDeductions) {
            deductions.push(d);
            score -= d.points;
        }
        // ===== 5. 数据透明度扣分 =====
        const transparencyDeductions = HealthScoreCalculator.calculateTransparencyDeductions(food);
        for (const d of transparencyDeductions) {
            deductions.push(d);
            score -= d.points;
        }
        // ===== 6. 蛋白质正向加分（高蛋白食品加分） =====
        const proteinBonus = HealthScoreCalculator.calculateProteinBonus(food);
        if (proteinBonus !== null) {
            deductions.push(proteinBonus);
            score += proteinBonus.points;
        }
        // 确保分数在0-100之间
        score = Math.max(0, Math.min(100, score));
        return HealthScoreCalculator.buildResult(score, deductions);
    }
    /**
     * 检查过敏原
     */
    private static checkAllergen(foodAllergens: string[], memberRedline: string[]): string | null {
        if (!foodAllergens || foodAllergens.length === 0 || !memberRedline || memberRedline.length === 0) {
            return null;
        }
        for (const allergen of foodAllergens) {
            const trimmed = allergen.trim();
            if (trimmed.length === 0) {
                continue;
            }
            for (const redline of memberRedline) {
                if (trimmed.includes(redline) || redline.includes(trimmed)) {
                    return trimmed;
                }
            }
        }
        return null;
    }
    /**
     * 检查特殊禁忌
     */
    private static checkForbidden(food: FoodNutrition, member: FamilyMemberSimple): string | null {
        if (!food || !member) {
            return null;
        }
        const isChild = member.role === 'child' || member.healthGoal === 'children';
        if (isChild) {
            const productName = (food.productName ?? '').toLowerCase();
            if (productName.includes('咖啡') || productName.includes('茶饮料') || productName.includes('功能饮料')) {
                return '含咖啡因，不适合儿童';
            }
            if (food.sugar_g > 15) {
                return '糖含量偏高，不适合作为儿童日常零食';
            }
        }
        return null;
    }
    /**
     * 检查厌恶成分/添加剂
     * @param food - 食品数据
     * @param dislikedAdditives - 用户厌恶的添加剂列表
     * @returns 扣分明细列表
     */
    private static checkDislikedAdditives(food: FoodNutrition, dislikedAdditives: DislikedAdditive[]): HealthScoreDeduction[] {
        const deductions: HealthScoreDeduction[] = [];
        // 检查配料表中是否含厌恶成分
        const allIngredients = [
            food.productName,
            ...food.sweeteners,
            ...food.allergens
        ].join(',').toLowerCase();
        for (const additive of dislikedAdditives) {
            const additiveStr = additive.toString().toLowerCase();
            let found = false;
            // 在甜味剂中查找
            for (const sweetener of food.sweeteners) {
                if (sweetener.toLowerCase().includes(additiveStr) || additiveStr.includes(sweetener.toLowerCase())) {
                    found = true;
                    break;
                }
            }
            // 在过敏原中查找
            if (!found) {
                for (const allergen of food.allergens) {
                    if (allergen.toLowerCase().includes(additiveStr) || additiveStr.includes(allergen.toLowerCase())) {
                        found = true;
                        break;
                    }
                }
            }
            // 在产品名中查找
            if (!found) {
                if (allIngredients.includes(additiveStr)) {
                    found = true;
                }
            }
            if (found) {
                deductions.push({
                    reason: `含厌恶成分「${additive}」`,
                    points: 15,
                    type: 'additive'
                });
            }
        }
        return deductions;
    }
    /**
     * 计算营养限制扣分（累进扣分）
     */
    private static calculateNutrientDeductions(food: FoodNutrition, riskFlags: string[]): HealthScoreDeduction[] {
        const deductions: HealthScoreDeduction[] = [];
        const energyKcal = FoodParser.kjToKcal(food.energy_kj);
        // 钠扣分（累进）
        if (food.sodium_mg >= 800) {
            deductions.push({ reason: `钠含量极高(${food.sodium_mg}mg/100g)`, points: 25, type: 'nutrient' });
        }
        else if (food.sodium_mg >= 500) {
            deductions.push({ reason: `钠含量偏高(${food.sodium_mg}mg/100g)`, points: 15, type: 'nutrient' });
        }
        else if (food.sodium_mg >= 200) {
            deductions.push({ reason: `钠含量中等(${food.sodium_mg}mg/100g)`, points: 5, type: 'nutrient' });
        }
        // 糖扣分（累进）
        if (food.sugar_g >= 30) {
            deductions.push({ reason: `糖含量极高(${food.sugar_g}g/100g)`, points: 25, type: 'nutrient' });
        }
        else if (food.sugar_g >= 15) {
            deductions.push({ reason: `糖含量偏高(${food.sugar_g}g/100g)`, points: 15, type: 'nutrient' });
        }
        else if (food.sugar_g >= 5) {
            deductions.push({ reason: `糖含量中等(${food.sugar_g}g/100g)`, points: 5, type: 'nutrient' });
        }
        // 热量扣分（累进）
        if (energyKcal >= 500) {
            deductions.push({ reason: `热量极高(${energyKcal}kcal/100g)`, points: 20, type: 'nutrient' });
        }
        else if (energyKcal >= 400) {
            deductions.push({ reason: `热量偏高(${energyKcal}kcal/100g)`, points: 10, type: 'nutrient' });
        }
        else if (energyKcal >= 250) {
            deductions.push({ reason: `热量中等(${energyKcal}kcal/100g)`, points: 5, type: 'nutrient' });
        }
        // 脂肪扣分（累进）
        if (food.fat_g >= 30) {
            deductions.push({ reason: `脂肪含量极高(${food.fat_g}g/100g)`, points: 20, type: 'nutrient' });
        }
        else if (food.fat_g >= 20) {
            deductions.push({ reason: `脂肪含量偏高(${food.fat_g}g/100g)`, points: 10, type: 'nutrient' });
        }
        else if (food.fat_g >= 10) {
            deductions.push({ reason: `脂肪含量中等(${food.fat_g}g/100g)`, points: 5, type: 'nutrient' });
        }
        // 反式脂肪扣分
        if (food.transFat_g > 0) {
            deductions.push({ reason: `含反式脂肪(${food.transFat_g}g/100g)`, points: 15, type: 'nutrient' });
        }
        return deductions;
    }
    /**
     * 计算数据透明度扣分
     */
    private static calculateTransparencyDeductions(food: FoodNutrition): HealthScoreDeduction[] {
        const deductions: HealthScoreDeduction[] = [];
        if (food.dataCompleteness === 'minimal') {
            deductions.push({ reason: '数据完整度低，仅含基本信息', points: 15, type: 'transparency' });
        }
        else if (food.dataCompleteness === 'partial') {
            deductions.push({ reason: '数据部分完整，部分营养信息缺失', points: 5, type: 'transparency' });
        }
        // 缺少生产商信息
        if (!food.manufacturer || food.manufacturer.length === 0) {
            deductions.push({ reason: '缺少生产商信息', points: 5, type: 'transparency' });
        }
        // 缺少SC编号
        if (!food.scNumber || food.scNumber.length === 0) {
            deductions.push({ reason: '缺少SC生产许可证编号', points: 3, type: 'transparency' });
        }
        return deductions;
    }
    /**
     * 计算蛋白质正向加分
     * 高蛋白食品（≥15g/100g）加分，鼓励选择优质蛋白来源
     * @param food - 食品营养数据
     * @returns 加分明细（null表示不加分）
     */
    private static calculateProteinBonus(food: FoodNutrition): HealthScoreDeduction | null {
        if (food.protein_g >= 20) {
            return { reason: `高蛋白食品(${food.protein_g}g/100g)，优质营养来源`, points: 10, type: 'nutrient' };
        }
        if (food.protein_g >= 15) {
            return { reason: `蛋白质含量较高(${food.protein_g}g/100g)`, points: 5, type: 'nutrient' };
        }
        if (food.protein_g >= 10) {
            return { reason: `蛋白质含量适中(${food.protein_g}g/100g)`, points: 3, type: 'nutrient' };
        }
        return null;
    }
    /**
     * 组装评分结果
     */
    private static buildResult(score: number, deductions: HealthScoreDeduction[]): HealthScoreResult {
        // 分数映射到级别
        let level: RecommendationLevel;
        let levelText: string;
        let levelColor: string;
        if (score <= 40) {
            level = RecommendationLevel.RED;
            levelText = '建议避免';
            levelColor = '#F44336';
        }
        else if (score <= 69) {
            level = RecommendationLevel.ORANGE;
            levelText = '今天谨慎';
            levelColor = '#FF5722';
        }
        else if (score <= 84) {
            level = RecommendationLevel.YELLOW;
            levelText = '少量可以';
            levelColor = '#FF9800';
        }
        else {
            level = RecommendationLevel.GREEN;
            levelText = '适合';
            levelColor = '#4CAF50';
        }
        return {
            score: score,
            deductions: deductions,
            level: level,
            levelText: levelText,
            levelColor: levelColor
        };
    }
}
