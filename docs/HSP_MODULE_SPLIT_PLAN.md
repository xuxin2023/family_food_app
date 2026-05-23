# HSP 模块化拆分规划文档

> 生成日期：2026-05-15
> 项目：family_food_app（家庭食品适配助手）
> 目标：从单 entry HAP 拆分为 entry(壳) + 5个 HSP 模块

---

## 1. 当前状态

- **架构**：单 entry HAP，267 个源文件
- **SDK**：compatibleSdkVersion/targetSdkVersion = 6.1.0(23)
- **问题**：模块耦合严重，service ↔ engine 循环依赖，engine → service/repository 反向依赖

---

## 2. 目标架构

```
entry (壳工程)
  ├── Ability入口 + Navigation + 全局状态
  ├── 通用页面 (HomePage, SettingsPage, ...)
  └── 依赖5个HSP模块

hsp-core (零业务依赖)
  ├── model/ (25文件)
  ├── constants/ (11文件)
  └── utils/ (纯工具子集, ~25文件)

hsp-service (依赖 hsp-core)
  ├── repository/ (12文件)
  ├── service/ (49文件)
  ├── manager/ (13文件)
  └── utils/ (业务工具: DataPortability, GlobalErrorHandler, ...)

feature-scan (依赖 hsp-core, hsp-service)
  ├── pages/ (ScanPage, OffSearchPage)
  ├── components/ (QuickFoodInput, LinkInputDialog)
  └── service/ (ScanService, OcrService, ...)

feature-report (依赖 hsp-core, hsp-service)
  ├── engine/ (27文件)
  ├── pages/ (ReportPage, WeeklyReportPage, ...)
  ├── components/ (EcoScoreDetail, NovaGroupBadge, ...)
  └── utils/ (ReportExporter)

feature-community (依赖 hsp-core, hsp-service)
  ├── pages/ (RecipeCommunityPage, RecipeDetailPage, ...)
  └── components/ (MemberCard, HomeMemberList, ...)
```

---

## 3. 依赖图

```
                    ┌──────────┐
                    │ hsp-core │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
      ┌───────────┐  ┌────────────┐  ┌──────────────┐
      │hsp-service│  │feature-    │  │feature-      │
      │(repo+svc+ │  │report      │  │community     │
      │ manager)  │  │(engine+    │  │(pages+       │
      └───────────┘  │ pages)     │  │ components)  │
                     └────────────┘  └──────────────┘

      feature-scan ──> hsp-core, hsp-service
      feature-report ─> hsp-core, hsp-service
      feature-community ─> hsp-core, hsp-service

      entry ──> hsp-core, hsp-service, feature-scan, feature-report, feature-community
```

---

## 4. 循环依赖与修复方案（前置条件！）

### 4.1 service ↔ engine 循环依赖（严重）

| service文件 | 依赖的engine | 修复方案 |
|---|---|---|
| `AiNutritionistService` | `NutritionTrendEngine` | 提取引擎输出类型(DailyNutritionSummary等)到hsp-core/model，service仅引用类型 |
| `AiWeeklyReportService` | `WeeklyReportEngine` | 提取WeeklyReport/WeeklyDietData类型到hsp-core/model |
| `DataService` | `AlternativeFoodRecommender` + `RuleEngine` | DataService拆分：核心数据查询留hsp-service，引擎调度移入feature-report |
| `NutritionDomainService` | `NutritionTrendEngine` | 通过接口/DI注入引擎实例，而非直接import |

### 4.2 engine → service/repository 反向依赖（中等）

| engine文件 | 依赖目标 | 修复方案 |
|---|---|---|
| `AlternativeRecommender` | `service/OfflineFoodDatabase` | 抽象IOfflineFoodProvider接口到hsp-core |
| `NutritionTrendEngine` | `repository/HistoryRepository` | aggregateDaily()改为接收DietRecord[]参数 |

### 4.3 utils → 上层反向依赖（中等）

| utils文件 | 依赖目标 | 迁移目标 |
|---|---|---|
| `DataPortability` | 7个Repository | → hsp-service |
| `GlobalErrorHandler` | AnalyticsService | → hsp-service |
| `ReportExporter` | WeeklyReportEngine + HistoryRepository | → feature-report |
| `FavoriteDataSource` | FavoriteRepository | → hsp-service |

---

## 5. 执行步骤（按顺序）

| 步骤 | 动作 | 影响范围 | 风险 |
|---|---|---|---|
| 1 | 提取引擎输出类型到hsp-core/model | 解除service↔engine循环 | 低 |
| 2 | 重构NutritionTrendEngine: aggregateDaily()接收DietRecord[]参数 | 解除engine→repo | 中 |
| 3 | 重构AlternativeRecommender: 引入IOfflineFoodProvider接口 | 解除engine→service | 中 |
| 4 | 迁移4个跨界utils到业务模块 | 解除utils反向依赖 | 低 |
| 5 | 创建hsp-core模块 | model+constants+纯utils | 低 |
| 6 | 创建hsp-service模块 | service+repository+manager+业务utils | 高 |
| 7 | 创建feature-report模块 | engine+报告页面/组件+EngineManager | 高 |
| 8 | 创建feature-scan模块 | 扫描页面/组件/扫描服务 | 中 |
| 9 | 创建feature-community模块 | 社区/食谱页面/组件 | 中 |
| 10 | 改造entry为壳工程 | Ability+Navigation+全局状态+通用页面 | 高 |

---

## 6. entry 模块保留内容

| 内容 | 文件/目录 |
|---|---|
| Ability入口 | entryability/EntryAbility.ets, app.ets |
| FormAbility | entryformability/EntryFormAbility.ets |
| Widget | widget/FoodTrackerCard.ets |
| 全局状态 | AppState.ets |
| Navigation容器 | pages/Index.ets, pages/MainTabsPage.ets |
| 通用页面 | HomePage, SettingsPage, MemberPage, MemberEditPage, FavoritePage, HistoryPage, ShoppingListPage, ReminderRulePage, NutritionTargetPage, NutritionKnowledgePage, MealPlanPage, SubscriptionPage, PrivacyDialogPage, FeedbackPage, DeviceDashboardPage, CloudSyncSettingsPage, AiChatPage, SharePage, V2DemoPage |

---

## 7. oh-package.json5 依赖声明

```json5
// entry/oh-package.json5
{
  "dependencies": {
    "@familyfood/hsp-core": "file:../hsp-core",
    "@familyfood/hsp-service": "file:../hsp-service",
    "@familyfood/feature-scan": "file:../feature-scan",
    "@familyfood/feature-report": "file:../feature-report",
    "@familyfood/feature-community": "file:../feature-community"
  }
}

// hsp-service/oh-package.json5
{
  "dependencies": {
    "@familyfood/hsp-core": "file:../hsp-core"
  }
}

// feature-scan/oh-package.json5
{
  "dependencies": {
    "@familyfood/hsp-core": "file:../hsp-core",
    "@familyfood/hsp-service": "file:../hsp-service"
  }
}

// feature-report/oh-package.json5
{
  "dependencies": {
    "@familyfood/hsp-core": "file:../hsp-core",
    "@familyfood/hsp-service": "file:../hsp-service"
  }
}

// feature-community/oh-package.json5
{
  "dependencies": {
    "@familyfood/hsp-core": "file:../hsp-core",
    "@familyfood/hsp-service": "file:../hsp-service"
  }
}
```

---

## 8. Index.ets 导出清单

### hsp-core/Index.ets
```typescript
// 模型层 (25个)
export * from './model/AiChat'
export * from './model/AiModels'
export * from './model/AnalyticsRecord'
export * from './model/ChildProtection'
export * from './model/CloudSyncConfig'
export * from './model/CredibilityResult'
export * from './model/DailyBudget'
export * from './model/FamilyComparisonItem'
export * from './model/FamilyGroup'
export * from './model/FamilyProfile'
export * from './model/FoodAdapterTypes'
export * from './model/FoodLabel'
export * from './model/HealthSignal'
export * from './model/JsonTypes'
export * from './model/MealBalance'
export * from './model/MealPlan'
export * from './model/MemberStatus'
export * from './model/NutritionSnapshot'
export * from './model/NutritionTarget'
export * from './model/PricingModel'
export * from './model/Recipe'
export * from './model/Recommendation'
export * from './model/ReminderRule'
export * from './model/ShoppingItem'
export * from './model/V2StateDemo'

// 常量层 (11个)
export * from './constants/AppConfig'
export * from './constants/AppTheme'
export * from './constants/DbSchema'
export * from './constants/HotFoods'
export * from './constants/MealTemplates'
export * from './constants/NutritionKnowledge'
export * from './constants/PermissionDescriptions'
export * from './constants/RoutePath'
export * from './constants/RouteTable'
export * from './constants/StringRes'

// 纯工具层 (~25个)
export * from './utils/BasicDataSource'
export * from './utils/CacheManager'
export * from './utils/DataIntegrityChecker'
export * from './utils/DateUtil'
export * from './utils/DebounceThrottle'
export * from './utils/EnumSafeParse'
export * from './utils/ErrorHandler'
export * from './utils/ImageCache'
export * from './utils/JsonHelper'
export * from './utils/JsonUtil'
export * from './utils/KeyFactory'
export * from './utils/Logger'
export * from './utils/LruCache'
export * from './utils/MathUtil'
export * from './utils/ModelConverter'
export * from './utils/NavigationManager'
export * from './utils/ObservableMap'
export * from './utils/PageTransitionConfig'
export * from './utils/PrivacyContentUtil'
export * from './utils/RecipeUtil'
export * from './utils/RouterUtil'
export * from './utils/SecureKeyStore'
export * from './utils/ToastHelper'
export * from './utils/AccessibilityManager'
export * from './utils/AssetKeyManager'
```

### hsp-service/Index.ets
```typescript
// 仓库层 (12个)
export * from './repository/FamilyGroupRepository'
export * from './repository/FamilyRepository'
export * from './repository/FavoriteRepository'
export * from './repository/FoodRepository'
export * from './repository/HistoryRepository'
export * from './repository/NutritionSnapshotRepository'
export * from './repository/NutritionTargetRepository'
export * from './repository/RecipeRepository'
export * from './repository/ReminderRuleRepository'
export * from './repository/RuleRepository'
export * from './repository/ShoppingListRepository'
export * from './repository/SyncQueueRepository'

// 服务层 (49个 - 含子目录)
export * from './service/AiChatService'
export * from './service/AuthService'
export * from './service/ScanService'
// ... 其余服务

// 管理器层 (13个)
export * from './manager/RepositoryManager'
export * from './manager/FoodDomainService'
// ... 其余管理器

export { ServiceManager } from './ServiceManager'
```

### feature-scan/Index.ets
```typescript
export { ScanPage } from './pages/ScanPage'
export { OffSearchPage } from './pages/OffSearchPage'
export { ScanService } from './service/ScanService'
export { OcrService } from './service/OcrService'
export { FoodInputService } from './service/FoodInputService'
```

### feature-report/Index.ets
```typescript
export { ReportPage } from './pages/ReportPage'
export { WeeklyReportPage } from './pages/WeeklyReportPage'
export { AlternativeFoodPage } from './pages/AlternativeFoodPage'
export { BalancePage } from './pages/BalancePage'
export { BasketCheckPage } from './pages/BasketCheckPage'
export { NutriScoreEngine } from './engine/NutriScoreEngine'
export { WeeklyReportEngine } from './engine/WeeklyReportEngine'
export { RecommendationEngine } from './engine/RecommendationEngine'
export { RuleEngine } from './engine/RuleEngine'
export { EngineManager } from './EngineManager'
```

### feature-community/Index.ets
```typescript
export { RecipeCommunityPage } from './pages/RecipeCommunityPage'
export { RecipeDetailPage } from './pages/RecipeDetailPage'
export { RecipeCreatePage } from './pages/RecipeCreatePage'
export { GroupFeedPage } from './pages/GroupFeedPage'
export { FamilyGroupPage } from './pages/FamilyGroupPage'
```

---

## 9. build-profile.json5 改造

```json5
{
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry",
      "targets": [{ "name": "default", "applyToProducts": ["default"] }]
    },
    {
      "name": "hsp-core",
      "srcPath": "./hsp-core",
      "targets": [{ "name": "default", "applyToProducts": ["default"] }]
    },
    {
      "name": "hsp-service",
      "srcPath": "./hsp-service",
      "targets": [{ "name": "default", "applyToProducts": ["default"] }]
    },
    {
      "name": "feature-scan",
      "srcPath": "./feature-scan",
      "targets": [{ "name": "default", "applyToProducts": ["default"] }]
    },
    {
      "name": "feature-report",
      "srcPath": "./feature-report",
      "targets": [{ "name": "default", "applyToProducts": ["default"] }]
    },
    {
      "name": "feature-community",
      "srcPath": "./feature-community",
      "targets": [{ "name": "default", "applyToProducts": ["default"] }]
    }
  ]
}
```
