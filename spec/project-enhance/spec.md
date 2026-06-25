# Feature Specification: 项目全面完善

**Created**: 2026-06-18  
**Status**: Draft  
**Input**: 用户要求"继续完善项目"，选择"全部完善"方向

## Overview

对家庭食品适配助手（family_food_app）进行全面完善，解决已识别的关键缺陷：端侧LLM推理桥接为空壳、RecipeRepository跨模块类型冲突导致AI食谱推荐断链、feature-profile模块UI缺失、遗留占位页和死代码污染、以及多处代码质量问题。目标是打通所有核心功能链路、补全缺失UI、清理技术债务，使应用达到可发布的完成度。

## User Scenarios & Testing *(mandatory)*

### User Story 1 - AI食谱推荐完整可用 (Priority: P1)

用户在首页或AI聊天页请求"推荐适合我的食谱"，系统通过AI食谱推荐服务调用RecipeRepository获取食谱数据，结合家庭成员画像生成个性化推荐结果，推荐内容包含真实食谱而非空列表。

**Why this priority**: AI食谱推荐是核心差异化功能，当前因RecipeRepository跨模块类型冲突导致推荐链路完全断裂，属于功能性缺陷，必须最优先修复。

**Independent Test**: 可通过调用AI食谱推荐接口验证返回结果非空来独立测试，不依赖其他用户故事。

**Acceptance Scenarios**:

1. **Given** 用户已添加家庭成员且设定了过敏原和健康目标, **When** 用户在AI聊天页输入"推荐适合我家人的食谱", **Then** 系统返回包含至少3个食谱的推荐列表，每个食谱与成员健康画像兼容
2. **Given** RecipeRepository已统一为单一实现, **When** AIRecipeRecommenderService调用setRecipeRepo获取数据, **Then** 推荐服务能正常查询食谱数据，无类型错误
3. **Given** AI推荐服务初始化, **When** AppState调用initAiServices传入recipeRepo, **Then** setRecipeRepo成功执行，AI食谱推荐功能恢复

---

### User Story 2 - 端侧AI推理真实可用 (Priority: P2)

用户在无网络环境下扫描食品，系统通过端侧LLM模型进行本地推理，返回食品成分分析和健康建议，而非仅依赖正则规则匹配的固定回复。端侧推理失败时优雅降级到规则引擎，再降级到离线回退消息。

**Why this priority**: 端侧AI是离线场景的核心能力，当前NPU推理为空壳、硬件检测为假逻辑、模型加载为模拟数据，整个端侧推理链路不可用，严重影响无网络场景用户体验。

**Independent Test**: 可在飞行模式下扫描食品，验证AI分析结果来源标识为"on-device"而非"rule"来独立测试。

**Acceptance Scenarios**:

1. **Given** 设备支持NPU且模型已下载, **When** 用户在离线模式扫描食品并请求AI分析, **Then** 系统通过MindSpore Lite执行本地推理，返回带有source:'on-device'标识的分析结果
2. **Given** 设备不支持NPU或模型未就绪, **When** 用户请求AI分析, **Then** 系统降级到规则引擎推理，返回带有source:'rule'和confidence:0.6标识的结果
3. **Given** 规则引擎也无法匹配, **When** 用户请求AI分析, **Then** 系统返回友好的离线回退消息，提示"AI功能暂不可用，已切换为本地规则分析"
4. **Given** ModelManager启动, **When** 调用loadModel加载模型, **Then** 通过MindSpore Lite API真实加载模型文件，模型状态变为LOADED且有真实模型元数据

---

### User Story 3 - 个人中心完整体验 (Priority: P3)

用户切换到"我的"Tab后，能看到完整的个人中心页面，包含头像、昵称编辑、家庭成员快捷管理入口、营养趋势摘要卡片、扫描历史快捷入口和过敏原配置入口，而非当前的空白设置页。

**Why this priority**: 个人中心是高频访问页面，当前feature-profile模块ViewModel为空壳、缺少独立ProfilePage，用户在"我的"Tab只能看到基础设置列表，无法快速查看营养趋势和扫描历史，体验不完整。

**Independent Test**: 可通过切换到"我的"Tab验证页面渲染完整性和各功能入口可点击来独立测试。

**Acceptance Scenarios**:

1. **Given** 用户已登录且有扫描历史, **When** 用户切换到"我的"Tab, **Then** 页面显示用户头像、昵称、家庭成员数量、本周营养评分摘要卡片、最近扫描记录（最多5条）
2. **Given** 用户在个人中心页, **When** 用户点击营养趋势卡片, **Then** 跳转到NutritionTrendPage显示详细营养趋势图表
3. **Given** 用户在个人中心页, **When** 用户点击扫描历史入口, **Then** 跳转到ScanHistoryTimelinePage显示时间线视图
4. **Given** 用户在个人中心页, **When** 用户点击过敏原配置, **Then** 跳转到AllergenSetupWizard进行过敏原设置
5. **Given** ProfileViewModel初始化, **When** 页面加载, **Then** ViewModel从Repository获取用户资料、营养摘要和最近扫描数据并驱动UI渲染

---

### User Story 4 - 清理死代码和占位页 (Priority: P4)

作为开发者，项目代码库中不应存在未引用的占位页面和组件文件，所有@Entry装饰器应仅用于真实页面入口，减少构建警告和维护负担。

**Why this priority**: 技术债务清理，虽不影响用户直接体验，但3个占位页+2个未引用组件文件（共约700行死代码）增加维护成本和构建警告，应在新功能开发完成后清理。

**Independent Test**: 可通过搜索项目确认占位页和死代码组件文件已被删除、构建无@Entry export警告来独立测试。

**Acceptance Scenarios**:

1. **Given** 项目包含ScanPlaceholderPage/CommunityPlaceholderPage/ServicePlaceholderPage, **When** 执行清理, **Then** 这3个占位页文件被删除，且无其他文件引用它们
2. **Given** HarmonyOS61Components和Advanced3DComponents从未被引用, **When** 执行清理, **Then** 这2个组件文件被删除或被实际页面集成引用
3. **Given** entry/repository/RecipeRepository.ets为未使用的re-export, **When** 执行清理, **Then** 该文件被删除，所有引用改为直接从统一源导入

---

### Edge Cases

- 当MindSpore Lite API在当前SDK版本不可用时，如何处理编译兼容性？
- RecipeRepository统一后，feature-community和hsp-service的RecipeUpdate类型差异如何合并？
- feature-profile新增页面的路由如何与MainTabsPage现有Navigation栈集成？
- 清理死代码时，如果发现间接引用（如通过字符串拼接路由名）如何确保不误删？

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 系统必须统一RecipeRepository为单一权威实现，消除feature-community和hsp-service之间的类型冲突
- **FR-002**: 系统必须使AIRecipeRecommenderService的setRecipeRepo方法可用，恢复AI食谱推荐功能
- **FR-003**: 系统必须将OnDeviceLlmBridge的tryNpuInference从空壳替换为真实的MindSpore Lite推理调用
- **FR-004**: 系统必须实现真实的NPU硬件能力检测逻辑，替换当前的假检测
- **FR-005**: 系统必须将ModelManager的loadModel替换为真实的MindSpore Lite模型加载
- **FR-006**: 系统必须在端侧推理不可用时保持现有的规则引擎降级和离线回退逻辑不变
- **FR-007**: 系统必须在feature-profile模块中实现完整的ProfilePage页面，包含用户信息、营养摘要、快捷入口
- **FR-008**: 系统必须将ProfileViewModel、NutritionTrendViewModel、ScanHistoryViewModel从空壳实现为有真实数据和方法的ViewModel
- **FR-009**: 系统必须将AllergySetupWizard从feature-profile的Index.ets中导出，使外部模块可引用
- **FR-010**: 系统必须删除ScanPlaceholderPage、CommunityPlaceholderPage、ServicePlaceholderPage三个未引用的占位页文件
- **FR-011**: 系统必须删除或集成HarmonyOS61Components和Advanced3DComponents两个未引用的组件文件
- **FR-012**: 系统必须删除entry/repository/RecipeRepository.ets中未使用的re-export
- **FR-013**: 系统必须确保清理后构建无新增编译错误和警告
- **FR-014**: [NEEDS CLARIFICATION: MindSpore Lite API在当前HarmonyOS SDK 23中是否已正式发布？如果未发布，是否需要条件编译或接口预留？]

### Key Entities

- **RecipeRepository（统一后）**: 食谱数据仓库，提供食谱查询、创建、更新、删除、收藏检查等方法，是AI食谱推荐和社区功能的共享数据源
- **RecipeUpdate（统一后）**: 食谱更新数据结构，包含category、difficulty、totalMinutes、servings等扩展字段（采用feature-community版本的完整定义）
- **OnDeviceLlmBridge**: 端侧LLM推理桥接，负责NPU推理→规则引擎→离线回退的三级降级链路
- **ModelManager**: 端侧AI模型管理器，负责模型下载、加载、状态跟踪
- **ProfileViewModel**: 个人中心视图模型，管理用户资料、营养摘要、扫描历史等数据
- **ProfilePage**: 个人中心页面，展示用户信息和功能快捷入口

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: AI食谱推荐接口在RecipeRepository有数据时返回非空推荐列表，推荐结果与成员健康画像100%兼容
- **SC-002**: 端侧LLM推理在支持NPU的设备上返回source:'on-device'标识的结果，推理延迟低于3秒
- **SC-003**: 端侧推理不可用时，降级链路在1秒内完成切换，用户无感知中断
- **SC-004**: 个人中心页在页面加载2秒内完成渲染，展示用户资料、营养摘要和最近5条扫描记录
- **SC-005**: 项目构建零新增编译错误，@Entry export警告减少至少3个
- **SC-006**: 删除的死代码文件总数不少于5个，且无任何活跃代码引用被删除的文件

## Assumptions

- MindSpore Lite API在HarmonyOS SDK 23中已可通过@kit.AIFoundationKit引入，如未正式发布则预留接口层
- feature-community的RecipeUpdate定义（含扩展字段）为权威版本，hsp-service版本应同步对齐
- feature-profile新增的ProfilePage将作为SettingsPage的增强替代或补充，而非独立新增Tab
- 端侧LLM模型文件（.ms格式）由ModelDownloadService管理下载，本项目只负责推理调用
- 清理死代码时，通过全局搜索确认无字符串形式的间接引用
- 已有的rule-based inference作为永久降级方案保留，不删除

## Open Questions

- MindSpore Lite API在当前SDK版本的可用性和正确引入方式是什么？是否需要条件编译保护？
- feature-profile的ProfilePage应该替代当前SettingsPage还是作为其子页面推入导航栈？
- HarmonyOS61Components和Advanced3DComponents中的组件是否有计划在后续版本中使用，还是可以安全删除？
