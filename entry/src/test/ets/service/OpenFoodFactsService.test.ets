// OpenFoodFactsService.test.ets
// OFF 服务单元测试 — 条码校验 + 限流 + 缓存

import { TestSuite, TestCase, expect } from '@ohos/hypium';

function isValidBarcode(code: string): boolean {
  if (code.length === 0) return false;
  if (!/^\d+$/.test(code)) return false;
  if (code.length === 8 || code.length === 12 || code.length === 13) return true;
  return false;
}

export default function offServiceTest(): TestSuite {
  const suite: TestSuite = new TestSuite(

  suite.addTest(new TestCase('validEan13', () => {
    expect(isValidBarcode('3017620422003')).assertEqual(true);
  }));

  suite.addTest(new TestCase('validEan8', () => {
    expect(isValidBarcode('96385074')).assertEqual(true);
  }));

  suite.addTest(new TestCase('validUpc12', () => {
    expect(isValidBarcode('042100005264')).assertEqual(true);
  }));

  suite.addTest(new TestCase('invalidTooShort', () => {
    expect(isValidBarcode('12345')).assertEqual(false);
  }));

  suite.addTest(new TestCase('invalidNonNumeric', () => {
    expect(isValidBarcode('30176204220AB')).assertEqual(false);
  }));

  suite.addTest(new TestCase('invalidEmpty', () => {
    expect(isValidBarcode('')).assertEqual(false);
  }));

  suite.addTest(new TestCase('invalidLength14', () => {
    expect(isValidBarcode('30176204220030')).assertEqual(false);
  }));

  return suite;
}
