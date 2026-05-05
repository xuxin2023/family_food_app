// PermissionManager.ets
// 统一权限管理服务 - 管理敏感权限的延迟请求和安全降级
// 敏感权限不在启动时申请，而是在用户实际使用相关功能时按需请求

import { common, abilityAccessCtrl, Permissions, bundleManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'PermissionManager';
const DOMAIN_ZERO = 0;

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
export const SENSITIVE_PERMISSIONS = {
  /** 分布式数据同步 - 用于云同步功能 */
  DISTRIBUTED_DATASYNC: 'ohos.permission.DISTRIBUTED_DATASYNC' as Permissions,
  /** 活动运动数据 - 用于华为健康数据读取 */
  ACTIVITY_MOTION: 'ohos.permission.ACTIVITY_MOTION' as Permissions,
  /** 摄像头 - 用于扫码 */
  CAMERA: 'ohos.permission.CAMERA' as Permissions,
} as const;

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
  async checkPermission(permission: Permissions): Promise<PermissionStatus> {
    if (!this.context) return PermissionStatus.DENIED;

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.checkAccessToken(
        { tokenId: 0, permissionName: permission }
      );
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
   * @param permission 权限名
   * @param rationale 用户友好解释（当权限被拒绝时展示）
   * @returns 是否已授予
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

  /**
   * 清除权限缓存（用户重置数据时调用）
   */
  clearCache(): void {
    this.permissionCache.clear();
  }
}
