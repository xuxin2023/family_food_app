import { distributedDataObject } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';

const TAG = 'DistributedSyncHelper';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface DistributedMemberData {
  memberId: string;
  nickname: string;
  tier: string;
  lastModified: number;
}

export class DistributedSyncHelper {
  private static instance: DistributedSyncHelper | null = null;
  private distributedObj: distributedDataObject.DataObject | null = null;
  private sessionId: string = '';

  static getInstance(): DistributedSyncHelper {
    if (!DistributedSyncHelper.instance) {
      DistributedSyncHelper.instance = new DistributedSyncHelper();
    }
    return DistributedSyncHelper.instance;
  }

  async init(context: common.Context, data: DistributedMemberData[]): Promise<void> {
    try {
      this.distributedObj = distributedDataObject.create(context, data);
      this.distributedObj.on('progressChanged', () => {
        hilog.info(DOMAIN_ZERO, TAG, 'Distributed data changed');
      });
      hilog.info(DOMAIN_ZERO, TAG, 'DistributedSyncHelper initialized');
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'DistributedSync init failed: %{public}s', JSON.stringify(error));
    }
  }

  async syncToRemote(data: DistributedMemberData[]): Promise<void> {
    if (this.distributedObj === null) {
      hilog.warn(DOMAIN_ZERO, TAG, 'DistributedObj not initialized, skip sync');
      return;
    }
    try {
      this.distributedObj['family_member_sync'] = data;
      hilog.info(DOMAIN_ZERO, TAG, 'Distributed sync to remote success');
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Distributed sync failed: %{public}s', JSON.stringify(error));
    }
  }

  destroy(): void {
    if (this.distributedObj !== null) {
      try {
        this.distributedObj.off('change');
      } catch (_e) {
        // ignore
      }
      this.distributedObj = null;
    }
    DistributedSyncHelper.instance = null;
  }
}
