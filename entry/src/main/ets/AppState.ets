// V3: 领域门面模式 — AppState 变为薄协调者
// 食品(Member+Food+Favorite+History) → FoodFacade
// 成员(Family+HealthSignal+Budget+NutritionTarget) → MemberFacade
// 健康(HealthKit+AI+NutritionTrend+Report) → HealthFacade
// 同步(Group+RecipeCommunity+Sync) → SyncFacade

import {
  FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig, createDefaultMembers, FoodLabel, FoodLabelJson, DailyBudget, Recommendation, MealBalance, MealScenario, ChildProtection, CredibilityResult, NutritionTarget, NutritionSnapshot, GroupSummary, GroupFeed, FeedType, Recipe, RecipeQueryParams, RecipeComment, EnhancedFoodRecommendation, FamilyComparisonItem, DateUtil, CacheManager, DB_NAME, HILOG_DOMAIN_DEFAULT, HealthSignal, StepLevel, SleepStatus, WeightTrend, DataSource, BpStatus, BsStatus, HeartRateZone, SpO2Level, StressLevel, MemberTier, MemberStatus, PaywallTrigger, createDefaultMemberStatus, createMemberStatusForTier, getPaywallTriggerForFeature, hasTierAccess, getTierDisplayName, TIER_DAILY_SCAN_LIMIT, TIER_MEMBER_LIMIT, TIER_WEEKLY_REPORT_LIMIT, AiRecipeRecommendationResult, AiRecipeRequest, AiNutritionAdvice, DietRecord, DomainEventBus, DomainEvents, CacheInvalidationData
} from 'hsp_core';
import { FamilyRepository } from './repository/FamilyRepository';
import { FoodRepository } from './repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord, DietRecordInput } from './repository/HistoryRepository';
import { RuleRepository } from './repository/RuleRepository';
import { SyncService, SyncEvent, migrateDatabase, PermissionManager, NetworkMonitorService, PrivacyManager, MemberManager, BasketManager, ReportCacheManager } from 'hsp_service';
import { ScanService, ILocalCacheProvider, IRemoteLookupProvider, IDataLineageRecorder, RemoteLookupResult } from 'feature_scan';
import { OpenFoodFactsService, DataLineage } from 'hsp_service';
import { FavoriteItem, FavoriteRepository } from './repository/FavoriteRepository';
import { CreateRecipeParams } from 'hsp_core';
import { FamilyGroupRepository, RecipeRepository } from 'feature_community';
import { FoodInputService, FoodInputResult } from 'feature_scan';
import { DistributedSyncHelper } from 'hsp_service';
import { OnDeviceAiEngine } from 'feature_scan';
import { ExerciseNutritionRecommendation } from 'feature_report';
import { CheckupReport, HealthArchiveUpdate } from 'feature_report';
import { ChildHealthAssessment } from 'feature_report';
import { PersonalizedRecommendation } from 'feature_report';
import { DailyNutritionSummary, MealGroup } from 'feature_report';
import { EngineManager } from './EngineManager';
import { ServiceManager } from './ServiceManager';
import { FoodFacade } from './facade/FoodFacade';
import { MemberFacade } from './facade/MemberFacade';
import { HealthFacade } from './facade/HealthFacade';
import { SyncFacade } from './facade/SyncFacade';
import { OfflineModeManager } from 'hsp_service';
import { common } from '@kit.AbilityKit';
import { relationalStore, preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AppState';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

let appStateInstance: AppState | null = null;

export class AppState {
  private familyRepo: FamilyRepository = new FamilyRepository();
  readonly foodRepo: FoodRepository = new FoodRepository();
  readonly historyRepo: HistoryRepository = new HistoryRepository();
  private ruleRepo: RuleRepository = new RuleRepository();
  private groupRepo: FamilyGroupRepository = new FamilyGroupRepository();
  private recipeRepo: RecipeRepository = new RecipeRepository();
  private favoriteRepo: FavoriteRepository = new FavoriteRepository();

  readonly engines: EngineManager = new EngineManager();
  readonly services: ServiceManager = new ServiceManager();
  readonly permission: PermissionManager = PermissionManager.getInstance();
  readonly network: NetworkMonitorService = NetworkMonitorService.getInstance();
  readonly scanService: ScanService = new ScanService();
  readonly foodInput: FoodInputService = new FoodInputService();
  readonly privacy: PrivacyManager = new PrivacyManager();
  readonly member: MemberManager = new MemberManager();
  readonly basket: BasketManager = new BasketManager();
  readonly reportCache: ReportCacheManager = new ReportCacheManager();
  readonly offline: OfflineModeManager = OfflineModeManager.getInstance();

  hasShownGuide: boolean = false;
  readonly cache: CacheManager = new CacheManager();

  constructor() {
    const self = this;
    const cacheProvider: ILocalCacheProvider = {
      findFoodByBarcode: (barcode: string) => self.findFoodByBarcode(barcode)
    };
    this.scanService.setCacheProvider(cacheProvider);

    const remoteProvider: IRemoteLookupProvider = {
      lookupByBarcode: async (barcode: string) => {
        const result = await OpenFoodFactsService.getInstance().lookupByBarcode(barcode);
        if (result && result.found && result.foodLabel) {
          const r = new RemoteLookupResult();
          r.found = true;
          r.foodLabel = result.foodLabel;
          r.confidence = result.confidence;
          return r;
        }
        return null;
      }
    };
    this.scanService.setRemoteProvider(remoteProvider);

    const lineageRecorder: IDataLineageRecorder = {
      recordLineage: (foodId: string, source: string, confidence: number, transforms: string[]) => {
        DataLineage.record(DataLineage.createRecord(foodId, source, confidence, transforms, '', ''));
      }
    };
    this.scanService.setLineageRecorder(lineageRecorder);
  }

  private initPhase: 'none' | 'initializing' | 'ready' = 'none';
  private readyResolver: (() => void) | null = null;
  private readyRejecter: ((reason: Object) => void) | null = null;
  private initTimeoutId: number = -1;
  private readyPromise: Promise<void> = new Promise<void>((resolve, reject) => {
    this.readyResolver = resolve;
    this.readyRejecter = reject;
    this.initTimeoutId = setTimeout(() => {
      this.readyResolver = null;
      this.readyRejecter = null;
      reject(new Error('AppState init timeout after 15s'));
    }, 15000);
  });
  private syncEventHandler: ((event: SyncEvent) => void) | null = null;

  // ===== 领域门面（init 后可用） =====
  readonly food: FoodFacade = new FoodFacade(
    this.foodRepo, this.historyRepo, this.favoriteRepo, this.engines, this.cache
  );
  readonly memberFacade: MemberFacade = new MemberFacade(
    this.familyRepo, this.member, this.cache
  );
  readonly health: HealthFacade = new HealthFacade(
    this.historyRepo, this.engines, this.services
  );
  readonly sync: SyncFacade = new SyncFacade(this.services);

  // ===== 单例 =====
  static getInstance(): AppState {
    if (!appStateInstance) {
      appStateInstance = new AppState();
    }
    return appStateInstance;
  }

  static async waitForReady(): Promise<void> {
    const instance = AppState.getInstance();
    if (instance.initPhase === 'ready') return;
    return instance.readyPromise;
  }

  isInitFailed(): boolean {
    return this.initPhase === 'none' && this.readyResolver === null;
  }

  // ===== 初始化 =====
  async init(context: common.Context, rdbStore?: relationalStore.RdbStore): Promise<void> {
    if (this.initPhase === 'ready') return;
    if (this.initPhase === 'initializing') {
      await this.readyPromise;
      return;
    }
    this.initPhase = 'initializing';

    hilog.info(DOMAIN_ZERO, TAG, 'AppState init start...');

    let store = rdbStore;
    if (!store) {
      const rdbConfig = new relationalStore.StoreConfig();
      rdbConfig.name = DB_NAME;
      rdbConfig.securityLevel = relationalStore.SecurityLevel.S3;
      rdbConfig.encrypt = true;
      store = await relationalStore.getRdbStore(context, rdbConfig);
    }
    await migrateDatabase(context, store);

    await this.familyRepo.init(store);
    await this.foodRepo.init(store);
    await this.historyRepo.init(store);
    this.ruleRepo.setContext(context);
    await this.groupRepo.init(store);
    await this.recipeRepo.init(store);
    await this.favoriteRepo.init(store);

    await this.services.initAuth(context);
    this.services.initSocial(this.groupRepo, this.recipeRepo);
    await this.services.initAiServices(this.recipeRepo);
    await this.services.initCloudSync(context);

    this.member.setContext(context);
    this.basket.setContext(context);
    await this.member.restoreScanQuota(context);
    await this.basket.restoreFromPrefs(context);

    await this.memberFacade.loadCache();

    await this.offline.init(context);

    this.health.setMemberResolvers(
      (memberId: string) => this.memberFacade.membersCache.find(m => m.memberId === memberId),
      (memberId: string) => this.memberFacade.getHealthSignal(memberId),
      (memberId: string) => this.memberFacade.getNutritionTargetFromCache(memberId)
    );

    this.syncEventHandler = (event: SyncEvent) => {
      try {
        hilog.info(DOMAIN_ZERO, TAG, 'sync event received: ' + event.type);
        this.refreshCache();
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, 'AppState', 'sync event parse failed: %{public}s', JSON.stringify(_e));
      }
    };
    this.services.onSyncEvent(this.syncEventHandler);

    if (this.initTimeoutId !== -1) {
      clearTimeout(this.initTimeoutId);
      this.initTimeoutId = -1;
    }
    if (this.readyResolver) {
      this.readyResolver();
      this.readyResolver = null;
    }
    this.initPhase = 'ready';

    hilog.info(DOMAIN_ZERO, TAG, 'AppState init done');
  }

  // ===== 委托方法（保持向后兼容） =====

  // --- Member ---
  async getAllMembers(): Promise<FamilyProfile[]> {
    return this.memberFacade.getAllMembers();
  }
  getAllMembersSync(): FamilyProfile[] {
    return this.memberFacade.getAllMembersSync();
  }
  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.memberFacade.saveMember(profile);
  }
  async deleteMember(memberId: string): Promise<void> {
    await this.memberFacade.deleteMember(memberId);
  }
  getHealthSignal(memberId: string): HealthSignal {
    return this.memberFacade.getHealthSignal(memberId);
  }
  async getHealthSignalAsync(memberId: string): Promise<HealthSignal> {
    return this.memberFacade.getHealthSignalAsync(memberId);
  }
  updateHealthSignal(signal: HealthSignal): void {
    this.memberFacade.updateHealthSignal(signal);
  }
  getDailyBudgetSync(memberId: string): DailyBudget {
    return this.memberFacade.getDailyBudgetSync(memberId);
  }
  getDailyBudget(memberId: string): DailyBudget {
    return this.memberFacade.getDailyBudgetSync(memberId);
  }
  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    this.memberFacade.deductIntake(memberId, sodium, sugar, calories, fat);
  }
  async getNutritionTarget(memberId: string): Promise<NutritionTarget | null> {
    return this.memberFacade.getNutritionTarget(memberId);
  }
  getNutritionTargetFromCache(memberId: string): NutritionTarget {
    return this.memberFacade.getNutritionTargetFromCache(memberId);
  }
  async getNutritionTargetOrDefault(memberId: string): Promise<NutritionTarget> {
    return this.memberFacade.getNutritionTargetOrDefault(memberId);
  }
  async saveNutritionTarget(target: NutritionTarget): Promise<void> {
    await this.memberFacade.saveNutritionTarget(target);
  }

  // --- Health ---
  async switchToHwHealthKit(context: common.Context): Promise<boolean> {
    return this.health.switchToHwHealthKit(context);
  }
  switchToManualProvider(): void {
    this.health.switchToManualProvider();
  }
  isUsingHwHealthKit(): boolean {
    return this.health.isUsingHwHealthKit();
  }
  async requestHealthAuthorization(): Promise<boolean> {
    return this.health.requestHealthAuthorization();
  }
  async checkHealthAuthorization(): Promise<boolean> {
    return this.health.checkHealthAuthorization();
  }
  getOnDeviceAiEngine(): OnDeviceAiEngine | null {
    return this.health.getOnDeviceAiEngine();
  }
  async calculateExerciseNutrition(memberId: string, _exType: string, _minutes: number,
    _intensity: string): Promise<ExerciseNutritionRecommendation> {
    return this.health.calculateExerciseNutrition(memberId);
  }
  async parseCheckupReport(content: string, memberId: string): Promise<CheckupReport> {
    return this.health.parseCheckupReport(content, memberId);
  }
  async generateHealthArchiveUpdate(memberId: string, report: CheckupReport): Promise<HealthArchiveUpdate> {
    return this.health.generateHealthArchiveUpdate(memberId, report);
  }
  async assessChildHealth(memberId: string, foodLabel: FoodLabel): Promise<ChildHealthAssessment> {
    return this.health.assessChildHealth(memberId, foodLabel);
  }
  async getPersonalizedRecommendation(memberId: string, foodLabel: FoodLabel): Promise<PersonalizedRecommendation> {
    return this.health.getPersonalizedRecommendation(memberId);
  }

  // --- Food ---
  async saveFoodLabel(label: FoodLabel): Promise<void> {
    await this.food.saveFoodLabel(label);
  }
  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return this.food.findFoodByBarcode(barcode);
  }
  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return this.food.findFoodById(foodId);
  }
  async findFoodByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    return this.food.findFoodByIds(foodIds);
  }
  async getRecentScanHistory(limit?: number): Promise<ScanHistoryRecord[]> {
    return this.food.getRecentScanHistory(limit);
  }
  async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
    return this.food.getDietRecordsByDateRange(memberId, startDate, endDate);
  }
  async getTodayDietRecords(memberId: string): Promise<DietRecord[]> {
    return this.food.getTodayDietRecords(memberId);
  }
  async getNutritionSnapshots(memberId: string, limit: number): Promise<NutritionSnapshot[]> {
    return this.food.getNutritionSnapshots(memberId, limit);
  }
  async getAllFavorites(): Promise<FavoriteItem[]> {
    return this.food.getAllFavorites();
  }
  async removeFavorite(foodId: string): Promise<void> {
    await this.food.removeFavorite(foodId);
  }
  calculateRecommendation(memberId: string, foodLabel: FoodLabel): Recommendation {
    return this.food.calculateRecommendation(
      memberId, foodLabel,
      this.memberFacade.membersCache,
      (mid: string) => this.memberFacade.getHealthSignal(mid),
      (mid: string) => this.memberFacade.getDailyBudgetSync(mid)
    );
  }
  async calculateEnhancedRecommendation(memberId: string, foodLabel: FoodLabel): Promise<EnhancedFoodRecommendation> {
    return this.food.calculateEnhancedRecommendation(
      memberId, foodLabel,
      this.memberFacade.membersCache,
      (mid: string) => this.memberFacade.getHealthSignal(mid),
      (mid: string) => this.memberFacade.getDailyBudgetSync(mid)
    );
  }
  async saveDietRecord(
    memberId: string, scenario: MealScenario, mealType: string,
    foodId: string, amount: number, sodium: number, sugar: number,
    calories: number, fat: number
  ): Promise<void> {
    await this.food.saveDietRecord(memberId, scenario, mealType, foodId, amount, sodium, sugar, calories, fat);
  }
  calculateMealBalance(scenario: MealScenario, memberId?: string): MealBalance {
    return this.food.calculateMealBalance(scenario);
  }
  generatePositiveAdvice(scenario?: MealScenario, memberId?: string): Object | null {
    return this.food.generatePositiveAdvice();
  }
  calculateChildProtection(memberId: string, foodLabel: FoodLabel): ChildProtection {
    return this.food.calculateChildProtection(foodLabel);
  }

  // --- AI Nutrition ---
  async getAiNutritionAdvice(
    member: FamilyProfile, foodLabel: FoodLabel,
    signal: HealthSignal, memberId: string, days: number, includeMealPlan: boolean
  ): Promise<AiNutritionAdvice> {
    return this.health.getAiNutritionAdvice(
      member, foodLabel, signal, memberId, days, includeMealPlan,
      (mid: string) => this.memberFacade.getHealthSignal(mid),
      (mid: string) => this.memberFacade.getDailyBudgetSync(mid)
    );
  }
  async getAiRecipeRecommendation(request: AiRecipeRequest): Promise<AiRecipeRecommendationResult> {
    return this.health.getAiRecipeRecommendation(
      request,
      this.memberFacade.membersCache,
      (mid: string) => this.memberFacade.getHealthSignal(mid),
      (mid: string) => this.memberFacade.getDailyBudgetSync(mid)
    );
  }

  // --- Nutrition Trend ---
  async getNutritionTrend(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    return this.health.getNutritionTrend(memberId, days);
  }
  async getDailySummaries(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    return this.health.getDailySummaries(memberId, days);
  }
  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    return this.health.getDailyDietGroups(memberId, date);
  }
  async generateWeeklyReport(memberId: string): Promise<string> {
    return this.health.generateWeeklyReport(
      memberId,
      this.memberFacade.membersCache,
      (mid: string) => this.memberFacade.getDailyBudgetSync(mid)
    );
  }

  // --- Sync/Group ---
  async getMyGroups(): Promise<GroupSummary[]> {
    return this.sync.getMyGroups();
  }
  async createFamilyGroup(name: string): Promise<GroupSummary> {
    return this.sync.createFamilyGroup(name);
  }
  async getOrCreateGroupSummary(): Promise<GroupSummary | null> {
    return this.sync.getOrCreateGroupSummary();
  }
  async getGroupFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    return this.sync.getGroupFeeds(groupId, offset, limit);
  }
  async postFeed(groupId: string, content: string, feedType: FeedType, mediaUri?: string): Promise<void> {
    await this.sync.postFeed(groupId, content, feedType, mediaUri);
  }
  async joinFamilyGroup(code: string): Promise<GroupSummary> {
    return this.sync.joinFamilyGroup(code);
  }
  async shareFoodScanToGroup(
    groupId: string, foodName: string, foodId: string,
    nutriScore: number, summary: string, memberResults: string
  ): Promise<void> {
    await this.sync.shareFoodScanToGroup(groupId, foodName, foodId, nutriScore, summary, memberResults);
  }

  // --- Recipe ---
  async createRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    return this.sync.createRecipe(params);
  }
  async getRecipeRecommendations(params: RecipeQueryParams): Promise<Recipe[]> {
    return this.sync.getRecipeRecommendations(params);
  }
  async queryCommunityRecipes(params: RecipeQueryParams): Promise<Recipe[]> {
    return this.sync.queryCommunityRecipes(params);
  }
  async getRecipeDetail(recipeId: string): Promise<Recipe | null> {
    return this.sync.getRecipeDetail(recipeId);
  }
  async getRecipeComments(recipeId: string): Promise<RecipeComment[]> {
    return this.sync.getRecipeComments(recipeId);
  }
  async hasLikedRecipe(recipeId: string): Promise<boolean> {
    return this.sync.hasLikedRecipe(recipeId);
  }
  async toggleRecipeLike(recipeId: string): Promise<boolean> {
    return this.sync.toggleRecipeLike(recipeId);
  }
  async toggleRecipeBookmark(recipeId: string, notes: string): Promise<boolean> {
    return this.sync.toggleRecipeBookmark(recipeId, notes);
  }
  async addRecipeComment(recipeId: string, text: string, authorName: string): Promise<RecipeComment | null> {
    return this.sync.addRecipeComment(recipeId, text, authorName);
  }
  async publishRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    return this.sync.publishRecipe(params);
  }

  // --- Privacy ---
  async checkPrivacyAgreed(context: common.Context): Promise<boolean> {
    return PrivacyManager.checkPrivacyAgreed(context);
  }
  async agreePrivacy(context: common.Context): Promise<void> {
    await PrivacyManager.agreePrivacy(context);
  }

  // ===== 缓存刷新 =====
  refreshCache(): void {
    this.memberFacade.refreshMemberCache();
    this.memberFacade.refreshBudgetCache();
    this.engines.cleanExpiredEngineCache();
    const cacheData = new CacheInvalidationData();
    cacheData.source = 'sync';
    DomainEventBus.emit(DomainEvents.CACHE_INVALIDATED, cacheData);
  }

  refreshMemberCache(): void {
    this.memberFacade.refreshMemberCache();
  }

  refreshBudgetCache(): void {
    this.memberFacade.refreshBudgetCache();
  }

  persistAllHealthSignals(): void {
    this.cache.clearHealthSignalsCache();
  }

  trimCache(): void {
    this.cache.clearAll();
    this.engines.cleanExpiredEngineCache();
  }

  destroy(): void {
    if (this.syncEventHandler) {
      try {
        this.services.syncService.offEvent(this.syncEventHandler);
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'offSyncEvent failed: %{public}s', JSON.stringify(_e));
      }
      this.syncEventHandler = null;
    }
    this.member.clearContext();
    this.basket.clearContext();
    this.cache.clearAll();
    this.engines.cleanExpiredEngineCache();
    this.ruleRepo.clearCache();
    DistributedSyncHelper.getInstance().destroy();
    this.offline.destroy();
    this.initPhase = 'none';
    appStateInstance = null;
    hilog.info(DOMAIN_ZERO, TAG, 'AppState destroyed');
  }
}
