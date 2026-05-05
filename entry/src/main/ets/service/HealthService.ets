// 健康数据服务 - 只负责健康信号提供者的适配与切换

import { HealthSignal } from '../model/HealthSignal';
import { ManualHealthSignalProvider } from './health/ManualHealthSignalProvider';
import { HealthSignalProvider } from './health/HealthSignalProvider';

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
      } catch (_e) {
        // 释放失败不影响主流程
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
