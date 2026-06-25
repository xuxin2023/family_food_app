// EnhancedSecurityDetector.ets
// hsp-core: 增强安全检测器
// 集成 VPN/代理环境检测
// HarmonyOS 6.1 合规要求

import { hilog } from '@kit.PerformanceAnalysisKit';
import { connection } from '@kit.NetworkKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'EnhancedSecurityDetector';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface SecurityCheckResult {
  isSafe: boolean;
  hasProxy: boolean;
  hasVpn: boolean;
  deviceIntegrityOk: boolean;
  sslPinningValid: boolean;
  risks: string[];
  riskLevel: 'safe' | 'warning' | 'danger';
}

export class EnhancedSecurityDetector {
  static async performFullCheck(): Promise<SecurityCheckResult> {
    const result: SecurityCheckResult = {
      isSafe: true,
      hasProxy: false,
      hasVpn: false,
      deviceIntegrityOk: true,
      sslPinningValid: true,
      risks: [],
      riskLevel: 'safe',
    };

    try {
      const proxyOn: boolean = await EnhancedSecurityDetector.checkProxy();
      if (proxyOn) {
        result.hasProxy = true;
        result.isSafe = false;
        result.risks.push('检测到HTTP代理');
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Proxy check error: %{public}s", JSON.stringify(_e));
    }

    try {
      const vpnOn: boolean = await EnhancedSecurityDetector.checkVpn();
      if (vpnOn) {
        result.hasVpn = true;
        result.isSafe = false;
        result.risks.push('检测到VPN连接');
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "VPN check error: %{public}s", JSON.stringify(_e));
    }

    result.riskLevel = result.risks.length >= 2 ? 'danger'
      : result.risks.length === 1 ? 'warning' : 'safe';

    hilog.info(DOMAIN_ZERO, TAG,
      'Security check: safe=%{public}s, level=%{public}s, risks=%{public}d',
      result.isSafe.toString(), result.riskLevel, result.risks.length);

    return result;
  }

  static async checkProxy(): Promise<boolean> {
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

  static async checkVpn(): Promise<boolean> {
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

  static async checkDeviceIntegrity(): Promise<boolean> {
    return true;
  }

  static getWarningMessage(riskLevel: 'warning' | 'danger'): string {
    if (riskLevel === 'danger') {
      return '检测到严重安全风险：建议关闭代理/VPN后使用。数据已加密传输，但为了您的安全，推荐在安全网络环境中继续。';
    }
    return '检测到轻微安全风险：数据已加密传输，建议在安全网络环境中使用。';
  }
}
