// EnhancedSecurityDetector.test.ets
// V5 增强安全检测器单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { EnhancedSecurityDetector } from 'hsp_core';

export default function securityDetectorTest(): TestSuite {
  const suite = new TestSuite('EnhancedSecurityDetector');

  suite.addTest(new TestCase('performFullCheck_returns structured result', async () => {
    const result = await EnhancedSecurityDetector.performFullCheck();
    expect(result).assertTrue(result !== null && result !== undefined);
    expect(typeof result.isSafe).assertEqual('boolean');
    expect(typeof result.hasProxy).assertEqual('boolean');
    expect(typeof result.hasVpn).assertEqual('boolean');
    expect(typeof result.deviceIntegrityOk).assertEqual('boolean');
    expect(typeof result.riskLevel).assertEqual('string');
    expect(result.risks).assertTrue(Array.isArray(result.risks));
  }));

  suite.addTest(new TestCase('riskLevel is valid enum value', async () => {
    const result = await EnhancedSecurityDetector.performFullCheck();
    expect(['safe', 'warning', 'danger'].includes(result.riskLevel)).assertTrue();
  }));

  suite.addTest(new TestCase('checkProxy_returns boolean', async () => {
    const hasProxy = await EnhancedSecurityDetector.checkProxy();
    expect(typeof hasProxy).assertEqual('boolean');
  }));

  suite.addTest(new TestCase('checkVpn_returns boolean', async () => {
    const hasVpn = await EnhancedSecurityDetector.checkVpn();
    expect(typeof hasVpn).assertEqual('boolean');
  }));

  suite.addTest(new TestCase('checkDeviceIntegrity_returns boolean', async () => {
    const ok = await EnhancedSecurityDetector.checkDeviceIntegrity();
    expect(typeof ok).assertEqual('boolean');
  }));

  suite.addTest(new TestCase('getWarningMessage_danger_level', () => {
    const msg = EnhancedSecurityDetector.getWarningMessage('danger');
    expect(msg.length).assertTrue(msg.length > 0);
    expect(msg.includes('关闭代理') || msg.includes('风险')).assertTrue();
  }));

  suite.addTest(new TestCase('getWarningMessage_warning_level', () => {
    const msg = EnhancedSecurityDetector.getWarningMessage('warning');
    expect(msg.length).assertTrue(msg.length > 0);
  }));

  suite.addTest(new TestCase('checks_are_independent', async () => {
    const [proxy, vpn, integrity] = await Promise.all([
      EnhancedSecurityDetector.checkProxy(),
      EnhancedSecurityDetector.checkVpn(),
      EnhancedSecurityDetector.checkDeviceIntegrity(),
    ]);
    expect(typeof proxy).assertEqual('boolean');
    expect(typeof vpn).assertEqual('boolean');
    expect(typeof integrity).assertEqual('boolean');
  }));

  return suite;
}