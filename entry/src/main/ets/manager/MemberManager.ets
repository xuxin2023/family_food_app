// MemberManager.ets
// 会员状态管理 - 负责会员等级、扫码配额、订阅相关逻辑
// 从 AppState 拆分，减少 God Class 负担

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DateUtil } from '../utils/DateUtil';
import {
  MemberTier,
  MemberStatus,
  PaywallTrigger,
  createDefaultMemberStatus,
  createMemberStatusForTier,
  getPaywallTriggerForFeature,
  hasTierAccess,
  getTierDisplayName,
  TIER_DAILY_SCAN_LIMIT,
  TIER_MEMBER_LIMIT
} from '../model/MemberStatus';

const TAG = 'MemberManager';
const DOMAIN_ZERO = 0;

export class MemberManager {
  /** 会员状态 */
  memberStatus: MemberStatus = createDefaultMemberStatus();

  /** 已添加的家庭成员数量（用于计算剩余可添加数） */
  private addedMemberCount: number = 0;

  /** Preferences 上下文（在 init 时设置） */
  private context: common.Context | null = null;

  /** 扫描配额 persistence 键名 */
  private readonly scanQuotaDateKey: string = 'scan_quota_date';
  private readonly scanQuotaRemainingKey: string = 'scan_quota_remaining';

  /** 当前成员缓存（由外部注入，用于 canAddMember 判断） */
  private currentMemberCount: number = 0;

  /**
   * 设置上下文（AppState.init 时调用）
   */
  setContext(ctx: common.Context): void {
    this.context = ctx;
  }

  /**
   * 同步当前成员数量（由 AppState 在成员加载后调用）
   */
  syncMemberCount(count: number): void {
    this.currentMemberCount = count;
  }

  // ========== 成员等级检查 ==========

  canAddMember(): boolean {
    const limit = TIER_MEMBER_LIMIT.get(this.memberStatus.tier) ?? 1;
    return this.currentMemberCount < limit;
  }

  getRemainingScans(): number {
    const limit = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
    if (limit === -1) return 999;
    return Math.max(0, this.memberStatus.scansRemainingToday);
  }

  /** 获取今日已扫描次数（用于 FoodAdapterEngine 衰减计算） */
  getTodayScanCount(): number {
    const limit = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
    if (limit === -1) return 0;
    return limit - Math.max(0, this.memberStatus.scansRemainingToday);
  }

  getMemberTierDisplay(): string {
    return getTierDisplayName(this.memberStatus.tier);
  }

  hasPremiumAccess(): boolean {
    return hasTierAccess(this.memberStatus.tier, MemberTier.PREMIUM);
  }

  hasFamilyAccess(): boolean {
    return hasTierAccess(this.memberStatus.tier, MemberTier.FAMILY);
  }

  // ========== 付费墙触发 ==========

  getPaywallTrigger(feature: string): PaywallTrigger | null {
    return getPaywallTriggerForFeature(feature, this.memberStatus.tier);
  }

  // ========== 扫描配额管理 ==========

  /**
   * 重置每日扫描计数（根据当前等级重新设置）
   * 每日首次打开 app 时调用
   */
  resetDailyScanQuota(): void {
    const limit = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
    this.memberStatus.scansRemainingToday = limit !== -1 ? limit : -1;
    this.persistScanQuota();
    AppStorage.set<number>('scanVersion', (AppStorage.get<number>('scanVersion') || 0) + 1);
  }

  /**
   * 使用一次扫描名额（递减计数 + 返回触发参数）
   * @returns 达到限制返回付费墙触发信息，否则返回 null
   */
  useScan(): PaywallTrigger | null {
    const limit = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
    if (limit === -1) return null;
    if (this.memberStatus.scansRemainingToday <= 0) {
      return getPaywallTriggerForFeature('scan', this.memberStatus.tier);
    }
    this.memberStatus.scansRemainingToday--;
    this.persistScanQuota();
    AppStorage.set<number>('scanVersion', (AppStorage.get<number>('scanVersion') || 0) + 1);
    if (this.memberStatus.scansRemainingToday <= 0) {
      return getPaywallTriggerForFeature('scan', this.memberStatus.tier);
    }
    return null;
  }

  /**
   * 使用一次家庭成员名额
   */
  useFamilyMember(): PaywallTrigger | null {
    return getPaywallTriggerForFeature('add_member', this.memberStatus.tier);
  }

  /**
   * 家庭成员添加完成后调用
   */
  onMemberAdded(): void {
    this.addedMemberCount++;
  }

  /**
   * 升级会员等级
   */
  upgradeTier(tier: MemberTier, days: number): void {
    this.memberStatus = createMemberStatusForTier(tier, days);
  }

  // ========== Preferences 持久化 ==========

  /**
   * 从 Preferences 恢复扫描配额（按日期检查是否需要重置）
   */
  async restoreScanQuota(context: common.Context): Promise<void> {
    this.context = context;
    try {
      const prefs = await preferences.getPreferences(context, 'scan_quota');
      const savedDate = prefs.getSync(this.scanQuotaDateKey, '') as string;
      const today = DateUtil.getToday();
      if (savedDate !== today) {
        this.resetDailyScanQuota();
        await prefs.put(this.scanQuotaDateKey, today);
        await prefs.flush();
      } else {
        const remaining = prefs.getSync(this.scanQuotaRemainingKey,
          TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3) as number;
        this.memberStatus.scansRemainingToday = remaining;
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'restoreScanQuota failed: %{public}s', JSON.stringify(error));
      const limit = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
      this.memberStatus.scansRemainingToday = limit === -1 ? -1 : limit;
    }
  }

  /** 持久化扫描计数 */
  private async persistScanQuota(): Promise<void> {
    const ctx = this.context;
    if (ctx === null) return;
    try {
      const pref = await preferences.getPreferences(ctx, 'scan_quota');
      await pref.put(this.scanQuotaRemainingKey, this.memberStatus.scansRemainingToday);
      await pref.flush();
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'persistScanQuota failed');
    }
  }
}
