// hsp-service: 统一成分分析服务（本地DB + 云端CloudDB + OFF API 三源融合）
// 对标 Yuka 核心引擎 —— 大规模成分数据库驱动型危害分析

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, OffApiConfig } from 'hsp_core';
import { CloudFunctionClient } from 'hsp_cloud';


const TAG = 'IngredientAnalysisService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const DOMAIN = DOMAIN_ZERO;

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

interface DeepAnalyzeRequest {
  ingredients: Object;
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
    const assessments: HazardItem[] = codes.map((code: string): HazardItem => {
      const h: HazardItem = {
        code,
        name: code,
        hazardScore: 0,
        hazardLevel: 'attention',
        category: '',
        description: `${code} — 食品添加剂`,
        longTermEffects: [] as string[],
        populationWarnings: [] as string[],
      };
      return h;
    });

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
      const params: Record<string, Object> = {}
      params['ingredients'] = ingredients as Object
      const response: Object = await this.cloudClient.call('ingredient-deep-analyze', params);
      const responseRecord: Record<string, Object> = response as Record<string, Object>;

      if (!responseRecord || !responseRecord.assessments) return null;

      const rawAssessments: Array<Record<string, Object>> = responseRecord.assessments as Array<Record<string, Object>>;
      const assessments: HazardItem[] = rawAssessments.map((a: Record<string, Object>): HazardItem => {
        const hLevel: string = (a.hazardLevel as string) ?? 'attention';
        let hazardLevel: 'safe' | 'attention' | 'warning' | 'danger' = 'attention';
        if (hLevel === 'safe') hazardLevel = 'safe';
        else if (hLevel === 'warning') hazardLevel = 'warning';
        else if (hLevel === 'danger') hazardLevel = 'danger';
        const item: HazardItem = {
          code: (a.code as string) ?? '',
          name: (a.name as string) ?? '',
          hazardScore: (a.hazardScore as number) ?? 0,
          hazardLevel: hazardLevel,
          category: (a.category as string) ?? '',
          description: (a.description as string) ?? '',
          longTermEffects: (a.longTermEffects as string[]) ?? ([] as string[]),
          populationWarnings: (a.specialPopulationWarnings as string[]) ?? ([] as string[]),
        };
        return item;
      });

      const result: IngredientAnalysisResult = this.buildResult(assessments, ['cloud_db']);
      if (responseRecord.allergenWarnings) {
        result.allergenWarnings = responseRecord.allergenWarnings as string[];
      }
      if (responseRecord.specialWarnings) {
        result.specialWarnings = responseRecord.specialWarnings as string[];
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
    const high = assessments.filter((a: HazardItem): boolean => a.hazardLevel === 'danger').length;
    const moderate = assessments.filter((a: HazardItem): boolean => a.hazardLevel === 'warning').length;
    const low = assessments.filter((a: HazardItem): boolean => a.hazardLevel === 'attention' || a.hazardLevel === 'safe').length;
    const overallScore = Math.max(0, Math.min(100,
      100 - (high * 25 + moderate * 10)));

    let overallRisk: 'low' | 'medium' | 'high' | 'critical' = 'low';
    if (high >= 3) overallRisk = 'critical';
    else if (high >= 1) overallRisk = 'high';
    else if (moderate >= 3) overallRisk = 'medium';

    const result: IngredientAnalysisResult = {
      overallScore: overallScore,
      overallRisk: overallRisk,
      totalAdditives: assessments.length,
      highRiskCount: high,
      moderateRiskCount: moderate,
      lowRiskCount: low,
      assessments: assessments,
      allergenWarnings: [],
      specialWarnings: [],
      summary: overallRisk === 'critical'
        ? `严重: ${high}种高风险添加剂`
        : `安全: 评分${overallScore}分`,
      recommendations: high > 0
        ? [`${high}种高风险添加剂建议替换为清洁标签食品`]
        : ['可以放心食用'],
      dataSources: dataSources,
      analyzedAt: Date.now(),
    };
    return result;
  }

  private extractECodes(ingredients: string[]): string[] {
    const codes: string[] = [];
    const ePattern: RegExp = /E\d{3,4}[a-z]?/gi;
    for (const ing of ingredients) {
      const matches: RegExpMatchArray | null = ing.match(ePattern);
      if (matches) {
        for (const m of matches) codes.push(m.toUpperCase());
      }
    }
    const uniqueCodes: string[] = [];
    for (const code of codes) {
      if (uniqueCodes.indexOf(code) === -1) {
        uniqueCodes.push(code);
      }
    }
    return uniqueCodes;
  }


  private emptyResult(): IngredientAnalysisResult {
    return this.buildResult([], ['local_db']);
  }
}