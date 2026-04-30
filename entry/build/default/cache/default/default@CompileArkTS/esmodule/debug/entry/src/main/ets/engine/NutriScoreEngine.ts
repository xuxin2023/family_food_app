import type { FoodNutrition } from '../model/FoodAdapterTypes';
/**
 * Nutri-Score 等级枚举
 */
export enum NutriScoreGrade {
    A = "A",
    B = "B",
    C = "C",
    D = "D",
    E = "E" // 0-24   红
}
/**
 * Nutri-Score 等级显示信息
 */
export class NutriScoreGradeInfo {
    grade: NutriScoreGrade = NutriScoreGrade.C;
    score: number = 50;
    color: string = '#FFC107'; // 默认黄色
    label: string = 'C';
}
/**
 * Nutri-Score 扣分/加分明细项
 */
export class NutriScoreDetail {
    /** 项目名称：能量/饱和脂肪/糖/钠/膳食纤维/蛋白质/果蔬比例/甜味剂 */
    name: string = '';
    /** 分值（负数为扣分，正数为加分） */
    points: number = 0;
    /** 类型：negative（负向）/ positive（正向）/ penalty（惩罚） */
    type: string = 'negative';
    /** 原始值 */
    value: number = 0;
    /** 单位 */
    unit: string = '';
}
/**
 * Nutri-Score 计算结果
 */
export class NutriScoreResult {
    /** 总分 0-100 */
    score: number = 0;
    /** 等级 A-E */
    grade: NutriScoreGrade = NutriScoreGrade.C;
    /** 等级颜色 */
    gradeColor: string = '#FFC107';
    /** 等级标签 */
    gradeLabel: string = 'C';
    /** 扣分/加分明细列表 */
    details: NutriScoreDetail[] = [];
    /** 原始负向总分（N） */
    negativeScore: number = 0;
    /** 原始正向总分（P） */
    positiveScore: number = 0;
    /** 甜味剂扣分 */
    sweetenerPenalty: number = 0;
}
/**
 * 等级映射条目
 */
class GradeMapEntry {
    min: number = 0;
    max: number = 0;
    grade: NutriScoreGrade = NutriScoreGrade.C;
    color: string = '';
    label: string = '';
}
/**
 * Nutri-Score 综合健康评分引擎
 * 基于欧洲 Nutri-Score 体系适配中国食品标签
 */
export class NutriScoreEngine {
    // ==================== 负向评分阈值 ====================
    // 能量(kJ/100g)：0分起点≤335kJ，每增加335kJ扣1分，上限10分
    private static readonly ENERGY_THRESHOLD = 335; // kJ
    private static readonly ENERGY_MAX_POINTS = 10;
    // 饱和脂肪(g/100g)：0分起点≤1g，每增加1g扣1分，上限10分
    private static readonly SATFAT_THRESHOLD = 1; // g
    private static readonly SATFAT_MAX_POINTS = 10;
    // 糖(g/100g)：0分起点≤4.5g，每增加4.5g扣1分，上限10分
    private static readonly SUGAR_THRESHOLD = 4.5; // g
    private static readonly SUGAR_MAX_POINTS = 10;
    // 钠(mg/100g)：0分起点≤90mg，每增加90mg扣1分，上限10分
    private static readonly SODIUM_THRESHOLD = 90; // mg
    private static readonly SODIUM_MAX_POINTS = 10;
    // ==================== 正向评分阈值 ====================
    // 膳食纤维(g/100g)：0分起点≤0.7g，每增加0.7g加1分，上限5分
    private static readonly FIBER_THRESHOLD = 0.7; // g
    private static readonly FIBER_MAX_POINTS = 5;
    // 蛋白质(g/100g)：N分≥11时启用蛋白质加分，每增加1.1g加1分，上限5分
    private static readonly PROTEIN_THRESHOLD = 1.1; // g
    private static readonly PROTEIN_MAX_POINTS = 5;
    private static readonly PROTEIN_ACTIVATE_N_SCORE = 11;
    // 果蔬坚果比例(%)：0分起点≤40%，每增加10%加1分，上限5分
    private static readonly FVP_THRESHOLD = 10; // %
    private static readonly FVP_MAX_POINTS = 5;
    // ==================== 甜味剂惩罚 ====================
    // 含无营养甜味剂额外扣1分
    private static readonly SWEETENER_PENALTY = 1;
    // ==================== 等级映射 ====================
    private static readonly GRADE_MAP: GradeMapEntry[] = [
        { min: 85, max: 100, grade: NutriScoreGrade.A, color: '#1B5E20', label: 'A 优秀' } as GradeMapEntry,
        { min: 70, max: 84, grade: NutriScoreGrade.B, color: '#4CAF50', label: 'B 良好' } as GradeMapEntry,
        { min: 40, max: 69, grade: NutriScoreGrade.C, color: '#FFC107', label: 'C 中等' } as GradeMapEntry,
        { min: 25, max: 39, grade: NutriScoreGrade.D, color: '#FF9800', label: 'D 较差' } as GradeMapEntry,
        { min: 0, max: 24, grade: NutriScoreGrade.E, color: '#F44336', label: 'E 避免' } as GradeMapEntry
    ];
    // ==================== 无营养甜味剂列表 ====================
    // 覆盖中文商业名称、英文名称及常见缩写
    private static readonly NON_NUTRITIVE_SWEETENERS: string[] = [
        // 中文名称
        '阿斯巴甜', '安赛蜜', '三氯蔗糖', '甜蜜素', '糖精',
        '纽甜', '甜菊糖苷', '罗汉果甜苷', '赤藓糖醇', '木糖醇',
        '山梨糖醇', '麦芽糖醇', '甘露糖醇', '异麦芽酮糖醇',
        '乳糖醇', '甜菊糖', '甜菊醇糖苷', '索马甜', '爱德万甜',
        '阿力甜', '环己基氨基磺酸钠', '乙酰磺胺酸钾',
        // 英文名称
        'aspartame', 'acesulfame', 'sucralose', 'saccharin', 'stevia',
        'steviol glycosides', 'neotame', 'advantame', 'cyclamate',
        'erythritol', 'xylitol', 'sorbitol', 'maltitol', 'mannitol',
        'isomalt', 'lactitol', 'thaumatin', 'tagatose'
    ];
    // ==================== 膳食纤维关键词列表（用于从配料表推断） ====================
    private static readonly FIBER_KEYWORDS: string[] = [
        '膳食纤维', '菊粉', '低聚果糖', '聚葡萄糖', '抗性糊精',
        '燕麦纤维', '小麦纤维', '大豆纤维', '苹果纤维', '魔芋精粉',
        '葡甘露聚糖', 'β-葡聚糖', '壳聚糖', '瓜尔胶', '黄原胶',
        '果胶', '海藻酸钠', '卡拉胶', '阿拉伯胶', 'inulin',
        'fructooligosaccharide', 'polydextrose', 'resistant dextrin'
    ];
    // ==================== 果蔬坚果关键词列表（用于从配料表推断） ====================
    private static readonly FVP_KEYWORDS: string[] = [
        '蔬菜', '水果', '坚果', '果干', '果仁', '蔓越莓', '蓝莓',
        '草莓', '树莓', '黑莓', '苹果', '香蕉', '橙子', '柠檬',
        '猕猴桃', '芒果', '菠萝', '木瓜', '石榴', '葡萄', '樱桃',
        '西梅', '无花果', '椰子', '牛油果', '番茄', '胡萝卜',
        '菠菜', '西兰花', '南瓜', '玉米', '青豆', '豌豆',
        '杏仁', '核桃', '腰果', '开心果', '松子', '榛子', '夏威夷果',
        '花生', '瓜子', '芝麻', '亚麻籽', '奇亚籽', '南瓜籽'
    ];
    /**
     * 计算 Nutri-Score 综合健康评分
     * @param food - 食品营养数据（每100g含量）
     * @param fruitVegPct - 果蔬坚果比例（%），默认0表示未知
     * @param fiber_g - 膳食纤维含量（g/100g），默认0表示未知
     * @returns NutriScoreResult 评分结果
     */
    static calculateNutriScore(food: FoodNutrition, fruitVegPct: number = 0, fiber_g: number = 0): NutriScoreResult {
        const result = new NutriScoreResult();
        const details: NutriScoreDetail[] = [];
        // ===== 步骤1：计算负向总分 N（0-40） =====
        const energyPoints = NutriScoreEngine.calcNegativePoints(food.energy_kj, NutriScoreEngine.ENERGY_THRESHOLD, NutriScoreEngine.ENERGY_MAX_POINTS, '能量', 'kJ');
        details.push(energyPoints);
        const satFatPoints = NutriScoreEngine.calcNegativePoints(food.saturatedFat_g, NutriScoreEngine.SATFAT_THRESHOLD, NutriScoreEngine.SATFAT_MAX_POINTS, '饱和脂肪', 'g');
        details.push(satFatPoints);
        const sugarPoints = NutriScoreEngine.calcNegativePoints(food.sugar_g, NutriScoreEngine.SUGAR_THRESHOLD, NutriScoreEngine.SUGAR_MAX_POINTS, '糖', 'g');
        details.push(sugarPoints);
        const sodiumPoints = NutriScoreEngine.calcNegativePoints(food.sodium_mg, NutriScoreEngine.SODIUM_THRESHOLD, NutriScoreEngine.SODIUM_MAX_POINTS, '钠', 'mg');
        details.push(sodiumPoints);
        const negativeScore = energyPoints.points + satFatPoints.points +
            sugarPoints.points + sodiumPoints.points;
        result.negativeScore = negativeScore;
        // ===== 步骤2：计算正向总分 P（0-15） =====
        let positiveScore = 0;
        // 膳食纤维加分
        if (fiber_g > 0) {
            const fiberPoints = NutriScoreEngine.calcPositivePoints(fiber_g, NutriScoreEngine.FIBER_THRESHOLD, NutriScoreEngine.FIBER_MAX_POINTS, '膳食纤维', 'g');
            details.push(fiberPoints);
            positiveScore += fiberPoints.points;
        }
        // 果蔬坚果比例加分
        if (fruitVegPct > 0) {
            const fvpPoints = NutriScoreEngine.calcPositivePoints(fruitVegPct, NutriScoreEngine.FVP_THRESHOLD, NutriScoreEngine.FVP_MAX_POINTS, '果蔬坚果比例', '%');
            details.push(fvpPoints);
            positiveScore += fvpPoints.points;
        }
        // 蛋白质加分（仅在 N >= 11 时启用）
        if (negativeScore >= NutriScoreEngine.PROTEIN_ACTIVATE_N_SCORE && food.protein_g > 0) {
            const proteinPoints = NutriScoreEngine.calcPositivePoints(food.protein_g, NutriScoreEngine.PROTEIN_THRESHOLD, NutriScoreEngine.PROTEIN_MAX_POINTS, '蛋白质', 'g');
            details.push(proteinPoints);
            positiveScore += proteinPoints.points;
        }
        result.positiveScore = positiveScore;
        // ===== 步骤3：计算基础分 =====
        // 基础分 = N - P，范围 -15 到 40
        let baseScore = negativeScore - positiveScore;
        // ===== 步骤4：甜味剂惩罚 =====
        let sweetenerPenalty = 0;
        if (NutriScoreEngine.hasNonNutritiveSweetener(food)) {
            sweetenerPenalty = NutriScoreEngine.SWEETENER_PENALTY;
            details.push({
                name: '无营养甜味剂',
                points: -sweetenerPenalty,
                type: 'penalty',
                value: 1,
                unit: ''
            });
        }
        result.sweetenerPenalty = sweetenerPenalty;
        // ===== 步骤5：映射到 0-100 分 =====
        // 基础分范围 -15 到 40，加上惩罚后范围 -16 到 40
        // 映射到 0-100：score = (1 - (adjustedScore + 16) / 56) * 100
        // 当 adjustedScore = -16 时 score = 100（最健康）
        // 当 adjustedScore = 40 时 score = 0（最不健康）
        const adjustedScore = baseScore + sweetenerPenalty;
        const rawScore = Math.round((1 - (adjustedScore + 16) / 56) * 100);
        const finalScore = Math.max(0, Math.min(100, rawScore));
        result.score = finalScore;
        // ===== 步骤6：映射等级 =====
        const gradeInfo = NutriScoreEngine.getGradeInfo(finalScore);
        result.grade = gradeInfo.grade;
        result.gradeColor = gradeInfo.color;
        result.gradeLabel = gradeInfo.label;
        result.details = details;
        return result;
    }
    /**
     * 计算单项负向扣分
     * @param value - 实际含量
     * @param threshold - 阈值（超过此值开始扣分）
     * @param maxPoints - 最大扣分
     * @param name - 营养素名称
     * @param unit - 单位
     * @returns 扣分明细
     */
    private static calcNegativePoints(value: number, threshold: number, maxPoints: number, name: string, unit: string): NutriScoreDetail {
        const detail = new NutriScoreDetail();
        detail.name = name;
        detail.type = 'negative';
        detail.value = value;
        detail.unit = unit;
        if (value <= 0) {
            detail.points = 0;
            return detail;
        }
        // 计算扣分：每超过一个阈值扣1分
        const points = Math.min(maxPoints, Math.floor(value / threshold));
        detail.points = points;
        return detail;
    }
    /**
     * 计算单项正向加分
     * @param value - 实际含量
     * @param threshold - 阈值（每达到此值加1分）
     * @param maxPoints - 最大加分
     * @param name - 营养素名称
     * @param unit - 单位
     * @returns 加分明细
     */
    private static calcPositivePoints(value: number, threshold: number, maxPoints: number, name: string, unit: string): NutriScoreDetail {
        const detail = new NutriScoreDetail();
        detail.name = name;
        detail.type = 'positive';
        detail.value = value;
        detail.unit = unit;
        if (value <= 0) {
            detail.points = 0;
            return detail;
        }
        // 计算加分：每达到一个阈值加1分
        const points = Math.min(maxPoints, Math.floor(value / threshold));
        detail.points = points;
        return detail;
    }
    /**
     * 检查食品是否含无营养甜味剂
     * @param food - 食品营养数据
     * @returns true 表示含无营养甜味剂
     */
    private static hasNonNutritiveSweetener(food: FoodNutrition): boolean {
        if (!food.sweeteners || food.sweeteners.length === 0) {
            return false;
        }
        for (const sweetener of food.sweeteners) {
            const lower = sweetener.toLowerCase();
            for (const keyword of NutriScoreEngine.NON_NUTRITIVE_SWEETENERS) {
                if (lower.includes(keyword.toLowerCase())) {
                    return true;
                }
            }
        }
        return false;
    }
    /**
     * 根据分数获取等级信息
     * @param score - 0-100 分
     * @returns 等级信息（等级、颜色、标签）
     */
    static getGradeInfo(score: number): NutriScoreGradeInfo {
        const info = new NutriScoreGradeInfo();
        info.score = score;
        for (const entry of NutriScoreEngine.GRADE_MAP) {
            if (score >= entry.min && score <= entry.max) {
                info.grade = entry.grade;
                info.color = entry.color;
                info.label = entry.label;
                return info;
            }
        }
        // 默认返回 C 级
        return info;
    }
    /**
     * 获取等级对应的颜色
     * @param grade - Nutri-Score 等级
     * @returns 十六进制颜色值
     */
    static getGradeColor(grade: NutriScoreGrade): string {
        for (const entry of NutriScoreEngine.GRADE_MAP) {
            if (entry.grade === grade) {
                return entry.color;
            }
        }
        return '#FFC107';
    }
    /**
     * 从 FoodNutrition 计算 Nutri-Score（便捷方法）
     * 自动从产品名称推断膳食纤维和果蔬比例
     * @param food - 食品营养数据
     * @returns NutriScoreResult
     */
    static calculateFromFoodNutrition(food: FoodNutrition): NutriScoreResult {
        // 从产品名称推断膳食纤维含量
        const inferredFiber = NutriScoreEngine.inferFiberFromProductName(food);
        // 从产品名称推断果蔬坚果比例
        const inferredFvp = NutriScoreEngine.inferFruitVegPctFromProductName(food);
        return NutriScoreEngine.calculateNutriScore(food, inferredFvp, inferredFiber);
    }
    /**
     * 从产品名称推断膳食纤维含量（g/100g）
     * 当产品名称含膳食纤维相关关键词时，估算合理值
     * @param food - 食品营养数据
     * @returns 推断的膳食纤维含量（g/100g）
     */
    private static inferFiberFromProductName(food: FoodNutrition): number {
        const name = (food.productName ?? '').toLowerCase();
        for (const keyword of NutriScoreEngine.FIBER_KEYWORDS) {
            if (name.includes(keyword.toLowerCase())) {
                // 含膳食纤维关键词，估算3g/100g（中等水平）
                return 3;
            }
        }
        // 全麦/燕麦/杂粮类食品通常含较多膳食纤维
        if (name.includes('全麦') || name.includes('燕麦') || name.includes('杂粮') ||
            name.includes('荞麦') || name.includes('黑麦') || name.includes('麸皮') ||
            name.includes('whole wheat') || name.includes('oat') || name.includes('bran')) {
            return 4;
        }
        // 坚果类
        if (name.includes('坚果') || name.includes('杏仁') || name.includes('核桃') ||
            name.includes('nut') || name.includes('almond')) {
            return 5;
        }
        // 蔬菜类
        if (name.includes('蔬菜') || name.includes('vegetable') || name.includes('沙拉')) {
            return 2;
        }
        return 0;
    }
    /**
     * 从产品名称推断果蔬坚果比例（%）
     * @param food - 食品营养数据
     * @returns 推断的果蔬坚果比例（%）
     */
    private static inferFruitVegPctFromProductName(food: FoodNutrition): number {
        const name = (food.productName ?? '').toLowerCase();
        let matchCount = 0;
        for (const keyword of NutriScoreEngine.FVP_KEYWORDS) {
            if (name.includes(keyword.toLowerCase())) {
                matchCount++;
            }
        }
        if (matchCount >= 3) {
            return 80; // 多种果蔬，高比例
        }
        if (matchCount >= 2) {
            return 60; // 两种果蔬，中等比例
        }
        if (matchCount >= 1) {
            return 40; // 一种果蔬，较低比例
        }
        return 0;
    }
}
