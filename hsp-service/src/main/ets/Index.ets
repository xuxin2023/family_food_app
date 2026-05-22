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
export { CloudAuthService } from '../../entry/src/main/ets/service/CloudAuthService';
export { CloudBackendService } from '../../entry/src/main/ets/service/CloudBackendService';
export { DataService } from '../../entry/src/main/ets/service/DataService';
export { ScanService } from '../../entry/src/main/ets/service/ScanService';
export { ScanDirectService } from '../../entry/src/main/ets/service/ScanDirectService';
export { OpenFoodFactsService } from '../../entry/src/main/ets/service/OpenFoodFactsService';
export { FamilyGroupService } from '../../entry/src/main/ets/service/FamilyGroupService';
export { RecipeCommunityService, CreateRecipeParams } from '../../entry/src/main/ets/service/RecipeCommunityService';
export { HuaweiCloudService } from '../../entry/src/main/ets/service/HuaweiCloudService';
export { PrivacyService } from '../../entry/src/main/ets/service/PrivacyService';
export { UpdateChecker, UpdateInfo } from '../../entry/src/main/ets/service/UpdateChecker';
export { SyncService, SyncEvent } from '../../entry/src/main/ets/service/sync/SyncService';

// ===== Manager 层导出（仍代理 entry，Sprint3 迁移源码） =====
export { MemberManager } from '../../entry/src/main/ets/manager/MemberManager';
export { BasketManager } from '../../entry/src/main/ets/manager/BasketManager';
export { ReportCacheManager } from '../../entry/src/main/ets/manager/ReportCacheManager';
export { RepositoryManager } from '../../entry/src/main/ets/manager/RepositoryManager';
