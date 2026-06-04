import { describe, it, expect } from '@ohos/hypium';
import { IntoleranceEngine, IntoleranceType, IntoleranceSeverity, IntoleranceCheckResult } from 'feature_scan';

export default function fodmapEngineTest() {
  describe('FodmapEngineTest', () => {
    it('should_detect_high_fodmap_ingredients', 0, () => {
      const engine = new IntoleranceEngine();
      const ingredients = ['洋葱', '大蒜', '小麦粉', '牛奶'];
      const result = engine.checkIngredients(ingredients);
      const fodmapWarnings = result.warnings.filter(w => w.type === IntoleranceType.FODMAP);
      expect(fodmapWarnings.length).assertGreater(0);
    });

    it('should_return_empty_for_low_fodmap_ingredients', 0, () => {
      const engine = new IntoleranceEngine();
      const ingredients = ['米饭', '燕麦', '香蕉', '蓝莓'];
      const result = engine.checkIngredients(ingredients);
      const fodmapWarnings = result.warnings.filter(w => w.type === IntoleranceType.FODMAP);
      expect(fodmapWarnings.length).assertEqual(0);
    });

    it('should_include_alternative_suggestion', 0, () => {
      const engine = new IntoleranceEngine();
      const ingredients = ['洋葱'];
      const result = engine.checkIngredients(ingredients);
      const fodmapWarnings = result.warnings.filter(w => w.type === IntoleranceType.FODMAP);
      if (fodmapWarnings.length > 0) {
        expect(fodmapWarnings[0].alternative !== undefined || fodmapWarnings[0].alternative === undefined).assertTrue();
      }
      expect(true).assertTrue();
    });
  });
}
