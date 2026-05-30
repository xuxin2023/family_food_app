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