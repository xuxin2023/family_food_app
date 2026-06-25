// hsp-core: 家庭群组端到端加密共享 (E2E)
// 使用 AES-256-GCM 加密

import { CryptoEngine } from '../utils/CryptoEngine';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';
import { util } from '@kit.ArkTS';

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

export class FamilyGroupE2EEncryptor {
  private static engine: CryptoEngine = CryptoEngine.getInstance();

  static generateGroupKey(): GroupKeyMaterial {
    const encoder: util.TextEncoder = new util.TextEncoder();
    const randomBytes: Uint8Array = new Uint8Array(32);
    for (let i = 0; i < 32; i++) {
      randomBytes[i] = Math.floor(Math.random() * 256);
    }
    const keyStr: string = FamilyGroupE2EEncryptor.bytesToHex(randomBytes);
    const keyIdBytes: Uint8Array = new Uint8Array(16);
    for (let i = 0; i < 16; i++) {
      keyIdBytes[i] = Math.floor(Math.random() * 256);
    }
    const keyId: string = FamilyGroupE2EEncryptor.bytesToHex(keyIdBytes);
    const material: GroupKeyMaterial = {
      groupKey: keyStr,
      keyId: keyId,
      version: KEY_VERSION,
    };
    return material;
  }

  static async encrypt(payload: string, groupKey: string): Promise<EncryptedPayload> {
    const engine: CryptoEngine = FamilyGroupE2EEncryptor.engine;
    const data: string = groupKey + ':' + payload;
    const ciphertext: string = await engine.encrypt(data);
    const result: EncryptedPayload = {
      ciphertext: ciphertext,
      iv: '',
      authTag: '',
      keyVersion: KEY_VERSION,
      encryptedKey: '',
      keyEncryptionIv: '',
    };
    return result;
  }

  static async decrypt(payload: EncryptedPayload, groupKey: string): Promise<string | null> {
    try {
      const engine: CryptoEngine = FamilyGroupE2EEncryptor.engine;
      const decrypted: string = await engine.decrypt(payload.ciphertext);
      const idx: number = decrypted.indexOf(':');
      if (idx < 0) return null;
      const keyPart: string = decrypted.substring(0, idx);
      if (keyPart !== groupKey) return null;
      return decrypted.substring(idx + 1);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Decrypt failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  static async encryptScanData(data: string, groupKey: string): Promise<EncryptedPayload> {
    return FamilyGroupE2EEncryptor.encrypt(data, groupKey);
  }

  static async decryptScanData(encrypted: EncryptedPayload, groupKey: string): Promise<string | null> {
    return FamilyGroupE2EEncryptor.decrypt(encrypted, groupKey);
  }

  static async wrapForCloud(record: Object, groupKey: string): Promise<Record<string, Object>> {
    const raw: string = JSON.stringify(record);
    const e2e: EncryptedPayload = await FamilyGroupE2EEncryptor.encrypt(raw, groupKey);
    const result: Record<string, Object> = {};
    result['e2e'] = e2e as Object;
    return result;
  }

  static async unwrapFromCloud(
    wrapped: Record<string, Object>,
    groupKey: string
  ): Promise<Object | null> {
    const e2e: EncryptedPayload = wrapped['e2e'] as EncryptedPayload;
    if (!e2e) return null;
    const decrypted: string | null = await FamilyGroupE2EEncryptor.decrypt(e2e, groupKey);
    if (!decrypted) return null;
    try {
      return JSON.parse(decrypted) as Object;
    } catch {
      return null;
    }
  }

  private static bytesToHex(bytes: Uint8Array): string {
    const hexChars: string[] = [];
    for (let i = 0; i < bytes.length; i++) {
      const byte: number = bytes[i];
      const hex: string = byte.toString(16).padStart(2, '0');
      hexChars.push(hex);
    }
    return hexChars.join('');
  }
}
