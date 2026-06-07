// hsp-core: 增强安全检测器
// 集成 DeviceSecurityKit 完整性检测 + VPN/代理/越狱环境检测
// HarmonyOS 6.1 合规要求

import { hilog } from '@kit.PerformanceAnalysisKit';
import { connection } from '@kit.NetworkKit';
import { deviceSecurity } from '@kit.DeviceSecurityKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';
import { CryptoEngine } from '../utils/CryptoEngine';

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

const CERT_PINS: string[] = [
  'sha256//RBFo0OoNMKB3QZbhM00qF7L1Z1JeGvJgkHOOnxwH0gQ=',
];

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

    const [proxyResult, vpnResult, integrityResult] = await Promise.allSettled([
      EnhancedSecurityDetector.checkProxy(),
      EnhancedSecurityDetector.checkVpn(),
      EnhancedSecurityDetector.checkDeviceIntegrity(),
    ]);

    if (proxyResult.status === 'fulfilled' && proxyResult.value) {
      result.hasProxy = true;
      result.isSafe = false;
      result.risks.push('检测到HTTP代理');
    }
    if (vpnResult.status === 'fulfilled' && vpnResult.value) {
      result.hasVpn = true;
      result.isSafe = false;
      result.risks.push('检测到VPN连接');
    }
    if (integrityResult.status === 'fulfilled' && !integrityResult.value) {
      result.deviceIntegrityOk = false;
      result.isSafe = false;
      result.risks.push('设备完整性校验异常');
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
      const netHandle = await connection.getDefaultNet();
      if (!netHandle) return false;
      const props = await connection.getProperties(netHandle);
      if (props) {
        const record = props as Record<string, Object>;
        const host = record.httpProxyHost as string | undefined;
        return host !== undefined && host !== null && host.length > 0;
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); /* ignore */ }
    return false;
  }

  static async checkVpn(): Promise<boolean> {
    try {
      const netHandle = await connection.getDefaultNet();
      if (!netHandle) return false;
      const capabilities = await connection.getNetCapabilities(netHandle);
      if (capabilities) {
        const bearerTypes = (capabilities as Record<string, Object>)['bearerTypes'] as number[] | undefined;
        return bearerTypes !== undefined && bearerTypes.includes(6); // BEARER_VPN = 6
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); /* ignore */ }
    return false;
  }

  static async checkDeviceIntegrity(): Promise<boolean> {
    try {
      const nonce = CryptoEngine.generateNonce(32);
      const result = await deviceSecurity.integrityCheck({ nonce });
      return result.advice === deviceSecurity.IntegrityAdvice.OK;
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      return true; // offline safe assumption
    }
  }

  static getWarningMessage(riskLevel: 'warning' | 'danger'): string {
    if (riskLevel === 'danger') {
      return '检测到严重安全风险：建议关闭代理/VPN后使用。数据已加密传输，但为了您的安全，推荐在安全网络环境中继续。';
    }
    return '检测到潜在安全风险。数据已加密传输，请知晓当前网络环境可能不是最优。';
  }
}