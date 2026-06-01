import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ExtendedIntoleranceEngine';
const DOMAIN_ZERO = 0x0001;

export enum ExtendedIntoleranceType {
  LACTOSE = 'lactose',
  GLUTEN = 'gluten',
  HISTAMINE = 'histamine',
  FRUCTOSE = 'fructose',
  SUCROSE = 'sucrose',
  OXALATE = 'oxalate',
  SALICYLATE = 'salicylate',
  SULFITE = 'sulfite',
  TAURINE = 'taurine',
  OTHER = 'other'
}

export interface ExtendedIntoleranceCheckResult {
  type: ExtendedIntoleranceType;
  matchedIngredients: string[];
  severity: 'low' | 'medium' | 'high';
  advice: string;
}

const INTOLERANCE_KEYWORDS: Map<ExtendedIntoleranceType, string[]> = new Map([
  [ExtendedIntoleranceType.LACTOSE, ['乳糖', '牛奶', '奶粉', '乳清蛋白', '奶酪', '黄油', '炼乳', '鲜奶油', '脱脂乳']],
  [ExtendedIntoleranceType.GLUTEN, ['小麦', '大麦', '黑麦', '面筋', '麸质', '小麦粉', '面粉', '麦芽', '酱油']],
  [ExtendedIntoleranceType.HISTAMINE, ['发酵食品', '陈年奶酪', '红酒', '啤酒', '香肠', '培根', '金枪鱼', '沙丁鱼', '酸菜', '醋']],
  [ExtendedIntoleranceType.FRUCTOSE, ['果糖', '蜂蜜', '苹果', '梨', '西瓜', '芒果', '高果糖玉米糖浆', '龙舌兰糖浆']],
  [ExtendedIntoleranceType.SUCROSE, ['蔗糖', '白砂糖', '红糖', '冰糖', '枫糖浆', '棕榈糖']],
  [ExtendedIntoleranceType.OXALATE, ['菠菜', '甜菜', '大黄', '杏仁', '花生', '巧克力', '红茶', '欧芹']],
  [ExtendedIntoleranceType.SALICYLATE, ['阿司匹林', '薄荷', '咖喱', '肉桂', '丁香', '番茄', '橘子', '葡萄']],
  [ExtendedIntoleranceType.SULFITE, ['亚硫酸盐', '二氧化硫', '干果', '葡萄酒', '泡菜', '虾', '啤酒', '醋']],
  [ExtendedIntoleranceType.TAURINE, ['牛磺酸', '能量饮料', '功能性饮料']]
]);

export class ExtendedIntoleranceEngine {
  checkIngredients(
    ingredients: string[],
    userIntolerances: ExtendedIntoleranceType[]
  ): ExtendedIntoleranceCheckResult[] {
    const results: ExtendedIntoleranceCheckResult[] = [];
    for (const intoleranceType of userIntolerances) {
      const keywords = INTOLERANCE_KEYWORDS.get(intoleranceType) ?? [];
      const matched: string[] = [];
      for (const ingredient of ingredients) {
        for (const keyword of keywords) {
          if (ingredient.includes(keyword)) {
            matched.push(ingredient);
            break;
          }
        }
      }
      if (matched.length > 0) {
        results.push({
          type: intoleranceType,
          matchedIngredients: matched,
          severity: this.determineSeverity(intoleranceType, matched.length),
          advice: this.generateAdvice(intoleranceType, matched)
        });
      }
    }
    return results;
  }

  private determineSeverity(type: ExtendedIntoleranceType, matchCount: number): 'low' | 'medium' | 'high' {
    if (matchCount >= 3) return 'high';
    if (matchCount >= 2) return 'medium';
    if (type === ExtendedIntoleranceType.HISTAMINE || type === ExtendedIntoleranceType.SULFITE) return 'medium';
    return 'low';
  }

  private generateAdvice(type: ExtendedIntoleranceType, matched: string[]): string {
    const adviceMap: Map<ExtendedIntoleranceType, string> = new Map([
      [ExtendedIntoleranceType.LACTOSE, '建议选择无乳糖或植物基替代品'],
      [ExtendedIntoleranceType.GLUTEN, '建议选择无麸质认证食品'],
      [ExtendedIntoleranceType.HISTAMINE, '建议避免发酵和陈年食品，选择新鲜食材'],
      [ExtendedIntoleranceType.FRUCTOSE, '建议选择低果糖水果如香蕉、蓝莓'],
      [ExtendedIntoleranceType.SUCROSE, '建议选择天然甜味剂如甜菊糖'],
      [ExtendedIntoleranceType.OXALATE, '建议选择低草酸蔬菜如生菜、黄瓜'],
      [ExtendedIntoleranceType.SALICYLATE, '建议选择低水杨酸食品如米饭、牛奶'],
      [ExtendedIntoleranceType.SULFITE, '建议选择无亚硫酸盐添加的食品'],
      [ExtendedIntoleranceType.TAURINE, '建议避免含牛磺酸的功能性饮料']
    ]);
    return adviceMap.get(type) ?? '建议咨询医生获取个性化饮食指导';
  }
}