import { FamilyProfile, AgeGroup, FoodLabel, NutritionThreshold } from 'hsp_core';
// ChildHealthAssessmentEngine.ets
// 儿童专属健康评估与推荐引擎
// 评估零食/食品对儿童的影响（食欲、糖分、添加剂），生成综合安全评分


/** 添加剂安全等级 */
export enum AdditiveSafetyLevel {
  SAFE = 'safe',
  CAUTION = 'caution',
  AVOID_FOR_CHILD = 'avoid_for_child',
  AVOID = 'avoid_for_child'
}

/** 添加剂安全评估结果 */
export class AdditiveSafetyResult {
  name: string = '';
  additiveName: string = '';
  code: string = '';
  safetyLevel: AdditiveSafetyLevel = AdditiveSafetyLevel.SAFE;
  description: string = '';
}

/** 零食影响评估 */
export class SnackImpactAssessment {
  mealAppetiteLevel: string = '轻微影响';
  sugarImpactLevel: string = '安全';
  dailySugarContribution: number = 0;
  recommendation: string = '';
  portionAdvice: string = '';
}

/** 儿童健康综合评估 */
export class ChildHealthAssessment {
  memberId: string = '';
  foodId: string = '';
  foodName: string = '';
  snackImpact: SnackImpactAssessment = new SnackImpactAssessment();
  additiveResults: AdditiveSafetyResult[] = [];
  overallSafetyScore: number = 100;
  overallAdvice: string = '';
  growthNutritionCheck: string[] = [];
}

/** 儿童敏感添加剂库 */
const AVOID_ADDITIVES: Record<string, string> = {
  '柠檬黄': '人工色素，可能导致儿童注意力不集中',
  '日落黄': '合成色素，儿童应避免摄入',
  '阿斯巴甜': '人工甜味剂，儿童不宜',
  '苯甲酸钠': '防腐剂，可能引起敏感反应',
  '诱惑红': '合成色素，儿童应避免',
  '亮蓝': '合成色素，不建议儿童摄入',
};

const CAUTION_ADDITIVES: Record<string, string> = {
  '山梨酸钾': '防腐剂，需控制摄入量',
  '味精': '增味剂，儿童不宜过多',
  '亚硝酸钠': '防腐剂/护色剂，需注意摄入量',
  '甜蜜素': '甜味剂，不建议儿童长期摄入',
};

const SAFE_ADDITIVES: Record<string, string> = {
  '黄原胶': '天然增稠剂，公认安全',
  '羧甲基纤维素': '膳食纤维类增稠剂，安全',
  '维生素C': '营养强化剂，有益',
  '维生素E': '抗氧化剂/营养强化剂',
  '乳酸链球菌素': '天然防腐剂，安全',
};

export class ChildHealthAssessmentEngine {

  /**
   * 评估食品对儿童的影响
   * @param food 食品标签
   * @param profile 成员档案
   * @param todaySnackCalories 今日已摄入零食热量
   * @param todaySugarGrams 今日已摄入糖克数
   */
  assess(
    food: FoodLabel,
    profile: FamilyProfile,
    todaySnackCalories: number,
    todaySugarGrams: number
  ): ChildHealthAssessment {
    const result = new ChildHealthAssessment();
    result.memberId = profile.memberId;
    result.foodId = food.foodId;
    result.foodName = food.foodName;

    // 1. 零食影响评估
    result.snackImpact = this.assessSnackImpact(food, profile, todaySnackCalories, todaySugarGrams);

    result.additiveResults = this.assessAdditivesForAge(food, profile.ageGroup);

    // 3. 生长发育营养检查
    result.growthNutritionCheck = this.checkGrowthNutrition(food, profile);

    // 4. 综合评分
    result.overallSafetyScore = this.calculateOverallScore(food, result, profile);
    result.overallAdvice = this.generateOverallAdvice(food, result, profile);

    return result;
  }

  private assessSnackImpact(
    food: FoodLabel,
    profile: FamilyProfile,
    todaySnackCalories: number,
    todaySugarGrams: number
  ): SnackImpactAssessment {
    const impact = new SnackImpactAssessment();
    const foodCalories = food.nutrition.calories;
    const foodSugar = food.nutrition.sugar;

    // 食欲影响
    const childLimit = profile.ageGroup === AgeGroup.TEEN ? 200 : 150;
    const totalCal = todaySnackCalories + foodCalories;
    if (totalCal >= childLimit) {
      impact.mealAppetiteLevel = '严重影响';
    } else if (foodCalories >= 100) {
      impact.mealAppetiteLevel = '中等影响';
    } else {
      impact.mealAppetiteLevel = '轻微影响';
    }

    // 糖分影响
    const childSugarLimit = profile.ageGroup === AgeGroup.TEEN ? 30 : 20;
    const totalSugar = todaySugarGrams + foodSugar;
    impact.dailySugarContribution = totalSugar;
    if (totalSugar > childSugarLimit) {
      impact.sugarImpactLevel = '超标';
    } else if (foodSugar >= 15) {
      impact.sugarImpactLevel = '偏高';
    } else {
      impact.sugarImpactLevel = '安全';
    }

    return impact;
  }

  private assessAdditives(food: FoodLabel): AdditiveSafetyResult[] {
    return this.assessAdditivesForAge(food, AgeGroup.CHILD);
  }

  private assessAdditivesForAge(food: FoodLabel, ageGroup: AgeGroup): AdditiveSafetyResult[] {
    const results: AdditiveSafetyResult[] = [];

    const avoidForAge: Record<string, string> = Object.assign({}, AVOID_ADDITIVES) as Record<string, string>;
    const cautionForAge: Record<string, string> = Object.assign({}, CAUTION_ADDITIVES) as Record<string, string>;

    if (ageGroup === AgeGroup.INFANT || ageGroup === AgeGroup.TODDLER) {
      avoidForAge['山梨酸钾'] = '婴幼儿禁用此防腐剂';
      avoidForAge['味精'] = '婴幼儿不宜摄入味精';
      avoidForAge['甜蜜素'] = '婴幼儿禁用人工甜味剂';
      avoidForAge['安赛蜜'] = '婴幼儿禁用人工甜味剂';
      cautionForAge['黄原胶'] = '增稠剂，婴幼儿需谨慎';
    } else if (ageGroup === AgeGroup.CHILD) {
      cautionForAge['山梨酸钾'] = '防腐剂，儿童需控制摄入量';
      cautionForAge['甜蜜素'] = '甜味剂，不建议儿童长期摄入';
    }

    for (const ingredient of food.ingredients) {
      const trimmed = ingredient.trim();

      if (avoidForAge[trimmed]) {
        const r = new AdditiveSafetyResult();
        r.name = trimmed;
        r.additiveName = trimmed;
        r.safetyLevel = AdditiveSafetyLevel.AVOID_FOR_CHILD;
        r.description = avoidForAge[trimmed];
        results.push(r);
      } else if (cautionForAge[trimmed]) {
        const r = new AdditiveSafetyResult();
        r.name = trimmed;
        r.additiveName = trimmed;
        r.safetyLevel = AdditiveSafetyLevel.CAUTION;
        r.description = cautionForAge[trimmed];
        results.push(r);
      } else if (SAFE_ADDITIVES[trimmed]) {
        const r = new AdditiveSafetyResult();
        r.name = trimmed;
        r.additiveName = trimmed;
        r.safetyLevel = AdditiveSafetyLevel.SAFE;
        r.description = SAFE_ADDITIVES[trimmed];
        results.push(r);
      }
    }

    return results;
  }

  private checkGrowthNutrition(food: FoodLabel, profile: FamilyProfile): string[] {
    const checks: string[] = [];

    // 关注儿童/青少年生长发育关键营养素
    if (profile.ageGroup === AgeGroup.CHILD || profile.ageGroup === AgeGroup.TEEN) {
      if (food.nutrition.protein >= 8) {
        checks.push('✅ 高蛋白食品，利于生长发育');
      }
      if (food.nutrition.calcium >= 100) {
        checks.push('✅ 富含钙质，促进骨骼发育');
      }
      if (food.nutrition.iron >= 2) {
        checks.push('✅ 含铁丰富，预防缺铁性贫血');
      }
      if (food.nutrition.fiber >= 3) {
        checks.push('✅ 膳食纤维充足，利于肠道健康');
      }
    }

    return checks;
  }

  private calculateOverallScore(
    food: FoodLabel,
    result: ChildHealthAssessment,
    profile: FamilyProfile
  ): number {
    let score = 100;

    // 扣分：零食高热量
    if (food.nutrition.calories >= 200) score -= 25;
    else if (food.nutrition.calories >= 150) score -= 15;
    else if (food.nutrition.calories >= 100) score -= 10;

    // 扣分：高糖
    const sugarLimit = profile.ageGroup === AgeGroup.TEEN ? 30 : 20;
    if (food.nutrition.sugar > sugarLimit) score -= 20;
    else if (food.nutrition.sugar >= 15) score -= 10;

    // 扣分：高钠
    if (food.nutrition.sodium >= 500) score -= 15;
    else if (food.nutrition.sodium >= NutritionThreshold.HIGH_SODIUM_MG) score -= 10;

    // 扣分：AVOID 添加剂
    const avoidCount = result.additiveResults.filter(a => a.safetyLevel === AdditiveSafetyLevel.AVOID_FOR_CHILD).length;
    score -= avoidCount * 10;

    // 扣分：CAUTION 添加剂
    const cautionCount = result.additiveResults.filter(a => a.safetyLevel === AdditiveSafetyLevel.CAUTION).length;
    score -= cautionCount * 5;

    // 加分：蛋白质
    if (food.nutrition.protein >= 10) score = Math.min(100, score + 10);

    // 加分：钙
    if (food.nutrition.calcium >= 100) score = Math.min(100, score + 5);

    return Math.max(0, Math.min(100, score));
  }

  private generateOverallAdvice(
    food: FoodLabel,
    result: ChildHealthAssessment,
    profile: FamilyProfile
  ): string {
    const nick = profile.nickname || '孩子';

    if (result.overallSafetyScore >= NutritionThreshold.CHILD_SAFETY_SCORE_GOOD) {
      return `${nick}食用「${food.foodName}」总体安全，适可而止哦。`;
    }

    const parts: string[] = [`「${food.foodName}」对${nick}的安全评分偏低（${result.overallSafetyScore}分）。`];

    if (result.snackImpact.mealAppetiteLevel === '严重影响') {
      parts.push('高热量零食会影响正餐食欲，建议减量。');
    }
    if (result.snackImpact.sugarImpactLevel === '超标') {
      parts.push('今日糖摄入已超标，不建议再吃此食品。');
    }
    if (result.additiveResults.some(a => a.safetyLevel === AdditiveSafetyLevel.AVOID_FOR_CHILD)) {
      parts.push('含儿童不宜添加剂，建议避免。');
    }

    return parts.join('');
  }
}
