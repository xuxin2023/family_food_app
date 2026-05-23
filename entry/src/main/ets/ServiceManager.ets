// ServiceManager.ets
// 服务管理器 - 统一管理所有业务服务的创建和生命周期
// AppState 通过此管理器委托所有服务调用

import {
  FEATURE_FLAGS, HILOG_DOMAIN, FamilyProfile, HealthSignal, DailyBudget, NutritionTarget, AiNutritionAdvice, AiRecipeRecommendationResult, AiRecipeRequest
} from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HealthService } from './service/HealthService';
import { AuthService } from './service/AuthService';
import { CloudAuthService } from './service/CloudAuthService';
import { SyncService, SyncEventCallback, SyncEvent } from './service/sync/SyncService';
import { FamilyGroupService } from './service/FamilyGroupService';
import { RecipeCommunityService } from './service/RecipeCommunityService';
import { HwHealthSignalProvider } from './service/health/HwHealthSignalProvider';
import { ManualHealthSignalProvider } from './service/health/ManualHealthSignalProvider';
import { AiNutritionistService } from './service/AiNutritionistService';
import { AiRecipeRecommenderService } from './service/AiRecipeRecommenderService';
import { AiChatService } from './service/AiChatService';
import { AiPolishService } from './service/AiPolishService';
import { AiWeeklyReportService } from './service/AiWeeklyReportService';
import { AiServiceBase } from './service/ai/AiServiceBase';
import { FamilyGroupRepository } from './repository/FamilyGroupRepository';
import { RecipeRepository } from './repository/RecipeRepository';
import { DietRecord } from './repository/HistoryRepository';

const TAG = 'ServiceManager';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class ServiceManager {
  // ========== 依赖注入注册表 ==========
  private serviceRegistry: Map<string, Object> = new Map();

  registerService<T>(key: string, service: T): void {
    this.serviceRegistry.set(key, service as Object);
  }

  getService<T>(key: string): T | undefined {
    return this.serviceRegistry.get(key) as T;
  }

  // ========== 基础服务 ==========
  private _healthService: HealthService | null = null;
  get healthService(): HealthService {
    return this.getService<HealthService>('healthService') ?? (this._healthService ?? (this._healthService = new HealthService()));
  }

  private _authService: AuthService | null = null;
  get authService(): AuthService {
    return this.getService<AuthService>('authService') ?? (this._authService ?? (this._authService = new AuthService()));
  }

  private _cloudAuthService: CloudAuthService | null = null;
  get cloudAuthService(): CloudAuthService {
    return this.getService<CloudAuthService>('cloudAuthService') ?? (this._cloudAuthService ?? (this._cloudAuthService = new CloudAuthService()));
  }

  private _syncService: SyncService | null = null;
  get syncService(): SyncService {
    return this.getService<SyncService>('syncService') ?? (this._syncService ?? (this._syncService = SyncService.getInstance()));
  }

  // ========== 社交服务（延迟初始化） ==========
  groupService: FamilyGroupService | null = null;
  recipeCommunityService: RecipeCommunityService | null = null;

  // ========== AI 服务 ==========
  private _aiNutritionist: AiNutritionistService | null = null;
  get aiNutritionist(): AiNutritionistService {
    return this.getService<AiNutritionistService>('aiNutritionist') ?? (this._aiNutritionist ?? (this._aiNutritionist = new AiNutritionistService()));
  }

  private _aiRecipeRecommender: AiRecipeRecommenderService | null = null;
  get aiRecipeRecommender(): AiRecipeRecommenderService {
    return this.getService<AiRecipeRecommenderService>('aiRecipeRecommender') ?? (this._aiRecipeRecommender ?? (this._aiRecipeRecommender = new AiRecipeRecommenderService()));
  }

  private _aiChat: AiChatService | null = null;
  get aiChat(): AiChatService {
    return this.getService<AiChatService>('aiChat') ?? (this._aiChat ?? (this._aiChat = new AiChatService()));
  }

  private _aiPolish: AiPolishService | null = null;
  get aiPolish(): AiPolishService {
    return this.getService<AiPolishService>('aiPolish') ?? (this._aiPolish ?? (this._aiPolish = new AiPolishService()));
  }

  private _aiWeeklyReport: AiWeeklyReportService | null = null;
  get aiWeeklyReport(): AiWeeklyReportService {
    return this.getService<AiWeeklyReportService>('aiWeeklyReport') ?? (this._aiWeeklyReport ?? (this._aiWeeklyReport = new AiWeeklyReportService()));
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
      const hwProvider = new HwHealthSignalProvider(context);
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
    const manualProvider = new ManualHealthSignalProvider();
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
    // syncEvent 监听器由 AppState.destroy() 统一清理，此处不再重复调用
    this.groupService = null;
    this.recipeCommunityService = null;
    hilog.info(DOMAIN_ZERO, TAG, 'ServiceManager destroyed');
  }
}