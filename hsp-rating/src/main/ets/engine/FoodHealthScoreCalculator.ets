// FoodHealthScoreCalculator.ets
// Yuka 风格综合健康评分 = 营养质量60% + 添加剂风险30% + 有机认证10%
// 同时整合 NOVA 加工度扣分

import { FoodLabel } from 'hsp_core';
import { NutriScoreV2Engine, NutriScoreV2Input, NutriScoreV2Breakdown, FoodCategory } from './NutriScoreV2Engine';
import { AdditiveScoreCalculator, AdditiveScoreResult } from './AdditiveScoreCalculator';

class GradeInfo {
  grade: string = '';
  color: string = '';
  label: string = '';
}

export class FoodHealthScoreBreakdown {
  totalScore: number = 0;
  grade: string = '';
  colorHex: string = '';
  label: string = '';

  nutriScore: number = 0;
  nutriGrade: string = '';
  additiveScore: number = 0;
  organicScore: number = 0;
  novaPenalty: number = 0;

  nutriWeight: number = 0.6;
  additiveWeight: number = 0.3;
  organicWeight: number = 0.1;

  nutriBreakdown: NutriScoreV2Breakdown = new NutriScoreV2Breakdown();
  additiveResult: AdditiveScoreResult = new AdditiveScoreResult();
  isOrganic: boolean = false;
  category: FoodCategory = FoodCategory.SOLID;
}

const ORGANIC_KEYWORDS: string[] = [
  '有机', 'organic', '中国有机', '绿色食品', 'AGI', '生态', '无公害',
  '有机认证', '中国绿色食品', 'certified organic', 'bio', 'ecocert'
];

export class FoodHealthScoreCalculator {
  static calculate(food: FoodLabel): FoodHealthScoreBreakdown {
    const result: FoodHealthScoreBreakdown = new FoodHealthScoreBreakdown();

    const category = NutriScoreV2Engine.detectCategory(food.foodName);
    result.category = category;

    const nutriInput = NutriScoreV2Input.fromNutrition(food.nutrition, category);
    const nutriBreakdown = NutriScoreV2Engine.calculate(nutriInput);
    result.nutriBreakdown = nutriBreakdown;
    result.nutriScore = nutriBreakdown.totalScore;
    result.nutriGrade = nutriBreakdown.grade;

    const additiveResult = AdditiveScoreCalculator.calculateFromIngredients(food.ingredients);
    result.additiveResult = additiveResult;
    result.additiveScore = additiveResult.score;

    const isOrganic = FoodHealthScoreCalculator.detectOrganic(food);
    result.isOrganic = isOrganic;
    result.organicScore = isOrganic ? 100 : 0;

    result.novaPenalty = FoodHealthScoreCalculator.calcNovaPenalty(food.novaGroup);

    let total = result.nutriScore * result.nutriWeight
      + result.additiveScore * result.additiveWeight
      + result.organicScore * result.organicWeight;

    total -= result.novaPenalty;
    total = Math.max(0, Math.min(100, Math.round(total)));
    result.totalScore = total;

    const gradeInfo = FoodHealthScoreCalculator.scoreToGrade(total);
    result.grade = gradeInfo.grade;
    result.colorHex = gradeInfo.color;
    result.label = gradeInfo.label;

    return result;
  }

  static detectOrganic(food: FoodLabel): boolean {
    const searchText = (food.foodName + ' ' + food.manufacturer + ' ' + food.ingredients.join(' ')).toLowerCase();
    for (let i = 0; i < ORGANIC_KEYWORDS.length; i++) {
      if (searchText.includes(ORGANIC_KEYWORDS[i].toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  private static calcNovaPenalty(novaGroup: number): number {
    if (novaGroup === 4) return 10;
    if (novaGroup === 3) return 5;
    if (novaGroup === 2) return 0;
    if (novaGroup === 1) return 0;
    return 0;
  }

  private static scoreToGrade(score: number): GradeInfo {
    const info: GradeInfo = new GradeInfo();
    if (score >= 80) { info.grade = 'A'; info.color = '#4CAF50'; info.label = '优秀'; return info; }
    if (score >= 60) { info.grade = 'B'; info.color = '#66BB6A'; info.label = '良好'; return info; }
    if (score >= 40) { info.grade = 'C'; info.color = '#FFA726'; info.label = '一般'; return info; }
    if (score >= 20) { info.grade = 'D'; info.color = '#FF7043'; info.label = '较差'; return info; }
    info.grade = 'E'; info.color = '#F44336'; info.label = '避免';
    return info;
  }
}
