import { HealthSignal } from 'hsp_core';

export abstract class HealthSignalProvider {
  abstract checkAuthorization(): Promise<boolean>;
  abstract requestAuthorization(): Promise<boolean>;
  abstract getTodayHealthData(memberId: string): Promise<HealthSignal>;
  release?(): void;
}