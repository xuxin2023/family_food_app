// FoodAdapterEngine.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { FoodAdapterEngine } from '../../../main/ets/engine/FoodAdapterEngine';

export default function foodAdapterEngineTest() {
  describe('FoodAdapterEngineTest', () => {
    it('should_clean_expired_records_without_error', 0, () => {
      // 清理过期记录不应抛出异常
      expect(FoodAdapterEngine.cleanExpiredRecords()).assertUndefined();
    });
  });
}
