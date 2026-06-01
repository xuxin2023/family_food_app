// hsp-rating: Eco-Score 生态评分计算引擎
// 基于标签关键词匹配与OFF（Open Food Facts）字段的简化实现
// 参考: https://docs.score-environnemental.com/

import { FoodLabel, NutritionThreshold, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'EcoScoreEngine';

export enum EcoScoreGrade {
  A = 'A', B = 'B', C = 'C', D = 'D', E = 'E', UNKNOWN = '?'
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

/** 认证标签关键词库 */
class CertKeywords {
  readonly organic: string[] = [
    'bio', 'organic', '有机', '有机认证', '有机食品', 'organic certified',
    'usda organic', 'ecocert', '中国有机', '绿色食品', '绿色认证',
    'oca', 'demeter', 'naturland'
  ];
  readonly fairTrade: string[] = [
    'fair-trade', 'fairtrade', '公平贸易', '公平贸易认证',
    'fsc', 'rainforest alliance', '雨林联盟'
  ];
  readonly carbon: string[] = [
    'carbon neutral', '碳中和', '零碳', 'carbon trust', 'carbon footprint',
    '碳足迹', '低碳认证', 'low carbon', 'climate neutral', '气候中性'
  ];
  readonly sustainable: string[] = [
    'sustainable', '可持续', 'sustainability', 'regenerative', '再生农业',
    'b corp', '共益企业', 'leaping bunny', '跃兔认证',
    'cruelty free', '无残忍', '非转基因', 'non-gmo', '无转基因'
  ];
  readonly local: string[] = [
    'local', '本地', 'locally sourced', '地产地销',
    'from our farm', '农场直供'
  ];
}

const CERT_KW = new CertKeywords();

const GRADE_TO_SCORE: Map<string, number> = new Map([
  [EcoScoreGrade.A, 90], [EcoScoreGrade.B, 70], [EcoScoreGrade.C, 50],
  [EcoScoreGrade.D, 30], [EcoScoreGrade.E, 10]
]);

export class EcoScoreEngine {
  /** 从 FoodLabel 计算 Eco-Score —— HSP 对外统一入口 */
  compute(food: FoodLabel): EcoScoreResult {
    const result = this.evaluate(
      undefined, undefined,
      food.allergenHints.length > 0 ? food.allergenHints.join(',') : undefined,
      undefined, '', ''
    );
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'EcoScore computed: %{public}s (%{public}d) for %{public}s',
      result.grade, result.score, food.foodName);
    return result;
  }

  /**
   * 基于 OFF 字段 & 标签关键词计算 Eco-Score
   * 优先使用 OFF 官方数据；不可用时基于标签匹配估算
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

    // 优先使用 OFF 官方评级
    if (ecoscoreGrade && ecoscoreGrade.length === 1 && 'abcde'.includes(ecoscoreGrade.toLowerCase())) {
      result.grade = ({
        'a': EcoScoreGrade.A, 'b': EcoScoreGrade.B, 'c': EcoScoreGrade.C,
        'd': EcoScoreGrade.D, 'e': EcoScoreGrade.E
      } as Record<string, EcoScoreGrade>)[ecoscoreGrade.toLowerCase()] ?? EcoScoreGrade.UNKNOWN;
      result.score = ecoscoreScore ?? (GRADE_TO_SCORE.get(result.grade) ?? 50);
      result.confidence = 0.9;

      const f = new EcoScoreFactor();
      f.name = 'OFF官方评级';
      f.impact = result.score;
      f.description = `Eco-Score ${result.grade} (OFF官方数据)`;
      factors.push(f);
      result.factors = factors;
      return result;
    }

    let estimatedScore = 50;
    let confidence = 0.3;
    const labelStr = (labels ?? '').toLowerCase();

    // 有机认证
    if (CERT_KW.organic.some(k => labelStr.includes(k))) {
      estimatedScore += 15;
      confidence += 0.1;
      const f = new EcoScoreFactor();
      f.name = '有机认证';
      f.impact = 15;
      f.description = '有机生产减少环境影响';
      factors.push(f);
      result.certifications.push('有机认证');
    }

    // 公平贸易
    if (CERT_KW.fairTrade.some(k => labelStr.includes(k))) {
      estimatedScore += 10;
      const f = new EcoScoreFactor();
      f.name = '公平贸易';
      f.impact = 10;
      f.description = '公平贸易认证';
      factors.push(f);
      result.certifications.push('公平贸易');
    }

    // 碳足迹/碳中和
    if (CERT_KW.carbon.some(k => labelStr.includes(k))) {
      estimatedScore += 12;
      confidence += 0.08;
      const f = new EcoScoreFactor();
      f.name = '碳足迹认证';
      f.impact = 12;
      f.description = '碳中和或低碳认证，减少温室气体排放';
      factors.push(f);
      result.carbonLabels.push('碳足迹认证');
    }

    // 可持续认证
    if (CERT_KW.sustainable.some(k => labelStr.includes(k))) {
      estimatedScore += 8;
      confidence += 0.05;
      const f = new EcoScoreFactor();
      f.name = '可持续认证';
      f.impact = 8;
      f.description = '可持续/再生农业/非转基因等认证';
      factors.push(f);
      result.certifications.push('可持续认证');
    }

    // 本土生产
    const originStr = (origins ?? '').toLowerCase();
    const mfgStr = (manufacturingPlaces ?? '').toLowerCase();
    if (CERT_KW.local.some(k => labelStr.includes(k)) ||
      (originStr.includes('中国') && mfgStr.includes('中国'))) {
      estimatedScore += 10;
      confidence += 0.05;
      const f = new EcoScoreFactor();
      f.name = '本土生产';
      f.impact = 10;
      f.description = '本地生产减少运输碳排放';
      factors.push(f);
    }

    // 植物基加分
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

    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'EcoScore estimated: %{public}s (%{public}d/100, confidence: %{public}f)',
      result.grade, result.score, result.confidence);
    return result;
  }

  private scoreToGrade(score: number): EcoScoreGrade {
    if (score >= NutritionThreshold.SCORE_THRESHOLD_A) return EcoScoreGrade.A;
    if (score >= NutritionThreshold.SCORE_THRESHOLD_B) return EcoScoreGrade.B;
    if (score >= NutritionThreshold.SCORE_THRESHOLD_C) return EcoScoreGrade.C;
    if (score >= NutritionThreshold.SCORE_THRESHOLD_D) return EcoScoreGrade.D;
    return EcoScoreGrade.E;
  }
}
