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

export class RuleEngineAdapter implements IRuleCalculator {
  private delegate: IRuleCalculator | null = null;

  setDelegate(engine: IRuleCalculator): void {
    this.delegate = engine;
  }

  calculate(params: IRuleEngineParams): Recommendation {
    if (this.delegate !== null) {
      return this.delegate.calculate(params);
    }
    const rec: Recommendation = new Recommendation()
    rec.level = RecommendLevel.SUITABLE;
    rec.levelColor = LevelColor.GREEN;
    return rec;
  }
}
