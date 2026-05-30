import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { util } from '@kit.ArkTS';

const TAG = 'CryptoEngine';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const AES_KEY_ALIAS = 'family_food_aes256_key';

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
      throw new Error(String(error));
    }
  }

  async encrypt(plaintext: string): Promise<string> {
    if (!this.symKey) throw new Error('CryptoEngine not initialized');

    try {
      const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
      const iv = this.generateIv(12);
      const params = cryptoFramework.createGcmParams(iv, new Uint8Array(0), new Uint8Array(16));
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, this.symKey, params);

      const input: cryptoFramework.DataBlob = {
        data: new util.TextEncoder().encodeInto(plaintext)
      };
      const output = await cipher.doFinal(input);

      const combined = this.combineIvAndCiphertext(iv, output.data);
      return util.Base64Helper.encodeToStringSync(combined);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Encrypt failed: %{public}s', JSON.stringify(error));
      throw new Error(String(error));
    }
  }

  async decrypt(ciphertextBase64: string): Promise<string> {
    if (!this.symKey) throw new Error('CryptoEngine not initialized');

    try {
      const combined = util.Base64Helper.decodeSync(ciphertextBase64);
      const { iv, ciphertext, authTag } = this.separateIvAndCiphertext(combined);

      const decipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
      const params = cryptoFramework.createGcmParams(iv, new Uint8Array(0), authTag);
      await decipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, this.symKey, params);

      const input: cryptoFramework.DataBlob = { data: ciphertext };
      const output = await decipher.doFinal(input);

      return new util.TextDecoder().decodeToString(output.data);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Decrypt failed: %{public}s', JSON.stringify(error));
      throw new Error(String(error));
    }
  }

  async encryptField(obj: Object, fields: string[]): Promise<Object> {
    const result: Record<string, Object> = {};
    const entries = Object.entries(obj);
    for (const [key, value] of entries) {
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
    const entries = Object.entries(obj);
    for (const [key, value] of entries) {
      if (fields.includes(key) && typeof value === 'string') {
        try {
          result[key] = await this.decrypt(value as string);
        } catch (_) {
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
    const key = new Uint8Array(keyLen);
    for (let i = 0; i < keyLen; i++) {
      key[i] = Math.floor(Math.random() * 256);
    }
    return key;
  }

  private generateIv(length: number): Uint8Array {
    const iv = new Uint8Array(length);
    for (let i = 0; i < length; i++) {
      iv[i] = Math.floor(Math.random() * 256);
    }
    return iv;
  }

  private combineIvAndCiphertext(iv: Uint8Array, ciphertext: Uint8Array): Uint8Array {
    const combined = new Uint8Array(iv.length + ciphertext.length);
    combined.set(iv, 0);
    combined.set(ciphertext, iv.length);
    return combined;
  }

  private separateIvAndCiphertext(combined: Uint8Array): {
    iv: Uint8Array; ciphertext: Uint8Array; authTag: Uint8Array
  } {
    const ivLen = 12;
    const authTagLen = 16;
    const iv = combined.slice(0, ivLen);
    const ciphertext = combined.slice(ivLen, combined.length - authTagLen);
    const authTag = combined.slice(combined.length - authTagLen);
    return { iv, ciphertext, authTag };
  }
}
