import { DistributedSyncPayload, ConflictAction, DistributedSyncEnhancerImpl, IAiStateProvider } from 'hsp_service';
import { FamilyProfile, HealthSignal, DailyBudget, NutritionTarget } from 'hsp_core';
import { AppState } from '../AppState';

class SyncStateProvider implements IAiStateProvider {
  async getAllMembers(): Promise<FamilyProfile[]> {
    return AppState.getInstance().getAllMembers();
  }
  getAllMembersSync(): FamilyProfile[] {
    return AppState.getInstance().getAllMembersSync();
  }
  getHealthSignal(memberId: string): HealthSignal {
    return AppState.getInstance().getHealthSignal(memberId);
  }
  getDailyBudget(memberId: string): DailyBudget {
    return AppState.getInstance().getDailyBudgetSync(memberId);
  }
  getCurrentMemberId(): string {
    return AppState.getInstance().member.memberId;
  }
  getNutritionTarget(memberId: string): NutritionTarget | null {
    return AppState.getInstance().getNutritionTargetFromCache(memberId);
  }
}

let _impl: DistributedSyncEnhancerImpl | null = null;

function getImpl(): DistributedSyncEnhancerImpl {
  if (_impl === null) {
    _impl = DistributedSyncEnhancerImpl.getInstance(new SyncStateProvider());
  }
  return _impl;
}

export class DistributedSyncEnhancer {
  static getInstance(): DistributedSyncEnhancer { return new DistributedSyncEnhancer(); }
  setDeviceId(deviceId: string): void { getImpl().setDeviceId(deviceId); }
  serializeForSync(): DistributedSyncPayload { return getImpl().serializeForSync(); }
  resolveConflict(local: DistributedSyncPayload, remote: DistributedSyncPayload, action: ConflictAction): DistributedSyncPayload { return getImpl().resolveConflict(local, remote, action); }
}

export { DistributedSyncPayload, ConflictAction } from 'hsp_service';
