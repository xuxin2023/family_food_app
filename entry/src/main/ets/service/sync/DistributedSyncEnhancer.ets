import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FamilyProfile, FoodLabel, HealthSignal, DailyBudget } from 'hsp_core';
import { AppState } from '../AppState';

const TAG = 'DistributedSyncEnhancer';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface DistributedSyncPayload {
  currentMemberId: string;
  members: string;
  healthSignals: string;
  dailyBudgets: string;
  recentScanFoodId: string;
  timestamp: number;
  deviceId: string;
  version: number;
}

export enum ConflictAction {
  KEEP_LOCAL = 'keep_local',
  KEEP_REMOTE = 'keep_remote',
  MERGE = 'merge'
}

export class DistributedSyncEnhancer {
  private static instance: DistributedSyncEnhancer | null = null;
  private syncVersion: number = 0;
  private deviceId: string = '';

  static getInstance(): DistributedSyncEnhancer {
    if (!DistributedSyncEnhancer.instance) {
      DistributedSyncEnhancer.instance = new DistributedSyncEnhancer();
    }
    return DistributedSyncEnhancer.instance;
  }

  setDeviceId(deviceId: string): void {
    this.deviceId = deviceId;
  }

  serializeForSync(): DistributedSyncPayload {
    try {
      const appState = AppState.getInstance();
      const members = appState.getAllMembersSync();
      const healthSignals: Record<string, HealthSignal> = {};
      const dailyBudgets: Record<string, DailyBudget> = {};

      for (const member of members) {
        healthSignals[member.memberId] = appState.getHealthSignal(member.memberId);
        dailyBudgets[member.memberId] = appState.getDailyBudgetSync(member.memberId);
      }

      this.syncVersion++;
      const payload: DistributedSyncPayload = {
        currentMemberId: appState.member.memberId,
        members: JSON.stringify(members),
        healthSignals: JSON.stringify(healthSignals),
        dailyBudgets: JSON.stringify(dailyBudgets),
        recentScanFoodId: '',
        timestamp: Date.now(),
        deviceId: this.deviceId,
        version: this.syncVersion
      };

      hilog.info(DOMAIN_ZERO, TAG, 'Serialized sync payload: %{public}d members, v%{public}d',
        members.length, this.syncVersion);
      return payload;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'serializeForSync failed: %{public}s', JSON.stringify(e));
      return {
        currentMemberId: '',
        members: '[]',
        healthSignals: '{}',
        dailyBudgets: '{}',
        recentScanFoodId: '',
        timestamp: Date.now(),
        deviceId: this.deviceId,
        version: 0
      };
    }
  }

  restoreFromSync(payload: DistributedSyncPayload): void {
    try {
      const appState = AppState.getInstance();

      if (payload.currentMemberId.length > 0) {
        AppStorage.setOrCreate('currentMemberId', payload.currentMemberId);
      }

      hilog.info(DOMAIN_ZERO, TAG, 'Restored from distributed sync, v%{public}d, timestamp=%{public}d',
        payload.version, payload.timestamp);
      appState.refreshMemberCache();
      appState.refreshBudgetCache();
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'restoreFromSync failed: %{public}s', JSON.stringify(e));
    }
  }

  resolveConflict(local: DistributedSyncPayload, remote: DistributedSyncPayload,
    action: ConflictAction): DistributedSyncPayload {
    switch (action) {
      case ConflictAction.KEEP_LOCAL:
        hilog.info(DOMAIN_ZERO, TAG, 'Conflict resolved: keep local (v%{public}d)', local.version);
        return local;
      case ConflictAction.KEEP_REMOTE:
        hilog.info(DOMAIN_ZERO, TAG, 'Conflict resolved: keep remote (v%{public}d)', remote.version);
        return remote;
      case ConflictAction.MERGE:
        return this.mergePayloads(local, remote);
      default:
        return local.timestamp >= remote.timestamp ? local : remote;
    }
  }

  private mergePayloads(local: DistributedSyncPayload, remote: DistributedSyncPayload):
    DistributedSyncPayload {
    try {
      const localMembers = JSON.parse(local.members) as FamilyProfile[];
      const remoteMembers = JSON.parse(remote.members) as FamilyProfile[];
      const mergedMemberMap = new Map<string, FamilyProfile>();
      for (const m of localMembers) { mergedMemberMap.set(m.memberId, m); }
      for (const m of remoteMembers) {
        const existing = mergedMemberMap.get(m.memberId);
        if (!existing || m.lastModified > existing.lastModified) {
          mergedMemberMap.set(m.memberId, m);
        }
      }
      const mergedMembers = Array.from(mergedMemberMap.values());
      const result: DistributedSyncPayload = {
        currentMemberId: local.timestamp >= remote.timestamp ? local.currentMemberId : remote.currentMemberId,
        members: JSON.stringify(mergedMembers),
        healthSignals: local.timestamp >= remote.timestamp ? local.healthSignals : remote.healthSignals,
        dailyBudgets: local.timestamp >= remote.timestamp ? local.dailyBudgets : remote.dailyBudgets,
        recentScanFoodId: local.recentScanFoodId || remote.recentScanFoodId,
        timestamp: Math.max(local.timestamp, remote.timestamp),
        deviceId: local.timestamp >= remote.timestamp ? local.deviceId : remote.deviceId,
        version: Math.max(local.version, remote.version) + 1
      };
      hilog.info(DOMAIN_ZERO, TAG, 'Merged payloads: %{public}d members, v%{public}d',
        mergedMembers.length, result.version);
      return result;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'mergePayloads failed: %{public}s', JSON.stringify(e));
      return local.timestamp >= remote.timestamp ? local : remote;
    }
  }
}
