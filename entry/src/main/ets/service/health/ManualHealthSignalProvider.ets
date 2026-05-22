import { hilog } from '@kit.PerformanceAnalysisKit';
import { HealthSignal, StepLevel, SleepStatus, WeightTrend, BpStatus, BsStatus, DataSource, HILOG_DOMAIN } from 'hsp_core';
import { HealthSignalProvider } from './HealthSignalProvider';


const TAG = 'ManualHealthSignalProvider';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class ManualHealthSignalProvider extends HealthSignalProvider {
  async checkAuthorization(): Promise<boolean> {
    hilog.info(DOMAIN_ZERO, TAG, 'Health Kit not connected in P0 MVP');
    return false;
  }

  async requestAuthorization(): Promise<boolean> {
    hilog.info(DOMAIN_ZERO, TAG, 'Health Kit request skipped in P0 MVP');
    return false;
  }

  async getTodayHealthData(memberId: string): Promise<HealthSignal> {
    const signal = new HealthSignal();
    signal.memberId = memberId;
    signal.date = this.getTodayDate();
    signal.stepLevel = StepLevel.NORMAL;
    signal.activityCaloriesLevel = StepLevel.NORMAL;
    signal.sleepStatus = SleepStatus.GOOD;
    signal.weightTrend = WeightTrend.STABLE;
    signal.manualBpStatus = BpStatus.NORMAL;
    signal.manualBsStatus = BsStatus.NORMAL;
    signal.hadHighSodiumToday = false;
    signal.hadHighSugarToday = false;
    signal.source = DataSource.MANUAL;
    return signal;
  }

  private getTodayDate(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}