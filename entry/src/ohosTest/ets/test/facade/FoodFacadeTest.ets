import { describe, it, expect } from '@ohos/hypium';
import { FoodFacade } from '../../../../../src/main/ets/facade/FoodFacade';
import { FoodLabel, NutritionPer100g, FamilyProfile, HealthSignal, DailyBudget, Recommendation } from '../../../../../../hsp_core/src/main/ets/model/FoodLabel';

class MockFoodRepository {
  private store: Map<string, FoodLabel> = new Map();

  async saveFoodLabel(label: FoodLabel): Promise<void> {
    this.store.set(label.foodId, label);
  }

  async findByBarcode(barcode: string): Promise<FoodLabel | null> {
    const arr = Array.from(this.store.values());
    return arr.find(l => l.barcode === barcode) ?? null;
  }

  async findById(foodId: string): Promise<FoodLabel | null> {
    return this.store.get(foodId) ?? null;
  }

  async findByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    const map = new Map<string, FoodLabel>();
    for (const id of foodIds) {
      const label = this.store.get(id);
      if (label) map.set(id, label);
    }
    return map;
  }
}

class MockHistoryRepository {
  async getRecentScanHistory(limit: number): Promise<Object[]> { return []; }
  async getDietRecordsByDateRange(mid: string, s: string, e: string): Promise<Object[]> { return []; }
  async getNutritionSnapshots(mid: string, limit: number): Promise<Object[]> { return []; }
  async saveDietRecord(record: Object): Promise<void> {}
}

class MockFavoriteRepository {
  async getAll(): Promise<Object[]> { return []; }
  async removeFavorite(foodId: string): Promise<void> {}
  async storeNutritionTarget(target: Object): Promise<void> {}
}

class MockEngineManager {
  calculateRecommendation(member: Object, signal: Object, foodLabel: Object, budget: Object): Recommendation {
    return new Recommendation();
  }
  calculateEnhancedAdaptation(member: Object, foodLabel: Object, signal: Object, intake: Object, count: number): Object {
    return {};
  }
  getMealBalance(member: Object, budget: Object, scenario: string, count: number): Object {
    return {};
  }
  getPositiveAdvice(foodLabel: Object, rec: Object): Object[] { return []; }
  getChildProtection(member: Object, foodLabel: Object, rec: Object): Object {
    return {};
  }
}

class MockCacheManager {
  getHealthSignalFromCache(mid: string): Object | null { return null; }
  setHealthSignalToCache(mid: string, signal: Object): void {}
}

export default function foodFacadeTest() {
  describe('FoodFacade', () => {
    it('saveFoodLabel_and_findById_should_work', 0, async () => {
      const foodRepo = new MockFoodRepository();
      const facade = new FoodFacade(
        foodRepo as Object,
        new MockHistoryRepository() as Object,
        new MockFavoriteRepository() as Object,
        new MockEngineManager() as Object,
        new MockCacheManager() as Object
      );

      const label = new FoodLabel();
      label.foodId = 'test-001';
      label.foodName = '测试牛奶';
      label.barcode = '6901234567890';

      await facade.saveFoodLabel(label);
      const found = await facade.findFoodById('test-001');
      expect(found).assertNotBeNull();
      if (found) {
        expect(found.foodName).assertEqual('测试牛奶');
      }
    });

    it('saveFoodLabel_and_findByBarcode_should_work', 0, async () => {
      const foodRepo = new MockFoodRepository();
      const facade = new FoodFacade(
        foodRepo as Object,
        new MockHistoryRepository() as Object,
        new MockFavoriteRepository() as Object,
        new MockEngineManager() as Object,
        new MockCacheManager() as Object
      );

      const label = new FoodLabel();
      label.foodId = 'test-002';
      label.foodName = '测试面包';
      label.barcode = '6909876543210';

      await facade.saveFoodLabel(label);
      const found = await facade.findFoodByBarcode('6909876543210');
      expect(found).assertNotBeNull();
      if (found) {
        expect(found.foodName).assertEqual('测试面包');
      }
    });

    it('findFoodById_should_return_null_for_missing', 0, async () => {
      const foodRepo = new MockFoodRepository();
      const facade = new FoodFacade(
        foodRepo as Object,
        new MockHistoryRepository() as Object,
        new MockFavoriteRepository() as Object,
        new MockEngineManager() as Object,
        new MockCacheManager() as Object
      );

      const found = await facade.findFoodById('nonexistent');
      expect(found).assertBeNull();
    });
  });
}