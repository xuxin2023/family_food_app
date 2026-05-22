// CloudStorageProvider.ets
// 云端存储适配层 - 封装与远程云存储服务的HTTP通信
// P0版本：RESTful API 接口封装（对接自建后端或云服务）
// 后续可替换为 AGC Cloud DB、WebSocket 等实现

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { SecureHttpHelper } from '../SecureHttpHelper';

const TAG = 'CloudStorageProvider';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

/**
 * 认证结果
 */
export class AuthResult {
  token: string = '';
}

/**
 * 设备注册结果
 */
export class DeviceRegisterResult {
  deviceRegistered: boolean = false;
}

/**
 * 云端设备信息
 */
export class CloudDeviceInfo {
  deviceId: string = '';
  deviceName: string = '';
  lastSyncAt: number = 0;
}

/**
 * 同步统计信息
 */
export class SyncStatsResult {
  totalSyncs: number = 0;
  totalConflicts: number = 0;
  lastSyncAt: number = 0;
  deviceCount: number = 0;
}

/**
 * 云端操作结果
 */
export class CloudOperationResult<T> {
  success: boolean = false;
  data: T | null = null;
  errorMessage: string = '';
  statusCode: number = 0;
}

/**
 * 云端同步批量请求体
 */
export class SyncBatchRequest {
  /** 用户认证Token */
  token: string = '';
  /** 设备唯一标识 */
  deviceId: string = '';
  /** 上次同步时间戳 */
  lastSyncAt: number = 0;
  /** 待上传的变更记录列表 */
  uploads: SyncBatchItem[] = [];
}

/**
 * 云端同步批量响应体
 */
export class SyncBatchResponse {
  /** 服务端收到的最大版本号 */
  serverVersion: number = 0;
  /** 需要应用到本地的远程变更列表 */
  downloads: SyncBatchItem[] = [];
  /** 冲突记录列表（需要解决冲突） */
  conflicts: SyncConflictItem[] = [];
}

/**
 * 同步批次数据项
 */
export class SyncBatchItem {
  entityType: string = '';
  entityId: string = '';
  changeType: string = '';
  data: string = '';
  version: number = 0;
  changedAt: number = 0;
}

/**
 * 冲突项
 */
export class SyncConflictItem {
  entityType: string = '';
  entityId: string = '';
  localData: string = '';
  remoteData: string = '';
  localVersion: number = 0;
  remoteVersion: number = 0;
}

/**
 * 云存储提供者配置
 */
export class CloudStorageProviderConfigUpdate {
  baseUrl: string | undefined = undefined;
  apiVersion: string | undefined = undefined;
  timeout: number | undefined = undefined;
}

export class CloudStorageProviderConfig {
  /** API基础URL */
  baseUrl: string = '';
  /** API版本路径 */
  apiVersion: string = '';
  /** 请求超时（ms） */
  timeout: number = 0;
}

export class CloudStorageProvider {
  private config: CloudStorageProviderConfig;

  constructor(config: CloudStorageProviderConfig) {
    this.config = config;
  }

  /**
   * 更新配置
   */
  updateConfig(config: CloudStorageProviderConfigUpdate): void {
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
  async authenticate(uid: string, deviceId: string): Promise<CloudOperationResult<AuthResult>> {
    return this.request<AuthResult>('POST', '/auth/login', JSON.stringify({
      uid: uid,
      deviceId: deviceId,
      timestamp: Date.now()
    }));
  }

  /**
   * 注册设备
   */
  async registerDevice(uid: string, deviceId: string, deviceName: string):
    Promise<CloudOperationResult<DeviceRegisterResult>> {
    return this.request<DeviceRegisterResult>('POST', '/devices/register', JSON.stringify({
      uid: uid,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: 'HarmonyOS'
    }));
  }

  /**
   * 上传变更批次（推送本地变更到云端）
   */
  async uploadBatch(token: string, batch: SyncBatchRequest):
    Promise<CloudOperationResult<SyncBatchResponse>> {
    return this.request<SyncBatchResponse>('POST', '/sync/upload', JSON.stringify(batch), token);
  }

  /**
   * 拉取远程变更（从云端获取变更）
   */
  async fetchChanges(token: string, deviceId: string, lastSyncAt: number):
    Promise<CloudOperationResult<SyncBatchResponse>> {
    return this.request<SyncBatchResponse>('GET',
      `/sync/changes?deviceId=${deviceId}&lastSyncAt=${lastSyncAt}`, '', token);
  }

  /**
   * 确认同步（标记云端变更为已处理）
   */
  async confirmSync(token: string, syncedIds: string[]): Promise<CloudOperationResult<void>> {
    return this.request<void>('POST', '/sync/confirm', JSON.stringify({
      syncedIds: syncedIds
    }), token);
  }

  /**
   * 报告冲突解决结果
   */
  async resolveConflict(token: string, entityType: string, entityId: string,
    resolution: string, resolvedData: string): Promise<CloudOperationResult<void>> {
    return this.request<void>('POST', '/sync/resolve-conflict', JSON.stringify({
      entityType: entityType,
      entityId: entityId,
      resolution: resolution,
      resolvedData: resolvedData
    }), token);
  }

  /**
   * 获取用户关联的设备列表
   */
  async getDevices(token: string): Promise<CloudOperationResult<CloudDeviceInfo[]>> {
    return this.request<CloudDeviceInfo[]>('GET', '/devices', '', token);
  }

  /**
   * 获取同步统计信息
   */
  async getSyncStats(token: string): Promise<CloudOperationResult<SyncStatsResult>> {
    return this.request<SyncStatsResult>('GET', '/sync/stats', '', token);
  }

  // ========== 内部HTTP请求封装 ==========

  private async request<T>(
    method: string, path: string,
    bodyStr: string, token?: string
  ): Promise<CloudOperationResult<T>> {
    const url = `${this.config.baseUrl}${this.config.apiVersion}${path}`;

    try {
      const header: Map<string, string> = new Map([
        ['Content-Type', 'application/json']
      ]);
      if (token !== undefined && token.length > 0) {
        header.set('Authorization', `Bearer ${token}`);
      }

      const resp = await SecureHttpHelper.request(
        url,
        method === 'GET' ? http.RequestMethod.GET : http.RequestMethod.POST,
        header,
        bodyStr,
        this.config.timeout
      );

      if (resp.responseCode >= 200 && resp.responseCode < 300 && resp.data !== null) {
        const r = new CloudOperationResult<T>();
        r.success = true;
        r.data = resp.data as T;
        r.errorMessage = '';
        r.statusCode = resp.responseCode;
        return r;
      }

      const r2 = new CloudOperationResult<T>();
      r2.success = false;
      r2.data = null;
      r2.errorMessage = `HTTP ${resp.responseCode}`;
      r2.statusCode = resp.responseCode;
      return r2;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN_ZERO, TAG, 'Request failed: %{public}s', JSON.stringify(err));
      const r3 = new CloudOperationResult<T>();
      r3.success = false;
      r3.data = null;
      r3.errorMessage = err.message || '网络请求失败';
      r3.statusCode = 0;
      return r3;
    }
  }
}