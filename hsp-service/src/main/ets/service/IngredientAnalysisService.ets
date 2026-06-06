// hsp-service: 统一成分分析服务（本地DB + 云端CloudDB + OFF API 三源融合）
// 对标 Yuka 核心引擎 —— 大规模成分数据库驱动型危害分析

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, OffApiConfig } from 'hsp_core';
import { CloudFunctionClient } from 'hsp_cloud';


const TAG = 'IngredientAnalysisService';
const DOMAIN = HILOG_DOMAIN_DEFAULT;

export interface HazardItem {
  code: string;
  name: string;
  hazardScore: number;
  hazardLevel: 'safe' | 'attention' | 'warning' | 'danger';
  category: string;
  description: string;
  longTermEffects: string[];
  populationWarnings: string[];
}

export interface IngredientAnalysisResult {
  overallScore: number;
  overallRisk: 'low' | 'medium' | 'high' | 'critical';
  totalAdditives: number;
  highRiskCount: number;
  moderateRiskCount: number;
  lowRiskCount: number;
  assessments: HazardItem[];
  allergenWarnings: string[];
  specialWarnings: string[];
  summary: string;
  recommendations: string[];
  dataSources: string[];
  analyzedAt: number;
}

export class IngredientAnalysisService {
  private static instance: IngredientAnalysisService | null = null;
  private cloudClient: CloudFunctionClient;

  private constructor() {
    this.cloudClient = new CloudFunctionClient();
  }

  static getInstance(): IngredientAnalysisService {
    if (!IngredientAnalysisService.instance) {
      IngredientAnalysisService.instance = new IngredientAnalysisService();
    }
    return IngredientAnalysisService.instance;
  }

  async analyze(food: FoodLabel): Promise<IngredientAnalysisResult> {
    const ingredients = food.ingredients;
    if (ingredients.length === 0) {
      return this.emptyResult();
    }

    let cloudResult: IngredientAnalysisResult | null = null;
    try {
      cloudResult = await this.analyzeCloud(ingredients);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Cloud deep analyze failed: %{public}s', JSON.stringify(e));
    }

    if (cloudResult && cloudResult.assessments.length > 0) {
      cloudResult.dataSources.push('local_kb');
      return cloudResult;
    }

    return this.analyzeLocalEOnly(ingredients);
  }

  private analyzeLocalEOnly(ingredients: string[]): IngredientAnalysisResult {
    const codes = this.extractECodes(ingredients);
    const assessments: HazardItem[] = codes.map(code => ({
      code,
      name: code,
      hazardScore: 0,
      hazardLevel: 'attention' as const,
      category: '',
      description: `${code} — 食品添加剂`,
      longTermEffects: [] as string[],
      populationWarnings: [] as string[],
    }));

    if (assessments.length === 0 && ingredients.length > 0) {
      assessments.push({
        code: 'ingredients',
        name: `共${ingredients.length}种配料`,
        hazardScore: 0,
        hazardLevel: 'safe',
        category: '',
        description: '请在联网状态下获取深度分析',
        longTermEffects: [],
        populationWarnings: [],
      });
    }

    return this.buildResult(assessments, ['local_kb']);
  }


  private async analyzeCloud(ingredients: string[]): Promise<IngredientAnalysisResult | null> {
    try {
      const response = await this.cloudClient.call({
        endpoint: 'ingredient-deep-analyze',
        data: { ingredients },
      }) as Record<string, Object>;

      if (!response || !response['assessments']) return null;

      const rawAssessments = response['assessments'] as Array<Record<string, Object>>;
      const assessments: HazardItem[] = rawAssessments.map(a => ({
        code: (a['code'] as string) ?? '',
        name: (a['name'] as string) ?? '',
        hazardScore: (a['hazardScore'] as number) ?? 0,
        hazardLevel: (a['hazardLevel'] as HazardItem['hazardLevel']) ?? 'attention',
        category: (a['category'] as string) ?? '',
        description: (a['description'] as string) ?? '',
        longTermEffects: (a['longTermEffects'] as string[]) ?? [],
        populationWarnings: (a['specialPopulationWarnings'] as string[]) ?? [],
      }));

      const result = this.buildResult(assessments, ['cloud_db']);
      if (response['allergenWarnings']) {
        result.allergenWarnings = response['allergenWarnings'] as string[];
      }
      if (response['specialWarnings']) {
        result.specialWarnings = response['specialWarnings'] as string[];
      }

      return result;
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      return null;
    }
  }

  private buildResult(
    assessments: HazardItem[],
    dataSources: string[]
  ): IngredientAnalysisResult {
    const highRisk = assessments.filter(a => a.hazardLevel === 'danger').length;
    const moderate = assessments.filter(a => a.hazardLevel === 'warning').length;
    const low = assessments.filter(a => a.hazardLevel === 'attention' || a.hazardLevel === 'safe').length;
    const overallScore = Math.max(0, Math.min(100,
      100 - (high * 25 + moderate * 10)));

    let overallRisk: IngredientAnalysisResult['overallRisk'] = 'low';
    if (high >= 3) overallRisk = 'critical';
    else if (high >= 1) overallRisk = 'high';
    else if (moderate >= 3) overallRisk = 'medium';

    return {
      overallScore,
      overallRisk,
      totalAdditives: assessments.length,
      highRiskCount: high,
      moderateRiskCount: moderate,
      lowRiskCount: low,
      assessments,
      allergenWarnings: [],
      specialWarnings: [],
      summary: overallRisk === 'critical'
        ? `严重: ${high}种高风险添加剂`
        : `安全: 评分${overallScore}分`,
      recommendations: high > 0
        ? [`${high}种高风险添加剂建议替换为清洁标签食品`]
        : ['可以放心食用'],
      dataSources,
      analyzedAt: Date.now(),
    };
  }

  private extractECodes(ingredients: string[]): string[] {
    const codes: string[] = [];
    const ePattern = /E\d{3,4}[a-z]?/gi;
    for (const ing of ingredients) {
      const matches = ing.match(ePattern);
      if (matches) {
        for (const m of matches) codes.push(m.toUpperCase());
      }
    }
    return [...new Set(codes)];
  }


  private emptyResult(): IngredientAnalysisResult {
    return this.buildResult([], ['local_db']);
  }
}