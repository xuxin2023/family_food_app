// IapProductManager.test.ets
// 内购商品管理单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { IapProductManager, IapProductDefinition, IAP_PRODUCT_IDS } from 'hsp_service';
import { MemberTier } from 'hsp_core';

export default function iapProductTest(): TestSuite {
  const suite: TestSuite = new TestSuite(

  suite.addTest(new TestCase('getAllProducts returns 6 products', () => {
    const products = IapProductManager.getAllProducts();
    expect(products.length).assertEqual(6);
  }));

  suite.addTest(new TestCase('getSubscriptionProducts returns 4', () => {
    const subs = IapProductManager.getSubscriptionProducts();
    expect(subs.length).assertEqual(4);
    expect(subs.every((p: IapProductDefinition) => p.isSubscription)).assertTrue();
  }));

  suite.addTest(new TestCase('getConsumableProducts returns 2', () => {
    const cons = IapProductManager.getConsumableProducts();
    expect(cons.length).assertEqual(2);
    expect(cons.every((p: IapProductDefinition) => !p.isSubscription)).assertTrue();
  }));

  suite.addTest(new TestCase('getProductById returns correct product', () => {
    const p = IapProductManager.getProductById(IAP_PRODUCT_IDS.FAMILY_YEARLY);
    expect(p).assertTrue(p !== undefined);
    expect(p!.tier).assertEqual(MemberTier.FAMILY);
    expect(p!.isSubscription).assertTrue();
  }));

  suite.addTest(new TestCase('getProductById returns undefined for invalid id', () => {
    const p = IapProductManager.getProductById('invalid_product_id');
    expect(p).assertTrue(p === undefined);
  }));

  suite.addTest(new TestCase('getTierForProductId maps correctly', () => {
    expect(IapProductManager.getTierForProductId(IAP_PRODUCT_IDS.PERSONAL_MONTHLY)).assertEqual(MemberTier.PERSONAL);
    expect(IapProductManager.getTierForProductId(IAP_PRODUCT_IDS.PREMIUM_YEARLY)).assertEqual(MemberTier.PREMIUM);
    expect(IapProductManager.getTierForProductId(IAP_PRODUCT_IDS.TRANSPARENCY_REPORT)).assertEqual(null);
  }));

  suite.addTest(new TestCase('isSubscription returns correct values', () => {
    expect(IapProductManager.isSubscription(IAP_PRODUCT_IDS.PERSONAL_YEARLY)).assertTrue();
    expect(IapProductManager.isSubscription(IAP_PRODUCT_IDS.TRANSPARENCY_REPORT)).assertFalse();
  }));

  suite.addTest(new TestCase('isConsumable returns correct values', () => {
    expect(IapProductManager.isConsumable(IAP_PRODUCT_IDS.BRAND_TRACE)).assertTrue();
    expect(IapProductManager.isConsumable(IAP_PRODUCT_IDS.FAMILY_YEARLY)).assertFalse();
  }));

  suite.addTest(new TestCase('getSubscriptionIds returns 4 ids', () => {
    expect(IapProductManager.getSubscriptionIds().length).assertEqual(4);
  }));

  suite.addTest(new TestCase('getConsumableIds returns 2 ids', () => {
    expect(IapProductManager.getConsumableIds().length).assertEqual(2);
  }));

  suite.addTest(new TestCase('buildProductInfo generates valid ProductInfo', () => {
    const def = IapProductManager.getProductById(IAP_PRODUCT_IDS.FAMILY_YEARLY);
    expect(def).assertTrue(def !== undefined);
    const info = IapProductManager.buildProductInfo(def!, '¥69/年');
    expect(info.productId).assertEqual(IAP_PRODUCT_IDS.FAMILY_YEARLY);
    expect(info.title).assertEqual('家庭年度版');
    expect(info.price).assertEqual('¥69/年');
    expect(info.tier).assertEqual(MemberTier.FAMILY);
  }));

  suite.addTest(new TestCase('all subscription products have features', () => {
    for (const p of IapProductManager.getSubscriptionProducts()) {
      expect(p.features.length).assertTrue(p.features.length > 0,
        `${p.title} should have features`);
    }
  }));

  return suite;
}