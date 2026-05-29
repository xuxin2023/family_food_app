// PermissionManager.ets
// 统一权限管理服务 - 管理敏感权限的延迟请求和安全降级
// 敏感权限不在启动时申请，而是在用户实际使用相关功能时按需请求

import { common, abilityAccessCtrl, Permissions, bundleManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'PermissionManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

/**
 * 权限状态枚举
 */
export enum PermissionStatus {
  /** 未请求 */
  NOT_REQUESTED = 'not_requested',
  /** 已授权 */
  GRANTED = 'granted',
  /** 已拒绝 */
  DENIED = 'denied'
}

/**
 * 敏感权限清单
 */
class SensitivePermissionItem {
  readonly key: string;
  readonly value: Permissions;

  constructor(key: string, value: Permissions) {
    this.key = key;
    this.value = value;
  }
}

/**
 * 敏感权限清单
 */
export class SENSITIVE_PERMISSIONS {
  static readonly DISTRIBUTED_DATASYNC: Permissions = 'ohos.permission.DISTRIBUTED_DATASYNC';
  static readonly ACTIVITY_MOTION: Permissions = 'ohos.permission.ACTIVITY_MOTION';
  static readonly CAMERA: Permissions = 'ohos.permission.CAMERA';
  static readonly MICROPHONE: Permissions = 'ohos.permission.MICROPHONE';
  static readonly READ_MEDIA: Permissions = 'ohos.permission.READ_MEDIA';
  static readonly READ_HEALTH_DATA: Permissions = 'ohos.permission.READ_HEALTH_DATA';
}

export class PermissionManager {
  private static instance: PermissionManager;
  private context: common.Context | null = null;
  private permissionCache: Map<string, PermissionStatus> = new Map();
  private privacyAgreed: boolean = false;

  private constructor() {}

  static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager();
    }
    return PermissionManager.instance;
  }

  /**
   * 初始化权限管理器
   * 注意：此方法不请求任何权限，仅初始化上下文
   */
  init(context: common.Context): void {
    this.context = context;
    hilog.info(DOMAIN_ZERO, TAG, 'PermissionManager initialized');
  }

  /**
   * 设置用户已同意隐私政策
   */
  setPrivacyAgreed(): void {
    this.privacyAgreed = true;
  }

  /**
   * 检查用户是否已同意隐私政策
   */
  isPrivacyAgreed(): boolean {
    return this.privacyAgreed;
  }

  /**
   * 检查单个权限状态
   */
  /**
   * 获取应用的 accessTokenId
   */
  private async getAccessTokenId(): Promise<number> {
    try {
      const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleFlags);
      return bundleInfo.appInfo.accessTokenId;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getAccessTokenId failed: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  async checkPermission(permission: Permissions): Promise<PermissionStatus> {
    if (!this.context) return PermissionStatus.DENIED;

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenId = await this.getAccessTokenId();
      if (tokenId === 0) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Invalid tokenId, permission check may fail');
        return PermissionStatus.DENIED;
      }
      const result = await atManager.checkAccessToken(tokenId, permission);
      const status = result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        ? PermissionStatus.GRANTED
        : PermissionStatus.DENIED;
      this.permissionCache.set(permission, status);
      return status;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'checkPermission failed: %{public}s', JSON.stringify(error));
      return PermissionStatus.DENIED;
    }
  }

  /**
   * 请求单个权限（带用户友好提示）
   */
  async requestPermission(
    permission: Permissions,
    rationale?: string
  ): Promise<boolean> {
    if (!this.context) return false;

    // 先检查是否已授权
    const status = await this.checkPermission(permission);
    if (status === PermissionStatus.GRANTED) {
      return true;
    }

    // 请求权限
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(
        this.context,
        [permission]
      );
      const granted = result.authResults[0] === 0;
      this.permissionCache.set(permission,
        granted ? PermissionStatus.GRANTED : PermissionStatus.DENIED
      );
      return granted;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'requestPermission failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 请求摄像头权限（扫码前调用）
   */
  async requestCameraPermission(): Promise<boolean> {
    return await this.requestPermission(
      SENSITIVE_PERMISSIONS.CAMERA,
      '需要摄像头权限来扫描食品条码和拍照识别食品信息'
    );
  }

  /**
   * 请求分布式数据同步权限（云同步前调用）
   */
  async requestDistributedSyncPermission(): Promise<boolean> {
    return await this.requestPermission(
      SENSITIVE_PERMISSIONS.DISTRIBUTED_DATASYNC,
      '需要分布式数据同步权限来实现多设备数据同步'
    );
  }

  /**
   * 请求活动运动权限（华为健康数据读取前调用）
   */
  async requestActivityMotionPermission(): Promise<boolean> {
    return await this.requestPermission(
      SENSITIVE_PERMISSIONS.ACTIVITY_MOTION,
      '需要活动运动权限来读取步数、睡眠等健康数据'
    );
  }

  async requestMicrophonePermission(): Promise<boolean> {
    return await this.requestPermission(
      SENSITIVE_PERMISSIONS.MICROPHONE,
      '需要麦克风权限来进行语音输入'
    );
  }

  async requestReadMediaPermission(): Promise<boolean> {
    return await this.requestPermission(
      SENSITIVE_PERMISSIONS.READ_MEDIA,
      '需要读取媒体权限来从相册选取食品图片'
    );
  }

  async requestReadHealthDataPermission(): Promise<boolean> {
    return await this.requestPermission(
      SENSITIVE_PERMISSIONS.READ_HEALTH_DATA,
      '需要读取健康数据权限来获取血压、血糖等健康指标'
    );
  }

  async requestWithFallback(
    permission: Permissions,
    rationale?: string
  ): Promise<boolean> {
    if (!this.context) return false;

    const status = await this.checkPermission(permission);
    if (status === PermissionStatus.GRANTED) {
      return true;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(
        this.context,
        [permission]
      );
      const granted = result.authResults[0] === 0;
      this.permissionCache.set(permission,
        granted ? PermissionStatus.GRANTED : PermissionStatus.DENIED
      );
      if (granted) {
        return true;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'Permission %{public}s denied by user, running in degraded mode', permission);
      return false;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'requestWithFallback failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 清除权限缓存（用户重置数据时调用）
   */
  clearCache(): void {
    this.permissionCache.clear();
  }
}