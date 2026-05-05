// ServiceManager.ets
// 服务管理器 - 统一管理所有业务服务的创建和生命周期
// AppState 通过此管理器委托所有服务调用

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
import { FamilyGroupRepository } from './repository/FamilyGroupRepository';
import { RecipeRepository } from './repository/RecipeRepository';
import { FEATURE_FLAGS } from './constants/AppConfig';

const TAG = 'ServiceManager';
const DOMAIN_ZERO = 0;

export class ServiceManager {
  // ========== 基础服务 ==========
  healthService: HealthService = new HealthService();
  authService: AuthService = new AuthService();
  cloudAuthService: CloudAuthService = new CloudAuthService();
  syncService: SyncService = SyncService.getInstance();

  // ========== 社交服务（延迟初始化） ==========
  groupService: FamilyGroupService | null = null;
  recipeCommunityService: RecipeCommunityService | null = null;

  // ========== AI 服务（延迟初始化） ==========
  aiNutritionist: AiNutritionistService = new AiNutritionistService();
  aiRecipeRecommender: AiRecipeRecommenderService = new AiRecipeRecommenderService();

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
   * 初始化 AI 服务
   */
  initAiServices(recipeRepo: RecipeRepository): void {
    if (FEATURE_FLAGS.ENABLE_AI_NUTRITIONIST) {
      this.aiRecipeRecommender.setRecipeRepo(recipeRepo);
      hilog.info(DOMAIN_ZERO, TAG, 'AI services initialized');
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
}
