// hsp-allergy: 交叉污染检测器
// 检测食品配料中可能与已知过敏原发生交叉反应的风险成分

import { FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { AllergyHint, Severity } from './AllergyEngine';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CrossContaminationDetector';

/** 交叉反应配对数据库 */
interface CrossReactivityPair {
  primaryAllergen: string;
  crossReactive: string;
  riskLevel: Severity;
  mechanism: string;
  prevalencePercent: number;
}

const CROSS_REACTIVITY_DB: Record<string, CrossReactivityPair[]> = {
  '花生': [
    { primaryAllergen: '花生', crossReactive: '大豆', riskLevel: Severity.MODERATE, mechanism: '豆科植物蛋白同源性', prevalencePercent: 5 },
    { primaryAllergen: '花生', crossReactive: '豌豆', riskLevel: Severity.MODERATE, mechanism: '豆科植物蛋白同源性', prevalencePercent: 5 },
    { primaryAllergen: '花生', crossReactive: '扁豆', riskLevel: Severity.LOW, mechanism: '豆科植物蛋白同源性', prevalencePercent: 2 },
  ],
  '牛奶': [
    { primaryAllergen: '牛奶', crossReactive: '山羊奶', riskLevel: Severity.HIGH, mechanism: '酪蛋白同源性>90%', prevalencePercent: 90 },
    { primaryAllergen: '牛奶', crossReactive: '绵羊奶', riskLevel: Severity.HIGH, mechanism: '酪蛋白同源性>90%', prevalencePercent: 90 },
    { primaryAllergen: '牛奶', crossReactive: '牛肉', riskLevel: Severity.LOW, mechanism: '牛血清白蛋白', prevalencePercent: 10 },
  ],
  '鸡蛋': [
    { primaryAllergen: '鸡蛋', crossReactive: '鸭蛋', riskLevel: Severity.MODERATE, mechanism: '卵白蛋白同源性', prevalencePercent: 50 },
    { primaryAllergen: '鸡蛋', crossReactive: '鹅蛋', riskLevel: Severity.MODERATE, mechanism: '卵白蛋白同源性', prevalencePercent: 50 },
  ],
  '小麦': [
    { primaryAllergen: '小麦', crossReactive: '大麦', riskLevel: Severity.HIGH, mechanism: '麸质蛋白同源性', prevalencePercent: 95 },
    { primaryAllergen: '小麦', crossReactive: '黑麦', riskLevel: Severity.HIGH, mechanism: '麸质蛋白同源性', prevalencePercent: 95 },
    { primaryAllergen: '小麦', crossReactive: '燕麦', riskLevel: Severity.LOW, mechanism: '燕麦可能被小麦污染', prevalencePercent: 5 },
  ],
  '鱼': [
    { primaryAllergen: '鱼', crossReactive: '虾', riskLevel: Severity.MODERATE, mechanism: '原肌球蛋白同源性', prevalencePercent: 10 },
    { primaryAllergen: '鱼', crossReactive: '蟹', riskLevel: Severity.MODERATE, mechanism: '原肌球蛋白同源性', prevalencePercent: 10 },
  ],
  '虾': [
    { primaryAllergen: '虾', crossReactive: '蟹', riskLevel: Severity.HIGH, mechanism: '原肌球蛋白高度同源', prevalencePercent: 75 },
    { primaryAllergen: '虾', crossReactive: '龙虾', riskLevel: Severity.HIGH, mechanism: '原肌球蛋白高度同源', prevalencePercent: 75 },
    { primaryAllergen: '虾', crossReactive: '鱿鱼', riskLevel: Severity.MODERATE, mechanism: '原肌球蛋白同源性', prevalencePercent: 30 },
  ],
  '大豆': [
    { primaryAllergen: '大豆', crossReactive: '花生', riskLevel: Severity.MODERATE, mechanism: '豆科植物蛋白同源性', prevalencePercent: 5 },
    { primaryAllergen: '大豆', crossReactive: '豌豆', riskLevel: Severity.LOW, mechanism: '豆科植物蛋白同源性', prevalencePercent: 2 },
  ],
  '坚果': [
    { primaryAllergen: '坚果', crossReactive: '花生', riskLevel: Severity.MODERATE, mechanism: '种子储存蛋白同源性', prevalencePercent: 30 },
    { primaryAllergen: '坚果', crossReactive: '芝麻', riskLevel: Severity.LOW, mechanism: '种子蛋白同源性', prevalencePercent: 10 },
  ],
  '芒果': [
    { primaryAllergen: '芒果', crossReactive: '腰果', riskLevel: Severity.MODERATE, mechanism: '漆树科蛋白同源性', prevalencePercent: 50 },
    { primaryAllergen: '芒果', crossReactive: '开心果', riskLevel: Severity.MODERATE, mechanism: '漆树科蛋白同源性', prevalencePercent: 40 },
  ],
  '芝麻': [
    { primaryAllergen: '芝麻', crossReactive: '坚果', riskLevel: Severity.LOW, mechanism: '种子蛋白同源性', prevalencePercent: 10 },
    { primaryAllergen: '芝麻', crossReactive: '花生', riskLevel: Severity.LOW, mechanism: '种子蛋白同源性', prevalencePercent: 5 },
  ],
};

export class CrossContaminationDetector {
  /**
   * 检测食品配料中与已知过敏原的交叉反应风险
   * @param food 食品标签
   * @param knownAllergens 已知过敏原列表（如 ['花生', '牛奶']）
   * @returns 交叉反应风险提示
   */
  detect(food: FoodLabel, knownAllergens: string[]): AllergyHint[] {
    const hints: AllergyHint[] = [];
    const allIngredients = [...food.ingredients, ...food.allergenHints];

    for (const knownAllergen of knownAllergens) {
      const pairs = CROSS_REACTIVITY_DB[knownAllergen];
      if (!pairs) continue;

      for (const pair of pairs) {
        // 检查配料是否含交叉反应目标
        const matched = allIngredients.filter(i => i.includes(pair.crossReactive));
        for (const ingredient of matched) {
          const hint: AllergyHint = new AllergyHint(
          hint.allergen = pair.crossReactive;
          hint.ingredient = ingredient;
          hint.severity = pair.riskLevel;
          hint.detail = `${knownAllergen}过敏者可能对${pair.crossReactive}交叉反应（${pair.mechanism}，发生率约${pair.prevalencePercent}%）`;
          hint.recommendation = pair.riskLevel === Severity.HIGH
            ? `强烈建议避免含${pair.crossReactive}的食品`
            : `建议谨慎食用`;
          hint.isCrossReactivity = true;
          hints.push(hint);
        }
      }
    }

    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'Cross-contamination detection: %{public}d risks for %{public}s',
      hints.length, food.foodName);
    return hints;
  }

  /** 获取指定过敏原的所有交叉反应配对 */
  getCrossReactivities(allergen: string): CrossReactivityPair[] {
    return CROSS_REACTIVITY_DB[allergen] ?? [];
  }
}
