import { describe, it, expect } from '@ohos/hypium';
import { AlternativeRecommender, AlternativeCandidate } from '../../../../../../feature-scan/src/main/ets/engine/AlternativeRecommender';

class MockOfflineFoodProvider implements IOfflineFoodProvider {
  private entries: OfflineFoodEntry[] = [];

  setEntries(entries: OfflineFoodEntry[]): void {
    this.entries = entries;
  }

  getAllEntries(): OfflineFoodEntry[] {
    return this.entries;
  }
}

export default function alternativeRecommenderTest() {
  describe('AlternativeRecommenderTest', () => {
    it('should_return_empty_when_no_candidates', 0, () => {
      const provider = new MockOfflineFoodProvider();
      provider.setEntries([]);
      const recommender = new AlternativeRecommender(provider);
      const current = new FoodLabel();
      current.barcode = '001';
      current.foodName = '测试牛奶';
      const result = recommender.recommend(current);
      expect(result.length).assertEqual(0);
    });

    it('should_skip_same_barcode', 0, () => {
      const provider = new MockOfflineFoodProvider();
      const entry = new OfflineFoodEntry();
      entry.barcode = '001';
      entry.foodName = '测试牛奶';
      entry.category = '乳制品';
      provider.setEntries([entry]);
      const recommender = new AlternativeRecommender(provider);
      const current = new FoodLabel();
      current.barcode = '001';
      current.foodName = '测试牛奶';
      const result = recommender.recommend(current);
      expect(result.length).assertEqual(0);
    });

    it('should_limit_to_10_results', 0, () => {
      const provider = new MockOfflineFoodProvider();
      const entries: OfflineFoodEntry[] = [];
      for (let i = 0; i < 15; i++) {
        const entry = new OfflineFoodEntry();
        entry.barcode = `bc_${i}`;
        entry.foodName = `候选_${i}`;
        entry.category = '饮料';
        entry.nutrition = new NutritionPer100g();
        entry.nutrition.sodium = 10;
        entry.nutrition.sugar = 2;
        entry.nutrition.fat = 1;
        entry.nutrition.calories = 50;
        entries.push(entry);
      }
      provider.setEntries(entries);
      const recommender = new AlternativeRecommender(provider);
      const current = new FoodLabel();
      current.barcode = 'cur';
      current.foodName = '可乐';
      current.nutrition = new NutritionPer100g();
      current.nutrition.sodium = 200;
      current.nutrition.sugar = 30;
      current.nutrition.fat = 15;
      current.nutrition.calories = 400;
      const result = recommender.recommend(current);
      expect(result.length).assertLessorEqual(10);
    });
  });
}
