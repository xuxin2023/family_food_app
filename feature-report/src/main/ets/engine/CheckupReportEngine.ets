// CheckupReportEngine.ets
// 体检报告解析与长效更新引擎
// 解析OCR文本提取体检指标，评估风险并生成饮食调整建议

import { HealthSignal, BpStatus, BsStatus } from 'hsp_core';

/** 体检项目 */
export class CheckupItem {
  name: string = '';
  value: number = 0;
  unit: string = '';
  normalRange: string = '';
  referenceLow: number = 0;
  referenceHigh: number = 0;
  isAbnormal: boolean = false;
  advice: string = '';
}

/** 体检报告 */
export class CheckupReport {
  items: CheckupItem[] = [];
  date: string = '';
  memberId: string = '';
  summary: string = '';
  riskScore: number = 0;
}

/** 健康档案更新 */
export class HealthArchiveUpdate {
  memberId: string = '';
  newAlerts: string[] = [];
  dietaryAdjustments: string[] = [];
  updatedSignal: HealthSignal = new HealthSignal();
}

/** 体检指标解析规则 */
interface CheckupRule {
  pattern: RegExp;
  name: string;
  unit: string;
  normalMax: number;
  abnormalAdvice: string;
  dietAdjustment?: string;
  alertText?: string;
}

const CHECKUP_RULES: CheckupRule[] = [
  {
    pattern: /收缩压\s*(\d+)\s*/,
    name: '收缩压', unit: 'mmHg', normalMax: 139,
    abnormalAdvice: '建议减少高钠食物摄入（如腌制食品、泡面），每日钠摄入<2000mg',
    dietAdjustment: '低盐饮食，每日钠<1500mg', alertText: '血压异常升高'
  },
  {
    pattern: /舒张压\s*(\d+)\s*/,
    name: '舒张压', unit: 'mmHg', normalMax: 89,
    abnormalAdvice: '舒张压偏高，建议控制体重、增加有氧运动',
    dietAdjustment: '低盐饮食，增加蔬菜水果', alertText: '血压异常升高'
  },
  {
    pattern: /空腹血糖\s*(\d+\.?\d*)\s*/,
    name: '空腹血糖', unit: 'mmol/L', normalMax: 6.0,
    abnormalAdvice: '血糖偏高，减少高糖食物和精制碳水（白米白面），多选全谷物和蔬菜',
    dietAdjustment: '控制碳水化合物，选择低GI食物', alertText: '血糖异常升高'
  },
  {
    pattern: /糖化血红蛋白HbA1c\s*(\d+\.?\d*)\s*/,
    name: '糖化血红蛋白HbA1c', unit: '%', normalMax: 6.0,
    abnormalAdvice: '糖化血红蛋白偏高，提示近3个月血糖控制不佳，需全面调整饮食结构',
    dietAdjustment: '严格控制糖和精制碳水摄入', alertText: '血糖长期偏高'
  },
  {
    pattern: /总胆固醇\s*(\d+\.?\d*)\s*/,
    name: '总胆固醇', unit: 'mmol/L', normalMax: 5.2,
    abnormalAdvice: '胆固醇偏高，减少动物内脏、油炸食品，增加膳食纤维',
    dietAdjustment: '低脂饮食，减少饱和脂肪', alertText: '血脂异常'
  },
  {
    pattern: /低密度脂蛋白LDL\s*(\d+\.?\d*)\s*/,
    name: '低密度脂蛋白LDL', unit: 'mmol/L', normalMax: 3.0,
    abnormalAdvice: 'LDL偏高（坏胆固醇），严格限制饱和脂肪和反式脂肪',
    dietAdjustment: '低脂饮食，避免油炸食品', alertText: '血脂异常'
  },
  {
    pattern: /甘油三酯\s*(\d+\.?\d*)\s*/,
    name: '甘油三酯', unit: 'mmol/L', normalMax: 1.7,
    abnormalAdvice: '甘油三酯偏高，减少糖类和酒精摄入，增加运动',
    dietAdjustment: '控制糖和酒精摄入', alertText: '血脂异常'
  },
  {
    pattern: /谷丙转氨酶ALT\s*(\d+\.?\d*)\s*/,
    name: '谷丙转氨酶ALT', unit: 'U/L', normalMax: 40,
    abnormalAdvice: '肝功能指标偏高，避免饮酒，减少高脂食物',
    dietAdjustment: '护肝饮食，避免酒精和高脂食物', alertText: '肝功能异常'
  },
  {
    pattern: /肌酐\s*(\d+\.?\d*)\s*/,
    name: '肌酐', unit: 'μmol/L', normalMax: 106,
    abnormalAdvice: '肾功能指标偏高，控制蛋白质摄入量，减少高嘌呤食物',
    dietAdjustment: '控制蛋白质摄入，减少高嘌呤食物', alertText: '肾功能异常'
  },
  {
    pattern: /尿酸\s*(\d+\.?\d*)\s*/,
    name: '尿酸', unit: 'μmol/L', normalMax: 420,
    abnormalAdvice: '尿酸偏高，避免海鲜、内脏、啤酒等高嘌呤食物',
    dietAdjustment: '低嘌呤饮食，多饮水促排泄', alertText: '尿酸异常升高'
  },
];

export class CheckupReportEngine {

  /** 解析OCR文本，提取体检项目并生成报告 */
  parseOcrText(ocrText: string, memberId: string): CheckupReport {
    const report: CheckupReport = new CheckupReport()
    report.memberId = memberId;
    report.date = new Date().toISOString().split('T')[0];
    report.items = [];

    for (const rule of CHECKUP_RULES) {
      const match = rule.pattern.exec(ocrText);
      if (match) {
        const item: CheckupItem = new CheckupItem()
        item.name = rule.name;
        item.value = parseFloat(match[1]);
        item.unit = rule.unit;
        item.normalRange = `≤${rule.normalMax} ${rule.unit}`;
        item.isAbnormal = item.value > rule.normalMax;
        if (item.isAbnormal) {
          item.advice = rule.abnormalAdvice;
        }
        report.items.push(item);
      }
    }

    // 计算风险评分（0-100）
    const abnormalCount = report.items.filter(i => i.isAbnormal).length;
    if (abnormalCount === 0) {
      report.riskScore = 0;
    } else {
      // 每个异常项加分，严重程度按超标倍数加权
      let score = 0;
      for (const item of report.items) {
        if (item.isAbnormal) {
          const rule = CHECKUP_RULES.find(r => r.name === item.name);
          if (rule) {
            const exceededRatio = (item.value - rule.normalMax) / rule.normalMax;
            score += 10 + Math.min(exceededRatio * 100, 30);
          }
        }
      }
      report.riskScore = Math.min(Math.round(score), 100);
    }

    // 摘要
    if (abnormalCount === 0) {
      report.summary = '本次体检指标均在正常范围内，继续保持健康饮食和生活方式。';
    } else {
      const abnormalNames = report.items.filter(i => i.isAbnormal).map(i => i.name).join('、');
      report.summary = `共 ${report.items.length} 项指标，其中 ${abnormalNames} 等 ${abnormalCount} 项异常，综合风险评分 ${report.riskScore} 分。`;
    }

    return report;
  }

  /** 根据体检报告生成健康档案更新建议 */
  generateHealthArchiveUpdate(report: CheckupReport, signal: HealthSignal): HealthArchiveUpdate {
    const update: HealthArchiveUpdate = new HealthArchiveUpdate()
    update.memberId = report.memberId;
    update.newAlerts = [];
    update.dietaryAdjustments = [];
    update.updatedSignal = signal;

    for (const item of report.items) {
      if (!item.isAbnormal) continue;
      const rule = CHECKUP_RULES.find(r => r.name === item.name);
      if (!rule) continue;

      // 生成预警
      if (rule.alertText && !update.newAlerts.includes(rule.alertText)) {
        update.newAlerts.push(rule.alertText);
      }

      // 生成饮食调整
      if (rule.dietAdjustment && !update.dietaryAdjustments.includes(rule.dietAdjustment)) {
        update.dietaryAdjustments.push(rule.dietAdjustment);
      }

      // 更新健康信号
      if (item.name === '收缩压' || item.name === '舒张压') {
        update.updatedSignal.manualBpStatus = BpStatus.HIGH;
      }
      if (item.name === '空腹血糖' || item.name === '糖化血红蛋白HbA1c') {
        update.updatedSignal.manualBsStatus = BsStatus.HIGH;
      }
    }

    return update;
  }
}
