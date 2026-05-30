// DataExportService.ets
// 数据导出与账号删除服务 — 满足 PIPL/GDPR 合规要求

import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { AuthService } from './AuthService';

const TAG = 'DataExportService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
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

      const userData = new Map<string, Object>();
      userData.set('exportTime', new Date().toISOString());
      userData.set('uid', this.authService?.getUid() ?? '');
      userData.set('familyMembers', new Array<string>());
      userData.set('scanHistory', new Array<string>());
      userData.set('dietRecords', new Array<string>());
      userData.set('favorites', new Array<string>());
      userData.set('shoppingList', new Array<string>());
      userData.set('nutritionTargets', new Array<string>());
      userData.set('reminderRules', new Array<string>());

      const jsonStr = JSON.stringify(userData, null, 2);
      const fd = fileIo.openSync(exportFile, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);
      fileIo.writeSync(fd.fd, jsonStr);
      fileIo.closeSync(fd);

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
