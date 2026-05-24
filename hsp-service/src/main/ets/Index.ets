// hsp-service 业务服务层入口
// Sprint1: Repository 层源码已物理迁移至本模块
// Sprint2: 高频 Service 层源码已物理迁移至本模块（第一批5个）

// ===== Repository 层导出 =====
export { FamilyRepository } from './src/main/ets/repository/FamilyRepository';
export { FoodRepository } from './src/main/ets/repository/FoodRepository';
export { HistoryRepository, ScanHistoryRecord, ScanHistoryInput, DietRecordInput, RiskDaysResult } from './src/main/ets/repository/HistoryRepository';
export { RuleRepository, GoalAdjustment, DynamicFactor, DynamicModifiers, NutritionBudgetRule, MealBalanceTemplate, AllergenKeywordMap } from './src/main/ets/repository/RuleRepository';
export { FamilyGroupRepository } from './src/main/ets/repository/FamilyGroupRepository';
export { RecipeRepository } from './src/main/ets/repository/RecipeRepository';
export { FavoriteRepository, FavoriteItem } from './src/main/ets/repository/FavoriteRepository';
export { ShoppingListRepository } from './src/main/ets/repository/ShoppingListRepository';
export { ReminderRuleRepository } from './src/main/ets/repository/ReminderRuleRepository';
export { NutritionTargetRepository } from './src/main/ets/repository/NutritionTargetRepository';
export { NutritionSnapshotRepository } from './src/main/ets/repository/NutritionSnapshotRepository';
export { SyncQueueRepository } from './src/main/ets/repository/SyncQueueRepository';

// ===== Service 层导出（Sprint2 已迁移） =====
export { AuthService, AuthUser } from './src/main/ets/service/AuthService';
export { PermissionManager, PermissionStatus } from './src/main/ets/service/PermissionManager';
export { IapService } from './src/main/ets/service/IapService';
export { TeenModeManager } from './src/main/ets/service/TeenModeManager';
export { migrateDatabase } from './src/main/ets/service/DatabaseMigrationService';
export { PrivacyManager } from './src/main/ets/service/PrivacyManager';
export { AnalyticsService } from './src/main/ets/service/AnalyticsService';
export { NetworkMonitorService, NetType, NetworkState, NetworkStateChangeCallback } from './src/main/ets/service/NetworkMonitorService';
export { DataExportService } from './src/main/ets/service/DataExportService';

// ===== Service 层导出（Sprint3 批次1 已迁移） =====
export { CloudAuthService } from './src/main/ets/service/CloudAuthService';
export { ScanDirectService } from './src/main/ets/service/ScanDirectService';
export { OpenFoodFactsService } from './src/main/ets/service/OpenFoodFactsService';
export { PrivacyService } from './src/main/ets/service/PrivacyService';
export { SecureHttpClient, SecureRequestOptions } from './src/main/ets/service/SecureHttpClient';
export { SecureHttpHelper, SecureJsonResponse, RawResponse } from './src/main/ets/service/SecureHttpHelper';
export { HuaweiCloudBackend } from './src/main/ets/service/HuaweiCloudBackend';

// ===== Service 层导出（Sprint3 批次3-Step2 已迁移） =====
export { HuaweiCloudService } from './src/main/ets/service/HuaweiCloudService';
export { UpdateChecker, UpdateInfo } from './src/main/ets/service/UpdateChecker';
export { SyncService, SyncEvent, SyncEventCallback } from './src/main/ets/service/sync/SyncService';
export { DataService } from './src/main/ets/service/DataService';
export { ScanService, ScanLookupResult, ILocalCacheProvider } from './src/main/ets/service/ScanService';
export { ServiceGateway } from './src/main/ets/service/ServiceGateway';
export { CloudBackendService, CloudProductResponse, CloudProductRecord, CloudNutritionInfo, FoodSubmissionRequest, AlternativeQueryRequest, SyncMemberDataRequest } from './src/main/ets/service/CloudBackendService';
export { OnlineAlternativeSearchService, OnlineSearchResult } from './src/main/ets/service/OnlineAlternativeSearchService';

// ===== Sync 基础层导出（Sprint3 批次3-Step1 已迁移） =====
export { SyncableEntity, SyncChangeType } from './src/main/ets/service/sync/Syncable';
export { CloudStorageProvider, AuthResult, DeviceRegisterResult } from './src/main/ets/service/sync/CloudStorageProvider';

// ===== Utils 导出（Sprint3 批次3-Step1 已迁移） =====
export { DataLineage, LineageRecord } from './src/main/ets/utils/DataLineage';

// ===== Manager 层导出（Sprint3 批次1 已迁移） =====
export { MemberManager } from './src/main/ets/manager/MemberManager';
export { BasketManager } from './src/main/ets/manager/BasketManager';
export { ReportCacheManager } from './src/main/ets/manager/ReportCacheManager';
export { RepositoryManager } from './src/main/ets/manager/RepositoryManager';

// ===== 工具层导出（Sprint3 批次2 已迁移至 hsp_core） =====
// OfflineFoodDatabase 和 GlobalStateProvider 已迁移至 hsp_core
