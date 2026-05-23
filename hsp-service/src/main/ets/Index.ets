// hsp-service 业务服务层入口
// Sprint1: Repository 层源码已物理迁移至本模块
// Sprint2: 高频 Service 层源码已物理迁移至本模块（第一批5个）

// ===== Repository 层导出 =====
export { FamilyRepository } from './src/main/ets/repository/FamilyRepository';
export { FoodRepository } from './src/main/ets/repository/FoodRepository';
export { HistoryRepository, ScanHistoryRecord, ScanHistoryInput, DietRecordInput, RiskDaysResult } from './src/main/ets/repository/HistoryRepository';
export { RuleRepository } from './src/main/ets/repository/RuleRepository';
export { FamilyGroupRepository } from './src/main/ets/repository/FamilyGroupRepository';
export { RecipeRepository } from './src/main/ets/repository/RecipeRepository';
export { FavoriteRepository, FavoriteItem } from './src/main/ets/repository/FavoriteRepository';
export { ShoppingListRepository } from './src/main/ets/repository/ShoppingListRepository';
export { ReminderRuleRepository } from './src/main/ets/repository/ReminderRuleRepository';
export { NutritionTargetRepository } from './src/main/ets/repository/NutritionTargetRepository';
export { NutritionSnapshotRepository } from './src/main/ets/repository/NutritionSnapshotRepository';
export { SyncQueueRepository } from './src/main/ets/repository/SyncQueueRepository';

// ===== Service 层导出（Sprint2 已迁移） =====
export { AuthService } from './src/main/ets/service/AuthService';
export { PermissionManager } from './src/main/ets/service/PermissionManager';
export { IapService } from './src/main/ets/service/IapService';
export { TeenModeManager } from './src/main/ets/service/TeenModeManager';
export { migrateDatabase } from './src/main/ets/service/DatabaseMigrationService';
export { PrivacyManager } from './src/main/ets/service/PrivacyManager';
export { AnalyticsService } from './src/main/ets/service/AnalyticsService';
export { NetworkMonitorService } from './src/main/ets/service/NetworkMonitorService';

// ===== Service 层导出（仍代理 entry，Sprint3 迁移源码） =====
// TODO(Sprint3): 以下12个Service需物理迁移至 hsp-service/src/main/ets/service/
export { CloudAuthService } from '../../entry/src/main/ets/service/CloudAuthService';
export { CloudBackendService } from '../../entry/src/main/ets/service/CloudBackendService';
export { DataService } from '../../entry/src/main/ets/service/DataService';
export { ScanService } from '../../entry/src/main/ets/service/ScanService';
export { ScanDirectService } from '../../entry/src/main/ets/service/ScanDirectService';
export { OpenFoodFactsService } from '../../entry/src/main/ets/service/OpenFoodFactsService';
export { HuaweiCloudService } from '../../entry/src/main/ets/service/HuaweiCloudService';
export { PrivacyService } from '../../entry/src/main/ets/service/PrivacyService';
export { UpdateChecker, UpdateInfo } from '../../entry/src/main/ets/service/UpdateChecker';
export { SyncService, SyncEvent } from '../../entry/src/main/ets/service/sync/SyncService';
// FamilyGroupService/RecipeCommunityService 已在 feature-community 本地实现，移除冗余代理
// CreateRecipeParams 已在 hsp_core Recipe 模型中导出

// ===== Manager 层导出（仍代理 entry，Sprint3 迁移源码） =====
// TODO(Sprint3): 以下4个Manager需物理迁移至 hsp-service/src/main/ets/manager/
export { MemberManager } from '../../entry/src/main/ets/manager/MemberManager';
export { BasketManager } from '../../entry/src/main/ets/manager/BasketManager';
export { ReportCacheManager } from '../../entry/src/main/ets/manager/ReportCacheManager';
export { RepositoryManager } from '../../entry/src/main/ets/manager/RepositoryManager';

// ===== 工具层导出（仍代理 entry，Sprint3 迁移源码） =====
// TODO(Sprint3): OfflineFoodDatabase/getGlobalState 需物理迁移至 hsp_core
export { OfflineFoodDatabase, lookupByBarcode, convertToFoodLabel } from '../../entry/src/main/ets/service/OfflineFoodDatabase';
export { getGlobalState } from '../../entry/src/main/ets/utils/GlobalStateProvider';
