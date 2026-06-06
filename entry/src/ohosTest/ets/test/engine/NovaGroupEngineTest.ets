import { describe, it, expect } from '@ohos/hypium';
import {
  NovaGroupEngine, NovaGroup, NovaEvaluationResult
} from 'feature_scan';

export default function novaGroupEngineTest() {
  describe('NovaGroupEngine', () => {
    const engine: NovaGroupEngine = new NovaGroupEngine()

    it('should_return_group1_for_unprocessed_food', 0, () => {
      const result = engine.evaluate(['苹果']);
      expect(result.group).assertEqual(NovaGroup.GROUP_1);
    });

    it('should_return_group1_for_single_ingredient', 0, () => {
      const result = engine.evaluate(['鸡胸肉']);
      expect(result.group).assertEqual(NovaGroup.GROUP_1);
    });

    it('should_return_group4_for_ultra_processed', 0, () => {
      const result = engine.evaluate(['小麦粉', '氢化植物油', '山梨酸钾', 'BHA', '阿斯巴甜']);
      expect(result.group).assertEqual(NovaGroup.GROUP_4);
      expect(result.matchedMarkers.length).assertGreater(0);
    });

    it('should_return_group4_for_single_ultra_marker', 0, () => {
      const result = engine.evaluate(['面粉', '味精']);
      expect(result.group).assertEqual(NovaGroup.GROUP_4);
    });

    it('should_return_group2_for_culinary_ingredient', 0, () => {
      const result = engine.evaluate(['白糖', '面粉', '鸡蛋', '牛奶', '植物油', '盐', '泡打粉']);
      expect(result.group).assertEqual(NovaGroup.GROUP_2);
    });

    it('should_return_group1_for_empty_ingredients', 0, () => {
      const result = engine.evaluate([]);
      expect(result.group).assertEqual(NovaGroup.GROUP_1);
    });

    it('should_return_group4_for_emulsifiers', 0, () => {
      const result = engine.evaluate(['单甘油酯', '黄原胶']);
      expect(result.group).assertEqual(NovaGroup.GROUP_4);
    });

    it('getLabel_should_return_correct_label', 0, () => {
      expect(engine.getLabel(NovaGroup.GROUP_1)).assertEqual('未加工/微加工');
      expect(engine.getLabel(NovaGroup.GROUP_2)).assertEqual('加工烹饪配料');
      expect(engine.getLabel(NovaGroup.GROUP_3)).assertEqual('加工食品');
      expect(engine.getLabel(NovaGroup.GROUP_4)).assertEqual('超加工食品');
    });

    it('getColor_should_return_valid_hex', 0, () => {
      const color1 = engine.getColor(NovaGroup.GROUP_1);
      expect(color1.startsWith('#')).assertTrue();
      expect(color1.length).assertEqual(7);

      const color4 = engine.getColor(NovaGroup.GROUP_4);
      expect(color4.startsWith('#')).assertTrue();
      expect(color4).assertEqual('#F44336');
    });

    it('getColor_should_return_grey_for_unknown', 0, () => {
      const color = engine.getColor(NovaGroup.UNKNOWN);
      expect(color).assertEqual('#9E9E9E');
    });

    it('getDescription_should_return_non_empty', 0, () => {
      const desc1 = engine.getDescription(NovaGroup.GROUP_1);
      expect(desc1.length).assertGreater(0);

      const desc4 = engine.getDescription(NovaGroup.GROUP_4);
      expect(desc4.length).assertGreater(0);
      expect(desc4.includes('工业')).assertTrue();
    });

    it('result_should_have_populated_fields', 0, () => {
      const result = engine.evaluate(['小麦粉', '氢化植物油', '山梨酸钾']);
      expect(result.label.length).assertGreater(0);
      expect(result.color.length).assertGreater(0);
      expect(result.description.length).assertGreater(0);
      expect(result.summary.length).assertGreater(0);
    });
  });
}