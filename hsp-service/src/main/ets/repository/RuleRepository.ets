// 规则仓库 - 加载JSON规则文件（带缓存）

import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'RuleRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

// 目标调整因子
export class GoalAdjustment {
  sodium: number = 0;
  sugar: number = 0;
  calorie: number = 0;
  fat: number = 0;
}

// 动态修正因子
export class DynamicFactor {
  sodiumFactor: number = 1;
  calorieFactor: number = 1;
  sugarFactor: number = 1;
  fatFactor: number = 1;
}

// 动态修正配置
export class DynamicModifiers {
  lowStep: DynamicFactor = new DynamicFactor();
  poorSleep: DynamicFactor = new DynamicFactor();
  highBp: DynamicFactor = new DynamicFactor();
  highBs: DynamicFactor = new DynamicFactor();
}

// 营养预算规则类型
export interface NutritionBudgetRule {
  ageGroup: string;
  sodiumBudget: number;
  sugarBudget: number;
  calorieBudget: number;
  fatBudget: number;
  goalAdjustments?: Record<string, GoalAdjustment>;
  dynamicModifiers?: DynamicModifiers;
}

// 美食平衡模板类型
export interface MealBalanceTemplate {
  scenario: string;
  riskTags: string[];
  nextMealAdvice: string;
  avoidStacking: string[];
  hydrationReminder: boolean;
  goalAdvice?: Record<string, string>;
}

// 过敏原关键词映射类型
export class AllergenKeywordMap {
  allergenToKeywords: Record<string, string[]> = {};
  commonAllergens: string[] = [];
}

export class RuleRepository {
  private context: common.Context | null = null;

  // 缓存已加载的规则
  private cache: Map<string, Record<string, Object>> = new Map();

  /**
   * 设置上下文（用于读取rawfile）
   */
  setContext(context: common.Context): void {
    this.context = context;
  }

  /**
   * 加载营养预算规则
   */
  async loadNutritionBudgets(): Promise<NutritionBudgetRule[]> {
    const data = await this.loadJsonFile('nutrition_budgets.json');
    if (data) {
      const budgetsObj = data.budgets as NutritionBudgetRule[];
      if (budgetsObj) {
        return budgetsObj;
      }
    }
    return [];
  }

  /**
   * 根据年龄段查找营养预算
   */
  async findBudgetByAgeGroup(ageGroup: string): Promise<NutritionBudgetRule | null> {
    const budgets = await this.loadNutritionBudgets();
    return budgets.find(b => b.ageGroup === ageGroup) || null;
  }

  /**
   * 加载美食平衡模板
   */
  async loadMealBalanceTemplates(): Promise<MealBalanceTemplate[]> {
    const data = await this.loadJsonFile('meal_balance_templates.json');
    if (data) {
      const templatesObj = data.templates as MealBalanceTemplate[];
      if (templatesObj) {
        return templatesObj;
      }
    }
    return [];
  }

  /**
   * 根据场景查找美食平衡模板
   */
  async findTemplateByScenario(scenario: string): Promise<MealBalanceTemplate | null> {
    const templates = await this.loadMealBalanceTemplates();
    return templates.find(t => t.scenario === scenario) || null;
  }

  /**
   * 加载过敏原关键词映射
   */
  async loadAllergenKeywords(): Promise<AllergenKeywordMap> {
    const data = await this.loadJsonFile('allergen_keywords.json');
    const result = new AllergenKeywordMap();
    if (data) {
      const a2k = data.allergenToKeywords as Record<string, string[]>;
      const ca = data.commonAllergens as string[];
      result.allergenToKeywords = a2k ?? {};
      result.commonAllergens = ca ?? [];
      return result;
    }
    return result;
  }

  /**
   * 检查配料是否命中某过敏原
   */
  async checkAllergenHit(ingredients: string[], allergen: string): Promise<boolean> {
    const keywordMap = await this.loadAllergenKeywords();
    const keywords = keywordMap.allergenToKeywords[allergen] || [];
    for (const ingredient of ingredients) {
      for (const keyword of keywords) {
        if (ingredient.includes(keyword)) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * 清除缓存（规则文件更新时调用）
   */
  clearCache(): void {
    this.cache.clear();
  }

  /**
   * 通用JSON文件加载（带缓存）
   */
  private emptyRecord: Record<string, Object> = {};

  private async loadJsonFile(fileName: string): Promise<Record<string, Object>> {
    // 检查缓存
    const cached = this.cache.get(fileName);
    if (cached) {
      return cached;
    }

    if (!this.context) {
      hilog.error(DOMAIN_ZERO, TAG, 'Context not set');
      return this.emptyRecord;
    }

    try {
      const resMgr = this.context.resourceManager;
      const content = await resMgr.getRawFileContent(fileName);

      // 将字节数组转为字符串
      const textDecoder = util.TextDecoder.create('utf-8');
      const text = textDecoder.decodeWithStream(content, { stream: false });
      const result = JSON.parse(text) as Record<string, Object>;

      // 写入缓存
      this.cache.set(fileName, result);

      hilog.info(DOMAIN_ZERO, TAG, 'Loaded rule file: %{public}s', fileName);
      return result;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Load JSON file %{public}s failed: %{public}s', fileName, JSON.stringify(error));
      return this.emptyRecord;
    }
  }
}