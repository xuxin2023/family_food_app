// MemberStatus.ets
// 会员状态底层数据结构 - 定义会员等级枚举、状态接口、付费墙触发信息、商品信息、购买结果

/**
 * 会员等级枚举
 * 按权限由低到高排列
 */
export enum MemberTier {
  FREE = 'free',
  PERSONAL = 'personal',
  FAMILY = 'family',
  PREMIUM = 'premium'
}

/**
 * 会员当前状态
 */
export interface MemberStatus {
  /** 当前会员等级 */
  tier: MemberTier;
  /** 今日剩余扫码次数（-1表示无限） */
  scansRemainingToday: number;
  /** 剩余可添加家庭成员数（-1表示无限） */
  familyMembersRemaining: number;
  /** 会员到期时间戳（null表示永久有效或免费版） */
  expiryDate: number | null;
  /** 试用期是否激活 */
  isTrialActive: boolean;
  /** 试用剩余天数 */
  trialRemainingDays: number;
  /** 本周剩余周报生成次数（-1表示无限） */
  weeklyReportsRemaining: number;
}

/**
 * 付费墙触发信息
 */
export interface PaywallTrigger {
  /** 弹窗标题 */
  title: string;
  /** 弹窗描述文案 */
  message: string;
  /** 受限功能名称 */
  featureName: string;
  /** 解锁该功能所需的最低会员等级 */
  requiredTier: MemberTier;
  /** 按钮文案 */
  cta: string;
  /** 是否为柔性限制（true=可跳过/可关闭，false=硬性拦截） */
  isSoftLimit: boolean;
}

/**
 * 商品信息
 */
export interface ProductInfo {
  /** 商品ID */
  productId: string;
  /** 对应会员等级 */
  tier: MemberTier;
  /** 价格文字（如 '¥29/年'） */
  price: string;
  /** 原价文字（用于划线价展示，无促销时与price相同） */
  originalPrice: string;
  /** 商品标题 */
  title: string;
  /** 商品描述 */
  description: string;
}

/**
 * 购买结果
 */
export interface PurchaseResult {
  /** 是否成功 */
  success: boolean;
  /** 商品ID */
  productId: string;
  /** 错误码（成功时为0） */
  errorCode: number;
  /** 错误消息 */
  errorMessage: string;
}

// ==================== 等级排序工具 ====================

/** 等级排序数组（索引越大等级越高） */
const TIER_ORDER: MemberTier[] = [
  MemberTier.FREE,
  MemberTier.PERSONAL,
  MemberTier.FAMILY,
  MemberTier.PREMIUM
];

/**
 * 获取会员等级在排序中的索引
 */
export function getTierIndex(tier: MemberTier): number {
  const index = TIER_ORDER.indexOf(tier);
  return index >= 0 ? index : -1;
}

/**
 * 判断当前等级是否达到或超过目标等级
 * @param currentTier 当前等级
 * @param requiredTier 目标等级
 * @returns true表示有权限
 */
export function hasTierAccess(currentTier: MemberTier, requiredTier: MemberTier): boolean {
  return getTierIndex(currentTier) >= getTierIndex(requiredTier);
}

/**
 * 根据等级获取友好中文名称
 */
export function getTierDisplayName(tier: MemberTier): string {
  switch (tier) {
    case MemberTier.FREE:
      return '免费版';
    case MemberTier.PERSONAL:
      return '个人版';
    case MemberTier.FAMILY:
      return '家庭版';
    case MemberTier.PREMIUM:
      return '高级版';
    default:
      return '未知';
  }
}

// ==================== 会员等级权益配置 ====================

/**
 * 各等级每日扫码次数（-1表示无限）
 */
export const TIER_DAILY_SCAN_LIMIT: Map<string, number> = new Map([
  [MemberTier.FREE, 3],
  [MemberTier.PERSONAL, -1],
  [MemberTier.FAMILY, -1],
  [MemberTier.PREMIUM, -1]
]);

/**
 * 各等级可添加家庭成员数（-1表示无限）
 */
export const TIER_MEMBER_LIMIT: Map<string, number> = new Map([
  [MemberTier.FREE, 1],
  [MemberTier.PERSONAL, 1],
  [MemberTier.FAMILY, 4],
  [MemberTier.PREMIUM, -1]
]);

/**
 * 各等级每周周报次数（-1表示无限）
 */
export const TIER_WEEKLY_REPORT_LIMIT: Map<string, number> = new Map([
  [MemberTier.FREE, 0],
  [MemberTier.PERSONAL, -1],
  [MemberTier.FAMILY, -1],
  [MemberTier.PREMIUM, -1]
]);

/**
 * 各等级试用天数
 */
export const TIER_TRIAL_DAYS: Map<string, number> = new Map([
  [MemberTier.FREE, 3],
  [MemberTier.PERSONAL, 0],
  [MemberTier.FAMILY, 7],
  [MemberTier.PREMIUM, 14]
]);

// ==================== 默认值工厂 ====================

/**
 * 创建默认会员状态（免费版初始状态）
 * 统一委托给 createMemberStatusForTier，确保与配置表一致
 */
export function createDefaultMemberStatus(): MemberStatus {
  return createMemberStatusForTier(MemberTier.FREE, 0);
}

/**
 * 根据等级创建对应的会员状态
 * @param tier 目标等级
 * @param expiryDays 有效期天数（付费版适用，免费版传0）
 */
export function createMemberStatusForTier(tier: MemberTier, expiryDays: number): MemberStatus {
  const scanLimit = TIER_DAILY_SCAN_LIMIT.get(tier) || 0;
  const memberLimit = TIER_MEMBER_LIMIT.get(tier) || 0;
  const reportLimit = TIER_WEEKLY_REPORT_LIMIT.get(tier) || 0;
  const trialDays = TIER_TRIAL_DAYS.get(tier) || 0;

  let expiryDate: number | null = null;
  if (expiryDays > 0) {
    expiryDate = Date.now() + expiryDays * 24 * 60 * 60 * 1000;
  }

  return {
    tier: tier,
    scansRemainingToday: scanLimit,
    familyMembersRemaining: memberLimit,
    expiryDate: expiryDate,
    isTrialActive: trialDays > 0,
    trialRemainingDays: trialDays,
    weeklyReportsRemaining: reportLimit
  };
}

// ==================== 付费墙配置 ====================

interface PaywallConfig {
  featureName: string;
  title: string;
  message: string;
  requiredTier: MemberTier;
  cta: string;
  isSoftLimit: boolean;
}

const PAYWALL_CONFIGS: PaywallConfig[] = [
  {
    featureName: 'scan',
    title: '今日扫码已达上限',
    message: '免费版每天只能扫码3次。升级后全家人都能不限次使用，每个人都有自己的专属饮食建议。',
    requiredTier: MemberTier.PERSONAL,
    cta: '解锁无限扫码',
    isSoftLimit: true
  },
  {
    featureName: 'add_member',
    title: '添加更多家庭成员',
    message: '免费版和个人版仅支持1位家庭成员。升级家庭版后，全家人都能拥有独立档案和个性化建议。',
    requiredTier: MemberTier.FAMILY,
    cta: '升级家庭版',
    isSoftLimit: true
  },
  {
    featureName: 'weekly_report',
    title: '查看饮食周报',
    message: '周报功能需要升级后才能使用。了解一周饮食趋势，做更科学的饮食调整。',
    requiredTier: MemberTier.PERSONAL,
    cta: '开通个人版',
    isSoftLimit: true
  },
  {
    featureName: 'family_weekly_report',
    title: '家庭饮食周报',
    message: '家庭版支持查看全家人的饮食周报，直观了解每位家庭成员的饮食健康状况。',
    requiredTier: MemberTier.FAMILY,
    cta: '升级家庭版',
    isSoftLimit: true
  },
  {
    featureName: 'transparency_report',
    title: '深度可信度报告',
    message: '高级版支持查看每款食品的深度数据可信度分析，了解数据来源和评分依据。',
    requiredTier: MemberTier.PREMIUM,
    cta: '升级高级版',
    isSoftLimit: false
  },
  {
    featureName: 'health_data_sync',
    title: '健康数据联动',
    message: '连接华为健康数据，结合运动步数、睡眠质量等动态调整每日饮食预算。',
    requiredTier: MemberTier.FAMILY,
    cta: '升级家庭版',
    isSoftLimit: true
  },
  {
    featureName: 'priority_update',
    title: '优先数据更新',
    message: '高级版用户享有食品数据库优先更新权限，第一时间获取最新的食品数据和评分。',
    requiredTier: MemberTier.PREMIUM,
    cta: '升级高级版',
    isSoftLimit: false
  },
  {
    featureName: 'basket_check',
    title: '购物篮健康检查',
    message: '购物篮功能可以一次性检查您选购的所有食品，分析整体营养搭配是否均衡。',
    requiredTier: MemberTier.FAMILY,
    cta: '升级家庭版',
    isSoftLimit: true
  }
];

/**
 * 根据功能名获取付费墙触发信息
 * @param feature 功能名（如 'scan', 'add_member', 'weekly_report' 等）
 * @param currentTier 当前会员等级
 * @returns PaywallTrigger | null（当前等级已有权限时返回null）
 */
export function getPaywallTriggerForFeature(feature: string, currentTier: MemberTier): PaywallTrigger | null {
  const config = PAYWALL_CONFIGS.find(item => item.featureName === feature);
  if (config === undefined) {
    return null;
  }

  // 如果当前等级已满足要求，不显示付费墙
  if (hasTierAccess(currentTier, config.requiredTier)) {
    return null;
  }

  return {
    title: config.title,
    message: config.message,
    featureName: config.featureName,
    requiredTier: config.requiredTier,
    cta: config.cta,
    isSoftLimit: config.isSoftLimit
  };
}
