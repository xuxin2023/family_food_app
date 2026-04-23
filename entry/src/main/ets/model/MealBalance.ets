// 美食平衡建议数据模型

// 美食场景枚举
export enum MealScenario {
  BBQ = '烧烤',
  HOTPOT = '火锅',
  FRIED_CHICKEN = '炸鸡',
  MILK_TEA = '奶茶',
  DESSERT = '甜品',
  LUWEI = '卤味',
  INSTANT_NOODLE = '方便面',
  LATE_NIGHT = '夜宵',
  OTHER = '其他'
}

// 风险标签
export enum RiskTag {
  HIGH_SALT = '高盐',
  HIGH_OIL = '高油',
  HIGH_SUGAR = '高糖',
  HIGH_CALORIE = '高热量',
  LOW_VEGGIE = '蔬菜少',
  TOO_MUCH_MEAT = '肉类偏多'
}

// 美食平衡建议
export class MealBalance {
  memberId: string = '';
  scenario: MealScenario = MealScenario.BBQ;
  riskTags: RiskTag[] = [];
  nextMealAdvice: string = '';
  avoidStacking: string[] = [];
  hydrationReminder: boolean = false;
  memberSpecificAdvice: string = '';

  toJson(): Record<string, Object> {
    return {
      memberId: this.memberId,
      scenario: this.scenario,
      riskTags: this.riskTags,
      nextMealAdvice: this.nextMealAdvice,
      avoidStacking: this.avoidStacking,
      hydrationReminder: this.hydrationReminder,
      memberSpecificAdvice: this.memberSpecificAdvice
    };
  }
}
