import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FamilyProfile, HealthSignal, DailyBudget } from 'hsp_core';
import { IAiStateProvider } from '../IAiStateProvider';
import { DistributedSyncPayload, ConflictAction } from './SyncTypes';

const TAG = 'DistributedSyncEnhancerImpl';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class DistributedSyncEnhancerImpl {
  private static instance: DistributedSyncEnhancerImpl | null = null;
  private syncVersion: number = 0;
  private deviceId: string = '';
  private stateProvider: IAiStateProvider;

  private constructor(stateProvider: IAiStateProvider) {
    this.stateProvider = stateProvider;
  }

  static getInstance(stateProvider: IAiStateProvider): DistributedSyncEnhancerImpl {
    if (DistributedSyncEnhancerImpl.instance === null) {
      DistributedSyncEnhancerImpl.instance = new DistributedSyncEnhancerImpl(stateProvider);
    }
    return DistributedSyncEnhancerImpl.instance;
  }

  setDeviceId(deviceId: string): void { this.deviceId = deviceId; }

  serializeForSync(): DistributedSyncPayload {
    try {
      const members = this.stateProvider.getAllMembersSync ? this.stateProvider.getAllMembersSync() : [];
      const healthSignals: Record<string, HealthSignal> = {};
      const dailyBudgets: Record<string, DailyBudget> = {};

      for (const member of members) {
        healthSignals[member.memberId] = this.stateProvider.getHealthSignal(member.memberId);
        dailyBudgets[member.memberId] = this.stateProvider.getDailyBudget(member.memberId);
      }

      this.syncVersion++;
      const payload: DistributedSyncPayload = {
        currentMemberId: this.stateProvider.getCurrentMemberId(),
        members: JSON.stringify(members),
        healthSignals: JSON.stringify(healthSignals),
        dailyBudgets: JSON.stringify(dailyBudgets),
        recentScanFoodId: '',
        timestamp: Date.now(),
        deviceId: this.deviceId,
        version: this.syncVersion
      };

      hilog.info(DOMAIN_ZERO, TAG, 'Serialized sync payload: %{public}d members, v%{public}d', members.length, this.syncVersion);
      return payload;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'serializeForSync failed: %{public}s', JSON.stringify(e));
      return { currentMemberId: '', members: '[]', healthSignals: '{}', dailyBudgets: '{}', recentScanFoodId: '', timestamp: Date.now(), deviceId: this.deviceId, version: 0 };
    }
  }

  resolveConflict(local: DistributedSyncPayload, remote: DistributedSyncPayload, action: ConflictAction): DistributedSyncPayload {
    switch (action) {
      case ConflictAction.KEEP_LOCAL: return local;
      case ConflictAction.KEEP_REMOTE: return remote;
      case ConflictAction.MERGE: return this.mergePayloads(local, remote);
      default: return local.timestamp >= remote.timestamp ? local : remote;
    }
  }

  private mergePayloads(local: DistributedSyncPayload, remote: DistributedSyncPayload): DistributedSyncPayload {
    try {
      const localMembers = JSON.parse(local.members) as FamilyProfile[];
      const remoteMembers = JSON.parse(remote.members) as FamilyProfile[];
      const mergedMemberMap = new Map<string, FamilyProfile>();
      for (const m of localMembers) { mergedMemberMap.set(m.memberId, m); }
      for (const m of remoteMembers) {
        const existing = mergedMemberMap.get(m.memberId);
        if (!existing || m.lastModified > existing.lastModified) { mergedMemberMap.set(m.memberId, m); }
      }
      const mergedMembers = Array.from(mergedMemberMap.values());
      return {
        currentMemberId: local.timestamp >= remote.timestamp ? local.currentMemberId : remote.currentMemberId,
        members: JSON.stringify(mergedMembers),
        healthSignals: local.timestamp >= remote.timestamp ? local.healthSignals : remote.healthSignals,
        dailyBudgets: local.timestamp >= remote.timestamp ? local.dailyBudgets : remote.dailyBudgets,
        recentScanFoodId: local.recentScanFoodId || remote.recentScanFoodId,
        timestamp: Math.max(local.timestamp, remote.timestamp),
        deviceId: local.timestamp >= remote.timestamp ? local.deviceId : remote.deviceId,
        version: Math.max(local.version, remote.version) + 1
      };
    } catch (e) {
      return local.timestamp >= remote.timestamp ? local : remote;
    }
  }
}