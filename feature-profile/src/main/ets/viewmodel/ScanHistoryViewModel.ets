// feature-profile: 扫描历史ViewModel
// 管理扫描历史列表数据

import { FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ScanHistoryViewModel';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class ScanHistoryGroup {
  date: string = '';
  items: FoodLabel[] = [];
}

@ObservedV2
export class ScanHistoryViewModel {
  @Trace isLoading: boolean = false;
  @Trace allScans: FoodLabel[] = [];
  @Trace groupedScans: ScanHistoryGroup[] = [];
  @Trace totalScans: number = 0;
  @Trace todayScans: number = 0;
  @Trace weekScans: number = 0;
  @Trace searchKeyword: string = '';

  loadFromScanHistory(scans: FoodLabel[]): void {
    this.isLoading = false;
    this.allScans = scans;
    this.totalScans = scans.length;
    this.groupedScans = this.groupByDate(scans);
    this.calculateStats(scans);
  }

  filterByKeyword(keyword: string): void {
    this.searchKeyword = keyword;
    if (keyword.length === 0) {
      this.groupedScans = this.groupByDate(this.allScans);
      return;
    }
    const lower: string = keyword.toLowerCase();
    const filtered: FoodLabel[] = this.allScans.filter((item: FoodLabel) => {
      return item.foodName.toLowerCase().includes(lower) ||
        item.barcode.includes(keyword);
    });
    this.groupedScans = this.groupByDate(filtered);
  }

  reset(): void {
    this.isLoading = true;
    this.allScans = [];
    this.groupedScans = [];
    this.totalScans = 0;
    this.todayScans = 0;
    this.weekScans = 0;
    this.searchKeyword = '';
  }

  private groupByDate(scans: FoodLabel[]): ScanHistoryGroup[] {
    const groups: ScanHistoryGroup[] = [];
    const groupMap: Map<string, FoodLabel[]> = new Map();

    for (let i = 0; i < scans.length; i++) {
      const scan: FoodLabel = scans[i];
      const dateKey: string = this.formatDate(scan.identifiedAt);
      const existing: FoodLabel[] | undefined = groupMap.get(dateKey);
      if (existing !== undefined) {
        existing.push(scan);
      } else {
        groupMap.set(dateKey, [scan]);
      }
    }

    groupMap.forEach((items: FoodLabel[], date: string) => {
      const group: ScanHistoryGroup = new ScanHistoryGroup();
      group.date = date;
      group.items = items;
      groups.push(group);
    });

    groups.sort((a: ScanHistoryGroup, b: ScanHistoryGroup) => {
      return b.date.localeCompare(a.date);
    });

    return groups;
  }

  private calculateStats(scans: FoodLabel[]): void {
    const now: number = Date.now();
    const oneDayMs: number = 24 * 60 * 60 * 1000;
    const sevenDaysMs: number = 7 * oneDayMs;

    let today = 0;
    let week = 0;
    for (let i = 0; i < scans.length; i++) {
      const scan: FoodLabel = scans[i];
      const age: number = now - scan.identifiedAt;
      if (age < oneDayMs) today++;
      if (age < sevenDaysMs) week++;
    }
    this.todayScans = today;
    this.weekScans = week;
  }

  private formatDate(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const year: number = date.getFullYear();
    const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
    const day: string = date.getDate().toString().padStart(2, '0');
    return year + '-' + month + '-' + day;
  }
}
