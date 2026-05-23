// IRecommendationEngine.ets
// 规则引擎 + 替代推荐接口 — 从 RuleEngine / AlternativeFoodRecommender 提取，供 DataService 依赖反转

import { FamilyProfile } from './FamilyProfile';
import { HealthSignal } from './HealthSignal';
import { FoodLabel } from './FoodLabel';
import { DailyBudget } from './DailyBudget';
import { Recommendation } from './Recommendation';
import { AlternativeFood } from './FoodAdapterTypes';

export interface IRuleCalculator {
  calculate(params: IRuleEngineParams): Recommendation;
}

export interface IRuleEngineParams {
  profile: FamilyProfile;
  healthSignal: HealthSignal;
  foodLabel: FoodLabel;
  dailyBudget: DailyBudget;
}

export interface IAlternativeRecommender {
  recommendAlternatives(foodLabel: FoodLabel, members: FamilyProfile[], topN: number): AlternativeFood[];
}
