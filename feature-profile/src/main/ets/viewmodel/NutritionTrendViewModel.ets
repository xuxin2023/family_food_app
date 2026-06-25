// feature-profile: 营养趋势ViewModel
// 管理营养趋势图表数据

import { NutritionSnapshot, NutritionDaily, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NutritionTrendViewModel';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@ObservedV2
export class NutritionTrendViewModel {
  @Trace isLoading: boolean = false;
  @Trace dailyRecords: NutritionDaily[] = [];
  @Trace avgCalories: number = 0;
  @Trace avgSodium: number = 0;
  @Trace avgSugar: number = 0;
  @Trace avgFat: number = 0;
  @Trace avgProtein: number = 0;
  @Trace calorieTrend: number = 0;
  @Trace sodiumTrend: number = 0;
  @Trace sugarTrend: number = 0;
  @Trace startDate: string = '';
  @Trace endDate: string = '';

  loadFromDailyRecords(records: NutritionDaily[]): void {
    this.isLoading = false;
    this.dailyRecords = records.slice(0, 7);

    if (records.length === 0) {
      return;
    }

    let totalCal = 0;
    let totalSod = 0;
    let totalSug = 0;
    let totalFat = 0;
    let totalPro = 0;
    const len: number = records.length;
    for (let i = 0; i < len; i++) {
      const r: NutritionDaily = records[i];
      totalCal += r.totalCalories;
      totalSod += r.totalSodium_mg;
      totalSug += r.totalSugar_g;
      totalFat += r.totalFat_g;
      totalPro += r.totalProtein_g;
    }
    this.avgCalories = Math.round(totalCal / len);
    this.avgSodium = Math.round(totalSod / len);
    this.avgSugar = Math.round(totalSug / len * 10) / 10;
    this.avgFat = Math.round(totalFat / len * 10) / 10;
    this.avgProtein = Math.round(totalPro / len * 10) / 10;

    if (records.length >= 2) {
      const last: NutritionDaily = records[len - 1];
      const prev: NutritionDaily = records[len - 2];
      this.calorieTrend = this.compareValues(last.totalCalories, prev.totalCalories);
      this.sodiumTrend = this.compareValues(last.totalSodium_mg, prev.totalSodium_mg);
      this.sugarTrend = this.compareValues(last.totalSugar_g, prev.totalSugar_g);
    }
  }

  reset(): void {
    this.isLoading = true;
    this.dailyRecords = [];
    this.avgCalories = 0;
    this.avgSodium = 0;
    this.avgSugar = 0;
    this.avgFat = 0;
    this.avgProtein = 0;
    this.calorieTrend = 0;
    this.sodiumTrend = 0;
    this.sugarTrend = 0;
    this.startDate = '';
    this.endDate = '';
  }

  private compareValues(current: number, previous: number): number {
    const diff: number = current - previous;
    if (Math.abs(diff) < 1) return 0;
    return diff > 0 ? 1 : -1;
  }
}
