// IapService.ets
// 内购服务 - 管理会员状态、商品查询、购买流程与每日扫码次数

import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { SubscriptionTier, PricingService, PRICING_PLANS } from '../model/PricingModel';

const TAG = 'IapService';
const DOMAIN_ZERO = 0;

// ===== 商品ID枚举 =====

export enum IapProductId {
  TRIAL_7DAY = 'com.familyfood.trial_7day',
  PERSONAL_YEAR = 'com.familyfood.personal_year',
  FAMILY_STANDARD = 'com.familyfood.family_standard',
  FAMILY_PREMIUM = 'com.familyfood.family_premium'
}

const PRODUCT_ID_TO_TIER: Map<string, SubscriptionTier> = new Map([
  [IapProductId.TRIAL_7DAY, SubscriptionTier.TRIAL_7DAY],
  [IapProductId.PERSONAL_YEAR, SubscriptionTier.PERSONAL_YEAR],
  [IapProductId.FAMILY_STANDARD, SubscriptionTier.FAMILY_STANDARD],
  [IapProductId.FAMILY_PREMIUM, SubscriptionTier.FAMILY_PREMIUM]
]);

const TIER_TO_PRODUCT_ID: Map<string, IapProductId> = new Map([
  [SubscriptionTier.TRIAL_7DAY, IapProductId.TRIAL_7DAY],
  [SubscriptionTier.PERSONAL_YEAR, IapProductId.PERSONAL_YEAR],
  [SubscriptionTier.FAMILY_STANDARD, IapProductId.FAMILY_STANDARD],
  [SubscriptionTier.FAMILY_PREMIUM, IapProductId.FAMILY_PREMIUM]
]);

// 会员等级排序（索引越大等级越高）
const TIER_ORDER: SubscriptionTier[] = [
  SubscriptionTier.FREE,
  SubscriptionTier.TRIAL_7DAY,
  SubscriptionTier.PERSONAL_YEAR,
  SubscriptionTier.FAMILY_STANDARD,
  SubscriptionTier.FAMILY_PREMIUM
];

// ===== 类型定义 =====

export interface ProductInfo {
  productId: string;
  title: string;
  description: string;
  price: string;
  priceValue: number;
  tier: SubscriptionTier;
}

export interface PurchaseResult {
  success: boolean;
  tier: SubscriptionTier;
  orderId: string;
  message: string;
}

/**
 * 会员状态
 */
export class MemberStatus {
  tier: string = SubscriptionTier.FREE;
  scansRemainingToday: number = 3;
  familyMembersCount: number = 1;
  expiryDate: number | null = null;
  isTrialActive: boolean = false;
  trialRemainingDays: number = 0;
}

// ===== 单例 =====

let iapServiceInstance: IapService | null = null;

export class IapService {
  private context: common.Context | null = null;
  private isInitialized: boolean = false;

  static getInstance(): IapService {
    if (iapServiceInstance === null) {
      iapServiceInstance = new IapService();
    }
    return iapServiceInstance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    this.isInitialized = true;
    hilog.info(DOMAIN_ZERO, TAG, 'IAP service initialized');
  }

  // ==================== 商品查询 ====================

  /**
   * 查询可购买商品列表（付费方案，不含免费版）
   */
  async queryProducts(): Promise<ProductInfo[]> {
    const products: ProductInfo[] = [];
    const paidTiers = [
      SubscriptionTier.TRIAL_7DAY,
      SubscriptionTier.PERSONAL_YEAR,
      SubscriptionTier.FAMILY_STANDARD,
      SubscriptionTier.FAMILY_PREMIUM
    ];
    const allPlans = PricingService.getAllPlans();
    for (const tier of paidTiers) {
      const plan = allPlans.find(p => p.tier === tier);
      if (plan === undefined) continue;
      const productId = TIER_TO_PRODUCT_ID.get(tier);
      if (productId === undefined) continue;
      const info: ProductInfo = {
        productId: productId,
        title: plan.tier,
        description: plan.features.join('、'),
        price: plan.price,
        priceValue: plan.priceValue,
        tier: plan.tier
      };
      products.push(info);
    }
    return products;
  }

  // ==================== 购买流程 ====================

  /**
   * 发起购买
   */
  async purchase(productId: string): Promise<PurchaseResult> {
    if (!this.context) {
      return this.failResult('服务未初始化');
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Purchase request: %{public}s', productId);

    try {
      const tier = PRODUCT_ID_TO_TIER.get(productId) || SubscriptionTier.FREE;
      await this.savePurchaseRecord(productId, 'mock_order_' + Date.now(), tier);

      hilog.info(DOMAIN_ZERO, TAG, 'Purchase success (mock): %{public}s -> %{public}s', productId, tier);
      return {
        success: true,
        tier: tier,
        orderId: 'mock_order_' + Date.now(),
        message: '购买成功'
      };
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Purchase failed: %{public}s', JSON.stringify(error));
      const errMsg = this.parseIapError(error);
      return this.failResult(errMsg);
    }
  }

  /**
   * 恢复购买
   */
  async restorePurchases(): Promise<void> {
    if (!this.context) {
      return;
    }

    try {
      const savedTier = await this.getSavedPurchaseTier();
      hilog.info(DOMAIN_ZERO, TAG, 'Restored purchases, tier: %{public}s', savedTier);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Restore purchases failed: %{public}s', JSON.stringify(error));
    }
  }

  // ==================== 会员状态 ====================

  /**
   * 从本地 Preference 读取当前会员状态
   */
  async getMemberStatus(): Promise<MemberStatus> {
    const status = new MemberStatus();

    if (!this.context) {
      return status;
    }

    try {
      const tierPrefs = await preferences.getPreferences(this.context, 'iap_records');
      const tierStr = tierPrefs.getSync('active_tier', SubscriptionTier.FREE) as string;
      let activeTier = SubscriptionTier.FREE;
      for (const t of TIER_ORDER) {
        if (t === tierStr) {
          activeTier = t;
          break;
        }
      }
      status.tier = activeTier;

      // 检查试用
      if (activeTier === SubscriptionTier.TRIAL_7DAY) {
        const purchaseTime = tierPrefs.getSync('purchase_time', '0') as string;
        const trialStart = parseInt(purchaseTime, 10) || Date.now();
        const daysSince = (Date.now() - trialStart) / (24 * 60 * 60 * 1000);
        status.isTrialActive = daysSince < 7;
        status.trialRemainingDays = Math.max(0, 7 - Math.floor(daysSince));
        if (!status.isTrialActive) {
          // 试用过期视为免费版
          activeTier = SubscriptionTier.FREE;
          status.tier = SubscriptionTier.FREE;
        }
      }

      // 读取扫描次数
      const scanPrefs = await preferences.getPreferences(this.context, 'scan_records');
      const today = this.getTodayDate();
      const scanDate = scanPrefs.getSync('scan_date', '') as string;
      const scanCount = scanPrefs.getSync('scan_count', 0) as number;

      if (activeTier === SubscriptionTier.FREE) {
        status.scansRemainingToday = (scanDate === today)
          ? Math.max(0, PricingService.FREE_DAILY_SCAN_LIMIT - scanCount)
          : PricingService.FREE_DAILY_SCAN_LIMIT;
      } else {
        status.scansRemainingToday = -1; // 无限
      }

      // 读取家庭成员数
      const familyPrefs = await preferences.getPreferences(this.context, 'family_config');
      const memberCount = familyPrefs.getSync('member_count', 1) as number;
      status.familyMembersCount = memberCount;

      // 读取过期时间
      const expiryStr = tierPrefs.getSync('expiry_date', '') as string;
      if (expiryStr.length > 0) {
        status.expiryDate = parseInt(expiryStr, 10);
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getMemberStatus failed: %{public}s', JSON.stringify(error));
    }

    return status;
  }

  // ==================== 扫码次数管理 ====================

  /**
   * 消耗一次扫码次数，返回是否可继续使用
   * true = 可以扫码（次数充足或无限）
   * false = 已达上限
   */
  async useScan(): Promise<boolean> {
    if (!this.context) {
      return false;
    }

    try {
      const status = await this.getMemberStatus();
      if (status.tier !== SubscriptionTier.FREE) {
        // 付费版无限扫码
        return true;
      }

      const scanPrefs = await preferences.getPreferences(this.context, 'scan_records');
      const today = this.getTodayDate();
      const scanDate = scanPrefs.getSync('scan_date', '') as string;
      const scanCount = scanDate === today
        ? (scanPrefs.getSync('scan_count', 0) as number)
        : 0;

      if (scanCount >= PricingService.FREE_DAILY_SCAN_LIMIT) {
        return false;
      }

      scanPrefs.putSync('scan_date', today);
      scanPrefs.putSync('scan_count', scanCount + 1);
      await scanPrefs.flush();
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'useScan failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 每日重置扫码次数
   * 在 EntryAbility 的 onForeground 中调用
   */
  async resetDailyScans(): Promise<void> {
    if (!this.context) {
      return;
    }

    try {
      const scanPrefs = await preferences.getPreferences(this.context, 'scan_records');
      const today = this.getTodayDate();
      const scanDate = scanPrefs.getSync('scan_date', '') as string;
      if (scanDate !== today) {
        scanPrefs.putSync('scan_date', today);
        scanPrefs.putSync('scan_count', 0);
        await scanPrefs.flush();
        hilog.info(DOMAIN_ZERO, TAG, 'Daily scan count reset for %{public}s', today);
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'resetDailyScans failed: %{public}s', JSON.stringify(error));
    }
  }

  // ==================== 内部方法 ====================

  private async savePurchaseRecord(productId: string, orderId: string, tier: SubscriptionTier): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'iap_records');
      prefs.putSync('active_product_id', productId);
      prefs.putSync('active_order_id', orderId);
      prefs.putSync('active_tier', tier);
      prefs.putSync('purchase_time', Date.now().toString());
      // 试用/订阅过期时间（试用7天，其他年卡365天）
      const days = tier === SubscriptionTier.TRIAL_7DAY ? 7 : 365;
      prefs.putSync('expiry_date', (Date.now() + days * 24 * 60 * 60 * 1000).toString());
      await prefs.flush();
      hilog.info(DOMAIN_ZERO, TAG, 'Purchase record saved');
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Save purchase record failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 获取已保存的购买等级
   */
  async getSavedPurchaseTier(): Promise<SubscriptionTier> {
    if (!this.context) return SubscriptionTier.FREE;
    try {
      const prefs = await preferences.getPreferences(this.context, 'iap_records');
      const tierStr = prefs.getSync('active_tier', SubscriptionTier.FREE) as string;
      for (const t of TIER_ORDER) {
        if (t === tierStr) return t;
      }
      return SubscriptionTier.FREE;
    } catch (error) {
      return SubscriptionTier.FREE;
    }
  }

  private failResult(message: string): PurchaseResult {
    return {
      success: false,
      tier: SubscriptionTier.FREE,
      orderId: '',
      message: message
    };
  }

  private parseIapError(error: Object): string {
    const errStr = JSON.stringify(error);
    if (errStr.includes('cancel')) return '购买已取消';
    if (errStr.includes('network')) return '网络异常，请检查网络后重试';
    if (errStr.includes('already')) return '您已订阅该服务';
    return '购买失败，请稍后重试';
  }

  private getTodayDate(): string {
    const d = new Date();
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
  }
}
