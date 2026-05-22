// EcoScoreEngine.ets
// Eco-Score 生态评分计算引擎 — 基于 Open Food Facts 可获取字段简化实现
// 参考: https://docs.score-environnemental.com/

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';

const TAG = 'EcoScoreEngine';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export enum EcoScoreGrade {
  A = 'A',
  B = 'B',
  C = 'C',
  D = 'D',
  E = 'E',
  UNKNOWN = '?'
}

export class EcoScoreResult {
  grade: EcoScoreGrade = EcoScoreGrade.UNKNOWN;
  score: number = 0;
  confidence: number = 0;
  factors: EcoScoreFactor[] = [];
}

export class EcoScoreFactor {
  name: string = '';
  impact: number = 0;
  description: string = '';
}

export class EcoScoreEngine {
  private static instance: EcoScoreEngine;
  private constructor() {}

  private static readonly GRADE_MAP: Map<string, EcoScoreGrade> = new Map([
    ['a', EcoScoreGrade.A],
    ['b', EcoScoreGrade.B],
    ['c', EcoScoreGrade.C],
    ['d', EcoScoreGrade.D],
    ['e', EcoScoreGrade.E]
  ]);

  private static readonly GRADE_TO_SCORE: Map<string, number> = new Map([
    [EcoScoreGrade.A, 90],
    [EcoScoreGrade.B, 70],
    [EcoScoreGrade.C, 50],
    [EcoScoreGrade.D, 30],
    [EcoScoreGrade.E, 10]
  ]);

  static getInstance(): EcoScoreEngine {
    if (!EcoScoreEngine.instance) {
      EcoScoreEngine.instance = new EcoScoreEngine();
    }
    return EcoScoreEngine.instance;
  }

  /**
   * 基于 OFF 字段简化计算 Eco-Score
   * @param ecoscoreGrade OFF API 返回的 ecoscore_grade (a-e)
   * @param ecoscoreScore OFF API 返回的 ecoscore_score (0-100)
   * @param labels 产品的标签列表（如 "Bio","Fair-trade" 等）
   * @param categories 产品的分类
   * @param origins 原产地
   * @param manufacturingPlaces 生产地
   */
  evaluate(
    ecoscoreGrade: string | undefined,
    ecoscoreScore: number | undefined,
    labels: string | undefined,
    categories: string | undefined,
    origins: string | undefined,
    manufacturingPlaces: string | undefined
  ): EcoScoreResult {
    const result = new EcoScoreResult();
    const factors: EcoScoreFactor[] = [];

    if (ecoscoreGrade && ecoscoreGrade.length === 1 && 'abcde'.includes(ecoscoreGrade.toLowerCase())) {
      result.grade = EcoScoreEngine.GRADE_MAP.get(ecoscoreGrade.toLowerCase()) ?? EcoScoreGrade.UNKNOWN;
      result.score = ecoscoreScore ?? this.gradeToScore(result.grade);
      result.confidence = 0.9;

      const f1 = new EcoScoreFactor();
      f1.name = 'OFF官方评级';
      f1.impact = result.score;
      f1.description = `Eco-Score ${result.grade} (OFF官方数据)`;
      factors.push(f1);
      result.factors = factors;
      return result;
    }

    let estimatedScore = 50;
    let confidence = 0.3;

    const labelStr = (labels ?? '').toLowerCase();
    if (labelStr.includes('bio') || labelStr.includes('organic') || labelStr.includes('有机')) {
      estimatedScore += 15;
      confidence += 0.1;
      const f = new EcoScoreFactor();
      f.name = '有机认证';
      f.impact = 15;
      f.description = '有机生产减少环境影响';
      factors.push(f);
    }

    if (labelStr.includes('fair-trade') || labelStr.includes('fairtrade') || labelStr.includes('公平贸易')) {
      estimatedScore += 10;
      const f = new EcoScoreFactor();
      f.name = '公平贸易';
      f.impact = 10;
      f.description = '公平贸易认证';
      factors.push(f);
    }

    const originStr = (origins ?? '').toLowerCase();
    const mfgStr = (manufacturingPlaces ?? '').toLowerCase();
    if (originStr.includes('中国') && mfgStr.includes('中国')) {
      estimatedScore += 10;
      confidence += 0.05;
      const f = new EcoScoreFactor();
      f.name = '本土生产';
      f.impact = 10;
      f.description = '本地生产减少运输碳排放';
      factors.push(f);
    }

    result.score = Math.max(0, Math.min(100, estimatedScore));
    result.confidence = Math.min(1, confidence);
    result.grade = this.scoreToGrade(result.score);
    result.factors = factors;

    hilog.info(DOMAIN_ZERO, TAG, 'EcoScore estimated: %{public}s (%{public}d/100, confidence: %{public}f)',
      result.grade, result.score, result.confidence);
    return result;
  }

  private gradeToScore(grade: EcoScoreGrade): number {
    return EcoScoreEngine.GRADE_TO_SCORE.get(grade) ?? 50;
  }

  private scoreToGrade(score: number): EcoScoreGrade {
    if (score >= 80) return EcoScoreGrade.A;
    if (score >= 60) return EcoScoreGrade.B;
    if (score >= 40) return EcoScoreGrade.C;
    if (score >= 20) return EcoScoreGrade.D;
    return EcoScoreGrade.E;
  }
}
