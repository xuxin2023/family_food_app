import { IRuleCalculator, IRuleEngineParams, Recommendation, RecommendLevel, LevelColor, FamilyProfile, HealthSignal, FoodLabel, DailyBudget } from 'hsp_core';

export class RuleEngineParams implements IRuleEngineParams {
  profile: FamilyProfile = new FamilyProfile();
  healthSignal: HealthSignal = new HealthSignal();
  foodLabel: FoodLabel = new FoodLabel();
  dailyBudget: DailyBudget = new DailyBudget();

  constructor(profile?: FamilyProfile, healthSignal?: HealthSignal, foodLabel?: FoodLabel, dailyBudget?: DailyBudget) {
    if (profile) this.profile = profile;
    if (healthSignal) this.healthSignal = healthSignal;
    if (foodLabel) this.foodLabel = foodLabel;
    if (dailyBudget) this.dailyBudget = dailyBudget;
  }
}

export class RuleEngine implements IRuleCalculator {
  calculate(params: IRuleEngineParams): Recommendation {
    const rec = new Recommendation();
    rec.level = RecommendLevel.SUITABLE;
    rec.levelColor = LevelColor.GREEN;
    return rec;
  }
}
