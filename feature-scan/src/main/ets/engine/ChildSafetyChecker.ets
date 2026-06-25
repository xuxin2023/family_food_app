// ChildSafetyChecker.ets
// 儿童食品安全检测 — 人工色素/甜味剂/高钠/高糖检测 + 年龄营养限额

import { FoodLabel } from 'hsp_core';

export enum ChildAgeGroup {
  TODDLER = '1-3岁',
  PRESCHOOL = '4-6岁',
  SCHOOL = '7-12岁',
  TEEN = '13-17岁'
}

class AgeNutritionLimit {
  ageGroup: ChildAgeGroup = ChildAgeGroup.TODDLER;
  sodiumMaxMg: number = 0;
  sugarMaxG: number = 0;
  calorieMax: number = 0;
  fatMaxG: number = 0;
}

export class ChildSafetyResult {
  isChildFriendly: boolean = true;
  riskLevel: string = '';
  riskColor: string = '';
  warnings: string[] = [];
  ageGroup: ChildAgeGroup = ChildAgeGroup.SCHOOL;
  nutritionExceeded: string[] = [];
  summary: string = '';
}

const ARTIFICIAL_COLORS: string[] = [
  'E102', 'E104', 'E110', 'E120', 'E122', 'E124', 'E129', 'E131', 'E133',
  'E142', 'E151', 'E155', 'E171', 'E172', 'E173',
  '柠檬黄', '日落黄', '胭脂红', '诱惑红', '亮蓝', '靛蓝', '二氧化钛'
];

const ARTIFICIAL_SWEETENERS: string[] = [
  'E950', 'E951', 'E952', 'E954', 'E955',
  '阿斯巴甜', '安赛蜜', '糖精', '三氯蔗糖', '甜蜜素'
];

const PRESERVATIVES_CONCERN: string[] = [
  'E211', 'E220', 'E250', 'E251',
  '苯甲酸钠', '二氧化硫', '亚硝酸钠', '硝酸钠'
];

function buildAgeLimits(): AgeNutritionLimit[] {
  const list: AgeNutritionLimit[] = [];
  const l1: AgeNutritionLimit = new AgeNutritionLimit();
  l1.ageGroup = ChildAgeGroup.TODDLER; l1.sodiumMaxMg = 700; l1.sugarMaxG = 10; l1.calorieMax = 1000; l1.fatMaxG = 30;
  list.push(l1);

  const l2: AgeNutritionLimit = new AgeNutritionLimit();
  l2.ageGroup = ChildAgeGroup.PRESCHOOL; l2.sodiumMaxMg = 900; l2.sugarMaxG = 15; l2.calorieMax = 1400; l2.fatMaxG = 40;
  list.push(l2);

  const l3: AgeNutritionLimit = new AgeNutritionLimit();
  l3.ageGroup = ChildAgeGroup.SCHOOL; l3.sodiumMaxMg = 1200; l3.sugarMaxG = 20; l3.calorieMax = 1800; l3.fatMaxG = 50;
  list.push(l3);

  const l4: AgeNutritionLimit = new AgeNutritionLimit();
  l4.ageGroup = ChildAgeGroup.TEEN; l4.sodiumMaxMg = 1500; l4.sugarMaxG = 25; l4.calorieMax = 2200; l4.fatMaxG = 60;
  list.push(l4);

  return list;
}

const AGE_LIMITS: AgeNutritionLimit[] = buildAgeLimits();

export class ChildSafetyChecker {
  static check(food: FoodLabel, ageGroup: ChildAgeGroup = ChildAgeGroup.SCHOOL): ChildSafetyResult {
    const result: ChildSafetyResult = new ChildSafetyResult();
    result.ageGroup = ageGroup;

    const ingredientText = food.ingredients.join(' ').toUpperCase();
    const nameText = food.foodName.toUpperCase();

    let hasArtificialColor = false;
    let hasArtificialSweetener = false;
    let hasConcernPreservative = false;

    for (let i = 0; i < ARTIFICIAL_COLORS.length; i++) {
      const kw = ARTIFICIAL_COLORS[i].toUpperCase();
      if (ingredientText.includes(kw) || nameText.includes(kw)) {
        hasArtificialColor = true;
        result.warnings.push('含人工色素: ' + ARTIFICIAL_COLORS[i]);
      }
    }

    for (let i = 0; i < ARTIFICIAL_SWEETENERS.length; i++) {
      const kw = ARTIFICIAL_SWEETENERS[i].toUpperCase();
      if (ingredientText.includes(kw) || nameText.includes(kw)) {
        hasArtificialSweetener = true;
        result.warnings.push('含人工甜味剂: ' + ARTIFICIAL_SWEETENERS[i]);
      }
    }

    for (let i = 0; i < PRESERVATIVES_CONCERN.length; i++) {
      const kw = PRESERVATIVES_CONCERN[i].toUpperCase();
      if (ingredientText.includes(kw) || nameText.includes(kw)) {
        hasConcernPreservative = true;
        result.warnings.push('含关注防腐剂: ' + PRESERVATIVES_CONCERN[i]);
      }
    }

    const limit = GbComplianceChecker_getAgeLimit(ageGroup);
    const n = food.nutrition;

    if (n.sodium > limit.sodiumMaxMg) {
      result.nutritionExceeded.push('钠(' + Math.round(n.sodium) + 'mg) 超过' + ageGroup + '限额(' + limit.sodiumMaxMg + 'mg)');
    }
    if (n.sugar > limit.sugarMaxG) {
      result.nutritionExceeded.push('糖(' + n.sugar + 'g) 超过' + ageGroup + '限额(' + limit.sugarMaxG + 'g)');
    }
    if (n.fat > limit.fatMaxG) {
      result.nutritionExceeded.push('脂肪(' + n.fat + 'g) 超过' + ageGroup + '限额(' + limit.fatMaxG + 'g)');
    }

    let riskScore = 0;
    if (hasArtificialColor) riskScore += 30;
    if (hasArtificialSweetener) riskScore += 25;
    if (hasConcernPreservative) riskScore += 20;
    riskScore += result.nutritionExceeded.length * 15;

    if (riskScore >= 50) {
      result.isChildFriendly = false;
      result.riskLevel = '高风险';
      result.riskColor = '#F44336';
      result.summary = '⚠️ 儿童不宜：' + result.warnings.length + '项风险成分';
    } else if (riskScore >= 20) {
      result.riskLevel = '中风险';
      result.riskColor = '#FFA726';
      result.summary = '谨慎食用：' + result.warnings.length + '项关注成分';
    } else {
      result.riskLevel = '低风险';
      result.riskColor = '#4CAF50';
      result.summary = '儿童可食用';
    }

    return result;
  }

  static getAgeLimit(ageGroup: ChildAgeGroup): AgeNutritionLimit {
    for (let i = 0; i < AGE_LIMITS.length; i++) {
      if (AGE_LIMITS[i].ageGroup === ageGroup) {
        return AGE_LIMITS[i];
      }
    }
    return AGE_LIMITS[2];
  }
}

function GbComplianceChecker_getAgeLimit(ageGroup: ChildAgeGroup): AgeNutritionLimit {
  return ChildSafetyChecker.getAgeLimit(ageGroup);
}
