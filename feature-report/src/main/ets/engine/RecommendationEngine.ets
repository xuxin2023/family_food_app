// 适配计算引擎 - 封装规则引擎，提供高层API

import { FamilyProfile, HealthSignal, FoodLabel, DailyBudget, Recommendation } from 'hsp_core';
import { RuleEngine, RuleEngineParams } from './RuleEngine';

export class RecommendationEngine {
  private ruleEngine: RuleEngine = new RuleEngine();

  // 计算单个成员适配结论
  calculateForMember(
    profile: FamilyProfile,
    healthSignal: HealthSignal,
    foodLabel: FoodLabel,
    dailyBudget: DailyBudget
  ): Recommendation {
    const params: RuleEngineParams = new RuleEngineParams(profile, healthSignal, foodLabel, dailyBudget);
    return this.ruleEngine.calculate(params);
  }

  // 计算家庭对比（同一食品对多成员）
  calculateFamilyComparison(
    profiles: FamilyProfile[],
    healthSignals: HealthSignal[],
    foodLabel: FoodLabel,
    dailyBudgets: DailyBudget[]
  ): Recommendation[] {
    const results: Recommendation[] = [];
    for (let i = 0; i < profiles.length; i++) {
      const params: RuleEngineParams = new RuleEngineParams(profiles[i], healthSignals[i], foodLabel, dailyBudgets[i]);
      results.push(this.ruleEngine.calculate(params));
    }
    return results;
  }

  // 生成家庭对比摘要文本
  generateFamilySummary(recommendations: Recommendation[], profiles: FamilyProfile[]): string {
    const lines: string[] = [];
    for (let i = 0; i < recommendations.length; i++) {
      const rec = recommendations[i];
      const profile = profiles[i];
      const amountText = rec.maxAmount > 0 ? `最多${rec.maxAmount}g` : '建议避免';
      lines.push(`${profile.nickname}：${rec.level}，${amountText}`);
    }
    return lines.join('；');
  }
}
