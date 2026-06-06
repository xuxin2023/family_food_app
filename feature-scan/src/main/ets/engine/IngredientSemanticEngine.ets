import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'IngredientSemanticEngine';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

class AllergenSynonym {
  canonical: string = '';
  synonyms: string[] = [];
}

function mkSynonym(c: string, s: string[]): AllergenSynonym {
  const item: AllergenSynonym = new AllergenSynonym()
  item.canonical = c;
  item.synonyms = s;
  return item;
}

const ALLERGEN_SYNONYMS: AllergenSynonym[] = [
  mkSynonym('牛奶', ['牛奶', '乳', '乳制品', '奶粉', '脱脂奶粉', '全脂奶粉', '乳清蛋白', '酪蛋白', '奶油', '黄油', '芝士', '奶酪', '炼乳']),
  mkSynonym('鸡蛋', ['鸡蛋', '蛋', '蛋黄', '蛋白', '卵蛋白', '卵磷脂']),
  mkSynonym('花生', ['花生', '花生酱', '花生油', '落花生']),
  mkSynonym('坚果', ['坚果', '杏仁', '核桃', '腰果', '榛子', '开心果', '夏威夷果', '巴旦木', '胡桃', '碧根果']),
  mkSynonym('大豆', ['大豆', '黄豆', '豆制品', '大豆蛋白', '豆粕', '酱油', '豆瓣酱', '豆腐']),
  mkSynonym('小麦', ['小麦', '面粉', '麦麸', '面筋', '小麦粉', '全麦粉', '麦芽']),
  mkSynonym('鱼', ['鱼', '鱼肉', '鱼粉', '鱼油', '三文鱼', '金枪鱼', '鳕鱼']),
  mkSynonym('甲壳类', ['虾', '蟹', '龙虾', '对虾', '基围虾', '甲壳类']),
  mkSynonym('芝麻', ['芝麻', '芝麻酱', '芝麻油', '麻酱']),
  mkSynonym('亚硫酸盐', ['亚硫酸盐', '二氧化硫', '焦亚硫酸钠', '亚硫酸钠'])
];

const TRACE_KEYWORDS_ZH: string[] = [
  '可能含有', '可能含', '可能包含', '可能存在',
  '生产线共用', '同一生产线', '共线生产',
  '加工设施也处理', '工厂也生产', '工厂也加工',
  '微量', '痕迹量', '痕量'
];

export class TraceDeclaration {
  allergens: string[] = [];
  rawText: string = '';
}

export class AllergenMatchResult {
  directAllergens: string[] = [];
  traceAllergens: string[] = [];
  traceDeclarations: TraceDeclaration[] = [];
  matchedDetails: AllergenMatchDetail[] = [];
}

export class AllergenMatchDetail {
  ingredient: string = '';
  canonical: string = '';
  isTrace: boolean = false;
}

export class IngredientSemanticEngine {
  private static synonymIndex: Map<string, string> = new Map();

  static initialize(): void {
    if (IngredientSemanticEngine.synonymIndex.size > 0) return;
    for (const entry of ALLERGEN_SYNONYMS) {
      for (const syn of entry.synonyms) {
        IngredientSemanticEngine.synonymIndex.set(syn.toLowerCase(), entry.canonical);
      }
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Synonym index built: %{public}d entries',
      IngredientSemanticEngine.synonymIndex.size);
  }

  static analyzeIngredients(ingredientsText: string, userAllergens: string[]): AllergenMatchResult {
    IngredientSemanticEngine.initialize();

    const result: AllergenMatchResult = new AllergenMatchResult(

    if (!ingredientsText || ingredientsText.length === 0) return result;

    const lines = ingredientsText.split(/[;；,，\n]/);
    const traceTexts: string[] = [];

    for (let line of lines) {
      line = line.trim();
      if (line.length === 0) continue;

      const isTraceLine = TRACE_KEYWORDS_ZH.some(kw => line.includes(kw));
      if (isTraceLine) {
        traceTexts.push(line);
        continue;
      }

      const matched = IngredientSemanticEngine.matchAllergen(line);
      if (matched) {
        if (!result.directAllergens.includes(matched)) {
          result.directAllergens.push(matched);
        }
        const detail: AllergenMatchDetail = new AllergenMatchDetail()
        detail.ingredient = line;
        detail.canonical = matched;
        detail.isTrace = false;
        result.matchedDetails.push(detail);
      }
    }

    for (const traceText of traceTexts) {
      const traceAllergens: string[] = [];
      const matched = IngredientSemanticEngine.matchAllergen(traceText);
      if (matched) {
        traceAllergens.push(matched);
        if (!result.traceAllergens.includes(matched)) {
          result.traceAllergens.push(matched);
        }
        const detail: AllergenMatchDetail = new AllergenMatchDetail()
        detail.ingredient = traceText;
        detail.canonical = matched;
        detail.isTrace = true;
        result.matchedDetails.push(detail);
      }
      const td: TraceDeclaration = new TraceDeclaration()
      td.allergens = traceAllergens;
      td.rawText = traceText;
      result.traceDeclarations.push(td);
    }

    const userSet = new Set(userAllergens.map(a => a.toLowerCase()));
    result.directAllergens = result.directAllergens.filter(a => {
      const lower = a.toLowerCase();
      return userSet.has(lower) || userAllergens.some(ua => ua.includes(a) || a.includes(ua));
    });
    result.traceAllergens = result.traceAllergens.filter(a => {
      const lower = a.toLowerCase();
      return userSet.has(lower) || userAllergens.some(ua => ua.includes(a) || a.includes(ua));
    });

    return result;
  }

  static containsAllergen(ingredient: string, allergen: string): boolean {
    try {
      IngredientSemanticEngine.initialize();
      const allergenLower = allergen.toLowerCase();
      const matchedCanonical = IngredientSemanticEngine.matchAllergen(ingredient);
      if (matchedCanonical !== null) {
        if (matchedCanonical.toLowerCase() === allergenLower) return true;
        const userCanonical = IngredientSemanticEngine.synonymIndex.get(allergenLower);
        if (userCanonical !== undefined && userCanonical === matchedCanonical) return true;
      }
      return ingredient.toLowerCase().includes(allergenLower);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'containsAllergen failed: %{public}s', JSON.stringify(e));
      return ingredient.toLowerCase().includes(allergen.toLowerCase());
    }
  }

  private static matchAllergen(ingredient: string): string | null {
    const lower = ingredient.toLowerCase();
    let bestMatch: string | null = null;
    let bestLength = 0;

    IngredientSemanticEngine.synonymIndex.forEach((canonical: string, syn: string) => {
      if (lower.includes(syn) && syn.length > bestLength) {
        bestMatch = canonical;
        bestLength = syn.length;
      }
    });

    return bestMatch;
  }
}
