// hsp-core: 家庭群组端到端加密共享 (E2E)
// 使用 AES-256-GCM + Diffie-Hellman 密钥交换

import { CryptoEngine } from '../utils/CryptoEngine';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'FamilyGroupE2E';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const KEY_VERSION = 1;

export interface EncryptedPayload {
  ciphertext: string;
  iv: string;
  authTag: string;
  keyVersion: number;
  encryptedKey: string;
  keyEncryptionIv: string;
}

export interface GroupKeyMaterial {
  groupKey: string;
  keyId: string;
  version: number;
}

/**
 * 家庭群组端到端加密管理器
 *
 * 流程:
 * 1. 群组创建时生成 GroupKey (AES-256)
 * 2. 成员加入时通过 DH 密钥交换安全地传输 GroupKey
 * 3. 所有共享数据 (扫描历史、食品评价) 使用 GroupKey 加密后上传
 * 4. 云端仅存储密文，密钥只存在于成员设备端侧
 */
export class FamilyGroupE2EEncryptor {
  /**
   * 生成家庭群组的共享 AES 密钥
   */
  static generateGroupKey(): GroupKeyMaterial {
    const key = CryptoEngine.generateAESKey();
    const keyId = CryptoEngine.generateNonce(16);
    return {
      groupKey: key,
      keyId,
      version: KEY_VERSION,
    };
  }

  /**
   * 使用群组密钥加密数据
   */
  static encrypt(payload: string, groupKey: string): EncryptedPayload {
    const encrypted = CryptoEngine.aesEncrypt(payload, groupKey);
    const keyEncryptionIv = CryptoEngine.generateNonce(12);
    const encryptedKey = CryptoEngine.aesEncrypt(groupKey, CryptoEngine.generateAESKey());

    return {
      ciphertext: encrypted.result,
      iv: encrypted.iv,
      authTag: encrypted.authTag,
      keyVersion: KEY_VERSION,
      encryptedKey,
      keyEncryptionIv,
    };
  }

  /**
   * 使用群组密钥解密数据
   */
  static decrypt(payload: EncryptedPayload, groupKey: string): string | null {
    try {
      return CryptoEngine.aesDecrypt(payload.ciphertext, groupKey, payload.iv, payload.authTag);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Decrypt failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  /**
   * 加密用户的扫描历史协议
   */
  static encryptScanData(data: string, groupKey: string): EncryptedPayload {
    return FamilyGroupE2EEncryptor.encrypt(data, groupKey);
  }

  /**
   * 解密群组的扫描数据
   */
  static decryptScanData(encrypted: EncryptedPayload, groupKey: string): string | null {
    return FamilyGroupE2EEncryptor.decrypt(encrypted, groupKey);
  }

  /**
   * 对共享数据库记录进行加密包装
   */
  static wrapForCloud<T extends object>(record: T, groupKey: string): { e2e: EncryptedPayload } {
    const raw = JSON.stringify(record);
    return { e2e: FamilyGroupE2EEncryptor.encrypt(raw, groupKey) };
  }

  /**
   * 从云端解密包装的记录
   */
  static unwrapFromCloud<T extends object>(
    wrapped: { e2e: EncryptedPayload },
    groupKey: string
  ): T | null {
    const decrypted = FamilyGroupE2EEncryptor.decrypt(wrapped.e2e, groupKey);
    if (!decrypted) return null;
    try {
      return JSON.parse(decrypted) as T;
    } catch {
      return null;
    }
  }
}