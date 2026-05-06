// FoodLabel.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { FoodLabel, NutritionPer100g, FoodSource } from '../../../main/ets/model/FoodLabel';

export default function foodLabelTest() {
  describe('FoodLabelTest', () => {
    it('should_detect_high_sodium', 0, () => {
      const label = createTestFoodLabel();
      label.nutrition.sodium = 800;
      expect(label.nutrition.isHighSodium()).assertTrue();
    });

    it('should_detect_low_sodium', 0, () => {
      const label = createTestFoodLabel();
      label.nutrition.sodium = 100;
      expect(label.nutrition.isHighSodium()).assertFalse();
    });

    it('should_detect_high_sugar', 0, () => {
      const label = createTestFoodLabel();
      label.nutrition.sugar = 15;
      expect(label.nutrition.isHighSugar()).assertTrue();
    });

    it('should_detect_low_sugar', 0, () => {
      const label = createTestFoodLabel();
      label.nutrition.sugar = 3;
      expect(label.nutrition.isHighSugar()).assertFalse();
    });

    it('should_detect_high_fat', 0, () => {
      const label = createTestFoodLabel();
      label.nutrition.fat = 30;
      expect(label.nutrition.isHighFat()).assertTrue();
    });

    it('should_detect_low_fat', 0, () => {
      const label = createTestFoodLabel();
      label.nutrition.fat = 2;
      expect(label.nutrition.isHighFat()).assertFalse();
    });

    it('should_detect_high_calories', 0, () => {
      const label = createTestFoodLabel();
      label.nutrition.calories = 500;
      expect(label.nutrition.isHighCalories()).assertTrue();
    });

    it('should_serialize_to_json', 0, () => {
      const label = createTestFoodLabel();
      const json = label.toJson();
      expect(json).assertNotEmpty();
    });

    it('should_deserialize_from_json', 0, () => {
      const label = createTestFoodLabel();
      const json = JSON.stringify(label.toJson());
      const parsed = JSON.parse(json) as Record<string, Object>;
      expect(parsed['foodName'] as string).assertEqual('测试食品');
    });
  });
}

function createTestFoodLabel(): FoodLabel {
  const label = new FoodLabel();
  label.foodId = 'test_001';
  label.foodName = '测试食品';
  label.barcode = '6901234567890';
  label.nutrition = new NutritionPer100g();
  label.nutrition.sodium = 300;
  label.nutrition.sugar = 10;
  label.nutrition.fat = 15;
  label.nutrition.calories = 250;
  label.nutrition.protein = 5;
  label.nutrition.carbohydrate = 30;
  label.ingredients = ['水', '糖', '盐'];
  label.manufacturer = '测试厂商';
  label.scNumber = 'SC12345678901234';
  label.source = FoodSource.MANUAL;
  return label;
}
