// AlternativeFoodRecommender.ets
// 替代食品推荐引擎 - 根据食品营养数据和家庭成员健康画像，推荐更健康的替代品
// 基于中国居民膳食指南和常见食品替换策略
//
// 功能：
// 1. 基于当前食品的营养缺陷推荐同类替代品
// 2. 针对家庭成员健康目标给出替换建议
// 3. 支持按品类查找已知的健康替代方案
// 4. 提供食材替换的生活化建议文案

import { FamilyProfile, HealthGoal } from '../model/FamilyProfile';
import { FoodLabel, NutritionPer100g } from '../model/FoodLabel';
import { AlternativeFood, RecommendationLevel } from '../model/FoodAdapterTypes';

/**
 * 替代食品数据库条目
 */
interface AlternativeEntry {
  originalCategory: string;       // 原始品类（如"薯片"）
  alternativeName: string;        // 替代品名称
  brand: string;                  // 推荐品牌/来源
  healthScore: number;            // 健康评分 0-100
  sodium_mg: number;              // 每100g钠含量
  sugar_g: number;                // 每100g糖含量
  energyKcal: number;             // 每100g热量
  fat_g: number;                  // 每100g脂肪
  reason: string;                 // 推荐理由
  improvement: string;            // 改善说明
  suitableGoals: string[];        // 适合的健康目标
}

/**
 * 替代食品数据库（内置常见食品替换方案）
 */
const ALTERNATIVE_FOODS: AlternativeEntry[] = [
  // ===== 零食类替代 =====
  {
    originalCategory: '薯片',
    alternativeName: '原味海苔',
    brand: '波力/四洲',
    healthScore: 75,
    sodium_mg: 180,
    sugar_g: 1,
    energyKcal: 120,
    fat_g: 4,
    reason: '热量和脂肪大幅降低，富含膳食纤维和矿物质',
    improvement: '热量降低约70%，脂肪降低约80%',
    suitableGoals: [HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]
  },
  {
    originalCategory: '薯片',
    alternativeName: '原味坚果（无盐）',
    brand: '沃隆/三只松鼠',
    healthScore: 80,
    sodium_mg: 5,
    sugar_g: 2,
    energyKcal: 180,
    fat_g: 15,
    reason: '优质不饱和脂肪酸，饱腹感强，无添加盐',
    improvement: '钠含量降低99%，提供优质脂肪酸和维生素E',
    suitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT]
  },
  {
    originalCategory: '薯片',
    alternativeName: '冻干蔬菜干',
    brand: '来伊份/良品铺子',
    healthScore: 70,
    sodium_mg: 50,
    sugar_g: 5,
    energyKcal: 80,
    fat_g: 1,
    reason: '非油炸工艺，保留膳食纤维和维生素',
    improvement: '热量降低约80%，脂肪降低约95%',
    suitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },

  // ===== 饮料类替代 =====
  {
    originalCategory: '可乐',
    alternativeName: '无糖苏打水+柠檬片',
    brand: '怡泉/屈臣氏',
    healthScore: 85,
    sodium_mg: 10,
    sugar_g: 0,
    energyKcal: 0,
    fat_g: 0,
    reason: '零糖零热量，自加柠檬补充维生素C',
    improvement: '糖降低100%，热量降低100%',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP, HealthGoal.CHILD]
  },
  {
    originalCategory: '可乐',
    alternativeName: '零度可乐/零卡可乐',
    brand: '可口可乐/百事',
    healthScore: 50,
    sodium_mg: 20,
    sugar_g: 0,
    energyKcal: 0,
    fat_g: 0,
    reason: '零糖零热量，但含人工甜味剂',
    improvement: '糖和热量降低100%',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT]
  },
  {
    originalCategory: '可乐',
    alternativeName: '无糖茶饮（乌龙茶/绿茶）',
    brand: '三得利/东方树叶',
    healthScore: 80,
    sodium_mg: 5,
    sugar_g: 0,
    energyKcal: 0,
    fat_g: 0,
    reason: '零糖零热量，含茶多酚抗氧化',
    improvement: '糖降低100%，热量降低100%，含抗氧化成分',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP, HealthGoal.CHILD]
  },

  // ===== 甜品类替代 =====
  {
    originalCategory: '蛋糕',
    alternativeName: '全麦无糖欧包',
    brand: '曼可顿/桃李',
    healthScore: 65,
    sodium_mg: 150,
    sugar_g: 3,
    energyKcal: 150,
    fat_g: 3,
    reason: '全麦粉制作，低糖低脂，富含膳食纤维',
    improvement: '糖降低80%，脂肪降低70%',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT]
  },
  {
    originalCategory: '蛋糕',
    alternativeName: '希腊酸奶+新鲜水果',
    brand: '简爱/乐纯',
    healthScore: 85,
    sodium_mg: 40,
    sugar_g: 5,
    energyKcal: 60,
    fat_g: 0.5,
    reason: '高蛋白低糖，水果提供天然甜味和维生素',
    improvement: '热量降低70%，蛋白质更高，富含益生菌',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  {
    originalCategory: '蛋糕',
    alternativeName: '蒸红薯/紫薯',
    brand: '新鲜食材',
    healthScore: 80,
    sodium_mg: 10,
    sugar_g: 8,
    energyKcal: 90,
    fat_g: 0.2,
    reason: '天然甜味，高膳食纤维，富含花青素（紫薯）',
    improvement: '热量降低60%，富含膳食纤维和多种维生素',
    suitableGoals: [HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]
  },

  // ===== 饮品（奶茶）替代 =====
  {
    originalCategory: '奶茶',
    alternativeName: '纯牛奶+无糖抹茶粉',
    brand: '伊利/蒙牛',
    healthScore: 75,
    sodium_mg: 60,
    sugar_g: 5,
    energyKcal: 55,
    fat_g: 3,
    reason: '纯牛奶提供优质蛋白和钙，无糖抹茶含抗氧化剂',
    improvement: '糖降低90%，热量降低70%',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  {
    originalCategory: '奶茶',
    alternativeName: '黑咖啡/美式咖啡',
    brand: '星巴克/瑞幸',
    healthScore: 80,
    sodium_mg: 5,
    sugar_g: 0,
    energyKcal: 5,
    fat_g: 0,
    reason: '零糖零热量，提高代谢和专注力',
    improvement: '糖降低100%，热量降低95%以上',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT]
  },
  {
    originalCategory: '奶茶',
    alternativeName: '菊花枸杞茶',
    brand: '立顿/Chali',
    healthScore: 85,
    sodium_mg: 2,
    sugar_g: 0,
    energyKcal: 0,
    fat_g: 0,
    reason: '零糖零热量，明目养肝，适合长期饮用',
    improvement: '糖降低100%，热量降低100%',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP, HealthGoal.CHILD]
  },

  // ===== 肉类替代 =====
  {
    originalCategory: '培根',
    alternativeName: '纯瘦鸡胸肉',
    brand: '泰森/正大',
    healthScore: 85,
    sodium_mg: 50,
    sugar_g: 0,
    energyKcal: 110,
    fat_g: 2,
    reason: '高蛋白低脂低钠，不含亚硝酸盐',
    improvement: '钠降低85%，脂肪降低80%，不含加工肉制品有害物',
    suitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]
  },
  {
    originalCategory: '培根',
    alternativeName: '盐水牛肉片',
    brand: '科尔沁/张飞',
    healthScore: 65,
    sodium_mg: 300,
    sugar_g: 0,
    energyKcal: 130,
    fat_g: 4,
    reason: '比培根少加工，脂肪含量较低',
    improvement: '脂肪降低60%，无烟熏工艺',
    suitableGoals: [HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT]
  },
  {
    originalCategory: '午餐肉',
    alternativeName: '鲜牛肉饼（自煎）',
    brand: '新鲜食材',
    healthScore: 80,
    sodium_mg: 70,
    sugar_g: 0,
    energyKcal: 150,
    fat_g: 8,
    reason: '新鲜肉类，无添加剂和防腐剂，高蛋白',
    improvement: '钠降低80%，不含亚硝酸盐和过量添加剂',
    suitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },

  // ===== 主食替代 =====
  {
    originalCategory: '白米饭（精制）',
    alternativeName: '糙米饭/杂粮饭',
    brand: '金龙鱼/十月稻田',
    healthScore: 70,
    sodium_mg: 3,
    sugar_g: 0.5,
    energyKcal: 120,
    fat_g: 1,
    reason: '保留麸皮和胚芽，富含B族维生素和膳食纤维',
    improvement: '膳食纤维提高4倍，升糖指数降低30%',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP]
  },
  {
    originalCategory: '白米饭（精制）',
    alternativeName: '燕麦藜麦饭',
    brand: '桂格/三江',
    healthScore: 75,
    sodium_mg: 5,
    sugar_g: 0.3,
    energyKcal: 115,
    fat_g: 2,
    reason: '低升糖指数，高蛋白高膳食纤维，藜麦含全蛋白',
    improvement: '升糖指数降低40%，蛋白质提高50%',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  {
    originalCategory: '方便面',
    alternativeName: '荞麦面+水煮蛋+蔬菜',
    brand: '金龙鱼/想念',
    healthScore: 70,
    sodium_mg: 100,
    sugar_g: 1,
    energyKcal: 130,
    fat_g: 2,
    reason: '荞麦低脂低升糖，搭配蛋白质和蔬菜更均衡',
    improvement: '钠降低85%，脂肪降低80%，增加蛋白质和膳食纤维',
    suitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_SUGAR, HealthGoal.CHILD]
  },
  {
    originalCategory: '方便面',
    alternativeName: '魔芋丝+自调配料',
    brand: '卫龙/保持',
    healthScore: 75,
    sodium_mg: 50,
    sugar_g: 0,
    energyKcal: 15,
    fat_g: 0.2,
    reason: '几乎零热量，高膳食纤维，可搭配任意清淡酱料',
    improvement: '热量降低95%以上，钠降低90%',
    suitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]
  },

  // ===== 酱料替代 =====
  {
    originalCategory: '沙拉酱',
    alternativeName: '油醋汁（橄榄油+醋）',
    brand: '丘比/自制',
    healthScore: 70,
    sodium_mg: 200,
    sugar_g: 2,
    energyKcal: 80,
    fat_g: 8,
    reason: '橄榄油含单不饱和脂肪酸，醋助控血糖',
    improvement: '热量降低60%，糖降低90%，富含优质脂肪酸',
    suitableGoals: [HealthGoal.LOSE_FAT, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT]
  },
  {
    originalCategory: '沙拉酱',
    alternativeName: '无糖希腊酸奶+香草',
    brand: '简爱/乐纯',
    healthScore: 80,
    sodium_mg: 40,
    sugar_g: 3,
    energyKcal: 55,
    fat_g: 0.5,
    reason: '高蛋白低脂，天然乳酸风味',
    improvement: '热量降低70%，脂肪降低90%，蛋白质提高',
    suitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]
  },
  {
    originalCategory: '番茄酱',
    alternativeName: '自制番茄泥（无添加糖盐）',
    brand: '自制/亨氏低糖版',
    healthScore: 70,
    sodium_mg: 30,
    sugar_g: 4,
    energyKcal: 25,
    fat_g: 0.2,
    reason: '非浓缩还原，无添加糖和过量盐',
    improvement: '钠降低85%，糖降低70%',
    suitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CHILD]
  }
];

/**
 * 品类关键词匹配
 */
const CATEGORY_KEYWORDS: Record<string, string[]> = {
  '薯片': ['薯片', '薯条', '膨化', '虾条', '脆片', '米饼'],
  '可乐': ['可乐', '碳酸', '汽水', '雪碧', '芬达', '气泡'],
  '蛋糕': ['蛋糕', '面包', '吐司', '饼干', '曲奇', '蛋卷', '蛋黄派', '沙琪玛', '酥'],
  '奶茶': ['奶茶', '奶盖', '波波', '果茶', '冰红茶', '茉莉花'],
  '培根': ['培根', '火腿', '香肠', '腊肉', '腊肠', '熏肉'],
  '午餐肉': ['午餐肉', '火腿肠', '火腿罐头'],
  '白米饭（精制）': ['大米', '白米饭', '米', '炒饭'],
  '方便面': ['方便面', '泡面', '拉面', '拌面', '乌冬面', '意面', '意粉'],
  '沙拉酱': ['沙拉酱', '蛋黄酱', '千岛酱', '奶油酱'],
  '番茄酱': ['番茄酱', '番茄沙司', '辣椒酱', '甜辣酱', '豆瓣酱']
};

/**
 * 替代食品推荐引擎
 */
export class AlternativeFoodRecommender {
  /**
   * 根据食品标签信息和家庭成员健康画像，推荐替代食品
   * @param foodLabel 当前食品标签
   * @param members 家庭成员画像列表
   * @param topN 推荐数量（默认3）
   * @returns 替代食品推荐列表
   */
  static recommendAlternatives(
    foodLabel: FoodLabel,
    members: FamilyProfile[],
    topN: number = 3
  ): AlternativeFood[] {
    // 1. 识别食品所属品类
    const categories = AlternativeFoodRecommender.identifyCategory(foodLabel);

    if (categories.length === 0) {
      // 无法识别品类时，根据营养数据推荐通用替代方向
      return AlternativeFoodRecommender.getNutritionBasedAlternatives(foodLabel, members, topN);
    }

    // 2. 查找对应品类的替代品
    const allCandidates: AlternativeFood[] = [];
    for (const category of categories) {
      const alternatives = ALTERNATIVE_FOODS.filter(a => a.originalCategory === category);
      for (const alt of alternatives) {
        const food: AlternativeFood = {
          productName: alt.alternativeName,
          brand: alt.brand,
          healthScore: alt.healthScore,
          level: AlternativeFoodRecommender.scoreToLevel(alt.healthScore),
          sodium_mg: alt.sodium_mg,
          sugar_g: alt.sugar_g,
          energyKcal: alt.energyKcal,
          reason: alt.reason
        };
        allCandidates.push(food);
      }
    }

    // 3. 根据成员健康目标排序
    const scored = AlternativeFoodRecommender.scoreAlternativesForMembers(allCandidates, members);
    const sorted = scored.sort((a, b) => b.healthScore - a.healthScore);

    // 4. 去重后返回Top N
    const seen = new Set<string>();
    const deduplicated: AlternativeFood[] = [];
    for (const alt of sorted) {
      const key = alt.productName + alt.brand;
      if (!seen.has(key)) {
        seen.add(key);
        deduplicated.push(alt);
        if (deduplicated.length >= topN) break;
      }
    }

    return deduplicated;
  }

  /**
   * 基于营养数据的通用替代方向推荐
   * 适用于无法识别具体品类时
   */
  private static getNutritionBasedAlternatives(
    foodLabel: FoodLabel,
    members: FamilyProfile[],
    topN: number
  ): AlternativeFood[] {
    const nutrition = foodLabel.nutrition;
    const suggestions: AlternativeFood[] = [];

    // 高钠食品 -> 推荐低钠替代
    if (nutrition.sodium > 400) {
      suggestions.push({
        productName: '低钠版同类食品',
        brand: '建议选择',
        healthScore: 65,
        level: RecommendationLevel.YELLOW,
        sodium_mg: 120,
        sugar_g: nutrition.sugar,
        energyKcal: nutrition.calories,
        reason: '钠含量降低70%以上，更有助于控制血压和水分平衡'
      });
    }

    // 高糖食品 -> 推荐低糖替代
    if (nutrition.sugar > 12) {
      suggestions.push({
        productName: '无糖/低糖版',
        brand: '建议选择',
        healthScore: 60,
        level: RecommendationLevel.YELLOW,
        sodium_mg: nutrition.sodium,
        sugar_g: 3,
        energyKcal: Math.round(nutrition.calories * 0.7),
        reason: '糖含量降低75%以上，热量显著降低'
      });
    }

    // 高热量食品 -> 推荐低热量替代
    if (nutrition.calories > 250) {
      suggestions.push({
        productName: '清淡低卡替代品',
        brand: '新鲜食材优先',
        healthScore: 70,
        level: RecommendationLevel.YELLOW,
        sodium_mg: nutrition.sodium,
        sugar_g: nutrition.sugar,
        energyKcal: Math.round(nutrition.calories * 0.5),
        reason: '热量降低50%，更利于体重管理和代谢健康'
      });
    }

    // 高频推荐：天然食材
    suggestions.push({
      productName: '新鲜水果/蔬菜',
      brand: '当季新鲜食材',
      healthScore: 90,
      level: RecommendationLevel.GREEN,
      sodium_mg: 5,
      sugar_g: 8,
      energyKcal: 50,
      reason: '天然维生素和膳食纤维来源，热量低，无添加剂'
    });

    // 根据成员目标过滤排序
    const scored = AlternativeFoodRecommender.scoreAlternativesForMembers(suggestions, members);
    return scored.slice(0, topN);
  }

  /**
   * 根据家庭成员健康目标对替代品评分
   */
  private static scoreAlternativesForMembers(
    candidates: AlternativeFood[],
    members: FamilyProfile[]
  ): AlternativeFood[] {
    if (members.length === 0) return candidates;

    return candidates.map(alt => {
      let scoreAdjustment = 0;

      for (const member of members) {
        for (const goal of member.healthGoals) {
          switch (goal) {
            case HealthGoal.CONTROL_BP:
              if (alt.sodium_mg <= 120) scoreAdjustment += 5;
              else if (alt.sodium_mg > 400) scoreAdjustment -= 5;
              break;
            case HealthGoal.CONTROL_SUGAR:
              if (alt.sugar_g <= 5) scoreAdjustment += 5;
              else if (alt.sugar_g > 15) scoreAdjustment -= 5;
              break;
            case HealthGoal.LOSE_FAT:
              if (alt.energyKcal <= 80) scoreAdjustment += 5;
              else if (alt.energyKcal > 250) scoreAdjustment -= 5;
              break;
            case HealthGoal.CONTROL_FAT:
              if (alt.sodium_mg <= 200) scoreAdjustment += 3;
              break;
            case HealthGoal.CHILD:
              if (alt.sugar_g <= 5 && alt.sodium_mg <= 200) scoreAdjustment += 5;
              break;
            default:
              // NONE模式不调整
              break;
          }
        }
      }

      // 限制调整范围
      const adjustedScore = Math.max(10, Math.min(100, alt.healthScore + scoreAdjustment));
      return {
        productName: alt.productName,
        brand: alt.brand,
        healthScore: adjustedScore,
        level: AlternativeFoodRecommender.scoreToLevel(adjustedScore),
        sodium_mg: alt.sodium_mg,
        sugar_g: alt.sugar_g,
        energyKcal: alt.energyKcal,
        reason: alt.reason
      };
    });
  }

  /**
   * 识别食品所属品类
   */
  private static identifyCategory(foodLabel: FoodLabel): string[] {
    const categories: string[] = [];
    const foodName = foodLabel.foodName.toLowerCase();
    const ingredients = foodLabel.ingredients.join(',').toLowerCase();

    for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
      for (const keyword of keywords) {
        if (foodName.includes(keyword) || ingredients.includes(keyword)) {
          categories.push(category);
          break;
        }
      }
    }

    return categories;
  }

  /**
   * 根据食品营养数据查找替代方案
   * @param nutrition 食品营养数据
   * @param members 家庭成员画像
   * @returns 推荐替代食品列表
   */
  static recommendByNutrition(
    nutrition: NutritionPer100g,
    members: FamilyProfile[]
  ): AlternativeFood[] {
    const foodLabel = new FoodLabel();
    foodLabel.foodName = '扫描食品';
    foodLabel.nutrition = nutrition;
    foodLabel.ingredients = [];

    return AlternativeFoodRecommender.recommendAlternatives(foodLabel, members, 3);
  }

  /**
   * 获取特定品类的所有替代方案
   */
  static getAlternativesForCategory(category: string): AlternativeFood[] {
    return ALTERNATIVE_FOODS
      .filter(a => a.originalCategory === category)
      .map(a => ({
        productName: a.alternativeName,
        brand: a.brand,
        healthScore: a.healthScore,
        level: AlternativeFoodRecommender.scoreToLevel(a.healthScore),
        sodium_mg: a.sodium_mg,
        sugar_g: a.sugar_g,
        energyKcal: a.energyKcal,
        reason: a.reason
      }));
  }

  /**
   * 获取所有支持的品类
   */
  static getSupportedCategories(): string[] {
    return [...new Set(ALTERNATIVE_FOODS.map(a => a.originalCategory))];
  }

  /**
   * 生成生活化推荐文案
   */
  static generateAdviceText(originalFood: string, alternative: AlternativeFood): string {
    const lines: string[] = [];
    lines.push(`🔍 替代建议：${originalFood} → ${alternative.productName}`);
    lines.push('');
    lines.push(`推荐理由：${alternative.reason}`);
    lines.push('');
    lines.push(`📊 营养改善：`);
    lines.push(`  钠：↘️ 每100g含${alternative.sodium_mg}mg`);
    lines.push(`  糖：↘️ 每100g含${alternative.sugar_g}g`);
    lines.push(`  热量：↘️ 每100g含${alternative.energyKcal}kcal`);
    lines.push('');
    lines.push(`品牌推荐：${alternative.brand}`);
    lines.push('');
    lines.push('更换后不仅更健康，口感也能满足您的需求～');

    return lines.join('\n');
  }

  /**
   * 健康分数转推荐等级
   */
  private static scoreToLevel(score: number): RecommendationLevel {
    if (score >= 70) return RecommendationLevel.GREEN;
    if (score >= 50) return RecommendationLevel.YELLOW;
    if (score >= 30) return RecommendationLevel.ORANGE;
    return RecommendationLevel.RED;
  }
}
