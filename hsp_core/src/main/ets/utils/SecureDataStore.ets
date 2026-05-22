// SecureDataStore.ets
// HarmonyOS 6.1 数据安全 — 基于 HUKS + CryptoFramework 的敏感数据加密存储
// 适用场景：健康档案、过敏原信息、成员隐私数据

import { huks } from '@kit.UniversalKeystoreKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'SecureDataStore';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

const SECURE_PREF_NAME = 'secure_encrypted_store';
const KEY_ALIAS = 'family_food_aes256_key';
const IV_LENGTH = 12; // GCM IV 推荐 12 字节
const TAG_LENGTH = 16; // GCM Tag 16 字节

export class SecureDataStore {
  private static instance: SecureDataStore;
  private keyMaterial: huks.HuksResult | null = null;
  private context: common.Context | null = null;

  static getInstance(): SecureDataStore {
    if (!SecureDataStore.instance) {
      SecureDataStore.instance = new SecureDataStore();
    }
    return SecureDataStore.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.ensureKey();
  }

  // ========== 公开接口 ==========

  /** 加密并持久化存储字符串 */
  async encryptAndStore(key: string, plainText: string): Promise<boolean> {
    try {
      const encrypted = await this.encrypt(plainText);
      const hexStr = this.arrayBufferToHex(encrypted);
      const prefs = await preferences.getPreferences(this.context!, SECURE_PREF_NAME);
      await prefs.put(key, hexStr);
      await prefs.flush();
      return true;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'encryptAndStore failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  /** 读取并解密持久化数据 */
  async loadAndDecrypt(key: string): Promise<string | null> {
    try {
      const prefs = await preferences.getPreferences(this.context!, SECURE_PREF_NAME);
      const hexStr = await prefs.get(key, '') as string;
      if (hexStr.length === 0) return null;
      const encrypted = this.hexToArrayBuffer(hexStr);
      return await this.decrypt(encrypted);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'loadAndDecrypt failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  /** 删除指定键的加密数据 */
  async deleteKey(key: string): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(this.context!, SECURE_PREF_NAME);
      await prefs.delete(key);
      await prefs.flush();
    } catch (_) {
      // 静默处理
    }
  }

  /** 加密数据（不持久化，返回 ArrayBuffer） */
  async encrypt(plainText: string): Promise<ArrayBuffer> {
    await this.ensureKey();
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const keyData = new Uint8Array(this.keyMaterial!.outData!);
    const symKey = await symKeyGenerator.convertKey({ data: keyData.buffer as ArrayBuffer });

    const cipher = cryptoFramework.createCipher('AES256|GCM|NONE');
    const iv = cryptoFramework.createIv(new Uint8Array(IV_LENGTH));
    const params: cryptoFramework.GcmParamsSpec = {
      iv: { data: new Uint8Array(IV_LENGTH).buffer as ArrayBuffer },
      aad: { data: new Uint8Array(0).buffer as ArrayBuffer },
      authTag: { data: new Uint8Array(TAG_LENGTH).buffer as ArrayBuffer },
      algoName: 'GcmParamsSpec'
    };

    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, params);
    const input: cryptoFramework.DataBlob = {
      data: this.stringToArrayBuffer(plainText)
    };
    const result = await cipher.doFinal(input);
    // 返回 IV + 密文 + AuthTag 的拼接
    return this.concatBuffers(iv.data, result.data);
  }

  /** 解密数据 */
  async decrypt(encryptedData: ArrayBuffer): Promise<string> {
    await this.ensureKey();
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const keyData = new Uint8Array(this.keyMaterial!.outData!);
    const symKey = await symKeyGenerator.convertKey({ data: keyData.buffer as ArrayBuffer });

    if (encryptedData.byteLength < IV_LENGTH + TAG_LENGTH) {
      throw new Error('Invalid encrypted data length');
    }

    const fullData = new Uint8Array(encryptedData);
    const iv = new Uint8Array(fullData.slice(0, IV_LENGTH));
    const tag = new Uint8Array(fullData.slice(encryptedData.byteLength - TAG_LENGTH));
    const cipherData = new Uint8Array(fullData.slice(IV_LENGTH, encryptedData.byteLength - TAG_LENGTH));

    const decipher = cryptoFramework.createCipher('AES256|GCM|NONE');
    const params: cryptoFramework.GcmParamsSpec = {
      iv: { data: iv.buffer as ArrayBuffer },
      aad: { data: new Uint8Array(0).buffer as ArrayBuffer },
      authTag: { data: tag.buffer as ArrayBuffer },
      algoName: 'GcmParamsSpec'
    };

    await decipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, params);
    const input: cryptoFramework.DataBlob = { data: cipherData.buffer as ArrayBuffer };
    const result = await decipher.doFinal(input);
    return this.arrayBufferToString(result.data);
  }

  // ========== 内部方法 ==========

  private async ensureKey(): Promise<void> {
    if (this.keyMaterial) return;
    try {
      // 尝试获取已有密钥
      const keyProperties: huks.HuksKeyProperties = {
        alias: KEY_ALIAS
      };
      this.keyMaterial = await huks.getKeyProperties(keyProperties);
    } catch (_) {
      // 密钥不存在，生成新密钥
      await this.generateKey();
    }
  }

  private async generateKey(): Promise<void> {
    const keyGenParams: huks.HuksKeyGenOptions = {
      properties: [
        { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
        { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
        { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
        { tag: huks.HuksTag.HUKS_TAG_DIGEST, value: huks.HuksKeyDigest.HUKS_DIGEST_SHA256 },
        { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
        { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
        { tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL, value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_DE }
      ],
      alias: KEY_ALIAS
    };
    await huks.generateKeyItem(keyGenParams);
    // 重新获取
    const keyProperties2: huks.HuksKeyProperties = {
      alias: KEY_ALIAS
    };
    this.keyMaterial = await huks.getKeyProperties(keyProperties2);
  }

  private stringToArrayBuffer(str: string): ArrayBuffer {
    const encoder = new util.TextEncoder();
    return encoder.encodeInto(str).buffer as ArrayBuffer;
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const decoder = new util.TextDecoder('utf-8');
    return decoder.decodeWithStream(new Uint8Array(buffer));
  }

  private arrayBufferToHex(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let hex = '';
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0');
    }
    return hex;
  }

  private hexToArrayBuffer(hex: string): ArrayBuffer {
    const bytes = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
    }
    return bytes.buffer as ArrayBuffer;
  }

  private concatBuffers(a: ArrayBuffer, b: ArrayBuffer): ArrayBuffer {
    const result = new Uint8Array(a.byteLength + b.byteLength);
    result.set(new Uint8Array(a), 0);
    result.set(new Uint8Array(b), a.byteLength);
    return result.buffer as ArrayBuffer;
  }
}
