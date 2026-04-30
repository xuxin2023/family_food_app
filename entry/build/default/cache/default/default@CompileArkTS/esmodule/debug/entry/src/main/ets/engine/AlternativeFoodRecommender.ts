import { RecommendationLevel } from "@bundle:com.familyfood.helper/entry/ets/model/FoodAdapterTypes";
import type { FoodNutrition, AlternativeFood, FamilyMemberSimple } from "@bundle:com.familyfood.helper/entry/ets/model/FoodAdapterTypes";
import type { FoodLabel } from '../model/FoodLabel';
import { FoodParser } from "@bundle:com.familyfood.helper/entry/ets/engine/FoodParser";
import { NutriScoreEngine } from "@bundle:com.familyfood.helper/entry/ets/engine/NutriScoreEngine";
// ===== 增强替代品结果 =====
export interface EnhancedAlternative extends AlternativeFood {
    /** NutriScore 分数差值（正数表示更好） */
    nutriScoreDiff: number;
    /** 关键改善指标及改善百分比 */
    improvements: ImprovementItem[];
    /** 最适合的成员标签 */
    bestForMembers: string[];
}
export interface ImprovementItem {
    /** 指标名称 */
    nutrient: string;
    /** 改善百分比 */
    percent: number;
    /** 描述 */
    description: string;
}
// TODO: 替换为真实数据库数据
// 本地预置模拟食品数据库（品类分类）
class MockFoodDatabase {
    // 按品类组织的预置食品数据
    static foods: FoodNutrition[] = [
        // ===== 零食类 =====
        {
            productName: '原味海苔', brand: '良品铺子', netWeight_g: 32,
            energy_kj: 800, protein_g: 12, fat_g: 5, saturatedFat_g: 1, transFat_g: 0,
            carbs_g: 20, sugar_g: 2, sodium_mg: 200,
            allergens: [], isSugarFree: true, isSucroseFree: true, sweeteners: [],
            manufacturer: '良品铺子', entrustInfo: '', scNumber: 'SC12345000001', dataCompleteness: 'complete'
        },
        {
            productName: '无糖薄荷糖', brand: '炫迈', netWeight_g: 20,
            energy_kj: 600, protein_g: 0, fat_g: 0, saturatedFat_g: 0, transFat_g: 0,
            carbs_g: 35, sugar_g: 0, sodium_mg: 10,
            allergens: [], isSugarFree: true, isSucroseFree: true, sweeteners: ['山梨糖醇', '木糖醇'],
            manufacturer: '炫迈食品', entrustInfo: '', scNumber: 'SC12345000002', dataCompleteness: 'complete'
        },
        {
            productName: '每日坚果', brand: '沃隆', netWeight_g: 25,
            energy_kj: 1200, protein_g: 8, fat_g: 15, saturatedFat_g: 2, transFat_g: 0,
            carbs_g: 15, sugar_g: 3, sodium_mg: 5,
            allergens: ['坚果', '花生'], isSugarFree: true, isSucroseFree: true, sweeteners: [],
            manufacturer: '沃隆食品', entrustInfo: '', scNumber: 'SC12345000003', dataCompleteness: 'complete'
        },
        {
            productName: '全麦苏打饼干', brand: '太平', netWeight_g: 100,
            energy_kj: 1800, protein_g: 10, fat_g: 12, saturatedFat_g: 3, transFat_g: 0,
            carbs_g: 65, sugar_g: 8, sodium_mg: 350,
            allergens: ['小麦', '麸质'], isSugarFree: false, isSucroseFree: true, sweeteners: [],
            manufacturer: '太平食品', entrustInfo: '', scNumber: 'SC12345000004', dataCompleteness: 'complete'
        },
        {
            productName: '魔芋爽素毛肚', brand: '卫龙', netWeight_g: 50,
            energy_kj: 400, protein_g: 1, fat_g: 3, saturatedFat_g: 0.5, transFat_g: 0,
            carbs_g: 15, sugar_g: 2, sodium_mg: 600,
            allergens: [], isSugarFree: true, isSucroseFree: true, sweeteners: [],
            manufacturer: '卫龙食品', entrustInfo: '', scNumber: 'SC12345000005', dataCompleteness: 'complete'
        },
        // ===== 饮品类 =====
        {
            productName: '无糖乌龙茶', brand: '三得利', netWeight_g: 500,
            energy_kj: 0, protein_g: 0, fat_g: 0, saturatedFat_g: 0, transFat_g: 0,
            carbs_g: 0, sugar_g: 0, sodium_mg: 30,
            allergens: [], isSugarFree: true, isSucroseFree: true, sweeteners: [],
            manufacturer: '三得利', entrustInfo: '', scNumber: 'SC12345000006', dataCompleteness: 'complete'
        },
        {
            productName: '纯牛奶', brand: '蒙牛', netWeight_g: 250,
            energy_kj: 270, protein_g: 3.2, fat_g: 3.6, saturatedFat_g: 2.4, transFat_g: 0,
            carbs_g: 5, sugar_g: 5, sodium_mg: 50,
            allergens: ['乳制品'], isSugarFree: false, isSucroseFree: true, sweeteners: [],
            manufacturer: '蒙牛乳业', entrustInfo: '', scNumber: 'SC12345000007', dataCompleteness: 'complete'
        },
        {
            productName: '无糖可乐', brand: '可口可乐', netWeight_g: 330,
            energy_kj: 0, protein_g: 0, fat_g: 0, saturatedFat_g: 0, transFat_g: 0,
            carbs_g: 0, sugar_g: 0, sodium_mg: 20,
            allergens: [], isSugarFree: true, isSucroseFree: true, sweeteners: ['阿斯巴甜', '安赛蜜'],
            manufacturer: '可口可乐', entrustInfo: '', scNumber: 'SC12345000008', dataCompleteness: 'complete'
        },
        // ===== 烘焙食品类 =====
        {
            productName: '全麦面包', brand: '桃李', netWeight_g: 200,
            energy_kj: 900, protein_g: 8, fat_g: 3, saturatedFat_g: 0.5, transFat_g: 0,
            carbs_g: 40, sugar_g: 5, sodium_mg: 250,
            allergens: ['小麦', '麸质'], isSugarFree: false, isSucroseFree: true, sweeteners: [],
            manufacturer: '桃李面包', entrustInfo: '', scNumber: 'SC12345000009', dataCompleteness: 'complete'
        },
        {
            productName: '无糖全麦饼干', brand: '谷优', netWeight_g: 80,
            energy_kj: 1500, protein_g: 8, fat_g: 8, saturatedFat_g: 2, transFat_g: 0,
            carbs_g: 55, sugar_g: 1, sodium_mg: 150,
            allergens: ['小麦', '麸质'], isSugarFree: true, isSucroseFree: true, sweeteners: ['麦芽糖醇'],
            manufacturer: '谷优食品', entrustInfo: '', scNumber: 'SC12345000010', dataCompleteness: 'complete'
        },
        // ===== 酱料/调味品类 =====
        {
            productName: '低钠酱油', brand: '李锦记', netWeight_g: 500,
            energy_kj: 200, protein_g: 5, fat_g: 0, saturatedFat_g: 0, transFat_g: 0,
            carbs_g: 8, sugar_g: 4, sodium_mg: 4000,
            allergens: ['大豆', '小麦'], isSugarFree: false, isSucroseFree: true, sweeteners: [],
            manufacturer: '李锦记', entrustInfo: '', scNumber: 'SC12345000011', dataCompleteness: 'complete'
        },
        {
            productName: '零脂油醋汁', brand: '百利', netWeight_g: 200,
            energy_kj: 150, protein_g: 0.5, fat_g: 0, saturatedFat_g: 0, transFat_g: 0,
            carbs_g: 8, sugar_g: 5, sodium_mg: 600,
            allergens: [], isSugarFree: false, isSucroseFree: true, sweeteners: [],
            manufacturer: '百利食品', entrustInfo: '', scNumber: 'SC12345000012', dataCompleteness: 'complete'
        },
        // ===== 主食/速食类 =====
        {
            productName: '荞麦方便面', brand: '农心', netWeight_g: 100,
            energy_kj: 1400, protein_g: 6, fat_g: 5, saturatedFat_g: 1.5, transFat_g: 0,
            carbs_g: 60, sugar_g: 3, sodium_mg: 800,
            allergens: ['小麦', '麸质'], isSugarFree: false, isSucroseFree: true, sweeteners: [],
            manufacturer: '农心食品', entrustInfo: '', scNumber: 'SC12345000013', dataCompleteness: 'complete'
        },
        {
            productName: '即食鸡胸肉', brand: '优形', netWeight_g: 100,
            energy_kj: 550, protein_g: 25, fat_g: 2, saturatedFat_g: 0.5, transFat_g: 0,
            carbs_g: 2, sugar_g: 0, sodium_mg: 400,
            allergens: [], isSugarFree: true, isSucroseFree: true, sweeteners: [],
            manufacturer: '优形食品', entrustInfo: '', scNumber: 'SC12345000014', dataCompleteness: 'complete'
        },
        // ===== 糖果/甜品类 =====
        {
            productName: '黑巧克力(85%)', brand: '每日黑巧', netWeight_g: 50,
            energy_kj: 2200, protein_g: 10, fat_g: 40, saturatedFat_g: 24, transFat_g: 0,
            carbs_g: 25, sugar_g: 12, sodium_mg: 10,
            allergens: ['乳制品'], isSugarFree: false, isSucroseFree: false, sweeteners: [],
            manufacturer: '每日黑巧', entrustInfo: '', scNumber: 'SC12345000015', dataCompleteness: 'complete'
        },
        {
            productName: '零卡果冻', brand: '喜之郎', netWeight_g: 80,
            energy_kj: 20, protein_g: 0, fat_g: 0, saturatedFat_g: 0, transFat_g: 0,
            carbs_g: 1, sugar_g: 0, sodium_mg: 15,
            allergens: [], isSugarFree: true, isSucroseFree: true, sweeteners: ['赤藓糖醇', '三氯蔗糖'],
            manufacturer: '喜之郎', entrustInfo: '', scNumber: 'SC12345000016', dataCompleteness: 'complete'
        }
    ];
    /**
     * 根据品类筛选食品
     * @param category - 品类关键词
     * @returns 匹配品类的食品列表
     */
    static filterByCategory(category: string): FoodNutrition[] {
        const results: FoodNutrition[] = [];
        for (const food of MockFoodDatabase.foods) {
            if (food.productName.includes(category) || category.includes(food.productName.substring(0, 2))) {
                results.push(food);
            }
        }
        return results;
    }
    /**
     * 获取所有食品
     */
    static getAll(): FoodNutrition[] {
        return MockFoodDatabase.foods;
    }
}
/**
 * 智能替代品推荐器
 * 根据当前商品的关键限制因素和品类，推荐更健康的替代品
 */
export class AlternativeFoodRecommender {
    /**
     * 为当前商品推荐替代品
     * @param currentFood - 当前扫描的食品
     * @param currentLevel - 当前建议级别（仅ORANGE/RED时触发）
     * @param limitingNutrient - 关键限制因素（如"钠"、"糖"、"热量"）
     * @param member - 当前成员（用于过敏红线过滤）
     * @returns 替代品推荐列表（至少2款）
     */
    static recommend(currentFood: FoodNutrition, currentLevel: RecommendationLevel, limitingNutrient: string, member: FamilyMemberSimple): AlternativeFood[] {
        // 仅当ORANGE或RED时触发推荐
        if (currentLevel !== RecommendationLevel.ORANGE && currentLevel !== RecommendationLevel.RED) {
            return [];
        }
        // 推断当前食品的品类
        const category = AlternativeFoodRecommender.inferCategory(currentFood);
        // 从数据库中搜索替代品
        const candidates = AlternativeFoodRecommender.searchAlternatives(currentFood, category, limitingNutrient, member);
        // 按健康评分排序，取前3款
        candidates.sort((a, b) => b.healthScore - a.healthScore);
        return candidates.slice(0, 3);
    }
    /**
     * 增强版替代品推荐 - 包含NutriScore差值、改善百分比、成员标签
     */
    static recommendEnhanced(currentFood: FoodNutrition, currentLevel: RecommendationLevel, limitingNutrient: string, member: FamilyMemberSimple, allMembers?: FamilyMemberSimple[]): EnhancedAlternative[] {
        const base = AlternativeFoodRecommender.recommend(currentFood, currentLevel, limitingNutrient, member);
        if (base.length === 0)
            return [];
        const currentScore = NutriScoreEngine.calculateFromFoodNutrition(currentFood);
        const enhanced: EnhancedAlternative[] = [];
        const members = allMembers ?? [member];
        for (const alt of base) {
            const altFood = MockFoodDatabase.getAll().find(f => f.productName === alt.productName && f.brand === alt.brand);
            if (altFood === undefined)
                continue;
            const altScore = NutriScoreEngine.calculateFromFoodNutrition(altFood);
            const scoreDiff = altScore.score - currentScore.score;
            const improvements = AlternativeFoodRecommender.calcImprovements(currentFood, altFood, limitingNutrient);
            const bestFor = AlternativeFoodRecommender.determineBestForMembers(altFood, members);
            const enhancedAlt: EnhancedAlternative = {
                productName: alt.productName,
                brand: alt.brand,
                healthScore: alt.healthScore,
                level: alt.level,
                sodium_mg: alt.sodium_mg,
                sugar_g: alt.sugar_g,
                energyKcal: alt.energyKcal,
                reason: alt.reason,
                nutriScoreDiff: scoreDiff,
                improvements: improvements,
                bestForMembers: bestFor
            };
            enhanced.push(enhancedAlt);
        }
        return enhanced;
    }
    /**
     * 计算关键改善指标及百分比
     */
    private static calcImprovements(current: FoodNutrition, alternative: FoodNutrition, _limitingNutrient: string): ImprovementItem[] {
        const items: ImprovementItem[] = [];
        const addIfImproved = (name: string, cur: number, alt: number, unit: string): void => {
            if (cur <= 0)
                return;
            const diff = cur - alt;
            if (diff <= 0)
                return;
            const percent = Math.round((diff / cur) * 100);
            const imp: ImprovementItem = {
                nutrient: name,
                percent: percent,
                description: `${name}减少${percent}% (${alt}${unit}/100g)`
            };
            items.push(imp);
        };
        addIfImproved('钠', current.sodium_mg, alternative.sodium_mg, 'mg');
        addIfImproved('糖', current.sugar_g, alternative.sugar_g, 'g');
        addIfImproved('脂肪', current.fat_g, alternative.fat_g, 'g');
        addIfImproved('饱和脂肪', current.saturatedFat_g, alternative.saturatedFat_g, 'g');
        addIfImproved('热量', FoodParser.kjToKcal(current.energy_kj), FoodParser.kjToKcal(alternative.energy_kj), 'kcal');
        return items.slice(0, 3);
    }
    /**
     * 判断替代品最适合哪些成员
     */
    private static determineBestForMembers(food: FoodNutrition, members: FamilyMemberSimple[]): string[] {
        const tags: string[] = [];
        for (const m of members) {
            let suitable = true;
            if (m.allergenRedline !== undefined) {
                for (const a of food.allergens) {
                    for (const r of m.allergenRedline) {
                        if (a.includes(r) || r.includes(a)) {
                            suitable = false;
                            break;
                        }
                    }
                    if (!suitable)
                        break;
                }
            }
            if (suitable) {
                if (m.healthGoal === 'sugar_control' && food.sugar_g <= 5)
                    tags.push(m.name);
                else if (m.healthGoal === 'blood_pressure' && food.sodium_mg <= 200)
                    tags.push(m.name);
                else if (m.healthGoal === 'fat_loss' && food.fat_g <= 5)
                    tags.push(m.name);
                else if (m.healthGoal === 'children' && food.sugar_g <= 10 && food.sodium_mg <= 300)
                    tags.push(m.name);
            }
        }
        return tags;
    }
    /**
     * 搜索替代品
     * @param currentFood - 当前食品
     * @param category - 品类
     * @param limitingNutrient - 限制因素
     * @param member - 成员
     * @returns 候选替代品列表
     */
    private static searchAlternatives(currentFood: FoodNutrition, category: string, limitingNutrient: string, member: FamilyMemberSimple): AlternativeFood[] {
        const results: AlternativeFood[] = [];
        const allFoods = MockFoodDatabase.getAll();
        for (const food of allFoods) {
            // 排除当前商品自身
            if (food.productName === currentFood.productName && food.brand === currentFood.brand) {
                continue;
            }
            // 品类匹配：名称包含品类关键词或品类关键词包含名称前两个字
            const isCategoryMatch = food.productName.includes(category) ||
                category.includes(food.productName.substring(0, 2));
            if (!isCategoryMatch) {
                continue;
            }
            // 过敏红线过滤：替代品不能触发成员过敏
            if (AlternativeFoodRecommender.hasAllergenConflict(food, member)) {
                continue;
            }
            // 计算该替代品对当前成员的健康评分（简化版）
            const score = AlternativeFoodRecommender.calculateSimpleScore(food, limitingNutrient, member);
            // 只推荐评分更高的替代品
            const currentScore = AlternativeFoodRecommender.calculateSimpleScore(currentFood, limitingNutrient, member);
            if (score <= currentScore) {
                continue;
            }
            // 生成推荐理由
            const reason = AlternativeFoodRecommender.generateReason(food, currentFood, limitingNutrient);
            // 确定级别
            let level: RecommendationLevel = RecommendationLevel.GREEN;
            if (score < 60) {
                level = RecommendationLevel.ORANGE;
            }
            else if (score < 80) {
                level = RecommendationLevel.YELLOW;
            }
            results.push({
                productName: food.productName,
                brand: food.brand,
                healthScore: score,
                level: level,
                sodium_mg: food.sodium_mg,
                sugar_g: food.sugar_g,
                energyKcal: FoodParser.kjToKcal(food.energy_kj),
                reason: reason
            });
        }
        return results;
    }
    /**
     * 检查替代品是否与成员过敏红线冲突
     */
    private static hasAllergenConflict(food: FoodNutrition, member: FamilyMemberSimple): boolean {
        if (!member.allergenRedline || member.allergenRedline.length === 0) {
            return false;
        }
        for (const allergen of food.allergens) {
            for (const redline of member.allergenRedline) {
                if (allergen.includes(redline) || redline.includes(allergen)) {
                    return true;
                }
            }
        }
        return false;
    }
    /**
     * 简化版健康评分计算（仅用于替代品排序）
     */
    private static calculateSimpleScore(food: FoodNutrition, limitingNutrient: string, member: FamilyMemberSimple): number {
        let score = 100;
        // 根据限制因素扣分
        switch (limitingNutrient) {
            case '钠':
                if (food.sodium_mg >= 500) {
                    score -= 30;
                }
                else if (food.sodium_mg >= 200) {
                    score -= 15;
                }
                break;
            case '糖':
                if (food.sugar_g >= 15) {
                    score -= 30;
                }
                else if (food.sugar_g >= 5) {
                    score -= 15;
                }
                break;
            case '热量':
                const kcal = FoodParser.kjToKcal(food.energy_kj);
                if (kcal >= 400) {
                    score -= 30;
                }
                else if (kcal >= 200) {
                    score -= 15;
                }
                break;
            case '脂肪':
                if (food.fat_g >= 20) {
                    score -= 30;
                }
                else if (food.fat_g >= 10) {
                    score -= 15;
                }
                break;
            default:
                break;
        }
        // 数据完整度扣分
        if (food.dataCompleteness === 'minimal') {
            score -= 10;
        }
        else if (food.dataCompleteness === 'partial') {
            score -= 5;
        }
        return Math.max(0, score);
    }
    /**
     * 生成推荐理由
     */
    private static generateReason(alternative: FoodNutrition, current: FoodNutrition, limitingNutrient: string): string {
        switch (limitingNutrient) {
            case '钠':
                const sodiumDiff = current.sodium_mg - alternative.sodium_mg;
                if (sodiumDiff > 0) {
                    const pct = Math.round((sodiumDiff / current.sodium_mg) * 100);
                    return `钠含量低${sodiumDiff}mg/100g（减少${pct}%），更友好`;
                }
                return '整体营养更均衡';
            case '糖':
                const sugarDiff = current.sugar_g - alternative.sugar_g;
                if (sugarDiff > 0) {
                    const pct = Math.round((sugarDiff / current.sugar_g) * 100);
                    return `糖含量低${sugarDiff}g/100g（减少${pct}%），更友好`;
                }
                return '整体营养更均衡';
            case '热量':
                const currentKcal = FoodParser.kjToKcal(current.energy_kj);
                const altKcal = FoodParser.kjToKcal(alternative.energy_kj);
                const kcalDiff = currentKcal - altKcal;
                if (kcalDiff > 0) {
                    const pct = Math.round((kcalDiff / currentKcal) * 100);
                    return `热量低${kcalDiff}kcal/100g（减少${pct}%），更友好`;
                }
                return '整体营养更均衡';
            case '脂肪':
                const fatDiff = current.fat_g - alternative.fat_g;
                if (fatDiff > 0) {
                    const pct = Math.round((fatDiff / current.fat_g) * 100);
                    return `脂肪低${fatDiff}g/100g（减少${pct}%），更友好`;
                }
                return '整体营养更均衡';
            default:
                return '整体营养更均衡';
        }
    }
    /**
     * 获取无替代品时的提示文案
     */
    static getNoAlternativeMessage(category: string, limitingNutrient: string): string {
        return `当前品类暂无可替代商品，建议查看同品类低${limitingNutrient}版本`;
    }
    /**
     * 根据食品名称推断品类
     */
    private static inferCategory(food: FoodNutrition): string {
        const name = food.productName;
        if (name.includes('饼干') || name.includes('薯片') || name.includes('坚果') ||
            name.includes('海苔') || name.includes('糖') || name.includes('果冻') ||
            name.includes('巧克力') || name.includes('辣条') || name.includes('魔芋')) {
            return '零食';
        }
        if (name.includes('茶') || name.includes('奶') || name.includes('可乐') ||
            name.includes('果汁') || name.includes('咖啡') || name.includes('水')) {
            return '饮料';
        }
        if (name.includes('面包') || name.includes('蛋糕') || name.includes('糕')) {
            return '烘焙';
        }
        if (name.includes('酱油') || name.includes('醋') || name.includes('酱') ||
            name.includes('油') || name.includes('调味')) {
            return '调味品';
        }
        if (name.includes('面') || name.includes('饭') || name.includes('粉') ||
            name.includes('粥') || name.includes('鸡胸')) {
            return '主食';
        }
        return '零食';
    }
    /**
     * 基于 FoodLabel 和成员画像查找替代品（供 ReportPage 直接调用）
     * @param currentFood - 当前扫描的食品标签
     * @param member - 当前成员（用于过敏红线过滤）
     * @returns 替代品推荐列表（2-3款）
     */
    static findAlternatives(currentFood: FoodLabel, member: FamilyMemberSimple): AlternativeFood[] {
        // 将 FoodLabel 转换为 FoodNutrition
        const currentNutrition: FoodNutrition = {
            productName: currentFood.foodName,
            brand: currentFood.manufacturer,
            netWeight_g: 100,
            energy_kj: Math.round(currentFood.nutrition.calories * 4.184),
            protein_g: currentFood.nutrition.protein,
            fat_g: currentFood.nutrition.fat,
            saturatedFat_g: currentFood.nutrition.saturatedFat,
            transFat_g: 0,
            carbs_g: currentFood.nutrition.carbohydrate,
            sugar_g: currentFood.nutrition.sugar,
            sodium_mg: currentFood.nutrition.sodium,
            allergens: currentFood.allergenHints,
            isSugarFree: currentFood.nutrition.sugar <= 0.5,
            isSucroseFree: false,
            sweeteners: [],
            manufacturer: currentFood.manufacturer,
            entrustInfo: currentFood.principal,
            scNumber: currentFood.scNumber,
            dataCompleteness: currentFood.hasManufacturer() ? 'complete' : 'partial'
        };
        // 确定限制因素
        let limitingNutrient = '钠';
        if (currentFood.isHighSugar()) {
            limitingNutrient = '糖';
        }
        else if (currentFood.isHighCalorie()) {
            limitingNutrient = '热量';
        }
        else if (currentFood.isHighFat()) {
            limitingNutrient = '脂肪';
        }
        // 确定当前级别
        let currentLevel: RecommendationLevel = RecommendationLevel.YELLOW;
        if (currentFood.isHighSodium() || currentFood.isHighSugar() || currentFood.isHighFat()) {
            currentLevel = RecommendationLevel.ORANGE;
        }
        // 调用核心推荐方法
        return AlternativeFoodRecommender.recommend(currentNutrition, currentLevel, limitingNutrient, member);
    }
}
