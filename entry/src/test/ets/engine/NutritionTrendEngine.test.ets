// NutritionTrendEngine.test.ets
// 营养趋势引擎单元测试

import { describe, it, expect } from '@ohos/hypium';
import { NutritionTrendEngine } from '../../../main/ets/engine/NutritionTrendEngine';
import { DietRecord } from '../../../main/ets/repository/HistoryRepository';

export default function nutritionTrendTest() {
  describe('NutritionTrendEngine', () => {
    it('should aggregate empty records gracefully', () => {
      const records: DietRecord[] = [];
      const result = NutritionTrendEngine.aggregateDaily(records);
      expect(result.length).assertEqual(0);
    });

    it('should group records by date', () => {
      const records: DietRecord[] = [
        { recordId: '1', memberId: 'm1', date: '2026-05-01', mealType: 'breakfast',
          scenario: '', foodId: 'f1', amountG: 100,
          sodiumIntake: 200, sugarIntake: 10, calorieIntake: 300, fatIntake: 5, recordedAt: Date.now() },
        { recordId: '2', memberId: 'm1', date: '2026-05-01', mealType: 'lunch',
          scenario: '', foodId: 'f2', amountG: 150,
          sodiumIntake: 300, sugarIntake: 15, calorieIntake: 400, fatIntake: 8, recordedAt: Date.now() }
      ];
      const result = NutritionTrendEngine.aggregateDaily(records);
      expect(result.length).assertEqual(1);
      expect(result[0].date).assertEqual('2026-05-01');
    });

    it('should group by meal type', () => {
      const records: DietRecord[] = [
        { recordId: '1', memberId: 'm1', date: '2026-05-01', mealType: 'breakfast',
          scenario: '', foodId: 'f1', amountG: 100,
          sodiumIntake: 100, sugarIntake: 5, calorieIntake: 200, fatIntake: 3, recordedAt: Date.now() },
        { recordId: '2', memberId: 'm1', date: '2026-05-01', mealType: 'breakfast',
          scenario: '', foodId: 'f2', amountG: 200,
          sodiumIntake: 150, sugarIntake: 8, calorieIntake: 300, fatIntake: 5, recordedAt: Date.now() },
        { recordId: '3', memberId: 'm1', date: '2026-05-01', mealType: 'lunch',
          scenario: '', foodId: 'f3', amountG: 300,
          sodiumIntake: 500, sugarIntake: 20, calorieIntake: 600, fatIntake: 10, recordedAt: Date.now() }
      ];
      const result = NutritionTrendEngine.groupByMealType(records);
      expect(result.length).assertEqual(2);
    });
  });
}
