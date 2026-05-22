// V3: 领域门面模式 — AppState 变为薄协调者
// 食品(Member+Food+Favorite+History) → FoodFacade
// 成员(Family+HealthSignal+Budget+NutritionTarget) → MemberFacade
// 健康(HealthKit+AI+NutritionTrend+Report) → HealthFacade
// 同步(Group+RecipeCommunity+Sync) → SyncFacade

import {
  FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig, createDefaultMembers, FoodLabel, FoodLabelJson, DailyBudget, Recommendation, MealBalance, MealScenario, ChildProtection, CredibilityResult, NutritionTarget, NutritionSnapshot, GroupSummary, GroupFeed, FeedType, Recipe, RecipeQueryParams, RecipeComment, EnhancedFoodRecommendation, FamilyComparisonItem, DateUtil, CacheManager, DB_NAME, HILOG_DOMAIN, HealthSignal, StepLevel, SleepStatus, WeightTrend, DataSource, BpStatus, BsStatus, HeartRateZone, SpO2Level, StressLevel, MemberTier, MemberStatus, PaywallTrigger, createDefaultMemberStatus, createMemberStatusForTier, getPaywallTriggerForFeature, hasTierAccess, getTierDisplayName, TIER_DAILY_SCAN_LIMIT, TIER_MEMBER_LIMIT, TIER_WEEKLY_REPORT_LIMIT, AiRecipeRecommendationResult, AiRecipeRequest, AiNutritionAdvice, DietRecord
} from 'hsp_core';
import { FamilyRepository } from './repository/FamilyRepository';
import { FoodRepository } from './repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord, DietRecordInput } from './repository/HistoryRepository';
import { RuleRepository } from './repository/RuleRepository';
import { FamilyGroupRepository } from './repository/FamilyGroupRepository';
import { RecipeRepository } from './repository/RecipeRepository';
import { FavoriteItem, FavoriteRepository } from './repository/FavoriteRepository';
import { SyncService, SyncEvent } from './service/sync/SyncService';
import { CreateRecipeParams } from './service/RecipeCommunityService';
import { migrateDatabase } from './service/DatabaseMigrationService';
import { PermissionManager } from './service/PermissionManager';
import { NetworkMonitorService } from './service/NetworkMonitorService';
import { ScanService } from './service/ScanService';
import { FoodInputService, FoodInputResult } from './service/FoodInputService';
import { PrivacyManager } from './service/PrivacyManager';
import { DistributedSyncHelper } from './service/sync/DistributedSyncHelper';
import { OnDeviceAiEngine } from './engine/OnDeviceAiEngine';
import { ExerciseNutritionRecommendation } from './engine/ExerciseNutritionEngine';
import { CheckupReport, HealthArchiveUpdate } from './engine/CheckupReportEngine';
import { ChildHealthAssessment } from './engine/ChildHealthAssessmentEngine';
import { PersonalizedRecommendation } from './engine/PersonalizedRecommendEngine';
import { DailyNutritionSummary, MealGroup } from './engine/NutritionTrendEngine';
import { EngineManager } from './EngineManager';
import { ServiceManager } from './ServiceManager';
import { MemberManager } from './manager/MemberManager';
import { BasketManager } from './manager/BasketManager';
import { ReportCacheManager } from './manager/ReportCacheManager';
import { FoodFacade } from './facade/FoodFacade';
import { MemberFacade } from './facade/MemberFacade';
import { HealthFacade } from './facade/HealthFacade';
import { SyncFacade } from './facade/SyncFacade';
import { common } from '@kit.AbilityKit';
import { relationalStore, preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AppState';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

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
  readonly privacy: PrivacyManager = PrivacyManager.getInstance();
  readonly member: MemberManager = new MemberManager();
  readonly basket: BasketManager = new BasketManager();
  readonly reportCache: ReportCacheManager = new ReportCacheManager();

  hasShownGuide: boolean = false;
  readonly cache: CacheManager = new CacheManager();

  private initPhase: 'none' | 'initializing' | 'ready' = 'none';
  private readyResolver: (() => void) | null = null;
  private readyPromise: Promise<void> = new Promise<void>((resolve) => {
    this.readyResolver = resolve;
  });

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
      const rdbConfig: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S3,
        encrypt: true
      };
      store = await relationalStore.getRdbStoreV9(context, rdbConfig);
    }
    await migrateDatabase(context, store);

    await this.familyRepo.init(store);
    await this.foodRepo.init(store);
    await this.historyRepo.init(store);
    await this.ruleRepo.init(store);
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

    this.services.onSyncEvent((event: SyncEvent) => {
      try {
        hilog.info(DOMAIN_ZERO, TAG, 'sync event received: ' + event.type);
        this.refreshCache();
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, 'AppState', 'sync event parse failed: %{public}s', JSON.stringify(_e));
      }
    });

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
  async getDailyBudget(memberId: string): Promise<DailyBudget> {
    return this.memberFacade.getDailyBudgetSync(memberId);
  }
  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    this.memberFacade.deductIntake(memberId, sodium, sugar, calories, fat);
  }
  getNutritionTargetSync(memberId: string): NutritionTarget {
    return this.memberFacade.getNutritionTargetSync(memberId);
  }
  async getNutritionTargetOrDefault(memberId: string): Promise<NutritionTarget> {
    return this.memberFacade.getNutritionTargetOrDefault(memberId);
  }
  async getNutritionTarget(memberId: string): Promise<NutritionTarget | null> {
    return this.memberFacade.getNutritionTarget(memberId);
  }
  async saveNutritionTarget(target: NutritionTarget): Promise<void> {
    await this.food.saveNutritionTarget(target);
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
  async calculateExerciseNutrition(memberId: string, exType: string, minutes: number,
    intensity: string): Promise<ExerciseNutritionRecommendation> {
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
  calculateMealBalance(scenario: MealScenario, _memberId: string): MealBalance {
    return this.food.calculateMealBalance(scenario);
  }
  generatePositiveAdvice(_scenario: MealScenario, _memberId: string): PositiveAdvice | null {
    return this.food.generatePositiveAdvice();
  }
  calculateChildProtection(_memberId: string, foodLabel: FoodLabel): ChildProtection {
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
    AppStorage.setOrCreate<number>('scanVersion', (AppStorage.get<number>('scanVersion') ?? 0) + 1);
  }

  refreshMemberCache(): void {
    this.memberFacade.refreshMemberCache();
  }

  refreshBudgetCache(): void {
    this.memberFacade.refreshBudgetCache();
  }

  destroy(): void {
    this.member.clearContext();
    this.basket.clearContext();
    this.engines.cleanExpiredEngineCache();
    DistributedSyncHelper.getInstance().destroy();
    this.initPhase = 'none';
    appStateInstance = null;
    hilog.info(DOMAIN_ZERO, TAG, 'AppState destroyed');
  }
}
