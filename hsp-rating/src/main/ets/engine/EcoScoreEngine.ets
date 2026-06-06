// hsp-rating: Eco-Score 生态评分计算引擎 (V2)
// 优先接入 Open Food Facts 实时数据 / 不可用时基于标签关键词匹配估算
// 参考: https://docs.score-environnemental.com/

import { FoodLabel, NutritionThreshold, HILOG_DOMAIN_DEFAULT, OffApiConfig } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';

const TAG = 'EcoScoreEngine';
const OFF_SEARCH = 'search';
const REQUEST_TIMEOUT = 8000;

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
  dataSource: 'off_api' | 'local_estimate' | 'none' = 'none';
}

export class EcoScoreFactor {
  name: string = '';
  impact: number = 0;
  description: string = '';
}

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
  readonly palmOilFree: string[] = [
    'palm oil free', '无棕榈油', 'no palm oil', 'rspo', '可持续棕榈油'
  ];
  readonly animalWelfare: string[] = [
    'free range', '散养', 'pasture raised', '牧场', 'grass fed', '草饲',
    'animal welfare', '动物福利', 'cage free'
  ];
}

const CERT_KW: CertKeywords = new CertKeywords(

const GRADE_TO_SCORE: Map<string, number> = new Map([
  [EcoScoreGrade.A, 90], [EcoScoreGrade.B, 70], [EcoScoreGrade.C, 50],
  [EcoScoreGrade.D, 30], [EcoScoreGrade.E, 10]
]);

export class EcoScoreEngine {
  compute(food: FoodLabel): EcoScoreResult {
    const result = this.evaluate(
      undefined, undefined,
      food.allergenHints.length > 0 ? food.allergenHints.join(',') : undefined,
      undefined, '', ''
    );
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'EcoScore=%{public}s(%{public}d) ds=%{public}s for %{public}s',
      result.grade, result.score, result.dataSource, food.foodName);
    return result;
  }

  async computeAsync(barcode: string): Promise<EcoScoreResult> {
    try {
      const offResult = await this.fetchFromOpenFoodFacts(barcode);
      if (offResult && offResult.dataSource === 'off_api') {
        return offResult;
      }
    } catch (_err) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'OFF API failed, fallback to local');
    }
    return this.compute(new FoodLabel());
  }

  private async fetchFromOpenFoodFacts(barcode: string): Promise<EcoScoreResult | null> {
    const url = `${OffApiConfig.BASE_URL}${OFF_SEARCH}?code=${encodeURIComponent(barcode)}&fields=ecoscore_grade,ecoscore_score,labels_tags,categories_tags,origins,manufacturing_places,carbon_footprint_from_known_ingredients`;
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: REQUEST_TIMEOUT,
        readTimeout: REQUEST_TIMEOUT,
        header: { 'User-Agent': OffApiConfig.USER_AGENT },
      });
      if (response.responseCode === 200 && response.result) {
        const body = typeof response.result === 'string'
          ? JSON.parse(response.result as string) as Record<string, Object>
          : response.result as Record<string, Object>;
        const products = (body['products'] as Object[]) ?? [];
        if (products.length > 0) {
          const product = products[0] as Record<string, Object>;
          return this.evaluate(
            product['ecoscore_grade'] as string | undefined,
            product['ecoscore_score'] as number | undefined,
            (product['labels_tags'] as string[])?.join(',') ?? undefined,
            (product['categories_tags'] as string[])?.join(',') ?? undefined,
            product['origins'] as string | undefined,
            product['manufacturing_places'] as string | undefined
          );
        }
      }
    } catch (_err) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'OFF request failed');
    } finally {
      request.destroy();
    }
    return null;
  }

  evaluate(
    ecoscoreGrade: string | undefined,
    ecoscoreScore: number | undefined,
    labels: string | undefined,
    categories: string | undefined,
    origins: string | undefined,
    manufacturingPlaces: string | undefined
  ): EcoScoreResult {
    const result: EcoScoreResult = new EcoScoreResult(
    const factors: EcoScoreFactor[] = [];

    if (ecoscoreGrade && ecoscoreGrade.length === 1 && 'abcde'.includes(ecoscoreGrade.toLowerCase())) {
      const gradeMap: Record<string, EcoScoreGrade> = {
        'a': EcoScoreGrade.A, 'b': EcoScoreGrade.B, 'c': EcoScoreGrade.C,
        'd': EcoScoreGrade.D, 'e': EcoScoreGrade.E
      };
      result.grade = gradeMap[ecoscoreGrade.toLowerCase()] ?? EcoScoreGrade.UNKNOWN;
      result.score = ecoscoreScore ?? (GRADE_TO_SCORE.get(result.grade) ?? 50);
      result.confidence = 0.95;
      result.dataSource = 'off_api';
      const f: EcoScoreFactor = new EcoScoreFactor(
      f.name = 'OFF官方评级';
      f.impact = result.score;
      f.description = `Eco-Score ${result.grade} (Open Food Facts 官方)`;
      factors.push(f);
      result.factors = factors;
      return result;
    }

    return this.localEstimate(labels ?? '', categories ?? '', origins ?? '', manufacturingPlaces ?? '');
  }

  private localEstimate(labels: string, categories: string, origins: string, manufacturingPlaces: string): EcoScoreResult {
    const result: EcoScoreResult = new EcoScoreResult(
    const factors: EcoScoreFactor[] = [];
    let estimatedScore = 50;
    let confidence = 0.3;
    const labelStr = labels.toLowerCase();
    const catStr = categories.toLowerCase();

    const applyFactor = (keywords: string[], name: string, scoreImpact: number, desc: string, certLabel?: string, carbonLabel?: string): void => {
      if (keywords.some(k => labelStr.includes(k))) {
        estimatedScore += scoreImpact;
        confidence += 0.06;
        const f: EcoScoreFactor = new EcoScoreFactor(
        f.name = name;
        f.impact = scoreImpact;
        f.description = desc;
        factors.push(f);
        if (certLabel) result.certifications.push(certLabel);
        if (carbonLabel) result.carbonLabels.push(carbonLabel);
      }
    };

    applyFactor(CERT_KW.organic, '有机认证', 15, '有机生产减少环境影响', '有机认证');
    applyFactor(CERT_KW.fairTrade, '公平贸易', 10, '公平贸易认证', '公平贸易');
    applyFactor(CERT_KW.carbon, '碳足迹认证', 12, '碳中和或低碳认证', undefined, '碳足迹认证');
    applyFactor(CERT_KW.sustainable, '可持续认证', 8, '可持续/再生农业/非转基因认证', '可持续认证');
    applyFactor(CERT_KW.palmOilFree, '无棕榈油', 5, '避免棕榈油使用保护热带雨林');
    applyFactor(CERT_KW.animalWelfare, '动物福利', 6, '关注动物福利的饲养方式', '动物福利');

    const originStr = (origins ?? '').toLowerCase();
    const mfgStr = (manufacturingPlaces ?? '').toLowerCase();
    const isLocal = CERT_KW.local.some(k => labelStr.includes(k)) ||
      (originStr.includes('中国') && mfgStr.includes('中国')) ||
      (originStr.length === 0 && mfgStr.includes('中国'));
    if (isLocal) {
      estimatedScore += 10;
      confidence += 0.05;
      const f: EcoScoreFactor = new EcoScoreFactor(
      f.name = '本土生产';
      f.impact = 10;
      f.description = '本地生产减少运输碳排放';
      factors.push(f);
    }

    if (catStr.includes('plant-based') || catStr.includes('植物基') || catStr.includes('素食') ||
      catStr.includes('vegan') || catStr.includes('vegetarian')) {
      estimatedScore += 5;
      const f: EcoScoreFactor = new EcoScoreFactor(
      f.name = '植物基加分';
      f.impact = 5;
      f.description = '植物基食品碳足迹和用水量更低';
      factors.push(f);
    }

    if (catStr.includes('beef') || catStr.includes('牛肉') || catStr.includes('lamb') || catStr.includes('羊肉')) {
      estimatedScore -= 8;
      const f: EcoScoreFactor = new EcoScoreFactor(
      f.name = '红肉碳足迹';
      f.impact = -8;
      f.description = '反刍动物养殖碳足迹较高';
      factors.push(f);
    }

    if (labels.length === 0 && categories.length === 0) {
      confidence = 0.15;
    }

    result.score = Math.max(0, Math.min(100, estimatedScore));
    result.confidence = Math.min(1, Math.max(0.1, confidence));
    result.grade = this.scoreToGrade(result.score);
    result.factors = factors;
    result.dataSource = 'local_estimate';

    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'EcoScore local estimate: %{public}s (%{public}d, conf=%{public}f)',
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
