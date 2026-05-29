import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'ConfigManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PREFS_NAME = 'app_config_prefs';

export class ConfigManager {
  private static instance: ConfigManager | null = null;
  private configCache: Map<string, string> = new Map();
  private initialized: boolean = false;

  private static readonly DEFAULTS: Map<string, string> = new Map([
    ['cloud_function_base', 'https://familyfood-api.cn-north-4.myhuaweicloud.com'],
    ['cloud_function_dev_base', 'https://familyfood-dev.cn-north-4.myhuaweicloud.com'],
    ['off_api_base', 'https://world.openfoodfacts.org/api/v2/'],
    ['off_product_url_template', 'https://world.openfoodfacts.org/api/v2/product/{barcode}.json'],
    ['obs_privacy_base', 'https://familyfood-privacy.obs.cn-north-4.myhuaweicloud.com'],
    ['feedback_url', 'https://familyfood-api.cn-north-4.myhuaweicloud.com/api/feedback'],
    ['cloud_region', 'cn-north-4'],
  ]);

  static getInstance(): ConfigManager {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager();
    }
    return ConfigManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.initialized) return;

    try {
      const prefs = await preferences.getPreferences(context, PREFS_NAME);
      ConfigManager.DEFAULTS.forEach((defaultValue, key) => {
        const cachedValue = prefs.getSync(key, '') as string;
        this.configCache.set(key, cachedValue || defaultValue);
      });

      this.initialized = true;
      hilog.info(DOMAIN_ZERO, TAG, 'ConfigManager initialized with %{public}d keys', this.configCache.size);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'ConfigManager init failed, using defaults: %{public}s', JSON.stringify(error));
      ConfigManager.DEFAULTS.forEach((defaultValue, key) => {
        this.configCache.set(key, defaultValue);
      });
      this.initialized = true;
    }
  }

  getUrl(key: string): string {
    return this.configCache.get(key) ?? ConfigManager.DEFAULTS.get(key) ?? '';
  }

  getCloudFunctionBase(): string {
    return this.getUrl('cloud_function_base');
  }

  getCloudFunctionDevBase(): string {
    return this.getUrl('cloud_function_dev_base');
  }

  getOffApiBase(): string {
    return this.getUrl('off_api_base');
  }

  getProductUrl(barcode: string): string {
    return this.getUrl('off_product_url_template').replace('{barcode}', barcode);
  }

  getObsPrivacyBase(): string {
    return this.getUrl('obs_privacy_base');
  }

  getFeedbackUrl(): string {
    return this.getUrl('feedback_url');
  }

  getCloudRegion(): string {
    return this.getUrl('cloud_region');
  }

  buildFunctionUrl(funcId: string): string {
    const region = this.getCloudRegion();
    return `https://${funcId}.${region}.myhuaweicloud.com`;
  }

  async updateConfig(context: common.Context, key: string, value: string): Promise<void> {
    this.configCache.set(key, value);
    try {
      const prefs = await preferences.getPreferences(context, PREFS_NAME);
      await prefs.put(key, value);
      await prefs.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Failed to persist config: %{public}s', JSON.stringify(error));
    }
  }
}
