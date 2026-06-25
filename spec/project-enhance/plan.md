# Implementation Plan: 项目全面完善

**Input**: Feature specification from `spec/project-enhance/spec.md`

## Summary

对 family_food_app 进行全面完善，打通4个关键缺陷链路：(1) 统一 RecipeRepository 消除跨模块类型冲突，恢复 AI 食谱推荐功能；(2) 集成 MindSpore Lite Kit 替换端侧 LLM 推理空壳；(3) 补全 feature-profile 模块 UI 和 ViewModel；(4) 清理占位页、死代码组件和冗余 re-export。技术方案采用最小侵入策略，通过接口抽象解决跨模块依赖，通过 @kit.MindSporeLiteKit 集成端侧推理，通过补全 ViewModel 和页面完善个人中心。

## Technical Context

**Language/Version**: ArkTS (HarmonyOS SDK 23, API 13+)
**Primary Dependencies**: @kit.MindSporeLiteKit (mindSporeLite), @kit.ArkData (RDB), @kit.PerformanceAnalysisKit (hilog), hsp_core/hsp_service/feature_community 模块
**Storage**: 关系型数据库 (RDB) - 已有 schema
**Testing**: 构建验证 + UI 验证
**Target Platform**: HarmonyOS 6.1+ (手机/平板/2in1)
**Project Type**: 移动应用 (HAP + HSP 多模块架构)
**Performance Goals**: 端侧推理 <3s, 页面加载 <2s, 降级切换 <1s
**Constraints**: 不破坏现有功能、构建零新增错误、12个模块依赖关系不可随意更改
**Scale/Scope**: 12模块、48页面、56组件、5门面、12仓库

## Project Structure

### Documentation (this feature)

```text
spec/project-enhance/
├── spec.md              # Feature specification
├── plan.md              # This file
└── tasks.md             # Task breakdown (to be generated)
```

### Source Code (repository root)

```text
# 关键修改文件映射

# --- P1: RecipeRepository统一 ---
entry/src/main/ets/
├── ServiceManager.ets                # 取消注释setRecipeRepo，调整导入
├── AppState.ets                      # 无需修改（已从feature_community导入）
hsp-service/src/main/ets/
├── repository/RecipeRepository.ets   # 删除此文件，改为从hsp_core导出接口
├── service/AiRecipeRecommenderService.ets  # 删除stub interface，使用hsp_core接口
├── Index.ets                         # 移除RecipeRepository re-export
feature-community/src/main/ets/
├── repository/RecipeRepository.ets   # 保留为唯一实现，RecipeUpdate扩展字段保留
├── Index.ets                         # 导出RecipeRepository + RecipeUpdate
hsp-core/src/main/ets/
├── model/                            # 新增IRecipeRepository接口定义
├── Index.ets                         # 导出IRecipeRepository

# --- P2: MindSpore Lite集成 ---
hsp-llm/src/main/ets/
├── bridge/OnDeviceLlmBridge.ets      # 替换tryNpuInference为真实MindSpore Lite调用
├── ModelManager.ets                  # 替换假模型加载为真实loadModelFromFile
├── Index.ets                         # 更新导出

# --- P3: ProfilePage补全 ---
feature-profile/src/main/ets/
├── pages/
│   └── ProfilePage.ets               # 新增：个人中心页面
├── viewmodel/
│   ├── ProfileViewModel.ets          # 充实：用户资料+营养摘要+扫描历史
│   ├── NutritionTrendViewModel.ets   # 充实：营养趋势数据
│   └── ScanHistoryViewModel.ets      # 充实：扫描历史数据
├── Index.ets                         # 导出ProfilePage + AllergySetupWizard

entry/src/main/ets/
├── pages/
│   ├── MainTabsPage.ets              # 集成ProfilePage到"我的"Tab
│   └── SettingsPage.ets              # 调整为ProfilePage的子页面

# --- P4: 死代码清理 ---
# 删除文件:
feature-scan/src/main/ets/pages/ScanPlaceholderPage.ets
feature-community/src/main/ets/pages/CommunityPlaceholderPage.ets
hsp-service/src/main/ets/pages/ServicePlaceholderPage.ets
entry/src/main/ets/components/HarmonyOS61Components.ets
entry/src/main/ets/components/Advanced3DComponents.ets
entry/src/main/ets/repository/RecipeRepository.ets

# 更新main_pages.json: 移除已删除页面的路由
entry/src/main/resources/base/profile/main_pages.json
```

**Structure Decision**: 保持现有12模块架构不变。RecipeRepository统一策略：在hsp_core新增接口定义，feature-community保留唯一实现，hsp-service删除重复实现并改用接口。ProfilePage新增在feature-profile模块中，通过Navigation栈集成到MainTabsPage。

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| 在hsp_core新增IRecipeRepository接口 | feature-community是HAP而非HSP，hsp-service无法直接依赖HAP模块 | 直接导入feature_community会引入HAP→HSP循环依赖；合并两个RecipeRepository到hsp-service会丢失feature-community的RecipeUpdate扩展字段 |
| MindSpore Lite条件编译 | 设备可能不支持NPU/Model能力，需运行时检测 | 不做检测在不支持设备上会crash；仅用try-catch无法优雅降级 |
| ProfilePage放在feature-profile而非entry | 符合模块化设计，profile功能内聚 | 放在entry会增大entry模块体积，且与feature-profile的ViewModel脱节 |

## Research & Decisions

### Decision 1: RecipeRepository统一策略 — 接口抽象层

**Decision**: 在 hsp_core 中定义 `IRecipeRepository` 接口（包含 `queryApprovedRecipes` 等方法签名），feature-community 的 RecipeRepository 实现该接口，hsp-service 的 AiRecipeRecommenderService 依赖该接口而非具体类。

**Rationale**: 
- feature-community 是 Feature HAP，hsp-service 是 HSP，HSP 不应依赖 HAP（会破坏构建）
- 两个 RecipeRepository 的 `queryApprovedRecipes` 签名实际相同（`offset, limit, category, sortBy`），AiRecipeRecommenderService 的 stub interface 参数名是 `page/size` 但实际传入的是 `0, 50`，与 offset/limit 语义一致
- 通过接口抽象，AppState 传入的 feature-community RecipeRepository 自然满足 IRecipeRepository，无需类型转换

**Alternatives considered**:
1. 将 RecipeRepository 移到 hsp-service 并删除 feature-community 版本 → 拒绝：会丢失 RecipeUpdate 的扩展字段（category, difficulty, totalMinutes, servings），且 feature-community 的社区功能依赖这些字段
2. 将 RecipeRepository 移到 hsp-core → 拒绝：hsp-core 是纯数据模型层，不应包含 RDB 仓库实现
3. 使用 re-export 中转 → 拒绝：已有先例证明 re-export 无法解决类型冲突（entry/repository/RecipeRepository.ets 就是失败的 re-export）

### Decision 2: MindSpore Lite集成 — 条件编译 + canIUse检测

**Decision**: 使用 `@kit.MindSporeLiteKit` 的 `mindSporeLite.loadModelFromFile()` 和 `model.predict()` API 进行端侧推理。通过 `canIUse('SystemCapability.AI.MindSporeLite')` 检测设备能力，不支持时直接降级到规则引擎。模型文件路径由 ModelDownloadService 管理。

**Rationale**:
- 官方文档确认 `@kit.MindSporeLiteKit` 从 API 10 起支持，当前项目 API 13+ 完全兼容
- `mindSporeLite.loadModelFromFile(modelPath, context)` 支持指定 `context.target = ['cpu']` 或 `['npu']`，NPU 不可用时自动降级到 CPU
- 现有 ModelManager 的假硬件检测 (`typeof ({} as Record<string, Object>)['AI']`) 需替换为 `canIUse` 系统调用
- 推理流程：加载模型 → 获取输入 Tensor → 填充数据 → predict → 解析输出 Tensor

**Alternatives considered**:
1. 使用 NNRt Kit → 拒绝：NNRt 是更底层的跨芯片推理接口，MindSpore Lite Kit 已封装 NNRt，无需重复封装
2. 仅使用 CPU 推理不做 NPU 检测 → 拒绝：NPU 推理性能显著优于 CPU，应在支持设备上启用
3. 不集成MindSpore Lite，仅保留规则引擎 → 拒绝：无法满足用户对真实AI分析的期望

### Decision 3: ProfilePage集成方式 — 嵌入Tab + 导航栈子页面

**Decision**: 将 ProfilePage 作为"我的"Tab 的直接内容替换 SettingsPage（SettingsPage 变为从 ProfilePage 导航进入的子页面）。ProfilePage 展示用户信息区、营养摘要卡片、功能快捷入口网格，SettingsPage 保留为完整设置列表。

**Rationale**:
- 当前"我的"Tab 直接渲染 SettingsPage（纯设置列表），缺少个人中心的核心信息展示
- ProfilePage 提供更丰富的入口（营养趋势、扫描历史、过敏配置），SettingsPage 保留深度设置项
- 符合主流 App 的"我的"页面设计模式（信息摘要 + 快捷入口 + 设置入口）

**Alternatives considered**:
1. 在 SettingsPage 顶部增加 Profile 区域 → 拒绝：SettingsPage 已有很多设置项，混入 Profile 会导致页面过长
2. 新增第6个 Tab → 拒绝：5 Tab 已是上限，增加 Tab 会破坏导航结构
3. ProfilePage 完全替代 SettingsPage → 拒绝：设置项（隐私、同步、通知等）需要独立页面展示

### Decision 4: 死代码清理 — 直接删除

**Decision**: 直接删除3个占位页文件、2个未引用组件文件、1个冗余 re-export 文件。删除前全局搜索确认无引用。

**Rationale**:
- 探索结果确认所有6个文件均无任何导入引用
- 占位页仅有静态文本，无业务逻辑
- HarmonyOS61Components 和 Advanced3DComponents 从未被任何页面使用
- entry/repository/RecipeRepository.ets 的 re-export 未被使用（AppState 直接从 feature_community 导入）

**Alternatives considered**:
1. 保留但添加 @Deprecated 注释 → 拒绝：死代码增加维护负担和构建警告
2. 将组件集成到现有页面后再删除 → 拒绝：这些组件（3D emoji查看器、Lottie假动画等）与当前功能无关，集成反而增加复杂度

## Data Model

### IRecipeRepository 接口（新增于 hsp_core）

```
接口名称: IRecipeRepository
所在模块: hsp_core
目的: 定义食谱仓库的公共契约，解耦 hsp-service 对 feature-community 的直接依赖

方法:
- init(rdbStore: RdbStore): void
- queryApprovedRecipes(offset: number, limit: number, category?: string, sortBy?: string): Promise<Recipe[]>
- getRecipe(recipeId: string): Promise<Recipe | null>
- hasBookmarked(recipeId: string, uid: string): Promise<boolean>
```

### RecipeUpdate 统一（已存在于 feature-community）

```
类名: RecipeUpdate
所在模块: feature-community（权威版本，已导出）
字段扩展: category, difficulty, totalMinutes, servings（相比hsp-service版本多4个字段）

策略: hsp-service 版本的 RecipeUpdate 删除，使用 feature-community 的导出版本
```

### ProfileViewModel（充实于 feature-profile）

```
类名: ProfileViewModel
所在模块: feature-profile
属性:
- isLoading: boolean
- userAvatar: string
- userNickname: string
- familyMemberCount: number
- weekNutritionScore: number
- recentScans: FoodLabel[] (最多5条)
- weekCalorieAvg: number
- weekSodiumAvg: number
- weekSugarAvg: number

方法:
- async loadProfile(context: Context): Promise<void>  -- 从Repository加载数据
- async refreshNutritionSummary(): Promise<void>      -- 刷新营养摘要
```

### MindSporeLite推理会话（修改于 hsp-llm）

```
类名: OnDeviceLlmBridge (修改)
新增依赖: @kit.MindSporeLiteKit
修改方法:
- tryNpuInference(): 空壳 → 调用 mindSporeLite.loadModelFromFile + model.predict
- detectNpuAvailability(): 假检测 → canIUse('SystemCapability.AI.MindSporeLite')

新增属性:
- private msModel: mindSporeLite.Model | null = null  -- 推理会话实例
- private modelLoaded: boolean = false                 -- 模型加载状态
```

## Contracts & Interfaces

### IRecipeRepository（hsp_core 新增接口）

定义位置: `hsp-core/src/main/ets/model/IRecipeRepository.ets`
消费者: `hsp-service/AiRecipeRecommenderService` (依赖注入)
提供者: `feature-community/RecipeRepository` (implements IRecipeRepository)

接口方法签名必须与 feature-community RecipeRepository 的公共方法对齐，优先包含 AiRecipeRecommenderService 实际使用的方法。

### MindSpore Lite 推理契约

调用方: `OnDeviceLlmBridge.infer()`
被调用方: `@kit.MindSporeLiteKit` 系统API

输入: PromptBuilder 构建的文本 prompt → 编码为 Float32 ArrayBuffer
输出: mindSporeLite.Model.predict() → MSTensor[] → 解码为文本结果

降级契约:
1. MindSpore Lite 推理成功 → source:'on-device', confidence: 0.9
2. MindSpore Lite 不可用/推理失败 → ruleBasedInference(), source:'rule', confidence: 0.6
3. 规则引擎无匹配 → LlmFallbackStrategy.getFallbackMessage(), source:'fallback'

### ProfilePage 导航契约

路由: 通过 MainTabsPage 的 Navigation 栈导航
Tab 4 内容: ProfilePage (替换 SettingsPage)
子路由:
- ProfilePage → SettingsPage (导航推入)
- ProfilePage → NutritionTrendPage (导航推入)
- ProfilePage → ScanHistoryTimelinePage (导航推入)
- ProfilePage → AllergenSetupWizard (导航推入)
- ProfilePage → MemberPage (导航推入)

### 模块导出契约更新

feature-profile/Index.ets:
- 新增导出: ProfilePage, AllergySetupWizard
- 已有导出: ProfileViewModel, NutritionTrendViewModel, ScanHistoryViewModel

hsp-core/Index.ets:
- 新增导出: IRecipeRepository

hsp-service/Index.ets:
- 移除导出: RecipeRepository (已删除)

feature-community/Index.ets:
- 保留导出: RecipeRepository, RecipeUpdate
