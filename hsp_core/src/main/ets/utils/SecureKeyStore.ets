// SecureKeyStore.ets
// 安全密钥存储 - 委托 AssetStoreKit 提供系统级加密保护
// 符合HarmonyOS 6.1安全规范：敏感数据使用Asset Store Kit加密存储，非明文

import { AssetKeyManager } from './AssetKeyManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'SecureKeyStore';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const KEY_PREFIX = 'sk_';

export class SecureKeyStore {
  private static instance: SecureKeyStore;
  private assetManager: AssetKeyManager = AssetKeyManager.getInstance();

  private constructor() {}

  static getInstance(): SecureKeyStore {
    if (!SecureKeyStore.instance) {
      SecureKeyStore.instance = new SecureKeyStore();
    }
    return SecureKeyStore.instance;
  }

  async saveKey(key: string, value: string): Promise<void> {
    const alias = KEY_PREFIX + key;
    const ok = await this.assetManager.saveKey(alias, value);
    if (ok) {
      hilog.info(DOMAIN_ZERO, TAG, 'Key saved securely: %{public}s', key);
    } else {
      hilog.warn(DOMAIN_ZERO, TAG, 'Key save failed: %{public}s', key);
    }
  }

  async getKey(key: string): Promise<string> {
    const alias = KEY_PREFIX + key;
    return await this.assetManager.getKey(alias);
  }

  async removeKey(key: string): Promise<void> {
    const alias = KEY_PREFIX + key;
    await this.assetManager.removeKey(alias);
  }

  async hasKey(key: string): Promise<boolean> {
    const value = await this.getKey(key);
    return value.length > 0;
  }

  /**
   * 获取或生成密钥（HM 6.1 数据库加密等场景）
   * - 已存在则直接返回
   * - 不存在则通过 Asset Store Kit 生成安全随机密钥并持久化
   * @param key 密钥别名
   * @returns 密钥字符串（32 字节 hex，对应 AES-256）
   */
  async getOrCreateKey(key: string): Promise<string> {
    const existing = await this.getKey(key);
    if (existing.length > 0) {
      return existing;
    }
    // 通过 CryptoFramework 生成 32 字节安全随机密钥（AES-256）
    const random = cryptoFramework.createRandom();
    const randomData: cryptoFramework.DataBlob = await random.generateRandom(32);
    const bytes = new Uint8Array(randomData.data);
    let hexKey: string = '';
    for (let i = 0; i < bytes.length; i++) {
      hexKey += bytes[i].toString(16).padStart(2, '0');
    }
    await this.saveKey(key, hexKey);
    hilog.info(DOMAIN_ZERO, TAG, 'New secure key generated: %{public}s', key);
    return hexKey;
  }
}
