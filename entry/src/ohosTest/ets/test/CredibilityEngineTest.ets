// CredibilityEngine 单元测试 - 食品可信度雷达模�?

import { describe, it, expect } from '@ohos/hypium';
import { CredibilityEngine } from '../../../../src/main/ets/engine/CredibilityEngine';
import { CredibilityResult, DataGrade } from '../../../../src/main/ets/model/CredibilityResult';
import { FoodLabel, FoodSource } from '../../../../src/main/ets/model/FoodLabel';

function createFood(manufacturer: string = '', scNumber: string = '',
  principal: string = '', trustee: string = '',
  traceCode: string = ''): FoodLabel {
  const f = new FoodLabel();
  f.foodId = 'test'; f.foodName = '测试食品';
  f.nutrition = { sodium: 100, sugar: 5, calories: 200, fat: 10, saturatedFat: 3, carbohydrate: 15, protein: 5 };
  f.ingredients = ['大米'];
  f.manufacturer = manufacturer;
  f.scNumber = scNumber;
  f.principal = principal;
  f.trustee = trustee;
  f.traceCode = traceCode;
  f.source = FoodSource.USER_UPLOAD;
  f.identifiedAt = Date.now();
  return f;
}

export default function credibilityEngineTest() {
  describe('CredibilityEngine', () => {

    it('should_return_high_score_when_full_info', () => {
      const engine: CredibilityEngine = new CredibilityEngine();
      const food = createFood('XX食品有限公司', 'SC10633018501234', '', '', 'TRACE123');
      const result = engine.calculate(food);
      expect(result.score).assertLargerThan(60);
      expect(result.manufacturerClear).assertTrue();
      expect(result.scNumberClear).assertTrue();
    });

    it('should_return_low_score_when_no_info', () => {
      const engine: CredibilityEngine = new CredibilityEngine();
      const food = createFood('', '', '', '', '');
      const result = engine.calculate(food);
      expect(result.score).assertLessThan(40);
      expect(result.manufacturerMissing).assertTrue();
    });

    it('should_detect_oem_relation', () => {
      const engine: CredibilityEngine = new CredibilityEngine();
      const food = createFood('XX食品有限公司', 'SC10633018501234', 'YY品牌公司', 'XX食品有限公司');
      const result = engine.calculate(food);
      expect(result.oemRelationClear).assertTrue();
    });

    it('should_flag_missing_trustee', () => {
      const engine: CredibilityEngine = new CredibilityEngine();
      const food = createFood('XX食品有限公司', 'SC10633018501234', 'YY品牌公司', '');
      const result = engine.calculate(food);
      expect(result.oemTrusteeMissing).assertTrue();
    });

    it('should_have_radar_dimensions', () => {
      const engine: CredibilityEngine = new CredibilityEngine();
      const food = createFood('XX食品有限公司', 'SC10633018501234');
      const result = engine.calculate(food);
      expect(result.radarDimensions.length).assertEqual(5);
    });

    it('should_have_public_query_entries', () => {
      const engine: CredibilityEngine = new CredibilityEngine();
      const food = createFood('XX食品有限公司', 'SC10633018501234');
      const result = engine.calculate(food);
      expect(result.publicQueryEntries.length).assertLargerThan(0);
    });

    it('should_assign_D_grade_for_user_upload', () => {
      const engine: CredibilityEngine = new CredibilityEngine();
      const food = createFood('XX食品有限公司', 'SC10633018501234');
      const result = engine.calculate(food);
      expect(result.overallGrade).assertEqual(DataGrade.D);
    });

    it('should_generate_tips', () => {
      const engine: CredibilityEngine = new CredibilityEngine();
      const food = createFood('', '');
      const result = engine.calculate(food);
      expect(result.tips.length).assertLargerThan(0);
    });
  });
}

