// 今日预算数据模型
// V2 状态管理: @ObservedV2 + @Trace

// DailyBudget JSON 输出类
export class DailyBudgetJson {
  memberId: string = '';
  date: string = '';
  sodiumBudget: number = 0;
  sodiumRemaining: number = 0;
  sugarBudget: number = 0;
  sugarRemaining: number = 0;
  calorieBudget: number = 0;
  calorieRemaining: number = 0;
  fatBudget: number = 0;
  fatRemaining: number = 0;
}

@ObservedV2
export class DailyBudget {
  @Trace memberId: string = '';
  @Trace date: string = '';              // YYYY-MM-DD
  @Trace sodiumBudget: number = 2000;    // 钠预算总量 mg
  @Trace sodiumRemaining: number = 2000; // 钠剩余额度 mg
  @Trace sugarBudget: number = 50;       // 糖预算总量 g
  @Trace sugarRemaining: number = 50;    // 糖剩余额度 g
  @Trace calorieBudget: number = 2000;   // 热量预算总量 kcal
  @Trace calorieRemaining: number = 2000;// 热量剩余额度 kcal
  @Trace fatBudget: number = 65;         // 脂肪预算总量 g
  @Trace fatRemaining: number = 65;      // 脂肪剩余额度 g

  // 钠预算使用百分比
  sodiumUsagePercent(): number {
    if (this.sodiumBudget === 0) return 100;
    return Math.max(0, Math.min(100, ((this.sodiumBudget - this.sodiumRemaining) / this.sodiumBudget) * 100));
  }

  // 糖预算使用百分比
  sugarUsagePercent(): number {
    if (this.sugarBudget === 0) return 100;
    return Math.max(0, Math.min(100, ((this.sugarBudget - this.sugarRemaining) / this.sugarBudget) * 100));
  }

  // 热量预算使用百分比
  calorieUsagePercent(): number {
    if (this.calorieBudget === 0) return 100;
    return Math.max(0, Math.min(100, ((this.calorieBudget - this.calorieRemaining) / this.calorieBudget) * 100));
  }

  // 脂肪预算使用百分比
  fatUsagePercent(): number {
    if (this.fatBudget === 0) return 100;
    return Math.max(0, Math.min(100, ((this.fatBudget - this.fatRemaining) / this.fatBudget) * 100));
  }

  // 钠预算是否耗尽
  isSodiumExhausted(): boolean {
    return this.sodiumRemaining <= 0;
  }

  // 糖预算是否耗尽
  isSugarExhausted(): boolean {
    return this.sugarRemaining <= 0;
  }

  // 扣减摄入量（有下限保护，避免显示负值）
  deductIntake(sodium: number, sugar: number, calories: number, fat: number): void {
    this.sodiumRemaining = Math.max(0, this.sodiumRemaining - sodium);
    this.sugarRemaining = Math.max(0, this.sugarRemaining - sugar);
    this.calorieRemaining = Math.max(0, this.calorieRemaining - calories);
    this.fatRemaining = Math.max(0, this.fatRemaining - fat);
  }

  toJson(): DailyBudgetJson {
    const json = new DailyBudgetJson();
    json.memberId = this.memberId;
    json.date = this.date;
    json.sodiumBudget = this.sodiumBudget;
    json.sodiumRemaining = this.sodiumRemaining;
    json.sugarBudget = this.sugarBudget;
    json.sugarRemaining = this.sugarRemaining;
    json.calorieBudget = this.calorieBudget;
    json.calorieRemaining = this.calorieRemaining;
    json.fatBudget = this.fatBudget;
    json.fatRemaining = this.fatRemaining;
    return json;
  }

  static fromJson(json: DailyBudgetJson): DailyBudget {
    const budget = new DailyBudget();
    budget.memberId = json.memberId;
    budget.date = json.date;
    budget.sodiumBudget = json.sodiumBudget;
    budget.sodiumRemaining = json.sodiumRemaining;
    budget.sugarBudget = json.sugarBudget;
    budget.sugarRemaining = json.sugarRemaining;
    budget.calorieBudget = json.calorieBudget;
    budget.calorieRemaining = json.calorieRemaining;
    budget.fatBudget = json.fatBudget;
    budget.fatRemaining = json.fatRemaining;
    return budget;
  }
}
