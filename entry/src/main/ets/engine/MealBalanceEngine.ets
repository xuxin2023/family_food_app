import { FamilyProfile, HealthSignal, MealBalance, MealScenario, RiskTag, MEAL_TEMPLATES, safeParseRiskTag } from 'hsp_core';
// MealBalanceEngine.ets
// 餐次平衡引擎 - 美食平衡建议
// V2增强：新增6种场景、具体菜品建议、明天早餐建议、下一餐营养素补充


export class MealBalanceEngine {
  /**
   * 计算美食平衡建议
   */
  calculate(scenario: MealScenario, profile: FamilyProfile, healthSignal: HealthSignal): MealBalance {
    const result = new MealBalance();
    result.memberId = profile.memberId;
    result.scenario = scenario;

    const template = MEAL_TEMPLATES.find(t => t.scenario === scenario);
    if (template === undefined) {
      result.riskTags = [RiskTag.HIGH_CALORIE];
      result.nextMealAdvice = '下一餐建议清淡均衡，增加蔬菜和水分';
      result.avoidStacking = [];
      result.hydrationReminder = false;
      return result;
    }

    result.riskTags = template.riskTags.map(tag => safeParseRiskTag(tag));
    result.nextMealAdvice = template.nextMealAdvice;
    result.avoidStacking = template.avoidStacking;
    result.hydrationReminder = template.hydrationReminder;

    const goalAdvices: string[] = [];
    for (const goal of profile.healthGoals) {
      const goalName = goal as string;
      const advice = template.goalAdvice.get(goalName);
      if (advice !== undefined) {
        goalAdvices.push(advice);
      }
    }

    if (healthSignal.isLowActivity()) {
      goalAdvices.push('今日活动量偏低，建议下一餐更加清淡');
    }
    if (healthSignal.isPoorSleep()) {
      goalAdvices.push('睡眠较差，不建议再摄入含咖啡因饮品或高糖食品');
    }

    result.memberSpecificAdvice = goalAdvices.join('。');

    return result;
  }

  /**
   * 获取所有可用场景
   */
  getAvailableScenarios(): MealScenario[] {
    return [
      MealScenario.BBQ,
      MealScenario.HOTPOT,
      MealScenario.FRIED_CHICKEN,
      MealScenario.MILK_TEA,
      MealScenario.DESSERT,
      MealScenario.LUWEI,
      MealScenario.INSTANT_NOODLE,
      MealScenario.LATE_NIGHT,
      MealScenario.MALATANG,
      MealScenario.BBQ_MEAT,
      MealScenario.SUSHI,
      MealScenario.BUFFET,
      MealScenario.AFTERNOON_TEA,
      MealScenario.LUOSIFEN
    ];
  }

  /**
   * 获取场景的生活化完整建议文案
   */
  getFriendlyAdvice(scenario: MealScenario): string {
    const template = MEAL_TEMPLATES.find(t => t.scenario === scenario);
    if (template === undefined) return '';

    const riskText = template.riskTags.join('、');
    return `这顿${scenario}温暖又过瘾！不过${riskText}可能偏多，下一餐建议来份${template.nextMealAdvice}，今天${template.avoidStacking.slice(0, 2).join('和')}就先放一放吧～`;
  }
}
