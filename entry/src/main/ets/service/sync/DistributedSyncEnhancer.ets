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
}

export class DistributedSyncEnhancer {
  private static instance: DistributedSyncEnhancer | null = null;

  static getInstance(): DistributedSyncEnhancer {
    if (!DistributedSyncEnhancer.instance) {
      DistributedSyncEnhancer.instance = new DistributedSyncEnhancer();
    }
    return DistributedSyncEnhancer.instance;
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

      const payload: DistributedSyncPayload = {
        currentMemberId: appState.member.memberId,
        members: JSON.stringify(members),
        healthSignals: JSON.stringify(healthSignals),
        dailyBudgets: JSON.stringify(dailyBudgets),
        recentScanFoodId: '',
        timestamp: Date.now()
      };

      hilog.info(DOMAIN_ZERO, TAG, 'Serialized sync payload: %{public}d members', members.length);
      return payload;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'serializeForSync failed: %{public}s', JSON.stringify(e));
      return {
        currentMemberId: '',
        members: '[]',
        healthSignals: '{}',
        dailyBudgets: '{}',
        recentScanFoodId: '',
        timestamp: Date.now()
      };
    }
  }

  restoreFromSync(payload: DistributedSyncPayload): void {
    try {
      const appState = AppState.getInstance();

      if (payload.currentMemberId.length > 0) {
        AppStorage.setOrCreate('currentMemberId', payload.currentMemberId);
      }

      hilog.info(DOMAIN_ZERO, TAG, 'Restored from distributed sync, timestamp=%{public}d', payload.timestamp);
      appState.refreshMemberCache();
      appState.refreshBudgetCache();
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'restoreFromSync failed: %{public}s', JSON.stringify(e));
    }
  }
}
