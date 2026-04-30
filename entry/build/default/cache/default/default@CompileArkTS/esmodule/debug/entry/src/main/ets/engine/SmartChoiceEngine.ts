import type { FoodNutrition } from '../model/FoodAdapterTypes';
// ==================== 类型定义 ====================
/**
 * 单项营养指标检查结果
 */
export class CheckedNutrient {
    /** 营养素名称：脂肪 / 饱和脂肪 / 钠 / 糖 */
    name: string = '';
    /** 实际含量值 */
    actualValue: number = 0;
    /** 单位 */
    unit: string = '';
    /** 该食品类别下的界限值 */
    threshold: number = 0;
    /** 是否达标（实际值 ≤ 界限值） */
    isQualified: boolean = false;
    /** 说明 */
    reason: string = '';
}
/**
 * 食品类别信息
 */
export class FoodCategoryInfo {
    /** 大类名称 */
    categoryName: string = '';
    /** 亚类名称 */
    subCategoryName: string = '';
    /** 匹配依据（匹配到的关键词） */
    matchedKeyword: string = '';
}
/**
 * "智慧选择"规范解读结果
 */
export class SmartChoiceResult {
    /** 是否达标（四项指标均符合界限值） */
    eligible: boolean = false;
    /** 达标/未达标的原因逐项列出 */
    reasons: string[] = [];
    /** 脂肪、饱和脂肪、钠、糖各指标的实际值与阈值对比 */
    checkedNutrients: CheckedNutrient[] = [];
    /** 匹配到的食品类别信息 */
    foodCategory: FoodCategoryInfo = new FoodCategoryInfo();
    /** 是否适用于该规范（特殊膳食用食品和保健食品不适用） */
    isApplicable: boolean = false;
    /** 若不适用，说明原因 */
    notApplicableReason: string = '';
}
// ==================== 食品类别与阈值常量 ====================
/**
 * 食品类别定义
 * 覆盖T/CNSS 001-2025规定的十个大类27个亚类
 * 每类定义脂肪(g/100g)、饱和脂肪(g/100g)、钠(mg/100g)、糖(g/100g)的界限值
 *
 * TODO: 接入T/CNSS 001-2025标准全文中的具体类别阈值
 * 当前阈值为基于公开资料估算的参考值，待标准全文发布后校准
 */
class FoodCategoryThreshold {
    /** 大类名称 */
    categoryName: string = '';
    /** 亚类名称 */
    subCategoryName: string = '';
    /** 匹配关键词列表 */
    keywords: string[] = [];
    /** 脂肪界限值（g/100g） */
    fatThreshold: number = 0;
    /** 饱和脂肪界限值（g/100g） */
    satFatThreshold: number = 0;
    /** 钠界限值（mg/100g） */
    sodiumThreshold: number = 0;
    /** 糖界限值（g/100g） */
    sugarThreshold: number = 0;
}
/**
 * 预置的食品类别阈值表
 * 基于T/CNSS 001-2025标准框架，涵盖十个大类
 *
 * 阈值设定参考依据：
 * - 脂肪：参考《中国居民膳食营养素参考摄入量》及同类标准
 * - 饱和脂肪：通常为脂肪含量的1/3
 * - 钠：参考《中国居民膳食指南》低钠标准
 * - 糖：参考各国"低糖"标准（≤5g/100g）
 */
class CategoryThresholds {
    static readonly LIST: FoodCategoryThreshold[] = [
        // ===== 1. 粮谷类制品 =====
        {
            categoryName: '粮谷类制品',
            subCategoryName: '谷物早餐/麦片',
            keywords: ['麦片', '燕麦', '谷物早餐', '即食谷物', 'cereal', 'granola'],
            fatThreshold: 10,
            satFatThreshold: 3,
            sodiumThreshold: 400,
            sugarThreshold: 15
        },
        {
            categoryName: '粮谷类制品',
            subCategoryName: '饼干/糕点',
            keywords: ['饼干', '曲奇', '酥饼', '薄脆', 'cracker', 'cookie', 'biscuit'],
            fatThreshold: 20,
            satFatThreshold: 7,
            sodiumThreshold: 500,
            sugarThreshold: 20
        },
        {
            categoryName: '粮谷类制品',
            subCategoryName: '面包/馒头',
            keywords: ['面包', '吐司', '馒头', '包子', 'bread', 'bun', 'steamed bread'],
            fatThreshold: 8,
            satFatThreshold: 3,
            sodiumThreshold: 500,
            sugarThreshold: 10
        },
        {
            categoryName: '粮谷类制品',
            subCategoryName: '方便面/米粉',
            keywords: ['方便面', '米粉', '米线', '河粉', '速食面', 'instant noodle'],
            fatThreshold: 22,
            satFatThreshold: 8,
            sodiumThreshold: 800,
            sugarThreshold: 5
        },
        // ===== 2. 豆类制品 =====
        {
            categoryName: '豆类制品',
            subCategoryName: '豆腐/豆干',
            keywords: ['豆腐', '豆干', '豆腐干', '千张', '腐竹', 'tofu', 'bean curd'],
            fatThreshold: 10,
            satFatThreshold: 2,
            sodiumThreshold: 600,
            sugarThreshold: 5
        },
        {
            categoryName: '豆类制品',
            subCategoryName: '发酵豆制品',
            keywords: ['腐乳', '豆豉', '纳豆', '味噌', 'fermented bean'],
            fatThreshold: 15,
            satFatThreshold: 3,
            sodiumThreshold: 2000,
            sugarThreshold: 5
        },
        // ===== 3. 乳及乳制品 =====
        {
            categoryName: '乳及乳制品',
            subCategoryName: '液态奶/酸奶',
            keywords: ['牛奶', '纯奶', '鲜奶', '酸奶', '发酵乳', 'milk', 'yogurt', 'yoghurt'],
            fatThreshold: 5,
            satFatThreshold: 3,
            sodiumThreshold: 100,
            sugarThreshold: 12
        },
        {
            categoryName: '乳及乳制品',
            subCategoryName: '奶酪/黄油',
            keywords: ['奶酪', '芝士', '黄油', '奶油', 'cheese', 'butter', 'cream'],
            fatThreshold: 35,
            satFatThreshold: 20,
            sodiumThreshold: 800,
            sugarThreshold: 5
        },
        {
            categoryName: '乳及乳制品',
            subCategoryName: '乳饮料',
            keywords: ['乳饮料', '含乳饮料', '乳酸菌饮料', 'dairy drink'],
            fatThreshold: 3,
            satFatThreshold: 2,
            sodiumThreshold: 100,
            sugarThreshold: 12
        },
        // ===== 4. 坚果和籽类食品 =====
        {
            categoryName: '坚果和籽类食品',
            subCategoryName: '坚果仁',
            keywords: ['坚果', '杏仁', '核桃', '腰果', '开心果', '松子', 'nut', 'almond'],
            fatThreshold: 55,
            satFatThreshold: 8,
            sodiumThreshold: 300,
            sugarThreshold: 10
        },
        {
            categoryName: '坚果和籽类食品',
            subCategoryName: '瓜子/种子',
            keywords: ['瓜子', '花生', '芝麻', '亚麻籽', '奇亚籽', 'seed'],
            fatThreshold: 50,
            satFatThreshold: 8,
            sodiumThreshold: 500,
            sugarThreshold: 10
        },
        // ===== 5. 肉制品 =====
        {
            categoryName: '肉制品',
            subCategoryName: '火腿/香肠',
            keywords: ['火腿', '香肠', '腊肠', '培根', 'ham', 'sausage', 'bacon'],
            fatThreshold: 20,
            satFatThreshold: 7,
            sodiumThreshold: 1200,
            sugarThreshold: 5
        },
        {
            categoryName: '肉制品',
            subCategoryName: '肉干/肉松',
            keywords: ['肉干', '肉松', '牛肉干', '猪肉脯', 'jerky', 'dried meat'],
            fatThreshold: 15,
            satFatThreshold: 5,
            sodiumThreshold: 1500,
            sugarThreshold: 15
        },
        {
            categoryName: '肉制品',
            subCategoryName: '酱卤肉制品',
            keywords: ['酱肉', '卤肉', '酱牛肉', '卤味', '烧鸡', '酱鸭'],
            fatThreshold: 18,
            satFatThreshold: 6,
            sodiumThreshold: 1000,
            sugarThreshold: 8
        },
        // ===== 6. 水产制品 =====
        {
            categoryName: '水产制品',
            subCategoryName: '鱼罐头/鱼松',
            keywords: ['鱼罐头', '鱼松', '金枪鱼', '沙丁鱼', 'fish can', 'tuna'],
            fatThreshold: 15,
            satFatThreshold: 4,
            sodiumThreshold: 800,
            sugarThreshold: 5
        },
        {
            categoryName: '水产制品',
            subCategoryName: '海苔/海藻',
            keywords: ['海苔', '紫菜', '海带', 'seaweed', 'nori', 'kelp'],
            fatThreshold: 15,
            satFatThreshold: 3,
            sodiumThreshold: 1000,
            sugarThreshold: 10
        },
        // ===== 7. 蛋制品 =====
        {
            categoryName: '蛋制品',
            subCategoryName: '蛋类加工品',
            keywords: ['卤蛋', '咸蛋', '皮蛋', '松花蛋', '鸡蛋干', 'egg product'],
            fatThreshold: 15,
            satFatThreshold: 5,
            sodiumThreshold: 1200,
            sugarThreshold: 5
        },
        // ===== 8. 蔬果产品 =====
        {
            categoryName: '蔬果产品',
            subCategoryName: '果蔬干/蜜饯',
            keywords: ['果蔬干', '水果干', '蔬菜干', '蜜饯', '果脯', 'dried fruit', 'dried vegetable'],
            fatThreshold: 5,
            satFatThreshold: 1,
            sodiumThreshold: 500,
            sugarThreshold: 40
        },
        {
            categoryName: '蔬果产品',
            subCategoryName: '果蔬汁/浆',
            keywords: ['果汁', '蔬菜汁', '果蔬汁', '果浆', 'juice', 'puree'],
            fatThreshold: 1,
            satFatThreshold: 0.5,
            sodiumThreshold: 50,
            sugarThreshold: 12
        },
        {
            categoryName: '蔬果产品',
            subCategoryName: '果酱/果泥',
            keywords: ['果酱', '果泥', '果蓉', 'jam', 'marmalade', 'fruit spread'],
            fatThreshold: 1,
            satFatThreshold: 0.5,
            sodiumThreshold: 100,
            sugarThreshold: 45
        },
        // ===== 9. 饮料 =====
        {
            categoryName: '饮料',
            subCategoryName: '碳酸饮料',
            keywords: ['碳酸', '汽水', '可乐', '雪碧', 'soda', 'cola', 'carbonated'],
            fatThreshold: 0.5,
            satFatThreshold: 0.1,
            sodiumThreshold: 50,
            sugarThreshold: 11.25
        },
        {
            categoryName: '饮料',
            subCategoryName: '茶饮料/咖啡',
            keywords: ['茶饮料', '冰茶', '咖啡饮料', '拿铁', 'tea drink', 'coffee drink'],
            fatThreshold: 2,
            satFatThreshold: 1,
            sodiumThreshold: 80,
            sugarThreshold: 8
        },
        {
            categoryName: '饮料',
            subCategoryName: '运动/功能饮料',
            keywords: ['运动饮料', '功能饮料', '能量饮料', '电解质', 'sports drink', 'energy drink'],
            fatThreshold: 0.5,
            satFatThreshold: 0.1,
            sodiumThreshold: 100,
            sugarThreshold: 8
        },
        // ===== 10. 其他食品 =====
        {
            categoryName: '其他食品',
            subCategoryName: '调味品/酱料',
            keywords: ['酱油', '醋', '酱料', '沙拉酱', '番茄酱', '豆瓣酱', 'sauce', 'dressing'],
            fatThreshold: 30,
            satFatThreshold: 5,
            sodiumThreshold: 5000,
            sugarThreshold: 20
        },
        {
            categoryName: '其他食品',
            subCategoryName: '汤料/高汤',
            keywords: ['汤料', '高汤', '浓汤宝', '速溶汤', 'soup', 'broth', 'stock'],
            fatThreshold: 5,
            satFatThreshold: 2,
            sodiumThreshold: 3000,
            sugarThreshold: 5
        },
        {
            categoryName: '其他食品',
            subCategoryName: '冷冻甜品',
            keywords: ['冰淇淋', '雪糕', '冰棍', '冰激凌', 'ice cream', 'gelato', 'sorbet'],
            fatThreshold: 12,
            satFatThreshold: 8,
            sodiumThreshold: 100,
            sugarThreshold: 20
        },
        {
            categoryName: '其他食品',
            subCategoryName: '膨化食品',
            keywords: ['薯片', '薯条', '膨化', '虾条', '爆米花', 'chips', 'puff', 'popcorn'],
            fatThreshold: 30,
            satFatThreshold: 10,
            sodiumThreshold: 700,
            sugarThreshold: 10
        },
        {
            categoryName: '其他食品',
            subCategoryName: '巧克力/糖果',
            keywords: ['巧克力', '糖果', '糖', '巧克力豆', 'chocolate', 'candy', 'sweet'],
            fatThreshold: 35,
            satFatThreshold: 20,
            sodiumThreshold: 200,
            sugarThreshold: 50
        }
    ];
}
/**
 * 不适用"智慧选择"标识的食品类别关键词
 */
class ExcludedCategoryKeywords {
    static readonly LIST: string[] = [
        // 特殊膳食用食品
        '特殊膳食', '婴幼儿配方', '较大婴儿', '幼儿配方',
        '特殊医学用途', '全营养', '特定全营养',
        '婴儿米粉', '辅食营养包',
        // 保健食品
        '保健食品', '蓝帽子', '功能声称',
        // 英文
        'infant formula', 'baby food', 'medical food',
        'health supplement', 'dietary supplement'
    ];
}
// ==================== 引擎实现 ====================
/**
 * 中国营养学会"智慧选择"规范解读引擎
 * 依据T/CNSS 001-2025标准框架
 * 判断预包装食品的脂肪、饱和脂肪、钠、糖是否达标
 */
export class SmartChoiceEngine {
    /**
     * 检查食品是否符合"智慧选择"规范
     * @param food - 食品营养数据
     * @returns SmartChoiceResult 检查结果
     */
    static checkSmartChoice(food: FoodNutrition): SmartChoiceResult {
        const result = new SmartChoiceResult();
        // ===== 步骤1：判断是否适用 =====
        const isApplicable = SmartChoiceEngine.isApplicableForSmartChoice(food);
        result.isApplicable = isApplicable;
        if (!isApplicable) {
            result.notApplicableReason = '该产品属于特殊膳食用食品或保健食品，不适用"智慧选择"标识规范';
            result.eligible = false;
            return result;
        }
        // ===== 步骤2：匹配食品类别 =====
        const categoryInfo = SmartChoiceEngine.matchFoodCategory(food);
        result.foodCategory = categoryInfo;
        if (categoryInfo.categoryName === '未分类') {
            result.eligible = false;
            result.reasons.push('未能匹配到合适的食品类别，无法进行"智慧选择"判定');
            return result;
        }
        // ===== 步骤3：查找对应阈值 =====
        const threshold = SmartChoiceEngine.findThreshold(categoryInfo);
        if (threshold === null) {
            result.eligible = false;
            result.reasons.push(`已匹配到类别"${categoryInfo.categoryName}-${categoryInfo.subCategoryName}"，但未找到对应阈值`);
            return result;
        }
        // ===== 步骤4：逐项检查四项指标 =====
        const checkedNutrients: CheckedNutrient[] = [];
        const reasons: string[] = [];
        let allQualified = true;
        // 4.1 检查脂肪
        const fatCheck = SmartChoiceEngine.checkSingleNutrient('脂肪', food.fat_g, 'g/100g', threshold.fatThreshold);
        checkedNutrients.push(fatCheck);
        if (!fatCheck.isQualified) {
            allQualified = false;
            reasons.push(fatCheck.reason);
        }
        // 4.2 检查饱和脂肪
        const satFatCheck = SmartChoiceEngine.checkSingleNutrient('饱和脂肪', food.saturatedFat_g, 'g/100g', threshold.satFatThreshold);
        checkedNutrients.push(satFatCheck);
        if (!satFatCheck.isQualified) {
            allQualified = false;
            reasons.push(satFatCheck.reason);
        }
        // 4.3 检查钠
        const sodiumCheck = SmartChoiceEngine.checkSingleNutrient('钠', food.sodium_mg, 'mg/100g', threshold.sodiumThreshold);
        checkedNutrients.push(sodiumCheck);
        if (!sodiumCheck.isQualified) {
            allQualified = false;
            reasons.push(sodiumCheck.reason);
        }
        // 4.4 检查糖
        const sugarCheck = SmartChoiceEngine.checkSingleNutrient('糖', food.sugar_g, 'g/100g', threshold.sugarThreshold);
        checkedNutrients.push(sugarCheck);
        if (!sugarCheck.isQualified) {
            allQualified = false;
            reasons.push(sugarCheck.reason);
        }
        result.checkedNutrients = checkedNutrients;
        result.eligible = allQualified;
        // ===== 步骤5：生成总结原因 =====
        if (allQualified) {
            reasons.push(`该${categoryInfo.subCategoryName}的脂肪、饱和脂肪、钠、糖含量均符合"智慧选择"标准`);
        }
        else {
            reasons.unshift(`该${categoryInfo.subCategoryName}未完全达到"智慧选择"标准`);
        }
        result.reasons = reasons;
        return result;
    }
    /**
     * 判断食品是否适用于"智慧选择"规范
     * 特殊膳食用食品和保健食品不适用
     * @param food - 食品营养数据
     * @returns true 表示适用
     */
    private static isApplicableForSmartChoice(food: FoodNutrition): boolean {
        const name = (food.productName ?? '').toLowerCase();
        const brand = (food.brand ?? '').toLowerCase();
        const combined = name + ' ' + brand;
        for (const keyword of ExcludedCategoryKeywords.LIST) {
            if (combined.includes(keyword.toLowerCase())) {
                return false;
            }
        }
        return true;
    }
    /**
     * 匹配食品所属类别
     * @param food - 食品营养数据
     * @returns 匹配到的食品类别信息
     */
    private static matchFoodCategory(food: FoodNutrition): FoodCategoryInfo {
        const info = new FoodCategoryInfo();
        const name = (food.productName ?? '').toLowerCase();
        const brand = (food.brand ?? '').toLowerCase();
        const combined = name + ' ' + brand;
        for (const threshold of CategoryThresholds.LIST) {
            for (const keyword of threshold.keywords) {
                if (combined.includes(keyword.toLowerCase())) {
                    info.categoryName = threshold.categoryName;
                    info.subCategoryName = threshold.subCategoryName;
                    info.matchedKeyword = keyword;
                    return info;
                }
            }
        }
        info.categoryName = '未分类';
        info.subCategoryName = '未分类';
        info.matchedKeyword = '';
        return info;
    }
    /**
     * 根据匹配到的类别信息查找对应的阈值
     * @param categoryInfo - 食品类别信息
     * @returns 对应的阈值，未找到返回null
     */
    private static findThreshold(categoryInfo: FoodCategoryInfo): FoodCategoryThreshold | null {
        for (const threshold of CategoryThresholds.LIST) {
            if (threshold.categoryName === categoryInfo.categoryName &&
                threshold.subCategoryName === categoryInfo.subCategoryName) {
                return threshold;
            }
        }
        return null;
    }
    /**
     * 检查单项营养素是否达标
     * @param name - 营养素名称
     * @param actualValue - 实际含量
     * @param unit - 单位
     * @param threshold - 界限值
     * @returns 检查结果
     */
    private static checkSingleNutrient(name: string, actualValue: number, unit: string, threshold: number): CheckedNutrient {
        const check = new CheckedNutrient();
        check.name = name;
        check.actualValue = actualValue;
        check.unit = unit;
        check.threshold = threshold;
        check.isQualified = actualValue <= threshold;
        if (check.isQualified) {
            check.reason = `${name}含量${actualValue}${unit}，≤${threshold}${unit}，达标`;
        }
        else {
            check.reason = `${name}含量${actualValue}${unit}，>${threshold}${unit}，未达标`;
        }
        return check;
    }
    /**
     * 获取食品所属类别名称
     * @param food - 食品营养数据
     * @returns 类别名称
     */
    static getCategoryName(food: FoodNutrition): string {
        const info = SmartChoiceEngine.matchFoodCategory(food);
        if (info.categoryName === '未分类') {
            return '未分类';
        }
        return `${info.categoryName} > ${info.subCategoryName}`;
    }
    /**
     * 获取食品类别的阈值信息（用于展示）
     * @param food - 食品营养数据
     * @returns 阈值信息字符串数组
     */
    static getThresholdInfo(food: FoodNutrition): string[] {
        const info = SmartChoiceEngine.matchFoodCategory(food);
        const threshold = SmartChoiceEngine.findThreshold(info);
        if (threshold === null) {
            return ['未能匹配到类别阈值'];
        }
        return [
            `类别：${threshold.categoryName} > ${threshold.subCategoryName}`,
            `脂肪 ≤ ${threshold.fatThreshold}g/100g`,
            `饱和脂肪 ≤ ${threshold.satFatThreshold}g/100g`,
            `钠 ≤ ${threshold.sodiumThreshold}mg/100g`,
            `糖 ≤ ${threshold.sugarThreshold}g/100g`
        ];
    }
}
