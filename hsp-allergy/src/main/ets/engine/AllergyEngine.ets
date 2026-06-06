// hsp-allergy: 过敏原检测引擎
// 多成员过敏原检测、严重度分级、交叉反应风险评估

import { FamilyProfile, FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AllergyEngine';

export enum Severity {
  HIGH = 'HIGH',
  MODERATE = 'MODERATE',
  LOW = 'LOW',
  INFO = 'INFO'
}

export class AllergyHint {
  memberId: string = '';
  memberNickname: string = '';
  allergen: string = '';
  ingredient: string = '';
  severity: Severity = Severity.INFO;
  detail: string = '';
  recommendation: string = '';
  /** 是否为交叉反应风险 */
  isCrossReactivity: boolean = false;
}

/** 常见过敏原中英文映射 */
const ALLERGEN_ALIASES: Map<string, string[]> = new Map([
  ['花生', ['花生', 'peanut', '落花生', '花生仁']],
  ['牛奶', ['牛奶', 'milk', '乳', '奶粉', '乳清', '奶油', '炼乳', '酪蛋白', '乳固体']],
  ['鸡蛋', ['鸡蛋', 'egg', '蛋', '蛋黄', '蛋清', '全蛋粉', '卵白', '卵磷脂']],
  ['大豆', ['大豆', 'soy', 'soybean', '黄豆', '豆粕', '大豆蛋白', '大豆分离蛋白']],
  ['小麦', ['小麦', 'wheat', '面粉', '面筋', '麦麸', '全麦粉', '小麦粉', '麦芽']],
  ['坚果', ['坚果', 'nut', '杏仁', '腰果', '核桃', '榛子', '开心果', '夏威夷果']],
  ['鱼', ['鱼', 'fish', '鲑鱼', '金枪鱼', '鳕鱼', '鱼油', '鱼粉']],
  ['虾', ['虾', 'shrimp', '龙虾', '蟹', '贝类', '鱿鱼', '章鱼']],
  ['芝麻', ['芝麻', 'sesame', '芝麻油', '芝麻酱']],
  ['芒果', ['芒果', 'mango']],
]);

/** 交叉反应数据库 */
interface CrossReactivityPair {
  primaryAllergen: string;
  crossReactive: string;
  riskLevel: Severity;
  mechanism: string;
}

const CROSS_REACTIVITY_DB: Record<string, CrossReactivityPair[]> = {
  '花生': [
    { primaryAllergen: '花生', crossReactive: '大豆', riskLevel: Severity.MODERATE, mechanism: '豆科蛋白同源性' },
    { primaryAllergen: '花生', crossReactive: '豌豆', riskLevel: Severity.MODERATE, mechanism: '豆科蛋白同源性' },
  ],
  '牛奶': [
    { primaryAllergen: '牛奶', crossReactive: '山羊奶', riskLevel: Severity.HIGH, mechanism: '酪蛋白同源性>90%' },
    { primaryAllergen: '牛奶', crossReactive: '绵羊奶', riskLevel: Severity.HIGH, mechanism: '酪蛋白同源性>90%' },
  ],
  '鸡蛋': [
    { primaryAllergen: '鸡蛋', crossReactive: '鸭蛋', riskLevel: Severity.MODERATE, mechanism: '卵白蛋白同源性' },
  ],
  '小麦': [
    { primaryAllergen: '小麦', crossReactive: '大麦', riskLevel: Severity.HIGH, mechanism: '麸质蛋白同源性' },
    { primaryAllergen: '小麦', crossReactive: '黑麦', riskLevel: Severity.HIGH, mechanism: '麸质蛋白同源性' },
    { primaryAllergen: '小麦', crossReactive: '燕麦', riskLevel: Severity.LOW, mechanism: '可能被小麦污染' },
  ],
  '大豆': [
    { primaryAllergen: '大豆', crossReactive: '花生', riskLevel: Severity.MODERATE, mechanism: '豆科蛋白同源性' },
  ],
  '虾': [
    { primaryAllergen: '虾', crossReactive: '蟹', riskLevel: Severity.HIGH, mechanism: '原肌球蛋白高度同源' },
    { primaryAllergen: '虾', crossReactive: '鱿鱼', riskLevel: Severity.MODERATE, mechanism: '原肌球蛋白同源性' },
  ],
  '芒果': [
    { primaryAllergen: '芒果', crossReactive: '腰果', riskLevel: Severity.MODERATE, mechanism: '漆树科蛋白同源性' },
    { primaryAllergen: '芒果', crossReactive: '开心果', riskLevel: Severity.MODERATE, mechanism: '漆树科蛋白同源性' },
  ],
};

export class AllergyEngine {
  /**
   * 对食品进行多成员过敏原检测
   * 匹配成员已知过敏原、配料表、标签过敏原提示
   * 同时检测交叉反应风险
   */
  detectAllergens(food: FoodLabel, members: FamilyProfile[]): AllergyHint[] {
    const hints: AllergyHint[] = [];

    for (const member of members) {
      if (member.allergens.length === 0) continue;

      for (const userAllergen of member.allergens) {
        // 直接匹配：配料表中查找
        const aliases = ALLERGEN_ALIASES.get(userAllergen) ?? [userAllergen];
        for (const ingredient of food.ingredients) {
          for (const alias of aliases) {
            if (ingredient.includes(alias)) {
              const hint: AllergyHint = new AllergyHint()
              hint.memberId = member.memberId;
              hint.memberNickname = member.nickname;
              hint.allergen = userAllergen;
              hint.ingredient = ingredient;
              hint.severity = Severity.HIGH;
              hint.detail = `配料"${ingredient}"含过敏原"${userAllergen}"`;
              hint.recommendation = `${member.nickname}应避免食用该食品`;
              hints.push(hint);
            }
          }
        }

        // 直接匹配：标签过敏原提示
        for (const hintTag of food.allergenHints) {
          for (const alias of aliases) {
            if (hintTag.includes(alias)) {
              const hint: AllergyHint = new AllergyHint()
              hint.memberId = member.memberId;
              hint.memberNickname = member.nickname;
              hint.allergen = userAllergen;
              hint.ingredient = hintTag;
              hint.severity = Severity.HIGH;
              hint.detail = `标签标注含"${userAllergen}"过敏原`;
              hint.recommendation = `${member.nickname}应避免食用该食品`;
              hints.push(hint);
            }
          }
        }

        // 交叉反应检测
        const crossRisks = CROSS_REACTIVITY_DB[userAllergen];
        if (crossRisks) {
          for (const cross of crossRisks) {
            const crossAliases = ALLERGEN_ALIASES.get(cross.crossReactive) ?? [cross.crossReactive];
            const matched = food.ingredients.find(i => crossAliases.some(a => i.includes(a)));
            if (matched) {
              const hint: AllergyHint = new AllergyHint()
              hint.memberId = member.memberId;
              hint.memberNickname = member.nickname;
              hint.allergen = cross.crossReactive;
              hint.ingredient = matched;
              hint.severity = cross.riskLevel;
              hint.detail = `${userAllergen}过敏者可能对${cross.crossReactive}交叉反应（${cross.mechanism}）`;
              hint.recommendation = riskLevelToAdvice(member.nickname, cross.riskLevel);
              hint.isCrossReactivity = true;
              hints.push(hint);
            }
          }
        }
      }
    }

    hilog.info(HILOG_DOMAIN_DEFAULT, TAG,
      'Allergen detection: %{public}d hints for %{public}s (%{public}d members)',
      hints.length, food.foodName, members.length);
    return hints;
  }
}

function riskLevelToAdvice(nickname: string, level: Severity): string {
  switch (level) {
    case Severity.HIGH: return `${nickname}强烈建议避免食用`;
    case Severity.MODERATE: return `${nickname}建议谨慎食用`;
    case Severity.LOW: return `${nickname}低风险，注意观察`;
    default: return `${nickname}可常规食用`;
  }
}
