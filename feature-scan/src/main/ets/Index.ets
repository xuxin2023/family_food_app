// feature-scan 扫描功能模块入口
// Sprint3: 源码已物理迁移至本模块

// ===== 扫描服务 =====
export { ScanService } from './service/ScanService';
export { FoodInputService, FoodInputResult } from './service/FoodInputService';

// ===== 扫描相关引擎 =====
export { FoodAdapterEngine, TodayIntakeInput } from './engine/FoodAdapterEngine';
export { NutriScoreEngine } from './engine/NutriScoreEngine';
export { NovaGroupEngine, NovaGroup, NovaGroupOne, NovaGroupTwo, NovaGroupThree, NovaGroupFour, NovaEvaluationResult } from './engine/NovaGroupEngine';
export { EcoScoreEngine, EcoScoreGrade, EcoScoreResult, EcoScoreFactor } from './engine/EcoScoreEngine';
export { AlternativeFoodRecommender } from './engine/AlternativeFoodRecommender';
export { IntoleranceEngine, IntoleranceType, IntoleranceSeverity, IntoleranceWarning, IntoleranceCheckResult } from './engine/IntoleranceEngine';
export { IngredientKnowledgeBase, IngredientRiskLevel, IngredientAssessment } from './engine/IngredientKnowledgeBase';
export { IngredientSemanticEngine } from './engine/IngredientSemanticEngine';
export { CrossRiskAssessor } from './engine/CrossRiskAssessor';

// ===== 扫描相关组件 =====
export { NutriScoreBadge } from './components/NutriScoreBadge';
export { AdditiveTrafficLight, AdditiveTrafficLightList, AdditiveClassifier, AdditiveEntry, AdditiveRiskLevel } from './components/AdditiveTrafficLight';
export { AllergenHighlightList } from './components/AllergenHighlightList';
export { IntoleranceWarningCard } from './components/IntoleranceWarningCard';
export { PermissionGuideDialog } from './components/PermissionGuideDialog';
export { PaywallDialog } from './components/PaywallDialog';
export { AlternativeRecommender } from './engine/AlternativeRecommender';
