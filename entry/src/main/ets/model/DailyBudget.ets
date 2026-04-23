// 今日预算数据模型

// DailyBudget JSON 输出类
export class DailyBudgetJson {
  memberId: Object = '';
  date: Object = '';
  sodiumBudget: Object = 0;
  sodiumRemaining: Object = 0;
  sugarBudget: Object = 0;
  sugarRemaining: Object = 0;
  calorieBudget: Object = 0;
  calorieRemaining: Object = 0;
  fatBudget: Object = 0;
  fatRemaining: Object = 0;
}

export class DailyBudget {
  memberId: string = '';
  date: string = '';              // YYYY-MM-DD
  sodiumBudget: number = 2000;    // 钠预算总量 mg
  sodiumRemaining: number = 2000; // 钠剩余额度 mg
  sugarBudget: number = 50;       // 糖预算总量 g
  sugarRemaining: number = 50;    // 糖剩余额度 g
  calorieBudget: number = 2000;   // 热量预算总量 kcal
  calorieRemaining: number = 2000;// 热量剩余额度 kcal
  fatBudget: number = 65;         // 脂肪预算总量 g
  fatRemaining: number = 65;      // 脂肪剩余额度 g

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

  // 扣减摄入量
  deductIntake(sodium: number, sugar: number, calories: number, fat: number): void {
    this.sodiumRemaining -= sodium;
    this.sugarRemaining -= sugar;
    this.calorieRemaining -= calories;
    this.fatRemaining -= fat;
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

  static fromJson(json: Record<string, Object>): DailyBudget {
    const budget = new DailyBudget();
    budget.memberId = json.memberId as string;
    budget.date = json.date as string;
    budget.sodiumBudget = json.sodiumBudget as number;
    budget.sodiumRemaining = json.sodiumRemaining as number;
    budget.sugarBudget = json.sugarBudget as number;
    budget.sugarRemaining = json.sugarRemaining as number;
    budget.calorieBudget = json.calorieBudget as number;
    budget.calorieRemaining = json.calorieRemaining as number;
    budget.fatBudget = json.fatBudget as number;
    budget.fatRemaining = json.fatRemaining as number;
    return budget;
  }
}
