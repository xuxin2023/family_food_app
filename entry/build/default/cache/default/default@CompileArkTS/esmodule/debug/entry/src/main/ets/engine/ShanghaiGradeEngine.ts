import type { FoodNutrition } from '../model/FoodAdapterTypes';
// ==================== 类型定义 ====================
/**
 * 单项指标分级结果
 */
export class GradeDetail {
    /** 指标名称：非乳源性糖 / 饱和脂肪 / 反式脂肪 / 非糖甜味剂 */
    name: string = '';
    /** 单项等级：A / B / C / D */
    grade: string = '';
    /** 实际含量值 */
    value: number = 0;
    /** 单位 */
    unit: string = '';
    /** 等级说明 */
    reason: string = '';
}
/**
 * 上海"营养选择"饮料分级结果
 */
export class ShanghaiGradeResult {
    /** 最终总体等级：A / B / C / D */
    grade: string = '';
    /** 等级对应颜色 */
    gradeColor: string = '';
    /** 等级文字说明 */
    gradeText: string = '';
    /** 四项指标各自的分级详情 */
    details: GradeDetail[] = [];
    /** 是否适用于该分级（仅饮料类适用） */
    isApplicable: boolean = false;
    /** 若不适用，说明原因 */
    notApplicableReason: string = '';
}
// ==================== 分级阈值常量 ====================
/**
 * 非乳源性糖分级阈值（g/100mL）
 * A级：≤0.5g（无糖标准）
 * B级：≤5g（低糖标准）
 * C级：≤11.25g（中等含糖）
 * D级：>11.25g（高糖）
 */
class NonMilkSugarThreshold {
    static readonly A_MAX: number = 0.5; // g/100mL
    static readonly B_MAX: number = 5.0; // g/100mL
    static readonly C_MAX: number = 11.25; // g/100mL
}
/**
 * 饱和脂肪分级阈值（g/100mL）
 * A级：≤0.75g
 * B级：≤1.5g
 * C级：≤2.25g
 * D级：>2.25g
 */
class SaturatedFatThreshold {
    static readonly A_MAX: number = 0.75; // g/100mL
    static readonly B_MAX: number = 1.5; // g/100mL
    static readonly C_MAX: number = 2.25; // g/100mL
}
/**
 * 反式脂肪分级阈值（g/100mL）
 * A级：≤0.3g
 * B级：≤0.6g
 * C级：≤0.9g
 * D级：>0.9g
 */
class TransFatThreshold {
    static readonly A_MAX: number = 0.3; // g/100mL
    static readonly B_MAX: number = 0.6; // g/100mL
    static readonly C_MAX: number = 0.9; // g/100mL
}
/**
 * 非糖甜味剂分级
 * A级：不使用任何非糖甜味剂
 * B级：使用1种非糖甜味剂
 * C级：使用2种非糖甜味剂
 * D级：使用3种及以上非糖甜味剂
 */
class NonSugarSweetenerThreshold {
    static readonly A_MAX: number = 0; // 不使用
    static readonly B_MAX: number = 1; // 1种
    static readonly C_MAX: number = 2; // 2种
}
/**
 * 非糖甜味剂识别列表
 * 用于从食品配料表中识别非糖甜味剂
 */
class NonSugarSweetenerKeywords {
    static readonly LIST: string[] = [
        // 人工合成甜味剂
        '阿斯巴甜', '安赛蜜', '三氯蔗糖', '甜蜜素', '糖精钠',
        '纽甜', '爱德万甜', '阿力甜', '环己基氨基磺酸钠',
        '乙酰磺胺酸钾', '蔗糖素',
        // 天然甜味剂（非营养性）
        '甜菊糖苷', '甜菊糖', '甜菊醇糖苷', '罗汉果甜苷',
        '索马甜', '奇异果甜蛋白',
        // 英文名称
        'aspartame', 'acesulfame', 'sucralose', 'saccharin',
        'stevia', 'steviol glycosides', 'neotame', 'advantame',
        'cyclamate', 'thaumatin', 'mogroside'
    ];
}
// ==================== 等级显示信息常量 ====================
class GradeDisplayInfoEntry {
    color: string = '';
    text: string = '';
}
class GradeDisplayInfo {
    static readonly A: GradeDisplayInfoEntry = {
        color: '#2E7D32',
        text: '推荐'
    } as GradeDisplayInfoEntry;
    static readonly B: GradeDisplayInfoEntry = {
        color: '#66BB6A',
        text: '可接受'
    } as GradeDisplayInfoEntry;
    static readonly C: GradeDisplayInfoEntry = {
        color: '#FF9800',
        text: '谨慎选择'
    } as GradeDisplayInfoEntry;
    static readonly D: GradeDisplayInfoEntry = {
        color: '#F44336',
        text: '不建议'
    } as GradeDisplayInfoEntry;
}
// ==================== 引擎实现 ====================
/**
 * 上海"营养选择"饮料分级引擎
 * 依据上海市疾病预防控制中心2024年3月试行的"营养选择"标识标准
 * 适用于饮料类食品，综合考量非乳源性糖、饱和脂肪、反式脂肪、非糖甜味剂四项指标
 */
export class ShanghaiGradeEngine {
    /**
     * 计算上海"营养选择"饮料分级
     * @param food - 食品营养数据
     * @returns ShanghaiGradeResult 分级结果
     */
    static calculateShanghaiGrade(food: FoodNutrition): ShanghaiGradeResult {
        const result = new ShanghaiGradeResult();
        // ===== 步骤1：判断是否适用于饮料类 =====
        const isApplicable = ShanghaiGradeEngine.isBeverage(food);
        result.isApplicable = isApplicable;
        if (!isApplicable) {
            result.notApplicableReason = '该产品不属于饮料类，不适用上海"营养选择"饮料分级标识';
            result.grade = 'N/A';
            result.gradeColor = '#9E9E9E';
            result.gradeText = '不适用';
            return result;
        }
        // ===== 步骤2：计算四项指标各自等级 =====
        const details: GradeDetail[] = [];
        // 2.1 非乳源性糖分级
        const sugarGrade = ShanghaiGradeEngine.calcNonMilkSugarGrade(food);
        details.push(sugarGrade);
        // 2.2 饱和脂肪分级
        const satFatGrade = ShanghaiGradeEngine.calcSaturatedFatGrade(food);
        details.push(satFatGrade);
        // 2.3 反式脂肪分级
        const transFatGrade = ShanghaiGradeEngine.calcTransFatGrade(food);
        details.push(transFatGrade);
        // 2.4 非糖甜味剂分级
        const sweetenerGrade = ShanghaiGradeEngine.calcNonSugarSweetenerGrade(food);
        details.push(sweetenerGrade);
        result.details = details;
        // ===== 步骤3：短板原则——取四项中最低等级 =====
        const grades = details.map(item => item.grade);
        const finalGrade = ShanghaiGradeEngine.getLowestGrade(grades);
        result.grade = finalGrade;
        // ===== 步骤4：设置显示信息 =====
        const displayInfo = ShanghaiGradeEngine.getGradeDisplayInfo(finalGrade);
        result.gradeColor = displayInfo.color;
        result.gradeText = displayInfo.text;
        return result;
    }
    /**
     * 判断食品是否属于饮料类
     * @param food - 食品营养数据
     * @returns true 表示属于饮料类
     */
    private static isBeverage(food: FoodNutrition): boolean {
        const name = (food.productName ?? '').toLowerCase();
        const brand = (food.brand ?? '').toLowerCase();
        // 饮料类关键词
        const beverageKeywords: string[] = [
            '饮料', '饮品', '茶', '奶茶', '果汁', '汽水', '碳酸',
            '苏打水', '矿泉水', '纯净水', '饮用水', '运动饮料',
            '功能饮料', '能量饮料', '电解质', '咖啡', '拿铁',
            '奶昔', '酸奶饮品', '乳酸菌', '豆奶', '椰汁',
            '植物蛋白饮料', '谷物饮料', '凉茶', '花茶',
            'beverage', 'drink', 'juice', 'soda', 'cola',
            'tea', 'coffee', 'latte', 'smoothie', 'yogurt drink'
        ];
        for (const keyword of beverageKeywords) {
            if (name.includes(keyword) || brand.includes(keyword)) {
                return true;
            }
        }
        return false;
    }
    /**
     * 计算非乳源性糖等级
     * @param food - 食品营养数据
     * @returns 非乳源性糖分级详情
     */
    private static calcNonMilkSugarGrade(food: FoodNutrition): GradeDetail {
        const detail = new GradeDetail();
        detail.name = '非乳源性糖';
        detail.value = food.sugar_g;
        detail.unit = 'g/100mL';
        const sugar = food.sugar_g;
        if (sugar <= NonMilkSugarThreshold.A_MAX) {
            detail.grade = 'A';
            detail.reason = `含糖量≤${NonMilkSugarThreshold.A_MAX}g/100mL，达到无糖标准`;
        }
        else if (sugar <= NonMilkSugarThreshold.B_MAX) {
            detail.grade = 'B';
            detail.reason = `含糖量≤${NonMilkSugarThreshold.B_MAX}g/100mL，达到低糖标准`;
        }
        else if (sugar <= NonMilkSugarThreshold.C_MAX) {
            detail.grade = 'C';
            detail.reason = `含糖量≤${NonMilkSugarThreshold.C_MAX}g/100mL，含糖量中等`;
        }
        else {
            detail.grade = 'D';
            detail.reason = `含糖量>${NonMilkSugarThreshold.C_MAX}g/100mL，含糖量较高`;
        }
        return detail;
    }
    /**
     * 计算饱和脂肪等级
     * @param food - 食品营养数据
     * @returns 饱和脂肪分级详情
     */
    private static calcSaturatedFatGrade(food: FoodNutrition): GradeDetail {
        const detail = new GradeDetail();
        detail.name = '饱和脂肪';
        detail.value = food.saturatedFat_g;
        detail.unit = 'g/100mL';
        const satFat = food.saturatedFat_g;
        if (satFat <= SaturatedFatThreshold.A_MAX) {
            detail.grade = 'A';
            detail.reason = `饱和脂肪≤${SaturatedFatThreshold.A_MAX}g/100mL，含量较低`;
        }
        else if (satFat <= SaturatedFatThreshold.B_MAX) {
            detail.grade = 'B';
            detail.reason = `饱和脂肪≤${SaturatedFatThreshold.B_MAX}g/100mL，含量适中`;
        }
        else if (satFat <= SaturatedFatThreshold.C_MAX) {
            detail.grade = 'C';
            detail.reason = `饱和脂肪≤${SaturatedFatThreshold.C_MAX}g/100mL，含量偏高`;
        }
        else {
            detail.grade = 'D';
            detail.reason = `饱和脂肪>${SaturatedFatThreshold.C_MAX}g/100mL，含量较高`;
        }
        return detail;
    }
    /**
     * 计算反式脂肪等级
     * @param food - 食品营养数据
     * @returns 反式脂肪分级详情
     */
    private static calcTransFatGrade(food: FoodNutrition): GradeDetail {
        const detail = new GradeDetail();
        detail.name = '反式脂肪';
        detail.value = food.transFat_g;
        detail.unit = 'g/100mL';
        const transFat = food.transFat_g;
        if (transFat <= TransFatThreshold.A_MAX) {
            detail.grade = 'A';
            detail.reason = `反式脂肪≤${TransFatThreshold.A_MAX}g/100mL，含量较低`;
        }
        else if (transFat <= TransFatThreshold.B_MAX) {
            detail.grade = 'B';
            detail.reason = `反式脂肪≤${TransFatThreshold.B_MAX}g/100mL，含量适中`;
        }
        else if (transFat <= TransFatThreshold.C_MAX) {
            detail.grade = 'C';
            detail.reason = `反式脂肪≤${TransFatThreshold.C_MAX}g/100mL，含量偏高`;
        }
        else {
            detail.grade = 'D';
            detail.reason = `反式脂肪>${TransFatThreshold.C_MAX}g/100mL，含量较高`;
        }
        return detail;
    }
    /**
     * 计算非糖甜味剂等级
     * @param food - 食品营养数据
     * @returns 非糖甜味剂分级详情
     */
    private static calcNonSugarSweetenerGrade(food: FoodNutrition): GradeDetail {
        const detail = new GradeDetail();
        detail.name = '非糖甜味剂';
        detail.value = 0;
        detail.unit = '种';
        // 统计使用的非糖甜味剂种类数
        const sweetenerCount = ShanghaiGradeEngine.countNonSugarSweeteners(food);
        detail.value = sweetenerCount;
        if (sweetenerCount <= NonSugarSweetenerThreshold.A_MAX) {
            detail.grade = 'A';
            detail.reason = '未使用非糖甜味剂';
        }
        else if (sweetenerCount <= NonSugarSweetenerThreshold.B_MAX) {
            detail.grade = 'B';
            detail.reason = '使用1种非糖甜味剂';
        }
        else if (sweetenerCount <= NonSugarSweetenerThreshold.C_MAX) {
            detail.grade = 'C';
            detail.reason = '使用2种非糖甜味剂';
        }
        else {
            detail.grade = 'D';
            detail.reason = `使用${sweetenerCount}种非糖甜味剂，种类较多`;
        }
        return detail;
    }
    /**
     * 统计食品中使用的非糖甜味剂种类数
     * @param food - 食品营养数据
     * @returns 非糖甜味剂种类数
     */
    private static countNonSugarSweeteners(food: FoodNutrition): number {
        if (!food.sweeteners || food.sweeteners.length === 0) {
            return 0;
        }
        const matched = new Set<string>();
        for (const sweetener of food.sweeteners) {
            const lower = sweetener.toLowerCase();
            for (const keyword of NonSugarSweetenerKeywords.LIST) {
                if (lower.includes(keyword.toLowerCase())) {
                    matched.add(keyword);
                    break;
                }
            }
        }
        return matched.size;
    }
    /**
     * 取多个等级中的最低级（短板原则）
     * 等级高低：A > B > C > D
     * @param grades - 等级数组
     * @returns 最低等级
     */
    private static getLowestGrade(grades: string[]): string {
        const gradeOrder: string[] = ['A', 'B', 'C', 'D'];
        let lowest = 'A';
        for (const grade of grades) {
            const currentIndex = gradeOrder.indexOf(grade);
            const lowestIndex = gradeOrder.indexOf(lowest);
            if (currentIndex > lowestIndex) {
                lowest = grade;
            }
        }
        return lowest;
    }
    /**
     * 获取等级对应的显示信息（颜色和文字）
     * @param grade - 等级 A/B/C/D
     * @returns 显示信息
     */
    private static getGradeDisplayInfo(grade: string): GradeDisplayInfoEntry {
        switch (grade) {
            case 'A':
                return GradeDisplayInfo.A;
            case 'B':
                return GradeDisplayInfo.B;
            case 'C':
                return GradeDisplayInfo.C;
            case 'D':
                return GradeDisplayInfo.D;
            default:
                return { color: '#9E9E9E', text: '未知' } as GradeDisplayInfoEntry;
        }
    }
    /**
     * 获取等级对应的颜色值
     * @param grade - 等级 A/B/C/D
     * @returns 十六进制颜色值
     */
    static getGradeColor(grade: string): string {
        return ShanghaiGradeEngine.getGradeDisplayInfo(grade).color;
    }
    /**
     * 获取等级对应的文字说明
     * @param grade - 等级 A/B/C/D
     * @returns 文字说明
     */
    static getGradeText(grade: string): string {
        return ShanghaiGradeEngine.getGradeDisplayInfo(grade).text;
    }
}
