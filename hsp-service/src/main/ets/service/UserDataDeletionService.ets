import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { HuaweiCloudBackend } from './HuaweiCloudBackend';
import { SecureKeyStore } from 'hsp_core';
import { common } from '@kit.AbilityKit';

const TAG = 'UserDataDeletionService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface DeletionResult {
  success: boolean;
  deletedLocal: boolean;
  deletedCloud: boolean;
  deletionTime: number;
  errors: string[];
}

export class UserDataDeletionService {
  private static instance: UserDataDeletionService | null = null;

  static getInstance(): UserDataDeletionService {
    if (!UserDataDeletionService.instance) {
      UserDataDeletionService.instance = new UserDataDeletionService();
    }
    return UserDataDeletionService.instance;
  }

  async deleteAllUserData(userId: string, context: common.Context): Promise<DeletionResult> {
    const result: DeletionResult = {
      success: false,
      deletedLocal: false,
      deletedCloud: false,
      deletionTime: Date.now(),
      errors: []
    };

    try {
      result.deletedLocal = await this.deleteLocalData(context);
    } catch (e) {
      result.errors.push(`Local deletion failed: ${JSON.stringify(e)}`);
    }

    try {
      result.deletedCloud = await this.deleteCloudData(userId);
    } catch (e) {
      result.errors.push(`Cloud deletion failed: ${JSON.stringify(e)}`);
    }

    try {
      await SecureKeyStore.clearAll();
    } catch (e) {
      result.errors.push(`SecureKeyStore clear failed: ${JSON.stringify(e)}`);
    }

    result.success = result.deletedLocal && result.deletedCloud;
    hilog.info(DOMAIN_ZERO, TAG, 'Data deletion result: local=%{public}s cloud=%{public}s',
      result.deletedLocal.toString(), result.deletedCloud.toString());
    return result;
  }

  private async deleteLocalData(context: common.Context): Promise<boolean> {
    try {
      const rdb = await import('@kit.ArkData').then(m =>
        m.relationalStore.getRdbStore(context, { name: 'family_food.db', securityLevel: m.relationalStore.SecurityLevel.S3 })
      );
      const tables = ['family_members', 'food_labels', 'scan_history', 'diet_records',
        'nutrition_targets', 'favorites', 'shopping_list', 'reminder_rules', 'recipes', 'family_groups'];
      for (const table of tables) {
        try {
          rdb.executeSqlSync(`DELETE FROM ${table}`);
        } catch (_e) {
          // 表可能不存在
        }
      }
      return true;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'deleteLocalData failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  private async deleteCloudData(userId: string): Promise<boolean> {
    try {
      const backend = HuaweiCloudBackend.getInstance();
      await backend.request({
        path: `/api/users/${userId}/data`,
        method: 'DELETE'
      });
      return true;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'deleteCloudData failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  async exportUserData(userId: string): Promise<string | null> {
    try {
      const backend = HuaweiCloudBackend.getInstance();
      const result = await backend.request({
        path: `/api/users/${userId}/export`,
        method: 'GET'
      });
      return JSON.stringify(result);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'exportUserData failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }
}
