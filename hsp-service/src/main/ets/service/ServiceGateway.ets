import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN } from 'hsp_core';

const TAG = 'ServiceGateway';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const PREF_CACHE_NAME = 'service_gateway_cache';
const CACHE_TTL_MS = 300000;

export class ServiceGateway {
  private static instance: ServiceGateway | null = null;
  private context: common.Context | null = null;

  static getInstance(): ServiceGateway {
    if (!ServiceGateway.instance) {
      ServiceGateway.instance = new ServiceGateway();
    }
    return ServiceGateway.instance;
  }

  init(context: common.Context): void {
    this.context = context;
  }

  static async callWithFallback<T>(
    primary: () => Promise<T>,
    fallback: () => Promise<T>,
    cacheKey?: string
  ): Promise<T> {
    const gateway = ServiceGateway.getInstance();
    try {
      const result = await primary();
      if (cacheKey) {
        await gateway.saveCache(cacheKey, result);
      }
      return result;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Primary call failed, using fallback: %{public}s', JSON.stringify(error));
      if (cacheKey) {
        const cached = await gateway.loadCache<T>(cacheKey);
        if (cached !== null) {
          hilog.info(DOMAIN_ZERO, TAG, 'Cache hit for key: %{public}s', cacheKey);
          return cached;
        }
      }
      return fallback();
    }
  }

  private async saveCache(key: string, data: Object): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_CACHE_NAME);
      await prefs.put(key, JSON.stringify(data));
      await prefs.flush();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'saveCache failed: %{public}s', JSON.stringify(e));
    }
  }

  private async loadCache<T>(key: string): Promise<T | null> {
    if (!this.context) return null;
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_CACHE_NAME);
      const raw = prefs.getSync(key, '') as string;
      if (raw.length === 0) return null;
      return JSON.parse(raw) as T;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadCache failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }
}
