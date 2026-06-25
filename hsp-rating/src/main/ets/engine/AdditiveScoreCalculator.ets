// AdditiveScoreCalculator.ets
// Yuka 风格添加剂风险评分 — 红/橙/黄三级扣分规则
// 规则: 红色(AVOID)添加剂存在 → 封顶49分；橙色(CAUTION)每个扣5分；无添加剂满分100

import { FoodLabel } from 'hsp_core';

export enum AdditiveRiskLevelV2 {
  SAFE = 'safe',
  CAUTION = 'caution',
  AVOID = 'avoid',
  UNKNOWN = 'unknown'
}

export class AdditiveScoreAssessment {
  eNumber: string = '';
  name: string = '';
  riskLevel: AdditiveRiskLevelV2 = AdditiveRiskLevelV2.UNKNOWN;
}

class AdditiveDBEntry {
  name: string = '';
  risk: AdditiveRiskLevelV2 = AdditiveRiskLevelV2.UNKNOWN;
}

export class AdditiveScoreResult {
  score: number = 100;
  avoidCount: number = 0;
  cautionCount: number = 0;
  unknownCount: number = 0;
  totalAdditives: number = 0;
  assessments: AdditiveScoreAssessment[] = [];
  cappedAt49: boolean = false;
}

const AVOID_PENALTY_CAP = 49;
const CAUTION_PENALTY_EACH = 5;
const UNKNOWN_PENALTY_EACH = 1;

export class AdditiveScoreCalculator {
  static calculate(assessments: AdditiveScoreAssessment[]): AdditiveScoreResult {
    const result: AdditiveScoreResult = new AdditiveScoreResult();
    result.assessments = assessments;
    result.totalAdditives = assessments.length;

    let avoidCount = 0;
    let cautionCount = 0;
    let unknownCount = 0;

    for (let i = 0; i < assessments.length; i++) {
      const a = assessments[i];
      if (a.riskLevel === AdditiveRiskLevelV2.AVOID) {
        avoidCount++;
      } else if (a.riskLevel === AdditiveRiskLevelV2.CAUTION) {
        cautionCount++;
      } else if (a.riskLevel === AdditiveRiskLevelV2.UNKNOWN) {
        unknownCount++;
      }
    }

    result.avoidCount = avoidCount;
    result.cautionCount = cautionCount;
    result.unknownCount = unknownCount;

    let score = 100;
    score -= cautionCount * CAUTION_PENALTY_EACH;
    score -= unknownCount * UNKNOWN_PENALTY_EACH;

    if (avoidCount > 0) {
      score = Math.min(score, AVOID_PENALTY_CAP);
      result.cappedAt49 = true;
    }

    result.score = Math.max(0, Math.min(100, score));
    return result;
  }

  static calculateFromIngredients(ingredients: string[]): AdditiveScoreResult {
    const assessments: AdditiveScoreAssessment[] = AdditiveScoreCalculator.parseAdditives(ingredients);
    return AdditiveScoreCalculator.calculate(assessments);
  }

  static parseAdditives(ingredients: string[]): AdditiveScoreAssessment[] {
    const assessments: AdditiveScoreAssessment[] = [];
    const ePattern = /E(\d{3,4}[a-z]?)/gi;
    let match: RegExpExecArray | null;
    const text = ingredients.join(', ');

    const regex = new RegExp(ePattern);
    const seen: Set<string> = new Set();

    while ((match = regex.exec(text)) !== null) {
      const eNum = 'E' + match[1].toUpperCase();
      if (seen.has(eNum)) continue;
      seen.add(eNum);

      const risk = AdditiveScoreCalculator.getRiskLevel(eNum);
      const assessment: AdditiveScoreAssessment = new AdditiveScoreAssessment();
      assessment.eNumber = eNum;
      assessment.name = AdditiveScoreCalculator.getAdditiveName(eNum);
      assessment.riskLevel = risk;
      assessments.push(assessment);
    }

    return assessments;
  }

  private static additiveDB: Map<string, AdditiveDBEntry> = AdditiveScoreCalculator.buildDB();

  private static buildDB(): Map<string, AdditiveDBEntry> {
    const db: Map<string, AdditiveDBEntry> = new Map();
    const entries: string[] = [
      'E102|柠檬黄|caution', 'E104|喹啉黄|avoid', 'E110|日落黄|caution',
      'E120|胭脂红|avoid', 'E122|胭脂红4R|caution', 'E124|丽春红4R|avoid',
      'E129|诱惑红AC|caution', 'E131|专利蓝V|avoid', 'E133|亮蓝FCF|safe',
      'E150A|焦糖色I|safe', 'E150D|焦糖色IV|caution', 'E171|二氧化钛|avoid',
      'E200|山梨酸|safe', 'E211|苯甲酸钠|caution', 'E220|二氧化硫|caution',
      'E250|亚硝酸钠|avoid', 'E251|硝酸钠|avoid', 'E280|丙酸|safe',
      'E300|抗坏血酸|safe', 'E320|BHA|avoid', 'E321|BHT|caution',
      'E322|卵磷脂|safe', 'E330|柠檬酸|safe', 'E334|酒石酸|safe',
      'E407|卡拉胶|caution', 'E412|瓜尔胶|safe', 'E415|黄原胶|safe',
      'E450|磷酸盐|caution', 'E471|脂肪酸单双甘油酯|safe',
      'E621|谷氨酸钠|caution', 'E627|鸟苷酸二钠|safe', 'E631|肌苷酸二钠|safe',
      'E950|安赛蜜|safe', 'E951|阿斯巴甜|caution', 'E952|糖精钠|caution',
      'E954|三氯蔗糖|safe', 'E955|三氯半乳蔗糖|safe', 'E960|甜菊糖苷|safe',
      'E965|麦芽糖醇|safe', 'E967|木糖醇|safe'
    ];
    for (let i = 0; i < entries.length; i++) {
      const parts = entries[i].split('|');
      const entry: AdditiveDBEntry = new AdditiveDBEntry();
      entry.name = parts[1];
      entry.risk = AdditiveScoreCalculator.parseRisk(parts[2]);
      db.set(parts[0], entry);
    }
    return db;
  }

  private static parseRisk(s: string): AdditiveRiskLevelV2 {
    if (s === 'safe') return AdditiveRiskLevelV2.SAFE;
    if (s === 'caution') return AdditiveRiskLevelV2.CAUTION;
    if (s === 'avoid') return AdditiveRiskLevelV2.AVOID;
    return AdditiveRiskLevelV2.UNKNOWN;
  }

  private static getRiskLevel(eNumber: string): AdditiveRiskLevelV2 {
    const entry = AdditiveScoreCalculator.additiveDB.get(eNumber.toUpperCase());
    if (entry) return entry.risk;
    return AdditiveRiskLevelV2.UNKNOWN;
  }

  private static getAdditiveName(eNumber: string): string {
    const entry = AdditiveScoreCalculator.additiveDB.get(eNumber.toUpperCase());
    if (entry) return entry.name;
    return eNumber;
  }
}
