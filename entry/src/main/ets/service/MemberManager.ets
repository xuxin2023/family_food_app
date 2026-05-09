// MemberManager.ets
// 会员管理服务 - 功能权限矩阵、鉴权判断、付费墙触发逻辑
//
// 权限矩阵：
// | 功能                   | 免费      | 个人     | 家庭     | 高级     |
// |------------------------|-----------|----------|----------|----------|
// | 扫码                   | 3次/天    | 无限     | 无限     | 无限     |
// | 家庭成员               | 1人       | 1人      | 4人      | 6人      |
// | 历史记录               | ✅        | ✅       | ✅       | ✅       |
// | 替代品推荐             | ❌        | ✅       | ✅       | ✅       |
// | 购物篮检查             | ❌        | ✅       | ✅       | ✅       |
// | 儿童正餐保护           | ✅        | ✅       | ✅       | ✅       |
// | 美食平衡               | 3次/天    | 无限     | 无限     | 无限     |
// | 周报                   | ❌        | 个人     | 家庭     | 家庭     |
// | 透明度深度报告         | ❌        | ❌       | ✅       | ✅       |
// | 外卖透明度             | ❌        | ❌       | ❌       | ✅       |
// | 品牌信用等级           | ❌        | ❌       | ❌       | ✅       |

import { MemberTier, PaywallTrigger, hasTierAccess, getTierDisplayName } from '../model/MemberStatus';
import { StringRes } from '../constants/StringRes';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'MemberManager';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

// ==================== 功能权限定义 ====================

/**
 * 功能访问权限条目
 */
export interface FeatureAccess {
  /** 功能名（英文标识，用于程序匹配） */
  featureName: string;
  /** 功能展示名称 */
  featureLabel: string;
  /** 当前等级是否可访问 */
  isAccessible: boolean;
  /** 该功能所需的最低等级 */
  requiredTier: MemberTier;
  /** 当前等级 */
  currentTier: MemberTier;
  /** 免费版的限制说明（次数/人数等） */
  freeLimitDesc: string;
}

interface FeatureMatrixEntry {
  featureName: string;
  featureLabel: string;
  requiredTier: MemberTier;
  freeLimitDesc: string;
}

/**
 * 功能权限矩阵
 */
const FEATURE_MATRIX: FeatureMatrixEntry[] = [
  { featureName: 'scan',               featureLabel: StringRes.FEATURE_SCAN,           requiredTier: MemberTier.FREE,     freeLimitDesc: StringRes.LIMIT_DAILY_3 },
  { featureName: 'family_member',      featureLabel: StringRes.FEATURE_FAMILY_MEMBER,  requiredTier: MemberTier.FREE,     freeLimitDesc: StringRes.LIMIT_MAX_1 },
  { featureName: 'history',            featureLabel: StringRes.FEATURE_HISTORY,        requiredTier: MemberTier.FREE,     freeLimitDesc: '' },
  { featureName: 'alternative',        featureLabel: StringRes.FEATURE_ALTERNATIVE,    requiredTier: MemberTier.PERSONAL, freeLimitDesc: StringRes.LIMIT_LOCKED },
  { featureName: 'basket_check',       featureLabel: StringRes.FEATURE_BASKET,         requiredTier: MemberTier.PERSONAL, freeLimitDesc: StringRes.LIMIT_LOCKED },
  { featureName: 'child_protection',   featureLabel: StringRes.FEATURE_CHILD_PROTECTION, requiredTier: MemberTier.FREE,   freeLimitDesc: '' },
  { featureName: 'meal_balance',       featureLabel: StringRes.FEATURE_MEAL_BALANCE,   requiredTier: MemberTier.FREE,     freeLimitDesc: StringRes.LIMIT_DAILY_3 },
  { featureName: 'weekly_report',      featureLabel: StringRes.FEATURE_WEEKLY_REPORT,  requiredTier: MemberTier.PERSONAL, freeLimitDesc: StringRes.LIMIT_LOCKED },
  { featureName: 'family_weekly_report', featureLabel: '家庭周报',                      requiredTier: MemberTier.FAMILY,   freeLimitDesc: StringRes.LIMIT_LOCKED },
  { featureName: 'transparency_report', featureLabel: StringRes.FEATURE_TRANSPARENCY,  requiredTier: MemberTier.FAMILY,   freeLimitDesc: StringRes.LIMIT_LOCKED },
  { featureName: 'takeout_transparency', featureLabel: '外卖透明度',                    requiredTier: MemberTier.PREMIUM,  freeLimitDesc: StringRes.LIMIT_LOCKED },
  { featureName: 'brand_credibility',  featureLabel: '品牌信用等级',                    requiredTier: MemberTier.PREMIUM,  freeLimitDesc: StringRes.LIMIT_LOCKED },
];

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
    title: StringRes.PW_SCAN_TITLE,
    message: StringRes.PW_SCAN_MSG,
    requiredTier: MemberTier.PERSONAL,
    cta: StringRes.PW_SCAN_CTA,
    isSoftLimit: true
  },
  {
    featureName: 'family_member',
    title: StringRes.PW_FAMILY_TITLE,
    message: StringRes.PW_FAMILY_MSG,
    requiredTier: MemberTier.FAMILY,
    cta: StringRes.PW_FAMILY_CTA,
    isSoftLimit: true
  },
  {
    featureName: 'alternative',
    title: StringRes.PW_ALT_TITLE,
    message: StringRes.PW_ALT_MSG,
    requiredTier: MemberTier.PERSONAL,
    cta: StringRes.PW_ALT_CTA,
    isSoftLimit: true
  },
  {
    featureName: 'basket_check',
    title: StringRes.PW_BASKET_TITLE,
    message: StringRes.PW_BASKET_MSG,
    requiredTier: MemberTier.PERSONAL,
    cta: StringRes.PW_BASKET_CTA,
    isSoftLimit: true
  },
  {
    featureName: 'weekly_report',
    title: StringRes.PW_WEEKLY_TITLE,
    message: StringRes.PW_WEEKLY_MSG,
    requiredTier: MemberTier.PERSONAL,
    cta: StringRes.PW_WEEKLY_CTA,
    isSoftLimit: true
  },
  {
    featureName: 'family_weekly_report',
    title: StringRes.PW_FAMILY_WEEKLY_TITLE,
    message: StringRes.PW_FAMILY_WEEKLY_MSG,
    requiredTier: MemberTier.FAMILY,
    cta: StringRes.PW_FAMILY_WEEKLY_CTA,
    isSoftLimit: true
  },
  {
    featureName: 'transparency_report',
    title: StringRes.PW_TRANSPARENCY_TITLE,
    message: StringRes.PW_TRANSPARENCY_MSG,
    requiredTier: MemberTier.FAMILY,
    cta: StringRes.PW_TRANSPARENCY_CTA,
    isSoftLimit: false
  },
  {
    featureName: 'takeout_transparency',
    title: StringRes.PW_TAKEOUT_TITLE,
    message: StringRes.PW_TAKEOUT_MSG,
    requiredTier: MemberTier.PREMIUM,
    cta: StringRes.PW_TAKEOUT_CTA,
    isSoftLimit: false
  },
  {
    featureName: 'brand_credibility',
    title: StringRes.PW_BRAND_TITLE,
    message: StringRes.PW_BRAND_MSG,
    requiredTier: MemberTier.PREMIUM,
    cta: StringRes.PW_BRAND_CTA,
    isSoftLimit: false
  }
];

// ==================== 等级排序 ====================

const TIER_ORDER: MemberTier[] = [
  MemberTier.FREE,
  MemberTier.PERSONAL,
  MemberTier.FAMILY,
  MemberTier.PREMIUM
];

// ==================== 单例 ====================

let memberManagerInstance: MemberManager | null = null;

export class MemberManager {
  private currentTier: MemberTier = MemberTier.FREE;

  static getInstance(): MemberManager {
    if (memberManagerInstance === null) {
      memberManagerInstance = new MemberManager();
    }
    return memberManagerInstance;
  }

  /**
   * 设置当前会员等级
   */
  setTier(tier: MemberTier): void {
    this.currentTier = tier;
  }

  /**
   * 获取当前会员等级
   */
  getCurrentTier(): MemberTier {
    return this.currentTier;
  }

  // ==================== 功能鉴权 ====================

  /**
   * 根据当前会员等级判断是否有权限使用某功能
   *
   * @param feature 功能名（如 'scan', 'alternative', 'weekly_report' 等）
   * @returns null 表示有权限，返回 PaywallTrigger 表示需要拦截并展示付费墙
   */
  checkCanAccess(feature: string): PaywallTrigger | null {
    // 在权限矩阵中查找该功能
    const entry = FEATURE_MATRIX.find(item => item.featureName === feature);
    if (entry === undefined) {
      // 未知功能默认允许访问
      return null;
    }

    // 检查当前等级是否满足要求
    const hasAccess = hasTierAccess(this.currentTier, entry.requiredTier);
    if (hasAccess) {
      return null;  // 有权限，不拦截
    }

    // 生成付费墙信息
    const config = PAYWALL_CONFIGS.find(item => item.featureName === feature);
    if (config !== undefined) {
      return {
        title: config.title,
        message: config.message,
        featureName: config.featureName,
        requiredTier: config.requiredTier,
        cta: config.cta,
        isSoftLimit: config.isSoftLimit
      };
    }

    // 兜底：未配置付费墙文案时，使用自动生成文案
    const requiredName = getTierDisplayName(entry.requiredTier);
    return {
      title: '该功能已锁定',
      message: `当前版本不支持"${entry.featureLabel}"。升级至${requiredName}即可解锁。`,
      featureName: feature,
      requiredTier: entry.requiredTier,
      cta: `升级${requiredName}`,
      isSoftLimit: true
    };
  }

  // ==================== 权限矩阵查询 ====================

  /**
   * 返回所有功能的权限矩阵
   *
   * 用于在页面中展示功能权限对比表
   *
   * @returns FeatureAccess[] 所有功能的权限状态
   */
  getAllFeatures(): FeatureAccess[] {
    return FEATURE_MATRIX.map((entry: FeatureMatrixEntry): FeatureAccess => {
      const result: FeatureAccess = {
        featureName: entry.featureName,
        featureLabel: entry.featureLabel,
        isAccessible: hasTierAccess(this.currentTier, entry.requiredTier),
        requiredTier: entry.requiredTier,
        currentTier: this.currentTier,
        freeLimitDesc: entry.freeLimitDesc
      };
      return result;
    });
  }

  /**
   * 获取当前等级的扫码次数上限
   * @returns -1 表示无限
   */
  getDailyScanLimit(): number {
    if (this.currentTier === MemberTier.FREE) {
      return 3;
    }
    return -1;
  }

  /**
   * 获取当前等级的家庭成员数上限
   * @returns -1 表示无限
   */
  getMemberLimit(): number {
    switch (this.currentTier) {
      case MemberTier.FREE:
      case MemberTier.PERSONAL:
        return 1;
      case MemberTier.FAMILY:
        return 4;
      case MemberTier.PREMIUM:
        return 6;
      default:
        return 1;
    }
  }

  /**
   * 获取当前等级的每日美食平衡次数上限
   * @returns -1 表示无限
   */
  getDailyMealBalanceLimit(): number {
    if (this.currentTier === MemberTier.FREE) {
      return 3;
    }
    return -1;
  }

  /**
   * 获取指定功能在当前等级下的描述文案
   * 例如：'每天3次', '最多1人', '功能锁定' 等
   */
  getFeatureLimitDesc(feature: string): string {
    const entry = FEATURE_MATRIX.find(item => item.featureName === feature);
    if (entry === undefined) {
      return '';
    }
    const hasAccess = hasTierAccess(this.currentTier, entry.requiredTier);
    if (hasAccess) {
      return this.currentTier === MemberTier.FREE ? entry.freeLimitDesc : '不限';
    }
    return '功能锁定';
  }
}