// 全局应用状态管理器 - 统一数据访问入口
// V2: 将引擎和服务管理委托给 EngineManager / ServiceManager

import { FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig } from './model/FamilyProfile';
import {
  HealthSignal, StepLevel, SleepStatus, WeightTrend, DataSource
} from './model/HealthSignal';
import { FoodLabel } from './model/FoodLabel';
import { DailyBudget } from './model/DailyBudget';
import { Recommendation } from './model/Recommendation';
import { MealBalance, MealScenario } from './model/MealBalance';
import { ChildProtection } from './model/ChildProtection';
import { CredibilityResult } from './model/CredibilityResult';
import { FamilyRepository } from './repository/FamilyRepository';
import { FoodRepository } from './repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord, DietRecord } from './repository/HistoryRepository';
import { RuleRepository } from './repository/RuleRepository';
import { FamilyGroupRepository } from './repository/FamilyGroupRepository';
import { RecipeRepository } from './repository/RecipeRepository';
import { FamilyGroupService } from './service/FamilyGroupService';
import { RecipeCommunityService } from './service/RecipeCommunityService';
import { SyncService } from './service/sync/SyncService';
import { GroupSummary, GroupFeed, FeedType } from './model/FamilyGroup';
import { CreateRecipeParams } from './service/RecipeCommunityService';
import { Recipe, RecipeQueryParams, RecipeComment } from './model/Recipe';
import { NutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from './engine/NutritionTrendEngine';
import { BasketCheckResult } from './engine/BasketCheckEngine';
import { ElderFriendlyReport } from './engine/ElderFriendlyEngine';
import { PositiveAdvice } from './engine/PositiveAdviceEngine';
import { DateUtil } from './utils/DateUtil';
import { CacheManager } from './utils/CacheManager';
import { EngineManager } from './EngineManager';
import { ServiceManager } from './ServiceManager';
import { common } from '@kit.AbilityKit';
import { relationalStore, preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
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
  TIER_MEMBER_LIMIT,
  TIER_WEEKLY_REPORT_LIMIT
} from './model/MemberStatus';
import {
  AiRecipeRecommendationResult, AiRecipeRequest,
  AiNutritionAdvice
} from './model/AiModels';

const TAG = 'AppState';
const DOMAIN_ZERO = 0;

// 全局单例
let appStateInstance: AppState | null = null;

export class AppState {
  // 数据仓库
  private familyRepo: FamilyRepository = new FamilyRepository();
  private foodRepo: FoodRepository = new FoodRepository();
  private historyRepo: HistoryRepository = new HistoryRepository();
  private ruleRepo: RuleRepository = new RuleRepository();
  private groupRepo: FamilyGroupRepository = new FamilyGroupRepository();
  private recipeRepo: RecipeRepository = new RecipeRepository();

  // 引擎管理器（委托所有引擎调用）
  readonly engines: EngineManager = new EngineManager();

  // 服务管理器（委托所有服务调用）
  readonly services: ServiceManager = new ServiceManager();

  // 购物篮（内存中暂存）
  private basketItems: FoodLabel[] = [];

  // 引导状态
  hasShownGuide: boolean = false;

  // ========== 会员状态管理 ==========

  /** 会员状态 */
  memberStatus: MemberStatus = createDefaultMemberStatus();

  /** 已添加的家庭成员数量（用于计算剩余可添加数） */
  private addedMemberCount: number = 0;

  /** 缓存管理器 */
  cache: CacheManager = new CacheManager();

  private isInitialized: boolean = false;

  // ========== 缓存向后兼容属性（委托给 CacheManager） ==========
  private get membersCache(): FamilyProfile[] { return this.cache.membersCache; }
  private set membersCache(val: FamilyProfile[]) { this.cache.membersCache = val; }

  private get healthSignalsCache(): Map<string, HealthSignal> { return this.cache.healthSignalsSnapshot; }
  private set healthSignalsCache(_val: Map<string, HealthSignal>) { /* 只读兼容 */ }

  private get dailyBudgetsCache(): Map<string, DailyBudget> { return this.cache.dailyBudgetsSnapshot; }
  private set dailyBudgetsCache(_val: Map<string, DailyBudget>) { /* 只读兼容 */ }

  // ========== 向后兼容属性委托 ==========

  /** @deprecated 使用 services.healthService */
  private get healthService() { return this.services.healthService; }
  /** @deprecated 使用 services.authService */
  private get authService() { return this.services.authService; }
  /** @deprecated 使用 services.cloudAuthService */
  getCloudAuthService() { return this.services.cloudAuthService; }
  /** @deprecated 使用 services.syncService */
  getSyncService() { return this.services.syncService; }
  /** @deprecated 使用 services.groupService */
  getGroupService(): FamilyGroupService | null { return this.services.groupService; }
  /** @deprecated 使用 services.recipeCommunityService */
  getRecipeCommunityService(): RecipeCommunityService | null { return this.services.recipeCommunityService; }

  // ========== 向后兼容引擎委托 ==========

  /** @deprecated 使用 engines.ruleEngine */
  private get ruleEngine() { return this.engines.ruleEngine; }
  /** @deprecated 使用 engines.mealBalanceEngine */
  private get mealBalanceEngine() { return this.engines.mealBalanceEngine; }
  /** @deprecated 使用 engines.childProtectionEngine */
  private get childProtectionEngine() { return this.engines.childProtectionEngine; }
  /** @deprecated 使用 engines.credibilityEngine */
  private get credibilityEngine() { return this.engines.credibilityEngine; }
  /** @deprecated 使用 engines.basketCheckEngine */
  private get basketCheckEngine() { return this.engines.basketCheckEngine; }
  /** @deprecated 使用 engines.elderFriendlyEngine */
  private get elderFriendlyEngine() { return this.engines.elderFriendlyEngine; }
  /** @deprecated 使用 engines.positiveAdviceEngine */
  private get positiveAdviceEngine() { return this.engines.positiveAdviceEngine; }

  private constructor() {}

  static getInstance(): AppState {
    if (!appStateInstance) {
      appStateInstance = new AppState();
    }
    return appStateInstance;
  }

  /**
   * 等待 AppState 初始化完成
   */
  static waitForReady(): Promise<void> {
    const state = AppState.getInstance();
    if (state.isInitialized) return Promise.resolve();
    return new Promise((resolve) => {
      const check = (): void => {
        if (state.isInitialized) {
          resolve();
        } else {
          setTimeout(check, 50);
        }
      };
      check();
    });
  }

  /**
   * 初始化数据库和规则
   */
  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) return;

    try {
      const rdbConfig: relationalStore.StoreConfig = {
        name: 'food_helper.db',
        securityLevel: relationalStore.SecurityLevel.S3
      };
      const rdbStore = await relationalStore.getRdbStore(context, rdbConfig);

      // 并行初始化无依赖的仓库
      await Promise.all([
        this.familyRepo.init(rdbStore),
        this.foodRepo.init(rdbStore),
        this.historyRepo.init(rdbStore),
      ]);

      // 群组和食谱数据库
      this.groupRepo.init(rdbStore);
      await Promise.all([
        this.groupRepo.createTables(),
        this.recipeRepo.init(rdbStore),
      ]);
      await this.recipeRepo.createTables();

      // 认证服务
      await this.services.initAuth(context);

      // 社交服务
      this.services.initSocial(this.groupRepo, this.recipeRepo);

      // 规则仓库
      this.ruleRepo.setContext(context);

      // AI服务
      this.services.initAiServices(this.recipeRepo);

      // 云端同步
      await this.services.initCloudSync(context);

      // 同步事件监听
      this.services.onSyncEvent((event) => {
        if (typeof event === 'object' && event !== null &&
            (event as Record<string, Object>)['type'] === 'sync_completed') {
          this.refreshCache();
        }
      });

      // 加载缓存
      this.membersCache = await this.familyRepo.getAllMembers();
      await this.restoreTodayBudgets();
      await this.restoreHealthSignalsFromPrefs(context);

      this.isInitialized = true;
      hilog.info(DOMAIN_ZERO, TAG, 'AppState initialized');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AppState init failed: %{public}s', JSON.stringify(error));
      this.membersCache = this.createDefaultMembers();
      this.isInitialized = true;
    }
  }

  /** 成员初始化锁 */
  private memberInitLock: boolean = false;

  // ========== 家庭成员管理 ==========

  async getAllMembers(): Promise<FamilyProfile[]> {
    if (this.membersCache.length === 0) {
      this.membersCache = await this.familyRepo.getAllMembers();
      if (this.membersCache.length === 0 && !this.memberInitLock) {
        this.memberInitLock = true;
        try {
          this.membersCache = this.createDefaultMembers();
          for (const member of this.membersCache) {
            await this.familyRepo.saveMember(member);
          }
        } finally {
          this.memberInitLock = false;
        }
      }
    }
    return this.membersCache;
  }

  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.familyRepo.saveMember(profile);
    const index = this.membersCache.findIndex(m => m.memberId === profile.memberId);
    if (index >= 0) {
      this.membersCache[index] = profile;
    } else {
      this.membersCache.push(profile);
    }
  }

  async deleteMember(memberId: string): Promise<void> {
    await this.familyRepo.deleteMember(memberId);
    this.membersCache = this.membersCache.filter(m => m.memberId !== memberId);
    this.healthSignalsCache.delete(memberId);
    this.dailyBudgetsCache.delete(memberId);
  }

  // ========== 健康信号管理 ==========

  async getHealthSignalAsync(memberId: string): Promise<HealthSignal> {
    const today = DateUtil.getToday();
    const cached = this.healthSignalsCache.get(memberId);
    if (cached && cached.date === today && cached.source === DataSource.HUAWEI_HEALTH) {
      return cached;
    }

    try {
      const signal = await this.healthService.getTodayHealthData(memberId);
      if (signal.source === DataSource.HUAWEI_HEALTH) {
        this.healthSignalsCache.set(memberId, signal);
        return signal;
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Health Service read failed, using cache');
    }

    if (cached && cached.date === today) {
      return cached;
    }
    return this.getDefaultHealthSignal(memberId);
  }

  getHealthSignal(memberId: string): HealthSignal {
    const today = DateUtil.getToday();
    const cached = this.healthSignalsCache.get(memberId);
    if (cached && cached.date === today) {
      return cached;
    }
    return this.getDefaultHealthSignal(memberId);
  }

  private getDefaultHealthSignal(memberId: string): HealthSignal {
    const signal = new HealthSignal();
    signal.memberId = memberId;
    signal.date = DateUtil.getToday();
    signal.stepLevel = StepLevel.NORMAL;
    signal.sleepStatus = SleepStatus.GOOD;
    signal.weightTrend = WeightTrend.STABLE;
    signal.source = DataSource.MANUAL;
    return signal;
  }

  updateHealthSignal(signal: HealthSignal): void {
    this.healthSignalsCache.set(signal.memberId, signal);
  }

  async switchToHwHealthKit(context: common.Context): Promise<boolean> {
    return await this.services.switchToHwHealthKit(context);
  }

  switchToManualProvider(): void {
    this.services.switchToManualProvider();
  }

  isUsingHwHealthKit(): boolean {
    return this.services.useHwHealthKit;
  }

  async requestHealthAuthorization(): Promise<boolean> {
    return await this.services.requestHealthAuthorization();
  }

  async checkHealthAuthorization(): Promise<boolean> {
    return await this.services.checkHealthAuthorization();
  }

  // ========== 今日预算管理 ==========

  getDailyBudget(memberId: string): DailyBudget {
    const today = DateUtil.getToday();
    const cached = this.dailyBudgetsCache.get(memberId);
    if (cached && cached.date === today) {
      return cached;
    }
    const budget = this.createBudgetForMember(memberId);
    this.dailyBudgetsCache.set(memberId, budget);
    return budget;
  }

  private createBudgetForMember(memberId: string): DailyBudget {
    const member = this.membersCache.find(m => m.memberId === memberId);
    const budget = new DailyBudget();
    budget.memberId = memberId;
    budget.date = DateUtil.getToday();

    if (member) {
      budget.sodiumBudget = member.dailyBudget.sodiumBudget;
      budget.sugarBudget = member.dailyBudget.sugarBudget;
      budget.calorieBudget = member.dailyBudget.calorieBudget;
      budget.fatBudget = member.dailyBudget.fatBudget;
    }

    budget.sodiumRemaining = budget.sodiumBudget;
    budget.sugarRemaining = budget.sugarBudget;
    budget.calorieRemaining = budget.calorieBudget;
    budget.fatRemaining = budget.fatBudget;
    return budget;
  }

  private async restoreTodayBudgets(): Promise<void> {
    const today = DateUtil.getToday();
    this.dailyBudgetsCache.clear();
    for (const member of this.membersCache) {
      const budget = this.createBudgetForMember(member.memberId);
      const records = await this.historyRepo.getDietRecordsByDateRange(member.memberId, today, today);
      for (const record of records) {
        budget.deductIntake(
          record.sodiumIntake,
          record.sugarIntake,
          record.calorieIntake,
          record.fatIntake
        );
      }
      this.dailyBudgetsCache.set(member.memberId, budget);
    }
  }

  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    const budget = this.getDailyBudget(memberId);
    budget.deductIntake(sodium, sugar, calories, fat);
  }

  // ========== 食品标签管理 ==========

  async saveFoodLabel(label: FoodLabel): Promise<void> {
    if (label.foodId.length === 0) {
      label.foodId = `food_${Date.now()}`;
    }
    if (label.identifiedAt <= 0) {
      label.identifiedAt = Date.now();
    }
    await this.foodRepo.saveFoodLabel(label);
  }

  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return await this.foodRepo.findByBarcode(barcode);
  }

  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return await this.foodRepo.findById(foodId);
  }

  async findFoodByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    return await this.foodRepo.findByIds(foodIds);
  }

  async getRecentScanHistory(limit: number = 50): Promise<ScanHistoryRecord[]> {
    return await this.historyRepo.getRecentScanHistory(limit);
  }

  async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
    return await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
  }

  // ========== 核心业务计算（委托给 EngineManager） ==========

  calculateRecommendation(memberId: string, foodLabel: FoodLabel): Recommendation {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudget(memberId);
    return this.engines.calculateRecommendation(profile, signal, foodLabel, budget);
  }

  calculateFamilyComparison(foodLabel: FoodLabel): Recommendation[] {
    return this.engines.calculateFamilyComparison(
      this.membersCache, this.healthSignalsCache, this.dailyBudgetsCache, foodLabel
    );
  }

  calculateMealBalance(scenario: MealScenario, memberId: string): MealBalance {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    return this.engines.calculateMealBalance(scenario, profile, signal);
  }

  calculateChildProtection(memberId: string, foodLabel: FoodLabel): ChildProtection {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engines.calculateChildProtection(profile, foodLabel);
  }

  calculateCredibility(foodLabel: FoodLabel): CredibilityResult {
    return this.engines.calculateCredibility(foodLabel);
  }

  checkBasket(): BasketCheckResult {
    return this.engines.checkBasket(this.basketItems, this.membersCache);
  }

  generateElderFriendlyReport(rec: Recommendation, memberId: string, food: FoodLabel): ElderFriendlyReport {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engines.generateElderFriendlyReport(rec, profile, food);
  }

  generatePositiveAdvice(scenario: MealScenario, memberId: string): PositiveAdvice {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engines.generatePositiveAdvice(scenario, profile);
  }

  // ========== 购物篮管理 ==========

  addToBasket(item: FoodLabel): void {
    this.basketItems.push(item);
  }

  getBasketItems(): FoodLabel[] {
    return this.basketItems;
  }

  clearBasket(): void {
    this.basketItems = [];
  }

  // ========== 历史记录 ==========

  async saveScanHistory(memberId: string, foodLabel: FoodLabel, rec: Recommendation): Promise<void> {
    await this.historyRepo.saveScanHistory({
      memberId,
      foodId: foodLabel.foodId,
      foodName: foodLabel.foodName,
      level: rec.level,
      maxAmount: rec.maxAmount,
      reasons: rec.reasons,
      scannedAt: Date.now()
    });
  }

  async saveDietRecord(memberId: string, scenario: string, mealType: string, foodId: string,
    amountG: number, sodium: number, sugar: number, calories: number, fat: number): Promise<void> {
    await this.historyRepo.saveDietRecord({
      memberId,
      date: DateUtil.getToday(),
      scenario,
      mealType,
      foodId,
      amountG,
      sodiumIntake: sodium,
      sugarIntake: sugar,
      calorieIntake: calories,
      fatIntake: fat,
      recordedAt: Date.now()
    });
  }

  // ========== 会员状态管理 ==========

  canAddMember(): boolean {
    return this.membersCache.length < TIER_MEMBER_LIMIT[this.memberStatus.tier];
  }

  getRemainingScans(): number {
    return TIER_DAILY_SCAN_LIMIT[this.memberStatus.tier];
  }

  getMemberTierDisplay(): string {
    return getTierDisplayName(this.memberStatus.tier);
  }

  hasPremiumAccess(): boolean {
    return hasTierAccess(this.memberStatus.tier, MemberTier.PREMIUM);
  }

  // ========== 向后兼容方法（委派给 services / engines） ==========

  /**
   * @deprecated 直接使用 getRemainingScans()
   */
  getRemainingScansToday(): number {
    return this.getRemainingScans();
  }

  /**
   * 获取付费墙触发参数
   */
  getPaywallTrigger(feature: string): PaywallTrigger | null {
    return getPaywallTriggerForFeature(feature, this.memberStatus.tier);
  }

  /**
   * 使用一次扫描名额（返回触发参数）
   */
  useScan(): PaywallTrigger | null {
    return getPaywallTriggerForFeature('scan', this.memberStatus.tier);
  }

  /**
   * 使用一次家庭成员名额（返回触发参数）
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
   * 是否有家庭群组功能访问权限
   */
  hasFamilyAccess(): boolean {
    return hasTierAccess(this.memberStatus.tier, MemberTier.FAMILY);
  }

  /**
   * 升级会员等级
   */
  upgradeTier(tier: MemberTier, _days: number): void {
    this.memberStatus = createMemberStatusForTier(tier, _days);
  }

  /**
   * 清除所有缓存
   */
  clearAllCache(): void {
    this.cache.clearAll();
  }

  // ========== 群组服务委派 ==========

  async getMyGroups(): Promise<GroupSummary[]> {
    if (!this.services.groupService) return [];
    return await this.services.groupService.getMyGroups();
  }

  async createFamilyGroup(name: string, description: string, creatorName: string): Promise<GroupSummary> {
    if (!this.services.groupService) return {} as GroupSummary;
    return await this.services.groupService.createGroup({ groupName: name, description, ownerName: creatorName });
  }

  async joinFamilyGroup(inviteCode: string, displayName: string): Promise<GroupSummary> {
    if (!this.services.groupService) return {} as GroupSummary;
    return await this.services.groupService.joinGroupByCode(inviteCode, displayName);
  }

  async getGroupFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    return await this.groupRepo.getFeeds(groupId, offset, limit);
  }

  async shareFoodScanToGroup(groupId: string, foodName: string, _type: string,
    _amount: number, message: string, _imageUri: string): Promise<void> {
    const feed: GroupFeed = {
      feedId: `feed_${Date.now()}`,
      groupId: groupId,
      feedType: FeedType.FOOD_SCAN_SHARE,
      senderUid: '',
      senderName: '',
      content: JSON.stringify({ foodName, summary: message }),
      createdAt: Date.now(),
      commentCount: 0,
      likeCount: 0
    };
    await this.groupRepo.saveFeed(feed);
  }

  // ========== 食谱服务委派 ==========

  async queryCommunityRecipes(params: RecipeQueryParams): Promise<Recipe[]> {
    if (!this.services.recipeCommunityService) return [];
    return await this.services.recipeCommunityService.queryRecipes(params);
  }

  async getRecipeDetail(recipeId: string): Promise<Recipe | null> {
    if (!this.services.recipeCommunityService) return null;
    return await this.services.recipeCommunityService.getRecipeDetail(recipeId);
  }

  async getRecipeComments(recipeId: string): Promise<RecipeComment[]> {
    if (!this.services.recipeCommunityService) return [];
    return await this.services.recipeCommunityService.getComments(recipeId);
  }

  async hasLikedRecipe(recipeId: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return await this.services.recipeCommunityService.hasLiked(recipeId);
  }

  async toggleRecipeLike(recipeId: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return await this.services.recipeCommunityService.toggleLike(recipeId);
  }

  async toggleRecipeBookmark(recipeId: string, note: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return await this.services.recipeCommunityService.toggleBookmark(recipeId, note);
  }

  async addRecipeComment(recipeId: string, content: string, parentId: string): Promise<RecipeComment> {
    if (!this.services.recipeCommunityService) return {} as RecipeComment;
    return await this.services.recipeCommunityService.addComment(recipeId, content, parentId);
  }

  async publishRecipe(params: CreateRecipeParams): Promise<string> {
    if (!this.services.recipeCommunityService) return '';
    const recipe = await this.services.recipeCommunityService.createRecipe(params);
    return recipe.recipeId || '';
  }

  async getAiRecipeRecommendations(memberIds: string[], _prefs: undefined,
    _exclude: undefined, _count: number): Promise<AiRecipeRecommendationResult> {
    return await this.services.aiRecipeRecommender.getRecommendations(
      {} as AiRecipeRequest, [], new Map(), new Map());
  }

  // ========== AI / 营养服务委派 ==========

  async getAiNutritionAdvice(memberId: string, days: number, includeMealPlan: boolean): Promise<AiNutritionAdvice> {
    const member = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudget(memberId);
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return await this.services.aiNutritionist.getAdvice(member, signal, budget, records, days, includeMealPlan);
  }

  private getDaysAgo(days: number): string {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }

  // ========== 趋势分析 ==========

  async getNutritionTrends(memberId: string, days: number): Promise<NutrientTrendData[]> {
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    const member = this.membersCache.find(m => m.memberId === memberId);
    const targetSodium = member?.dailyBudget.sodiumBudget || 2000;
    const targetSugar = member?.dailyBudget.sugarBudget || 50;
    const targetCalorie = member?.dailyBudget.calorieBudget || 2000;
    const targetFat = member?.dailyBudget.fatBudget || 65;
    return NutritionTrendEngine.buildNutrientTrends(
      NutritionTrendEngine.aggregateDaily(records),
      targetSodium, targetSugar, targetCalorie, targetFat);
  }

  async getDailySummaries(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return NutritionTrendEngine.aggregateDaily(records);
  }

  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, date, date);
    return NutritionTrendEngine.groupByMealType(records);
  }

  // ========== 实用工具方法 ==========

  private createDefaultMembers(): FamilyProfile[] {
    const defaultMembers: FamilyProfile[] = [];
    if (DateUtil.getToday().length > 0) {
      const adult = new FamilyProfile();
      adult.memberId = 'default_adult';
      adult.nickname = '我';
      adult.ageGroup = AgeGroup.ADULT;
      adult.healthGoals = [HealthGoal.NONE];
      adult.allergens = [];
      adult.dailyBudget = new DailyBudgetConfig();
      defaultMembers.push(adult);
    }
    return defaultMembers;
  }

  private async restoreHealthSignalsFromPrefs(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'health_signals_cache');
      for (const member of this.membersCache) {
        const json = prefs.getSync(member.memberId, '') as string;
        if (json.length > 0) {
          const signal = HealthSignal.fromJson(JSON.parse(json));
          this.healthSignalsCache.set(member.memberId, signal);
        }
      }
    } catch (_e) {
      // 恢复失败不影响主流程
    }
  }

  private async refreshCache(): Promise<void> {
    try {
      this.membersCache = await this.familyRepo.getAllMembers();
    } catch (_e) {
      // 刷新失败不影响主流程
    }
  }
}
