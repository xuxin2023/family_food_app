// NetworkMonitorService.ets
// 网络状态监听服务 - 使用 @kit.NetworkKit connection 实现
// 支持初始化时与运行时通知两种方式获取网络状态

import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NetworkMonitorService';
const DOMAIN_ZERO = 0;

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
export interface NetworkState {
  /** 是否有可用网络 */
  isConnected: boolean;
  /** 是否已验证（可访问互联网） */
  isValidated: boolean;
  /** 网络类型 */
  netType: NetType;
  /** 网络ID */
  netId: number;
}

/**
 * 网络状态变化回调
 */
export type NetworkStateChangeCallback = (state: NetworkState) => void;

export class NetworkMonitorService {
  private netConnection: connection.NetConnection | null = null;
  private isRegistered: boolean = false;
  private currentState: NetworkState = {
    isConnected: false,
    isValidated: false,
    netType: NetType.NONE,
    netId: -1
  };
  private callbacks: NetworkStateChangeCallback[] = [];

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
      this.netConnection.unregister((err: BusinessError) => {
        if (err) {
          hilog.warn(DOMAIN_ZERO, TAG, 'Unregister net conn failed: %{public}s',
            JSON.stringify(err));
        }
      });
      this.netConnection = null;
      this.isRegistered = false;
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
  refreshState(): NetworkState {
    try {
      const netHandle = connection.getDefaultNetSync();
      if (!netHandle || netHandle.netId < 100) {
        this.updateState({
          isConnected: false,
          isValidated: false,
          netType: NetType.NONE,
          netId: -1
        });
        return this.currentState;
      }

      const capabilities = connection.getNetCapabilitiesSync(netHandle);
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

      this.updateState({
        isConnected: true,
        isValidated: validated,
        netType: netType,
        netId: netHandle.netId
      });
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Refresh state failed: %{public}s',
        JSON.stringify(error));
      this.updateState({
        isConnected: false,
        isValidated: false,
        netType: NetType.NONE,
        netId: -1
      });
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
    }
  }
}
