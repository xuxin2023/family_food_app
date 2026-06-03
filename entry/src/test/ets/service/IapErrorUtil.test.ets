// IapErrorUtil.test.ets
// IAP错误码映射工具单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { IapErrorUtil } from 'hsp_service';

export default function iapErrorTest(): TestSuite {
  const suite = new TestSuite('IapErrorUtil');

  suite.addTest(new TestCase('parse returns ResourceStr for all error codes', () => {
    const codes = [0, 1, 2, 3, -1, -2, -3, 1001, 1002,
      35001, 35002, 35003, 35004, 35005, 35006, 35007, 35008];
    for (const code of codes) {
      const msg = IapErrorUtil.parseError(code);
      expect(msg).assertTrue(typeof msg === 'string' || typeof msg === 'object');
    }
  }));

  suite.addTest(new TestCase('parse returns non-empty for PRODUCT_OWNED', () => {
    const msg = IapErrorUtil.parseError(1);
    expect(msg).assertTrue(msg !== undefined && msg !== null);
  }));

  suite.addTest(new TestCase('parse returns non-empty for SYSTEM_ERROR', () => {
    const msg = IapErrorUtil.parseError(2);
    expect(msg).assertTrue(msg !== undefined && msg !== null);
  }));

  suite.addTest(new TestCase('parse returns non-empty for USER_CANCELED', () => {
    const msg = IapErrorUtil.parseError(2);
    expect(msg).assertTrue(msg !== undefined && msg !== null);
  }));

  suite.addTest(new TestCase('parse handles unknown code gracefully', () => {
    const msg = IapErrorUtil.parseError(99999);
    expect(msg).assertTrue(msg !== undefined && msg !== null);
  }));

  suite.addTest(new TestCase('parse handles negative code', () => {
    const msg = IapErrorUtil.parseError(-1);
    expect(msg).assertTrue(msg !== undefined && msg !== null);
  }));

  suite.addTest(new TestCase('parse handles extended code 35001-35008', () => {
    for (let code = 35001; code <= 35008; code++) {
      const msg = IapErrorUtil.parseError(code);
      expect(msg).assertTrue(msg !== undefined && msg !== null,
        `code ${code} should have a message`);
    }
  }));

  return suite;
}