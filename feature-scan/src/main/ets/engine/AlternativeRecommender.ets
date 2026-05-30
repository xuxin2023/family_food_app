import { FoodLabel, NutritionPer100g, IOfflineFoodProvider, OfflineFoodEntry, NutritionThreshold } from 'hsp_core';
import { NutriScoreEngine } from './NutriScoreEngine';

export class AlternativeCandidate {
  foodName: string = '';
  barcode: string = '';
  brand: string = '';
  nutrition: NutritionPer100g = new NutritionPer100g();
  nutriGrade: string = '';
  improvements: string[] = [];
  category: string = '';
}

export class AlternativeRecommender {
  private provider: IOfflineFoodProvider;

  constructor(provider: IOfflineFoodProvider) {
    this.provider = provider;
  }

  recommend(current: FoodLabel): AlternativeCandidate[] {
    const currentNutrition = current.nutrition;
    const currentCategory = AlternativeRecommender.findCategory(current);
    const candidates: AlternativeCandidate[] = [];

    const db = this.provider.getAllEntries();
    for (let i = 0; i < db.length; i++) {
      const entry = db[i];
      if (entry.barcode === current.barcode) {
        continue;
      }
      if (currentCategory.length > 0 && entry.category !== currentCategory) {
        continue;
      }
      const candidate = AlternativeRecommender.buildCandidate(entry, currentNutrition);
      if (candidate.improvements.length > 0) {
        candidates.push(candidate);
      }
    }

    const sorted = [...candidates].sort((a: AlternativeCandidate, b: AlternativeCandidate) => {
      return b.improvements.length - a.improvements.length;
    });

    const result: AlternativeCandidate[] = [];
    for (let i = 0; i < sorted.length && i < 10; i++) {
      result.push(sorted[i]);
    }
    return result;
  }

  private static findCategory(food: FoodLabel): string {
    const name = food.foodName;
    const keywords: Map<string, string[]> = new Map();
    keywords.set('乳制品', ['牛奶', '酸奶', '乳', '奶酪']);
    keywords.set('饮料', ['可乐', '茶', '水', '果汁', '咖啡', '奶茶']);
    keywords.set('休闲零食', ['薯片', '辣条', '饼干', '坚果', '瓜子']);
    keywords.set('方便面', ['方便面', '泡面', '面']);
    keywords.set('主食', ['米', '面', '粉', '麦']);
    keywords.set('肉制品', ['火腿', '培根', '香肠', '肉']);
    keywords.set('调味品', ['酱油', '醋', '酱', '蚝油']);
    keywords.set('速冻食品', ['水饺', '汤圆', '手抓饼']);

    const keys = Array.from(keywords.keys());
    for (let ki = 0; ki < keys.length; ki++) {
      const category = keys[ki];
      const kws = keywords.get(category)!;
      for (let wi = 0; wi < kws.length; wi++) {
        if (name.includes(kws[wi])) {
          return category;
        }
      }
    }
    return '';
  }

  private static buildCandidate(entry: OfflineFoodEntry, current: NutritionPer100g): AlternativeCandidate {
    const candidate = new AlternativeCandidate();
    candidate.foodName = entry.foodName;
    candidate.barcode = entry.barcode;
    candidate.brand = entry.manufacturer;
    candidate.nutrition = entry.nutrition;
    candidate.category = entry.category;

    const breakdown = NutriScoreEngine.calculateFromNutrition(entry.nutrition);
    candidate.nutriGrade = breakdown.grade;

    const improvements: string[] = [];
    if (current.sodium > NutritionThreshold.HIGH_SODIUM_MG && entry.nutrition.sodium < current.sodium * 0.7) {
      const pct = Math.round((1 - entry.nutrition.sodium / current.sodium) * 100);
      improvements.push('钠减少' + pct + '%');
    }
    if (current.sugar > 8 && entry.nutrition.sugar < current.sugar * 0.7) {
      const pct = Math.round((1 - entry.nutrition.sugar / current.sugar) * 100);
      improvements.push('糖减少' + pct + '%');
    }
    if (current.fat > 10 && entry.nutrition.fat < current.fat * 0.7) {
      const pct = Math.round((1 - entry.nutrition.fat / current.fat) * 100);
      improvements.push('脂肪减少' + pct + '%');
    }
    if (current.calories > 200 && entry.nutrition.calories < current.calories * 0.7) {
      const pct = Math.round((1 - entry.nutrition.calories / current.calories) * 100);
      improvements.push('热量减少' + pct + '%');
    }
    if ((entry.nutrition.fiber ?? 0) > 5 && (entry.nutrition.fiber ?? 0) > (current.fiber ?? 0) * 1.5) {
      improvements.push('膳食纤维更丰富');
    }
    if (entry.nutrition.protein > 10 && entry.nutrition.protein > current.protein * 1.3) {
      improvements.push('蛋白质更高');
    }
    candidate.improvements = improvements;

    return candidate;
  }
}
