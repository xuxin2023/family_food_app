// AiClientTest.ets
// AiClient 单元测试 - 验证统一的 AgentArts HTTP 调用客户端

import { describe, it, expect } from '@ohos/hypium';
import { AiClient, AiCallResponse } from 'hsp_service';

export default function aiClientTest() {
  describe('AiClientTest', () => {
    it('should_set_and_get_api_key', 0, () => {
      const client = new AiClient();
      client.setApiKey('test_key_123');
      expect(client.getApiKey()).assertEqual('test_key_123');
    });

    it('should_report_no_api_key_when_empty', 0, () => {
      const client = new AiClient();
      expect(client.hasApiKey()).assertFalse();
    });

    it('should_report_api_key_exists', 0, () => {
      const client = new AiClient();
      client.setApiKey('valid_key');
      expect(client.hasApiKey()).assertTrue();
    });

    it('should_update_api_key', 0, () => {
      const client = new AiClient();
      client.setApiKey('key1');
      expect(client.getApiKey()).assertEqual('key1');
      client.setApiKey('key2');
      expect(client.getApiKey()).assertEqual('key2');
    });

    it('should_return_null_when_no_api_key', 0, async () => {
      const client = new AiClient();
      const result = await client.call({
        systemPrompt: 'test system',
        userPrompt: 'test user',
        temperature: 0.5,
        maxTokens: 100
      });
      expect(result).assertNull();
    });
  });
}
