// InferenceFallback.ets
// 端侧推理 fallback — 规则引擎的轻量级推理逻辑
// 当 OnDeviceInferenceEngine 模型不可用时，基于营养阈值提供基础推理
// 独立文件避免 OnDeviceInferenceEngine ↔ RuleEngine 循环引用

import { NutritionPer100g, HILOG_DOMAIN } from 'hsp_core';
import { InferenceResult, InferenceAlternative } from './InferenceTypes';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'InferenceFallback';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

const HIGH_SODIUM_THRESHOLD_MG: number = 800;
const HIGH_SUGAR_THRESHOLD_G: number = 15;
const ULTRA_PROCESSED_ADDITIVE_COUNT: number = 3;

export class RuleFallbackResult {
  isHighSodium: boolean = false;
  isHighSugar: boolean = false;
  isUltraProcessed: boolean = false;
  warnings: string[] = [];
  confidence: number = 0.7;
}

export function evaluateNutritionFallback(
  nutrition: NutritionPer100g, additiveCount: number = 0
): RuleFallbackResult {
  const startTime = Date.now();
  const result = new RuleFallbackResult();
  result.isHighSodium = nutrition.sodium > HIGH_SODIUM_THRESHOLD_MG;
  result.isHighSugar = nutrition.sugar > HIGH_SUGAR_THRESHOLD_G;
  result.isUltraProcessed = additiveCount >= ULTRA_PROCESSED_ADDITIVE_COUNT;

  if (result.isHighSodium) {
    result.warnings.push(`高钠食品 (${Math.round(nutrition.sodium)}mg/100g > ${HIGH_SODIUM_THRESHOLD_MG}mg)`);
  }
  if (result.isHighSugar) {
    result.warnings.push(`高糖食品 (${nutrition.sugar.toFixed(1)}g/100g > ${HIGH_SUGAR_THRESHOLD_G}g)`);
  }
  if (result.isUltraProcessed) {
    result.warnings.push(`可能超加工食品 (含${additiveCount}种以上添加剂)`);
  }
  if (!result.isHighSodium && !result.isHighSugar && !result.isUltraProcessed) {
    result.confidence = 0.85;
  }

  const elapsed = Date.now() - startTime;
  hilog.info(DOMAIN_ZERO, TAG,
    'evaluateNutritionFallback: %{public}d warnings, %{public}dms',
    result.warnings.length, elapsed);
  return result;
}

export function predictAsInference(
  nutrition: NutritionPer100g, additiveCount: number = 0
): InferenceResult {
  const startTime = Date.now();
  const ruleResult = evaluateNutritionFallback(nutrition, additiveCount);

  let label = 'safe_food';
  let confidence = 0.7;
  const alternatives: InferenceAlternative[] = [];

  if (ruleResult.isHighSodium) {
    label = 'high_sodium';
    confidence = 0.75;
    alternatives.push(new InferenceAlternative('high_sodium', 0.75));
  }
  if (ruleResult.isHighSugar) {
    if (label === 'safe_food') {
      label = 'high_sugar';
    }
    confidence = Math.max(confidence, 0.75);
    alternatives.push(new InferenceAlternative('high_sugar', 0.75));
  }
  if (ruleResult.isUltraProcessed) {
    if (label === 'safe_food') {
      label = 'ultra_processed';
    }
    confidence = Math.max(confidence, 0.7);
    alternatives.push(new InferenceAlternative('ultra_processed', 0.7));
  }

  if (label === 'safe_food') {
    alternatives.push(new InferenceAlternative('safe_food', 0.85));
  }

  const elapsed = Date.now() - startTime;
  hilog.info(DOMAIN_ZERO, TAG,
    'predictAsInference: %{public}s (%.2f), %{public}dms',
    label, confidence, elapsed);

  return new InferenceResult(label, confidence, alternatives, elapsed);
}
