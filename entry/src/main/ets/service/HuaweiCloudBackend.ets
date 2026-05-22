// HuaweiCloudBackend.ets
// 华为云 Serverless 后端架构定义 — 云函数/云数据库/云存储完整配置
// 实际部署请使用华为云 AGC (AppGallery Connect) 控制台

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { http } from '@kit.NetworkKit';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';

const TAG = 'HuaweiCloudBackend';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class CloudFunctionConfig {
  name: string = '';
  path: string = '';
  method: http.RequestMethod = http.RequestMethod.POST;
  timeout: number = 10000;
  description: string = '';
}

export class CloudDatabaseConfig {
  name: string = '';
  collection: string = '';
  schema: string = '';
  description: string = '';
}

export class CloudStorageConfig {
  name: string = '';
  bucket: string = '';
  path: string = '';
  description: string = '';
}

export const CLOUD_FUNCTIONS: CloudFunctionConfig[] = [
  { name: 'food-lookup', path: '/api/food/lookup', method: http.RequestMethod.GET, timeout: 5000,
    description: '食品查找 — 条码/名称查询，L1本地缓存/L2华为云数据库/L3 OFF API' },
  { name: 'alt-recommend', path: '/api/food/alternatives', method: http.RequestMethod.POST, timeout: 8000,
    description: '替代推荐 — 基于AI模型的食品替代方案生成' },
  { name: 'iap-verify', path: '/api/iap/verify', method: http.RequestMethod.POST, timeout: 5000,
    description: 'IAP验证 — 华为支付购买凭证服务端二次校验' },
  { name: 'error-report', path: '/api/errors/report', method: http.RequestMethod.POST, timeout: 3000,
    description: '错误上报 — 客户端异常聚合上报与告警' },
  { name: 'sync-gateway', path: '/api/sync/batch', method: http.RequestMethod.POST, timeout: 15000,
    description: '同步网关 — 离线变更批量同步与冲突检测' },
  { name: 'user-profile', path: '/api/user/profile', method: http.RequestMethod.POST, timeout: 3000,
    description: '用户档案 — 创建/更新/删除用户及家庭成员档案' },
  { name: 'nutrition-analysis', path: '/api/nutrition/analyze', method: http.RequestMethod.POST, timeout: 10000,
    description: '营养分析 — 批量营养摄入分析与周报生成' },
  { name: 'ai-chat', path: '/api/ai/chat', method: http.RequestMethod.POST, timeout: 30000,
    description: 'AI对话 — 云端大模型对话降级（端侧模型不可用时）' }
];

export const CLOUD_DATABASES: CloudDatabaseConfig[] = [
  { name: 'food_db', collection: 'foods', schema: 'food_v2', description: '食品营养数据库（50万+中国SKU）' },
  { name: 'subscription_db', collection: 'subscriptions', schema: 'sub_v1', description: '订阅状态数据库' },
  { name: 'user_profile_db', collection: 'user_profiles', schema: 'profile_v2', description: '用户档案数据库' },
  { name: 'scan_history_db', collection: 'scan_history', schema: 'history_v1', description: '扫描历史数据库' },
  { name: 'community_db', collection: 'recipes', schema: 'recipe_v1', description: '食谱社区数据库' }
];

export const CLOUD_STORAGES: CloudStorageConfig[] = [
  { name: 'food_images', bucket: 'food-images', path: '/images/', description: '食品图片CDN' },
  { name: 'model_assets', bucket: 'ai-models', path: '/models/', description: '端侧AI模型文件分发' },
  { name: 'user_exports', bucket: 'user-exports', path: '/exports/', description: '用户数据导出文件' }
];

export class HuaweiCloudBackend {
  private static instance: HuaweiCloudBackend | null = null;
  private baseUrl: string = '';
  private apiVersion: string = 'v2';

  static getInstance(): HuaweiCloudBackend {
    if (!HuaweiCloudBackend.instance) {
      HuaweiCloudBackend.instance = new HuaweiCloudBackend();
    }
    return HuaweiCloudBackend.instance;
  }

  init(baseUrl: string): void {
    this.baseUrl = baseUrl;
    hilog.info(DOMAIN_ZERO, TAG, 'HuaweiCloudBackend init: %{public}s', baseUrl);
  }

  async callFunction(functionName: string, payload: Object, token?: string): Promise<Object | null> {
    const config = CLOUD_FUNCTIONS.find(f => f.name === functionName);
    if (!config) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Unknown cloud function: %{public}s', functionName);
      return null;
    }

    try {
      const url = `${this.baseUrl}${config.path}`;
      const header = new Map<string, string>();
      header.set('Content-Type', 'application/json');
      header.set('X-Api-Version', this.apiVersion);
      if (token && token.length > 0) {
        header.set('Authorization', `Bearer ${token}`);
      }

      const opts = new SecureRequestOptions();
      opts.url = url;
      opts.method = config.method;
      opts.header = header;
      opts.extraData = config.method === http.RequestMethod.GET ? '' : JSON.stringify(payload);
      opts.connectTimeout = config.timeout;
      opts.readTimeout = config.timeout;

      const response = await SecureHttpClient.getInstance().request(opts);
      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as Object;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'Cloud function %{public}s returned HTTP %{public}d',
        functionName, response.responseCode);
      return null;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Cloud function %{public}s failed: %{public}s',
        functionName, (e as Error).message);
      return null;
    }
  }

  getFunctionConfigs(): CloudFunctionConfig[] {
    return [...CLOUD_FUNCTIONS];
  }

  getDatabaseConfigs(): CloudDatabaseConfig[] {
    return [...CLOUD_DATABASES];
  }

  getStorageConfigs(): CloudStorageConfig[] {
    return [...CLOUD_STORAGES];
  }

  getArchitectureSummary(): string {
    return [
      `华为云 Serverless 架构:`,
      `  云函数: ${CLOUD_FUNCTIONS.length}个 — ${CLOUD_FUNCTIONS.map(f => f.name).join(', ')}`,
      `  云数据库: ${CLOUD_DATABASES.length}个 — ${CLOUD_DATABASES.map(d => d.name).join(', ')}`,
      `  云存储: ${CLOUD_STORAGES.length}个 — ${CLOUD_STORAGES.map(s => s.name).join(', ')}`,
      `  API版本: ${this.apiVersion}`
    ].join('\n');
  }
}
