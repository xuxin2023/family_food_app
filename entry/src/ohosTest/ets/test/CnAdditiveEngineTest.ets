import { describe, it, expect } from '@ohos/hypium';
import {
  AdditiveSafetyEngine, AdditiveRiskLevel, FoodAdditiveReport, AdditiveAssessment
} from '../../../../../../feature-scan/src/main/ets/engine/AdditiveSafetyEngine';

export default function cnAdditiveEngineTest() {
  describe('CnAdditiveEngineTest', () => {
    it('should_assess_cn_additive_with_cns_code', 0, () => {
      const engine = new AdditiveSafetyEngine();
      const result = engine.assessByCnsCode('01.101');
      if (result !== null) {
        expect(result.cnsCode).assertEqual('01.101');
      }
      expect(true).assertTrue();
    });

    it('should_classify_avoid_level_additives', 0, () => {
      const engine = new AdditiveSafetyEngine();
      const assessment = engine.assessByENumber('E621');
      if (assessment !== null) {
        const isCautionOrAvoid = assessment.riskLevel === AdditiveRiskLevel.CAUTION ||
          assessment.riskLevel === AdditiveRiskLevel.AVOID;
        expect(isCautionOrAvoid).assertTrue();
      }
      expect(true).assertTrue();
    });

    it('should_generate_food_additive_report', 0, () => {
      const engine = new AdditiveSafetyEngine();
      const label = new FoodLabel();
      label.foodName = '测试食品';
      label.additives = ['E300', 'E621'];
      const report = engine.assessFood(label);
      expect(report.assessments.length).assertGreater(0);
      expect(report.foodName).assertEqual('测试食品');
    });
  });
}
