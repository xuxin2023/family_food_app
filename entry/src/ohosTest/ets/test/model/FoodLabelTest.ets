// FoodLabel 单元测试 - 食品标签模型
import { describe, it, expect } from '@ohos/hypium';
import { FoodLabel, NutritionPer100g, FoodLabelJson, FoodSource, JsonHelper } from 'hsp_core';

function jsonParse(text: string): Map<string, Object> {
  const raw = JSON.parse(text) as Record<string, Object>;
  return JsonHelper.recordToMap(raw);
}

function createFoodLabel(sodium: number, sugar: number, calories: number, fat: number,
  saturatedFat: number, carbohydrate: number, protein: number,
  ingredients: string[], allergenHints: string[], manufacturer: string,
  scNumber: string, source: FoodSource, identifiedAt: number,
  barcode: string, foodName: string, foodId: string,
  principal: string, traceCode: string): FoodLabel {
  const food: FoodLabel = new FoodLabel();
  food.foodId = foodId;
  food.foodName = foodName;
  food.barcode = barcode;
  food.ingredients = ingredients;
  food.nutrition = new NutritionPer100g();
  food.nutrition.sodium = sodium;
  food.nutrition.sugar = sugar;
  food.nutrition.calories = calories;
  food.nutrition.fat = fat;
  food.nutrition.saturatedFat = saturatedFat;
  food.nutrition.carbohydrate = carbohydrate;
  food.nutrition.protein = protein;
  food.allergenHints = allergenHints;
  food.manufacturer = manufacturer;
  food.scNumber = scNumber;
  food.source = source;
  food.identifiedAt = identifiedAt;
  food.principal = principal;
  food.traceCode = traceCode;
  return food;
}

function createDefaultFoodLabel(): FoodLabel {
  return createFoodLabel(300, 10, 250, 8, 2, 40, 5,
    ['小麦', '水', '盐', '植物油'], ['含有麸质', '含有乳制品'],
    '测试食品有限公司', 'SC12345678901234', FoodSource.USER_UPLOAD,
    1700000000000, '123456789', '测试食品', 'food_1',
    '', '');
}

export default function foodLabelTest() {
  describe('FoodLabel', () => {

    // ========== 食品状态检测 ==========

    it('should_detect_high_sodium', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.nutrition.sodium = 500;
      expect(food.isHighSodium()).assertTrue();
    });

    it('should_not_detect_normal_sodium_as_high', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.nutrition.sodium = 100;
      expect(food.isHighSodium()).assertFalse();
    });

    it('should_detect_high_sugar', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.nutrition.sugar = 15;
      expect(food.isHighSugar()).assertTrue();
    });

    it('should_not_detect_normal_sugar_as_high', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.nutrition.sugar = 5;
      expect(food.isHighSugar()).assertFalse();
    });

    it('should_detect_high_fat', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.nutrition.fat = 20;
      expect(food.isHighFat()).assertTrue();
    });

    it('should_not_detect_normal_fat_as_high', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.nutrition.fat = 5;
      expect(food.isHighFat()).assertFalse();
    });

    it('should_detect_high_calorie', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.nutrition.calories = 400;
      expect(food.isHighCalorie()).assertTrue();
    });

    it('should_not_detect_normal_calorie_as_high', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.nutrition.calories = 100;
      expect(food.isHighCalorie()).assertFalse();
    });

    // ========== 生产商信息 ==========

    it('should_detect_oem_production', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.principal = '委托方公司';
      expect(food.isOem()).assertTrue();
    });

    it('should_detect_non_oem_production', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.principal = '';
      expect(food.isOem()).assertFalse();
    });

    it('should_detect_manufacturer_exists', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.manufacturer = '某食品公司';
      expect(food.hasManufacturer()).assertTrue();
    });

    it('should_detect_missing_manufacturer', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.manufacturer = '';
      expect(food.hasManufacturer()).assertFalse();
    });

    it('should_detect_sc_number_exists', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.scNumber = 'SC1234';
      expect(food.hasScNumber()).assertTrue();
    });

    it('should_detect_trace_code_exists', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.traceCode = 'TRACE001';
      expect(food.hasTraceCode()).assertTrue();
    });

    it('should_detect_missing_trace_code', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.traceCode = '';
      expect(food.hasTraceCode()).assertFalse();
    });

    // ========== 配料文本 ==========

    it('should_join_ingredients_with_comma', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.ingredients = ['水', '盐', '糖'];
      expect(food.ingredientsText()).assertEqual('水,盐,糖');
    });

    it('should_return_empty_for_no_ingredients', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      food.ingredients = [];
      expect(food.ingredientsText()).assertEqual('');
    });

    // ========== JSON序列化 ==========

    it('should_serialize_to_json', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      const json: FoodLabelJson = food.toJson();

      expect(json.foodId).assertEqual('food_1');
      expect(json.foodName).assertEqual('测试食品');
      expect(json.barcode).assertEqual('123456789');
      expect(json.source).assertEqual(FoodSource.USER_UPLOAD);
      expect(json.manufacturer).assertEqual('测试食品有限公司');
    });

    it('should_deserialize_from_json', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      const jsonObj: FoodLabelJson = food.toJson();
      const jsonStr: string = JSON.stringify(jsonObj);
      const restored: FoodLabel = FoodLabel.fromJson(jsonParse(jsonStr));

      expect(restored.foodId).assertEqual('food_1');
      expect(restored.foodName).assertEqual('测试食品');
      expect(restored.barcode).assertEqual('123456789');
      expect(restored.nutrition.sodium).assertEqual(300);
      expect(restored.nutrition.sugar).assertEqual(10);
      expect(restored.manufacturer).assertEqual('测试食品有限公司');
      expect(restored.source).assertEqual(FoodSource.USER_UPLOAD);
    });

    it('should_preserve_allergen_hints_through_json_round_trip', 0, () => {
      const food: FoodLabel = createDefaultFoodLabel();
      const jsonObj: FoodLabelJson = food.toJson();
      const jsonStr: string = JSON.stringify(jsonObj);
      const restored: FoodLabel = FoodLabel.fromJson(jsonParse(jsonStr));

      expect(restored.allergenHints.length).assertEqual(2);
      expect(restored.allergenHints[0]).assertEqual('含有麸质');
    });
  });
}
