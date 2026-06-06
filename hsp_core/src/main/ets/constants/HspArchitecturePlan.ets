// HspArchitecturePlan.ets
// HSP 模块化架构拆分方案 — 从单 entry 模块演进为多 HSP + 多 Feature 模块
// 目标：减少包体积、按需加载、独立开发/测试/发布
//
// 当前架构: entry (单模块 160+ 源文件)
// 目标架构:
//   ├── entry/                    (壳工程，仅路由注册 + Ability)
//   ├── hsp-core/                 (核心HSP — 共用模型、工具、常量)
//   │   ├── model/                (FamilyProfile, FoodLabel, HealthSignal...)
//   │   ├── utils/                (EnumSafeParse, LruCache, DateUtil...)
//   │   ├── constants/            (AppConfig, AppTheme, RoutePath...)
//   │   └── engine/               (RuleEngine, NutriScore, NovaGroup...)
//   ├── hsp-service/              (服务HSP — 网络通信、数据仓库、AI服务)
//   │   ├── service/              (SecureHttpClient, AuthService, IapService...)
//   │   ├── repository/           (FoodRepository, FamilyRepository...)
//   │   └── manager/              (EngineManager, BasketManager...)
//   ├── feature-scan/             (扫码Feature — 相机 + 条码 + OCR)
//   ├── feature-report/           (报告Feature — 食品报告 + 替代品 + 对比)
//   └── feature-community/        (社区Feature — 食谱社区 + 家庭群组)
//
// 拆分步骤：
// Phase 1 — 抽取 hsp-core (模型+工具+常量+引擎)
// Phase 2 — 抽取 hsp-service (服务+仓库+管理器)
// Phase 3 — 拆分 feature-scan / feature-report / feature-community
// Phase 4 — entry 壳工程瘦身（仅保留 Ability + 路由注册）
//
// 技术约束：
// 1. HSP 间不可循环依赖
// 2. Feature 模块可依赖 HSP，但不可互相依赖
// 3. 路由统一使用 Navigation + NavPathStack
// 4. 状态共享通过 @Provider/@Consumer 或 AppStorage-V2
// 5. HSP 导出接口必须向后兼容
//
// 预期收益：
// - entry 首包体积减少 60%+（Feature 按需加载）
// - 编译速度提升 3x+（增量编译仅影响变更模块）
// - 团队协作效率提升（模块独立开发/测试/发布）
// - 商店审核通过率提升（包体积合规）

export class HspModuleConfig {
  name: string = '';
  type: string = 'hsp';
  dependencies: string[] = [];
  description: string = '';
}

function makeHspModuleConfig(name: string, type: string, dependencies: string[], description: string): HspModuleConfig {
  const cfg: HspModuleConfig = new HspModuleConfig(
  cfg.name = name;
  cfg.type = type;
  cfg.dependencies = dependencies;
  cfg.description = description;
  return cfg;
}

export const HSP_MODULES: HspModuleConfig[] = [
  makeHspModuleConfig('hsp-core', 'hsp', [], '核心模型、工具、常量、引擎'),
  makeHspModuleConfig('hsp-service', 'hsp', ['hsp-core'], '网络通信、数据仓库、AI服务、管理器'),
  makeHspModuleConfig('feature-scan', 'feature', ['hsp-core', 'hsp-service'], '扫码+条码+OCR识别'),
  makeHspModuleConfig('feature-report', 'feature', ['hsp-core', 'hsp-service'], '食品报告+替代品+对比'),
  makeHspModuleConfig('feature-community', 'feature', ['hsp-core', 'hsp-service'], '食谱社区+家庭群组')
];
