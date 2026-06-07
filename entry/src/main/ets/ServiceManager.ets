// ServiceManager.ets
// 服务管理器 - 统一管理所有业务服务的创建和生命周期
// AppState 通过此管理器委托所有服务调用

import {
  FEATURE_FLAGS, HILOG_DOMAIN_DEFAULT, FamilyProfile, HealthSignal, DailyBudget, NutritionTarget, AiNutritionAdvice, AiRecipeRecommendationResult, AiRecipeRequest, DietRecord
} from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HealthService } from 'feature_report';
import { AuthService, CloudAuthService } from 'hsp_service';
import { SyncService, SyncEventCallback, SyncEvent } from 'hsp_service';
import {
  FoodCompareService, BatchScanService, NutritionKnowledgeService, MealPlanService, ReminderService, FeedbackService
} from 'hsp_service';
import { FamilyGroupService, RecipeCommunityService } from 'feature_community';
import { FamilyGroupRepository } from 'feature_community';
import { RecipeRepository } from 'feature_community';
import { HwHealthSignalProvider } from 'hsp_service';
import { ManualHealthSignalProvider } from 'hsp_service';
import { AiNutritionistService } from './service/AiNutritionistService';
import { AiRecipeRecommenderService } from 'hsp_service';
import { AiChatService } from './service/AiChatService';
import { AiPolishService } from 'hsp_service';
import { AiWeeklyReportService } from 'feature_report';
import { AiServiceBase } from 'hsp_service';

const TAG = 'ServiceManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class ServiceManager {
  // ========== 依赖注入注册表 ==========
  private serviceRegistry: Map<string, Object> = new Map();

  registerService(key: string, service: Object): void {
    this.serviceRegistry.set(key, service);
  }

  getService(key: string): Object | undefined {
    return this.serviceRegistry.get(key);
  }

  // ========== 基础服务 ==========
  private _healthService: HealthService | null = null;
  get healthService(): HealthService {
    return (this.getService('healthService') as HealthService) ?? (this._healthService ?? (this._healthService = new HealthService()));
  }

  private _authService: AuthService | null = null;
  get authService(): AuthService {
    return (this.getService('authService') as AuthService) ?? (this._authService ?? (this._authService = new AuthService()));
  }

  private _cloudAuthService: CloudAuthService | null = null;
  get cloudAuthService(): CloudAuthService {
    return (this.getService('cloudAuthService') as CloudAuthService) ?? (this._cloudAuthService ?? (this._cloudAuthService = new CloudAuthService()));
  }

  private _syncService: SyncService | null = null;
  get syncService(): SyncService {
    return (this.getService('syncService') as SyncService) ?? (this._syncService ?? (this._syncService = SyncService.getInstance()));
  }

  // ========== 社交服务（延迟初始化） ==========
  groupService: FamilyGroupService | null = null;
  recipeCommunityService: RecipeCommunityService | null = null;

  // ========== AI 服务 ==========
  private _aiNutritionist: AiNutritionistService | null = null;
  get aiNutritionist(): AiNutritionistService {
    return (this.getService('aiNutritionist') as AiNutritionistService) ?? (this._aiNutritionist ?? (this._aiNutritionist = new AiNutritionistService()));
  }

  private _aiRecipeRecommender: AiRecipeRecommenderService | null = null;
  get aiRecipeRecommender(): AiRecipeRecommenderService {
    return (this.getService('aiRecipeRecommender') as AiRecipeRecommenderService) ?? (this._aiRecipeRecommender ?? (this._aiRecipeRecommender = new AiRecipeRecommenderService()));
  }

  private _aiChat: AiChatService | null = null;
  get aiChat(): AiChatService {
    return (this.getService('aiChat') as AiChatService) ?? (this._aiChat ?? (this._aiChat = new AiChatService()));
  }

  private _aiPolish: AiPolishService | null = null;
  get aiPolish(): AiPolishService {
    return (this.getService('aiPolish') as AiPolishService) ?? (this._aiPolish ?? (this._aiPolish = new AiPolishService()));
  }

  private _aiWeeklyReport: AiWeeklyReportService | null = null;
  get aiWeeklyReport(): AiWeeklyReportService {
    return (this.getService('aiWeeklyReport') as AiWeeklyReportService) ?? (this._aiWeeklyReport ?? (this._aiWeeklyReport = new AiWeeklyReportService()));
  }

  // ========== 功能增强服务 ==========
  private _foodCompare: FoodCompareService | null = null;
  get foodCompareService(): FoodCompareService {
    return (this.getService('foodCompareService') as FoodCompareService) ?? (this._foodCompare ?? (this._foodCompare = new FoodCompareService()));
  }

  private _batchScan: BatchScanService | null = null;
  get batchScanService(): BatchScanService {
    return (this.getService('batchScanService') as BatchScanService) ?? (this._batchScan ?? (this._batchScan = new BatchScanService()));
  }

  private _nutritionKnowledge: NutritionKnowledgeService | null = null;
  get nutritionKnowledgeService(): NutritionKnowledgeService {
    return (this.getService('nutritionKnowledgeService') as NutritionKnowledgeService) ??
      (this._nutritionKnowledge ?? (this._nutritionKnowledge = NutritionKnowledgeService.getInstance()));
  }

  private _mealPlan: MealPlanService | null = null;
  get mealPlanService(): MealPlanService {
    const cached = this.getService('mealPlanService');
    if (cached instanceof MealPlanService) {
      return cached;
    }
    return this._mealPlan ?? (this._mealPlan = new MealPlanService());
  }

  private _reminder: ReminderService | null = null;
  get reminderService(): ReminderService {
    return (this.getService('reminderService') as ReminderService) ?? (this._reminder ?? (this._reminder = ReminderService.getInstance()));
  }

  private _feedback: FeedbackService | null = null;
  get feedbackService(): FeedbackService {
    return (this.getService('feedbackService') as FeedbackService) ?? (this._feedback ?? (this._feedback = FeedbackService.getInstance()));
  }

  // ========== 健康设备开关 ==========
  useHwHealthKit: boolean = false;

  /**
   * 初始化认证服务
   */
  async initAuth(context: common.Context): Promise<void> {
    try {
      await this.authService.init(context);
      await this.cloudAuthService.init(context);
      hilog.info(DOMAIN_ZERO, TAG, 'Auth services initialized');
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Auth init failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 初始化社交服务
   */
  initSocial(groupRepo: FamilyGroupRepository, recipeRepo: RecipeRepository): void {
    this.groupService = new FamilyGroupService(groupRepo, this.authService);
    this.recipeCommunityService = new RecipeCommunityService(recipeRepo, this.authService);
    hilog.info(DOMAIN_ZERO, TAG, 'Social services initialized');
  }

  /**
   * 初始化 AI 服务（异步加载 API Key）
   * 统一管理所有 AI 服务的生命周期和密钥加载
   */
  async initAiServices(recipeRepo: RecipeRepository): Promise<void> {
    if (FEATURE_FLAGS.ENABLE_AI_NUTRITIONIST) {
      this.aiRecipeRecommender.setRecipeRepo(recipeRepo);

      // 统一从 Asset Kit 安全存储加载所有 AI 服务的 API Key
      const allAiServices: AiServiceBase[] = [
        this.aiNutritionist,
        this.aiRecipeRecommender,
        this.aiChat,
        this.aiPolish,
        this.aiWeeklyReport
      ];

      const promises = allAiServices.map(s => s.loadApiKey());
      const results = await Promise.allSettled(promises);
      const loadedCount = results.filter(r => r.status === 'fulfilled' && r.value).length;

      hilog.info(DOMAIN_ZERO, TAG, 'AI services initialized, %{public}d/%{public}d keys loaded',
        loadedCount, promises.length);
    }
  }

  /**
   * 初始化云端同步
   */
  async initCloudSync(context: common.Context): Promise<void> {
    if (FEATURE_FLAGS.ENABLE_CLOUD_SYNC) {
      try {
        await this.syncService.init(context);
        hilog.info(DOMAIN_ZERO, TAG, 'Cloud sync initialized');
      } catch (error) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Cloud sync init failed: %{public}s', JSON.stringify(error));
      }
    }
  }

  /**
   * 注册同步事件监听
   */
  onSyncEvent(callback: SyncEventCallback): void {
    if (FEATURE_FLAGS.ENABLE_CLOUD_SYNC) {
      this.syncService.onEvent(callback);
    }
  }

  /**
   * 切换到华为健康套件
   */
  async switchToHwHealthKit(context: common.Context): Promise<boolean> {
    try {
      const hwProvider: HwHealthSignalProvider = new HwHealthSignalProvider()
      this.healthService.setProvider(hwProvider);
      this.useHwHealthKit = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Switched to HwHealthKit');
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Failed to switch to HwHealthKit: %{public}s', JSON.stringify(error));
      this.useHwHealthKit = false;
      return false;
    }
  }

  /**
   * 切换回手动数据提供
   */
  switchToManualProvider(): void {
    const manualProvider: ManualHealthSignalProvider = new ManualHealthSignalProvider()
    this.healthService.setProvider(manualProvider);
    this.useHwHealthKit = false;
    hilog.info(DOMAIN_ZERO, TAG, 'Switched to Manual provider');
  }

  /**
   * 请求健康数据授权
   */
  async requestHealthAuthorization(): Promise<boolean> {
    if (this.useHwHealthKit) {
      return await this.healthService.requestAuthorization();
    }
    return true;
  }

  /**
   * 检查健康数据授权状态
   */
  async checkHealthAuthorization(): Promise<boolean> {
    if (this.useHwHealthKit) {
      return await this.healthService.checkAuthorization();
    }
    return true;
  }

  // ========== AI 服务委托 ==========
  async getAiNutritionAdvice(memberId: string, dietRecords: DietRecord[], days: number,
    includeMealPlan: boolean, budget: DailyBudget, target: NutritionTarget): Promise<AiNutritionAdvice> {
    return this.aiNutritionist.generateAdvice(memberId, dietRecords, days, includeMealPlan, budget, target);
  }

  async getAiRecipeRecommendation(request: AiRecipeRequest, members: FamilyProfile[],
    signals: Map<string, HealthSignal>, budgets: Map<string, DailyBudget>): Promise<AiRecipeRecommendationResult> {
    return this.aiRecipeRecommender.recommendForFamily(request, members, signals, budgets);
  }

  destroy(): void {
    this.groupService = null;
    this.recipeCommunityService = null;
    this._healthService = null;
    this._authService = null;
    this._cloudAuthService = null;
    this._syncService = null;
    this._batchScan = null;
    this._feedback = null;
    this._reminder = null;
    this._mealPlan = null;
    this._nutritionKnowledge = null;
    this._foodCompare = null;
    this._aiNutritionist = null;
    this._aiRecipeRecommender = null;
    this._aiChat = null;
    this._aiPolish = null;
    this._aiWeeklyReport = null;
    this.serviceRegistry.clear();
    hilog.info(DOMAIN_ZERO, TAG, 'ServiceManager destroyed');
  }
}