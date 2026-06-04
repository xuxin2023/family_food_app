// HealthSignal 单元测试 - 健康信号模型
import { describe, it, expect } from '@ohos/hypium';
import { HealthSignal, StepLevel, SleepStatus, WeightTrend,
  BpStatus, BsStatus, DataSource, JsonHelper } from 'hsp_core';

function createHealthSignal(stepLevel: StepLevel, sleepStatus: SleepStatus,
  weightTrend: WeightTrend, activityCaloriesLevel: StepLevel,
  manualBpStatus: BpStatus, manualBsStatus: BsStatus,
  hadHighSodiumToday: boolean, hadHighSugarToday: boolean,
  source: DataSource): HealthSignal {
  const signal: HealthSignal = new HealthSignal();
  signal.memberId = 'member_1';
  signal.date = '2025-12-15';
  signal.stepLevel = stepLevel;
  signal.sleepStatus = sleepStatus;
  signal.weightTrend = weightTrend;
  signal.activityCaloriesLevel = activityCaloriesLevel;
  signal.manualBpStatus = manualBpStatus;
  signal.manualBsStatus = manualBsStatus;
  signal.hadHighSodiumToday = hadHighSodiumToday;
  signal.hadHighSugarToday = hadHighSugarToday;
  signal.source = source;
  return signal;
}

function createDefaultSignal(): HealthSignal {
  return createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD, WeightTrend.STABLE,
    StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL, false, false, DataSource.MANUAL);
}

export default function healthSignalTest() {
  describe('HealthSignal', () => {

    // ========== 活动量检查 ==========

    it('should_detect_low_activity_from_step_level', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.LOW, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isLowActivity()).assertTrue();
    });

    it('should_detect_low_activity_from_activity_calories', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.LOW, BpStatus.NORMAL, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isLowActivity()).assertTrue();
    });

    it('should_not_detect_normal_as_low_activity', 0, () => {
      const signal: HealthSignal = createDefaultSignal();
      expect(signal.isLowActivity()).assertFalse();
    });

    it('should_detect_high_activity', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.HIGH, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isHighActivity()).assertTrue();
    });

    it('should_detect_high_activity_from_calories', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.HIGH, BpStatus.NORMAL, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isHighActivity()).assertTrue();
    });

    // ========== 睡眠检查 ==========

    it('should_detect_poor_sleep', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.POOR,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isPoorSleep()).assertTrue();
    });

    it('should_not_detect_good_sleep_as_poor', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isPoorSleep()).assertFalse();
    });

    // ========== 体重趋势 ==========

    it('should_detect_weight_up', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.UP, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isWeightUp()).assertTrue();
    });

    it('should_not_detect_stable_as_weight_up', 0, () => {
      const signal: HealthSignal = createDefaultSignal();
      expect(signal.isWeightUp()).assertFalse();
    });

    // ========== 血压检查 ==========

    it('should_detect_elevated_bp', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.ELEVATED, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isHighBp()).assertTrue();
    });

    it('should_detect_high_bp', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.HIGH, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isHighBp()).assertTrue();
    });

    it('should_detect_very_high_bp', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.VERY_HIGH, BsStatus.NORMAL,
        false, false, DataSource.MANUAL);
      expect(signal.isHighBp()).assertTrue();
    });

    it('should_not_detect_normal_bp_as_high', 0, () => {
      const signal: HealthSignal = createDefaultSignal();
      expect(signal.isHighBp()).assertFalse();
    });

    // ========== 血糖检查 ==========

    it('should_detect_elevated_bs', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.ELEVATED,
        false, false, DataSource.MANUAL);
      expect(signal.isHighBs()).assertTrue();
    });

    it('should_detect_high_bs', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.HIGH,
        false, false, DataSource.MANUAL);
      expect(signal.isHighBs()).assertTrue();
    });

    it('should_not_detect_normal_bs_as_high', 0, () => {
      const signal: HealthSignal = createDefaultSignal();
      expect(signal.isHighBs()).assertFalse();
    });

    // ========== 今日饮食检查 ==========

    it('should_detect_high_sodium_today', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL,
        true, false, DataSource.MANUAL);
      expect(signal.isHighSodiumToday()).assertTrue();
    });

    it('should_detect_high_sugar_today', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.NORMAL, SleepStatus.GOOD,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL,
        false, true, DataSource.MANUAL);
      expect(signal.isHighSugarToday()).assertTrue();
    });

    it('should_not_detect_no_high_sodium_today', 0, () => {
      const signal: HealthSignal = createDefaultSignal();
      expect(signal.isHighSodiumToday()).assertFalse();
    });

    // ========== JSON序列化 ==========

    it('should_serialize_to_json', 0, () => {
      const signal: HealthSignal = createHealthSignal(StepLevel.LOW, SleepStatus.POOR,
        WeightTrend.STABLE, StepLevel.NORMAL, BpStatus.NORMAL, BsStatus.NORMAL,
        true, false, DataSource.HUAWEI_HEALTH);
      signal.memberId = 'test_json';

      const json: Object = signal.toJson();

      expect((json as Record<string, Object>).memberId as string).assertEqual('test_json');
      expect((json as Record<string, Object>).stepLevel as StepLevel).assertEqual(StepLevel.LOW);
      expect((json as Record<string, Object>).sleepStatus as SleepStatus).assertEqual(SleepStatus.POOR);
      expect((json as Record<string, Object>).hadHighSodiumToday as boolean).assertEqual(true);
      expect((json as Record<string, Object>).source as DataSource).assertEqual(DataSource.HUAWEI_HEALTH);
    });

    it('should_deserialize_from_json', 0, () => {
      const jsonStr: string = JSON.stringify({
        memberId: 'test_from_json',
        date: '2025-12-20',
        stepLevel: StepLevel.HIGH,
        sleepStatus: SleepStatus.GOOD,
        weightTrend: WeightTrend.DOWN,
        activityCaloriesLevel: StepLevel.HIGH,
        manualBpStatus: BpStatus.NORMAL,
        manualBsStatus: BsStatus.NORMAL,
        hadHighSodiumToday: false,
        hadHighSugarToday: true,
        source: DataSource.MANUAL
      });
      const signal: HealthSignal = HealthSignal.fromJson((() => {
        return JsonHelper.recordToMap(JSON.parse(jsonStr) as Record<string, Object>);
      })());

      expect(signal.memberId).assertEqual('test_from_json');
      expect(signal.stepLevel).assertEqual(StepLevel.HIGH);
      expect(signal.isHighActivity()).assertTrue();
      expect(signal.isHighSugarToday()).assertTrue();
      expect(signal.isHighBp()).assertFalse();
    });
  });
}
