import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { util } from '@kit.ArkTS';

const TAG = 'CryptoEngine';
const DOMAIN_ZERO: number = HILOG_DOMAIN_DEFAULT as number;
const AES_KEY_ALIAS = 'family_food_aes256_key';
const B64_TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

class GcmSeparatedData {
  iv: Uint8Array = new Uint8Array(0);
  ciphertext: Uint8Array = new Uint8Array(0);
  authTag: Uint8Array = new Uint8Array(0);
}

export class CryptoEngine {
  private static instance: CryptoEngine | null = null;
  private symKey: cryptoFramework.SymKey | null = null;
  private initialized: boolean = false;

  static getInstance(): CryptoEngine {
    if (!CryptoEngine.instance) {
      CryptoEngine.instance = new CryptoEngine();
    }
    return CryptoEngine.instance;
  }

  async init(): Promise<void> {
    if (this.initialized) return;

    try {
      const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const keyData = await this.getOrCreateKey();
      this.symKey = await keyGenerator.convertKey({ data: keyData });
      this.initialized = true;
      hilog.info(DOMAIN_ZERO, TAG, 'CryptoEngine initialized');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'CryptoEngine init failed: %{public}s', JSON.stringify(error));
      throw new Error(error.toString());
    }
  }

  async encrypt(plaintext: string): Promise<string> {
    if (!this.symKey) throw new Error('CryptoEngine not initialized');

    try {
      const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
      const iv = this.generateIv(12);
      const gcmParams: cryptoFramework.GcmParamsSpec = {
        iv: { data: iv.buffer as ArrayBuffer },
        aad: { data: (new Uint8Array(0)).buffer as ArrayBuffer },
        authTag: { data: (new Uint8Array(16)).buffer as ArrayBuffer }
      } as cryptoFramework.GcmParamsSpec;
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, this.symKey, gcmParams);

      const input: cryptoFramework.DataBlob = {
        data: new util.TextEncoder().encodeInto(plaintext)
      };
      const output = await cipher.doFinal(input);

      const combined = this.combineIvAndCiphertext(iv, output.data);
      return this.uint8ArrayToBase64(combined);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Encrypt failed: %{public}s', JSON.stringify(error));
      throw new Error(error.toString());
    }
  }

  async decrypt(ciphertextBase64: string): Promise<string> {
    if (!this.symKey) throw new Error('CryptoEngine not initialized');

    try {
      const combined = this.base64ToUint8Array(ciphertextBase64);
      const separated = this.separateIvAndCiphertext(combined);
      const iv = separated.iv;
      const ciphertext = separated.ciphertext;
      const authTag = separated.authTag;

      const decipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
      const gcmParams2: cryptoFramework.GcmParamsSpec = {
        iv: { data: iv.buffer as ArrayBuffer },
        aad: { data: (new Uint8Array(0)).buffer as ArrayBuffer },
        authTag: { data: authTag.buffer as ArrayBuffer }
      } as cryptoFramework.GcmParamsSpec;
      await decipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, this.symKey, gcmParams2);

      const input: cryptoFramework.DataBlob = { data: ciphertext };
      const output = await decipher.doFinal(input);

      return new util.TextDecoder().decodeTooutput.data.toString();
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Decrypt failed: %{public}s', JSON.stringify(error));
      throw new Error(error.toString());
    }
  }

  async encryptField(obj: Object, fields: string[]): Promise<Object> {
    const result: Record<string, Object> = {};
    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = (obj as Record<string, Object>)[key];
      if (fields.includes(key) && typeof value === 'string') {
        result[key] = await this.encrypt(value as string);
      } else {
        result[key] = value;
      }
    }
    return result as Object;
  }

  async decryptField(obj: Object, fields: string[]): Promise<Object> {
    const result: Record<string, Object> = {};
    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = (obj as Record<string, Object>)[key];
      if (fields.includes(key) && typeof value === 'string') {
        try {
          result[key] = await this.decrypt(value as string);
        } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_));
          result[key] = '[解密失败]';
        }
      } else {
        result[key] = value;
      }
    }
    return result as Object;
  }

  isInitialized(): boolean {
    return this.initialized;
  }

  private async getOrCreateKey(): Promise<Uint8Array> {
    const keyLen = 32;
    const key: Uint8Array = new Uint8Array(
    for (let i = 0; i < keyLen; i++) {
      key[i] = Math.floor(Math.random() * 256);
    }
    return key;
  }

  private generateIv(length: number): Uint8Array {
    const iv: Uint8Array = new Uint8Array(
    for (let i = 0; i < length; i++) {
      iv[i] = Math.floor(Math.random() * 256);
    }
    return iv;
  }

  private combineIvAndCiphertext(iv: Uint8Array, ciphertext: Uint8Array): Uint8Array {
    const combined: Uint8Array = new Uint8Array(
    combined.set(iv, 0);
    combined.set(ciphertext, iv.length);
    return combined;
  }

  private separateIvAndCiphertext(combined: Uint8Array): GcmSeparatedData {
    const ivLen = 12;
    const authTagLen = 16;
    const result: GcmSeparatedData = new GcmSeparatedData()
    result.iv = combined.slice(0, ivLen);
    result.ciphertext = combined.slice(ivLen, combined.length - authTagLen);
    result.authTag = combined.slice(combined.length - authTagLen);
    return result;
  }

  private uint8ArrayToBase64(data: Uint8Array): string {
    let result = '';
    for (let i = 0; i < data.length; i += 3) {
      const b1 = data[i];
      const b2 = (i + 1 < data.length) ? data[i + 1] : 0;
      const b3 = (i + 2 < data.length) ? data[i + 2] : 0;
      const n = (b1 << 16) | (b2 << 8) | b3;
      result += B64_TABLE.charAt((n >> 18) & 63);
      result += B64_TABLE.charAt((n >> 12) & 63);
      result += (i + 1 < data.length) ? B64_TABLE.charAt((n >> 6) & 63) : '=';
      result += (i + 2 < data.length) ? B64_TABLE.charAt(n & 63) : '=';
    }
    return result;
  }

  private base64ToUint8Array(str: string): Uint8Array {
    const lookup = new Array<number>(128);
    for (let i = 0; i < 128; i++) { lookup[i] = -1; }
    for (let i = 0; i < B64_TABLE.length; i++) { lookup[B64_TABLE.charCodeAt(i)] = i; }
    const len = str.length;
    let padCount = 0;
    if (len > 0 && str.charAt(len - 1) === '=') { padCount++; }
    if (len > 1 && str.charAt(len - 2) === '=') { padCount++; }
    const byteLen = (len * 3) / 4 - padCount;
    const result: Uint8Array = new Uint8Array(
    let p = 0;
    for (let i = 0; i < len; i += 4) {
      const n = (lookup[str.charCodeAt(i)] << 18) | (lookup[str.charCodeAt(i + 1)] << 12) |
                (lookup[str.charCodeAt(i + 2)] << 6) | lookup[str.charCodeAt(i + 3)];
      result[p++] = (n >> 16) & 255;
      if (str.charAt(i + 2) !== '=') { result[p++] = (n >> 8) & 255; }
      if (str.charAt(i + 3) !== '=') { result[p++] = n & 255; }
    }
    return result;
  }
}
