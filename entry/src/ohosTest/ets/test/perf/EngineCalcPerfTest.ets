// EngineCalcPerfTest.ets
// 引擎计算性能基准测试 — 测量各引擎单次计算耗时
// 基准: 单次 ≤ 100ms, 容差: 50ms

import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  FoodLabel, NutritionPer100g, FamilyProfile, AgeGroup, HealthSignal, DailyBudget
} from 'hsp_core';
import { NutriScoreEngine, NutriScoreInput, AllergenAutoDetector } from 'feature_scan';
import {
  FoodAdapterEngine, FamilyMemberSimpleInput, FoodNutritionInput,
  HealthSignalInput, TodayIntakeInput
} from 'feature_scan';

const TAG = 'EngineCalcPerfTest';
const DOMAIN_ZERO = 0xFD00;

const ENGINE_CALC_BASELINE_MS = 100;
const ENGINE_CALC_TOLERANCE_MS = 50;
const ITERATIONS = 100;

interface PerfResult {
  testName: string;
  avgMs: number;
  minMs: number;
  maxMs: number;
  p95Ms: number;
  baselineMs: number;
  toleranceMs: number;
  passed: boolean;
}

function createSampleFoodLabel(): FoodLabel {
  const label = new FoodLabel();
  label.foodId = 'perf_test_food';
  label.foodName = '测试食品';
  label.barcode = '6901234567890';
  label.nutrition = new NutritionPer100g();
  label.nutrition.calories = 250;
  label.nutrition.sugar = 12;
  label.nutrition.sodium = 400;
  label.nutrition.fat = 8;
  label.nutrition.saturatedFat = 3;
  label.nutrition.protein = 15;
  label.nutrition.fiber = 4;
  label.nutrition.carbohydrate = 30;
  label.ingredients = ['花生酱', '面粉', '乳清蛋白', '白砂糖', '大豆卵磷脂'];
  return label;
}

function measureIteration(fn: () => void): number {
  const start = Date.now();
  fn();
  return Date.now() - start;
}

function computeStats(samples: number[]): { avg: number; min: number; max: number; p95: number } {
  const sorted = [...samples].sort((a, b) => a - b);
  const sum = sorted.reduce((acc, v) => acc + v, 0);
  const p95Idx = Math.floor(sorted.length * 0.95);
  return {
    avg: sum / sorted.length,
    min: sorted[0],
    max: sorted[sorted.length - 1],
    p95: sorted[p95Idx]
  };
}

export class EngineCalcPerfTest {
  private results: PerfResult[] = [];

  testNutriScoreEngine(): PerfResult {
    const input = new NutriScoreInput(250, 12, 400, 8, 3, 15, 4);
    const samples: number[] = [];

    for (let i = 0; i < ITERATIONS; i++) {
      samples.push(measureIteration(() => { NutriScoreEngine.calculateScore(input); }));
    }

    const stats = computeStats(samples);
    const passed = stats.avg <= (ENGINE_CALC_BASELINE_MS + ENGINE_CALC_TOLERANCE_MS);
    const result: PerfResult = {
      testName: 'NutriScoreEngine.calculateScore',
      avgMs: Math.round(stats.avg * 100) / 100,
      minMs: stats.min,
      maxMs: stats.max,
      p95Ms: stats.p95,
      baselineMs: ENGINE_CALC_BASELINE_MS,
      toleranceMs: ENGINE_CALC_TOLERANCE_MS,
      passed
    };
    this.results.push(result);
    hilog.info(DOMAIN_ZERO, TAG, '%{public}s: avg=%{public}fms p95=%{public}dms → %{public}s',
      result.testName, result.avgMs, result.p95Ms, passed ? 'PASS' : 'FAIL');
    return result;
  }

  testAllergenAutoDetector(): PerfResult {
    const detector = AllergenAutoDetector.getInstance();
    const userAllergens = ['花生', '牛奶', '鸡蛋'];
    const ingredients = ['花生酱', '面粉', '乳清蛋白', '白砂糖', '大豆卵磷脂', '脱脂乳粉'];
    const samples: number[] = [];

    for (let i = 0; i < ITERATIONS; i++) {
      samples.push(measureIteration(() => { detector.checkAllergens(userAllergens, ingredients); }));
    }

    const stats = computeStats(samples);
    const passed = stats.avg <= (ENGINE_CALC_BASELINE_MS + ENGINE_CALC_TOLERANCE_MS);
    const result: PerfResult = {
      testName: 'AllergenAutoDetector.checkAllergens',
      avgMs: Math.round(stats.avg * 100) / 100,
      minMs: stats.min,
      maxMs: stats.max,
      p95Ms: stats.p95,
      baselineMs: ENGINE_CALC_BASELINE_MS,
      toleranceMs: ENGINE_CALC_TOLERANCE_MS,
      passed
    };
    this.results.push(result);
    hilog.info(DOMAIN_ZERO, TAG, '%{public}s: avg=%{public}fms p95=%{public}dms → %{public}s',
      result.testName, result.avgMs, result.p95Ms, passed ? 'PASS' : 'FAIL');
    return result;
  }

  testFoodAdapterEngine(): PerfResult {
    const memberInput = new FamilyMemberSimpleInput();
    memberInput.id = 'perf_member';
    memberInput.name = '测试成员';
    memberInput.role = 'adult';
    memberInput.age = 35;
    memberInput.healthGoal = '均衡饮食';
    memberInput.allergenRedline = ['花生'];
    memberInput.dislikedAdditives = [];

    const budget = new (FamilyMemberSimpleInput as EsObject).constructor().dailyBudget?.constructor ??
      null;
    const foodInput = new FoodNutritionInput();
    foodInput.productName = '测试食品';
    foodInput.sodium_mg = 400;
    foodInput.sugar_g = 12;
    foodInput.energy_kj = 1046;
    foodInput.fat_g = 8;
    foodInput.saturatedFat_g = 3;
    foodInput.protein_g = 15;
    foodInput.allergens = ['花生酱'];

    const healthInput = new HealthSignalInput();
    healthInput.steps = 'normal';
    healthInput.sleep = 'good';

    const todayIntake = new TodayIntakeInput();
    todayIntake.sodium_mg = 800;
    todayIntake.sugar_g = 15;
    todayIntake.energy_kcal = 500;

    const samples: number[] = [];
    for (let i = 0; i < ITERATIONS; i++) {
      samples.push(measureIteration(() => {
        FoodAdapterEngine.calculateDynamicIntake(memberInput, foodInput, healthInput, todayIntake, i);
      }));
    }

    const stats = computeStats(samples);
    const passed = stats.avg <= (ENGINE_CALC_BASELINE_MS + ENGINE_CALC_TOLERANCE_MS);
    const result: PerfResult = {
      testName: 'FoodAdapterEngine.calculateDynamicIntake',
      avgMs: Math.round(stats.avg * 100) / 100,
      minMs: stats.min,
      maxMs: stats.max,
      p95Ms: stats.p95,
      baselineMs: ENGINE_CALC_BASELINE_MS,
      toleranceMs: ENGINE_CALC_TOLERANCE_MS,
      passed
    };
    this.results.push(result);
    hilog.info(DOMAIN_ZERO, TAG, '%{public}s: avg=%{public}fms p95=%{public}dms → %{public}s',
      result.testName, result.avgMs, result.p95Ms, passed ? 'PASS' : 'FAIL');
    return result;
  }

  testNutriScoreFromNutrition(): PerfResult {
    const nutrition = new NutritionPer100g();
    nutrition.calories = 250;
    nutrition.sugar = 12;
    nutrition.sodium = 400;
    nutrition.fat = 8;
    nutrition.saturatedFat = 3;
    nutrition.protein = 15;
    nutrition.fiber = 4;

    const samples: number[] = [];
    for (let i = 0; i < ITERATIONS; i++) {
      samples.push(measureIteration(() => { NutriScoreEngine.calculateFromNutrition(nutrition); }));
    }

    const stats = computeStats(samples);
    const passed = stats.avg <= (ENGINE_CALC_BASELINE_MS + ENGINE_CALC_TOLERANCE_MS);
    const result: PerfResult = {
      testName: 'NutriScoreEngine.calculateFromNutrition',
      avgMs: Math.round(stats.avg * 100) / 100,
      minMs: stats.min,
      maxMs: stats.max,
      p95Ms: stats.p95,
      baselineMs: ENGINE_CALC_BASELINE_MS,
      toleranceMs: ENGINE_CALC_TOLERANCE_MS,
      passed
    };
    this.results.push(result);
    return result;
  }

  runAll(): PerfResult[] {
    this.results = [];
    this.testNutriScoreEngine();
    this.testAllergenAutoDetector();
    this.testFoodAdapterEngine();
    this.testNutriScoreFromNutrition();
    return this.results;
  }

  getResults(): PerfResult[] {
    return [...this.results];
  }

  getSummary(): string {
    const total = this.results.length;
    const passed = this.results.filter(r => r.passed).length;
    return `EngineCalcPerf: ${passed}/${total} passed`;
  }
}