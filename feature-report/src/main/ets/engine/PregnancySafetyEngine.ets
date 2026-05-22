// PregnancySafetyEngine.ets
// 孕期/哺乳期安全检测引擎 — 针对特殊人群的成分安全检测

import { HILOG_DOMAIN, PregnancyStatus } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'PregnancySafetyEngine';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class PregnancyIngredientRule {
  name: string = '';
  maxDailyMg: number = 0;
  hasMaxDaily: boolean = false;
  severity: string = 'CAUTION';
  reason: string = '';
}

export class PregnancyWarning {
  ingredient: string = '';
  matchedRule: PregnancyIngredientRule = new PregnancyIngredientRule();
}

export class PregnancySafetyResult {
  safe: boolean = true;
  warnings: PregnancyWarning[] = [];
  summary: string = '';
}

function makeRule(name: string, severity: string, reason: string, maxDailyMg: number = 0): PregnancyIngredientRule {
  const r = new PregnancyIngredientRule();
  r.name = name; r.severity = severity; r.reason = reason;
  if (maxDailyMg > 0) { r.maxDailyMg = maxDailyMg; r.hasMaxDaily = true; }
  return r;
}

export class PregnancySafetyEngine {
  private static readonly RULES: Map<PregnancyStatus, PregnancyIngredientRule[]> = new Map([
    [PregnancyStatus.FIRST_TRIMESTER, [
      makeRule('酒精', 'AVOID', '孕早期任何剂量酒精均有致畸风险，器官形成期最敏感'),
      makeRule('咖啡因', 'CAUTION', '孕早期建议每日咖啡因<200mg，过量增加流产风险', 200),
      makeRule('维生素A', 'AVOID', '孕早期过量维生素A(>3000μg)有致畸风险', 3000),
      makeRule('生鱼片', 'AVOID', '孕早期感染李斯特菌流产风险最高'),
      makeRule('生肉', 'AVOID', '未充分加热的肉可能含弓形虫'),
      makeRule('生蛋', 'AVOID', '生蛋可能含沙门氏菌'),
      makeRule('含汞鱼类', 'AVOID', '汞损害胎儿神经系统发育'),
      makeRule('未经巴氏杀菌', 'AVOID', '未经巴氏杀菌的乳制品可能含李斯特菌'),
    ]],
    [PregnancyStatus.SECOND_TRIMESTER, [
      makeRule('酒精', 'AVOID', '孕期任何剂量酒精均有风险'),
      makeRule('咖啡因', 'CAUTION', '孕中期建议每日咖啡因<200mg', 200),
      makeRule('生鱼片', 'AVOID', '孕中期仍应避免生食'),
      makeRule('含汞鱼类', 'AVOID', '汞损害胎儿神经系统发育'),
    ]],
    [PregnancyStatus.THIRD_TRIMESTER, [
      makeRule('酒精', 'AVOID', '孕晚期酒精影响胎儿脑发育'),
      makeRule('咖啡因', 'CAUTION', '孕晚期建议每日咖啡因<100mg，过量影响胎儿心率', 100),
      makeRule('生鱼片', 'AVOID', '孕晚期感染风险仍高'),
      makeRule('含汞鱼类', 'AVOID', '汞损害胎儿神经系统发育'),
      makeRule('甘草', 'AVOID', '大量甘草可能诱发早产'),
    ]],
    [PregnancyStatus.PREGNANT, [
      makeRule('酒精', 'AVOID', '孕期任何剂量酒精均有致畸风险，可导致胎儿酒精综合征'),
      makeRule('咖啡因', 'CAUTION', '建议每日咖啡因摄入<200mg(约2杯咖啡)，过量增加流产风险', 200),
      makeRule('维生素A', 'CAUTION', '过量维生素A(>3000μg RE/天)有致畸风险，避免动物肝脏和维A补充剂', 3000),
      makeRule('生鱼片', 'AVOID', '生鱼可能含李斯特菌和寄生虫，孕期感染风险极高'),
      makeRule('生肉', 'AVOID', '未充分加热的肉可能含弓形虫和沙门氏菌'),
      makeRule('生蛋', 'AVOID', '生蛋或半熟蛋可能含沙门氏菌'),
      makeRule('含汞鱼类', 'AVOID', '鲨鱼、剑鱼、旗鱼、马林鱼含高量汞，损害胎儿神经系统'),
      makeRule('未经巴氏杀菌', 'AVOID', '未经巴氏杀菌的乳制品和软芝士可能含李斯特菌'),
      makeRule('甘草', 'AVOID', '大量甘草摄入与早产和胎儿发育不良相关'),
      makeRule('人参', 'CAUTION', '人参可能影响胎儿发育，建议谨慎使用'),
      makeRule('藏红花', 'AVOID', '藏红花可能刺激子宫收缩，孕期禁用'),
    ]],
    [PregnancyStatus.BREASTFEEDING, [
      makeRule('酒精', 'AVOID', '酒精进入乳汁影响婴儿神经发育，哺乳期应完全避免'),
      makeRule('咖啡因', 'CAUTION', '建议每日咖啡因<300mg，约0.5-1%会进入乳汁', 300),
      makeRule('高汞鱼类', 'AVOID', '汞通过乳汁传递给婴儿，损害神经系统发育'),
      makeRule('生鱼片', 'CAUTION', '哺乳期生食风险低于孕期，但仍建议充分加热'),
    ]],
  ]);

  private static readonly KEYWORD_MAP: Map<string, string[]> = new Map([
    ['酒精', ['酒精', '乙醇', '白酒', '红酒', '啤酒', '黄酒', '米酒', '料酒', '酒酿']],
    ['咖啡因', ['咖啡因', '咖啡', '红茶', '绿茶', '可乐', '能量饮料', '可可', '巧克力']],
    ['维生素A', ['维生素A', '视黄醇', '鱼肝油', '动物肝脏', '猪肝', '鸡肝', '牛肝']],
    ['生鱼片', ['生鱼片', '刺身', '寿司', '三文鱼刺身', '金枪鱼刺身']],
    ['生肉', ['生肉', '生牛肉', '鞑靼牛肉', '半熟牛排']],
    ['生蛋', ['生蛋', '溏心蛋', '半熟蛋', '蛋黄酱', '提拉米苏']],
    ['含汞鱼类', ['鲨鱼', '剑鱼', '旗鱼', '马林鱼', '方头鱼', '大眼金枪鱼']],
    ['未经巴氏杀菌', ['生乳', '未经巴氏杀菌', '布里芝士', '卡门培尔芝士', '蓝纹芝士', '菲达芝士']],
    ['甘草', ['甘草', '甘草片', '甘草提取物']],
    ['人参', ['人参', '红参', '高丽参', '西洋参', '参片']],
    ['藏红花', ['藏红花', '番红花', '西红花']],
    ['高汞鱼类', ['鲨鱼', '剑鱼', '旗鱼', '马林鱼', '大眼金枪鱼']],
  ]);

  evaluate(status: PregnancyStatus, ingredients: string[]): PregnancySafetyResult {
    if (status === PregnancyStatus.NONE || ingredients.length === 0) {
      return new PregnancySafetyResult();
    }

    const applicableRules = PregnancySafetyEngine.RULES.get(status) ?? [];
    const warnings: PregnancyWarning[] = [];

    for (const rule of applicableRules) {
      const keywords = PregnancySafetyEngine.KEYWORD_MAP.get(rule.name) ?? [rule.name];
      const matchedIngredients = ingredients.filter(i => keywords.some(k => i.includes(k)));
      if (matchedIngredients.length > 0) {
        for (const ing of matchedIngredients) {
          const w = new PregnancyWarning();
          w.ingredient = ing; w.matchedRule = rule;
          warnings.push(w);
        }
      }
    }

    const safe = warnings.filter(w => w.matchedRule.severity === 'AVOID').length === 0;
    const avoidCount = warnings.filter(w => w.matchedRule.severity === 'AVOID').length;
    const cautionCount = warnings.filter(w => w.matchedRule.severity === 'CAUTION').length;

    let summary = '';
    if (warnings.length > 0) {
      const statusLabel = status === PregnancyStatus.PREGNANT ? '孕期' : '哺乳期';
      summary = `${statusLabel}安全提示：发现${avoidCount > 0 ? `${avoidCount}项应避免` : ''}${avoidCount > 0 && cautionCount > 0 ? '、' : ''}${cautionCount > 0 ? `${cautionCount}项需谨慎` : ''}的成分`;
      hilog.info(DOMAIN_ZERO, TAG, 'Pregnancy check: %{public}d warnings, safe=%{public}s', warnings.length, String(safe));
    }

    const result = new PregnancySafetyResult();
    result.safe = safe; result.warnings = warnings; result.summary = summary;
    return result;
  }
}
