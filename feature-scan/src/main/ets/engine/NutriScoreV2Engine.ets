// NutriScoreV2Engine.ets
// Yuka 级 Nutri-Score v2 引擎 — 官方非线性阈值表
// 区分固体食物/饮料/脂肪 三套阈值
// 新增水果蔬菜坚果含量评分维度

import { NutritionPer100g } from 'hsp_core';

export enum FoodCategory {
  SOLID = 'solid',
  BEVERAGE = 'beverage',
  FAT_OIL = 'fat_oil',
  CHEESE = 'cheese'
}

export class NutriScoreV2Input {
  energyKJ: number = 0;
  sugarG: number = 0;
  sodiumMg: number = 0;
  saturatedFatG: number = 0;
  proteinG: number = 0;
  fiberG: number = 0;
  fruitVegPercent: number = 0;
  category: FoodCategory = FoodCategory.SOLID;

  static fromNutrition(n: NutritionPer100g, category: FoodCategory = FoodCategory.SOLID): NutriScoreV2Input {
    const input: NutriScoreV2Input = new NutriScoreV2Input();
    input.energyKJ = Math.round(n.calories * 4.184);
    input.sugarG = n.sugar;
    input.sodiumMg = n.sodium;
    input.saturatedFatG = n.saturatedFat;
    input.proteinG = n.protein;
    input.fiberG = n.fiber;
    input.fruitVegPercent = n.fruitVegNutPercent;
    input.category = category;
    return input;
  }
}

export class NutriScoreV2Breakdown {
  totalScore: number = 0;
  grade: string = '';
  colorHex: string = '';
  negativePoints: number = 0;
  positivePoints: number = 0;
  fruitVegPoints: number = 0;
  category: FoodCategory = FoodCategory.SOLID;
}

interface ThresholdRow {
  points: number;
  value: number;
}

const SOLID_ENERGY: ThresholdRow[] = [
  { points: 0, value: 335 }, { points: 1, value: 670 }, { points: 2, value: 1005 },
  { points: 3, value: 1340 }, { points: 4, value: 1675 }, { points: 5, value: 2010 },
  { points: 6, value: 2345 }, { points: 7, value: 2680 }, { points: 8, value: 3015 },
  { points: 9, value: 3350 }, { points: 10, value: Infinity }
];
const BEVERAGE_ENERGY: ThresholdRow[] = [
  { points: 0, value: 0 }, { points: 1, value: 30 }, { points: 2, value: 60 },
  { points: 3, value: 90 }, { points: 4, value: 120 }, { points: 5, value: 150 },
  { points: 6, value: 180 }, { points: 7, value: 210 }, { points: 8, value: 240 },
  { points: 9, value: 270 }, { points: 10, value: Infinity }
];
const SOLID_SUGAR: ThresholdRow[] = [
  { points: 0, value: 4.5 }, { points: 1, value: 9 }, { points: 2, value: 13.5 },
  { points: 3, value: 18 }, { points: 4, value: 22.5 }, { points: 5, value: 27 },
  { points: 6, value: 31.5 }, { points: 7, value: 36 }, { points: 8, value: 40.5 },
  { points: 9, value: 45 }, { points: 10, value: Infinity }
];
const BEVERAGE_SUGAR: ThresholdRow[] = [
  { points: 0, value: 0 }, { points: 1, value: 1.5 }, { points: 2, value: 3 },
  { points: 3, value: 4.5 }, { points: 4, value: 6 }, { points: 5, value: 7.5 },
  { points: 6, value: 9 }, { points: 7, value: 10.5 }, { points: 8, value: 12 },
  { points: 9, value: 13.5 }, { points: 10, value: Infinity }
];
const SODIUM: ThresholdRow[] = [
  { points: 0, value: 90 }, { points: 1, value: 180 }, { points: 2, value: 270 },
  { points: 3, value: 360 }, { points: 4, value: 450 }, { points: 5, value: 540 },
  { points: 6, value: 630 }, { points: 7, value: 720 }, { points: 8, value: 810 },
  { points: 9, value: 900 }, { points: 10, value: Infinity }
];
const SAT_FAT_SOLID: ThresholdRow[] = [
  { points: 0, value: 1 }, { points: 1, value: 2 }, { points: 2, value: 3 },
  { points: 3, value: 4 }, { points: 4, value: 5 }, { points: 5, value: 6 },
  { points: 6, value: 7 }, { points: 7, value: 8 }, { points: 8, value: 9 },
  { points: 9, value: 10 }, { points: 10, value: Infinity }
];
const SAT_FAT_FAT: ThresholdRow[] = [
  { points: 0, value: 10 }, { points: 1, value: 16 }, { points: 2, value: 22 },
  { points: 3, value: 28 }, { points: 4, value: 34 }, { points: 5, value: 40 },
  { points: 6, value: 46 }, { points: 7, value: 52 }, { points: 8, value: 58 },
  { points: 9, value: 64 }, { points: 10, value: Infinity }
];
const PROTEIN: ThresholdRow[] = [
  { points: 0, value: 1.6 }, { points: 1, value: 3.2 }, { points: 2, value: 4.8 },
  { points: 3, value: 6.4 }, { points: 4, value: 8.0 }, { points: 5, value: 10 }
];
const FIBER: ThresholdRow[] = [
  { points: 0, value: 0.9 }, { points: 1, value: 1.9 }, { points: 2, value: 2.8 },
  { points: 3, value: 3.7 }, { points: 4, value: 4.7 }, { points: 5, value: 7 }
];
const FRUIT_VEG: ThresholdRow[] = [
  { points: 0, value: 40 }, { points: 1, value: 60 }, { points: 2, value: 80 },
  { points: 5, value: 100 }
];
const FRUIT_VEG_BEVERAGE: ThresholdRow[] = [
  { points: 0, value: 40 }, { points: 2, value: 60 }, { points: 4, value: 80 },
  { points: 5, value: 100 }
];

function lookupPoints(table: ThresholdRow[], value: number): number {
  for (let i = 0; i < table.length; i++) {
    if (value <= table[i].value) {
      return table[i].points;
    }
  }
  return table[table.length - 1].points;
}

export class NutriScoreV2Engine {
  static calculate(input: NutriScoreV2Input): NutriScoreV2Breakdown {
    const isBeverage = input.category === FoodCategory.BEVERAGE;

    const energyTable = isBeverage ? BEVERAGE_ENERGY : SOLID_ENERGY;
    const sugarTable = isBeverage ? BEVERAGE_SUGAR : SOLID_SUGAR;
    const satFatTable = input.category === FoodCategory.FAT_OIL ? SAT_FAT_FAT :
      (input.category === FoodCategory.CHEESE ? SAT_FAT_FAT : SAT_FAT_SOLID);
    const fruitVegTable = isBeverage ? FRUIT_VEG_BEVERAGE : FRUIT_VEG;

    const energyPoints = lookupPoints(energyTable, input.energyKJ);
    const sugarPoints = lookupPoints(sugarTable, input.sugarG);
    const sodiumPoints = lookupPoints(SODIUM, input.sodiumMg);
    const satFatPoints = lookupPoints(satFatTable, input.saturatedFatG);

    const negativePoints = energyPoints + sugarPoints + sodiumPoints + satFatPoints;

    const proteinPoints = lookupPoints(PROTEIN, input.proteinG);
    const fiberPoints = lookupPoints(FIBER, input.fiberG);
    const fruitVegPoints = lookupPoints(fruitVegTable, input.fruitVegPercent);

    const positivePoints = proteinPoints + fiberPoints + fruitVegPoints;

    let finalScore: number;
    if (negativePoints < 11) {
      finalScore = negativePoints - positivePoints;
    } else {
      if (fruitVegPoints === 5) {
        finalScore = negativePoints - positivePoints;
      } else {
        finalScore = negativePoints - (fiberPoints + fruitVegPoints);
        if (finalScore < 11) {
          finalScore = negativePoints - positivePoints;
        }
      }
    }

    finalScore = Math.max(-15, Math.min(40, finalScore));

    let grade: string;
    let colorHex: string;
    if (isBeverage) {
      if (finalScore <= -1) { grade = 'A'; colorHex = '#4CAF50'; }
      else if (finalScore <= 2) { grade = 'B'; colorHex = '#66BB6A'; }
      else if (finalScore <= 6) { grade = 'C'; colorHex = '#FFA726'; }
      else if (finalScore <= 9) { grade = 'D'; colorHex = '#FF7043'; }
      else { grade = 'E'; colorHex = '#F44336'; }
    } else {
      if (finalScore <= -1) { grade = 'A'; colorHex = '#4CAF50'; }
      else if (finalScore <= 2) { grade = 'B'; colorHex = '#66BB6A'; }
      else if (finalScore <= 10) { grade = 'C'; colorHex = '#FFA726'; }
      else if (finalScore <= 18) { grade = 'D'; colorHex = '#FF7043'; }
      else { grade = 'E'; colorHex = '#F44336'; }
    }

    const percentageScore = NutriScoreV2Engine.scoreToPercentage(finalScore, isBeverage);

    const breakdown: NutriScoreV2Breakdown = new NutriScoreV2Breakdown();
    breakdown.totalScore = percentageScore;
    breakdown.grade = grade;
    breakdown.colorHex = colorHex;
    breakdown.negativePoints = negativePoints;
    breakdown.positivePoints = positivePoints;
    breakdown.fruitVegPoints = fruitVegPoints;
    breakdown.category = input.category;
    return breakdown;
  }

  static scoreToPercentage(score: number, isBeverage: boolean): number {
    const min = -15;
    const max = 40;
    const clamped = Math.max(min, Math.min(max, score));
    const ratio = (max - clamped) / (max - min);
    return Math.round(ratio * 100);
  }

  static detectCategory(foodName: string): FoodCategory {
    const lower = foodName.toLowerCase();
    const beverageKeywords = ['水', '饮料', '果汁', '茶', '咖啡', '可乐', '奶茶', '牛奶', '酸奶',
      '汽水', '酒', '啤酒', '豆浆', '椰汁', '矿泉水', 'jice', 'water', 'tea', 'coffee', 'milk',
      'soda', 'drink', 'beverage'];
    const fatKeywords = ['油', '黄油', '奶油', '脂', 'oil', 'butter', 'fat', 'margarine'];
    const cheeseKeywords = ['奶酪', '芝士', '干酪', 'cheese'];

    for (const kw of cheeseKeywords) {
      if (lower.includes(kw)) return FoodCategory.CHEESE;
    }
    for (const kw of fatKeywords) {
      if (lower.includes(kw)) return FoodCategory.FAT_OIL;
    }
    for (const kw of beverageKeywords) {
      if (lower.includes(kw)) return FoodCategory.BEVERAGE;
    }
    return FoodCategory.SOLID;
  }
}
