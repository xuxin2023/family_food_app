/**
 * hsp-core-cj/Index.ets — 仓颉计算模块 ArkTS NAPI 桥接层
 * 暴露仓颉核心函数给 ArkTS 调用
 */
import computeLib from 'libcompute_engine.so';

export interface NutriScoreResult {
  score: number;
  grade: string;
}

export class CjCompute {
  static cosineSimilarity(a: number[], b: number[]): number {
    return computeLib.cosineSimilarity(a, b);
  }

  static vectorNormalize(a: number[]): number[] {
    return computeLib.vectorNormalize(a);
  }

  static nutriScoreCalc(
    calories: number, sugar: number, sodium: number,
    fat: number, saturatedFat: number, protein: number,
    fiber: number, fruitVegPercent: number
  ): NutriScoreResult {
    return computeLib.nutriScoreCalc(
      calories, sugar, sodium, fat, saturatedFat,
      protein, fiber, fruitVegPercent
    );
  }

  static bmiCalculate(weightKg: number, heightCm: number): number {
    return computeLib.bmiCalculate(weightKg, heightCm);
  }

  static weightedScore(factors: number[], weights: number[]): number {
    return computeLib.weightedScore(factors, weights);
  }
}

export { NutriScoreResult };