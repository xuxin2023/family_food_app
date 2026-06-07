import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'OcrParser';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface OcrParseResult {
  ingredients: string[];
  additives: string[];
  allergenHints: string[];
  confidence: number;
  rawText: string;
}

export class OcrParser {
  private static readonly SEPARATOR_PATTERNS: RegExp[] = [
    /[、，,;；\n]/,
    /\s+/,
    /[：:]/,
    /[（(]/,
    /[）)]/,
  ];

  private static readonly UNIT_PATTERN: RegExp = /[\d.]+\s*(g|mg|kg|μg|µg|%|ml|L|IU)/gi;

  private static readonly COMMON_TYPOS: Map<string, string> = new Map([
    ['安赛蜜钾', '安赛蜜'],
    ['阿斯匹林', '阿司匹林'],
    ['维生素C钠', '抗坏血酸钠'],
    ['维生素E', '生育酚'],
    ['脱氢醋酸', '脱氢乙酸'],
    ['山梨酸', '山梨酸钾'],
    ['笨甲酸钠', '苯甲酸钠'],
    ['柠檬酸纳', '柠檬酸钠'],
  ]);

  private static readonly ALLERGEN_KEYWORDS: string[] = [
    '花生', '牛奶', '鸡蛋', '小麦', '大豆', '鱼', '甲壳类', '贝类',
    '芝麻', '坚果', '杏仁', '核桃', '榛子', '腰果', '乳糖', '麸质'
  ];

  parseOcrText(rawText: string): OcrParseResult {
    if (!rawText || rawText.trim().length === 0) {
      return { ingredients: [], additives: [], allergenHints: [], confidence: 0, rawText } as Record<string, Object>;
    }

    const cleanedText = this.preprocess(rawText);
    const ingredients = this.splitIngredients(cleanedText);
    const correctedIngredients = ingredients.map(i => this.correctTypo(i));
    const additives = this.identifyAdditives(correctedIngredients);
    const allergenHints = this.detectAllergenHints(correctedIngredients);
    const confidence = this.estimateConfidence(rawText, correctedIngredients);

    hilog.info(DOMAIN_ZERO, TAG,
      'OCR parse: %{public}d ingredients, %{public}d additives, %{public}d allergens, confidence=%.2f',
      correctedIngredients.length, additives.length, allergenHints.length, confidence);

    return {
      ingredients: correctedIngredients,
      additives,
      allergenHints,
      confidence,
      rawText
    };
  }

  private preprocess(text: string): string {
    let cleaned = text.replace(/[^\u4e00-\u9fa5a-zA-Z0-9、，,;；\n\s()%]/g, '');
    cleaned = cleaned.replace(/\n{2,}/g, '\n');
    return cleaned.trim();
  }

  private splitIngredients(text: string): string[] {
    const parts: string[] = [text];

    for (const pattern of OcrParser.SEPARATOR_PATTERNS) {
      const newParts: string[] = [];
      for (const part of parts) {
        const split = part.split(pattern);
        newParts.push(...split);
      }
      parts.length = 0;
      parts.push(...newParts);
    }

    return parts
      .map(p => p.trim())
      .filter(p => p.length >= 2)
      .filter(p => !OcrParser.UNIT_PATTERN.test(p));
  }

  private correctTypo(ingredient: string): string {
    const corrected = OcrParser.COMMON_TYPOS.get(ingredient);
    return corrected ?? ingredient;
  }

  private identifyAdditives(ingredients: string[]): string[] {
    const additivePrefixes = ['E', 'INS', 'CNS'];
    return ingredients.filter(i => {
      const upper = i.toUpperCase();
      return additivePrefixes.some(prefix => upper.startsWith(prefix)) ||
        i.match(/^[E]\d{3}[a-z]?$/i) !== null;
    });
  }

  private detectAllergenHints(ingredients: string[]): string[] {
    const hints: string[] = [];
    for (const ingredient of ingredients) {
      for (const keyword of OcrParser.ALLERGEN_KEYWORDS) {
        if (ingredient.includes(keyword)) {
          if (!hints.includes(keyword)) {
            hints.push(keyword);
          }
        }
      }
    }
    return hints;
  }

  private estimateConfidence(rawText: string, ingredients: string[]): number {
    if (ingredients.length === 0) return 0;
    const avgLen = ingredients.reduce((sum, i) => sum + i.length, 0) / ingredients.length;
    const chineseRatio = (rawText.match(/[\u4e00-\u9fa5]/g) ?? []).length / Math.max(rawText.length, 1);
    let confidence = 0.5;
    if (ingredients.length >= 3) confidence += 0.15;
    if (ingredients.length >= 6) confidence += 0.1;
    if (avgLen >= 2 && avgLen <= 10) confidence += 0.1;
    if (chineseRatio > 0.3) confidence += 0.1;
    return Math.min(confidence, 0.95);
  }
}
