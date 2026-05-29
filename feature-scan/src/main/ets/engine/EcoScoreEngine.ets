// EcoScoreEngine.ets
// Eco-Score 生态评分计算引擎 — 基于 Open Food Facts 可获取字段简化实现
// 参考: https://docs.score-environnemental.com/

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, NutritionThreshold } from 'hsp_core';

const TAG = 'EcoScoreEngine';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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
  certifications: string[] = [];
  carbonLabels: string[] = [];
}

export class EcoScoreFactor {
  name: string = '';
  impact: number = 0;
  description: string = '';
}

class CertKeywordSet {
  organic: string[] = ['bio', 'organic', '有机', '有机认证', '有机食品', 'organic certified', 'usda organic', 'ecocert', '中国有机', '绿色食品', '绿色认证', 'oca', 'demeter', 'naturland'];
  fairTrade: string[] = ['fair-trade', 'fairtrade', '公平贸易', '公平贸易认证', 'fsc', 'rainforest alliance', '雨林联盟'];
  carbon: string[] = ['carbon neutral', '碳中和', '零碳', 'carbon trust', 'carbon footprint', '碳足迹', '低碳认证', 'low carbon', 'climate neutral', '气候中性'];
  sustainable: string[] = ['sustainable', '可持续', 'sustainability', 'regenerative', '再生农业', 'b corp', '共益企业', 'leaping bunny', '跃兔认证', 'cruelty free', '无残忍', '非转基因', 'non-gmo', '无转基因'];
  local: string[] = ['local', '本地', 'locally sourced', '地产地销', 'from our farm', '农场直供'];
}

const CERT_KEYWORDS = new CertKeywordSet();

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

    // 有机认证关键词匹配
    const organicMatch = CERT_KEYWORDS.organic.some(k => labelStr.includes(k));
    if (organicMatch || labelStr.includes('bio') || labelStr.includes('organic') || labelStr.includes('有机')) {
      estimatedScore += 15;
      confidence += 0.1;
      const f = new EcoScoreFactor();
      f.name = '有机认证';
      f.impact = 15;
      f.description = '有机生产减少环境影响';
      factors.push(f);
      result.certifications.push('有机认证');
    }

    // 公平贸易关键词匹配
    const fairTradeMatch = CERT_KEYWORDS.fairTrade.some(k => labelStr.includes(k));
    if (fairTradeMatch || labelStr.includes('fair-trade') || labelStr.includes('fairtrade') || labelStr.includes('公平贸易')) {
      estimatedScore += 10;
      const f = new EcoScoreFactor();
      f.name = '公平贸易';
      f.impact = 10;
      f.description = '公平贸易认证';
      factors.push(f);
      result.certifications.push('公平贸易');
    }

    // 碳足迹/碳中和标签识别
    const carbonMatch = CERT_KEYWORDS.carbon.some(k => labelStr.includes(k));
    if (carbonMatch) {
      estimatedScore += 12;
      confidence += 0.08;
      const f = new EcoScoreFactor();
      f.name = '碳足迹认证';
      f.impact = 12;
      f.description = '碳中和或低碳认证，减少温室气体排放';
      factors.push(f);
      result.carbonLabels.push('碳足迹认证');
    }

    // 可持续/再生农业/非转基因等
    const sustainableMatch = CERT_KEYWORDS.sustainable.some(k => labelStr.includes(k));
    if (sustainableMatch) {
      estimatedScore += 8;
      confidence += 0.05;
      const f = new EcoScoreFactor();
      f.name = '可持续认证';
      f.impact = 8;
      f.description = '可持续/再生农业/非转基因等认证';
      factors.push(f);
      result.certifications.push('可持续认证');
    }

    // 本地生产标签
    const localMatch = CERT_KEYWORDS.local.some(k => labelStr.includes(k));
    const originStr = (origins ?? '').toLowerCase();
    const mfgStr = (manufacturingPlaces ?? '').toLowerCase();
    if (localMatch || (originStr.includes('中国') && mfgStr.includes('中国'))) {
      estimatedScore += 10;
      confidence += 0.05;
      const f = new EcoScoreFactor();
      f.name = '本土生产';
      f.impact = 10;
      f.description = '本地生产减少运输碳排放';
      factors.push(f);
    }

    // 分类标签环境影响修正
    const catStr = (categories ?? '').toLowerCase();
    if (catStr.includes('plant-based') || catStr.includes('植物基') || catStr.includes('素食')) {
      estimatedScore += 5;
      const f = new EcoScoreFactor();
      f.name = '植物基加分';
      f.impact = 5;
      f.description = '植物基食品碳足迹更低';
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
    if (score >= NutritionThreshold.SCORE_THRESHOLD_A) return EcoScoreGrade.A;
    if (score >= NutritionThreshold.SCORE_THRESHOLD_B) return EcoScoreGrade.B;
    if (score >= NutritionThreshold.SCORE_THRESHOLD_C) return EcoScoreGrade.C;
    if (score >= NutritionThreshold.SCORE_THRESHOLD_D) return EcoScoreGrade.D;
    return EcoScoreGrade.E;
  }
}
