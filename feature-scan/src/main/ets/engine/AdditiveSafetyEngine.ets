import { FoodLabel, HILOG_DOMAIN } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AdditiveSafetyEngine';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export enum AdditiveRiskLevel {
  SAFE = 'safe',
  CAUTION = 'caution',
  AVOID = 'avoid',
  UNKNOWN = 'unknown'
}

export interface AdditiveAssessment {
  eNumber: string;
  name: string;
  riskLevel: AdditiveRiskLevel;
  category: string;
  description: string;
  euStatus: string;
}

export interface FoodAdditiveReport {
  foodName: string;
  assessments: AdditiveAssessment[];
  overallRisk: AdditiveRiskLevel;
  avoidCount: number;
  cautionCount: number;
  safeCount: number;
  summary: string;
}

const ADDITIVE_DB: Record<string, { name: string; risk: AdditiveRiskLevel; category: string; desc: string; eu: string }> = {
  'E102': { name: '柠檬黄', risk: AdditiveRiskLevel.CAUTION, category: '着色剂', desc: '可能引起儿童多动症', eu: '允许' },
  'E104': { name: '喹啉黄', risk: AdditiveRiskLevel.AVOID, category: '着色剂', desc: '欧盟限用，可能致敏', eu: '限用' },
  'E110': { name: '日落黄', risk: AdditiveRiskLevel.CAUTION, category: '着色剂', desc: '可能引起过敏反应', eu: '允许' },
  'E120': { name: '胭脂红', risk: AdditiveRiskLevel.AVOID, category: '着色剂', desc: '动物源，可能致敏', eu: '允许' },
  'E122': { name: '胭脂红4R', risk: AdditiveRiskLevel.CAUTION, category: '着色剂', desc: '可能引起过敏', eu: '允许' },
  'E124': { name: '丽春红4R', risk: AdditiveRiskLevel.AVOID, category: '着色剂', desc: '可能与药物相互作用', eu: '限用' },
  'E129': { name: '诱惑红AC', risk: AdditiveRiskLevel.CAUTION, category: '着色剂', desc: '可能引起过敏', eu: '允许' },
  'E131': { name: '专利蓝V', risk: AdditiveRiskLevel.AVOID, category: '着色剂', desc: '可能致癌', eu: '限用' },
  'E133': { name: '亮蓝FCF', risk: AdditiveRiskLevel.SAFE, category: '着色剂', desc: '公认安全', eu: '允许' },
  'E150a': { name: '焦糖色I', risk: AdditiveRiskLevel.SAFE, category: '着色剂', desc: '最安全的焦糖色', eu: '允许' },
  'E150d': { name: '焦糖色IV', risk: AdditiveRiskLevel.CAUTION, category: '着色剂', desc: '含4-MEI，可能致癌', eu: '限用' },
  'E171': { name: '二氧化钛', risk: AdditiveRiskLevel.AVOID, category: '着色剂', desc: '欧盟已禁用作食品添加剂', eu: '禁用' },
  'E200': { name: '山梨酸', risk: AdditiveRiskLevel.SAFE, category: '防腐剂', desc: '公认安全', eu: '允许' },
  'E211': { name: '苯甲酸钠', risk: AdditiveRiskLevel.CAUTION, category: '防腐剂', desc: '与VC反应可能产生苯', eu: '允许' },
  'E220': { name: '二氧化硫', risk: AdditiveRiskLevel.CAUTION, category: '防腐剂', desc: '可能引起哮喘', eu: '允许' },
  'E250': { name: '亚硝酸钠', risk: AdditiveRiskLevel.AVOID, category: '防腐剂', desc: '可能形成致癌亚硝胺', eu: '限用' },
  'E251': { name: '硝酸钠', risk: AdditiveRiskLevel.AVOID, category: '防腐剂', desc: '可能形成致癌亚硝胺', eu: '限用' },
  'E280': { name: '丙酸', risk: AdditiveRiskLevel.SAFE, category: '防腐剂', desc: '天然存在，安全', eu: '允许' },
  'E300': { name: '抗坏血酸(VC)', risk: AdditiveRiskLevel.SAFE, category: '抗氧化剂', desc: '营养素，安全', eu: '允许' },
  'E320': { name: 'BHA', risk: AdditiveRiskLevel.AVOID, category: '抗氧化剂', desc: '可能致癌', eu: '限用' },
  'E321': { name: 'BHT', risk: AdditiveRiskLevel.CAUTION, category: '抗氧化剂', desc: '争议性抗氧化剂', eu: '限用' },
  'E322': { name: '卵磷脂', risk: AdditiveRiskLevel.SAFE, category: '乳化剂', desc: '天然存在，安全', eu: '允许' },
  'E330': { name: '柠檬酸', risk: AdditiveRiskLevel.SAFE, category: '酸度调节剂', desc: '天然存在，安全', eu: '允许' },
  'E334': { name: '酒石酸', risk: AdditiveRiskLevel.SAFE, category: '酸度调节剂', desc: '天然存在', eu: '允许' },
  'E407': { name: '卡拉胶', risk: AdditiveRiskLevel.CAUTION, category: '增稠剂', desc: '降解型可能致癌', eu: '允许' },
  'E412': { name: '瓜尔胶', risk: AdditiveRiskLevel.SAFE, category: '增稠剂', desc: '公认安全', eu: '允许' },
  'E415': { name: '黄原胶', risk: AdditiveRiskLevel.SAFE, category: '增稠剂', desc: '公认安全', eu: '允许' },
  'E450': { name: '磷酸盐', risk: AdditiveRiskLevel.CAUTION, category: '乳化剂', desc: '过量影响钙吸收', eu: '允许' },
  'E471': { name: '脂肪酸单双甘油酯', risk: AdditiveRiskLevel.SAFE, category: '乳化剂', desc: '公认安全', eu: '允许' },
  'E621': { name: '谷氨酸钠(味精)', risk: AdditiveRiskLevel.CAUTION, category: '增味剂', desc: '可能引起味精综合征', eu: '允许' },
  'E627': { name: '鸟苷酸二钠', risk: AdditiveRiskLevel.SAFE, category: '增味剂', desc: '核酸类增味剂', eu: '允许' },
  'E631': { name: '肌苷酸二钠', risk: AdditiveRiskLevel.SAFE, category: '增味剂', desc: '核酸类增味剂', eu: '允许' },
  'E950': { name: '安赛蜜', risk: AdditiveRiskLevel.SAFE, category: '甜味剂', desc: '人工甜味剂，安全', eu: '允许' },
  'E951': { name: '阿斯巴甜', risk: AdditiveRiskLevel.CAUTION, category: '甜味剂', desc: 'WHO列为可能致癌', eu: '允许' },
  'E952': { name: '糖精钠', risk: AdditiveRiskLevel.CAUTION, category: '甜味剂', desc: '争议性甜味剂', eu: '限用' },
  'E954': { name: '三氯蔗糖', risk: AdditiveRiskLevel.SAFE, category: '甜味剂', desc: '公认安全', eu: '允许' },
  'E955': { name: '三氯半乳蔗糖', risk: AdditiveRiskLevel.SAFE, category: '甜味剂', desc: '新一代甜味剂', eu: '允许' },
  'E960': { name: '甜菊糖苷', risk: AdditiveRiskLevel.SAFE, category: '甜味剂', desc: '天然甜味剂', eu: '允许' },
  'E965': { name: '麦芽糖醇', risk: AdditiveRiskLevel.SAFE, category: '甜味剂', desc: '糖醇类，安全', eu: '允许' },
  'E967': { name: '木糖醇', risk: AdditiveRiskLevel.SAFE, category: '甜味剂', desc: '天然糖醇', eu: '允许' },
};

export class AdditiveSafetyEngine {
  assessFood(foodLabel: FoodLabel): FoodAdditiveReport {
    const assessments: AdditiveAssessment[] = [];
    const ingredients = foodLabel.ingredients;

    const ePattern = /\b(E\d{3}[a-z]?)\b/gi;
    let match: RegExpExecArray | null;
    const foundENumbers: Set<string> = new Set();

    const ingredientText = typeof ingredients === 'string' ? ingredients : ingredients.join(', ');
    const execPattern = new RegExp(ePattern.source, ePattern.flags);
    while ((match = execPattern.exec(ingredientText)) !== null) {
      foundENumbers.add(match[1].toUpperCase());
    }

    for (const eNum of foundENumbers) {
      const info = ADDITIVE_DB[eNum];
      if (info) {
        assessments.push({
          eNumber: eNum,
          name: info.name,
          riskLevel: info.risk,
          category: info.category,
          description: info.desc,
          euStatus: info.eu
        });
      } else {
        assessments.push({
          eNumber: eNum,
          name: '未知添加剂',
          riskLevel: AdditiveRiskLevel.UNKNOWN,
          category: '未知',
          description: '该E编号尚未收录',
          euStatus: '未知'
        });
      }
    }

    const avoidCount = assessments.filter(a => a.riskLevel === AdditiveRiskLevel.AVOID).length;
    const cautionCount = assessments.filter(a => a.riskLevel === AdditiveRiskLevel.CAUTION).length;
    const safeCount = assessments.filter(a => a.riskLevel === AdditiveRiskLevel.SAFE).length;

    let overallRisk: AdditiveRiskLevel = AdditiveRiskLevel.SAFE;
    if (avoidCount > 0) { overallRisk = AdditiveRiskLevel.AVOID; }
    else if (cautionCount > 0) { overallRisk = AdditiveRiskLevel.CAUTION; }

    let summary = '';
    if (assessments.length === 0) {
      summary = '未检测到E编号添加剂';
    } else if (overallRisk === AdditiveRiskLevel.AVOID) {
      summary = `检测到${avoidCount}种应避免添加剂，建议谨慎食用`;
    } else if (overallRisk === AdditiveRiskLevel.CAUTION) {
      summary = `检测到${cautionCount}种需注意添加剂，适量食用`;
    } else {
      summary = `检测到${safeCount}种安全添加剂`;
    }

    return { foodName: foodLabel.foodName, assessments, overallRisk, avoidCount, cautionCount, safeCount, summary };
  }

  getAdditiveInfo(eNumber: string): AdditiveAssessment | null {
    const info = ADDITIVE_DB[eNumber.toUpperCase()];
    if (!info) return null;
    return {
      eNumber: eNumber.toUpperCase(),
      name: info.name,
      riskLevel: info.risk,
      category: info.category,
      description: info.desc,
      euStatus: info.eu
    };
  }

  searchByRiskLevel(level: AdditiveRiskLevel): AdditiveAssessment[] {
    const results: AdditiveAssessment[] = [];
    for (const [eNum, info] of Object.entries(ADDITIVE_DB)) {
      if (info.risk === level) {
        results.push({
          eNumber: eNum, name: info.name, riskLevel: info.risk,
          category: info.category, description: info.desc, euStatus: info.eu
        });
      }
    }
    return results;
  }
}
