// GbComplianceChecker.ets
// GB标准合规检测 — 根据食品类别匹配适用GB标准，检查营养成分是否在标准范围内

import { FoodLabel } from 'hsp_core';

export class GbStandard {
  standardCode: string = '';
  standardName: string = '';
  category: string = '';
  sodiumMaxMg: number = 0;
  sugarMaxG: number = 0;
  fatMaxG: number = 0;
  proteinMinG: number = 0;
  description: string = '';
}

export class GbComplianceResult {
  isCompliant: boolean = true;
  matchedStandard: GbStandard | null = null;
  violations: string[] = [];
  warnings: string[] = [];
  summary: string = '';
}

function buildGbStandards(): GbStandard[] {
  const list: GbStandard[] = [];
  const data: string[] = [
    'GB 19301|巴氏杀菌乳|乳制品|0|0|0|28|生乳',
    'GB 25190|灭菌乳|乳制品|0|0|0|28|灭菌乳',
    'GB 25191|调制乳|乳制品|0|0|0|23|调制乳',
    'GB 19302|发酵乳|乳制品|0|0|0|27|发酵乳',
    'GB 10765|婴儿配方食品|婴幼儿|300|0|0|10|0-6月婴儿配方',
    'GB 10767|较大婴儿和幼儿配方食品|婴幼儿|400|0|0|10|6-36月幼儿配方',
    'GB 10769|婴幼儿谷类辅助食品|婴幼儿|0|0|0|5|婴幼儿谷类',
    'GB 13102|浓缩乳制品|乳制品|0|0|0|16|浓缩乳',
    'GB 19644|乳粉|乳制品|0|0|0|16|乳粉',
    'GB 7101|饮料|饮料|0|0|0|0|饮料通则',
    'GB 17399|糖果|糖果|0|0|0|0|糖果通则',
    'GB 7099|糕点|糕点|0|0|0|0|糕点通则',
    'GB 2730|肉制品|肉制品|0|0|0|0|肉制品卫生标准',
    'GB 17400|方便面|方便食品|0|0|0|0|方便面',
    'GB 19640|麦片|方便食品|0|0|0|0|麦片',
    'GB 7100|饼干|饼干|0|0|0|0|饼干',
    'GB 7098|罐头|罐头|0|0|0|0|罐头通则',
    'GB 19295|速冻面米食品|速冻食品|0|0|0|0|速冻面米',
    'GB 14881|食品生产通用卫生规范|通用|0|0|0|0|通用规范'
  ];
  for (let i = 0; i < data.length; i++) {
    const parts = data[i].split('|');
    const s: GbStandard = new GbStandard();
    s.standardCode = parts[0];
    s.standardName = parts[1];
    s.category = parts[2];
    s.sodiumMaxMg = parseInt(parts[3]);
    s.sugarMaxG = parseInt(parts[4]);
    s.fatMaxG = parseInt(parts[5]);
    s.proteinMinG = parseInt(parts[6]);
    s.description = parts[7];
    list.push(s);
  }
  return list;
}

const GB_STANDARDS: GbStandard[] = buildGbStandards();

const CATEGORY_KEYWORDS: string[][] = [
  ['乳制品', '牛奶|酸奶|乳|奶酪|奶'],
  ['婴幼儿', '婴儿|幼儿|配方|辅食'],
  ['饮料', '饮料|果汁|茶饮|汽水|可乐'],
  ['糖果', '糖果|巧克力|软糖|硬糖'],
  ['糕点', '糕点|蛋糕|面包|饼干|月饼'],
  ['肉制品', '火腿|培根|香肠|肉松|午餐肉'],
  ['方便食品', '方便面|泡面|速食|自热'],
  ['罐头', '罐头|罐装'],
  ['速冻食品', '速冻|水饺|汤圆']
];

export class GbComplianceChecker {
  static check(food: FoodLabel): GbComplianceResult {
    const result: GbComplianceResult = new GbComplianceResult();
    const matched = GbComplianceChecker.matchStandard(food.foodName);
    result.matchedStandard = matched;

    if (matched === null) {
      result.summary = '未匹配到具体GB标准，建议参考GB 14881通用规范';
      return result;
    }

    const n = food.nutrition;

    if (matched.sodiumMaxMg > 0 && n.sodium > matched.sodiumMaxMg) {
      result.isCompliant = false;
      result.violations.push('钠含量' + Math.round(n.sodium) + 'mg超标（' + matched.standardCode + '限值' + matched.sodiumMaxMg + 'mg）');
    }

    if (matched.sugarMaxG > 0 && n.sugar > matched.sugarMaxG) {
      result.isCompliant = false;
      result.violations.push('糖含量' + n.sugar + 'g超标（' + matched.standardCode + '限值' + matched.sugarMaxG + 'g）');
    }

    if (matched.fatMaxG > 0 && n.fat > matched.fatMaxG) {
      result.isCompliant = false;
      result.violations.push('脂肪含量' + n.fat + 'g超标（' + matched.standardCode + '限值' + matched.fatMaxG + 'g）');
    }

    if (matched.proteinMinG > 0 && n.protein < matched.proteinMinG) {
      result.isCompliant = false;
      result.violations.push('蛋白质含量' + n.protein + 'g低于标准（' + matched.standardCode + '最低' + matched.proteinMinG + 'g）');
    }

    if (n.sodium > 600) {
      result.warnings.push('钠含量较高，建议关注');
    }
    if (n.sugar > 15) {
      result.warnings.push('糖含量较高，建议关注');
    }

    if (result.isCompliant) {
      result.summary = '符合' + matched.standardCode + ' ' + matched.standardName + '标准要求';
    } else {
      result.summary = '检出' + result.violations.length + '项不符合' + matched.standardCode + '标准';
    }

    return result;
  }

  private static matchStandard(foodName: string): GbStandard | null {
    for (let i = 0; i < CATEGORY_KEYWORDS.length; i++) {
      const category = CATEGORY_KEYWORDS[i][0];
      const keywords = CATEGORY_KEYWORDS[i][1].split('|');
      for (let j = 0; j < keywords.length; j++) {
        if (foodName.includes(keywords[j])) {
          for (let k = 0; k < GB_STANDARDS.length; k++) {
            if (GB_STANDARDS[k].category === category) {
              return GB_STANDARDS[k];
            }
          }
        }
      }
    }
    return null;
  }
}
