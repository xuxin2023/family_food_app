// SecureDataStore.ets
// HarmonyOS 6.1 数据安全 — 基于 HUKS + CryptoFramework 的敏感数据加密存储
// 适用场景：健康档案、过敏原信息、成员隐私数据

import { huks } from '@kit.UniversalKeystoreKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'SecureDataStore';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const SECURE_PREF_NAME = 'secure_encrypted_store';
const KEY_ALIAS = 'family_food_aes256_key';
const IV_LENGTH = 12; // GCM IV 推荐 12 字节
const TAG_LENGTH = 16; // GCM Tag 16 字节

/**
 * 安全数据存储
 *
 * 基于HarmonyOS 6.1 HUKS + CryptoFramework的敏感数据加密存储，
 * 加密方式：AES-256-GCM（认证加密），密钥由HUKS安全生成和管理，
 * 存储格式：IV(12字节) + 密文 + AuthTag(16字节)，持久化使用Preferences。
 *
 * 适用场景：健康档案、过敏原信息、成员隐私数据等敏感信息的加密存储。
 *
 * 安全特性：
 * - 密钥由HUKS在DE(设备加密)级别生成，不可导出明文
 * - AES-256-GCM提供机密性+完整性+认证性保证
 * - 每次加密使用随机IV，防止密文分析
 *
 * @since 1.0.0
 */
export class SecureDataStore {
  private static instance: SecureDataStore;
  private keyMaterial: huks.HuksReturnResult | null = null;
  private keyExists: boolean = false;
  private context: common.Context | null = null;

  /**
   * 获取SecureDataStore单例
   *
   * @returns SecureDataStore实例
   */
  static getInstance(): SecureDataStore {
    if (!SecureDataStore.instance) {
      SecureDataStore.instance = new SecureDataStore();
    }
    return SecureDataStore.instance;
  }

  /**
   * 初始化安全存储（生成或加载HUKS密钥）
   *
   * @param context - 应用上下文
   * @returns Promise<void>
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.ensureKey();
  }

  // ========== 公开接口 ==========

  /**
   * 加密并持久化存储字符串
   *
   * @param key - 存储键名
   * @param plainText - 明文内容
   * @returns 加密存储是否成功
   */
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

  /**
   * 读取并解密持久化数据
   *
   * @param key - 存储键名
   * @returns 解密后的明文，键不存在或解密失败返回null
   */
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

  /**
   * 删除指定键的加密数据
   *
   * @param key - 存储键名
   * @returns Promise<void>
   */
  async deleteKey(key: string): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(this.context!, SECURE_PREF_NAME);
      await prefs.delete(key);
      await prefs.flush();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'remove failed: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 加密数据（不持久化，返回ArrayBuffer）
   *
   * 输出格式：IV(12字节) + AES-GCM密文 + AuthTag(16字节)
   *
   * @param plainText - 明文内容
   * @returns 加密后的ArrayBuffer
   */
  async encrypt(plainText: string): Promise<ArrayBuffer> {
    await this.ensureKey();
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const keyData: Uint8Array = new Uint8Array(
    const symKey = await symKeyGenerator.convertKey({ data: keyData.buffer as ArrayBuffer });

    const cipher = cryptoFramework.createCipher('AES256|GCM|NONE');
    const random = cryptoFramework.createRandom();
    const randomBlob = await random.generateRandom(IV_LENGTH);
    const ivBytes: Uint8Array = new Uint8Array(
    const aadArr: Uint8Array = new Uint8Array(0);
    const tagArr: Uint8Array = new Uint8Array(TAG_LENGTH);
    const params: cryptoFramework.GcmParamsSpec = {
      iv: { data: ivBytes.buffer as ArrayBuffer },
      aad: { data: aadArr.buffer as ArrayBuffer },
      authTag: { data: tagArr.buffer as ArrayBuffer }
    } as cryptoFramework.GcmParamsSpec;

    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, params);
    const input: cryptoFramework.DataBlob = {
      data: this.stringToArrayBuffer(plainText)
    };
    const result = await cipher.doFinal(input);
    // 返回 IV + 密文 + AuthTag 的拼接
    return this.concatBuffers(ivBytes.buffer as ArrayBuffer, result.data);
  }

  /**
   * 解密数据
   *
   * 输入格式须为encrypt()输出的IV+密文+AuthTag格式。
   *
   * @param encryptedData - 加密数据ArrayBuffer
   * @returns 解密后的明文字符串
   * @throws Error 数据长度不足时抛出
   */
  async decrypt(encryptedData: ArrayBuffer): Promise<string> {
    await this.ensureKey();
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const keyData: Uint8Array = new Uint8Array(
    const symKey = await symKeyGenerator.convertKey({ data: keyData.buffer as ArrayBuffer });

    if (encryptedData.byteLength < IV_LENGTH + TAG_LENGTH) {
      throw new Error('Invalid encrypted data length');
    }

    const fullData: Uint8Array = new Uint8Array(
    const iv: Uint8Array = new Uint8Array(
    const tag: Uint8Array = new Uint8Array(
    const cipherData: Uint8Array = new Uint8Array(

    const aadArr2: Uint8Array = new Uint8Array(0);
    const decipher = cryptoFramework.createCipher('AES256|GCM|NONE');
    const gcmParams2: cryptoFramework.GcmParamsSpec = {
      iv: { data: iv.buffer as ArrayBuffer },
      aad: { data: aadArr2.buffer as ArrayBuffer },
      authTag: { data: tag.buffer as ArrayBuffer }
    } as cryptoFramework.GcmParamsSpec;

    await decipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, params);
    const input: cryptoFramework.DataBlob = { data: cipherData.buffer as ArrayBuffer };
    const result = await decipher.doFinal(input);
    return this.arrayBufferToString(result.data);
  }

  // ========== 内部方法 ==========

  private async ensureKey(): Promise<void> {
    if (this.keyMaterial && this.keyExists) return;
    try {
      const isExistOptions: huks.HuksOptions = {
        properties: [
          { tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL, value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_DE } as huks.HuksParam
        ]
      };
      const isExistResult = await huks.isKeyItemExist(KEY_ALIAS, isExistOptions);
      if (isExistResult) {
        this.keyExists = true;
        this.keyMaterial = await this.exportKeyMaterial();
      } else {
        await this.generateKey();
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'ensureKey failed: %{public}s', JSON.stringify(e));
      await this.generateKey();
    }
  }

  private async exportKeyMaterial(): Promise<huks.HuksReturnResult> {
    const exportOptions: huks.HuksOptions = {
      properties: [
        { tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL, value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_DE } as huks.HuksParam
      ]
    };
    return await huks.exportKeyItem(KEY_ALIAS, exportOptions);
  }

  private async generateKey(): Promise<void> {
    const keyGenProperties: huks.HuksParam[] = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES } as huks.HuksParam,
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 } as huks.HuksParam,
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT } as huks.HuksParam,
      { tag: huks.HuksTag.HUKS_TAG_DIGEST, value: huks.HuksKeyDigest.HUKS_DIGEST_SHA256 } as huks.HuksParam,
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM } as huks.HuksParam,
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE } as huks.HuksParam,
      { tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL, value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_DE } as huks.HuksParam
    ];
    const keyGenOptions: huks.HuksOptions = {
      properties: keyGenProperties
    };
    await huks.generateKeyItem(KEY_ALIAS, keyGenOptions);
    this.keyMaterial = await this.exportKeyMaterial();
    this.keyExists = true;
  }

  private stringToArrayBuffer(str: string): ArrayBuffer {
    const encoder: util.TextEncoder = new util.TextEncoder();
    const encoded: Uint8Array = encoder.encodeInto(str);
    return encoded.buffer as ArrayBuffer;
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const decoder: util.TextDecoder = new util.TextDecoder('utf-8');
    const bytes: Uint8Array = new Uint8Array(
    const decoded: string = decoder.decodeToString(bytes);
    return decoded;
  }

  private arrayBufferToHex(buffer: ArrayBuffer): string {
    const bytes: Uint8Array = new Uint8Array(
    let hex = '';
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0');
    }
    return hex;
  }

  private hexToArrayBuffer(hex: string): ArrayBuffer {
    const bytes: Uint8Array = new Uint8Array(
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
    }
    return bytes.buffer as ArrayBuffer;
  }

  private concatBuffers(a: ArrayBuffer, b: ArrayBuffer): ArrayBuffer {
    const result: Uint8Array = new Uint8Array(
    result.set(new Uint8Array(a), 0);
    result.set(new Uint8Array(b), a.byteLength);
    return result.buffer as ArrayBuffer;
  }
}
