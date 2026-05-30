import { describe, it, expect } from '@ohos/hypium';
import { MathUtil } from '../../../../../../hsp_core/src/main/ets/utils/MathUtil';

export default function mathUtilTest() {
  describe('MathUtil', () => {
    it('clamp_should_return_value_within_range', 0, () => {
      expect(MathUtil.clamp(5, 0, 10)).assertEqual(5);
    });

    it('clamp_should_return_min_when_below', 0, () => {
      expect(MathUtil.clamp(-5, 0, 10)).assertEqual(0);
    });

    it('clamp_should_return_max_when_above', 0, () => {
      expect(MathUtil.clamp(15, 0, 10)).assertEqual(10);
    });

    it('clamp_should_handle_equal_min', 0, () => {
      expect(MathUtil.clamp(0, 0, 10)).assertEqual(0);
    });

    it('clamp_should_handle_equal_max', 0, () => {
      expect(MathUtil.clamp(10, 0, 10)).assertEqual(10);
    });

    it('roundTo_should_round_to_0_decimals', 0, () => {
      expect(MathUtil.roundTo(3.7, 0)).assertEqual(4);
      expect(MathUtil.roundTo(3.3, 0)).assertEqual(3);
    });

    it('roundTo_should_round_to_2_decimals', 0, () => {
      expect(MathUtil.roundTo(3.14159, 2)).assertEqual(3.14);
      expect(MathUtil.roundTo(3.145, 2)).assertEqual(3.15);
    });

    it('roundTo_should_round_to_negative_decimals', 0, () => {
      expect(MathUtil.roundTo(1234, -2)).assertEqual(1200);
    });

    it('percent_should_calculate_correctly', 0, () => {
      expect(MathUtil.percent(25, 100)).assertEqual(25);
      expect(MathUtil.percent(1, 4)).assertEqual(25);
    });

    it('percent_should_return_0_for_zero_total', 0, () => {
      expect(MathUtil.percent(50, 0)).assertEqual(0);
    });

    it('percent_should_clamp_to_100', 0, () => {
      expect(MathUtil.percent(150, 100)).assertEqual(100);
    });

    it('percent_should_clamp_to_0', 0, () => {
      expect(MathUtil.percent(-10, 100)).assertEqual(0);
    });

    it('percent_should_handle_half', 0, () => {
      expect(MathUtil.percent(1, 2)).assertEqual(50);
    });
  });
}