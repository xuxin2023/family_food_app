// NutritionTrendEngine.test.ets
// NutritionTrendEngine 单元测试（纯逻辑，无UI依赖）

import { describe, it, expect } from '@ohos/hypium';
import { NutritionTrendEngine, NutrientTrendData, TrendDirection } from '../../main/ets/engine/NutritionTrendEngine';

export default function nutritionTrendTest() {
  describe('NutritionTrendEngine', () => {
    it('calculateZScore_typicalValues', 0, () => {
      const engine = new NutritionTrendEngine();
      // 模拟7天钠摄入数据
      const trends: NutrientTrendData[] = [
        { date: '2026-05-01', sodium: 1800, sugar: 30, calorie: 1900, fat: 50 },
        { date: '2026-05-02', sodium: 2200, sugar: 45, calorie: 2100, fat: 55 },
        { date: '2026-05-03', sodium: 1500, sugar: 25, calorie: 1700, fat: 40 },
        { date: '2026-05-04', sodium: 2000, sugar: 35, calorie: 2000, fat: 52 },
        { date: '2026-05-05', sodium: 1700, sugar: 28, calorie: 1800, fat: 45 },
        { date: '2026-05-06', sodium: 2100, sugar: 50, calorie: 2200, fat: 60 },
        { date: '2026-05-07', sodium: 1900, sugar: 32, calorie: 1950, fat: 48 },
      ];
      const zScore = engine.calculateZScore(trends, 'sodium');
      // zScore 应为有限数字
      expect(zScore !== null && Number.isFinite(zScore)).assertTrue();
    });
  });
}
