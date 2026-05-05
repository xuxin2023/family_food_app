// AiServiceBaseTest.ets
// AiServiceBase 单元测试 - 验证 AI 服务基类的状态管理

import { describe, it, expect } from '@ohos/hypium';
import { AiServiceBase } from '../../../../src/main/ets/service/ai/AiServiceBase';
import { AI_SERVICE_DEFAULTS } from '../../../../src/main/ets/service/ai/AiConfig';

class TestAiService extends AiServiceBase {
  protected getTag(): string {
    return 'TestAiService';
  }

  protected getDefaultTemperature(): number {
    return AI_SERVICE_DEFAULTS.NUTRITIONIST_TEMPERATURE;
  }

  protected getDefaultMaxTokens(): number {
    return AI_SERVICE_DEFAULTS.NUTRITIONIST_MAX_TOKENS;
  }

  protected getSystemPrompt(): string {
    return '你是一个测试助手。';
  }

  async callAiWithPrompt(prompt: string): Promise<string | null> {
    return this.callAi(prompt);
  }
}

export default function aiServiceBaseTest() {
  describe('AiServiceBaseTest', () => {
    let service: TestAiService;

    beforeEach(() => {
      service = new TestAiService();
    });

    it('should_be_enabled_by_default', 0, () => {
      expect(service.shouldUseAi()).assertFalse(); // apiKey not set yet
    });

    it('should_not_use_ai_when_disabled', 0, () => {
      service.setApiKey('test_key');
      service.setEnabled(false);
      expect(service.shouldUseAi()).assertFalse();
    });

    it('should_not_use_ai_without_api_key', 0, () => {
      expect(service.shouldUseAi()).assertFalse();
    });

    it('should_use_ai_when_configured', 0, () => {
      service.setApiKey('test_key');
      expect(service.shouldUseAi()).assertTrue();
    });

    it('should_not_use_ai_when_tokens_exhausted', 0, () => {
      service.setApiKey('test_key');
      service.setTokensUsed(999999);
      expect(service.shouldUseAi()).assertFalse(); // exceeds MAX_TOKENS
    });

    it('should_track_tokens_used', 0, () => {
      expect(service.getTokensUsed()).assertEqual(0);
      service.setTokensUsed(100);
      expect(service.getTokensUsed()).assertEqual(100);
    });

    it('should_implement_abstract_methods', 0, () => {
      expect(service.getTag()).assertEqual('TestAiService');
      expect(service.getDefaultTemperature()).assertEqual(0.5);
      expect(service.getDefaultMaxTokens()).assertEqual(1000);
      expect(service.getSystemPrompt()).assertEqual('你是一个测试助手。');
    });
  });
}
