// SmartBasketService.ets
// 智能购物篮服务 — BasketCheckEngine + IngredientAnalysis + LlmChatProxy 三引擎融合
// 对标 Yuka 整篮分析与替代建议

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, FamilyProfile } from 'hsp_core';
import { BasketCheckEngine, BasketCheckResult } from '../engine/BasketCheckEngine';
import { IngredientAnalysisService, IngredientAnalysisResult, HazardItem } from './IngredientAnalysisService';
import { LlmChatProxy, LlmSource } from './ai/LlmChatProxy';

const TAG = 'SmartBasketService';
const DOMAIN = HILOG_DOMAIN_DEFAULT;

export interface SmartBasketItem {
  food: FoodLabel;
  nutriScore: number;
  ingredientRisk: IngredientAnalysisResult | null;
  level: 'safe' | 'caution' | 'avoid';
}

export interface SmartBasketResult {
  items: SmartBasketItem[];
  totalItems: number;
  safeCount: number;
  cautionCount: number;
  avoidCount: number;
  basketCheck: BasketCheckResult;
  overallScore: number;
  aiAdvice: string;
  topSwaps: SwapSuggestion[];
  generatedAt: number;
}

export interface SwapSuggestion {
  avoidFoodName: string;
  reason: string;
  betterAlternative: string;
  benefit: string;
}

export class SmartBasketService {
  private static instance: SmartBasketService | null = null;
  private basketEngine: BasketCheckEngine;
  private ingredientService: IngredientAnalysisService;
  private llmProxy: LlmChatProxy;

  private constructor() {
    this.basketEngine = new BasketCheckEngine();
    this.ingredientService = IngredientAnalysisService.getInstance();
    this.llmProxy = LlmChatProxy.getInstance();
  }

  static getInstance(): SmartBasketService {
    if (!SmartBasketService.instance) {
      SmartBasketService.instance = new SmartBasketService();
    }
    return SmartBasketService.instance;
  }

  async analyze(items: FoodLabel[], profiles: FamilyProfile[]): Promise<SmartBasketResult> {
    const smartItems: SmartBasketItem[] = [];
    let safeCount = 0, cautionCount = 0, avoidCount = 0;

    for (const food of items) {
      let ingredientRisk: IngredientAnalysisResult | null = null;
      try {
        ingredientRisk = await this.ingredientService.analyze(food);
      } catch (_) { /* fallback */ }

      let level: SmartBasketItem['level'] = 'safe';
      if (ingredientRisk) {
        const risk = ingredientRisk.overallRisk;
        if (risk === 'critical' || risk === 'high') { level = 'avoid'; avoidCount++; }
        else if (risk === 'medium') { level = 'caution'; cautionCount++; }
        else { level = 'safe'; safeCount++; }
      } else {
        safeCount++;
      }

      let nutriScore = food.nutriScore ?? 50;

      smartItems.push({ food, nutriScore, ingredientRisk, level });
    }

    const basketCheck = this.basketEngine.check(items, profiles);

    const avoidItems = smartItems.filter(i => i.level === 'avoid');
    const topSwaps: SwapSuggestion[] = avoidItems.slice(0, 3).map(item => ({
      avoidFoodName: item.food.foodName,
      reason: item.ingredientRisk?.highRiskCount
        ? `${item.ingredientRisk.highRiskCount}种高风险添加剂`
        : '综合评分偏低',
      betterAlternative: this.findQuickAlternative(item.food),
      benefit: '配料更简洁、评分更高',
    }));

    const overallScore = Math.round(
      smartItems.reduce((s: number, i: SmartBasketItem) => s + i.nutriScore, 0) / Math.max(1, items.length)
    );

    let aiAdvice = this.generateLocalAdvice(basketCheck, avoidItems.length);
    try {
      const question = `购物篮总览: ${smartItems.length}件商品, ${avoidCount}件需避免。高钠${basketCheck.highSodiumCount}件, 高糖${basketCheck.highSugarCount}件, 高脂${basketCheck.highFatCount}件。请给出一句话健康建议。`;
      const resp = await this.llmProxy.chat({
        question, context: [], memberId: profiles[0]?.memberId ?? '',
        analysisType: 'general', preferOffline: false,
      });
      if (resp && resp.source !== LlmSource.FALLBACK_TEMPLATE) {
        aiAdvice = resp.answer;
      }
    } catch (_) { /* use local */ }

    return {
      items: smartItems, totalItems: items.length,
      safeCount, cautionCount, avoidCount,
      basketCheck, overallScore, aiAdvice, topSwaps,
      generatedAt: Date.now(),
    };
  }

  private generateLocalAdvice(basket: BasketCheckResult, avoidCount: number): string {
    const parts: string[] = [];
    if (basket.highSodiumCount > 2) parts.push(`含${basket.highSodiumCount}件高钠食品`);
    if (basket.highSugarCount > 2) parts.push(`${basket.highSugarCount}件高糖食品`);
    if (avoidCount > 0) parts.push(`${avoidCount}件含高风险添加剂`);
    if (parts.length === 0) return '购物篮总体健康，营养均衡 ✓';
    return `建议: ${parts.join('、')}，可考虑替换`;
  }

  private findQuickAlternative(food: FoodLabel): string {
    const name = food.foodName;
    if (name.includes('薯片')) return '原味海苔';
    if (name.includes('饼干')) return '全麦饼干';
    if (name.includes('方便面')) return '荞麦面';
    if (name.includes('果冻')) return '鲜果杯';
    if (name.includes('饮料') || name.includes('汽水')) return '无糖茶饮';
    if (name.includes('蛋糕') || name.includes('面包')) return '全麦吐司';
    if (name.includes('香肠') || name.includes('火腿')) return '鸡胸肉';
    if (name.includes('辣条')) return '原味坚果';
    return '更健康的选择';
  }
}