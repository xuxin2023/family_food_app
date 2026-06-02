import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SecureStorageUtil';
const DOMAIN_ZERO = 0x0001;
const FIXED_IV = new Uint8Array([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c]);
const FIXED_TAG_PLACEHOLDER = new Uint8Array(16);
const FIXED_AAD = new Uint8Array(0);
const B64_TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function makeGcmParams(iv: Uint8Array, aad: Uint8Array, authTag: Uint8Array): cryptoFramework.GcmParamsSpec {
  return {
    iv: { data: iv.buffer as ArrayBuffer },
    aad: { data: aad.buffer as ArrayBuffer },
    authTag: { data: authTag.buffer as ArrayBuffer }
  } as cryptoFramework.GcmParamsSpec;
}

function uint8ArrayToBase64(data: Uint8Array): string {
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

function base64ToUint8Array(str: string): Uint8Array {
  const lookup = new Array<number>(128);
  for (let i = 0; i < 128; i++) { lookup[i] = -1; }
  for (let i = 0; i < B64_TABLE.length; i++) { lookup[B64_TABLE.charCodeAt(i)] = i; }
  const len = str.length;
  let padCount = 0;
  if (len > 0 && str.charAt(len - 1) === '=') { padCount++; }
  if (len > 1 && str.charAt(len - 2) === '=') { padCount++; }
  const byteLen = (len * 3) / 4 - padCount;
  const result = new Uint8Array(byteLen);
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

export class SecureStorageUtil {
  private static instance: SecureStorageUtil | null = null;
  private symKey: cryptoFramework.SymKey | null = null;

  private constructor() {}

  static getInstance(): SecureStorageUtil {
    if (!SecureStorageUtil.instance) {
      SecureStorageUtil.instance = new SecureStorageUtil();
    }
    return SecureStorageUtil.instance;
  }

  async init(keyMaterial: Uint8Array): Promise<void> {
    try {
      const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const blob: cryptoFramework.DataBlob = { data: keyMaterial };
      this.symKey = await keyGenerator.convertKey(blob);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'init encryption key failed: %{public}s', JSON.stringify(e));
    }
  }

  async encrypt(plainText: string): Promise<string> {
    if (!this.symKey) {
      hilog.warn(DOMAIN_ZERO, TAG, 'symKey not initialized, returning plain text');
      return plainText;
    }
    try {
      const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
      const params = makeGcmParams(FIXED_IV, FIXED_AAD, FIXED_TAG_PLACEHOLDER);
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, this.symKey, params);
      const encoder = new util.TextEncoder();
      const encoded = encoder.encodeInto(plainText);
      const input: cryptoFramework.DataBlob = { data: encoded };
      const result = await cipher.doFinal(input);
      return uint8ArrayToBase64(new Uint8Array(result.data));
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'encrypt failed: %{public}s', JSON.stringify(e));
      return plainText;
    }
  }

  async decrypt(cipherText: string): Promise<string> {
    if (!this.symKey) {
      hilog.warn(DOMAIN_ZERO, TAG, 'symKey not initialized, returning cipher text as-is');
      return cipherText;
    }
    try {
      const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
      const params = makeGcmParams(FIXED_IV, FIXED_AAD, FIXED_TAG_PLACEHOLDER);
      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, this.symKey, params);
      const encryptedData = base64ToUint8Array(cipherText);
      const input: cryptoFramework.DataBlob = { data: new Uint8Array(encryptedData) };
      const result = await cipher.doFinal(input);
      const decoder = new util.TextDecoder('utf-8');
      return decoder.decodeToString(new Uint8Array(result.data));
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'decrypt failed: %{public}s', JSON.stringify(e));
      return cipherText;
    }
  }
}
