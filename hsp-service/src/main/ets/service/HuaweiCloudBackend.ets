// HuaweiCloudBackend.ets
// 华为云 Serverless 后端架构定义 — 云函数/云数据库/云存储完整配置
// 实际部署请使用华为云 AGC (AppGallery Connect) 控制台

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, API_CONFIG, serialScheduler } from 'hsp_core';
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
  'ai-chat': 'aichat',
  'additive-interaction': 'additiveinteraction',
  'additive-safety-assess': 'additivesafetyassess',
  'allergen-detect': 'allergendetect',
  'allergen-cross-check': 'allergencrosscheck',
  'alternative-search': 'alternativesearch',
  'health-report-generator': 'healthreportgen',
  'food-submission': 'foodsubmission',
  'submit-feedback': 'submitfeedback',
  'user-data-deletion': 'userdatadeletion'
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
  const config: CloudFunctionConfig = new CloudFunctionConfig()
  config.name = name;
  config.path = path;
  config.method = method;
  config.timeout = timeout;
  config.description = description;
  return config;
}

function createCloudDatabaseConfig(name: string, collection: string, schema: string, description: string): CloudDatabaseConfig {
  const config: CloudDatabaseConfig = new CloudDatabaseConfig()
  config.name = name;
  config.collection = collection;
  config.schema = schema;
  config.description = description;
  return config;
}

function createCloudStorageConfig(name: string, bucket: string, path: string, description: string): CloudStorageConfig {
  const config: CloudStorageConfig = new CloudStorageConfig()
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
    'AI对话 — 云端大模型对话降级（端侧模型不可用时）'),
  createCloudFunctionConfig('additive-interaction', '/api/additive/interaction', http.RequestMethod.POST, 5000,
    '添加剂交互检测 — 检测多添加剂协同风险'),
  createCloudFunctionConfig('additive-safety-assess', '/api/additive/safety-assess', http.RequestMethod.POST, 5000,
    '添加剂安全评估 — E编号风险评级'),
  createCloudFunctionConfig('allergen-detect', '/api/allergen/detect', http.RequestMethod.POST, 5000,
    '过敏原检测 — 成分与用户过敏原匹配'),
  createCloudFunctionConfig('allergen-cross-check', '/api/allergen/cross-check', http.RequestMethod.POST, 5000,
    '交叉过敏检测 — 交叉反应性风险分析'),
  createCloudFunctionConfig('alternative-search', '/api/food/alternative-search', http.RequestMethod.POST, 8000,
    '替代品搜索 — GaussDB向量检索替代食品'),
  createCloudFunctionConfig('health-report-generator', '/api/health/report', http.RequestMethod.POST, 10000,
    '健康报告生成 — 营养摄入汇总与评估'),
  createCloudFunctionConfig('food-submission', '/api/contribute/food-submission', http.RequestMethod.POST, 5000,
    '食品贡献 — 用户补录食品信息审核'),
  createCloudFunctionConfig('submit-feedback', '/api/feedback/submit', http.RequestMethod.POST, 3000,
    '反馈提交 — 用户反馈工单生成'),
  createCloudFunctionConfig('user-data-deletion', '/api/user/data-deletion', http.RequestMethod.POST, 10000,
    '用户数据删除 — GDPR/PIPL一键数据擦除')
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

export interface RequestCacheEntry {
  result: Object | null;
  timestamp: number;
}

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

  private requestCache: Map<string, RequestCacheEntry> = new Map();
  private static readonly IDEMPOTENT_TTL_MS = 5000;

  async callFunction(functionName: string, payload: Object, token?: string, idempotencyKey?: string): Promise<Object | null> {
    const cacheKey = idempotencyKey ?? `${functionName}_${Date.now()}`;
    const cached = this.requestCache.get(cacheKey);
    if (cached !== undefined && Date.now() - cached.timestamp < HuaweiCloudBackend.IDEMPOTENT_TTL_MS) {
      return cached.result;
    }

    return serialScheduler.enqueue(`cf_${functionName}_${cacheKey}`, async (): Promise<Object | null> => {
      const cachedInner = this.requestCache.get(cacheKey);
      if (cachedInner !== undefined && Date.now() - cachedInner.timestamp < HuaweiCloudBackend.IDEMPOTENT_TTL_MS) {
        return cachedInner.result;
      }

      const result = await this.doCallFunction(functionName, payload, token);
      this.requestCache.set(cacheKey, { result: result, timestamp: Date.now() });
      if (this.requestCache.size > 100) {
        let firstKey: string = '';
        this.requestCache.forEach((_value: RequestCacheEntry, key: string) => {
          if (firstKey.length === 0) {
            firstKey = key;
          }
        });
        if (firstKey.length > 0) {
          this.requestCache.delete(firstKey);
        }
      }
      return result;
    });
  }

  private async doCallFunction(functionName: string, payload: Object, token?: string): Promise<Object | null> {
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

      const opts: SecureRequestOptions = new SecureRequestOptions()
      opts.url = url;
      opts.method = config.method;
      opts.header = header;
      opts.extraData = config.method === http.RequestMethod.GET ? '' : JSON.stringify(payload);
      opts.connectTimeout = config.timeout;
      opts.readTimeout = config.timeout;

      const response = await SecureHttpClient.getInstance().request(opts);
      if (response.responseCode === 200) {
        let bodyStr: string = '';
        if (typeof response.result === 'string') {
          bodyStr = response.result;
        } else if (response.result instanceof ArrayBuffer) {
          bodyStr = String.fromCharCode(...new Uint8Array(response.result));
        } else {
          bodyStr = response.result.toString();
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
    const summary: string[] = []
    summary.push(`华为云 Serverless 架构:`)
    summary.push(`  云函数: ${CLOUD_FUNCTIONS.length}个 — ${CLOUD_FUNCTIONS.map(f => f.name).join(', ')}`)
    summary.push(`  云数据库: ${CLOUD_DATABASES.length}个 — ${CLOUD_DATABASES.map(d => d.name).join(', ')}`)
    summary.push(`  云存储: ${CLOUD_STORAGES.length}个 — ${CLOUD_STORAGES.map(s => s.name).join(', ')}`)
    summary.push(`  API版本: ${this.apiVersion}`)
    return summary.join('\n');
  }
}
