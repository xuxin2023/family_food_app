// WeeklyReport.ets
// 周报数据模型 — 从 WeeklyReportEngine 提取至 hsp_core，实现 service→engine 依赖反转

export class NutrientComparison {
  name: string = '';
  nutrientName: string = '';
  thisWeekAvg: number = 0;
  lastWeekAvg: number = 0;
  dailyAvg: number = 0;
  target: number = 0;
  unit: string = '';
  changePercent: number = 0;
  status: NutrientStatus = NutrientStatus.GOOD;
}

export enum NutrientStatus {
  EXCELLENT = 'excellent',
  GOOD = 'good',
  WARNING = 'warning',
  OVER = 'over'
}

export class WeeklyDietData {
  memberId: string = '';
  weekStart: string = '';
  weekEnd: string = '';
  totalScans: number = 0;
  highSodiumDays: number = 0;
  highSugarDays: number = 0;
  highFatDays: number = 0;
  sweetNearMealCount: number = 0;
  lateNightSnackCount: number = 0;
  heavyFlavorCount: number = 0;
  childSnackOverLimit: number = 0;
}

export class WeeklyReport {
  memberId: string = '';
  memberName: string = '';
  weekRange: string = '';
  summary: string = '';
  highlights: string[] = [];
  suggestions: string[] = [];
  buyLess: string[] = [];
  buyMore: string[] = [];
  nutrientComparisons: NutrientComparison[] = [];
  nutrientStatuses: NutrientStatus[] = [];
}

export class PurchaseAdvice {
  buyLess: string[] = [];
  buyMore: string[] = [];
}
