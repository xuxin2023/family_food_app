import { describe, it, expect } from '@ohos/hypium';
import {
  IntoleranceEngine, IntoleranceType, IntoleranceSeverity,
  IntoleranceCheckResult, IntoleranceWarning
} from 'feature_scan';
import {
  HealthSignal, BpStatus, BsStatus, SleepStatus
} from 'hsp_core';

export default function intoleranceEngineTest() {
  describe('IntoleranceEngine', () => {
    const engine = IntoleranceEngine.getInstance();

    it('should_detect_lactose_intolerance', 0, () => {
      const result = engine.check([IntoleranceType.LACTOSE], ['牛奶', '面粉', '乳清蛋白']);
      expect(result.hasWarnings).assertTrue();
      expect(result.warnings.length).assertGreater(0);
      const hasLactose = result.warnings.some(w => w.type === IntoleranceType.LACTOSE);
      expect(hasLactose).assertTrue();
    });

    it('should_detect_gluten_intolerance', 0, () => {
      const result = engine.check([IntoleranceType.GLUTEN], ['小麦粉', '面筋', '大米']);
      expect(result.hasWarnings).assertTrue();
    });

    it('should_detect_fructose_intolerance', 0, () => {
      const result = engine.check([IntoleranceType.FRUCTOSE], ['果糖', '蜂蜜', '苹果汁']);
      expect(result.hasWarnings).assertTrue();
    });

    it('should_return_empty_for_safe_ingredients', 0, () => {
      const result = engine.check([IntoleranceType.LACTOSE], ['大米', '食盐', '蔬菜']);
      expect(result.hasWarnings).assertFalse();
    });

    it('should_return_empty_for_empty_intolerances', 0, () => {
      const result = engine.check([], ['牛奶']);
      expect(result.hasWarnings).assertFalse();
    });

    it('should_return_empty_for_empty_ingredients', 0, () => {
      const result = engine.check([IntoleranceType.LACTOSE], []);
      expect(result.hasWarnings).assertFalse();
    });

    it('should_set_correct_severity_for_histamine', 0, () => {
      const result = engine.check([IntoleranceType.HISTAMINE], ['发酵食品', '陈年芝士']);
      if (result.warnings.length > 0) {
        expect(result.warnings[0].severity).assertEqual(IntoleranceSeverity.AVOID);
      }
    });

    it('should_set_correct_severity_for_lactose', 0, () => {
      const result = engine.check([IntoleranceType.LACTOSE], ['牛奶']);
      if (result.warnings.length > 0) {
        expect(result.warnings[0].severity).assertEqual(IntoleranceSeverity.CAUTION);
      }
    });

    it('should_generate_summary_when_warnings', 0, () => {
      const result = engine.check([IntoleranceType.LACTOSE], ['牛奶']);
      if (result.hasWarnings) {
        expect(result.summary.length).assertGreater(0);
      }
    });

    it('isHighHistamine_should_detect', 0, () => {
      expect(engine.isHighHistamine('发酵食品')).assertTrue();
      expect(engine.isHighHistamine('大米')).assertFalse();
    });

    it('isHighSalicylate_should_detect', 0, () => {
      expect(engine.isHighSalicylate('薄荷')).assertTrue();
      expect(engine.isHighSalicylate('大米')).assertFalse();
    });

    it('isHighFodmap_should_use_fallback', 0, () => {
      expect(engine.isHighFodmap('小麦')).assertTrue();
      expect(engine.isHighFodmap('大蒜')).assertTrue();
      expect(engine.isHighFodmap('食盐')).assertFalse();
    });

    it('getAllTypes_should_return_all_8_types', 0, () => {
      const types = engine.getAllTypes();
      expect(types.length).assertEqual(8);
    });

    it('getTypeLabel_should_return_chinese', 0, () => {
      expect(engine.getTypeLabel(IntoleranceType.LACTOSE)).assertEqual('乳糖');
      expect(engine.getTypeLabel(IntoleranceType.GLUTEN)).assertEqual('麸质');
      expect(engine.getTypeLabel(IntoleranceType.FRUCTOSE)).assertEqual('果糖');
    });

    it('inferFromHealthSignal_high_bs_should_infer_lactose_fructose', 0, () => {
      const signal = new HealthSignal();
      signal.manualBsStatus = BsStatus.HIGH;
      const types = IntoleranceEngine.inferFromHealthSignal(signal);
      expect(types.includes(IntoleranceType.LACTOSE)).assertTrue();
      expect(types.includes(IntoleranceType.FRUCTOSE)).assertTrue();
    });

    it('inferFromHealthSignal_high_bp_should_infer_salicylate_histamine', 0, () => {
      const signal = new HealthSignal();
      signal.manualBpStatus = BpStatus.HIGH;
      const types = IntoleranceEngine.inferFromHealthSignal(signal);
      expect(types.includes(IntoleranceType.SALICYLATE)).assertTrue();
      expect(types.includes(IntoleranceType.HISTAMINE)).assertTrue();
    });

    it('inferFromHealthSignal_poor_sleep_should_infer_histamine_caffeine', 0, () => {
      const signal = new HealthSignal();
      signal.sleepStatus = SleepStatus.POOR;
      const types = IntoleranceEngine.inferFromHealthSignal(signal);
      expect(types.includes(IntoleranceType.HISTAMINE)).assertTrue();
      expect(types.includes(IntoleranceType.CAFFEINE)).assertTrue();
    });

    it('inferFromHealthSignal_normal_should_return_empty', 0, () => {
      const signal = new HealthSignal();
      const types = IntoleranceEngine.inferFromHealthSignal(signal);
      expect(types.length).assertEqual(0);
    });
  });
}