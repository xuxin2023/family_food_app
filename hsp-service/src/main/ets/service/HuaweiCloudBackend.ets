// HuaweiCloudBackend.ets
// 华为云 Serverless 后端架构定义 — 云函数/云数据库/云存储完整配置
// 实际部署请使用华为云 AGC (AppGallery Connect) 控制台

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, API_CONFIG } from 'hsp_core';
import { http } from '@kit.NetworkKit';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';
import { ConfigManager } from './ConfigManager';

const TAG = 'HuaweiCloudBackend';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const CLOUD_FUNCTION_IDS: Record<string, string> = {
  'food-lookup': 'foodlookup',
  'alt-recommend': 'altrecommend',
  'search-alternatives': 'searchalternatives',
  'iap-verify': 'iapverify',
  'error-report': 'errorreport',
  'sync-gateway': 'syncgateway',
  'user-profile': 'userprofile',
  'nutrition-analysis': 'nutritionanalysis',
  'ai-chat': 'aichat'
};

function resolveBaseUrl(): string {
  const configured = API_CONFIG.HUAWEI_CLOUD_BASE_URL;
  if (configured.length > 0) {
    return configured;
  }
  return ConfigManager.getInstance().getCloudFunctionBase();
}

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

function createCloudFunctionConfig(name: string, path: string, method: http.RequestMethod,
  timeout: number, description: string): CloudFunctionConfig {
  const config = new CloudFunctionConfig();
  config.name = name;
  config.path = path;
  config.method = method;
  config.timeout = timeout;
  config.description = description;
  return config;
}

function createCloudDatabaseConfig(name: string, collection: string, schema: string, description: string): CloudDatabaseConfig {
  const config = new CloudDatabaseConfig();
  config.name = name;
  config.collection = collection;
  config.schema = schema;
  config.description = description;
  return config;
}

function createCloudStorageConfig(name: string, bucket: string, path: string, description: string): CloudStorageConfig {
  const config = new CloudStorageConfig();
  config.name = name;
  config.bucket = bucket;
  config.path = path;
  config.description = description;
  return config;
}

export const CLOUD_FUNCTIONS: CloudFunctionConfig[] = [
  createCloudFunctionConfig('food-lookup', '/api/food/lookup', http.RequestMethod.GET, 5000,
    '食品查找 — 条码/名称查询，L1本地缓存/L2华为云数据库/L3 OFF API'),
  createCloudFunctionConfig('alt-recommend', '/api/food/alternatives', http.RequestMethod.POST, 8000,
    '替代推荐 — 基于AI模型的食品替代方案生成'),
  createCloudFunctionConfig('search-alternatives', '/api/food/search-alternatives', http.RequestMethod.POST, 8000,
    '替代品搜索 — 基于GaussDB的在线替代品检索'),
  createCloudFunctionConfig('iap-verify', '/api/iap/verify', http.RequestMethod.POST, 5000,
    'IAP验证 — 华为支付购买凭证服务端二次校验'),
  createCloudFunctionConfig('error-report', '/api/errors/report', http.RequestMethod.POST, 3000,
    '错误上报 — 客户端异常聚合上报与告警'),
  createCloudFunctionConfig('sync-gateway', '/api/sync/batch', http.RequestMethod.POST, 15000,
    '同步网关 — 离线变更批量同步与冲突检测'),
  createCloudFunctionConfig('user-profile', '/api/user/profile', http.RequestMethod.POST, 3000,
    '用户档案 — 创建/更新/删除用户及家庭成员档案'),
  createCloudFunctionConfig('nutrition-analysis', '/api/nutrition/analyze', http.RequestMethod.POST, 10000,
    '营养分析 — 批量营养摄入分析与周报生成'),
  createCloudFunctionConfig('ai-chat', '/api/ai/chat', http.RequestMethod.POST, 30000,
    'AI对话 — 云端大模型对话降级（端侧模型不可用时）')
];

export const CLOUD_DATABASES: CloudDatabaseConfig[] = [
  createCloudDatabaseConfig('food_db', 'foods', 'food_v2', '食品营养数据库（50万+中国SKU）'),
  createCloudDatabaseConfig('subscription_db', 'subscriptions', 'sub_v1', '订阅状态数据库'),
  createCloudDatabaseConfig('user_profile_db', 'user_profiles', 'profile_v2', '用户档案数据库'),
  createCloudDatabaseConfig('scan_history_db', 'scan_history', 'history_v1', '扫描历史数据库'),
  createCloudDatabaseConfig('community_db', 'recipes', 'recipe_v1', '食谱社区数据库')
];

export const CLOUD_STORAGES: CloudStorageConfig[] = [
  createCloudStorageConfig('food_images', 'food-images', '/images/', '食品图片CDN'),
  createCloudStorageConfig('model_assets', 'ai-models', '/models/', '端侧AI模型文件分发'),
  createCloudStorageConfig('user_exports', 'user-exports', '/exports/', '用户数据导出文件'),
  createCloudStorageConfig('privacy_docs', 'familyfood-privacy', '/privacy/', '隐私政策与用户协议OBS托管')
];

export class HuaweiCloudBackend {
  private static instance: HuaweiCloudBackend | null = null;
  private baseUrl: string = resolveBaseUrl();
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
      const funcId = CLOUD_FUNCTION_IDS[functionName] ?? '';
      const url = funcId.length > 0
        ? `https://${funcId}.cn-north-4.myhuaweicloud.com${config.path}`
        : `${this.baseUrl}${config.path}`;
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
        let bodyStr: string;
        if (typeof response.result === 'string') {
          bodyStr = response.result;
        } else if (response.result instanceof ArrayBuffer) {
          bodyStr = String.fromCharCode(...new Uint8Array(response.result));
        } else {
          bodyStr = String(response.result);
        }
        return JSON.parse(bodyStr) as Object;
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
