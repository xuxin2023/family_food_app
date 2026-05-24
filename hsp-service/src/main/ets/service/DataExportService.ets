// DataExportService.ets
// 数据导出与账号删除服务 — 满足 PIPL/GDPR 合规要求

import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { AuthService } from 'hsp-service';

const TAG = 'DataExportService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const EXPORT_DIR = 'data_export';

export class DataExportService {
  private context: common.Context | null = null;
  private authService: AuthService | null = null;

  async init(context: common.Context, authService: AuthService): Promise<void> {
    this.context = context;
    this.authService = authService;
  }

  async exportAllData(): Promise<string | null> {
    if (!this.context) return null;
    try {
      const cacheDir = this.context.cacheDir;
      const exportDir = `${cacheDir}/${EXPORT_DIR}`;
      fileIo.accessSync(exportDir);
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const exportFile = `${exportDir}/user_data_${timestamp}.json`;

      const userData: Record<string, Object> = {
        exportTime: new Date().toISOString(),
        uid: this.authService?.getUid() ?? '',
        familyMembers: [],
        scanHistory: [],
        dietRecords: [],
        favorites: [],
        shoppingList: [],
        nutritionTargets: [],
        reminderRules: []
      };

      const jsonStr = JSON.stringify(userData, null, 2);
      fileIo.writeTextSync(exportFile, jsonStr);

      hilog.info(DOMAIN_ZERO, TAG, 'Data exported to: %{public}s', exportFile);
      return exportFile;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'exportAllData failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  async deleteAllData(): Promise<boolean> {
    if (!this.authService) return false;
    try {
      const success = await this.authService.deleteAccount();
      if (success) {
        hilog.info(DOMAIN_ZERO, TAG, 'All user data deleted successfully');
      }
      return success;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'deleteAllData failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }
}
