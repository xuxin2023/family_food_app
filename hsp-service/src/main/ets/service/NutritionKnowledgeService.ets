import { FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NutritionKnowledgeService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface KnowledgeEntry {
  id: string;
  title: string;
  category: string;
  summary: string;
  details: string;
  relatedNutrients: string[];
  references: string[];
}

export class NutritionKnowledgeService {
  private static instance: NutritionKnowledgeService | null = null;
  private cache: Map<string, KnowledgeEntry> = new Map();

  static getInstance(): NutritionKnowledgeService {
    if (!NutritionKnowledgeService.instance) {
      NutritionKnowledgeService.instance = new NutritionKnowledgeService();
    }
    return NutritionKnowledgeService.instance;
  }

  searchByKeyword(keyword: string): KnowledgeEntry[] {
    const results: KnowledgeEntry[] = [];
    for (const entry of this.cache.values()) {
      if (entry.title.includes(keyword) || entry.summary.includes(keyword) ||
          entry.details.includes(keyword) || entry.relatedNutrients.some(n => n.includes(keyword))) {
        results.push(entry);
      }
    }
    return results;
  }

  searchByCategory(category: string): KnowledgeEntry[] {
    const results: KnowledgeEntry[] = [];
    for (const entry of this.cache.values()) {
      if (entry.category === category) {
        results.push(entry);
      }
    }
    return results;
  }

  getRelatedToFood(foodLabel: FoodLabel): KnowledgeEntry[] {
    const keywords: string[] = [];
    if (foodLabel.nutrition.sodium > 500) keywords.push('钠');
    if (foodLabel.nutrition.sugar > 15) keywords.push('糖');
    if (foodLabel.nutrition.fat > 20) keywords.push('脂肪');
    if (foodLabel.nutrition.protein > 10) keywords.push('蛋白质');
    if (foodLabel.nutrition.fiber > 3) keywords.push('膳食纤维');
    keywords.push(...foodLabel.allergens);

    const results: KnowledgeEntry[] = [];
    const seen = new Set<string>();
    for (const kw of keywords) {
      for (const entry of this.searchByKeyword(kw)) {
        if (!seen.has(entry.id)) {
          seen.add(entry.id);
          results.push(entry);
        }
      }
    }
    return results;
  }

  addEntry(entry: KnowledgeEntry): void {
    this.cache.set(entry.id, entry);
  }

  getAllCategories(): string[] {
    const categories = new Set<string>();
    for (const entry of this.cache.values()) {
      categories.add(entry.category);
    }
    return Array.from(categories);
  }
}
