import { describe, it, expect } from '@ohos/hypium';
import { DataBackupService, BackupResult, RestoreResult } from 'hsp_service';

export default function dataBackupServiceTest() {
  describe('DataBackupServiceTest', () => {
    it('should_return_singleton_instance', 0, () => {
      const a = DataBackupService.getInstance();
      const b = DataBackupService.getInstance();
      expect(a === b).assertTrue();
    });

    it('should_create_backup_result_with_defaults', 0, () => {
      const result: BackupResult = new BackupResult()
      expect(result.success).assertFalse();
      expect(result.encrypted).assertFalse();
      expect(result.recordCount).assertEqual(0);
    });

    it('should_create_restore_result_with_defaults', 0, () => {
      const result: RestoreResult = new RestoreResult()
      expect(result.success).assertFalse();
      expect(result.schemaCompatible).assertFalse();
      expect(result.tablesRestored.size).assertEqual(0);
    });
  });
}
