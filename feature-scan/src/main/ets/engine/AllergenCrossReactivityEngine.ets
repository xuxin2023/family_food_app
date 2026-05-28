import { FamilyProfile, FoodLabel, HILOG_DOMAIN } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AllergenCrossReactivityEngine';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface CrossReactivityPair {
  primaryAllergen: string;
  crossReactiveAllergen: string;
  riskLevel: 'high' | 'moderate' | 'low';
  mechanism: string;
  prevalencePercent: number;
}

export interface AllergenCrossReport {
  memberId: string;
  foodName: string;
  directAllergens: string[];
  crossReactiveRisks: CrossReactiveRisk[];
  overallRisk: 'high' | 'moderate' | 'low' | 'none';
  recommendation: string;
}

export interface CrossReactiveRisk {
  allergen: string;
  triggeredBy: string;
  pair: CrossReactivityPair;
}

const CROSS_REACTIVITY_MAP: Record<string, CrossReactivityPair[]> = {
  '花生': [
    { primaryAllergen: '花生', crossReactiveAllergen: '大豆', riskLevel: 'moderate', mechanism: '豆科植物蛋白同源性', prevalencePercent: 5 },
    { primaryAllergen: '花生', crossReactiveAllergen: '豌豆', riskLevel: 'moderate', mechanism: '豆科植物蛋白同源性', prevalencePercent: 5 },
    { primaryAllergen: '花生', crossReactiveAllergen: '扁豆', riskLevel: 'low', mechanism: '豆科植物蛋白同源性', prevalencePercent: 2 },
  ],
  '牛奶': [
    { primaryAllergen: '牛奶', crossReactiveAllergen: '山羊奶', riskLevel: 'high', mechanism: '酪蛋白同源性>90%', prevalencePercent: 90 },
    { primaryAllergen: '牛奶', crossReactiveAllergen: '绵羊奶', riskLevel: 'high', mechanism: '酪蛋白同源性>90%', prevalencePercent: 90 },
    { primaryAllergen: '牛奶', crossReactiveAllergen: '牛肉', riskLevel: 'low', mechanism: '牛血清白蛋白', prevalencePercent: 10 },
  ],
  '鸡蛋': [
    { primaryAllergen: '鸡蛋', crossReactiveAllergen: '鸭蛋', riskLevel: 'moderate', mechanism: '卵白蛋白同源性', prevalencePercent: 50 },
    { primaryAllergen: '鸡蛋', crossReactiveAllergen: '鹅蛋', riskLevel: 'moderate', mechanism: '卵白蛋白同源性', prevalencePercent: 50 },
  ],
  '小麦': [
    { primaryAllergen: '小麦', crossReactiveAllergen: '大麦', riskLevel: 'high', mechanism: '麸质蛋白同源性', prevalencePercent: 95 },
    { primaryAllergen: '小麦', crossReactiveAllergen: '黑麦', riskLevel: 'high', mechanism: '麸质蛋白同源性', prevalencePercent: 95 },
    { primaryAllergen: '小麦', crossReactiveAllergen: '燕麦', riskLevel: 'low', mechanism: '燕麦可能被小麦污染', prevalencePercent: 5 },
  ],
  '鱼': [
    { primaryAllergen: '鱼', crossReactiveAllergen: '虾', riskLevel: 'moderate', mechanism: '原肌球蛋白同源性', prevalencePercent: 10 },
    { primaryAllergen: '鱼', crossReactiveAllergen: '蟹', riskLevel: 'moderate', mechanism: '原肌球蛋白同源性', prevalencePercent: 10 },
  ],
  '虾': [
    { primaryAllergen: '虾', crossReactiveAllergen: '蟹', riskLevel: 'high', mechanism: '原肌球蛋白高度同源', prevalencePercent: 75 },
    { primaryAllergen: '虾', crossReactiveAllergen: '龙虾', riskLevel: 'high', mechanism: '原肌球蛋白高度同源', prevalencePercent: 75 },
    { primaryAllergen: '虾', crossReactiveAllergen: '鱿鱼', riskLevel: 'moderate', mechanism: '原肌球蛋白同源性', prevalencePercent: 30 },
  ],
  '大豆': [
    { primaryAllergen: '大豆', crossReactiveAllergen: '花生', riskLevel: 'moderate', mechanism: '豆科植物蛋白同源性', prevalencePercent: 5 },
    { primaryAllergen: '大豆', crossReactiveAllergen: '豌豆', riskLevel: 'low', mechanism: '豆科植物蛋白同源性', prevalencePercent: 2 },
  ],
  '坚果': [
    { primaryAllergen: '坚果', crossReactiveAllergen: '花生', riskLevel: 'moderate', mechanism: '种子储存蛋白同源性', prevalencePercent: 30 },
    { primaryAllergen: '坚果', crossReactiveAllergen: '芝麻', riskLevel: 'low', mechanism: '种子蛋白同源性', prevalencePercent: 10 },
  ],
  '芒果': [
    { primaryAllergen: '芒果', crossReactiveAllergen: '腰果', riskLevel: 'moderate', mechanism: '漆树科蛋白同源性', prevalencePercent: 50 },
    { primaryAllergen: '芒果', crossReactiveAllergen: '开心果', riskLevel: 'moderate', mechanism: '漆树科蛋白同源性', prevalencePercent: 40 },
  ],
  '芝麻': [
    { primaryAllergen: '芝麻', crossReactiveAllergen: '坚果', riskLevel: 'low', mechanism: '种子蛋白同源性', prevalencePercent: 10 },
    { primaryAllergen: '芝麻', crossReactiveAllergen: '花生', riskLevel: 'low', mechanism: '种子蛋白同源性', prevalencePercent: 5 },
  ],
};

export class AllergenCrossReactivityEngine {
  analyzeFood(foodLabel: FoodLabel, profile: FamilyProfile): AllergenCrossReport {
    const directAllergens: string[] = [];
    for (const a of profile.allergens) {
      if (foodLabel.allergens.includes(a) || foodLabel.ingredients.includes(a)) {
        directAllergens.push(a);
      }
    }

    const crossReactiveRisks: CrossReactiveRisk[] = [];
    for (const userAllergen of profile.allergens) {
      const pairs = CROSS_REACTIVITY_MAP[userAllergen];
      if (!pairs) continue;
      for (const pair of pairs) {
        if (foodLabel.ingredients.includes(pair.crossReactiveAllergen) ||
            foodLabel.allergens.includes(pair.crossReactiveAllergen)) {
          crossReactiveRisks.push({
            allergen: pair.crossReactiveAllergen,
            triggeredBy: userAllergen,
            pair
          });
        }
      }
    }

    const uniqueCross = new Map<string, CrossReactiveRisk>();
    for (const risk of crossReactiveRisks) {
      if (!uniqueCross.has(risk.allergen) || risk.pair.riskLevel === 'high') {
        uniqueCross.set(risk.allergen, risk);
      }
    }
    const dedupedRisks = Array.from(uniqueCross.values());

    let overallRisk: 'high' | 'moderate' | 'low' | 'none' = 'none';
    if (directAllergens.length > 0) {
      overallRisk = 'high';
    } else if (dedupedRisks.some(r => r.pair.riskLevel === 'high')) {
      overallRisk = 'high';
    } else if (dedupedRisks.some(r => r.pair.riskLevel === 'moderate')) {
      overallRisk = 'moderate';
    } else if (dedupedRisks.length > 0) {
      overallRisk = 'low';
    }

    let recommendation = '';
    if (overallRisk === 'high') {
      recommendation = directAllergens.length > 0
        ? `含直接过敏原(${directAllergens.join('、')})，强烈建议避免食用`
        : '存在高风险交叉反应性过敏原，建议避免食用';
    } else if (overallRisk === 'moderate') {
      recommendation = '存在中等风险交叉反应性，对敏感人群建议谨慎食用';
    } else if (overallRisk === 'low') {
      recommendation = '存在低风险交叉反应性，大多数人可安全食用';
    } else {
      recommendation = '未检测到过敏风险';
    }

    return {
      memberId: profile.memberId,
      foodName: foodLabel.foodName,
      directAllergens,
      crossReactiveRisks: dedupedRisks,
      overallRisk,
      recommendation
    };
  }

  getCrossReactivities(allergen: string): CrossReactivityPair[] {
    return CROSS_REACTIVITY_MAP[allergen] ?? [];
  }
}
