import { describe, it, expect } from '@ohos/hypium';
import { OfflineModeManager, OfflineOperationType, OfflineOperation } from '../../../../src/main/ets/service/OfflineModeManager';

export default function offlineModeManagerTest() {
  describe('OfflineModeManagerTest', () => {
    it('should_indicate_feature_unavailable_in_offline', 0, () => {
      const manager = OfflineModeManager.getInstance();
      const onlineFeatures: boolean[] = [
        manager.isFeatureAvailable('ai_chat'),
        manager.isFeatureAvailable('cloud_sync'),
        manager.isFeatureAvailable('online_search')
      ];
      const offlineFeatures: boolean[] = [
        manager.isFeatureAvailable('scan'),
        manager.isFeatureAvailable('favorite'),
        manager.isFeatureAvailable('diet')
      ];
      expect(offlineFeatures.every(f => f === true)).assertTrue();
    });

    it('should_enqueue_offline_operation', 0, async () => {
      const manager = OfflineModeManager.getInstance();
      const before = manager.pendingCount;
      await manager.enqueue(OfflineOperationType.SCAN_RECORD, '{"barcode":"123"}');
      const after = manager.pendingCount;
      expect(after).assertGreater(before);
    });

    it('should_create_offline_operation_with_correct_type', 0, () => {
      const op = new OfflineOperation();
      op.type = OfflineOperationType.FAVORITE_ADD;
      op.payload = '{"foodId":"abc"}';
      expect(op.type).assertEqual(OfflineOperationType.FAVORITE_ADD);
      expect(op.synced).assertFalse();
    });
  });
}
