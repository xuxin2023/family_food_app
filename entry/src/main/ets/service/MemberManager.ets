// MemberManager.ets
// 会员管理服务 - 权限矩阵、付费墙触发逻辑

import { SubscriptionTier } from '../model/PricingModel';

// ===== 付费墙触发信息 =====

export class PaywallTrigger {
  title: string = '';
  message: string = '';
  featureName: string = '';
  requiredTier: string = '';
  cta: string = '';
}

// ===== 功能权限定义 =====

interface FeatureAccess {
  featureName: string;
  requiredTier: SubscriptionTier;
  quotaLimit: number;  // -1 表示无限
}

// ===== 权限矩阵 =====

const FEATURE_ACCESS_MATRIX: FeatureAccess[] = [
  { featureName: 'scan', requiredTier: SubscriptionTier.FREE, quotaLimit: 3 },
  { featureName: 'scan_unlimited', requiredTier: SubscriptionTier.TRIAL_7DAY, quotaLimit: -1 },
  { featureName: 'member_add', requiredTier: SubscriptionTier.TRIAL_7DAY, quotaLimit: -1 },
  { featureName: 'weekly_report', requiredTier: SubscriptionTier.PERSONAL_YEAR, quotaLimit: -1 },
  { featureName: 'family_weekly_report', requiredTier: SubscriptionTier.FAMILY_STANDARD, quotaLimit: -1 },
  { featureName: 'health_data_sync', requiredTier: SubscriptionTier.FAMILY_STANDARD, quotaLimit: -1 },
  { featureName: 'basket_check', requiredTier: SubscriptionTier.FAMILY_STANDARD, quotaLimit: -1 },
  { featureName: 'child_protection', requiredTier: SubscriptionTier.TRIAL_7DAY, quotaLimit: -1 },
  { featureName: 'meal_balance', requiredTier: SubscriptionTier.FREE, quotaLimit: -1 },
  { featureName: 'meal_balance_advanced', requiredTier: SubscriptionTier.TRIAL_7DAY, quotaLimit: -1 },
  { featureName: 'transparency_report', requiredTier: SubscriptionTier.FAMILY_PREMIUM, quotaLimit: -1 },
  { featureName: 'shopping_list', requiredTier: SubscriptionTier.PERSONAL_YEAR, quotaLimit: -1 },
  { featureName: 'family_shopping_list', requiredTier: SubscriptionTier.FAMILY_STANDARD, quotaLimit: -1 },
  { featureName: 'export_data', requiredTier: SubscriptionTier.FAMILY_PREMIUM, quotaLimit: -1 },
  { featureName: 'history', requiredTier: SubscriptionTier.FREE, quotaLimit: -1 },
  { featureName: 'history_full', requiredTier: SubscriptionTier.PERSONAL_YEAR, quotaLimit: -1 },
];

// 付费墙配置
interface PaywallConfig {
  action: string;
  title: string;
  message: string;
  featureName: string;
  requiredTier: SubscriptionTier;
  cta: string;
}

const PAYWALL_TRIGGERS: PaywallConfig[] = [
  {
    action: 'scan_exceeded',
    title: '今日扫码已达上限',
    message: '免费版每天只能扫码3次。升级后全家人都能不限次使用，每个人都有自己的专属饮食建议。',
    featureName: '无限扫码',
    requiredTier: SubscriptionTier.TRIAL_7DAY,
    cta: '免费试用7天'
  },
  {
    action: 'add_member',
    title: '添加家人',
    message: '免费版仅支持1个成员。升级后可以添加爸爸/妈妈/孩子/我，每个人都有独立档案和个性化建议。',
    featureName: '多成员支持',
    requiredTier: SubscriptionTier.TRIAL_7DAY,
    cta: '解锁家庭版'
  },
  {
    action: 'weekly_report',
    title: '查看饮食周报',
    message: '周报功能需要升级后才能使用。了解一周饮食趋势，做更科学的饮食调整。',
    featureName: '饮食周报',
    requiredTier: SubscriptionTier.PERSONAL_YEAR,
    cta: '开通个人版'
  },
  {
    action: 'child_protection',
    title: '儿童正餐保护',
    message: '孩子饭前想吃零食？升级后可以设置儿童正餐保护规则，自动提醒孩子先吃正餐。',
    featureName: '儿童正餐保护',
    requiredTier: SubscriptionTier.TRIAL_7DAY,
    cta: '免费试用7天'
  },
  {
    action: 'health_sync',
    title: '健康数据联动',
    message: '连接华为健康数据，结合运动步数、睡眠质量等动态调整每日饮食预算。',
    featureName: '健康数据联动',
    requiredTier: SubscriptionTier.FAMILY_STANDARD,
    cta: '升级家庭版'
  },
  {
    action: 'basket_check',
    title: '一键购物篮检查',
    message: '升级后可以一次性检查整个购物篮的食品适配情况，一键了解全家人的适配建议。',
    featureName: '购物篮检查',
    requiredTier: SubscriptionTier.FAMILY_STANDARD,
    cta: '升级家庭版'
  },
  {
    action: 'transparency_report',
    title: '深度可信度报告',
    message: '升级到高级版后可以查看每款食品的深度数据可信度分析，了解数据来源和评分依据。',
    featureName: '深度可信度报告',
    requiredTier: SubscriptionTier.FAMILY_PREMIUM,
    cta: '升级高级版'
  },
  {
    action: 'export_data',
    title: '数据导出',
    message: '高级版支持导出家庭饮食数据报告，方便您做更深入的分析和记录。',
    featureName: '数据导出',
    requiredTier: SubscriptionTier.FAMILY_PREMIUM,
    cta: '升级高级版'
  }
];

const TIER_ORDER: SubscriptionTier[] = [
  SubscriptionTier.FREE,
  SubscriptionTier.TRIAL_7DAY,
  SubscriptionTier.PERSONAL_YEAR,
  SubscriptionTier.FAMILY_STANDARD,
  SubscriptionTier.FAMILY_PREMIUM
];

// ===== 单例 =====

let memberManagerInstance: MemberManager | null = null;

export class MemberManager {
  private currentTier: SubscriptionTier = SubscriptionTier.FREE;

  static getInstance(): MemberManager {
    if (memberManagerInstance === null) {
      memberManagerInstance = new MemberManager();
    }
    return memberManagerInstance;
  }

  /**
   * 设置当前会员等级
   */
  setTier(tier: SubscriptionTier): void {
    this.currentTier = tier;
  }

  /**
   * 检查功能是否有权限访问
   * @param feature 功能名，如 'scan', 'weekly_report', 'child_protection' 等
   * @returns true = 有权限，false = 被限制
   */
  checkCanAccess(feature: string): boolean {
    const entry = FEATURE_ACCESS_MATRIX.find(item => item.featureName === feature);
    if (entry === undefined) {
      return true; // 未知功能默认允许
    }
    const currentIndex = TIER_ORDER.indexOf(this.currentTier);
    const requiredIndex = TIER_ORDER.indexOf(entry.requiredTier);
    return currentIndex >= requiredIndex;
  }

  /**
   * 获取当前等级的成员数上限（-1表示无限）
   */
  getMemberLimit(): number {
    if (this.currentTier === SubscriptionTier.FREE) {
      return 1;
    }
    return -1;
  }

  /**
   * 获取当前等级的每日扫码上限（-1表示无限）
   */
  getDailyScanLimit(): number {
    if (this.currentTier === SubscriptionTier.FREE) {
      return 3;
    }
    return -1;
  }

  /**
   * 获取付费墙触发信息
   * @param action 触发动作，如 'scan_exceeded', 'add_member', 'weekly_report' 等
   * @returns PaywallTrigger | null（当前等级已有权限时返回null）
   */
  getPaywallTrigger(action: string): PaywallTrigger | null {
    const config = PAYWALL_TRIGGERS.find(item => item.action === action);
    if (config === undefined) {
      return null;
    }

    // 检查用户是否已有该功能权限
    const hasAccess = this.checkCanAccess(config.featureName);
    if (hasAccess) {
      return null; // 已有权限，不显示付费墙
    }

    const trigger = new PaywallTrigger();
    trigger.title = config.title;
    trigger.message = config.message;
    trigger.featureName = config.featureName;
    trigger.requiredTier = config.requiredTier;
    trigger.cta = config.cta;
    return trigger;
  }
}
