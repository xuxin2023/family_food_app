// PricingModel.ets
// 定价模型 - 基于 MemberTier 的套餐方案配置
//
// ⚠️ SubscriptionTier 已废弃，迁移到 MemberStatus.ets 中的 MemberTier + ProductInfo
// 参见：MemberStatus.ets 中的 ProductInfo 接口

import { MemberTier, ProductInfo, TIER_DAILY_SCAN_LIMIT, TIER_MEMBER_LIMIT, TIER_WEEKLY_REPORT_LIMIT } from './MemberStatus';

// ==================== 会员套餐配置 ====================

export interface ProductPlan {
  tier: MemberTier;
  productId: string;
  title: string;
  price: string;
  priceValue: number;
  isYearly: boolean;
  features: string[];
  limitations: string[];
  badge: string;
}

/**
 * 产品方案列表（供订阅页展示）
 */
export const PRODUCT_PLANS: ProductPlan[] = [
  {
    tier: MemberTier.FREE,
    productId: 'free_tier',
    title: '免费版',
    price: '0元',
    priceValue: 0,
    isYearly: false,
    features: [
      '每天3次扫描',
      '1个家庭成员',
      '基础食品适配',
      '基础美食平衡',
      '分享卡'
    ],
    limitations: [
      '扫描次数限制',
      '仅1位家庭成员',
      '无健康数据联动',
      '无周报'
    ],
    badge: ''
  },
  {
    tier: MemberTier.PERSONAL,
    productId: 'family_food_personal_yearly',
    title: '个人版',
    price: '29-49元/年',
    priceValue: 39,
    isYearly: true,
    features: [
      '无限扫码',
      '个人历史记录',
      '今日预算',
      '饮食平衡建议',
      '购物清单'
    ],
    limitations: [
      '仅本人档案',
      '无家庭对比',
      '无健康数据联动'
    ],
    badge: '推荐'
  },
  {
    tier: MemberTier.FAMILY,
    productId: 'family_food_family_yearly',
    title: '家庭版',
    price: '89-129元/年',
    priceValue: 109,
    isYearly: true,
    features: [
      '最多4位家庭成员',
      '家庭购物清单',
      '家庭饮食周报',
      '儿童正餐保护',
      '美食平衡建议'
    ],
    limitations: [
      '无深度可信度报告'
    ],
    badge: '最惠'
  },
  {
    tier: MemberTier.PREMIUM,
    productId: 'family_food_premium_yearly',
    title: '高级版',
    price: '129-199元/年',
    priceValue: 169,
    isYearly: true,
    features: [
      '无限家庭成员',
      '动态健康数据联动',
      '深度可信度报告',
      '个性化周报',
      '外卖透明度'
    ],
    limitations: [],
    badge: '尊享'
  }
];

/**
 * 根据 MemberTier 获取对应的产品方案
 */
export function getProductPlanForTier(tier: MemberTier): ProductPlan | null {
  return PRODUCT_PLANS.find(p => p.tier === tier) || null;
}

/**
 * 获取会员套餐的 ProductInfo（供 IAP 使用）
 */
export function getProductInfoForTier(tier: MemberTier, price: string): ProductInfo {
  const plan = getProductPlanForTier(tier);
  return {
    productId: plan?.productId || `product_${tier}`,
    tier,
    price: price || plan?.price || '0元',
    originalPrice: price || plan?.price || '0元',
    title: plan?.title || tier,
    description: plan?.features.join('、') || ''
  };
}
