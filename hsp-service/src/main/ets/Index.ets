// hsp-service 业务服务层入口
// Sprint1: Repository 层源码已物理迁移至本模块
// Sprint2: 高频 Service 层源码已物理迁移至本模块（第一批5个）

// ===== Repository 层导出 =====
export { FamilyRepository } from './repository/FamilyRepository';
export { FoodRepository } from './repository/FoodRepository';
export { HistoryRepository, ScanHistoryRecord, ScanHistoryInput, DietRecordInput, RiskDaysResult } from './repository/HistoryRepository';
export { RuleRepository, GoalAdjustment, DynamicFactor, DynamicModifiers, NutritionBudgetRule, MealBalanceTemplate, AllergenKeywordMap } from './repository/RuleRepository';
export { FamilyGroupRepository } from './repository/FamilyGroupRepository';
export { RecipeRepository } from './repository/RecipeRepository';
export { FavoriteRepository, FavoriteItem } from './repository/FavoriteRepository';
export { ShoppingListRepository } from './repository/ShoppingListRepository';
export { ReminderRuleRepository } from './repository/ReminderRuleRepository';
export { NutritionTargetRepository } from './repository/NutritionTargetRepository';
export { NutritionSnapshotRepository } from './repository/NutritionSnapshotRepository';
export { SyncQueueRepository } from './repository/SyncQueueRepository';

// ===== Service 层导出（Sprint2 已迁移） =====
export { AuthService, AuthUser } from './service/AuthService';
export { PermissionManager, PermissionStatus } from './service/PermissionManager';
export { IapService } from './service/IapService';
export { TeenModeManager } from './service/TeenModeManager';
export { migrateDatabase } from './service/DatabaseMigrationService';
export { PrivacyManager, PrivacyDocumentUrls } from './service/PrivacyManager';
export { AnalyticsService } from './service/AnalyticsService';
export { NetworkMonitorService, NetType, NetworkState, NetworkStateChangeCallback } from './service/NetworkMonitorService';
export { DataExportService } from './service/DataExportService';

// ===== Service 层导出（Sprint3 批次1 已迁移） =====
export { CloudAuthService } from './service/CloudAuthService';
export { ScanDirectService } from './service/ScanDirectService';
export { OpenFoodFactsService, OnlineLookupResult } from './service/OpenFoodFactsService';
export { PrivacyService } from './service/PrivacyService';
export { SecureHttpClient, SecureRequestOptions } from './service/SecureHttpClient';
export { SecureHttpHelper, SecureJsonResponse, RawResponse } from './service/SecureHttpHelper';
export { HuaweiCloudBackend } from './service/HuaweiCloudBackend';

// ===== Service 层导出（Sprint3 批次3-Step2 已迁移） =====
export { HuaweiCloudService } from './service/HuaweiCloudService';
export { UpdateChecker, UpdateInfo } from './service/UpdateChecker';
export { SyncService, SyncEvent, SyncEventCallback } from './service/sync/SyncService';
export { DataService } from './service/DataService';
export { ServiceGateway } from './service/ServiceGateway';
export { CloudBackendService, CloudProductResponse, CloudProductRecord, CloudNutritionInfo, FoodSubmissionRequest, AlternativeQueryRequest, SyncMemberDataRequest } from './service/CloudBackendService';
export { OnlineAlternativeSearchService, OnlineSearchResult, CloudAlternativeResult } from './service/OnlineAlternativeSearchService';

// ===== Sync 基础层导出（Sprint3 批次3-Step1 已迁移） =====
export { SyncableEntity, SyncChangeType } from './service/sync/Syncable';
export { CloudStorageProvider, AuthResult, DeviceRegisterResult } from './service/sync/CloudStorageProvider';

// ===== Utils 导出（Sprint3 批次3-Step1 已迁移） =====
export { DataLineage, LineageRecord } from './utils/DataLineage';
export { GlobalErrorHandler, ErrorModule } from './utils/GlobalErrorHandler';

// ===== Manager 层导出（Sprint3 批次1 已迁移） =====
export { MemberManager } from './manager/MemberManager';
export { BasketManager } from './manager/BasketManager';
export { ReportCacheManager } from './manager/ReportCacheManager';
export { RepositoryManager } from './manager/RepositoryManager';

// ===== 工具层导出（Sprint3 批次2 已迁移至 hsp_core） =====
// OfflineFoodDatabase 和 GlobalStateProvider 已迁移至 hsp_core

// ===== 合规服务导出（P0 新增） =====
export { SystemPrivacyService } from './service/SystemPrivacyService';
export { UserDataDeletionService, DeletionResult } from './service/UserDataDeletionService';
export { ScanToShoppingService, ShoppingItemInput, PriceCompareResult } from './service/ScanToShoppingService';
export { HealthReportExportService, HealthReportRequest, HealthReportResult } from './service/HealthReportExportService';
export { PermissionProgressiveGuide, PermissionGuideStep } from './service/PermissionProgressiveGuide';

// ===== 功能增强服务 =====
export { ConfigManager } from './service/ConfigManager';
export { BatchScanService, BatchScanResult, ILocalCacheProvider, IRemoteLookupProvider } from './service/BatchScanService';
export { FoodCompareService, FoodCompareResult, NutritionDelta } from './service/FoodCompareService';
export { NutritionKnowledgeService, KnowledgeEntry } from './service/NutritionKnowledgeService';
export { MealPlanService, MealPlan, MealPlanItem } from './service/MealPlanService';
export { ReminderService, ReminderRule, ReminderEvent } from './service/ReminderService';
export { FeedbackService, FeedbackSubmission, FeedbackResult } from './service/FeedbackService';

// ===== T-068 entry瘦身迁移: AI服务层 =====
export { AiClient } from './service/ai/AiClient';
export { AiConfig, AI_SERVICE_DEFAULTS, SYSTEM_PROMPTS } from './service/ai/AiConfig';
export { AiServiceBase } from './service/ai/AiServiceBase';
export { OnDeviceLlmService } from './service/ai/OnDeviceLlmService';
export { AiPolishService } from './service/AiPolishService';
export { AiRecipeRecommenderService } from './service/AiRecipeRecommenderService';
export { AiVisionService } from './service/AiVisionService';
export { ChatHistoryPrefsService } from './service/ChatHistoryPrefsService';

// ===== T-068 entry瘦身迁移: 通用业务服务 =====
export { CloudDbSchema } from './service/CloudDbSchema';
export { ComplianceService } from './service/ComplianceService';
export { CrashMonitorManager } from './service/CrashMonitorManager';
export { DataBackupService, BackupResult, RestoreResult } from './service/DataBackupService';
export { DistributedDataManager } from './service/DistributedDataManager';
export { DistributedFoodSync } from './service/DistributedFoodSync';
export { ElderModeManager } from './service/ElderModeManager';
export { FamilyDomainService } from './service/FamilyDomainService';
export { FoodDomainService } from './service/FoodDomainService';
export { FoodWidgetManager } from './service/FoodWidgetManager';
export { FoodInputService, FoodInputResult } from './service/FoodInputService';
export { IapServerValidator } from './service/IapServerValidator';
export { IntentRegistrationService } from './service/IntentRegistrationService';
export { ModelConverter } from './service/ModelConverter';
export { NutritionDomainService } from './service/NutritionDomainService';
export { OfflineAiCache } from './service/OfflineAiCache';
export { OfflineModeManager } from './service/OfflineModeManager';

export { PrivacySettingsService } from './service/PrivacySettingsService';
export { PushMessageHandler, PushMessagePayload } from './service/PushMessageHandler';
export { PushNotificationService } from './service/PushNotificationService';
export { PushService } from './service/PushService';
export { RemoteErrorReporter, remoteErrorReporter } from './service/RemoteErrorReporter';
export { ShareImageService } from './service/ShareImageService';
export { ShareKitService } from './service/ShareKitService';
export { SharePosterGenerator, PosterData, PosterNutritionItem } from './service/SharePosterGenerator';
export { ShareService } from './service/ShareService';
export { SubscriptionVerifyService } from './service/SubscriptionVerifyService';

// ===== T-068 entry瘦身迁移: health子目录 =====
export { HealthSignalProvider } from './service/health/HealthSignalProvider';
export { HwHealthSignalProvider } from './service/health/HwHealthSignalProvider';
export { ManualHealthSignalProvider } from './service/health/ManualHealthSignalProvider';

// ===== T-068 entry瘦身迁移: share子目录 =====
export { CopyTextProvider } from './service/share/CopyTextProvider';
export { ShareProvider } from './service/share/ShareProvider';

// ===== T-068 entry瘦身迁移: sync子目录 =====

export { DistributedSyncHelper } from './service/sync/DistributedSyncHelper';

// ===== T-068 entry瘦身迁移: Engine =====
export { BasketCheckEngine, BasketCheckResult } from './engine/BasketCheckEngine';

// ===== T-075 AI服务迁移: 接口+实现+工厂 =====
export { IAiStateProvider } from './service/IAiStateProvider';
export { IAiNutritionistService } from './service/ai/IAiNutritionistService';
export { IAiChatService } from './service/ai/IAiChatService';
export { AiNutritionistServiceImpl } from './service/ai/AiNutritionistServiceImpl';
export { AiChatServiceImpl } from './service/ai/AiChatServiceImpl';
export { createAiNutritionistService, createAiChatService } from './service/ai/AiServiceFactory';

// ===== T-076 同步服务迁移: 类型+实现 =====
export { DistributedSyncPayload, ConflictAction } from './service/sync/SyncTypes';
export { DistributedSyncEnhancerImpl } from './service/sync/DistributedSyncEnhancerImpl';
export { DeferredInitQueue } from './service/sync/DeferredInitQueue';
