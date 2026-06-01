import { hilog } from '@kit.PerformanceAnalysisKit';
import { FoodLabel } from 'hsp_core';

const TAG = 'ScanHistoryAdvancedService';
const DOMAIN_ZERO = 0x0001;

export interface ScanHistoryFilter {
  startDate?: string;
  endDate?: string;
  nutriScoreRange?: [string, string];
  hasAllergenHit?: boolean;
  hasIntoleranceHit?: boolean;
  memberId?: string;
  keyword?: string;
}

export interface ScanHistoryStats {
  totalScans: number;
  avgNutriScore: number;
  allergenHitRate: number;
  topAllergens: string[];
  scoreDistribution: Map<string, number>;
}

export class ScanHistoryAdvancedService {
  filterHistory(records: ScanHistoryRecord[], filter: ScanHistoryFilter): ScanHistoryRecord[] {
    let result = records;
    if (filter.startDate) {
      result = result.filter(r => r.scanDate >= filter.startDate!);
    }
    if (filter.endDate) {
      result = result.filter(r => r.scanDate <= filter.endDate!);
    }
    if (filter.nutriScoreRange) {
      const scores = ['A', 'B', 'C', 'D', 'E'];
      const startIdx = scores.indexOf(filter.nutriScoreRange[0]);
      const endIdx = scores.indexOf(filter.nutriScoreRange[1]);
      const validScores = scores.slice(Math.min(startIdx, endIdx), Math.max(startIdx, endIdx) + 1);
      result = result.filter(r => validScores.includes(r.nutriScore));
    }
    if (filter.hasAllergenHit === true) {
      result = result.filter(r => r.allergenHits && r.allergenHits.length > 0);
    }
    if (filter.hasIntoleranceHit === true) {
      result = result.filter(r => r.intoleranceHits && r.intoleranceHits.length > 0);
    }
    if (filter.memberId) {
      result = result.filter(r => r.memberId === filter.memberId);
    }
    if (filter.keyword) {
      const kw = filter.keyword.toLowerCase();
      result = result.filter(r => r.foodName.toLowerCase().includes(kw));
    }
    return result;
  }

  calculateStats(records: ScanHistoryRecord[]): ScanHistoryStats {
    const scoreMap: Map<string, number> = new Map();
    let totalScore = 0;
    let allergenHitCount = 0;
    const allergenCountMap: Map<string, number> = new Map();
    for (const r of records) {
      const scoreNum = this.scoreToNumber(r.nutriScore);
      totalScore += scoreNum;
      const prev = scoreMap.get(r.nutriScore) ?? 0;
      scoreMap.set(r.nutriScore, prev + 1);
      if (r.allergenHits && r.allergenHits.length > 0) {
        allergenHitCount++;
        for (const a of r.allergenHits) {
          const ac = allergenCountMap.get(a) ?? 0;
          allergenCountMap.set(a, ac + 1);
        }
      }
    }
    const sortedAllergens = Array.from(allergenCountMap.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(e => e[0]);
    return {
      totalScans: records.length,
      avgNutriScore: records.length > 0 ? totalScore / records.length : 0,
      allergenHitRate: records.length > 0 ? allergenHitCount / records.length : 0,
      topAllergens: sortedAllergens,
      scoreDistribution: scoreMap
    };
  }

  exportToCsv(records: ScanHistoryRecord[]): string {
    const header = '扫描日期,食品名称,条码,NutriScore,Nova分组,过敏原命中,不耐受命中,成员ID';
    const rows = records.map(r => {
      const allergens = (r.allergenHits ?? []).join(';');
      const intolerances = (r.intoleranceHits ?? []).join(';');
      return `${r.scanDate},${r.foodName},${r.barcode},${r.nutriScore},${r.novaGroup},${allergens},${intolerances},${r.memberId}`;
    });
    return [header, ...rows].join('\n');
  }

  private scoreToNumber(score: string): number {
    const map: Record<string, number> = { 'A': 5, 'B': 4, 'C': 3, 'D': 2, 'E': 1 };
    return map[score] ?? 3;
  }
}

export interface ScanHistoryRecord {
  scanDate: string;
  foodName: string;
  barcode: string;
  nutriScore: string;
  novaGroup: number;
  allergenHits: string[];
  intoleranceHits: string[];
  memberId: string;
}