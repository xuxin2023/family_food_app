// PrivacyManager.ets
// 隐私政策版本追踪管理 - 版本化同意机制
// 隐私政策更新后需重新同意，不同意则退出应用
// V2: 华为云OBS在线托管隐私政策/用户协议，支持远程版本检测

import { HILOG_DOMAIN_DEFAULT, safeBack, clearToHome, safePushUrl, API_CONFIG } from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { http } from '@kit.NetworkKit';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';

const TAG = 'PrivacyManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const DEFAULT_PRIVACY_OSS_BASE = 'https://familyfood-privacy.obs.cn-north-4.myhuaweicloud.com';
const PRIVACY_POLICY_PATH = '/privacy-policy-v{version}.html';
const USER_AGREEMENT_PATH = '/user-agreement-v{version}.html';
const VERSION_MANIFEST_PATH = '/manifest.json';
const REMOTE_VERSION_CACHE_TTL = 24 * 60 * 60 * 1000;

interface RemoteVersionManifest {
  latestVersion: string
  privacyPolicyUrl: string
  userAgreementUrl: string
  updatedAt: number
}

export class PrivacyDocumentUrls {
  privacyPolicyUrl: string = '';
  userAgreementUrl: string = '';
  version: string = '';
  isOnline: boolean = false;
}

export class PrivacyManager {
  private static readonly CURRENT_PRIVACY_VERSION: string = '2.0';
  private static readonly KEY_AGREED_VERSION: string = 'privacy_agreed_version';
  private static readonly KEY_AGREED_TIMESTAMP: string = 'privacy_agreed_timestamp';
  private static readonly PREFS_FILE: string = 'privacy_settings';
  private static readonly KEY_REMOTE_VERSION_CACHE: string = 'remote_version_cache';
  private static readonly KEY_REMOTE_VERSION_CACHE_TIME: string = 'remote_version_cache_time';

  private static cachedAgreed: boolean | null = null;
  private static remoteManifest: RemoteVersionManifest | null = null;
  private static remoteManifestFetchedAt: number = 0;

  static isPrivacyAgreed(): boolean {
    if (PrivacyManager.cachedAgreed !== null) {
      return PrivacyManager.cachedAgreed;
    }
    return false;
  }

  static async checkPrivacyAgreed(context: common.Context): Promise<boolean> {
    try {
      const pref = await preferences.getPreferences(context, PrivacyManager.PREFS_FILE);
      const agreedVersion = pref.getSync(PrivacyManager.KEY_AGREED_VERSION, '') as string;
      const agreed = agreedVersion === PrivacyManager.CURRENT_PRIVACY_VERSION;
      PrivacyManager.cachedAgreed = agreed;
      return agreed;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'checkPrivacyAgreed failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  static getAgreedVersion(): string {
    return PrivacyManager.CURRENT_PRIVACY_VERSION;
  }

  static async agreePrivacy(context: common.Context): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, PrivacyManager.PREFS_FILE);
      pref.putSync(PrivacyManager.KEY_AGREED_VERSION, PrivacyManager.CURRENT_PRIVACY_VERSION);
      pref.putSync(PrivacyManager.KEY_AGREED_TIMESTAMP, Date.now());
      await pref.flush();
      PrivacyManager.cachedAgreed = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Privacy agreed, version: %{public}s', PrivacyManager.CURRENT_PRIVACY_VERSION);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'agreePrivacy failed: %{public}s', JSON.stringify(e));
    }
  }

  static async needReConsent(context: common.Context): Promise<boolean> {
    try {
      const pref = await preferences.getPreferences(context, PrivacyManager.PREFS_FILE);
      const agreedVersion = pref.getSync(PrivacyManager.KEY_AGREED_VERSION, '') as string;
      if (agreedVersion.length === 0) {
        return true;
      }
      return agreedVersion !== PrivacyManager.CURRENT_PRIVACY_VERSION;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'needReConsent check failed: %{public}s', JSON.stringify(e));
      return true;
    }
  }

  static showPrivacyDialog(_context: common.Context): void {
    try {
      safePushUrl('pages/PrivacyDialogPage');
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'showPrivacyDialog failed: %{public}s', JSON.stringify(e));
    }
  }

  static getCurrentVersion(): string {
    return PrivacyManager.CURRENT_PRIVACY_VERSION;
  }

  static resetCache(): void {
    PrivacyManager.cachedAgreed = null;
  }

  static async getDocumentUrls(context: common.Context): Promise<PrivacyDocumentUrls> {
    const result = new PrivacyDocumentUrls();
    result.version = PrivacyManager.CURRENT_PRIVACY_VERSION;

    const manifest = await PrivacyManager.fetchRemoteManifest(context);
    if (manifest !== null) {
      result.privacyPolicyUrl = manifest.privacyPolicyUrl;
      result.userAgreementUrl = manifest.userAgreementUrl;
      result.version = manifest.latestVersion;
      result.isOnline = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Using online privacy docs v%{public}s', manifest.latestVersion);
      return result;
    }

    const ossBase = API_CONFIG.HUAWEI_CLOUD_BASE_URL.length > 0
      ? API_CONFIG.HUAWEI_CLOUD_BASE_URL
      : DEFAULT_PRIVACY_OSS_BASE;
    result.privacyPolicyUrl = ossBase + PRIVACY_POLICY_PATH.replace('{version}', PrivacyManager.CURRENT_PRIVACY_VERSION);
    result.userAgreementUrl = ossBase + USER_AGREEMENT_PATH.replace('{version}', PrivacyManager.CURRENT_PRIVACY_VERSION);
    result.isOnline = false;
    hilog.info(DOMAIN_ZERO, TAG, 'Using fallback privacy doc URLs');
    return result;
  }

  private static async fetchRemoteManifest(context: common.Context): Promise<RemoteVersionManifest | null> {
    const now = Date.now();
    if (PrivacyManager.remoteManifest !== null &&
        (now - PrivacyManager.remoteManifestFetchedAt) < REMOTE_VERSION_CACHE_TTL) {
      return PrivacyManager.remoteManifest;
    }

    try {
      const pref = await preferences.getPreferences(context, PrivacyManager.PREFS_FILE);
      const cachedJson = pref.getSync(PrivacyManager.KEY_REMOTE_VERSION_CACHE, '') as string;
      const cachedTime = pref.getSync(PrivacyManager.KEY_REMOTE_VERSION_CACHE_TIME, 0) as number;
      if (cachedJson.length > 0 && (now - cachedTime) < REMOTE_VERSION_CACHE_TTL) {
        try {
          PrivacyManager.remoteManifest = JSON.parse(cachedJson) as RemoteVersionManifest;
          PrivacyManager.remoteManifestFetchedAt = cachedTime;
          return PrivacyManager.remoteManifest;
        } catch (_e) {
          // fall through to fetch online
        }
      }
    } catch (_e) {
      // fall through
    }

    try {
      const ossBase = DEFAULT_PRIVACY_OSS_BASE;
      const manifestUrl = ossBase + VERSION_MANIFEST_PATH;

      try {
        const opts = new SecureRequestOptions();
        opts.url = manifestUrl;
        opts.method = http.RequestMethod.GET;
        opts.connectTimeout = 5000;
        opts.readTimeout = 5000;
        const response = await SecureHttpClient.getInstance().request(opts);

        if (response.responseCode === 200 && typeof response.result === 'string') {
          const manifest = JSON.parse(response.result) as RemoteVersionManifest;
          if (manifest.latestVersion && manifest.privacyPolicyUrl && manifest.userAgreementUrl) {
            PrivacyManager.remoteManifest = manifest;
            PrivacyManager.remoteManifestFetchedAt = now;

            try {
              const pref = await preferences.getPreferences(context, PrivacyManager.PREFS_FILE);
              pref.putSync(PrivacyManager.KEY_REMOTE_VERSION_CACHE, JSON.stringify(manifest));
              pref.putSync(PrivacyManager.KEY_REMOTE_VERSION_CACHE_TIME, now);
              await pref.flush();
            } catch (_e) { /* cache save failure non-critical */ }

            hilog.info(DOMAIN_ZERO, TAG, 'Remote manifest fetched: v%{public}s', manifest.latestVersion);
            return manifest;
          }
        }
      } catch (fetchErr) {
        hilog.warn(DOMAIN_ZERO, TAG, 'SecureHttpClient request failed: %{public}s', JSON.stringify(fetchErr));
      }

      hilog.info(DOMAIN_ZERO, TAG, 'Remote manifest fetch failed or invalid');
      return null;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'fetchRemoteManifest error: %{public}s', JSON.stringify(e));
      return null;
    }
  }
}
