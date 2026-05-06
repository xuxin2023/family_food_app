// FoodLabel.test.ets
// FoodLabel 模型单元测试

import { describe, it, expect } from '@ohos/hypium';
import { FoodLabel } from '../../main/ets/model/FoodLabel';

export default function foodLabelTest() {
  describe('FoodLabel', () => {
    it('newLabel_hasEmptyFoodId', 0, () => {
      const label = new FoodLabel();
      expect(label.foodId === '').assertTrue();
      expect(label.foodName === '').assertTrue();
    });

    it('highSodium_detected', 0, () => {
      const label = new FoodLabel();
      label.nutrition.sodium = 800;
      expect(label.isHighSodium()).assertTrue();
    });

    it('lowSodium_notHigh', 0, () => {
      const label = new FoodLabel();
      label.nutrition.sodium = 200;
      expect(label.isHighSodium()).assertFalse();
    });

    it('highSugar_detected', 0, () => {
      const label = new FoodLabel();
      label.nutrition.sugar = 25;
      expect(label.isHighSugar()).assertTrue();
    });

    it('setters_updateFields', 0, () => {
      const label = new FoodLabel();
      label.foodId = 'test-123';
      label.foodName = '测试食品';
      label.manufacturer = '测试厂商';
      expect(label.foodId === 'test-123').assertTrue();
      expect(label.foodName === '测试食品').assertTrue();
      expect(label.manufacturer === '测试厂商').assertTrue();
    });
  });
}
