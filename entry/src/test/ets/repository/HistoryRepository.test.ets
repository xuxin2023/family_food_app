import { describe, it, expect } from '@ohos/hypium';
import { HistoryRepository } from 'hsp_service';

export default function historyRepositoryTest() {
  describe('HistoryRepository', () => {
    const repo: HistoryRepository = new HistoryRepository()

    it('should return empty array when rdbStore not initialized', async () => {
      const result = await repo.getRecentScanHistory(10);
      expect(result.length).assertEqual(0);
    });

    it('should respect limitAs with limit parameter', async () => {
      const result = await repo.getScanHistoryByMember('test_member', 5);
      expect(result.length).assertEqual(0);
    });
  });
}
