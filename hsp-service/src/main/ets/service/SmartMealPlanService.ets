// SmartMealPlanService.ets
// AI驱动个性化周计划生成 — MealPlanService + LlmChatProxy + HealthGoal优化

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, DailyBudget, FamilyProfile, HealthGoal } from 'hsp_core';
import { MealPlanService, MealPlan, MealPlanItem } from './MealPlanService';
import { LlmChatProxy, LlmSource } from './ai/LlmChatProxy';

const TAG = 'SmartMealPlanService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface WeeklyMealPlan {
  memberId: string;
  memberName: string;
  weekStart: string;
  weekEnd: string;
  dailyPlans: MealPlan[];
  weeklySummary: {
    avgCalories: number; avgSodium: number; avgSugar: number;
    avgFat: number; avgProtein: number;
  };
  aiWeeklyAdvice: string;
  aiMealTips: string[];
  goalProgress: GoalProgress;
}

export interface GoalProgress {
  goal: string;
  currentStatus: string;
  weeklyTarget: string;
  tipOfWeek: string;
}

export class SmartMealPlanService {
  private static instance: SmartMealPlanService | null = null;
  private mealPlanService: MealPlanService;
  private llmProxy: LlmChatProxy;

  private constructor() {
    this.mealPlanService = new MealPlanService();
    this.llmProxy = LlmChatProxy.getInstance();
  }

  static getInstance(): SmartMealPlanService {
    if (!SmartMealPlanService.instance) {
      SmartMealPlanService.instance = new SmartMealPlanService();
    }
    return SmartMealPlanService.instance;
  }

  async generateWeeklyPlan(
    memberId: string,
    memberName: string,
    profile: FamilyProfile,
    availableFoods: FoodLabel[],
    startDate: string,
    days: number = 7
  ): Promise<WeeklyMealPlan> {
    const dailyPlans: MealPlan[] = [];
    let totalCal = 0, totalSodium = 0, totalSugar = 0, totalFat = 0, totalProtein = 0;
    let planCount = 0;

    const start = new Date(startDate);
    for (let d = 0; d < days; d++) {
      const date = new Date(start);
      date.setDate(start.getDate() + d);
      const dateStr = this.formatDate(date);
      const budget = this.buildBudgetForDay(profile, d);

      const plan = this.mealPlanService.generatePlan(memberId, dateStr, availableFoods, budget, profile);
      dailyPlans.push(plan);
      totalCal += plan.dailyTotal.calories;
      totalSodium += plan.dailyTotal.sodium;
      totalSugar += plan.dailyTotal.sugar;
      totalFat += plan.dailyTotal.fat;
      totalProtein += plan.dailyTotal.protein;
      planCount++;
    }

    const weeklySummary = {
      avgCalories: Math.round(totalCal / planCount),
      avgSodium: Math.round(totalSodium / planCount),
      avgSugar: Math.round(totalSugar / planCount),
      avgFat: Math.round(totalFat / planCount),
      avgProtein: Math.round(totalProtein / planCount),
    };

    const goalProgress = this.buildGoalProgress(profile);
    const ctx = this.buildAiContext(memberName, profile, weeklySummary, goalProgress);

    let aiWeeklyAdvice = this.localWeeklyAdvice(profile, weeklySummary);
    let aiMealTips = this.localMealTips(profile);

    try {
      const question = `${ctx}\n\n请给出: 1) 本周饮食总评(50字) 2) 3条改进建议`;
      const resp = await this.llmProxy.chat({
        question, context: [], memberId,
        analysisType: 'nutrition', preferOffline: false,
      });
      if (resp && resp.source !== LlmSource.FALLBACK_TEMPLATE) {
        aiWeeklyAdvice = resp.answer.split('2)')[0]?.replace('1)', '').trim() ?? resp.answer;
      }
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_)); /* use local */ }

    const weekEnd = new Date(start);
    weekEnd.setDate(start.getDate() + days - 1);

    return {
      memberId, memberName,
      weekStart: this.formatDate(start), weekEnd: this.formatDate(weekEnd),
      dailyPlans, weeklySummary,
      aiWeeklyAdvice, aiMealTips, goalProgress,
    };
  }

  private buildAiContext(
    name: string, profile: FamilyProfile,
    summary: WeeklyMealPlan.weeklySummary,
    goal: GoalProgress
  ): string {
    const goals = profile.healthGoals?.join('、') ?? '维持体重';
    return `用户: ${name}, 健康目标: ${goals}, 本周日均: 热量${summary.avgCalories}kcal、钠${summary.avgSodium}mg、糖${summary.avgSugar}g、脂肪${summary.avgFat}g、蛋白质${summary.avgProtein}g。目标: ${goal.weeklyTarget}。`;
  }

  private buildGoalProgress(profile: FamilyProfile): GoalProgress {
    const goals = profile.healthGoals ?? [];
    let goal = '均衡营养';
    let tip = '保持多样化饮食，每日摄入12种以上食物';

    if (goals.includes(HealthGoal.CONTROL_BP)) {
      goal = '控血压'; tip = '每日钠摄入<2000mg，多吃含钾蔬果(菠菜/香蕉)';
    } else if (goals.includes(HealthGoal.LOSE_FAT)) {
      goal = '减脂'; tip = '控制总热量，增加蛋白质占比至25%，每周运动3次';
    } else if (goals.includes(HealthGoal.CONTROL_SUGAR)) {
      goal = '控糖'; tip = '避免含糖饮料，优选低GI主食(糙米/荞麦)';
    } else if (goals.includes(HealthGoal.MUSCLE_GAIN)) {
      goal = '增肌'; tip = '蛋白质目标1.6g/kg体重，搭配力量训练';
    }

    return {
      goal, currentStatus: '进行中',
      weeklyTarget: `达成${goal}周目标`,
      tipOfWeek: tip,
    };
  }

  private localWeeklyAdvice(profile: FamilyProfile, summary: WeeklyMealPlan.weeklySummary): string {
    const limits = profile.getDailyLimits?.() ?? { sodium: 2000, sugar: 25, fat: 65 };
    const parts: string[] = [];
    if (summary.avgSodium > limits.sodium) parts.push('钠摄入偏高');
    if (summary.avgSugar > limits.sugar) parts.push('糖分偏高');
    if (summary.avgFat > limits.fat) parts.push('脂肪偏高');
    if (parts.length > 0) {
      return `本周需关注: ${parts.join('、')}，建议调整食材搭配。`;
    }
    return `本周饮食均衡，各项指标在合理范围内，继续保持！`;
  }

  private localMealTips(profile: FamilyProfile): string[] {
    const tips: string[] = [];
    const goals = profile.healthGoals ?? [];

    if (goals.includes(HealthGoal.CONTROL_BP)) {
      tips.push('选择低钠酱油和减盐调味品');
      tips.push('多吃深绿色蔬菜补充钾镁');
    }
    if (goals.includes(HealthGoal.LOSE_FAT)) {
      tips.push('优先选择蒸煮方式，减少油炸');
      tips.push('午餐加一份绿叶蔬菜增加饱腹感');
    }
    tips.push('早餐加一份优质蛋白(鸡蛋/豆腐/酸奶)');
    tips.push('每餐至少3种颜色食材，保证营养多样性');

    return tips.slice(0, 4);
  }

  private buildBudgetForDay(profile: FamilyProfile, dayIndex: number): DailyBudget {
    const budget: DailyBudget = new DailyBudget(
    const baseCal = profile.isChild() ? 1800 : 2200;
    budget.calorieBudget = baseCal;
    budget.sodiumBudget = profile.isControlBp() ? 1500 : 2000;
    budget.sugarBudget = profile.isControlSugar() ? 15 : 25;
    budget.fatBudget = profile.isLoseFat() ? 50 : 65;
    budget.proteinBudget = profile.isMuscleGain() ? 100 : 60;
    return budget;
  }

  private formatDate(date: Date): string {
    const y = date.getFullYear();
    const m = ().toString().padStart(2, '0');
    const d = date.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
}