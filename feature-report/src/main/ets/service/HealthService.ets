// 健康数据服务 - 只负责健康信号提供者的适配与切换

import { HealthSignal, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ManualHealthSignalProvider, HealthSignalProvider } from 'hsp_service';

const TAG = 'HealthService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class HealthService {
  private provider: HealthSignalProvider;

  constructor(provider: HealthSignalProvider = new ManualHealthSignalProvider()) {
    this.provider = provider;
  }

  setProvider(provider: HealthSignalProvider): void {
    // 调用旧 provider 的可选 release() 释放资源
    if (this.provider.release !== undefined) {
      try {
        this.provider.release();
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'release provider failed: %{public}s', JSON.stringify(e));
      }
    }
    this.provider = provider;
  }

  async checkAuthorization(): Promise<boolean> {
    return await this.provider.checkAuthorization();
  }

  async requestAuthorization(): Promise<boolean> {
    return await this.provider.requestAuthorization();
  }

  async getTodayHealthData(memberId: string): Promise<HealthSignal> {
    return await this.provider.getTodayHealthData(memberId);
  }
}