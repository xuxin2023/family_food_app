// CloudStorageProvider.ets
// 云端存储适配层 - 封装与远程云存储服务的HTTP通信
// P0版本：RESTful API 接口封装（对接自建后端或云服务）
// 后续可替换为 AGC Cloud DB、WebSocket 等实现

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CloudStorageProvider';
const DOMAIN_ZERO = 0;

/**
 * 云端操作结果
 */
export interface CloudOperationResult<T = unknown> {
  success: boolean;
  data: T | null;
  errorMessage: string;
  statusCode: number;
}

/**
 * 云端同步批量请求体
 */
export interface SyncBatchRequest {
  /** 用户认证Token */
  token: string;
  /** 设备唯一标识 */
  deviceId: string;
  /** 上次同步时间戳 */
  lastSyncAt: number;
  /** 待上传的变更记录列表 */
  uploads: SyncBatchItem[];
}

/**
 * 云端同步批量响应体
 */
export interface SyncBatchResponse {
  /** 服务端收到的最大版本号 */
  serverVersion: number;
  /** 需要应用到本地的远程变更列表 */
  downloads: SyncBatchItem[];
  /** 冲突记录列表（需要解决冲突） */
  conflicts: SyncConflictItem[];
}

/**
 * 同步批次数据项
 */
export interface SyncBatchItem {
  entityType: string;
  entityId: string;
  changeType: string;
  data: string;
  version: number;
  changedAt: number;
}

/**
 * 冲突项
 */
export interface SyncConflictItem {
  entityType: string;
  entityId: string;
  localData: string;
  remoteData: string;
  localVersion: number;
  remoteVersion: number;
}

/**
 * 云存储提供者配置
 */
export interface CloudStorageProviderConfig {
  /** API基础URL */
  baseUrl: string;
  /** API版本路径 */
  apiVersion: string;
  /** 请求超时（ms） */
  timeout: number;
}

export class CloudStorageProvider {
  private config: CloudStorageProviderConfig;
  private httpClient: http.HttpRequest | null = null;

  constructor(config: CloudStorageProviderConfig) {
    this.config = config;
  }

  /**
   * 更新配置
   */
  updateConfig(config: Partial<CloudStorageProviderConfig>): void {
    if (config.baseUrl !== undefined) {
      this.config.baseUrl = config.baseUrl;
    }
    if (config.apiVersion !== undefined) {
      this.config.apiVersion = config.apiVersion;
    }
    if (config.timeout !== undefined) {
      this.config.timeout = config.timeout;
    }
  }

  /**
   * 用户注册/登录（获取token）
   */
  async authenticate(uid: string, deviceId: string): Promise<CloudOperationResult<{ token: string }>> {
    return this.request<{ token: string }>('POST', '/auth/login', {
      uid: uid,
      deviceId: deviceId,
      timestamp: Date.now()
    });
  }

  /**
   * 注册设备
   */
  async registerDevice(uid: string, deviceId: string, deviceName: string):
    Promise<CloudOperationResult<{ deviceRegistered: boolean }>> {
    return this.request('POST', '/devices/register', {
      uid: uid,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: 'HarmonyOS'
    });
  }

  /**
   * 上传变更批次（推送本地变更到云端）
   */
  async uploadBatch(token: string, batch: SyncBatchRequest):
    Promise<CloudOperationResult<SyncBatchResponse>> {
    return this.request('POST', '/sync/upload', batch, token);
  }

  /**
   * 拉取远程变更（从云端获取变更）
   */
  async fetchChanges(token: string, deviceId: string, lastSyncAt: number):
    Promise<CloudOperationResult<SyncBatchResponse>> {
    return this.request('GET',
      `/sync/changes?deviceId=${deviceId}&lastSyncAt=${lastSyncAt}`, null, token);
  }

  /**
   * 确认同步（标记云端变更为已处理）
   */
  async confirmSync(token: string, syncedIds: string[]): Promise<CloudOperationResult<void>> {
    return this.request('POST', '/sync/confirm', {
      syncedIds: syncedIds
    }, token);
  }

  /**
   * 报告冲突解决结果
   */
  async resolveConflict(token: string, entityType: string, entityId: string,
    resolution: string, resolvedData: string): Promise<CloudOperationResult<void>> {
    return this.request('POST', '/sync/resolve-conflict', {
      entityType: entityType,
      entityId: entityId,
      resolution: resolution,
      resolvedData: resolvedData
    }, token);
  }

  /**
   * 获取用户关联的设备列表
   */
  async getDevices(token: string): Promise<CloudOperationResult<Array<{
    deviceId: string;
    deviceName: string;
    lastSyncAt: number;
  }>>> {
    return this.request('GET', '/devices', null, token);
  }

  /**
   * 获取同步统计信息
   */
  async getSyncStats(token: string): Promise<CloudOperationResult<{
    totalSyncs: number;
    totalConflicts: number;
    lastSyncAt: number;
    deviceCount: number;
  }>> {
    return this.request('GET', '/sync/stats', null, token);
  }

  // ========== 内部HTTP请求封装 ==========

  private async request<T>(
    method: string, path: string,
    body: unknown | null, token?: string
  ): Promise<CloudOperationResult<T>> {
    const url = `${this.config.baseUrl}${this.config.apiVersion}${path}`;

    try {
      this.httpClient = http.createHttp();
      const header: Record<string, string> = {
        'Content-Type': 'application/json'
      };
      if (token && token.length > 0) {
        header['Authorization'] = `Bearer ${token}`;
      }

      const result = await this.httpClient.request(url, {
        method: method === 'GET' ? http.RequestMethod.GET : http.RequestMethod.POST,
        header: header,
        extraData: body ? JSON.stringify(body) : '',
        connectTimeout: this.config.timeout,
        readTimeout: this.config.timeout
      });

      if (result.responseCode === http.ResponseCode.OK ||
          result.responseCode === http.ResponseCode.CREATED) {
        const responseData = JSON.parse(result.result as string);
        return {
          success: true,
          data: responseData as T,
          errorMessage: '',
          statusCode: result.responseCode
        };
      }

      return {
        success: false,
        data: null,
        errorMessage: `HTTP ${result.responseCode}`,
        statusCode: result.responseCode
      };
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN_ZERO, TAG, 'Request failed: %{public}s', JSON.stringify(err));
      return {
        success: false,
        data: null,
        errorMessage: err.message || '网络请求失败',
        statusCode: 0
      };
    } finally {
      if (this.httpClient) {
        this.httpClient.destroy();
        this.httpClient = null;
      }
    }
  }
}
