import { describe, it, expect } from '@ohos/hypium';
import { FoodFacade } from '../../../../../src/main/ets/facade/FoodFacade';
import { FoodLabel, NutritionPer100g, FamilyProfile, HealthSignal, DailyBudget, Recommendation, EnhancedFoodRecommendation, MealBalance, ChildProtection, NutritionSnapshot, DietRecord, CacheManager, NutritionTarget } from 'hsp_core';
import { FoodRepository } from '../../../../../src/main/ets/repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord, DietRecordInput } from '../../../../../src/main/ets/repository/HistoryRepository';
import { FavoriteRepository, FavoriteItem } from '../../../../../src/main/ets/repository/FavoriteRepository';
import { EngineManager } from '../../../../../src/main/ets/EngineManager';
import { PositiveAdvice } from 'feature_report';

class MockFoodRepository extends FoodRepository {
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

class MockHistoryRepository extends HistoryRepository {
  async getRecentScanHistory(_limit: number): Promise<ScanHistoryRecord[]> { return []; }
  async getDietRecordsByDateRange(_mid: string, _s: string, _e: string): Promise<DietRecord[]> { return []; }
  async getNutritionSnapshots(_mid: string, _limit: number): Promise<NutritionSnapshot[]> { return []; }
  async saveDietRecord(_record: DietRecordInput): Promise<void> {}
}

class MockFavoriteRepository extends FavoriteRepository {
  async getAll(): Promise<FavoriteItem[]> { return []; }
  async removeFavorite(_foodId: string): Promise<boolean> { return true; }
  async storeNutritionTarget(_target: NutritionTarget): Promise<void> {}
}

class MockEngineManager extends EngineManager {
  calculateRecommendation(_member: FamilyProfile, _signal: HealthSignal, _foodLabel: FoodLabel, _budget: DailyBudget): Recommendation {
    return new Recommendation();
  }
  calculateEnhancedAdaptation(_member: FamilyProfile, _foodLabel: FoodLabel, _signal: HealthSignal, _intake: Object, _count: number): EnhancedFoodRecommendation {
    return new EnhancedFoodRecommendation();
  }
  getMealBalance(_member: FamilyProfile, _budget: DailyBudget, _scenario: string, _count: number): MealBalance {
    return new MealBalance();
  }
  getPositiveAdvice(_foodLabel: FoodLabel, _rec: Recommendation): PositiveAdvice[] { return []; }
  getChildProtection(_member: FamilyProfile, _foodLabel: FoodLabel, _rec: Recommendation): ChildProtection {
    return new ChildProtection();
  }
}

class MockCacheManager extends CacheManager {
  getHealthSignalFromCache(_mid: string): HealthSignal | undefined { return undefined; }
  setHealthSignalToCache(_mid: string, _signal: HealthSignal): void {}
}

export default function foodFacadeTest() {
  describe('FoodFacade', () => {
    it('saveFoodLabel_and_findById_should_work', 0, async () => {
      const foodRepo: MockFoodRepository = new MockFoodRepository()
      const facade: FoodFacade = new FoodFacade(
        foodRepo,
        new MockHistoryRepository(),
        new MockFavoriteRepository(),
        new MockEngineManager(),
        new MockCacheManager()
      );

      const label: FoodLabel = new FoodLabel()
      label.foodId = 'test-001';
      label.foodName = '测试牛奶';
      label.barcode = '6901234567890';

      await facade.saveFoodLabel(label);
      const found = await facade.findFoodById('test-001');
      expect(found !== null).assertTrue();
      if (found) {
        expect(found.foodName).assertEqual('测试牛奶');
      }
    });

    it('saveFoodLabel_and_findByBarcode_should_work', 0, async () => {
      const foodRepo: MockFoodRepository = new MockFoodRepository()
      const facade: FoodFacade = new FoodFacade(
        foodRepo,
        new MockHistoryRepository(),
        new MockFavoriteRepository(),
        new MockEngineManager(),
        new MockCacheManager()
      );

      const label: FoodLabel = new FoodLabel()
      label.foodId = 'test-002';
      label.foodName = '测试面包';
      label.barcode = '6909876543210';

      await facade.saveFoodLabel(label);
      const found = await facade.findFoodByBarcode('6909876543210');
      expect(found !== null).assertTrue();
      if (found) {
        expect(found.foodName).assertEqual('测试面包');
      }
    });

    it('findFoodById_should_return_null_for_missing', 0, async () => {
      const foodRepo: MockFoodRepository = new MockFoodRepository()
      const facade: FoodFacade = new FoodFacade(
        foodRepo,
        new MockHistoryRepository(),
        new MockFavoriteRepository(),
        new MockEngineManager(),
        new MockCacheManager()
      );

      const found = await facade.findFoodById('nonexistent');
      expect(found === null).assertTrue();
    });
  });
}