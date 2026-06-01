import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SecureStorageUtil';
const DOMAIN_ZERO = 0x0001;

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
      const params = cryptoFramework.createGcmParams(
        new Uint8Array([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c]),
        12,
        new Uint8Array([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10]),
        16
      );
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, this.symKey, params);
      const input: cryptoFramework.DataBlob = { data: new Uint8Array(Buffer.from(plainText, 'utf-8')) };
      const result = await cipher.doFinal(input);
      const base64 = new util.Base64Helper();
      return base64.encodeToStringSync(result.data);
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
      const params = cryptoFramework.createGcmParams(
        new Uint8Array([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c]),
        12,
        new Uint8Array([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10]),
        16
      );
      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, this.symKey, params);
      const base64 = new util.Base64Helper();
      const encryptedData = base64.decodeSync(cipherText);
      const input: cryptoFramework.DataBlob = { data: new Uint8Array(encryptedData) };
      const result = await cipher.doFinal(input);
      return Buffer.from(result.data).toString('utf-8');
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'decrypt failed: %{public}s', JSON.stringify(e));
      return cipherText;
    }
  }
}