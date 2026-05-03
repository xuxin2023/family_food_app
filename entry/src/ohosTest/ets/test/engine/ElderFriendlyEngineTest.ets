// ElderFriendlyEngine 单元测试 - 老人友好模式
import { describe, it, expect } from '@ohos/hypium';
import { ElderFriendlyEngine, ElderFriendlyReport } from '../../../../../src/main/ets/engine/ElderFriendlyEngine';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../../../src/main/ets/model/FamilyProfile';
import { FoodLabel, NutritionPer100g } from '../../../../../src/main/ets/model/FoodLabel';
import { Recommendation, RecommendLevel, LevelColor } from '../../../../../src/main/ets/model/Recommendation';

function createElderRec(level: RecommendLevel, maxAmount: number,
  reasons: string[], reminders: string[]): Recommendation {
  const rec: Recommendation = new Recommendation();
  rec.memberId = 'elder_1';
  rec.foodId = 'food_1';
  rec.level = level;
  rec.levelColor = LevelColor.GREEN;
  rec.maxAmount = maxAmount;
  rec.reasons = reasons;
  rec.reminders = reminders;
  return rec;
}

function createElderProfile(): FamilyProfile {
  const profile: FamilyProfile = new FamilyProfile();
  profile.memberId = 'elder_1';
  profile.nickname = '爷爷';
  profile.ageGroup = AgeGroup.OLD;
  profile.healthGoals = [HealthGoal.CONTROL_BP];
  return profile;
}

function createElderFood(): FoodLabel {
  const food: FoodLabel = new FoodLabel();
  food.foodId = 'food_1';
  food.foodName = '咸饼干';
  return food;
}

function generateReport(rec: Recommendation, engine: ElderFriendlyEngine): ElderFriendlyReport {
  const profile: FamilyProfile = createElderProfile();
  const food: FoodLabel = createElderFood();
  return engine.generate(rec, profile, food);
}

export default function elderFriendlyEngineTest() {
  describe('ElderFriendlyEngine', () => {

    // ========== 1. 一句话结论测试 ==========

    it('should_generate_one_line_conclusion_for_avoid', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.AVOID, 0, ['含高盐'], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.oneLineConclusion.includes('不建议吃')).assertTrue();
    });

    it('should_generate_one_line_conclusion_for_suitable', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.SUITABLE, 100, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.oneLineConclusion.includes('可以吃')).assertTrue();
    });

    it('should_generate_one_line_conclusion_for_cautious', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.CAUTIOUS, 10, ['今天预算少'], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.oneLineConclusion.includes('今天要少吃')).assertTrue();
    });

    it('should_generate_one_line_conclusion_for_small_ok', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.SMALL_OK, 30, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.oneLineConclusion.includes('可以少量吃')).assertTrue();
    });

    // ========== 2. 建议份量测试 ==========

    it('should_suggest_portions_for_large_amount', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.SUITABLE, 200, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.suggestedAmount.includes('小份')).assertTrue();
    });

    it('should_suggest_grams_for_small_amount', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.CAUTIOUS, 20, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.suggestedAmount.includes('克')).assertTrue();
    });

    it('should_suggest_not_to_eat_when_zero_amount', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.AVOID, 0, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.suggestedAmount.includes('不吃')).assertTrue();
    });

    // ========== 3. 今日提醒 ==========

    it('should_use_first_reason_as_today_reminder', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.CAUTIOUS, 20,
        ['钠含量较高，控压需注意'], ['今日活动量偏低']);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.todayReminder.length).assertLarger(0);
    });

    // ========== 4. 语音播报文本 ==========

    it('should_generate_voice_text_for_avoid', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.AVOID, 0,
        ['高盐食品'], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.voiceText.includes('爷爷')).assertTrue();
      expect(report.voiceText.includes('咸饼干')).assertTrue();
      expect(report.voiceText.includes('不太适合')).assertTrue();
    });

    it('should_generate_voice_text_for_suitable', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.SUITABLE, 150, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.voiceText.includes('可以吃')).assertTrue();
    });

    it('should_generate_voice_text_for_cautious', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.CAUTIOUS, 15,
        ['钠含量偏高'], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.voiceText.includes('少吃')).assertTrue();
    });

    it('should_generate_voice_text_for_small_ok', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.SMALL_OK, 40, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.voiceText.includes('少量')).assertTrue();
    });

    // ========== 5. 家庭群分享文本 ==========

    it('should_generate_family_share_text_for_avoid', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.AVOID, 0,
        ['含高盐，建议避免'], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.familyShareText.includes('爷爷')).assertTrue();
      expect(report.familyShareText.includes('少吃')).assertTrue();
    });

    it('should_generate_family_share_text_for_cautious', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.CAUTIOUS, 10, ['今天少吃'], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.familyShareText.includes('爷爷')).assertTrue();
      expect(report.familyShareText.includes('今天少吃')).assertTrue();
    });

    it('should_generate_family_share_text_for_small_ok', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.SMALL_OK, 30, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.familyShareText.includes('少量')).assertTrue();
    });

    it('should_generate_family_share_text_for_suitable', 0, () => {
      const engine: ElderFriendlyEngine = new ElderFriendlyEngine();
      const rec: Recommendation = createElderRec(RecommendLevel.SUITABLE, 100, [], []);
      const report: ElderFriendlyReport = generateReport(rec, engine);

      expect(report.familyShareText.includes('可以吃')).assertTrue();
    });
  });
}
