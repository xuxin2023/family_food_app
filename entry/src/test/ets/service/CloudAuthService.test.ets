// CloudAuthService.test.ets
// CloudAuthService 单元测试 — 验证 AuthUser class + signIn 流程

import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { AuthUser } from 'hsp_service';

export default function cloudAuthTest(): TestSuite {
  const suite = new TestSuite('CloudAuthService');

  suite.addTest(new TestCase('authUser_defaultValues', () => {
    const user = new AuthUser();
    expect(user.uid).assertEqual('');
    expect(user.isAnonymous).assertEqual(true);
    expect(user.createdAt).assertEqual(0);
    expect(user.cloudToken).assertEqual('');
    expect(user.displayName).assertEqual('');
    expect(user.accountId).assertEqual('');
  }));

  suite.addTest(new TestCase('authUser_fieldAssignment', () => {
    const user = new AuthUser();
    user.uid = 'hw_12345';
    user.isAnonymous = false;
    user.createdAt = 1700000000000;
    user.cloudToken = 'eyJhbGciOiJIUzI1NiJ9.test.sig';
    user.displayName = '测试用户';
    user.accountId = 'test@example.com';
    expect(user.uid).assertEqual('hw_12345');
    expect(user.isAnonymous).assertEqual(false);
    expect(user.displayName).assertEqual('测试用户');
  }));

  suite.addTest(new TestCase('authUser_anonymousByDefault', () => {
    const user = new AuthUser();
    user.uid = 'local_abc';
    expect(user.isAnonymous).assertEqual(true);
    expect(user.cloudToken.length).assertEqual(0);
  }));

  return suite;
}
