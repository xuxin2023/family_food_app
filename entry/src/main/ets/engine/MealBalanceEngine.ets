// 餐次平衡引擎 - 美食平衡建议

import { FamilyProfile, HealthGoal } from '../model/FamilyProfile';
import { HealthSignal } from '../model/HealthSignal';
import { MealBalance, MealScenario, RiskTag } from '../model/MealBalance';

// 场景模板
interface MealTemplate {
  scenario: string;
  riskTags: string[];
  nextMealAdvice: string;
  avoidStacking: string[];
  hydrationReminder: boolean;
  goalAdvice: Record<string, string>;
}

// 内置场景模板
const MEAL_TEMPLATES: MealTemplate[] = [
  {
    scenario: '烧烤',
    riskTags: ['高盐', '高油', '肉类偏多', '蔬菜少'],
    nextMealAdvice: '清淡少油，多选深色蔬菜，主食适量，蛋白质优先选择蒸煮类鱼、蛋、豆制品或瘦肉',
    avoidStacking: ['火锅', '卤味', '方便面', '奶茶', '甜品'],
    hydrationReminder: true,
    goalAdvice: {
      '控压': '下一餐少放盐、酱油、蚝油、鸡精，避免汤面、火锅、咸菜、加工肉和重口味夜宵',
      '控糖': '注意调味料中隐藏糖分，避免甜酱和含糖蘸料',
      '减脂': '下一餐减少油脂摄入，选择清蒸或水煮烹饪方式',
      '控脂': '下一餐严格控制脂肪摄入，避免油炸和红烧'
    }
  },
  {
    scenario: '火锅',
    riskTags: ['高盐', '高油', '蔬菜可能不足'],
    nextMealAdvice: '清淡少盐，增加蔬菜和水分，主食适量',
    avoidStacking: ['烧烤', '卤味', '方便面', '重口味'],
    hydrationReminder: true,
    goalAdvice: {
      '控压': '火锅汤底通常高钠，下一餐务必清淡，避免再摄入高盐食品',
      '控糖': '注意火锅蘸料中的糖分，下一餐减少甜食',
      '减脂': '火锅油脂含量高，下一餐选择清淡饮食'
    }
  },
  {
    scenario: '炸鸡',
    riskTags: ['高油', '高热量'],
    nextMealAdvice: '清淡少油，增加蔬菜，选择蒸煮类蛋白质',
    avoidStacking: ['油炸食品', '奶茶', '甜品'],
    hydrationReminder: true,
    goalAdvice: {
      '控压': '油炸食品钠含量也不低，下一餐注意控盐',
      '减脂': '炸鸡热量和脂肪都很高，下一餐严格控制热量和脂肪',
      '控脂': '下一餐避免任何高脂食品'
    }
  },
  {
    scenario: '奶茶',
    riskTags: ['高糖', '高热量'],
    nextMealAdvice: '减少今日糖摄入，下一餐少甜，多喝水',
    avoidStacking: ['甜品', '含糖饮料', '蛋糕'],
    hydrationReminder: true,
    goalAdvice: {
      '控糖': '奶茶含糖量通常很高，今日不建议再摄入任何含糖食品',
      '减脂': '奶茶热量较高，下一餐减少主食量'
    }
  },
  {
    scenario: '甜品',
    riskTags: ['高糖', '高热量', '高脂肪'],
    nextMealAdvice: '下一餐减少主食和甜食，增加蔬菜和优质蛋白',
    avoidStacking: ['奶茶', '含糖饮料', '蛋糕', '饼干'],
    hydrationReminder: false,
    goalAdvice: {
      '控糖': '甜品糖分很高，今日不建议再摄入任何含糖食品',
      '减脂': '甜品热量和脂肪都高，下一餐严格控制',
      '控脂': '甜品通常含大量脂肪，下一餐避免高脂食品'
    }
  },
  {
    scenario: '卤味',
    riskTags: ['高盐', '加工肉'],
    nextMealAdvice: '下一餐少盐少加工肉，增加新鲜蔬菜和水分',
    avoidStacking: ['火锅', '方便面', '咸菜', '加工肉'],
    hydrationReminder: true,
    goalAdvice: {
      '控压': '卤味钠含量很高，下一餐务必清淡，少放盐、酱油、蚝油、鸡精，避免汤面、火锅、咸菜、加工肉和重口味夜宵',
      '控糖': '卤味调味料可能含糖，注意今日糖摄入总量'
    }
  },
  {
    scenario: '方便面',
    riskTags: ['高盐', '高油', '营养单一'],
    nextMealAdvice: '下一餐营养均衡，增加蛋白质和蔬菜，补充水分',
    avoidStacking: ['火锅', '卤味', '加工肉'],
    hydrationReminder: true,
    goalAdvice: {
      '控压': '方便面钠含量极高，下一餐务必清淡',
      '减脂': '方便面热量和脂肪较高，下一餐控制热量'
    }
  },
  {
    scenario: '夜宵',
    riskTags: ['高热量', '影响睡眠'],
    nextMealAdvice: '早餐适量，避免连续夜宵，白天注意营养均衡',
    avoidStacking: ['夜宵', '含咖啡因饮品'],
    hydrationReminder: false,
    goalAdvice: {
      '控压': '夜宵通常高盐高油，对血压控制不利，建议尽量避免',
      '减脂': '夜宵热量容易囤积，建议尽量避免',
      '控糖': '夜宵可能影响次日血糖，建议尽量避免'
    }
  }
];

export class MealBalanceEngine {
  // 计算美食平衡建议
  calculate(scenario: MealScenario, profile: FamilyProfile, healthSignal: HealthSignal): MealBalance {
    const result = new MealBalance();
    result.memberId = profile.memberId;
    result.scenario = scenario;

    // 查找匹配模板
    const template = MEAL_TEMPLATES.find(t => t.scenario === scenario);
    if (!template) {
      // 无匹配模板，返回默认建议
      result.riskTags = [RiskTag.HIGH_CALORIE];
      result.nextMealAdvice = '下一餐建议清淡均衡，增加蔬菜和水分';
      result.avoidStacking = [];
      result.hydrationReminder = false;
      return result;
    }

    // 填充模板数据
    result.riskTags = template.riskTags.map(tag => tag as RiskTag);
    result.nextMealAdvice = template.nextMealAdvice;
    result.avoidStacking = template.avoidStacking;
    result.hydrationReminder = template.hydrationReminder;

    // 结合成员健康目标生成特定建议
    const goalAdvices: string[] = [];
    for (const goal of profile.healthGoals) {
      const goalName = goal as string;
      if (template.goalAdvice[goalName]) {
        goalAdvices.push(template.goalAdvice[goalName]);
      }
    }

    // 动态修正：活动量低时更严格
    if (healthSignal.isLowActivity()) {
      goalAdvices.push('今日活动量偏低，建议下一餐更加清淡');
    }

    // 动态修正：睡眠差时提醒
    if (healthSignal.isPoorSleep()) {
      goalAdvices.push('睡眠较差，不建议再摄入含咖啡因饮品或高糖食品');
    }

    result.memberSpecificAdvice = goalAdvices.join('。');

    return result;
  }

  // 获取所有可用场景
  getAvailableScenarios(): MealScenario[] {
    return [
      MealScenario.BBQ,
      MealScenario.HOTPOT,
      MealScenario.FRIED_CHICKEN,
      MealScenario.MILK_TEA,
      MealScenario.DESSERT,
      MealScenario.LUWEI,
      MealScenario.INSTANT_NOODLE,
      MealScenario.LATE_NIGHT
    ];
  }
}
