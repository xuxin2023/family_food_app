// hsp-allergy: 不耐受检测器
// 基于配料关键词匹配检测乳糖/麸质/果糖/组胺/水杨酸/亚硫酸盐/咖啡因/FODMAP 不耐受

import { FamilyProfile, FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { AllergyHint, Severity } from './AllergyEngine';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'IntoleranceDetector';

export enum IntoleranceType {
  LACTOSE = 'lactose',
  GLUTEN = 'gluten',
  FRUCTOSE = 'fructose',
  HISTAMINE = 'histamine',
  SALICYLATE = 'salicylate',
  SULFITE = 'sulfite',
  CAFFEINE = 'caffeine',
  FODMAP = 'fodmap'
}

/** 不耐受关键词库 */
const KEYWORD_MAP: Map<IntoleranceType, string[]> = new Map([
  [IntoleranceType.LACTOSE, [
    '乳糖', '牛奶', '奶粉', '乳清蛋白', '乳清粉', '奶油', '芝士',
    '炼乳', '脱脂乳', '酪蛋白', '酪蛋白酸钠', '乳固体', '淡奶油'
  ]],
  [IntoleranceType.GLUTEN, [
    '小麦', '大麦', '黑麦', '面粉', '面筋', '麦麸', '全麦粉',
    '小麦粉', '小麦蛋白', '麦芽', '麦芽糊精', '酱油'
  ]],
  [IntoleranceType.FRUCTOSE, [
    '果糖', '高果糖浆', '高果糖玉米糖浆', '蜂蜜', '苹果汁',
    '梨汁', '葡萄汁', '浓缩果汁', '龙舌兰糖浆', '菊粉'
  ]],
  [IntoleranceType.HISTAMINE, [
    '陈年芝士', '发酵食品', '腌制鱼', '香肠', '腊肉', '火腿', '泡菜',
    '酵母提取物', '番茄', '茄子', '菠菜', '蘑菇', '牛油果',
    '巧克力', '可可', '咖啡', '红茶', '绿茶',
    '豆制品', '豆腐', '纳豆', '豆瓣酱'
  ]],
  [IntoleranceType.SALICYLATE, [
    '薄荷', '薄荷醇', '柑橘皮', '咖喱粉', '肉桂', '丁香', '茴香',
    '姜黄', '胡椒粉', '辣椒粉', '八角', '花椒', '孜然', '芥末',
    '番茄', '番茄酱', '草莓', '蓝莓', '杏仁', '花生', '核桃',
    '橄榄', '橄榄油', '椰子', '菠萝', '柠檬皮', '橙皮',
    '花椰菜', '菠菜', '蘑菇', '青椒', '黄瓜皮'
  ]],
  [IntoleranceType.SULFITE, [
    '亚硫酸盐', '二氧化硫', '焦亚硫酸钠', '亚硫酸钠', '偏重亚硫酸钾',
    '葡萄酒', '干果', '腌制蔬菜', '脱水蔬菜'
  ]],
  [IntoleranceType.CAFFEINE, [
    '咖啡因', '咖啡', '红茶', '绿茶', '乌龙茶', '可乐',
    '能量饮料', '可可粉', '巧克力', '黑巧克力', '瓜拉纳'
  ]],
  [IntoleranceType.FODMAP, [
    '小麦', '大蒜', '洋葱', '苹果', '梨', '牛奶', '酸奶',
    '蜂蜜', '豆类', '蘑菇', '西兰花', '花椰菜', '西瓜',
    '杏', '樱桃', '芒果', '鹰嘴豆', '扁豆', '黄豆'
  ]],
]);

/** 不耐受原因说明 */
const REASON_MAP: Map<IntoleranceType, string> = new Map([
  [IntoleranceType.LACTOSE, '乳糖不耐受：缺乏乳糖酶，摄入后可能腹胀、腹泻'],
  [IntoleranceType.GLUTEN, '麸质不耐受（非乳糜泻）：摄入后可能消化不适、腹胀'],
  [IntoleranceType.FRUCTOSE, '果糖不耐受：果糖吸收不良，可能导致腹胀、腹痛'],
  [IntoleranceType.HISTAMINE, '组胺不耐受：DAO酶活性低，组胺蓄积可能致头痛、皮疹'],
  [IntoleranceType.SALICYLATE, '水杨酸不耐受：对水杨酸盐敏感，可能诱发哮喘、皮疹'],
  [IntoleranceType.SULFITE, '亚硫酸盐不耐受：可能诱发哮喘、呼吸困难'],
  [IntoleranceType.CAFFEINE, '咖啡因不耐受：代谢缓慢，少量即可致心悸、失眠'],
  [IntoleranceType.FODMAP, 'FODMAP不耐受：含高FODMAP成分，IBS患者易腹胀、腹痛'],
]);

/** 不耐受严重度配置 */
const SEVERITY_MAP: Map<IntoleranceType, Severity> = new Map([
  [IntoleranceType.LACTOSE, Severity.MODERATE],
  [IntoleranceType.GLUTEN, Severity.MODERATE],
  [IntoleranceType.FRUCTOSE, Severity.MODERATE],
  [IntoleranceType.HISTAMINE, Severity.HIGH],
  [IntoleranceType.SALICYLATE, Severity.MODERATE],
  [IntoleranceType.SULFITE, Severity.HIGH],
  [IntoleranceType.CAFFEINE, Severity.MODERATE],
  [IntoleranceType.FODMAP, Severity.MODERATE],
]);

/** 不耐受类型中文标签 */
const TYPE_LABEL_MAP: Map<string, string> = new Map([
  ['lactose', '乳糖'], ['gluten', '麸质'], ['fructose', '果糖'],
  ['histamine', '组胺'], ['salicylate', '水杨酸'], ['sulfite', '亚硫酸盐'],
  ['caffeine', '咖啡因'], ['fodmap', 'FODMAP'],
]);

export class IntoleranceDetector {
  /**
   * 基于配料关键词匹配检测不耐受成分
   * @param food 食品标签
   * @param members 家庭成员列表（用于获取各成员的健康目标信息）
   * @returns 不耐受风险提示
   */
  detect(food: FoodLabel, members: FamilyProfile[]): AllergyHint[] {
    const hints: AllergyHint[] = [];
    // 推断可能的不耐受类型（基于配料覆盖）
    const intoleranceTypes = this.inferRelevantTypes(food.ingredients);

    for (const type of intoleranceTypes) {
      const keywords = KEYWORD_MAP.get(type) ?? [];
      const reason = REASON_MAP.get(type) ?? '';
      const severity = SEVERITY_MAP.get(type) ?? Severity.MODERATE;
      const typeLabel = TYPE_LABEL_MAP.get(type) ?? type;

      for (const ingredient of food.ingredients) {
        const normalized = ingredient.trim().toLowerCase();
        const matchedKw = keywords.find(k => normalized.includes(k.toLowerCase()));
        if (matchedKw) {
          const hint: AllergyHint = new AllergyHint()
          hint.allergen = `${typeLabel}不耐受`;
          hint.ingredient = ingredient;
          hint.severity = severity;
          hint.detail = `含${typeLabel}不耐受成分"${ingredient}" — ${reason}`;
          hint.recommendation = severity === Severity.HIGH
            ? '建议避免食用'
            : '建议少量或避免食用';
          hints.push(hint);
          break; // 每种类型每个食材只记一次
        }
      }
    }

    hilog.info(HILOG_DOMAIN_DEFAULT, TAG,
      'Intolerance detection: %{public}d hints for %{public}s from %{public}d intolerance types',
      hints.length, food.foodName, intoleranceTypes.length);
    return hints;
  }

  /** 推断相关的不耐受类型（至少一种配料匹配关键词则纳入检测） */
  private inferRelevantTypes(ingredients: string[]): IntoleranceType[] {
    const relevant: IntoleranceType[] = [];
    const allTypes = [
      IntoleranceType.LACTOSE, IntoleranceType.GLUTEN, IntoleranceType.FRUCTOSE,
      IntoleranceType.HISTAMINE, IntoleranceType.SALICYLATE, IntoleranceType.SULFITE,
      IntoleranceType.CAFFEINE, IntoleranceType.FODMAP
    ];

    for (const type of allTypes) {
      const keywords = KEYWORD_MAP.get(type) ?? [];
      const matched = ingredients.some(i =>
        keywords.some(k => i.toLowerCase().includes(k.toLowerCase())));
      if (matched) {
        relevant.push(type);
      }
    }
    return relevant;
  }
}
