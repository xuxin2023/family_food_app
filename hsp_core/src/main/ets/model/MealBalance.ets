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
  MALATANG = '麻辣烫',
  BBQ_MEAT = '烤肉',
  SUSHI = '日料',
  BUFFET = '自助餐',
  AFTERNOON_TEA = '下午茶',
  LUOSIFEN = '螺蛳粉',
  MAOCAI = '冒菜',
  MALAXIANG_GUO = '麻辣香锅',
  LIGHT_SALAD = '轻食沙拉',
  PIZZA = '披萨',
  HAMBURGER = '汉堡',
  DUMPLINGS = '饺子包子',
  FRIED_RICE = '炒饭盖饭',
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

// MealBalance JSON 输出类
export class MealBalanceJson {
  memberId: string = '';
  scenario: string = MealScenario.BBQ;
  riskTags: string[] = [];
  nextMealAdvice: string = '';
  avoidStacking: string[] = [];
  hydrationReminder: boolean = false;
  memberSpecificAdvice: string = '';
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

  toJson(): MealBalanceJson {
    const json: MealBalanceJson = new MealBalanceJson(
    json.memberId = this.memberId;
    json.scenario = this.scenario;
    json.riskTags = this.riskTags;
    json.nextMealAdvice = this.nextMealAdvice;
    json.avoidStacking = this.avoidStacking;
    json.hydrationReminder = this.hydrationReminder;
    json.memberSpecificAdvice = this.memberSpecificAdvice;
    return json;
  }

  static getDefault(): MealBalance {
    const mb: MealBalance = new MealBalance(
    mb.scenario = MealScenario.OTHER;
    mb.riskTags = [];
    mb.nextMealAdvice = '';
    mb.avoidStacking = [];
    mb.hydrationReminder = false;
    mb.memberSpecificAdvice = '';
    return mb;
  }
}
