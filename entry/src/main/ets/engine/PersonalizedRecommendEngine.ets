import {
  FamilyProfile, AgeGroup, HealthGoal, HealthSignal, BpStatus, BsStatus, FoodLabel, NutritionTarget, DailyBudget
} from 'hsp_core';
// PersonalizedRecommendEngine.ets
// 个性化数据驱动推荐引擎
// 基于5维因子（健康目标/预算/信号/体检/行为）综合评分食品适配度


/** 个性化上下文 */
export class PersonalizedContext {
  profile: FamilyProfile = new FamilyProfile();
  signal: HealthSignal = new HealthSignal();
  target: NutritionTarget = new NutritionTarget();
  budget: DailyBudget = new DailyBudget();
  recentDietSodiumAvg: number = 0;
  recentDietSugarAvg: number = 0;
  consecutiveHighSodiumDays: number = 0;
  checkupAbnormalItems: string[] = [];
}

export type RecommendationContext = PersonalizedContext;

/** 个性化因子 */
export class PersonalizedFactor {
  name: string = '';
  score: number = 0;
  detail: string = '';
  reasoning: string = '';
}

/** 个性化推荐结果 */
export class PersonalizedRecommendation {
  memberId: string = '';
  foodId: string = '';
  factors: PersonalizedFactor[] = [];
  overallScore: number = 50;
  level: string = '';
  dataConfidence: number = 0.5;
  personalizedSummary: string = '';
  urgencyNote: string = '';
  maxPortion: string = '';
}

/** 基于上下文的空腹信度 */
function computeDataConfidence(ctx: PersonalizedContext): number {
  let score = 0.5;
  if (ctx.profile.memberId.length > 0 && ctx.profile.nickname.length > 0) score += 0.1;
  if (ctx.profile.healthGoals.length > 0 && ctx.profile.healthGoals[0] !== HealthGoal.NONE) score += 0.1;
  if (ctx.signal.lastUpdated > 0) score += 0.1;
  if (ctx.budget.date.length > 0) score += 0.1;
  return Math.min(1.0, Math.max(0.0, score));
}

/** 含嘌呤高风险关键词 */
const HIGH_PURINE_KEYWORDS: string[] = ['海鲜', '肉汤', '火锅', '内脏', '贝壳', '虾', '蟹', '贝', '鱼籽', '鹅肝'];

export class PersonalizedRecommendEngine {

  /**
   * 基于食品和个性化上下文，生成5维因子综合推荐
   */
  recommend(food: FoodLabel, ctx: PersonalizedContext): PersonalizedRecommendation {
    const result = new PersonalizedRecommendation();
    result.memberId = ctx.profile.memberId;
    result.foodId = food.foodId;
    result.factors = [];
    result.dataConfidence = computeDataConfidence(ctx);

    // 因子1: 健康目标契合度 (0-100)
    const goalScore = this.assessGoalAlignment(food, ctx);
    const f1 = new PersonalizedFactor();
    f1.name = '健康目标契合度'; f1.score = goalScore; f1.detail = this.describeGoalFactor(ctx);
    result.factors.push(f1);

    // 因子2: 营养预算占用 (0-100)
    const budgetScore = this.assessBudgetFit(food, ctx);
    const f2 = new PersonalizedFactor();
    f2.name = '营养预算占用'; f2.score = budgetScore; f2.detail = this.describeBudgetFactor(ctx);
    result.factors.push(f2);

    // 因子3: 健康信号影响 (0-100)
    const signalScore = this.assessSignalImpact(food, ctx);
    const f3 = new PersonalizedFactor();
    f3.name = '健康信号影响'; f3.score = signalScore; f3.detail = this.describeSignalFactor(ctx);
    result.factors.push(f3);

    // 因子4: 体检约束 (0-100)
    const checkupScore = this.assessCheckupConstraints(food, ctx);
    const f4 = new PersonalizedFactor();
    f4.name = '体检约束'; f4.score = checkupScore; f4.detail = this.describeCheckupFactor(ctx);
    result.factors.push(f4);

    // 因子5: 行为模式 (0-100)
    const behaviorScore = this.assessBehaviorPattern(ctx);
    const f5 = new PersonalizedFactor();
    f5.name = '行为模式'; f5.score = behaviorScore; f5.detail = this.describeBehaviorFactor(ctx);
    result.factors.push(f5);

    // 加权综合分数
    result.overallScore = Math.round(
      goalScore * 0.3 + budgetScore * 0.25 + signalScore * 0.2 + checkupScore * 0.15 + behaviorScore * 0.1
    );
    result.overallScore = Math.max(0, Math.min(100, result.overallScore));

    // 评级
    if (result.overallScore >= 80) result.level = '推荐';
    else if (result.overallScore >= 60) result.level = '可以';
    else if (result.overallScore >= 40) result.level = '谨慎';
    else result.level = '不建议';

    // 个性化总结
    result.personalizedSummary = this.generateSummary(food, ctx, result);

    // 紧急提示
    result.urgencyNote = this.generateUrgencyNote(food, ctx, result);

    return result;
  }

  // ========== 因子1: 健康目标契合度 ==========
  private assessGoalAlignment(food: FoodLabel, ctx: PersonalizedContext): number {
    let score = 80;
    const goals = ctx.profile.healthGoals;

    if (goals.length === 0 || goals.includes(HealthGoal.NONE)) return score;

    for (const goal of goals) {
      switch (goal) {
        case HealthGoal.CONTROL_BP:
          if (food.nutrition.sodium >= 500) score -= 30;
          else if (food.nutrition.sodium >= 300) score -= 15;
          else if (food.nutrition.sodium <= 100) score += 10;
          break;
        case HealthGoal.CONTROL_SUGAR:
          if (food.nutrition.sugar >= 15) score -= 20;
          else if (food.nutrition.sugar <= 5) score += 10;
          break;
        case HealthGoal.CONTROL_FAT:
        case HealthGoal.LOSE_FAT:
          if (food.nutrition.fat >= 20) score -= 25;
          else if (food.nutrition.calories >= 400) score -= 20;
          else if (food.nutrition.fat <= 5) score += 5;
          break;
        case HealthGoal.CHILD:
          if (food.nutrition.sodium >= 400) score -= 10;
          if (food.nutrition.sugar >= 20) score -= 10;
          break;
      }
    }

    return Math.max(0, Math.min(100, score));
  }

  private describeGoalFactor(ctx: PersonalizedContext): string {
    const goals = ctx.profile.healthGoals.filter(g => g !== HealthGoal.NONE);
    return goals.length > 0 ? `目标:${goals.join('/')}` : '无特殊目标';
  }

  // ========== 因子2: 营养预算占用 ==========
  private assessBudgetFit(food: FoodLabel, ctx: PersonalizedContext): number {
    let score = 100;

    if (ctx.budget.sodiumRemaining <= 0) return 10;
    if (ctx.budget.sugarRemaining <= 0) return 10;
    if (ctx.budget.calorieRemaining <= 0) return 10;

    const sodiumRatio = food.nutrition.sodium / ctx.budget.sodiumRemaining;
    const sugarRatio = food.nutrition.sugar / ctx.budget.sugarRemaining;
    const calorieRatio = food.nutrition.calories / ctx.budget.calorieRemaining;

    if (sodiumRatio > 0.5) score -= 30;
    else if (sodiumRatio > 0.3) score -= 15;
    if (sugarRatio > 0.5) score -= 20;
    else if (sugarRatio > 0.3) score -= 10;
    if (calorieRatio > 0.5) score -= 20;

    return Math.max(0, Math.min(100, score));
  }

  private describeBudgetFactor(ctx: PersonalizedContext): string {
    return `钠剩余${ctx.budget.sodiumRemaining}mg 糖剩余${ctx.budget.sugarRemaining}g`;
  }

  // ========== 因子3: 健康信号影响 ==========
  private assessSignalImpact(food: FoodLabel, ctx: PersonalizedContext): number {
    let score = 80;

    // 血压信号
    if (ctx.signal.manualBpStatus === BpStatus.HIGH || ctx.signal.manualBpStatus === BpStatus.VERY_HIGH) {
      if (food.nutrition.sodium <= 100) score += 10;
      else if (food.nutrition.sodium >= 400) score -= 25;
    }
    if (ctx.signal.manualBpStatus === BpStatus.ELEVATED) {
      if (food.nutrition.sodium >= 400) score -= 15;
    }

    // 血糖信号
    if (ctx.signal.manualBsStatus === BsStatus.HIGH || ctx.signal.manualBsStatus === BsStatus.VERY_HIGH) {
      if (food.nutrition.sugar >= 15) score -= 20;
      else if (food.nutrition.sugar <= 5) score += 5;
    }
    if (ctx.signal.manualBsStatus === BsStatus.ELEVATED) {
      if (food.nutrition.sugar >= 15) score -= 10;
    }

    // 睡眠差 → 高糖惩罚
    if (ctx.signal.sleepStatus === '差') {
      if (food.nutrition.sugar >= 15) score -= 10;
    }

    return Math.max(0, Math.min(100, score));
  }

  private describeSignalFactor(ctx: PersonalizedContext): string {
    const parts: string[] = [];
    if (ctx.signal.manualBpStatus !== BpStatus.NORMAL) parts.push(`血压${ctx.signal.manualBpStatus}`);
    if (ctx.signal.manualBsStatus !== BsStatus.NORMAL) parts.push(`血糖${ctx.signal.manualBsStatus}`);
    return parts.length > 0 ? parts.join('/') : '信号正常';
  }

  // ========== 因子4: 体检约束 ==========
  private assessCheckupConstraints(food: FoodLabel, ctx: PersonalizedContext): number {
    const abnormals = ctx.checkupAbnormalItems;
    if (abnormals.length === 0) return 100;

    let score = 100;
    const hasBpAbnormal = abnormals.some(a => a.includes('压'));
    const hasSugarAbnormal = abnormals.some(a => a.includes('血糖') || a.includes('HbA1c'));
    const hasUricAbnormal = abnormals.some(a => a.includes('尿酸'));

    if (hasBpAbnormal && food.nutrition.sodium >= 400) score -= 35;
    if (hasSugarAbnormal && food.nutrition.sugar >= 15) score -= 30;
    if (hasUricAbnormal) {
      // 检查是否含高嘌呤成分
      const ingredientsText = food.ingredients.join(' ');
      const hasHighPurine = HIGH_PURINE_KEYWORDS.some(kw => ingredientsText.includes(kw));
      if (hasHighPurine) score -= 45;
    }

    return Math.max(0, Math.min(100, score));
  }

  private describeCheckupFactor(ctx: PersonalizedContext): string {
    return ctx.checkupAbnormalItems.length > 0 ? `异常:${ctx.checkupAbnormalItems.join('/')}` : '无异常';
  }

  // ========== 因子5: 行为模式 ==========
  private assessBehaviorPattern(ctx: PersonalizedContext): number {
    let score = 80;
    if (ctx.consecutiveHighSodiumDays >= 3) score -= 20;
    if (ctx.consecutiveHighSodiumDays >= 5) score -= 30;
    if (ctx.consecutiveHighSodiumDays >= 7) score -= 40;
    return Math.max(0, Math.min(100, score));
  }

  private describeBehaviorFactor(ctx: PersonalizedContext): string {
    if (ctx.consecutiveHighSodiumDays > 0) {
      return `连续${ctx.consecutiveHighSodiumDays}天高钠`;
    }
    return '模式正常';
  }

  // ========== 综合描述 ==========
  private generateSummary(food: FoodLabel, ctx: PersonalizedContext, result: PersonalizedRecommendation): string {
    const nick = ctx.profile.nickname || '该成员';
    return `${nick}食用「${food.foodName}」的综合适配评分为${result.overallScore}分，评级：${result.level}。`;
  }

  private generateUrgencyNote(food: FoodLabel, ctx: PersonalizedContext, result: PersonalizedRecommendation): string {
    if (result.overallScore < 40) {
      const reasons: string[] = [];
      for (const f of result.factors) {
        if (f.score < 50) reasons.push(f.name);
      }
      if (reasons.length > 0) {
        return `⚠️ 紧急提醒：${reasons.join('、')}评分偏低，建议避免此食品。`;
      }
    }
    return '';
  }
}
