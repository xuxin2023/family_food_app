import {
  FamilyProfile, HealthGoal, FoodLabel, NutritionPer100g, AlternativeFood, RecommendationLevel,
  NUTRIENT_LIMITS_V2, IAlternativeRecommender, DislikedAdditive
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'AltFoodRecommender';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

class AlternativeEntry {
  originalCategory: string = '';
  alternativeName: string = '';
  brand: string = '';
  healthScore: number = 0;
  sodium_mg: number = 0;
  sugar_g: number = 0;
  energyKcal: number = 0;
  fat_g: number = 0;
  reason: string = '';
  improvement: string = '';
  suitableGoals: string[] = [];

  constructor(originalCategory: string, alternativeName: string, brand: string,
    healthScore: number, sodium_mg: number, sugar_g: number, energyKcal: number,
    fat_g: number, reason: string, improvement: string, suitableGoals: string[]) {
    this.originalCategory = originalCategory;
    this.alternativeName = alternativeName;
    this.brand = brand;
    this.healthScore = healthScore;
    this.sodium_mg = sodium_mg;
    this.sugar_g = sugar_g;
    this.energyKcal = energyKcal;
    this.fat_g = fat_g;
    this.reason = reason;
    this.improvement = improvement;
    this.suitableGoals = suitableGoals;
  }
}

class CategoryKeywordEntry {
  category: string = '';
  keywords: string[] = [];

  constructor(category: string, keywords: string[]) {
    this.category = category;
    this.keywords = keywords;
  }
}

class NutritionVector {
  energy: number = 0;
  fat: number = 0;
  sugar: number = 0;
  sodium: number = 0;
  protein: number = 0;
  fiber: number = 0;
  carbohydrate: number = 0;

  constructor(n: NutritionPer100g) {
    this.energy = n.calories;
    this.fat = n.fat;
    this.sugar = n.sugar;
    this.sodium = n.sodium;
    this.protein = n.protein;
    this.fiber = n.fiber;
    this.carbohydrate = n.carbohydrate;
  }

  magnitude(): number {
    return Math.sqrt(
      this.energy * this.energy + this.fat * this.fat + this.sugar * this.sugar +
      this.sodium * this.sodium + this.protein * this.protein + this.fiber * this.fiber +
      this.carbohydrate * this.carbohydrate
    );
  }

  dot(other: NutritionVector): number {
    return this.energy * other.energy + this.fat * other.fat + this.sugar * other.sugar +
      this.sodium * other.sodium + this.protein * other.protein + this.fiber * other.fiber +
      this.carbohydrate * other.carbohydrate;
  }

  cosineSimilarity(other: NutritionVector): number {
    const m1 = this.magnitude();
    const m2 = other.magnitude();
    if (m1 < 0.001 || m2 < 0.001) return 0;
    return this.dot(other) / (m1 * m2);
  }
}

class OfflineFoodCandidate {
  foodName: string = '';
  brand: string = '';
  nutrition: NutritionPer100g = new NutritionPer100g();
  ingredients: string[] = [];
  allergenHints: string[] = [];
  nutriScore: number = 0;
  novaGroup: number = 0;
  category: string = '';

  constructor(foodName: string, brand: string, nutrition: NutritionPer100g,
    ingredients: string[], allergenHints: string[], nutriScore: number,
    novaGroup: number, category: string) {
    this.foodName = foodName;
    this.brand = brand;
    this.nutrition = nutrition;
    this.ingredients = ingredients;
    this.allergenHints = allergenHints;
    this.nutriScore = nutriScore;
    this.novaGroup = novaGroup;
    this.category = category;
  }
}

export class AlternativeFoodRecommender implements IAlternativeRecommender {
  private readonly ALTERNATIVE_FOODS: AlternativeEntry[] = AlternativeFoodRecommender.buildAlternativeFoods();
  private readonly CATEGORY_KEYWORDS: CategoryKeywordEntry[] = AlternativeFoodRecommender.buildCategoryKeywords();
  private offlineFoodDB: OfflineFoodCandidate[] = [];

  private static buildAlternativeFoods(): AlternativeEntry[] {
    const list: AlternativeEntry[] = [];

    list.push(new AlternativeEntry('薯片', '原味海苔', '波力/四洲', 75, 180, 1, 120, 4,
      '热量和脂肪大幅降低，富含膳食纤维和矿物质',
      '热量降低约70%，脂肪降低约80%',
      [HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]));
    list.push(new AlternativeEntry('薯片', '原味坚果（无盐）', '沃隆/三只松鼠', 80, 5, 2, 180, 15,
      '优质不饱和脂肪酸，饱腹感强，无添加盐',
      '钠含量降低99%，提供优质脂肪酸和维生素E',
      [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT]));
    list.push(new AlternativeEntry('薯片', '冻干蔬菜干', '来伊份/良品铺子', 70, 50, 5, 80, 1,
      '非油炸工艺，保留膳食纤维和维生素',
      '热量降低约80%，脂肪降低约95%',
      [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));

    list.push(new AlternativeEntry('可乐', '无糖苏打水+柠檬片', '怡泉/屈臣氏', 85, 10, 0, 0, 0,
      '零糖零热量，自加柠檬补充维生素C',
      '糖降低100%，热量降低100%',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP, HealthGoal.CHILD]));
    list.push(new AlternativeEntry('可乐', '零度可乐/零卡可乐', '可口可乐/百事', 50, 20, 0, 0, 0,
      '零糖零热量，但含人工甜味剂',
      '糖和热量降低100%',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT]));
    list.push(new AlternativeEntry('可乐', '无糖茶饮（乌龙茶/绿茶）', '三得利/东方树叶', 80, 5, 0, 0, 0,
      '零糖零热量，含茶多酚抗氧化',
      '糖降低100%，热量降低100%，含抗氧化成分',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP, HealthGoal.CHILD]));

    list.push(new AlternativeEntry('蛋糕', '全麦无糖欧包', '曼可顿/桃李', 65, 150, 3, 150, 3,
      '全麦粉制作，低糖低脂，富含膳食纤维',
      '糖降低80%，脂肪降低70%',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT]));
    list.push(new AlternativeEntry('蛋糕', '希腊酸奶+新鲜水果', '简爱/乐纯', 85, 40, 5, 60, 0.5,
      '高蛋白低糖，水果提供天然甜味和维生素',
      '热量降低70%，蛋白质更高，富含益生菌',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    list.push(new AlternativeEntry('蛋糕', '蒸红薯/紫薯', '新鲜食材', 80, 10, 8, 90, 0.2,
      '天然甜味，高膳食纤维，富含花青素（紫薯）',
      '热量降低60%，富含膳食纤维和多种维生素',
      [HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]));

    list.push(new AlternativeEntry('奶茶', '纯牛奶+无糖抹茶粉', '伊利/蒙牛', 75, 60, 5, 55, 3,
      '纯牛奶提供优质蛋白和钙，无糖抹茶含抗氧化剂',
      '糖降低90%，热量降低70%',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    list.push(new AlternativeEntry('奶茶', '黑咖啡/美式咖啡', '星巴克/瑞幸', 80, 5, 0, 5, 0,
      '零糖零热量，提高代谢和专注力',
      '糖降低100%，热量降低95%以上',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT]));
    list.push(new AlternativeEntry('奶茶', '菊花枸杞茶', '立顿/Chali', 85, 2, 0, 0, 0,
      '零糖零热量，明目养肝，适合长期饮用',
      '糖降低100%，热量降低100%',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP, HealthGoal.CHILD]));

    list.push(new AlternativeEntry('培根', '纯瘦鸡胸肉', '泰森/正大', 85, 50, 0, 110, 2,
      '高蛋白低脂低钠，不含亚硝酸盐',
      '钠降低85%，脂肪降低80%，不含加工肉制品有害物',
      [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]));
    list.push(new AlternativeEntry('培根', '盐水牛肉片', '科尔沁/张飞', 65, 300, 0, 130, 4,
      '比培根少加工，脂肪含量较低',
      '脂肪降低60%，无烟熏工艺',
      [HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT]));
    list.push(new AlternativeEntry('午餐肉', '鲜牛肉饼（自煎）', '新鲜食材', 80, 70, 0, 150, 8,
      '新鲜肉类，无添加剂和防腐剂，高蛋白',
      '钠降低80%，不含亚硝酸盐和过量添加剂',
      [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));

    list.push(new AlternativeEntry('白米饭（精制）', '糙米饭/杂粮饭', '金龙鱼/十月稻田', 70, 3, 0.5, 120, 1,
      '保留麸皮和胚芽，富含B族维生素和膳食纤维',
      '膳食纤维提高4倍，升糖指数降低30%',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP]));
    list.push(new AlternativeEntry('白米饭（精制）', '燕麦藜麦饭', '桂格/三江', 75, 5, 0.3, 115, 2,
      '低升糖指数，高蛋白高膳食纤维，藜麦含全蛋白',
      '升糖指数降低40%，蛋白质提高50%',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    list.push(new AlternativeEntry('方便面', '荞麦面+水煮蛋+蔬菜', '金龙鱼/想念', 70, 100, 1, 130, 2,
      '荞麦低脂低升糖，搭配蛋白质和蔬菜更均衡',
      '钠降低85%，脂肪降低80%，增加蛋白质和膳食纤维',
      [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_SUGAR, HealthGoal.CHILD]));
    list.push(new AlternativeEntry('方便面', '魔芋丝+自调配料', '卫龙/保持', 75, 50, 0, 15, 0.2,
      '几乎零热量，高膳食纤维，可搭配任意清淡酱料',
      '热量降低95%以上，钠降低90%',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]));

    list.push(new AlternativeEntry('沙拉酱', '油醋汁（橄榄油+醋）', '丘比/自制', 70, 200, 2, 80, 8,
      '橄榄油含单不饱和脂肪酸，醋助控血糖',
      '热量降低60%，糖降低90%，富含优质脂肪酸',
      [HealthGoal.LOSE_FAT, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT]));
    list.push(new AlternativeEntry('沙拉酱', '无糖希腊酸奶+香草', '简爱/乐纯', 80, 40, 3, 55, 0.5,
      '高蛋白低脂，天然乳酸风味',
      '热量降低70%，脂肪降低90%，蛋白质提高',
      [HealthGoal.CONTROL_BP, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_FAT, HealthGoal.CHILD]));
    list.push(new AlternativeEntry('番茄酱', '自制番茄泥（无添加糖盐）', '自制/亨氏低糖版', 70, 30, 4, 25, 0.2,
      '非浓缩还原，无添加糖和过量盐',
      '钠降低85%，糖降低70%',
      [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CHILD]));

    return list;
  }

  private static buildCategoryKeywords(): CategoryKeywordEntry[] {
    const list: CategoryKeywordEntry[] = [];
    list.push(new CategoryKeywordEntry('薯片', ['薯片', '薯条', '膨化', '虾条', '脆片', '米饼']));
    list.push(new CategoryKeywordEntry('可乐', ['可乐', '碳酸', '汽水', '雪碧', '芬达', '气泡']));
    list.push(new CategoryKeywordEntry('蛋糕', ['蛋糕', '面包', '吐司', '饼干', '曲奇', '蛋卷', '蛋黄派', '沙琪玛', '酥']));
    list.push(new CategoryKeywordEntry('奶茶', ['奶茶', '奶盖', '波波', '果茶', '冰红茶', '茉莉花']));
    list.push(new CategoryKeywordEntry('培根', ['培根', '火腿', '香肠', '腊肉', '腊肠', '熏肉']));
    list.push(new CategoryKeywordEntry('午餐肉', ['午餐肉', '火腿肠', '火腿罐头']));
    list.push(new CategoryKeywordEntry('白米饭（精制）', ['大米', '白米饭', '米', '炒饭']));
    list.push(new CategoryKeywordEntry('方便面', ['方便面', '泡面', '拉面', '拌面', '乌冬面', '意面', '意粉']));
    list.push(new CategoryKeywordEntry('沙拉酱', ['沙拉酱', '蛋黄酱', '千岛酱', '奶油酱']));
    list.push(new CategoryKeywordEntry('番茄酱', ['番茄酱', '番茄沙司', '辣椒酱', '甜辣酱', '豆瓣酱']));
    return list;
  }

  setOfflineFoodDB(candidates: OfflineFoodCandidate[]): void {
    this.offlineFoodDB = candidates;
    hilog.info(DOMAIN_ZERO, TAG, 'Offline food DB set: %{public}d items', candidates.length);
  }

  async recommendAlternatives(
    foodLabel: FoodLabel,
    members: FamilyProfile[],
    topN: number = 3
  ): Promise<AlternativeFood[]> {
    const categories = this.identifyCategory(foodLabel);
    const memberAllergens = this.collectMemberAllergens(members);

    const ruleResults = this.recommendByCategoryRules(categories, members, memberAllergens, topN);
    if (ruleResults.length >= topN) {
      return ruleResults.slice(0, topN);
    }

    const offlineResults = await this.recommendByOfflineDB(
      foodLabel, categories, members, memberAllergens, topN - ruleResults.length
    );

    const combined = [...ruleResults, ...offlineResults];
    if (combined.length >= topN) {
      const seen: Set<string> = new Set();
      const deduped: AlternativeFood[] = [];
      for (const item of combined) {
        const key = item.productName + item.brand;
        if (!seen.has(key)) {
          seen.add(key);
          deduped.push(item);
          if (deduped.length >= topN) break;
        }
      }
      return deduped;
    }

    const nutritionResults = this.getNutritionBasedAlternatives(foodLabel, members, topN - combined.length);
    const allResults = [...combined, ...nutritionResults];
    const seen2: Set<string> = new Set();
    const finalResults: AlternativeFood[] = [];
    for (const item of allResults) {
      const key = item.productName + item.brand;
      if (!seen2.has(key)) {
        seen2.add(key);
        finalResults.push(item);
        if (finalResults.length >= topN) break;
      }
    }

    return finalResults;
  }

  private recommendByCategoryRules(
    categories: string[],
    members: FamilyProfile[],
    memberAllergens: Set<string>,
    topN: number
  ): AlternativeFood[] {
    if (categories.length === 0) return [];

    const allCandidates: AlternativeFood[] = [];
    for (const category of categories) {
      for (const alt of this.ALTERNATIVE_FOODS) {
        if (alt.originalCategory !== category) continue;

        const altAllergenConflict = this.hasAllergenConflict(alt.alternativeName, memberAllergens);
        if (altAllergenConflict) {
          hilog.info(DOMAIN_ZERO, TAG, 'Skipped allergen-conflicting: %{public}s', alt.alternativeName);
          continue;
        }

        allCandidates.push(new AlternativeFood(
          alt.alternativeName, alt.brand, alt.healthScore,
          AlternativeFoodRecommender.scoreToLevel(alt.healthScore),
          alt.sodium_mg, alt.sugar_g, alt.energyKcal, alt.reason
        ));
      }
    }

    return this.scoreAlternativesForMembers(allCandidates, members)
      .sort((a: AlternativeFood, b: AlternativeFood) => b.healthScore - a.healthScore)
      .slice(0, topN);
  }

  private async recommendByOfflineDB(
    currentFood: FoodLabel,
    categories: string[],
    members: FamilyProfile[],
    memberAllergens: Set<string>,
    topN: number
  ): Promise<AlternativeFood[]> {
    if (this.offlineFoodDB.length === 0 || topN <= 0) return [];

    const currentNutrition = new NutritionVector(currentFood.nutrition);
    const candidates: { candidate: OfflineFoodCandidate; score: number; reason: string }[] = [];

    for (const candidate of this.offlineFoodDB) {
      if (candidate.foodName === currentFood.foodName) continue;
      if (categories.length > 0 && !categories.includes(candidate.category)) continue;

      const allergenConflict = candidate.allergenHints.some((a: string) => memberAllergens.has(a));
      if (allergenConflict) continue;

      const candidateNutrition = new NutritionVector(candidate.nutrition);
      const nutritionSimilarity = currentNutrition.cosineSimilarity(candidateNutrition);
      if (nutritionSimilarity < 0.5) continue;

      let score = nutritionSimilarity * 40;

      if (currentFood.nutriScore > 0 && candidate.nutriScore > 0) {
        if (candidate.nutriScore < currentFood.nutriScore) {
          score += (currentFood.nutriScore - candidate.nutriScore) * 8;
        } else if (candidate.nutriScore > currentFood.nutriScore) {
          score -= (candidate.nutriScore - currentFood.nutriScore) * 10;
        }
      }

      if (currentFood.novaGroup > 0 && candidate.novaGroup > 0) {
        if (candidate.novaGroup < currentFood.novaGroup) {
          score += (currentFood.novaGroup - candidate.novaGroup) * 5;
        } else if (candidate.novaGroup > currentFood.novaGroup) {
          score -= (candidate.novaGroup - currentFood.novaGroup) * 6;
        }
      }

      const additivePenalty = this.computeAdditiveImprovement(currentFood, candidate);
      score += additivePenalty;

      if (currentFood.nutrition.sodium > 0 && candidate.nutrition.sodium < currentFood.nutrition.sodium) {
        score += 3;
      }
      if (currentFood.nutrition.sugar > 0 && candidate.nutrition.sugar < currentFood.nutrition.sugar) {
        score += 3;
      }
      if (currentFood.nutrition.calories > 0 && candidate.nutrition.calories < currentFood.nutrition.calories) {
        score += 2;
      }

      if (score < 10) continue;

      const reasons: string[] = [];
      if (nutritionSimilarity > 0.8) reasons.push('营养构成高度相似');
      else if (nutritionSimilarity > 0.6) reasons.push('营养构成相近');
      if (candidate.nutriScore < currentFood.nutriScore) reasons.push('营养等级更优');
      if (candidate.novaGroup < currentFood.novaGroup) reasons.push('加工程度更低');
      if (candidate.nutrition.sodium < currentFood.nutrition.sodium * 0.7) reasons.push('钠含量大幅降低');
      if (candidate.nutrition.sugar < currentFood.nutrition.sugar * 0.5) reasons.push('糖含量显著降低');

      candidates.push({
        candidate,
        score: Math.min(100, Math.max(0, score)),
        reason: reasons.length > 0 ? reasons.join('；') : '综合营养评估更优'
      });
    }

    candidates.sort((a, b) => b.score - a.score);
    const topCandidates = candidates.slice(0, topN);

    return this.scoreAlternativesForMembers(
      topCandidates.map(c => new AlternativeFood(
        c.candidate.foodName,
        c.candidate.brand,
        Math.round(c.score),
        AlternativeFoodRecommender.scoreToLevel(Math.round(c.score)),
        Math.round(c.candidate.nutrition.sodium),
        Math.round(c.candidate.nutrition.sugar * 10) / 10,
        Math.round(c.candidate.nutrition.calories),
        c.reason
      )),
      members
    );
  }

  private computeAdditiveImprovement(currentFood: FoodLabel, candidate: OfflineFoodCandidate): number {
    const dislikedAdditivePatterns: string[][] = [
      ['高果糖浆', '果葡糖浆', 'HFCS'],
      ['阿斯巴甜', 'aspartame'],
      ['部分氢化', '氢化植物油', '起酥油'],
      ['亚硝酸钠', '亚硝酸钾', '硝酸钠'],
      ['安赛蜜', 'acesulfame'],
      ['三氯蔗糖', 'sucralose'],
      ['苯甲酸钠', 'benzoate'],
      ['山梨酸钾', 'sorbate'],
      ['BHA', 'BHT', 'TBHQ'],
      ['人造奶油', '植脂末', '代可可脂'],
    ];

    const currentIngredientStr = currentFood.ingredients.join(',').toLowerCase();
    const candidateIngredientStr = candidate.ingredients.join(',').toLowerCase();

    let currentBadCount = 0;
    let candidateBadCount = 0;
    for (const patternGroup of dislikedAdditivePatterns) {
      const currentHas = patternGroup.some(p => currentIngredientStr.includes(p.toLowerCase()));
      const candidateHas = patternGroup.some(p => candidateIngredientStr.includes(p.toLowerCase()));
      if (currentHas) currentBadCount++;
      if (candidateHas) candidateBadCount++;
    }

    if (candidateBadCount < currentBadCount) {
      return (currentBadCount - candidateBadCount) * 5;
    }
    if (candidateBadCount > currentBadCount) {
      return (currentBadCount - candidateBadCount) * 8;
    }
    return 0;
  }

  private collectMemberAllergens(members: FamilyProfile[]): Set<string> {
    const allergens = new Set<string>();
    for (const member of members) {
      for (const allergen of member.allergens) {
        allergens.add(allergen.toLowerCase());
        allergens.add(allergen);
      }
    }
    return allergens;
  }

  private hasAllergenConflict(foodName: string, memberAllergens: Set<string>): boolean {
    const nameLower = foodName.toLowerCase();
    for (const allergen of memberAllergens) {
      if (nameLower.includes(allergen.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  private getNutritionBasedAlternatives(
    foodLabel: FoodLabel,
    members: FamilyProfile[],
    topN: number
  ): AlternativeFood[] {
    if (topN <= 0) return [];
    const nutrition = foodLabel.nutrition;
    const suggestions: AlternativeFood[] = [];

    if (nutrition.sodium > 400) {
      suggestions.push(new AlternativeFood(
        '低钠版同类食品', '建议选择', 65, RecommendationLevel.YELLOW,
        120, nutrition.sugar, nutrition.calories,
        '钠含量降低70%以上，更有助于控制血压和水分平衡'
      ));
    }

    if (nutrition.sugar > 12) {
      suggestions.push(new AlternativeFood(
        '无糖/低糖版', '建议选择', 60, RecommendationLevel.YELLOW,
        nutrition.sodium, 3, Math.round(nutrition.calories * 0.7),
        '糖含量降低75%以上，热量显著降低'
      ));
    }

    if (nutrition.calories > 250) {
      suggestions.push(new AlternativeFood(
        '清淡低卡替代品', '新鲜食材优先', 70, RecommendationLevel.YELLOW,
        nutrition.sodium, nutrition.sugar, Math.round(nutrition.calories * 0.5),
        '热量降低50%，更利于体重管理和代谢健康'
      ));
    }

    suggestions.push(new AlternativeFood(
      '新鲜水果/蔬菜', '当季新鲜食材', 90, RecommendationLevel.GREEN,
      5, 8, 50, '天然维生素和膳食纤维来源，热量低，无添加剂'
    ));

    return this.scoreAlternativesForMembers(suggestions, members).slice(0, topN);
  }

  private scoreAlternativesForMembers(
    candidates: AlternativeFood[],
    members: FamilyProfile[]
  ): AlternativeFood[] {
    if (members.length === 0) return candidates;

    const result: AlternativeFood[] = [];
    for (const alt of candidates) {
      let scoreAdjustment = 0;

      for (const member of members) {
        for (const goal of member.healthGoals) {
          if (goal === HealthGoal.CONTROL_BP) {
            if (alt.sodium_mg <= 120) scoreAdjustment += 5;
            else if (alt.sodium_mg > 400) scoreAdjustment -= 5;
          } else if (goal === HealthGoal.CONTROL_SUGAR) {
            if (alt.sugar_g <= 5) scoreAdjustment += 5;
            else if (alt.sugar_g > NUTRIENT_LIMITS_V2.SUGAR_HIGH_THRESHOLD_G) scoreAdjustment -= 5;
          } else if (goal === HealthGoal.LOSE_FAT) {
            if (alt.energyKcal <= 80) scoreAdjustment += 5;
            else if (alt.energyKcal > 250) scoreAdjustment -= 5;
          } else if (goal === HealthGoal.CONTROL_FAT) {
            if (alt.sodium_mg <= 200) scoreAdjustment += 3;
          } else if (goal === HealthGoal.CHILD) {
            if (alt.sugar_g <= 5 && alt.sodium_mg <= 200) scoreAdjustment += 5;
          }
        }
      }

      const adjustedScore = Math.max(10, Math.min(100, alt.healthScore + scoreAdjustment));
      result.push(new AlternativeFood(
        alt.productName, alt.brand, adjustedScore,
        AlternativeFoodRecommender.scoreToLevel(adjustedScore),
        alt.sodium_mg, alt.sugar_g, alt.energyKcal, alt.reason
      ));
    }

    return result;
  }

  private identifyCategory(foodLabel: FoodLabel): string[] {
    const categories: string[] = [];
    const foodName = foodLabel.foodName.toLowerCase();
    const ingredientsText = foodLabel.ingredients.join(',').toLowerCase();

    for (const entry of this.CATEGORY_KEYWORDS) {
      for (const kw of entry.keywords) {
        if (foodName.includes(kw) || ingredientsText.includes(kw)) {
          categories.push(entry.category);
          break;
        }
      }
    }

    return categories;
  }

  async recommendByNutrition(
    nutrition: NutritionPer100g,
    members: FamilyProfile[]
  ): Promise<AlternativeFood[]> {
    const foodLabel = new FoodLabel();
    foodLabel.foodName = '扫描食品';
    foodLabel.nutrition = nutrition;
    foodLabel.ingredients = [];
    return this.recommendAlternatives(foodLabel, members, 3);
  }

  getAlternativesForCategory(category: string): AlternativeFood[] {
    const result: AlternativeFood[] = [];
    for (const alt of this.ALTERNATIVE_FOODS) {
      if (alt.originalCategory === category) {
        result.push(new AlternativeFood(
          alt.alternativeName, alt.brand, alt.healthScore,
          AlternativeFoodRecommender.scoreToLevel(alt.healthScore),
          alt.sodium_mg, alt.sugar_g, alt.energyKcal, alt.reason
        ));
      }
    }
    return result;
  }

  getSupportedCategories(): string[] {
    const set: Set<string> = new Set();
    const result: string[] = [];
    for (const alt of this.ALTERNATIVE_FOODS) {
      if (!set.has(alt.originalCategory)) {
        set.add(alt.originalCategory);
        result.push(alt.originalCategory);
      }
    }
    return result;
  }

  static generateAdviceText(originalFood: string, alternative: AlternativeFood): string {
    const lines: string[] = [];
    lines.push('🔍 替代建议：' + originalFood + ' → ' + alternative.productName);
    lines.push('');
    lines.push('推荐理由：' + alternative.reason);
    lines.push('');
    lines.push('📊 营养改善：');
    lines.push('  钠：↘️ 每100g含' + alternative.sodium_mg + 'mg');
    lines.push('  糖：↘️ 每100g含' + alternative.sugar_g + 'g');
    lines.push('  热量：↘️ 每100g含' + alternative.energyKcal + 'kcal');
    lines.push('');
    lines.push('品牌推荐：' + alternative.brand);
    lines.push('');
    lines.push('更换后不仅更健康，口感也能满足您的需求～');
    return lines.join('\n');
  }

  private static scoreToLevel(score: number): RecommendationLevel {
    if (score >= 70) return RecommendationLevel.GREEN;
    if (score >= 50) return RecommendationLevel.YELLOW;
    if (score >= 30) return RecommendationLevel.ORANGE;
    return RecommendationLevel.RED;
  }
}

export const alternativeFoodRecommender: AlternativeFoodRecommender = new AlternativeFoodRecommender();
