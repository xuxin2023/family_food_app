// ParsedIngredient.ets
// 成分有害性解析模型 — 对标Yuka成分解析功能

export enum HazardLevel {
  SAFE = 'safe',
  LOW_RISK = 'low_risk',
  MODERATE_RISK = 'moderate_risk',
  HIGH_RISK = 'high_risk',
  HAZARDOUS = 'hazardous'
}

export class ParsedIngredient {
  name: string = '';
  originalText: string = '';
  role: string = '';
  hazardLevel: HazardLevel = HazardLevel.LOW_RISK;
  hazardDetail: string = '';
  eNumber: string = '';
  approved: boolean = true;
  vegan: boolean = true;
  organic: boolean = false;
  source: string = '';
  dailyMaxMg: number = 0;
}

export class AdditiveHazard {
  name: string = '';
  eNumber: string = '';
  hazardLevel: HazardLevel = HazardLevel.LOW_RISK;
  category: string = '';
  description: string = '';
  longTermEffect: string = '';
  coWarning: string = '';
  regulationStatus: string = '';
}

export class ParsedIngredientList {
  productBarcode: string = '';
  productName: string = '';
  ingredients: ParsedIngredient[] = [];
  highRiskCount: number = 0;
  moderateRiskCount: number = 0;
  summary: string = '';
  additiveInteractions: string[] = [];
  parsedAt: number = 0;
}

export function hazardLevelToLabel(level: HazardLevel): string {
  switch (level) {
    case HazardLevel.SAFE: return '安全';
    case HazardLevel.LOW_RISK: return '低风险';
    case HazardLevel.MODERATE_RISK: return '中等风险';
    case HazardLevel.HIGH_RISK: return '高风险';
    case HazardLevel.HAZARDOUS: return '有害';
    default: return '未知';
  }
}

export function hazardLevelToColor(level: HazardLevel): string {
  switch (level) {
    case HazardLevel.SAFE: return '#4CAF50';
    case HazardLevel.LOW_RISK: return '#8BC34A';
    case HazardLevel.MODERATE_RISK: return '#FFC107';
    case HazardLevel.HIGH_RISK: return '#FF9800';
    case HazardLevel.HAZARDOUS: return '#F44336';
    default: return '#9E9E9E';
  }
}