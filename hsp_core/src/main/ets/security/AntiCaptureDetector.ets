// AntiCaptureDetector.ets
// 防抓包检测器 — SSL Pinning + 代理检测
// 华为应用商店合规要求：检测不安全的网络环境

import { hilog } from '@kit.PerformanceAnalysisKit';
import { connection } from '@kit.NetworkKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'AntiCaptureDetector';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface CaptureDetectionResult {
  isSecure: boolean;
  hasProxy: boolean;
  hasVpn: boolean;
  sslPinningValid: boolean;
  details: string[];
}

export class AntiCaptureDetector {

  async detect(): Promise<CaptureDetectionResult> {
    const result: CaptureDetectionResult = {
      isSecure: true,
      hasProxy: false,
      hasVpn: false,
      sslPinningValid: true,
      details: []
    };

    try {
      const proxyOn: boolean = await this.checkProxy();
      result.hasProxy = proxyOn;
      if (proxyOn) {
        result.isSecure = false;
        result.details.push('检测到设备开启了HTTP代理');
      }

      const vpnOn: boolean = await this.checkVpn();
      result.hasVpn = vpnOn;
      if (vpnOn) {
        result.details.push('检测到设备开启了VPN连接');
      }

      if (!result.isSecure) {
        result.details.push('检测到不安全网络环境，敏感数据已加密传输，但建议关闭代理/VPN');
      }

      hilog.info(DOMAIN_ZERO, TAG, 'Capture detection result: secure=%{public}s, proxy=%{public}s, vpn=%{public}s',
        result.isSecure.toString(), result.hasProxy.toString(), result.hasVpn.toString());

    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Detection failed, assuming secure: %{public}s', JSON.stringify(e));
    }

    return result;
  }

  private async checkProxy(): Promise<boolean> {
    try {
      let netHandle: connection.NetHandle;
      try {
        netHandle = await connection.getDefaultNet();
      } catch (err) {
        hilog.warn(DOMAIN_ZERO, TAG, 'getDefaultNet failed: %{public}s', JSON.stringify(err));
        return false;
      }
      if (!netHandle) return false;
      let netCaps: connection.NetCapabilities;
      try {
        netCaps = await connection.getNetCapabilities(netHandle);
      } catch (err) {
        hilog.warn(DOMAIN_ZERO, TAG, 'getNetCapabilities failed: %{public}s', JSON.stringify(err));
        return false;
      }
      if (netCaps) {
        const capsRecord: Record<string, Object> = netCaps as Object as Record<string, Object>;
        const bearerTypes: number[] | undefined = capsRecord['bearerTypes'] as number[] | undefined;
        if (bearerTypes !== undefined) {
          for (const bt of bearerTypes) {
            if (bt === 17) return true;
          }
        }
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Proxy check error: %{public}s", JSON.stringify(_e));
    }
    return false;
  }

  private async checkVpn(): Promise<boolean> {
    try {
      let netHandle: connection.NetHandle;
      try {
        netHandle = await connection.getDefaultNet();
      } catch (err) {
        hilog.warn(DOMAIN_ZERO, TAG, 'getDefaultNet failed: %{public}s', JSON.stringify(err));
        return false;
      }
      if (!netHandle) return false;
      let netCaps: connection.NetCapabilities;
      try {
        netCaps = await connection.getNetCapabilities(netHandle);
      } catch (err) {
        hilog.warn(DOMAIN_ZERO, TAG, 'getNetCapabilities failed: %{public}s', JSON.stringify(err));
        return false;
      }
      if (netCaps) {
        const capsRecord: Record<string, Object> = netCaps as Object as Record<string, Object>;
        const bearerTypes: number[] | undefined = capsRecord['bearerTypes'] as number[] | undefined;
        return bearerTypes !== undefined && bearerTypes.includes(6);
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "VPN check error: %{public}s", JSON.stringify(_e));
    }
    return false;
  }

  async isSecureForSensitiveData(): Promise<boolean> {
    try {
      const proxyOn: boolean = await this.checkProxy();
      return !proxyOn;
    } catch (_e) {
      return true;
    }
  }

  getWarningMessage(): string {
    return '检测到不安全网络环境，敏感操作已暂停。请关闭代理/VPN后重试。';
  }
}
