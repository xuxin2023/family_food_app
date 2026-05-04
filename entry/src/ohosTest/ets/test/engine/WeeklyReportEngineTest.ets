// WeeklyReportEngine 单元测试 - 家庭饮食周报
import { describe, it, expect } from '@ohos/hypium';
import { WeeklyReportEngine, WeeklyDietData, WeeklyReport } from '../../../../../src/main/ets/engine/WeeklyReportEngine';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../../../src/main/ets/model/FamilyProfile';

function createWeeklyDietData(): WeeklyDietData {
  return {
    memberId: 'member_1',
    weekStart: '2025-12-01',
    weekEnd: '2025-12-07',
    totalScans: 14,
    highSodiumDays: 3,
    highSugarDays: 2,
    highFatDays: 1,
    sweetNearMealCount: 0,
    lateNightSnackCount: 2,
    heavyFlavorCount: 3,
    childSnackOverLimit: 0
  };
}

function createWeeklyDietDataWithHighSodium(highSodiumDays: number): WeeklyDietData {
  const d: WeeklyDietData = createWeeklyDietData();
  d.highSodiumDays = highSodiumDays;
  return d;
}

function createWeeklyDietDataWithHighSugar(highSugarDays: number): WeeklyDietData {
  const d: WeeklyDietData = createWeeklyDietData();
  d.highSugarDays = highSugarDays;
  return d;
}

function createWeeklyDietDataForChild(sweetNearMealCount: number, childSnackOverLimit: number): WeeklyDietData {
  const d: WeeklyDietData = createWeeklyDietData();
  d.sweetNearMealCount = sweetNearMealCount;
  d.childSnackOverLimit = childSnackOverLimit;
  return d;
}

function createWeeklyDietDataWithLateNight(lateNightSnackCount: number): WeeklyDietData {
  const d: WeeklyDietData = createWeeklyDietData();
  d.lateNightSnackCount = lateNightSnackCount;
  return d;
}

function createWeeklyDietDataWithHeavyFlavor(heavyFlavorCount: number): WeeklyDietData {
  const d: WeeklyDietData = createWeeklyDietData();
  d.heavyFlavorCount = heavyFlavorCount;
  return d;
}

function createWeeklyDietDataGoodWeek(): WeeklyDietData {
  return {
    memberId: 'member_1',
    weekStart: '2025-12-01',
    weekEnd: '2025-12-07',
    totalScans: 14,
    highSodiumDays: 0,
    highSugarDays: 0,
    highFatDays: 0,
    sweetNearMealCount: 0,
    lateNightSnackCount: 0,
    heavyFlavorCount: 0,
    childSnackOverLimit: 0
  };
}

export default function weeklyReportEngineTest() {
  describe('WeeklyReportEngine', () => {

    // ========== 1. 周报基本信息 ==========

    it('should_set_basic_report_fields', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietData();
      const profile: FamilyProfile = new FamilyProfile();
      profile.memberId = 'member_1';
      profile.nickname = '测试用户';

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.memberId).assertEqual('member_1');
      expect(report.memberName).assertEqual('测试用户');
      expect(report.weekRange).assertEqual('2025-12-01 ~ 2025-12-07');
    });

    // ========== 2. 控压周报摘要 ==========

    it('should_highlight_high_sodium_when_control_bp', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithHighSodium(5);
      const profile: FamilyProfile = new FamilyProfile();
      profile.memberId = 'member_1';
      profile.nickname = '奶奶';
      profile.healthGoals = [HealthGoal.CONTROL_BP];

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.summary.includes('高盐')).assertTrue();
      expect(report.summary.includes('5')).assertTrue();
      expect(report.highlights.length).assertLarger(0);
      expect(report.highlights[0].includes('高盐')).assertTrue();
    });

    it('should_praise_good_sodium_control', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithHighSodium(1);
      const profile: FamilyProfile = new FamilyProfile();
      profile.memberId = 'member_1';
      profile.nickname = '奶奶';
      profile.healthGoals = [HealthGoal.CONTROL_BP];

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.summary.includes('控制尚可')).assertTrue();
    });

    // ========== 3. 控糖周报摘要 ==========

    it('should_highlight_high_sugar_when_control_sugar', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithHighSugar(4);
      const profile: FamilyProfile = new FamilyProfile();
      profile.memberId = 'member_1';
      profile.nickname = '爸爸';
      profile.healthGoals = [HealthGoal.CONTROL_SUGAR];

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.summary.includes('高糖')).assertTrue();
      expect(report.summary.includes('4')).assertTrue();
      expect(report.highlights.length).assertLarger(0);
    });

    // ========== 4. 儿童周报 ==========

    it('should_highlight_child_snack_issues', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataForChild(3, 4);
      const profile: FamilyProfile = new FamilyProfile();
      profile.memberId = 'child_1';
      profile.nickname = '宝宝';
      profile.ageGroup = AgeGroup.CHILD;
      profile.healthGoals = [HealthGoal.CHILD];

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.summary.includes('甜食')).assertTrue();
      expect(report.summary.includes('零食超标')).assertTrue();
      expect(report.suggestions.length).assertLarger(0);
    });

    // ========== 5. 夜宵提醒 ==========

    it('should_warn_about_late_night_snacks', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithLateNight(3);
      const profile: FamilyProfile = new FamilyProfile();
      profile.memberId = 'member_1';
      profile.nickname = '测试用户';

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.summary.includes('夜宵')).assertTrue();
      expect(report.suggestions.length).assertLarger(0);
    });

    // ========== 6. 重口味提醒 ==========

    it('should_warn_about_heavy_flavor', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithHeavyFlavor(4);
      const profile: FamilyProfile = new FamilyProfile();
      profile.memberId = 'member_1';
      profile.nickname = '测试用户';

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.summary.includes('重口味')).assertTrue();
    });

    // ========== 7. 优秀周报 ==========

    it('should_praise_good_week', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataGoodWeek();
      const profile: FamilyProfile = new FamilyProfile();
      profile.memberId = 'member_1';
      profile.nickname = '测试用户';

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.summary.includes('均衡')).assertTrue();
    });

    // ========== 8. 采购建议 ==========

    it('should_recommend_buy_less_when_high_sodium', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithHighSodium(3);
      const profile: FamilyProfile = new FamilyProfile();
      profile.healthGoals = [HealthGoal.CONTROL_BP];

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.buyLess.length).assertLarger(0);
      expect(report.buyMore.length).assertLarger(0);
    });

    it('should_recommend_buy_less_when_high_sugar', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithHighSugar(3);
      const profile: FamilyProfile = new FamilyProfile();
      profile.healthGoals = [HealthGoal.CONTROL_SUGAR];

      const report: WeeklyReport = engine.generate(data, profile);

      expect(report.buyLess.length).assertLarger(0);
      expect(report.buyMore.length).assertLarger(0);
    });

    it('should_provide_default_buy_more_when_no_issues', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataGoodWeek();
      const profile: FamilyProfile = new FamilyProfile();

      const report: WeeklyReport = engine.generate(data, profile);

      // 默认建议应该包含蔬菜、水果等
      const hasDefaultSuggestion: boolean = report.buyMore.some((item: string) =>
        item.includes('蔬菜') || item.includes('水果') || item.includes('蛋白')
      );
      expect(hasDefaultSuggestion).assertTrue();
    });

    // ========== 9. 健康目标建议 ==========

    it('should_provide_control_bp_specific_suggestions', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithHighSodium(3);
      const profile: FamilyProfile = new FamilyProfile();
      profile.healthGoals = [HealthGoal.CONTROL_BP];

      const report: WeeklyReport = engine.generate(data, profile);

      const hasBpSuggestion: boolean = report.suggestions.some((s: string) =>
        s.includes('盐') || s.includes('酱油') || s.includes('蚝油')
      );
      expect(hasBpSuggestion).assertTrue();
    });

    it('should_provide_control_sugar_specific_suggestions', 0, () => {
      const engine: WeeklyReportEngine = new WeeklyReportEngine();
      const data: WeeklyDietData = createWeeklyDietDataWithHighSugar(4);
      const profile: FamilyProfile = new FamilyProfile();
      profile.healthGoals = [HealthGoal.CONTROL_SUGAR];

      const report: WeeklyReport = engine.generate(data, profile);

      const hasSugarSuggestion: boolean = report.suggestions.some((s: string) =>
        s.includes('含糖饮料') || s.includes('无糖')
      );
      expect(hasSugarSuggestion).assertTrue();
    });
  });
}
