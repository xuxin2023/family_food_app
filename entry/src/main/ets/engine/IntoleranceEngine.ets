// IntoleranceEngine.ets
// 不耐受检测引擎 — 独立于过敏原检测，处理乳糖/麸质/果糖/组胺等不耐受类型
// 过敏 = 免疫系统反应; 不耐受 = 消化系统反应（语义不同）

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';

const TAG = 'IntoleranceEngine';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export enum IntoleranceType {
  LACTOSE = 'lactose',
  GLUTEN = 'gluten',
  FRUCTOSE = 'fructose',
  HISTAMINE = 'histamine',
  SALICYLATE = 'salicylate',
  SULFITE = 'sulfite',
  CAFFEINE = 'caffeine'
}

export enum IntoleranceSeverity {
  CAUTION = 'CAUTION',
  AVOID = 'AVOID'
}

export class IntoleranceWarning {
  type: IntoleranceType = IntoleranceType.LACTOSE;
  ingredient: string = '';
  severity: IntoleranceSeverity = IntoleranceSeverity.CAUTION;
  reason: string = '';
}

export class IntoleranceCheckResult {
  hasWarnings: boolean = false;
  warnings: IntoleranceWarning[] = [];
  summary: string = '';
}

export class IntoleranceEngine {
  private static readonly KEYWORD_MAP: Map<IntoleranceType, string[]> = new Map([
    [IntoleranceType.LACTOSE, [
      '乳糖', '牛奶', '奶粉', '乳清蛋白', '乳清粉', '奶油', '芝士',
      '炼乳', '脱脂乳', '酪蛋白', '酪蛋白酸钠', '乳固体', '淡奶油'
    ]],
    [IntoleranceType.GLUTEN, [
      '小麦', '大麦', '黑麦', '面粉', '面筋', '麦麸', '全麦粉',
      '小麦粉', '小麦蛋白', '麦芽', '麦芽糊精', '啤酒', '酱油'
    ]],
    [IntoleranceType.FRUCTOSE, [
      '果糖', '高果糖浆', '高果糖玉米糖浆', '蜂蜜', '苹果汁',
      '梨汁', '葡萄汁', '浓缩果汁', '龙舌兰糖浆', '菊粉'
    ]],
    [IntoleranceType.HISTAMINE, [
      '发酵食品', '陈年芝士', '红酒', '白酒', '腌制鱼', '香肠',
      '腊肉', '火腿', '泡菜', '酱油', '醋', '番茄酱', '金枪鱼罐头',
      '沙丁鱼罐头', '酵母提取物'
    ]],
    [IntoleranceType.SALICYLATE, [
      '阿司匹林', '薄荷', '薄荷醇', '柑橘皮', '咖喱粉', '肉桂',
      '丁香', '茴香', '姜黄', '胡椒粉', '辣椒粉'
    ]],
    [IntoleranceType.SULFITE, [
      '亚硫酸盐', '二氧化硫', '焦亚硫酸钠', '亚硫酸钠', '偏重亚硫酸钾',
      '葡萄酒', '干果', '腌制蔬菜', '罐头蘑菇', '脱水蔬菜'
    ]],
    [IntoleranceType.CAFFEINE, [
      '咖啡因', '咖啡', '红茶', '绿茶', '乌龙茶', '可乐',
      '能量饮料', '可可粉', '巧克力', '黑巧克力', '瓜拉纳'
    ]]
  ]);

  private static readonly REASON_MAP: Map<IntoleranceType, string> = new Map([
    [IntoleranceType.LACTOSE, '乳糖不耐受：缺乏乳糖酶，摄入后可能腹胀、腹泻'],
    [IntoleranceType.GLUTEN, '麸质不耐受（非乳糜泻）：摄入后可能消化不适、腹胀'],
    [IntoleranceType.FRUCTOSE, '果糖不耐受：果糖吸收不良，可能导致腹胀、腹痛'],
    [IntoleranceType.HISTAMINE, '组胺不耐受：DAO酶活性低，组胺蓄积可能致头痛、皮疹'],
    [IntoleranceType.SALICYLATE, '水杨酸不耐受：对水杨酸盐敏感，可能诱发哮喘、皮疹'],
    [IntoleranceType.SULFITE, '亚硫酸盐不耐受：可能诱发哮喘、呼吸困难'],
    [IntoleranceType.CAFFEINE, '咖啡因不耐受：代谢缓慢，少量即可致心悸、失眠']
  ]);

  private static readonly SEVERITY_MAP: Map<IntoleranceType, string> = new Map([
    [IntoleranceType.LACTOSE, 'CAUTION'],
    [IntoleranceType.GLUTEN, 'CAUTION'],
    [IntoleranceType.FRUCTOSE, 'CAUTION'],
    [IntoleranceType.HISTAMINE, 'AVOID'],
    [IntoleranceType.SALICYLATE, 'CAUTION'],
    [IntoleranceType.SULFITE, 'AVOID'],
    [IntoleranceType.CAFFEINE, 'CAUTION']
  ]);

  private static readonly TYPE_LABEL_MAP: Map<string, string> = new Map([
    ['lactose', '乳糖'],
    ['gluten', '麸质'],
    ['fructose', '果糖'],
    ['histamine', '组胺'],
    ['salicylate', '水杨酸'],
    ['sulfite', '亚硫酸盐'],
    ['caffeine', '咖啡因']
  ]);

  check(intolerances: IntoleranceType[], ingredients: string[]): IntoleranceCheckResult {
    const emptyResult = new IntoleranceCheckResult();
    if (intolerances.length === 0 || ingredients.length === 0) {
      return emptyResult;
    }

    const warnings: IntoleranceWarning[] = [];

    for (const t of intolerances) {
      const keywords = IntoleranceEngine.KEYWORD_MAP.get(t) ?? [];
      const matched = ingredients.filter(i => keywords.some(k => i.includes(k)));
      if (matched.length > 0) {
        const reason = IntoleranceEngine.REASON_MAP.get(t) ?? '';
        const severityStr = IntoleranceEngine.SEVERITY_MAP.get(t) ?? 'CAUTION';
        const severity = severityStr === 'AVOID' ? IntoleranceSeverity.AVOID : IntoleranceSeverity.CAUTION;
        for (const m of matched) {
          const w = new IntoleranceWarning();
          w.type = t; w.ingredient = m; w.severity = severity; w.reason = reason;
          warnings.push(w);
        }
      }
    }

    const hasWarnings = warnings.length > 0;
    let summary = '';
    if (hasWarnings) {
      const typeSet = new Set(warnings.map(w => w.type));
      const typeLabels = Array.from(typeSet).map(t => IntoleranceEngine.TYPE_LABEL_MAP.get(t) ?? t);
      summary = `检测到${typeLabels.join('、')}相关成分，请注意`;
      hilog.info(DOMAIN_ZERO, TAG, 'Intolerance check: %{public}d warnings', warnings.length);
    }

    const result = new IntoleranceCheckResult();
    result.hasWarnings = hasWarnings; result.warnings = warnings; result.summary = summary;
    return result;
  }

  getTypeLabel(type: IntoleranceType): string {
    return IntoleranceEngine.TYPE_LABEL_MAP.get(type) ?? type;
  }

  getAllTypes(): IntoleranceType[] {
    return [
      IntoleranceType.LACTOSE,
      IntoleranceType.GLUTEN,
      IntoleranceType.FRUCTOSE,
      IntoleranceType.HISTAMINE,
      IntoleranceType.SALICYLATE,
      IntoleranceType.SULFITE,
      IntoleranceType.CAFFEINE
    ];
  }
}
