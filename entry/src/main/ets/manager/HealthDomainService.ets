// HealthDomainService.ets
// 健康信号领域服务 - 从 AppState 剥离的健康数据相关业务逻辑

import { HealthSignal, DataSource } from '../model/HealthSignal';
import { DateUtil } from '../utils/DateUtil';
import { CacheManager } from '../utils/CacheManager';
import { ServiceManager } from '../ServiceManager';
import { common } from '@kit.AbilityKit';

export class HealthDomainService {
  private services: ServiceManager;
  private cacheMgr: CacheManager;

  constructor(services: ServiceManager, cache: CacheManager) {
    this.services = services;
    this.cacheMgr = cache;
  }

  getHealthSignal(memberId: string): HealthSignal {
    const cached = this.cacheMgr.getHealthSignalFromCache(memberId);
    if (cached) return cached;
    const signal = new HealthSignal();
    signal.memberId = memberId;
    signal.date = DateUtil.getToday();
    this.cacheMgr.setHealthSignalToCache(memberId, signal);
    return signal;
  }

  updateHealthSignal(signal: HealthSignal): void {
    this.cacheMgr.setHealthSignalToCache(signal.memberId, signal);
  }

  async switchToHwHealthKit(context: common.Context): Promise<boolean> {
    return this.services.switchToHwHealthKit(context);
  }

  switchToManualProvider(): void {
    this.services.switchToManualProvider();
  }

  isUsingHwHealthKit(): boolean {
    return this.services.useHwHealthKit;
  }

  async requestHealthAuthorization(uiContext?: common.UIAbilityContext): Promise<boolean> {
    return this.services.requestHealthAuthorization(uiContext);
  }

  async checkHealthAuthorization(): Promise<boolean> {
    return this.services.checkHealthAuthorization();
  }
}
