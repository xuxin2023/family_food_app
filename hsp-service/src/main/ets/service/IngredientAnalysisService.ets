// hsp-service: 统一成分分析服务（本地DB + 云端CloudDB + OFF API 三源融合）
// 对标 Yuka 核心引擎 —— 大规模成分数据库驱动型危害分析

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, OffApiConfig } from 'hsp_core';
import { CloudFunctionClient } from 'hsp_cloud';
import { AdditiveSafetyEngine, IngredientKnowledgeBase } from 'feature_scan';

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
  private safetyEngine: AdditiveSafetyEngine;
  private knowledgeBase: IngredientKnowledgeBase;

  private constructor() {
    this.cloudClient = new CloudFunctionClient();
    this.safetyEngine = AdditiveSafetyEngine.getInstance();
    this.knowledgeBase = new IngredientKnowledgeBase();
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

    const localResult = this.analyzeLocal(ingredients);
    let cloudResult: IngredientAnalysisResult | null = null;

    try {
      cloudResult = await this.analyzeCloud(ingredients);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Cloud deep analyze failed: %{public}s', JSON.stringify(e));
    }

    if (cloudResult && cloudResult.assessments.length > 0) {
      cloudResult.dataSources.push('local_db');
      return cloudResult;
    }

    return localResult;
  }

  private analyzeLocal(ingredients: string[]): IngredientAnalysisResult {
    const eCodes = this.extractECodes(ingredients);
    const assessments: HazardItem[] = [];

    for (const code of eCodes) {
      try {
        const safetyInfo = this.safetyEngine.getAdditiveInfo(code);
        if (safetyInfo) {
          const hazard = safetyInfo as Record<string, Object>;
          assessments.push({
            code,
            name: (hazard['name'] as string) ?? code,
            hazardScore: (hazard['hazardLevel'] as number) ?? 0,
            hazardLevel: this.numToLevel((hazard['hazardLevel'] as number) ?? 0),
            category: (hazard['category'] as string) ?? '',
            description: (hazard['description'] as string) ?? '',
            longTermEffects: (hazard['longTermEffect'] as string)?.split(',') ?? [],
            populationWarnings: [],
          });
          continue;
        }
      } catch (_) { /* fall through to local knowledge base */ }

      const kbAssessment = this.knowledgeBase.analyzeIngredient(code);
      if (kbAssessment) {
        assessments.push({
          code,
          name: code,
          hazardScore: kbAssessment.score ?? 0,
          hazardLevel: 'attention',
          category: kbAssessment.category ?? '',
          description: kbAssessment.description ?? '',
          longTermEffects: [],
          populationWarnings: [],
        });
      }
    }

    if (assessments.length === 0) {
      for (const ing of ingredients.slice(0, 10)) {
        const kb = this.knowledgeBase.analyzeIngredient(ing);
        if (kb && kb.score && kb.score > 0) {
          assessments.push({
            code: ing.substring(0, 20),
            name: ing,
            hazardScore: kb.score,
            hazardLevel: 'attention',
            category: kb.category ?? '',
            description: kb.description ?? '',
            longTermEffects: [],
            populationWarnings: [],
          });
        }
      }
    }

    return this.buildResult(assessments, ['local_db']);
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

  private numToLevel(level: number): HazardItem['hazardLevel'] {
    const map: HazardItem['hazardLevel'][] = ['safe', 'attention', 'warning', 'danger'];
    return map[level] ?? 'attention';
  }

  private emptyResult(): IngredientAnalysisResult {
    return this.buildResult([], ['local_db']);
  }
}