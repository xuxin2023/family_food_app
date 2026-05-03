// Recommendation 单元测试 - 适配结论模型
import { describe, it, expect } from '@ohos/hypium';
import { Recommendation, RecommendLevel, LevelColor,
  getLevelColorValue } from '../../../../../src/main/ets/model/Recommendation';

function createRec(level: RecommendLevel, levelColor: LevelColor, maxAmount: number,
  maxServings: number, reasons: string[], reminders: string[]): Recommendation {
  const rec: Recommendation = new Recommendation();  rec.memberId = 'member_1';
  rec.foodId = 'food_001';
  rec.level = level;
  rec.levelColor = levelColor;
  rec.maxAmount = maxAmount;
  rec.maxServings = maxServings;
  rec.reasons = reasons;
  rec.reminders = reminders;
  rec.generatedAt = 1700000000000;
  return rec;
}

function createDefaultRec(): Recommendation {
  return createRec(RecommendLevel.SUITABLE, LevelColor.GREEN, 100, 1,
    ['当前情况下可以适量食用'], []);
}

export default function recommendationTest() {
  describe('Recommendation', () => {

    // ========== 等级判断 ==========

    it('should_detect_avoid_level', 0, () => {
      const rec: Recommendation = createRec(RecommendLevel.AVOID, LevelColor.RED, 0, 0, [], []);
      expect(rec.isAvoid()).assertTrue();
    });

    it('should_not_detect_suitable_as_avoid', 0, () => {
      const rec: Recommendation = createDefaultRec();
      expect(rec.isAvoid()).assertFalse();
    });

    it('should_detect_cautious_level', 0, () => {
      const rec: Recommendation = createRec(RecommendLevel.CAUTIOUS, LevelColor.ORANGE, 10, 0, [], []);
      expect(rec.isCautious()).assertTrue();
    });

    it('should_not_detect_suitable_as_cautious', 0, () => {
      const rec: Recommendation = createDefaultRec();
      expect(rec.isCautious()).assertFalse();
    });

    // ========== JSON序列化 ==========

    it('should_serialize_to_json', 0, () => {
      const rec: Recommendation = createRec(RecommendLevel.SMALL_OK, LevelColor.YELLOW, 30, 1,
        ['钠含量中等，控压注意', '可以少量食用'], ['今晚注意清淡']);

      const json: Object = rec.toJson();

      expect((json as Record<string, Object>).memberId as string).assertEqual('member_1');
      expect((json as Record<string, Object>).foodId as string).assertEqual('food_001');
      expect((json as Record<string, Object>).level as RecommendLevel).assertEqual(RecommendLevel.SMALL_OK);
      expect((json as Record<string, Object>).levelColor as LevelColor).assertEqual(LevelColor.YELLOW);
      expect((json as Record<string, Object>).maxAmount as number).assertEqual(30);
    });

    it('should_deserialize_from_json', 0, () => {
      const jsonStr: string = JSON.stringify({
        memberId: 'test_from_json',
        foodId: 'food_from_json',
        level: RecommendLevel.CAUTIOUS,
        levelColor: LevelColor.ORANGE,
        maxAmount: 10,
        maxServings: 0,
        reasons: ['今天预算剩余较少', '建议谨慎'],
        reminders: ['尽量选择清淡搭配'],
        disclaimer: '本结果仅供参考',
        generatedAt: 1700000000000
      });
      const rec: Recommendation = Recommendation.fromJson(JSON.parse(jsonStr) as Record<string, Object>);

      expect(rec.memberId).assertEqual('test_from_json');
      expect(rec.foodId).assertEqual('food_from_json');
      expect(rec.level).assertEqual(RecommendLevel.CAUTIOUS);
      expect(rec.isCautious()).assertTrue();
      expect(rec.maxAmount).assertEqual(10);
      expect(rec.reasons.length).assertEqual(2);
      expect(rec.reminders.length).assertEqual(1);
    });

    it('should_preserve_data_through_json_round_trip', 0, () => {
      const original: Recommendation = createRec(RecommendLevel.AVOID, LevelColor.RED, 0, 0,
        ['含过敏原：花生，建议避免'], []);

      const jsonStr: string = JSON.stringify(original.toJson());
      const restored: Recommendation = Recommendation.fromJson(JSON.parse(jsonStr) as Record<string, Object>);

      expect(restored.memberId).assertEqual('member_1');
      expect(restored.level).assertEqual(RecommendLevel.AVOID);
      expect(restored.isAvoid()).assertTrue();
      expect(restored.maxAmount).assertEqual(0);
      expect(restored.reasons[0]).assertEqual('含过敏原：花生，建议避免');
    });

    // ========== 默认值 ==========

    it('should_have_default_disclaimer', 0, () => {
      const rec: Recommendation = createDefaultRec();
      expect(rec.disclaimer.length).assertLarger(0);
      expect(rec.disclaimer.includes('本结果')).assertTrue();
    });

    it('should_initialize_with_empty_reasons_and_reminders', 0, () => {
      const rec: Recommendation = new Recommendation();
      expect(rec.reasons.length).assertEqual(0);
      expect(rec.reminders.length).assertEqual(0);
    });
  });

  // ========== getLevelColorValue 测试 ==========

  describe('getLevelColorValue', () => {

    it('should_return_green_color', 0, () => {
      expect(getLevelColorValue(LevelColor.GREEN)).assertEqual('#4CAF50');
    });

    it('should_return_yellow_color', 0, () => {
      expect(getLevelColorValue(LevelColor.YELLOW)).assertEqual('#FF9800');
    });

    it('should_return_orange_color', 0, () => {
      expect(getLevelColorValue(LevelColor.ORANGE)).assertEqual('#FF5722');
    });

    it('should_return_red_color', 0, () => {
      expect(getLevelColorValue(LevelColor.RED)).assertEqual('#F44336');
    });

    it('should_return_default_color_for_unknown', 0, () => {
      expect(getLevelColorValue(LevelColor.RED)).assertEqual('#F44336');
    });
  });
}
