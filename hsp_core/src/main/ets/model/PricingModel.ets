// PricingModel.ets
// 定价模型 - 基于 MemberTier 的套餐方案配置
//
// ⚠️ SubscriptionTier 已废弃，迁移到 MemberStatus.ets 中的 MemberTier + ProductInfo
// 参见：MemberStatus.ets 中的 ProductInfo 接口

import { MemberTier, ProductInfo, TIER_DAILY_SCAN_LIMIT, TIER_MEMBER_LIMIT, TIER_WEEKLY_REPORT_LIMIT } from './MemberStatus';

// ==================== 会员套餐配置 ====================

export class ProductPlan {
  tier: MemberTier = MemberTier.FREE;
  productId: string = '';
  title: string = '';
  price: string = '';
  priceValue: number = 0;
  isYearly: boolean = false;
  features: string[] = [];
  limitations: string[] = [];
  badge: string = '';
}

function createProductPlan(
  tier: MemberTier, productId: string, title: string, price: string,
  priceValue: number, isYearly: boolean, features: string[], limitations: string[], badge: string
): ProductPlan {
  const plan: ProductPlan = new ProductPlan(
  plan.tier = tier;
  plan.productId = productId;
  plan.title = title;
  plan.price = price;
  plan.priceValue = priceValue;
  plan.isYearly = isYearly;
  plan.features = features;
  plan.limitations = limitations;
  plan.badge = badge;
  return plan;
}

/**
 * 产品方案列表（供订阅页展示）
 */
export const PRODUCT_PLANS: ProductPlan[] = [
  createProductPlan(MemberTier.FREE, 'free_tier', '免费版', '0元', 0, false,
    ['每天3次扫描', '1个家庭成员', '基础食品适配', '基础美食平衡', '分享卡'],
    ['扫描次数限制', '仅1位家庭成员', '无健康数据联动', '无周报'], ''),
  createProductPlan(MemberTier.PERSONAL, 'family_food_personal_yearly', '个人版', '29-49元/年', 39, true,
    ['无限扫码', '个人历史记录', '今日预算', '饮食平衡建议', '购物清单'],
    ['仅本人档案', '无家庭对比', '无健康数据联动'], '推荐'),
  createProductPlan(MemberTier.FAMILY, 'family_food_family_yearly', '家庭版', '89-129元/年', 109, true,
    ['最多4位家庭成员', '家庭购物清单', '家庭饮食周报', '儿童正餐保护', '美食平衡建议'],
    ['无深度可信度报告'], '最惠'),
  createProductPlan(MemberTier.PREMIUM, 'family_food_premium_yearly', '高级版', '129-199元/年', 169, true,
    ['无限家庭成员', '动态健康数据联动', '深度可信度报告', '个性化周报', '外卖透明度'],
    [], '尊享')
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
  const info: ProductInfo = new ProductInfo(
  info.productId = plan?.productId || `product_${tier}`;
  info.tier = tier;
  info.price = price || plan?.price || '0元';
  info.originalPrice = price || plan?.price || '0元';
  info.title = plan?.title || tier;
  info.description = plan?.features.join('、') || '';
  return info;
}
