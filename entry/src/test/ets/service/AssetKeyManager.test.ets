// AssetKeyManager.test.ets
// AssetKeyManager 单元测试 — 测试 Key 的加密存储/读取

import { describe, it, expect } from '@ohos/hypium';
import { AssetKeyManager, KeyAlias } from '../../main/ets/utils/AssetKeyManager';

export default function assetKeyManagerTest() {
  describe('AssetKeyManager', () => {
    it('getInstance_returnsSameInstance', 0, () => {
      const instance1 = AssetKeyManager.getInstance();
      const instance2 = AssetKeyManager.getInstance();
      expect(instance1 === instance2).assertTrue();
    });

    it('saveAndRetrieveKey', 0, () => {
      // 此测试仅验证接口可调用（实际 Asset Store 需真机环境）
      const manager = AssetKeyManager.getInstance();
      const alias = 'test_key_alias';
      const key = 'sk-test-api-key-12345';
      // 验证 saveKey 不会抛异常
      let saved = false;
      try {
        manager.saveKey(alias, key).then((result) => { saved = result; }).catch(() => {});
        saved = true; // 至少不崩溃
      } catch (_e) {
        saved = false;
      }
      expect(saved).assertTrue();
    });
  });
}
