// AiConfigTest.ets
// AiConfig 单元测试 - 验证 AI 统一配置常量的正确性

import { describe, it, expect } from '@ohos/hypium';
import { AGENT_ARTS_ENDPOINT, AGENT_ARTS_MODEL, AI_SERVICE_DEFAULTS } from 'hsp_service';

export default function aiConfigTest() {
  describe('AiConfigTest', () => {
    it('should_have_correct_endpoint', 0, () => {
      expect(AGENT_ARTS_ENDPOINT).assertEqual('https://agentarts.cloud.huawei.com/v1/chat/completions');
    });

    it('should_have_correct_model_name', 0, () => {
      expect(AGENT_ARTS_MODEL).assertEqual('agentarts-food-polish');
    });

    it('should_have_positive_nutritionist_temperature', 0, () => {
      expect(AI_SERVICE_DEFAULTS.NUTRITIONIST_TEMPERATURE).assertEqual(0.5);
    });

    it('should_have_positive_nutritionist_max_tokens', 0, () => {
      expect(AI_SERVICE_DEFAULTS.NUTRITIONIST_MAX_TOKENS).assertEqual(1000);
    });

    it('should_have_positive_polish_temperature', 0, () => {
      expect(AI_SERVICE_DEFAULTS.POLISH_TEMPERATURE).assertEqual(0.7);
    });

    it('should_have_positive_polish_max_tokens', 0, () => {
      expect(AI_SERVICE_DEFAULTS.POLISH_MAX_TOKENS).assertEqual(200);
    });

    it('should_have_positive_recipe_temperature', 0, () => {
      expect(AI_SERVICE_DEFAULTS.RECIPE_TEMPERATURE).assertEqual(0.5);
    });

    it('should_have_positive_recipe_max_tokens', 0, () => {
      expect(AI_SERVICE_DEFAULTS.RECIPE_MAX_TOKENS).assertEqual(800);
    });

    it('should_have_positive_weekly_temperature', 0, () => {
      expect(AI_SERVICE_DEFAULTS.WEEKLY_TEMPERATURE).assertEqual(0.6);
    });

    it('should_have_positive_weekly_max_tokens', 0, () => {
      expect(AI_SERVICE_DEFAULTS.WEEKLY_MAX_TOKENS).assertEqual(500);
    });
  });
}
