import { FamilyProfile, HealthSignal, DailyBudget, NutritionTarget, MemberTier, MemberStatus, PaywallTrigger, createDefaultMemberStatus, createMemberStatusForTier, getPaywallTriggerForFeature, hasTierAccess, getTierDisplayName, TIER_DAILY_SCAN_LIMIT, TIER_MEMBER_LIMIT, TIER_WEEKLY_REPORT_LIMIT, CacheManager, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { MemberManager } from 'hsp_service';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'UserState';

@ObservedV2
export class UserState {
  @Trace currentMemberId: string = '';
  @Trace membersCache: FamilyProfile[] = [];
  @Trace memberStatusMap: Map<string, MemberStatus> = new Map();
  @Trace healthSignalsCache: Map<string, HealthSignal> = new Map();
  @Trace dailyBudgetsCache: Map<string, DailyBudget> = new Map();
  @Trace nutritionTargetsCache: Map<string, NutritionTarget> = new Map();

  private memberManager: MemberManager = new MemberManager();

  get currentMember(): FamilyProfile | null {
    return this.membersCache.find(m => m.memberId === this.currentMemberId) ?? null;
  }

  get currentMemberStatus(): MemberStatus {
    return this.memberStatusMap.get(this.currentMemberId) ?? createDefaultMemberStatus();
  }

  setContext(context: common.Context): void {
    this.memberManager.setContext(context);
  }

  async restoreScanQuota(context: common.Context): Promise<void> {
    await this.memberManager.restoreScanQuota(context);
  }

  async loadMembers(familyRepo: { getAllMembers: () => Promise<FamilyProfile[]> }): Promise<void> {
    this.membersCache = await familyRepo.getAllMembers();
    if (this.membersCache.length > 0 && !this.currentMemberId) {
      this.currentMemberId = this.membersCache[0].memberId;
    }
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'Loaded %{public}d members', this.membersCache.length);
  }

  updateHealthSignal(signal: HealthSignal): void {
    this.healthSignalsCache.set(signal.memberId, signal);
  }

  getHealthSignal(memberId: string): HealthSignal {
    return this.healthSignalsCache.get(memberId) ?? new HealthSignal();
  }

  getDailyBudget(memberId: string): DailyBudget {
    return this.dailyBudgetsCache.get(memberId) ?? new DailyBudget();
  }

  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    const budget = this.dailyBudgetsCache.get(memberId);
    if (budget) {
      budget.sodiumRemaining -= sodium;
      budget.sugarRemaining -= sugar;
      budget.caloriesRemaining -= calories;
      budget.fatRemaining -= fat;
    }
  }

  getNutritionTargetFromCache(memberId: string): NutritionTarget {
    return this.nutritionTargetsCache.get(memberId) ?? new NutritionTarget();
  }

  hasTierAccess(tier: MemberTier, feature: string): boolean {
    return hasTierAccess(tier, feature);
  }

  getPaywallTrigger(feature: string): PaywallTrigger | null {
    return getPaywallTriggerForFeature(feature);
  }

  getMemberManager(): MemberManager {
    return this.memberManager;
  }
}
