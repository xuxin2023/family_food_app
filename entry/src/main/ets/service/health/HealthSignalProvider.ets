import { HealthSignal } from '../../model/HealthSignal';

export interface HealthSignalProvider {
  checkAuthorization(): Promise<boolean>;
  requestAuthorization(): Promise<boolean>;
  getTodayHealthData(memberId: string): Promise<HealthSignal>;
  /** 释放资源（切换 provider 时调用） */
  release?(): void;
}
