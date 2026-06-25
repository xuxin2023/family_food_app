// IapProductManager.ets
// 内购商品管理 — 商品定义/价格/等级映射/套餐列表
// 纯数据层，延迟引用 IAPKit 枚举避免模块初始化时 kit 不可用导致 TypeError

import { MemberTier, ProductInfo } from 'hsp_core';

export type IapProductType = 'CONSUMABLE' | 'NONRENEWABLE' | 'AUTORENEWABLE';

export function toIapKitProductType(t: IapProductType): number {
  switch (t) {
    case 'CONSUMABLE':
      return 0;
    case 'NONRENEWABLE':
      return 2;
    case 'AUTORENEWABLE':
      return 1;
    default:
      return 0;
  }
}

export interface IapProductDefinition {
  productId: string;
  tier: MemberTier | null;
  price: string;
  originalPrice: string;
  title: string;
  description: string;
  iapProductType: IapProductType;
  isSubscription: boolean;
  features: string[];
}

export interface IapProductIds {
  PERSONAL_MONTHLY: string;
  PERSONAL_YEARLY: string;
  FAMILY_YEARLY: string;
  PREMIUM_YEARLY: string;
  TRANSPARENCY_REPORT: string;
  BRAND_TRACE: string;
}

export const PRODUCT_IDS: IapProductIds = {
  PERSONAL_MONTHLY: 'family_food_personal_monthly',
  PERSONAL_YEARLY: 'family_food_personal_yearly',
  FAMILY_YEARLY: 'family_food_family_yearly',
  PREMIUM_YEARLY: 'family_food_premium_yearly',
  TRANSPARENCY_REPORT: 'family_food_transparency_report',
  BRAND_TRACE: 'family_food_brand_trace',
};

export const ALL_PRODUCT_IDS: string[] = [
  PRODUCT_IDS.PERSONAL_MONTHLY, PRODUCT_IDS.PERSONAL_YEARLY,
  PRODUCT_IDS.FAMILY_YEARLY, PRODUCT_IDS.PREMIUM_YEARLY,
  PRODUCT_IDS.TRANSPARENCY_REPORT, PRODUCT_IDS.BRAND_TRACE,
];

const PRODUCT_DEFINITIONS: IapProductDefinition[] = [
  {
    productId: PRODUCT_IDS.PERSONAL_MONTHLY, tier: MemberTier.PERSONAL,
    price: '¥9/月', originalPrice: '', title: '个人月度版',
    description: '无限扫码、个人历史记录、今日预算、饮食平衡建议',
    iapProductType: 'NONRENEWABLE', isSubscription: true,
    features: ['无限扫码', '历史记录', '今日预算', '饮食平衡'],
  },
  {
    productId: PRODUCT_IDS.PERSONAL_YEARLY, tier: MemberTier.PERSONAL,
    price: '¥39/年', originalPrice: '¥108', title: '个人年度版',
    description: '无限扫码、历史记录、今日预算、平衡建议、购物清单',
    iapProductType: 'NONRENEWABLE', isSubscription: true,
    features: ['无限扫码', '历史记录', '购物清单', '今日预算'],
  },
  {
    productId: PRODUCT_IDS.FAMILY_YEARLY, tier: MemberTier.FAMILY,
    price: '¥69/年', originalPrice: '¥199', title: '家庭年度版',
    description: '不限家庭成员、家庭购物清单、家庭饮食周报、儿童正餐保护',
    iapProductType: 'NONRENEWABLE', isSubscription: true,
    features: ['家庭成员不限', '家庭购物清单', '饮食周报', '儿童正餐保护'],
  },
  {
    productId: PRODUCT_IDS.PREMIUM_YEARLY, tier: MemberTier.PREMIUM,
    price: '¥129/年', originalPrice: '¥299', title: '高级家庭版',
    description: '深度可信度报告、动态健康联动、个性化周报、品牌信用等级',
    iapProductType: 'NONRENEWABLE', isSubscription: true,
    features: ['可信度报告', '健康数据联动', '个性化周报', '品牌信用'],
  },
  {
    productId: PRODUCT_IDS.TRANSPARENCY_REPORT, tier: null,
    price: '¥3.9/次', originalPrice: '', title: '透明度深度报告',
    description: '查看食品数据可信度分析、数据来源和评分依据',
    iapProductType: 'CONSUMABLE', isSubscription: false,
    features: ['数据可信度分析', '来源追溯'],
  },
  {
    productId: PRODUCT_IDS.BRAND_TRACE, tier: null,
    price: '¥2.9/次', originalPrice: '', title: '品牌溯源查询',
    description: '查询品牌生产信息、SC证书编号、委托商信息等溯源数据',
    iapProductType: 'CONSUMABLE', isSubscription: false,
    features: ['品牌溯源', 'SC证书查询'],
  },
];

export class IapProductManager {
  static getAllProducts(): IapProductDefinition[] {
    return [...PRODUCT_DEFINITIONS];
  }

  static getSubscriptionProducts(): IapProductDefinition[] {
    return PRODUCT_DEFINITIONS.filter(p => p.isSubscription);
  }

  static getConsumableProducts(): IapProductDefinition[] {
    return PRODUCT_DEFINITIONS.filter(p => !p.isSubscription);
  }

  static getProductById(productId: string): IapProductDefinition | undefined {
    return PRODUCT_DEFINITIONS.find(p => p.productId === productId);
  }

  static getTierForProductId(productId: string): MemberTier | null {
    const def = PRODUCT_DEFINITIONS.find(p => p.productId === productId);
    return def?.tier ?? null;
  }

  static getSubscriptionIds(): string[] {
    return PRODUCT_DEFINITIONS.filter(p => p.isSubscription).map(p => p.productId);
  }

  static getConsumableIds(): string[] {
    return PRODUCT_DEFINITIONS.filter(p => !p.isSubscription).map(p => p.productId);
  }

  static isSubscription(productId: string): boolean {
    const def = PRODUCT_DEFINITIONS.find(p => p.productId === productId);
    return def?.isSubscription ?? false;
  }

  static isConsumable(productId: string): boolean {
    return !IapProductManager.isSubscription(productId);
  }

  static buildProductInfo(def: IapProductDefinition, iapPrice?: string): ProductInfo {
    const info: ProductInfo = new ProductInfo()
    info.productId = def.productId;
    info.title = def.title;
    info.description = def.description;
    info.price = iapPrice ?? def.price;
    info.originalPrice = def.originalPrice;
    info.tier = def.tier ?? MemberTier.FREE;
    info.isSubscription = def.isSubscription;
    return info;
  }
}
