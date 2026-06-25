// AdditiveSafetyEngine.ets
// 添加剂安全评估引擎 — 支持 EU E编号 + 中国 CNS编号 (GB 2760-2024)
// V6.1: 增加中国标准数据库支持，CNS/E双向映射

import { FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'AdditiveSafetyEngine';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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
  cnsCode?: string;
  cnMaxUsage?: string;
  safetyLevel?: string;
  gbRef?: string;
  adi?: string;
  childRestriction?: string;
  pregnancyRestriction?: string;
  allergyPotential?: boolean;
  intoleranceRisk?: string;
}

export interface FoodAdditiveReport {
  foodName: string;
  assessments: AdditiveAssessment[];
  overallRisk: AdditiveRiskLevel;
  avoidCount: number;
  cautionCount: number;
  safeCount: number;
  summary: string;
  standardUsed: string;
}

interface CnAdditiveEntry {
  cnsCode: string;
  name: string;
  nameZh?: string;
  nameEn: string;
  aliases?: string[];
  eNumber: string;
  function: string;
  category?: string;
  maxUsage: string;
  maxUseLevel?: number;
  safetyLevel: string;
  adi?: string;
  gb2760Categories?: string[];
  childRestriction?: string;
  pregnancyRestriction?: string;
  allergyPotential?: boolean;
  intoleranceRisk?: string;
  gbRef: string;
  source?: string;
}

interface EToCnsMapping {
  eToCns: Record<string, string>;
  cnsToE: Record<string, string>;
}

interface AdditiveEntry {
  name: string;
  risk: AdditiveRiskLevel;
  category: string;
  desc: string;
  eu: string;
}

const ADDITIVE_DB: Record<string, AdditiveEntry> = {
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

const SAFETY_LEVEL_MAP: Record<string, AdditiveRiskLevel> = {
  'safe': AdditiveRiskLevel.SAFE,
  'caution': AdditiveRiskLevel.CAUTION,
  'avoid': AdditiveRiskLevel.AVOID,
  'forbidden': AdditiveRiskLevel.AVOID
};

/**
 * 添加剂安全评估引擎
 *
 * 支持EU E编号 + 中国CNS编号(GB 2760-2024)双标准评估，
 * 内置E编号安全数据库及中国标准映射表，可扩展加载
 * cn_additive_database.json和e_to_cns_mapping.json。
 * 风险等级: SAFE(安全) / CAUTION(谨慎) / AVOID(避免) / UNKNOWN(未知)
 *
 * @since 1.0.0
 */
export class AdditiveSafetyEngine {
  private static instance: AdditiveSafetyEngine;
  private cnDatabase: CnAdditiveEntry[] = [];
  private eToCnsMap: Record<string, string> = {};
  private cnsToEMap: Record<string, string> = {};
  private cnDbLoaded: boolean = false;

  private constructor() {}

  /**
   * 获取AdditiveSafetyEngine单例
   *
   * @returns AdditiveSafetyEngine实例
   */
  static getInstance(): AdditiveSafetyEngine {
    if (!AdditiveSafetyEngine.instance) {
      AdditiveSafetyEngine.instance = new AdditiveSafetyEngine();
    }
    return AdditiveSafetyEngine.instance;
  }

  /**
   * 加载中国添加剂标准数据库(GB 2760-2024)
   *
   * 从rawfile加载cn_additive_database.json和e_to_cns_mapping.json，
   * 建立CNS↔E编号双向映射。仅需调用一次，重复调用无副作用。
   *
   * @param context - 应用上下文，用于访问resourceManager
   * @returns Promise<void>
   */
  async loadCnDatabase(context: common.Context): Promise<void> {
    if (this.cnDbLoaded) return;

    try {
      const resMgr = context.resourceManager;
      const cnRaw = resMgr.getRawFileContentSync('cn_additive_database.json');
      const cnText = String.fromCharCode(...cnRaw);
      this.cnDatabase = JSON.parse(cnText) as CnAdditiveEntry[];

      const mapRaw = resMgr.getRawFileContentSync('e_to_cns_mapping.json');
      const mapText = String.fromCharCode(...mapRaw);
      const mapping = JSON.parse(mapText) as EToCnsMapping;
      this.eToCnsMap = mapping.eToCns ?? {};
      this.cnsToEMap = mapping.cnsToE ?? {};

      this.cnDbLoaded = true;
      hilog.info(DOMAIN_ZERO, TAG, 'CN additive database loaded: %{public}d entries, %{public}d mappings',
        this.cnDatabase.length, Object.keys(this.eToCnsMap).length);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Failed to load CN database: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 评估食品中添加剂安全性
   *
   * 从配料表中提取E编号和CNS编号，优先使用中国标准(GB 2760-2024)评估，
   * 其次使用EU标准。返回各添加剂评估结果及整体风险等级。
   *
   * @param foodLabel - 食品标签数据
   * @returns 添加剂评估报告，包含各添加剂详情及整体风险等级
   *
   * @example
   * ```typescript`
   * const engine = AdditiveSafetyEngine.getInstance();
   * const report = engine.assessFood(foodLabel);
   * console.log(report.overallRisk); // AdditiveRiskLevel.AVOID | CAUTION | SAFE
   * ````
   */
  assessFood(foodLabel: FoodLabel): FoodAdditiveReport {
    const assessments: AdditiveAssessment[] = [];
    const ingredients = foodLabel.ingredients;

    const ePattern = /\b(E\d{3}[a-z]?)\b/gi;
    const cnsPattern = /\b(\d{2}\.\d{3})\b/g;
    let match: RegExpExecArray | null;
    const foundENumbers: Set<string> = new Set();
    const foundCnsCodes: Set<string> = new Set();

    const ingredientText = typeof ingredients === 'string' ? ingredients : ingredients.join(', ');

    const execE: RegExp = new RegExp(/E(\d{3,4}[a-z]?)/gi);
    while ((match = execE.exec(ingredientText)) !== null) {
      foundENumbers.add(match[1].toUpperCase());
    }

    const execCns: RegExp = new RegExp(/CNS\s*(\d{2}\.\d{3})/g);
    while ((match = execCns.exec(ingredientText)) !== null) {
      foundCnsCodes.add(match[1]);
    }

    // 评估 CNS 编码（中国标准）
    for (const cns of foundCnsCodes) {
      const cnEntry = this.cnDatabase.find(e => e.cnsCode === cns);
      if (cnEntry) {
        assessments.push({
          eNumber: this.cnsToEMap[cns] ?? cnEntry.eNumber,
          name: cnEntry.name,
          riskLevel: SAFETY_LEVEL_MAP[cnEntry.safetyLevel] ?? AdditiveRiskLevel.UNKNOWN,
          category: cnEntry.function,
          description: `${cnEntry.name}(${cnEntry.nameEn})，最大使用量：${cnEntry.maxUsage}`,
          euStatus: 'GB 2760-2024',
          cnsCode: cnEntry.cnsCode,
          cnMaxUsage: cnEntry.maxUsage,
          safetyLevel: cnEntry.safetyLevel,
          gbRef: cnEntry.gbRef,
          adi: cnEntry.adi,
          childRestriction: cnEntry.childRestriction,
          pregnancyRestriction: cnEntry.pregnancyRestriction,
          allergyPotential: cnEntry.allergyPotential,
          intoleranceRisk: cnEntry.intoleranceRisk
        });
      } else {
        assessments.push({
          eNumber: this.cnsToEMap[cns] ?? '',
          name: '未知添加剂',
          riskLevel: AdditiveRiskLevel.UNKNOWN,
          category: '未知',
          description: '该CNS编号尚未收录',
          euStatus: '未知',
          cnsCode: cns
        });
      }
    }

    // 评估 E 编号（优先使用中国标准映射，否则用 EU 标准）
    for (const eNum of foundENumbers) {
      const cnsFromMap = this.eToCnsMap[eNum];
      if (cnsFromMap && this.cnDbLoaded) {
        const cnEntry = this.cnDatabase.find(e => e.cnsCode === cnsFromMap);
        if (cnEntry) {
          assessments.push({
            eNumber: eNum,
            name: cnEntry.name,
            riskLevel: SAFETY_LEVEL_MAP[cnEntry.safetyLevel] ?? AdditiveRiskLevel.UNKNOWN,
            category: cnEntry.function,
            description: `${cnEntry.name}(CNS:${cnEntry.cnsCode})，最大使用量：${cnEntry.maxUsage}`,
            euStatus: 'GB 2760-2024',
            cnsCode: cnEntry.cnsCode,
            cnMaxUsage: cnEntry.maxUsage,
            safetyLevel: cnEntry.safetyLevel,
            gbRef: cnEntry.gbRef,
            adi: cnEntry.adi,
            childRestriction: cnEntry.childRestriction,
            pregnancyRestriction: cnEntry.pregnancyRestriction,
            allergyPotential: cnEntry.allergyPotential,
            intoleranceRisk: cnEntry.intoleranceRisk
          });
          continue;
        }
      }

      const info = ADDITIVE_DB[eNum];
      if (info) {
        assessments.push({
          eNumber: eNum,
          name: info.name,
          riskLevel: info.risk,
          category: info.category,
          description: info.desc,
          euStatus: info.eu,
          cnsCode: cnsFromMap ?? undefined
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
    const hasCn = assessments.some(a => a.cnsCode && a.cnsCode.length > 0);
    const standardUsed = hasCn && this.cnDbLoaded ? 'GB 2760-2024 + EU' : 'EU';

    if (assessments.length === 0) {
      summary = '未检测到添加剂编码';
    } else if (overallRisk === AdditiveRiskLevel.AVOID) {
      summary = `检测到${avoidCount}种应避免添加剂，建议谨慎食用`;
    } else if (overallRisk === AdditiveRiskLevel.CAUTION) {
      summary = `检测到${cautionCount}种需注意添加剂，适量食用`;
    } else {
      summary = `检测到${safeCount}种安全添加剂`;
    }

    return { foodName: foodLabel.foodName, assessments, overallRisk, avoidCount, cautionCount, safeCount, summary, standardUsed } as FoodAdditiveReport;
  }

  /**
   * 根据E编号查询添加剂信息
   *
   * @param eNumber - E编号，如'E250'
   * @returns 添加剂评估信息，未找到返回null
   */
  getAdditiveInfo(eNumber: string): AdditiveAssessment | null {
    const info = ADDITIVE_DB[eNumber.toUpperCase()];
    if (!info) return null;
    const cnsCode = this.eToCnsMap[eNumber.toUpperCase()] ?? undefined;
    return {
      eNumber: eNumber.toUpperCase(),
      name: info.name,
      riskLevel: info.risk,
      category: info.category,
      description: info.desc,
      euStatus: info.eu,
      cnsCode
    };
  }

  /**
   * 根据CNS编号查询中国标准添加剂信息
   *
   * @param cnsCode - CNS编号，如'17.003'
   * @returns 添加剂评估信息，未找到返回null
   */
  getCnsAdditiveInfo(cnsCode: string): AdditiveAssessment | null {
    const cnEntry = this.cnDatabase.find(e => e.cnsCode === cnsCode);
    if (!cnEntry) return null;
    return {
      eNumber: this.cnsToEMap[cnsCode] ?? cnEntry.eNumber,
      name: cnEntry.name,
      riskLevel: SAFETY_LEVEL_MAP[cnEntry.safetyLevel] ?? AdditiveRiskLevel.UNKNOWN,
      category: cnEntry.function,
      description: `最大使用量：${cnEntry.maxUsage}`,
      euStatus: 'GB 2760-2024',
      cnsCode: cnEntry.cnsCode,
      cnMaxUsage: cnEntry.maxUsage,
      safetyLevel: cnEntry.safetyLevel,
      gbRef: cnEntry.gbRef,
      adi: cnEntry.adi,
      childRestriction: cnEntry.childRestriction,
      pregnancyRestriction: cnEntry.pregnancyRestriction,
      allergyPotential: cnEntry.allergyPotential,
      intoleranceRisk: cnEntry.intoleranceRisk
    };
  }

  /**
   * E编号映射为CNS编号
   *
   * @param eNumber - E编号
   * @returns 对应CNS编号，无映射返回null
   */
  mapEToCns(eNumber: string): string | null {
    return this.eToCnsMap[eNumber.toUpperCase()] ?? null;
  }

  /**
   * CNS编号映射为E编号
   *
   * @param cnsCode - CNS编号
   * @returns 对应E编号，无映射返回null
   */
  mapCnsToE(cnsCode: string): string | null {
    return this.cnsToEMap[cnsCode] ?? null;
  }

  /**
   * 按风险等级搜索添加剂
   *
   * @param level - 风险等级
   * @returns 符合该风险等级的添加剂列表
   */
  searchByRiskLevel(level: AdditiveRiskLevel): AdditiveAssessment[] {
    const results: AdditiveAssessment[] = [];
    const entries: string[] = Object.keys(ADDITIVE_DB);
    for (const eNum of entries) {
      const info: AdditiveEntry = ADDITIVE_DB[eNum];
      if (info.risk === level) {
        results.push({
          eNumber: eNum, name: info.name, riskLevel: info.risk,
          category: info.category, description: info.desc, euStatus: info.eu,
          cnsCode: this.eToCnsMap[eNum] ?? undefined
        });
      }
    }
    return results;
  }
}
