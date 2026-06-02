// NutritionDaily.ets
// 营养日汇总模型 — 对标Yuka/Olive营养追踪功能

export class NutritionDaily {
  id: number = 0;
  memberId: string = '';
  date: string = '';
  totalCalories: number = 0;
  totalSodium_mg: number = 0;
  totalSugar_g: number = 0;
  totalFat_g: number = 0;
  totalSaturatedFat_g: number = 0;
  totalProtein_g: number = 0;
  totalCarbohydrate_g: number = 0;
  totalFiber_g: number = 0;
  scanCount: number = 0;
  scoreAvg: number = 0;
  updatedAt: number = 0;

  addEntry(calories: number, sodium: number, sugar: number, fat: number, satFat: number,
    protein: number, carb: number, fiber: number, score: number): void {
    this.totalCalories += calories;
    this.totalSodium_mg += sodium;
    this.totalSugar_g += sugar;
    this.totalFat_g += fat;
    this.totalSaturatedFat_g += satFat;
    this.totalProtein_g += protein;
    this.totalCarbohydrate_g += carb;
    this.totalFiber_g += fiber;
    this.scanCount += 1;
    this.scoreAvg = ((this.scoreAvg * (this.scanCount - 1)) + score) / this.scanCount;
    this.updatedAt = Date.now();
  }

  static createForDate(memberId: string, date: string): NutritionDaily {
    const d = new NutritionDaily();
    d.memberId = memberId;
    d.date = date;
    d.updatedAt = Date.now();
    return d;
  }
}