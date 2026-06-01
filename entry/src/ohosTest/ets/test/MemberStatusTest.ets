// MemberStatusTest.ets
// MemberStatus 单元测试 - 会员等级、权限、付费墙
// 验证 P0-1 修复：upgrade_member / meal_balance_advanced 功能配置

import { describe, it, expect } from '@ohos/hypium';
import {
  MemberTier,
  MemberStatus,
  PaywallTrigger,
  createDefaultMemberStatus,
  createMemberStatusForTier,
  hasTierAccess,
  getTierDisplayName,
  getPaywallTriggerForFeature,
  TIER_DAILY_SCAN_LIMIT,
  TIER_MEMBER_LIMIT,
  TIER_WEEKLY_REPORT_LIMIT
} from 'hsp_core';

export default function memberStatusTest() {
  describe('MemberTier', () => {
    it('tier_order_should_be_correct', 0, () => {
      expect(hasTierAccess(MemberTier.PREMIUM, MemberTier.FREE)).assertTrue();
      expect(hasTierAccess(MemberTier.PERSONAL, MemberTier.FAMILY)).assertFalse();
      expect(hasTierAccess(MemberTier.FAMILY, MemberTier.FAMILY)).assertTrue();
      expect(hasTierAccess(MemberTier.FREE, MemberTier.PREMIUM)).assertFalse();
    });

    it('getTierDisplayName_should_return_chinese_name', 0, () => {
      expect(getTierDisplayName(MemberTier.FREE)).assertEqual('免费版');
      expect(getTierDisplayName(MemberTier.PERSONAL)).assertEqual('个人版');
      expect(getTierDisplayName(MemberTier.FAMILY)).assertEqual('家庭版');
      expect(getTierDisplayName(MemberTier.PREMIUM)).assertEqual('高级版');
    });
  });

  describe('MemberStatus_create', () => {
    it('createDefaultMemberStatus_should_return_free_tier', 0, () => {
      const status: MemberStatus = createDefaultMemberStatus();
      expect(status.tier).assertEqual(MemberTier.FREE);
      expect(status.isTrialActive).assertTrue();
      expect(status.trialRemainingDays).assertEqual(3);
    });

    it('createMemberStatusForTier_should_set_correct_limits', 0, () => {
      const freeStatus: MemberStatus = createMemberStatusForTier(MemberTier.FREE, 0);
      expect(freeStatus.scansRemainingToday).assertEqual(3);
      expect(freeStatus.familyMembersRemaining).assertEqual(1);
      expect(freeStatus.weeklyReportsRemaining).assertEqual(0);

      const premiumStatus: MemberStatus = createMemberStatusForTier(MemberTier.PREMIUM, 365);
      expect(premiumStatus.scansRemainingToday).assertEqual(-1);
      expect(premiumStatus.familyMembersRemaining).assertEqual(-1);
      expect(premiumStatus.weeklyReportsRemaining).assertEqual(-1);
    });

    it('Observed_class_should_be_instantiable_and_mutable', 0, () => {
      const status: MemberStatus = new MemberStatus();
      expect(status.tier).assertEqual(MemberTier.FREE);
      expect(status.expiryDate).assertNull();

      status.tier = MemberTier.FAMILY;
      status.expiryDate = Date.now() + 86400000;
      expect(status.tier).assertEqual(MemberTier.FAMILY);
      expect(status.expiryDate).assertNull();
    });
  });

  describe('Paywall_config', () => {
    it('scan_feature_should_have_soft_limit_for_free', 0, () => {
      const trigger: PaywallTrigger | null = getPaywallTriggerForFeature('scan', MemberTier.FREE);
      expect(trigger === null).assertFalse();
      expect(trigger!.featureName).assertEqual('scan');
      expect(trigger!.requiredTier).assertEqual(MemberTier.PERSONAL);
      expect(trigger!.isSoftLimit).assertTrue();
    });

    it('getPaywallTrigger_should_return_null_when_tier_has_access', 0, () => {
      const trigger: PaywallTrigger | null = getPaywallTriggerForFeature('scan', MemberTier.PERSONAL);
      expect(trigger).assertNull();
    });

    it('add_member_should_require_personal', 0, () => {
      const trigger = getPaywallTriggerForFeature('add_member', MemberTier.FREE);
      expect(trigger === null).assertFalse();
      expect(trigger!.requiredTier).assertEqual(MemberTier.PERSONAL);
    });

    it('upgrade_member_should_be_configured', 0, () => {
      const trigger = getPaywallTriggerForFeature('upgrade_member', MemberTier.FREE);
      expect(trigger === null).assertFalse();
      expect(trigger!.featureName).assertEqual('upgrade_member');
      expect(trigger!.requiredTier).assertEqual(MemberTier.PERSONAL);
    });

    it('meal_balance_advanced_should_be_configured', 0, () => {
      const trigger = getPaywallTriggerForFeature('meal_balance_advanced', MemberTier.FREE);
      expect(trigger === null).assertFalse();
      expect(trigger!.featureName).assertEqual('meal_balance_advanced');
      expect(trigger!.isSoftLimit).assertTrue();
    });

    it('weekly_report_should_require_personal', 0, () => {
      const freeTrigger = getPaywallTriggerForFeature('weekly_report', MemberTier.FREE);
      expect(freeTrigger === null).assertFalse();
      expect(freeTrigger!.requiredTier).assertEqual(MemberTier.PERSONAL);

      const personalTrigger = getPaywallTriggerForFeature('weekly_report', MemberTier.PERSONAL);
      expect(personalTrigger).assertNull();
    });

    it('basket_check_should_require_family', 0, () => {
      const personalTrigger = getPaywallTriggerForFeature('basket_check', MemberTier.PERSONAL);
      expect(personalTrigger === null).assertFalse();
      expect(personalTrigger!.requiredTier).assertEqual(MemberTier.FAMILY);

      const familyTrigger = getPaywallTriggerForFeature('basket_check', MemberTier.FAMILY);
      expect(familyTrigger).assertNull();
    });

    it('transparency_report_should_be_hard_limit', 0, () => {
      const trigger = getPaywallTriggerForFeature('transparency_report', MemberTier.FREE);
      expect(trigger === null).assertFalse();
      expect(trigger!.isSoftLimit).assertFalse();
    });

    it('unknown_feature_should_return_null', 0, () => {
      const trigger = getPaywallTriggerForFeature('unknown_feature', MemberTier.FREE);
      expect(trigger).assertNull();
    });
  });
}
