// 规则仓库 - 加载JSON规则文件（带缓存）

import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog, util } from '@kit.BasicServicesKit';

const TAG = 'RuleRepository';
const DOMAIN_ZERO = 0;

// 营养预算规则类型
export interface NutritionBudgetRule {
  ageGroup: string;
  sodiumBudget: number;
  sugarBudget: number;
  calorieBudget: number;
  fatBudget: number;
  goalAdjustments?: Record<string, { sodium?: number; sugar?: number; calorie?: number; fat?: number }>;
  dynamicModifiers?: {
    lowStep?: { sodiumFactor: number; calorieFactor: number };
    poorSleep?: { sugarFactor: number; fatFactor: number };
    highBp?: { sodiumFactor: number };
    highBs?: { sugarFactor: number };
  };
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
export interface AllergenKeywordMap {
  allergenToKeywords: Record<string, string[]>;
  commonAllergens: string[];
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
    if (data && data['budgets']) {
      return data['budgets'] as NutritionBudgetRule[];
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
    if (data && data['templates']) {
      return data['templates'] as MealBalanceTemplate[];
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
    if (data) {
      return {
        allergenToKeywords: (data['allergenToKeywords'] || {}) as Record<string, string[]>,
        commonAllergens: (data['commonAllergens'] || []) as string[]
      };
    }
    return { allergenToKeywords: {}, commonAllergens: [] };
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
  private async loadJsonFile(fileName: string): Promise<Record<string, Object>> {
    // 检查缓存
    const cached = this.cache.get(fileName);
    if (cached) {
      return cached;
    }

    if (!this.context) {
      hilog.error(DOMAIN_ZERO, TAG, 'Context not set');
      return {};
    }

    try {
      const resMgr = this.context.resourceManager;
      const content = await resMgr.getRawFileContent(fileName);

      // 将字节数组转为字符串
      const textDecoder = util.TextDecoder.create('utf-8');
      const text = textDecoder.decodeToString(content);
      const result = JSON.parse(text) as Record<string, Object>;

      // 写入缓存
      this.cache.set(fileName, result);

      hilog.info(DOMAIN_ZERO, TAG, 'Loaded rule file: %{public}s', fileName);
      return result;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Load JSON file %{public}s failed: %{public}s', fileName, JSON.stringify(error));
      return {};
    }
  }
}
