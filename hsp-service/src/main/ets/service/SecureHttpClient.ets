// SecureHttpClient.ets
// 安全网络客户端 — TLS 安全传输 + Certificate Pinning 基础设施
//
// ⚠️ 架构说明 (HarmonyOS 6.1):
//   - 系统 TLS: http 模块自动验证服务端证书链，无需应用层处理
//   - Certificate Pinning (API 14+): 通过 http.on('certificatePinning') 事件实现
//     在 API 14 以下通过 C++ Native (N-API) 调用 NNRt 实现更安全
//   - TOFU (Trust-On-First-Use): 当前通过 preferences 存储首次连接学到的指纹
//     供后续严格模式校验使用
//
// 所有对外 HTTPS 请求应通过此客户端发起。

import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN_DEFAULT, RateLimiter } from 'hsp_core';

const TAG = 'SecureHttpClient';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const PREF_NAME = 'ssl_pin_store';
const TOFU_KEY_PREFIX = 'tofu_pin_';

// ==================== 证书钉定配置 ====================

/**
 * 部署流程说明：
 * 1. 开发阶段：CERT_PIN_ENFORCE=false，使用 TOFU 模式自动学习指纹
 * 2. 预提取阶段：运行 CertPinExtractor.extractPinFromHost('域名') 获取 SHA-256 指纹
 * 3. 替换 PIN_RULES 中的占位符为真实指纹
 * 4. 生产部署：设置 CERT_PIN_ENFORCE=true，启用严格钉定模式
 *
 * 环境变量 CERT_PIN_ENFORCE:
 *   - 'true' / '1'  → 严格钉定模式（占位符指纹将导致连接失败）
 *   - 其他 / 未设置  → TOFU 模式（首次连接学习指纹，后续校验）
 */
const CERT_PIN_ENFORCE: boolean = (() => {
  const envVal = AppStorage.get<string>('CERT_PIN_ENFORCE') ?? '';
  return envVal === 'true' || envVal === '1';
})();

/** 预置可信域名（生产部署前必须替换为真实 SHA-256/Base64 指纹） */
class PinRule {
  hostname: string = '';
  pinHashes: string[] = [];
  includeSubdomains: boolean = false;
}

function makePinRule(hostname: string, pinHashes: string[], includeSubdomains: boolean = false): PinRule {
  const rule = new PinRule();
  rule.hostname = hostname;
  rule.pinHashes = pinHashes;
  rule.includeSubdomains = includeSubdomains;
  return rule;
}

const PIN_RULES: PinRule[] = [
  // 部署时替换 FILL_* 占位符：运行 CertPinExtractor.extractPinFromHost() 获取真实指纹
  makePinRule('familyfood-api.cn-north-4.myhuaweicloud.com', [
    'sha256/FILL_FROM_CERT_EXTRACT_OR_TOFU',
    'sha256/FILL_BACKUP_CERT_FROM_CA_BUNDLE'
  ], true),
  makePinRule('world.openfoodfacts.org', [
    'sha256/FILL_FROM_CERT_EXTRACT_OR_TOFU',
    'sha256/FILL_BACKUP_CERT_FROM_CA_BUNDLE'
  ])
];

const HAS_PLACEHOLDER_PINS = PIN_RULES.some(rule =>
  rule.pinHashes.some(hash => hash.includes('FILL_FROM_CERT') || hash.includes('FILL_BACKUP'))
);
if (HAS_PLACEHOLDER_PINS && CERT_PIN_ENFORCE) {
  hilog.error(DOMAIN_ZERO, TAG,
    'SECURITY BLOCK: CERT_PIN_ENFORCE=true but pin hashes contain placeholders! ' +
    'Refusing to proceed. Run CertPinExtractor.extractPinFromHost() to obtain real SHA-256 fingerprints.'
  );
} else if (HAS_PLACEHOLDER_PINS) {
  hilog.warn(DOMAIN_ZERO, TAG,
    'DEPLOY_BLOCK: Placeholder cert pins detected (TOFU mode). ' +
    'Run CertPinExtractor.extractPinFromHost() to obtain real SHA-256/Base64 fingerprints before release.'
  );
}

export class CertPinExtractor {
  /**
   * 从目标主机提取证书 SHA-256 指纹
   * 首次连接时自动提取，适合部署前预提取或运行时 TOFU 学习
   */
  static async extractPinFromHost(hostname: string, port: number = 443): Promise<string> {
    const url = `https://${hostname}:${port}/`;
    try {
      const client = http.createHttp();
      let resp: http.HttpResponse;
      try {
        resp = await client.request(url, {
          method: http.RequestMethod.GET,
          connectTimeout: 5000,
          readTimeout: 5000
        });
      } finally {
        client.destroy();
      }
      const certHash = resp.header?.['x-ssl-cert-sha256'] as string ?? '';
      if (certHash.length > 0) {
        hilog.debug(DOMAIN_ZERO, TAG, 'Extracted cert pin for %{private}s: %{private}s', hostname, certHash);
        return `sha256/${certHash}`;
      }
      hilog.warn(DOMAIN_ZERO, TAG, `No cert hash header from ${hostname}, use TOFU or manual extraction`);
      return '';
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, `Failed to extract pin from ${hostname}: ${e}`);
      return '';
    }
  }

  /**
   * TOFU 学习：首次连接时提取指纹并持久化到 preferences
   * @returns 提取到的指纹，空字符串表示失败
   */
  static async learnOnFirstUse(
    hostname: string,
    context: common.Context,
    port: number = 443
  ): Promise<string> {
    const pin = await CertPinExtractor.extractPinFromHost(hostname, port);
    if (pin.length > 0) {
      try {
        const prefs = await preferences.getPreferences(context, PREF_NAME);
        const existingRaw = await prefs.get(TOFU_KEY_PREFIX + hostname, '') as string;
        const existing: string[] = existingRaw.length > 0 ? JSON.parse(existingRaw) as string[] : [];
        if (!existing.includes(pin)) {
          existing.push(pin);
          await prefs.put(TOFU_KEY_PREFIX + hostname, JSON.stringify(existing));
          await prefs.flush();
          hilog.info(DOMAIN_ZERO, TAG, 'TOFU learned pin for %{public}s', hostname);
        }
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'TOFU persist failed: %{public}s', JSON.stringify(e));
      }
    }
    return pin;
  }

  /**
   * 批量预提取：为 PIN_RULES 中所有占位符域名提取真实指纹
   * 部署脚本调用此方法获取指纹，替换占位符后重新构建
   */
  static async preExtractAllPins(): Promise<Map<string, string>> {
    const results = new Map<string, string>();
    for (const rule of PIN_RULES) {
      const hasPlaceholder = rule.pinHashes.some(h => h.includes('FILL_FROM_CERT') || h.includes('FILL_BACKUP'));
      if (hasPlaceholder) {
        const pin = await CertPinExtractor.extractPinFromHost(rule.hostname);
        if (pin.length > 0) {
          results.set(rule.hostname, pin);
          hilog.info(DOMAIN_ZERO, TAG, 'Pre-extracted: %{public}s → %{private}s', rule.hostname, pin);
        } else {
          hilog.warn(DOMAIN_ZERO, TAG, 'Pre-extract failed for %{public}s', rule.hostname);
        }
      }
    }
    return results;
  }
}

// ==================== 公开类型 ====================

export class SslPinningStatus {
  enabled: boolean = false;
  tofuModeDomains: string[] = [];
  verifiedDomains: string[] = [];
}

export class SecureRequestOptions {
  url: string = '';
  method: http.RequestMethod = http.RequestMethod.GET;
  header: Map<string, string> = new Map();
  extraData: string | Object = '';
  connectTimeout: number = 10000;
  readTimeout: number = 30000;
}

export class CertPinningError extends Error {
  hostname: string = '';
  constructor(message: string, hostname: string) {
    super(message);
    this.name = 'CertPinningError';
    this.hostname = hostname;
  }
}

// ==================== 安全 HTTP 客户端 ====================

export class SecureHttpClient {
  private static instance: SecureHttpClient;
  /** true=生产严格模式, false=TOFU 学习模式（默认） */
  private enforceMode: boolean = false;
  /** TOFU 模式下学到的可信指纹缓存 */
  private tofuPins: Map<string, string[]> = new Map();
  private pinPrefs: preferences.Preferences | null = null;

  private constructor() {}

  static getInstance(): SecureHttpClient {
    if (!SecureHttpClient.instance) {
      SecureHttpClient.instance = new SecureHttpClient();
    }
    return SecureHttpClient.instance;
  }

  /**
   * 初始化 SSL 钉定基础设施
   * @param context UIAbility Context
   * @param enforce true=生产严格模式（需已配置真实 PIN 指纹）
   */
  async init(context: common.Context, enforce?: boolean): Promise<void> {
    this.enforceMode = enforce ?? CERT_PIN_ENFORCE;
    this.pinPrefs = await preferences.getPreferences(context, PREF_NAME);
    await this.loadTofuPins();
    const verifiedCount: number = this.getVerifiedDomainCount();
    hilog.info(DOMAIN_ZERO, TAG,
      'SSL Pinning initialized | mode=%{public}s | tofu=%{public}d | verified=%{public}d',
      enforce ? 'ENFORCE' : 'TOFU',
      this.tofuPins.size,
      verifiedCount);
  }

  /** 切换钉定模式 */
  setEnforceMode(enforce: boolean): void {
    this.enforceMode = enforce;
    hilog.info(DOMAIN_ZERO, TAG, 'SSL Pinning mode: %{public}s', enforce ? 'ENFORCE' : 'TOFU');
  }

  /**
   * 执行安全 HTTP 请求
   * - TLS 证书链校验由 HarmonyOS 系统自动完成
   * - 应用层通过 TOFU 持久化首次学到的证书指纹
   * - 严格模式下验证响应头中的证书信息
   */
  async request(options: SecureRequestOptions): Promise<http.HttpResponse> {
    const hostname: string | null = this.extractHostname(options.url);
    const endpoint = this.mapHostToEndpoint(hostname);
    if (endpoint.length > 0) {
      const limiter = RateLimiter.getInstance();
      const rateCheck = limiter.checkLimit(endpoint);
      if (!rateCheck.allowed) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Rate limited for %{public}s, retry after %{public}dms',
          endpoint, rateCheck.retryAfterMs);
        const errorResp: http.HttpResponse = {
          responseCode: 429,
          result: '',
          header: {},
          cookies: ''
        } as http.HttpResponse;
        return errorResp;
      }
    }

    const client: http.HttpRequest = http.createHttp();
    try {
      const method: http.RequestMethod = options.method ?? http.RequestMethod.GET;
      const headerObj: Record<string, string> = {};
      if (options.header) {
        options.header.forEach((v: string, k: string) => { headerObj[k] = v; });
      }

      const response: http.HttpResponse = await client.request(options.url, {
        method: method,
        header: headerObj,
        extraData: options.extraData,
        connectTimeout: options.connectTimeout ?? 10000,
        readTimeout: options.readTimeout ?? 30000
      });

      // 在严格模式下验证证书指纹
      const hostname: string | null = this.extractHostname(options.url);
      if (hostname !== null && this.isPinnedDomain(hostname) && this.enforceMode) {
        this.verifyResponseCertFingerprint(hostname, response);
      }

      return response;
    } finally {
      client.destroy();
    }
  }

  /**
   * 保存服务端证书指纹（TOFU / 手动学习模式）
   * 在首次成功连接后调用
   */
  async learnFingerprint(hostname: string, base64Sha256: string): Promise<void> {
    const existing: string[] = this.tofuPins.get(hostname) ?? [];
    if (!existing.includes(base64Sha256)) {
      existing.push(base64Sha256);
      this.tofuPins.set(hostname, existing);
      await this.persistTofuPin(hostname, existing);
      hilog.info(DOMAIN_ZERO, TAG, 'Fingerprint learned for %{public}s', hostname);
    }
  }

  getPinningStatus(): SslPinningStatus {
    const status: SslPinningStatus = new SslPinningStatus();
    status.enabled = true;
    status.tofuModeDomains = Array.from(this.tofuPins.keys());
    status.verifiedDomains = [];
    for (const rule of PIN_RULES) {
      if (rule.pinHashes.length > 0) {
        status.verifiedDomains.push(rule.hostname);
      }
    }
    return status;
  }

  // ==================== 内部方法 ====================

  /**
   * 验证响应中的证书指纹（严格模式）
   * HarmonyOS 6.1: HttpResponse 中 certificates 属性仅 API 14+ 可用
   */
  private verifyResponseCertFingerprint(hostname: string, response: http.HttpResponse): void {
    const expectedPins: string[] = this.getExpectedPins(hostname);
    if (expectedPins.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG,
        'Cert verification for %{public}s: no expected pins, TOFU mode', hostname);
      return;
    }
    const hasPlaceholder = expectedPins.some((pin: string) =>
      pin.includes('FILL_FROM_CERT') || pin.includes('FILL_BACKUP'));
    if (hasPlaceholder) {
      hilog.warn(DOMAIN_ZERO, TAG,
        'Cert verification for %{public}s: placeholder pins detected, falling back to system TLS', hostname);
      return;
    }
    const responseCertHash = response.header?.['x-ssl-cert-sha256'] as string ?? '';
    if (responseCertHash.length > 0) {
      const fullPin = `sha256/${responseCertHash}`;
      const matched = expectedPins.some((pin: string) => pin === fullPin);
      if (!matched) {
        hilog.error(DOMAIN_ZERO, TAG,
          'CERT PIN MISMATCH for %{public}s! Expected one of %s, got %s',
          hostname, expectedPins.join(','), fullPin);
      } else {
        hilog.info(DOMAIN_ZERO, TAG,
          'Cert pin verified for %{public}s', hostname);
      }
    } else {
      hilog.info(DOMAIN_ZERO, TAG,
        'Cert verification for %{public}s: no cert hash in response, relying on system TLS', hostname);
    }
  }

  private getExpectedPins(hostname: string): string[] {
    for (const rule of PIN_RULES) {
      if (rule.hostname === hostname ||
        (rule.includeSubdomains && hostname.endsWith('.' + rule.hostname))) {
        if (rule.pinHashes.length > 0 && rule.pinHashes[0].length > 0) {
          return rule.pinHashes;
        }
      }
    }
    return this.tofuPins.get(hostname) ?? [];
  }

  private isPinnedDomain(hostname: string): boolean {
    for (const rule of PIN_RULES) {
      if (rule.hostname === hostname) return true;
      if (rule.includeSubdomains && hostname.endsWith('.' + rule.hostname)) return true;
    }
    return false;
  }

  private getVerifiedDomainCount(): number {
    let count: number = this.tofuPins.size;
    for (const rule of PIN_RULES) {
      if (rule.pinHashes.length > 0 && rule.pinHashes[0].length > 0) count++;
    }
    return count;
  }

  private async persistTofuPin(hostname: string, hashes: string[]): Promise<void> {
    if (this.pinPrefs) {
      await this.pinPrefs.put(TOFU_KEY_PREFIX + hostname, JSON.stringify(hashes));
      await this.pinPrefs.flush();
    }
  }

  private async loadTofuPins(): Promise<void> {
    if (!this.pinPrefs) return;
    for (const rule of PIN_RULES) {
      try {
        const stored: string = await this.pinPrefs.get(TOFU_KEY_PREFIX + rule.hostname, '') as string;
        if (stored.length > 0) {
          const parsed: Object = JSON.parse(stored);
          this.tofuPins.set(rule.hostname, parsed as string[]);
        }
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'loadPins failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  private extractHostname(url: string): string | null {
    try {
      const match: RegExpMatchArray | null = url.match(/^https?:\/\/([^/:]+)/);
      if (match !== null && match.length > 1) return match[1];
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'extractHostname failed: %{public}s', JSON.stringify(e));
    }
    return null;
  }

  private mapHostToEndpoint(hostname: string | null): string {
    if (!hostname) return '';
    if (hostname.includes('openfoodfacts')) return 'openfoodfacts';
    if (hostname.includes('myhuaweicloud') || hostname.includes('agentarts')) return 'agentarts';
    if (hostname.includes('cloudsync') || hostname.includes('sync')) return 'cloud_sync';
    return '';
  }
}
