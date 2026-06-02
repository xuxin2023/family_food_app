// FamilyGroupE2EEncryptor.test.ets
// V5 家庭群组端到端加密单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { FamilyGroupE2EEncryptor } from 'hsp_core';

export default function e2eTest(): TestSuite {
  const suite = new TestSuite('FamilyGroupE2EEncryptor');

  suite.addTest(new TestCase('generateGroupKey produces valid key', () => {
    const km = FamilyGroupE2EEncryptor.generateGroupKey();
    expect(km.groupKey).assertTrue(km.groupKey.length > 0);
    expect(km.keyId).assertTrue(km.keyId.length > 0);
    expect(km.version).assertEqual(1);
  }));

  suite.addTest(new TestCase('generateGroupKey produces unique keys', () => {
    const k1 = FamilyGroupE2EEncryptor.generateGroupKey();
    const k2 = FamilyGroupE2EEncryptor.generateGroupKey();
    expect(k1.keyId !== k2.keyId || k1.groupKey !== k2.groupKey).assertTrue();
  }));

  suite.addTest(new TestCase('encryptDecrypt_roundtrip', () => {
    const km = FamilyGroupE2EEncryptor.generateGroupKey();
    const plaintext = JSON.stringify({ foodName: '测试食品', nutriScore: 75, memberResults: '适合' });
    const encrypted = FamilyGroupE2EEncryptor.encrypt(plaintext, km.groupKey);
    expect(encrypted.ciphertext).assertTrue(encrypted.ciphertext.length > 0);
    expect(encrypted.iv).assertTrue(encrypted.iv.length > 0);
    expect(encrypted.authTag).assertTrue(encrypted.authTag.length > 0);

    const decrypted = FamilyGroupE2EEncryptor.decrypt(encrypted, km.groupKey);
    expect(decrypted).assertTrue(decrypted !== null);
    expect(decrypted!).assertEqual(plaintext);
  }));

  suite.addTest(new TestCase('decrypt_with wrong key returns null', () => {
    const km1 = FamilyGroupE2EEncryptor.generateGroupKey();
    const km2 = FamilyGroupE2EEncryptor.generateGroupKey();
    const encrypted = FamilyGroupE2EEncryptor.encrypt('secret data', km1.groupKey);
    const decrypted = FamilyGroupE2EEncryptor.decrypt(encrypted, km2.groupKey);
    expect(decrypted).assertTrue(decrypted === null);
  }));

  suite.addTest(new TestCase('encryptScanData_wrap', () => {
    const km = FamilyGroupE2EEncryptor.generateGroupKey();
    const encrypted = FamilyGroupE2EEncryptor.encryptScanData('foodScanPayload', km.groupKey);
    expect(encrypted.ciphertext.length).assertTrue(encrypted.ciphertext.length > 0);
    expect(encrypted.keyVersion).assertEqual(1);
  }));

  suite.addTest(new TestCase('decryptScanData_roundtrip', () => {
    const km = FamilyGroupE2EEncryptor.generateGroupKey();
    const payload = 'foodScanPayloadV2';
    const encrypted = FamilyGroupE2EEncryptor.encryptScanData(payload, km.groupKey);
    const decrypted = FamilyGroupE2EEncryptor.decryptScanData(encrypted, km.groupKey);
    expect(decrypted).assertEqual(payload);
  }));

  suite.addTest(new TestCase('wrapForCloud_and_unwrap', () => {
    const km = FamilyGroupE2EEncryptor.generateGroupKey();
    const record = { foodName: '云存储测试', score: 88 };
    const wrapped = FamilyGroupE2EEncryptor.wrapForCloud(record, km.groupKey);
    expect(wrapped.e2e).assertTrue(wrapped.e2e !== undefined);
    expect(wrapped.e2e.ciphertext.length).assertTrue(wrapped.e2e.ciphertext.length > 0);

    const unwrapped = FamilyGroupE2EEncryptor.unwrapFromCloud(wrapped, km.groupKey);
    expect(unwrapped).assertTrue(unwrapped !== null);
    expect((unwrapped! as Record<string, Object>)['foodName']).assertEqual('云存储测试');
  }));

  suite.addTest(new TestCase('unwrap with wrong key returns null', () => {
    const km1 = FamilyGroupE2EEncryptor.generateGroupKey();
    const km2 = FamilyGroupE2EEncryptor.generateGroupKey();
    const wrapped = FamilyGroupE2EEncryptor.wrapForCloud({ val: 42 }, km1.groupKey);
    const unwrapped = FamilyGroupE2EEncryptor.unwrapFromCloud(wrapped, km2.groupKey);
    expect(unwrapped).assertTrue(unwrapped === null);
  }));

  suite.addTest(new TestCase('encrypt empty string', () => {
    const km = FamilyGroupE2EEncryptor.generateGroupKey();
    const encrypted = FamilyGroupE2EEncryptor.encrypt('', km.groupKey);
    expect(encrypted.ciphertext.length).assertTrue(encrypted.ciphertext.length > 0);
  }));

  suite.addTest(new TestCase('encrypt large payload', () => {
    const km = FamilyGroupE2EEncryptor.generateGroupKey();
    const large = 'x'.repeat(10000);
    const encrypted = FamilyGroupE2EEncryptor.encrypt(large, km.groupKey);
    const decrypted = FamilyGroupE2EEncryptor.decrypt(encrypted, km.groupKey);
    expect(decrypted).assertEqual(large);
  }));

  return suite;
}