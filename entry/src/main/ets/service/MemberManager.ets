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

const TAG = 'MemberManager';
const DOMAIN_ZERO = 0;

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
  { featureName: 'scan',               featureLabel: '扫码',           requiredTier: MemberTier.FREE,     freeLimitDesc: '每天3次' },
  { featureName: 'family_member',      featureLabel: '家庭成员',       requiredTier: MemberTier.FREE,     freeLimitDesc: '最多1人' },
  { featureName: 'history',            featureLabel: '历史记录',       requiredTier: MemberTier.FREE,     freeLimitDesc: '' },
  { featureName: 'alternative',        featureLabel: '替代品推荐',     requiredTier: MemberTier.PERSONAL, freeLimitDesc: '功能锁定' },
  { featureName: 'basket_check',       featureLabel: '购物篮检查',     requiredTier: MemberTier.PERSONAL, freeLimitDesc: '功能锁定' },
  { featureName: 'child_protection',   featureLabel: '儿童正餐保护',   requiredTier: MemberTier.FREE,     freeLimitDesc: '' },
  { featureName: 'meal_balance',       featureLabel: '美食平衡',       requiredTier: MemberTier.FREE,     freeLimitDesc: '每天3次' },
  { featureName: 'weekly_report',      featureLabel: '周报',           requiredTier: MemberTier.PERSONAL, freeLimitDesc: '功能锁定' },
  { featureName: 'family_weekly_report', featureLabel: '家庭周报',     requiredTier: MemberTier.FAMILY,   freeLimitDesc: '功能锁定' },
  { featureName: 'transparency_report', featureLabel: '透明度深度报告', requiredTier: MemberTier.FAMILY,   freeLimitDesc: '功能锁定' },
  { featureName: 'takeout_transparency', featureLabel: '外卖透明度',   requiredTier: MemberTier.PREMIUM,  freeLimitDesc: '功能锁定' },
  { featureName: 'brand_credibility',  featureLabel: '品牌信用等级',   requiredTier: MemberTier.PREMIUM,  freeLimitDesc: '功能锁定' },
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
    title: '今日扫码已达上限',
    message: '免费版每天只能扫码3次。升级后全家人都能不限次使用，每个人都有自己的专属饮食建议。',
    requiredTier: MemberTier.PERSONAL,
    cta: '解锁无限扫码',
    isSoftLimit: true
  },
  {
    featureName: 'family_member',
    title: '添加更多家庭成员',
    message: '免费版和个人版仅支持1位家庭成员。升级家庭版后，全家人都能拥有独立档案和个性化建议。',
    requiredTier: MemberTier.FAMILY,
    cta: '升级家庭版',
    isSoftLimit: true
  },
  {
    featureName: 'alternative',
    title: '查看替代品推荐',
    message: '替代品推荐功能需要升级才能使用。发现更健康的选择，帮家人做出更好的饮食决策。',
    requiredTier: MemberTier.PERSONAL,
    cta: '开通个人版',
    isSoftLimit: true
  },
  {
    featureName: 'basket_check',
    title: '一键购物篮检查',
    message: '升级后可以一次性检查整个购物篮的食品适配情况，一键了解全家人的适配建议。',
    requiredTier: MemberTier.PERSONAL,
    cta: '开通个人版',
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
    message: '透明度深度报告需要家庭版以上才能查看。了解每款食品的数据来源和评分依据。',
    requiredTier: MemberTier.FAMILY,
    cta: '升级家庭版',
    isSoftLimit: false
  },
  {
    featureName: 'takeout_transparency',
    title: '外卖食品透明度',
    message: '高级版专属功能。查看外卖食品的营养数据和添加剂信息，在外卖场景也能吃得明白。',
    requiredTier: MemberTier.PREMIUM,
    cta: '升级高级版',
    isSoftLimit: false
  },
  {
    featureName: 'brand_credibility',
    title: '品牌信用等级',
    message: '高级版专属功能。查看品牌生产信息、SC证书编号、委托商信息等溯源数据。',
    requiredTier: MemberTier.PREMIUM,
    cta: '升级高级版',
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
