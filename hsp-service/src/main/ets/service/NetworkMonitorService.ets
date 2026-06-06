// NetworkMonitorService.ets
// 网络状态监听服务 - 使用 @kit.NetworkKit connection 实现
// 支持初始化时与运行时通知两种方式获取网络状态

import { HILOG_DOMAIN_DEFAULT, AppStorageSync } from 'hsp_core';
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NetworkMonitorService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

/**
 * 网络类型枚举
 */
export enum NetType {
  /** 无网络 */
  NONE = 'none',
  /** WiFi */
  WIFI = 'wifi',
  /** 蜂窝网络 */
  CELLULAR = 'cellular',
  /** 以太网 */
  ETHERNET = 'ethernet',
  /** VPN */
  VPN = 'vpn',
  /** 其他 */
  OTHER = 'other'
}

/**
 * 网络状态
 */
export class NetworkState {
  /** 是否有可用网络 */
  isConnected: boolean = false;
  /** 是否已验证（可访问互联网） */
  isValidated: boolean = false;
  /** 网络类型 */
  netType: NetType = NetType.NONE;
  /** 网络ID */
  netId: number = -1;
}

/**
 * 网络状态变化回调
 */
export type NetworkStateChangeCallback = (state: NetworkState) => void;

let networkMonitorServiceInstance: NetworkMonitorService | null = null;

export class NetworkMonitorService {
  private netConnection: connection.NetConnection | null = null;
  private isRegistered: boolean = false;
  private currentState: NetworkState = new NetworkState();
  private callbacks: NetworkStateChangeCallback[] = [];
  onNetworkChange: ((isOnline: boolean) => void) | null = null;

  static getInstance(): NetworkMonitorService {
    if (networkMonitorServiceInstance === null) {
      networkMonitorServiceInstance = new NetworkMonitorService();
    }
    return networkMonitorServiceInstance;
  }

  get isOnline(): boolean {
    return this.currentState.isConnected;
  }

  get connectionType(): string {
    return this.currentState.netType;
  }

  /**
   * 获取当前网络状态快照（同步方式）
   */
  getCurrentState(): NetworkState {
    return this.currentState;
  }

  /**
   * 检查是否已连接网络
   */
  isConnected(): boolean {
    return this.currentState.isConnected;
  }

  /**
   * 检查网络是否已验证（可访问互联网）
   */
  isValidated(): boolean {
    return this.currentState.isValidated;
  }

  /**
   * 检查是否为WiFi网络
   */
  isWifi(): boolean {
    return this.currentState.netType === NetType.WIFI;
  }

  /**
   * 注册网络监听
   */
  register(): void {
    if (this.isRegistered) return;

    try {
      this.netConnection = connection.createNetConnection();
      this.setupListeners();
      this.netConnection.register((err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN_ZERO, TAG, 'NetConnection register failed: %{public}s',
            JSON.stringify(err));
          return;
        }
        this.isRegistered = true;
        hilog.info(DOMAIN_ZERO, TAG, 'NetConnection registered');
        // 注册成功后立即刷新状态
        this.refreshState();
      });
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Register net conn failed: %{public}s',
        JSON.stringify(error));
    }
  }

  /**
   * 取消注册网络监听
   */
  unregister(): void {
    if (!this.isRegistered || !this.netConnection) return;
    try {
      this.netConnection.off('netAvailable');
      this.netConnection.off('netUnavailable');
      this.netConnection.off('netCapabilitiesChange');
      this.netConnection.off('netLost');
      this.netConnection.unregister((err: BusinessError) => {
        if (err) {
          hilog.warn(DOMAIN_ZERO, TAG, 'Unregister net conn failed: %{public}s',
            JSON.stringify(err));
        }
      });
      this.netConnection = null;
      this.isRegistered = false;
      this.callbacks = [];
      hilog.info(DOMAIN_ZERO, TAG, 'NetConnection unregistered');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Unregister net conn error: %{public}s',
        JSON.stringify(error));
    }
  }

  /**
   * 添加网络状态变化监听
   */
  onStateChange(callback: NetworkStateChangeCallback): void {
    this.callbacks.push(callback);
    // 添加后立即使用当前状态通知
    callback(this.currentState);
  }

  /**
   * 移除网络状态变化监听
   */
  offStateChange(callback: NetworkStateChangeCallback): void {
    const index = this.callbacks.indexOf(callback);
    if (index >= 0) {
      this.callbacks.splice(index, 1);
    }
  }

  /**
   * 手动刷新网络状态（同步查询）
   */
  async refreshState(): Promise<NetworkState> {
    try {
      const netHandle = await connection.getDefaultNet();
      if (!netHandle || netHandle.netId < 100) {
        const s: NetworkState = new NetworkState(
        s.isConnected = false;
        s.isValidated = false;
        s.netType = NetType.NONE;
        s.netId = -1;
        this.updateState(s);
        return this.currentState;
      }

      const capabilities = await connection.getNetCapabilities(netHandle);
      const bearerTypes = capabilities.bearerTypes;
      const networkCap = capabilities.networkCap;

      // 判断是否已验证（可访问互联网）
      let validated = false;
      if (networkCap) {
        for (let i = 0; i < networkCap.length; i++) {
          if (networkCap[i] === connection.NetCap.NET_CAPABILITY_VALIDATED) {
            validated = true;
            break;
          }
        }
      }

      // 判断网络类型
      let netType = NetType.OTHER;
      if (bearerTypes && bearerTypes.length > 0) {
        const type = bearerTypes[0];
        if (type === connection.NetBearType.BEARER_WIFI) {
          netType = NetType.WIFI;
        } else if (type === connection.NetBearType.BEARER_CELLULAR) {
          netType = NetType.CELLULAR;
        } else if (type === connection.NetBearType.BEARER_ETHERNET) {
          netType = NetType.ETHERNET;
        } else if (type === connection.NetBearType.BEARER_VPN) {
          netType = NetType.VPN;
        }
      }

      const s2: NetworkState = new NetworkState(
      s2.isConnected = true;
      s2.isValidated = validated;
      s2.netType = netType;
      s2.netId = netHandle.netId;
      this.updateState(s2);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Refresh state failed: %{public}s',
        JSON.stringify(error));
      const s3: NetworkState = new NetworkState(
      s3.isConnected = false;
      s3.isValidated = false;
      s3.netType = NetType.NONE;
      s3.netId = -1;
      this.updateState(s3);
    }
    return this.currentState;
  }

  /**
   * 检查是否适合进行同步（基于网络条件）
   * @param allowWifiOnly 是否仅WiFi允许
   */
  isSyncAllowed(allowWifiOnly: boolean): boolean {
    if (!this.currentState.isConnected || !this.currentState.isValidated) {
      return false;
    }
    if (allowWifiOnly && this.currentState.netType !== NetType.WIFI) {
      return false;
    }
    return true;
  }

  private setupListeners(): void {
    if (!this.netConnection) return;

    this.netConnection.on('netAvailable', () => {
      hilog.info(DOMAIN_ZERO, TAG, 'netAvailable event');
      this.refreshState();
    });

    this.netConnection.on('netUnavailable', () => {
      hilog.info(DOMAIN_ZERO, TAG, 'netUnavailable event');
      this.refreshState();
    });

    this.netConnection.on('netCapabilitiesChange', () => {
      hilog.info(DOMAIN_ZERO, TAG, 'netCapabilitiesChange event');
      this.refreshState();
    });

    this.netConnection.on('netLost', () => {
      hilog.info(DOMAIN_ZERO, TAG, 'netLost event');
      this.refreshState();
    });
  }

  private updateState(newState: NetworkState): void {
    const oldConnected = this.currentState.isConnected;
    this.currentState = newState;

    // 同步到 AppStorage 供全局访问
    AppStorageSync.syncNetworkState(newState.isConnected);
    AppStorage.setOrCreate('networkConnectionType', newState.netType);

    // 状态变化时通知所有监听者
    if (oldConnected !== newState.isConnected ||
        this.currentState.netType !== newState.netType) {
      for (const cb of this.callbacks) {
        try {
          cb(newState);
        } catch (error) {
          hilog.error(DOMAIN_ZERO, TAG, 'Callback error: %{public}s',
            JSON.stringify(error));
        }
      }
      if (this.onNetworkChange !== null) {
        try {
          this.onNetworkChange(newState.isConnected);
        } catch (error) {
          hilog.error(DOMAIN_ZERO, TAG, 'onNetworkChange error: %{public}s',
            JSON.stringify(error));
        }
      }
    }
  }
}