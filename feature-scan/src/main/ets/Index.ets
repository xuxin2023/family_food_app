// feature-scan 扫描功能模块入口
// Sprint3: 源码已物理迁移至本模块

// ===== 扫描服务 =====
export { ScanService } from './src/main/ets/service/ScanService';
export { FoodInputService, FoodInputResult } from './src/main/ets/service/FoodInputService';

// ===== 扫描相关引擎 =====
export { FoodAdapterEngine, TodayIntakeInput } from './src/main/ets/engine/FoodAdapterEngine';
export { NutriScoreEngine } from './src/main/ets/engine/NutriScoreEngine';
export { NovaGroupEngine, NovaGroup, NovaGroupOne, NovaGroupTwo, NovaGroupThree, NovaGroupFour, NovaEvaluationResult } from './src/main/ets/engine/NovaGroupEngine';
export { EcoScoreEngine, EcoScoreGrade, EcoScoreResult, EcoScoreFactor } from './src/main/ets/engine/EcoScoreEngine';
export { AlternativeFoodRecommender } from './src/main/ets/engine/AlternativeFoodRecommender';
export { IntoleranceEngine, IntoleranceType, IntoleranceSeverity, IntoleranceWarning, IntoleranceCheckResult } from './src/main/ets/engine/IntoleranceEngine';
export { IngredientKnowledgeBase, IngredientRiskLevel, IngredientAssessment } from './src/main/ets/engine/IngredientKnowledgeBase';
export { IngredientSemanticEngine } from './src/main/ets/engine/IngredientSemanticEngine';
export { CrossRiskAssessor } from './src/main/ets/engine/CrossRiskAssessor';

// ===== 扫描相关组件 =====
export { NutriScoreBadge } from './src/main/ets/components/NutriScoreBadge';
export { AdditiveTrafficLight } from './src/main/ets/components/AdditiveTrafficLight';
export { AllergenHighlightList } from './src/main/ets/components/AllergenHighlightList';
export { IntoleranceWarningCard } from './src/main/ets/components/IntoleranceWarningCard';
export { PermissionGuideDialog } from './src/main/ets/components/PermissionGuideDialog';
export { PaywallDialog } from './src/main/ets/components/PaywallDialog';
