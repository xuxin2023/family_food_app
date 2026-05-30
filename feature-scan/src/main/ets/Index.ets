// feature-scan 扫描功能模块入口
// Sprint3: 源码已物理迁移至本模块

// ===== 扫描服务 =====
export { ScanService, ScanLookupResult, ILocalCacheProvider, IRemoteLookupProvider, IDataLineageRecorder, RemoteLookupResult, QrScanResult, OfflineScanEntry } from './service/ScanService';
export { FoodInputService, FoodInputResult } from './service/FoodInputService';

// ===== 扫描相关引擎 =====
export { FoodAdapterEngine, TodayIntakeInput, DailyBudgetInput, FamilyMemberSimpleInput, FoodNutritionInput, HealthSignalInput } from './engine/FoodAdapterEngine';
export { NutriScoreEngine, NutriScoreBreakdown, NutriScoreInput } from './engine/NutriScoreEngine';
export { NovaGroupEngine, NovaGroup, NovaGroupOne, NovaGroupTwo, NovaGroupThree, NovaGroupFour, NovaEvaluationResult } from './engine/NovaGroupEngine';
export { EcoScoreEngine, EcoScoreGrade, EcoScoreResult, EcoScoreFactor } from './engine/EcoScoreEngine';
export { AlternativeFoodRecommender, alternativeFoodRecommender } from './engine/AlternativeFoodRecommender';
export { IntoleranceEngine, IntoleranceType, IntoleranceSeverity, IntoleranceWarning, IntoleranceCheckResult } from './engine/IntoleranceEngine';
export { IngredientKnowledgeBase, IngredientRiskLevel, IngredientAssessment } from './engine/IngredientKnowledgeBase';
export { IngredientSemanticEngine, AllergenMatchResult, AllergenMatchDetail, TraceDeclaration } from './engine/IngredientSemanticEngine';
export { CrossRiskAssessor } from './engine/CrossRiskAssessor';

// ===== 扫描相关组件 =====
export { NutriScoreBadge } from './components/NutriScoreBadge';
export { AdditiveTrafficLight, AdditiveTrafficLightList, AdditiveClassifier, AdditiveEntry, AdditiveRiskLevel } from './components/AdditiveTrafficLight';
export { AllergenHighlightList } from './components/AllergenHighlightList';
export { IntoleranceWarningCard } from './components/IntoleranceWarningCard';
export { PermissionGuideDialog } from './components/PermissionGuideDialog';
export { PaywallDialog } from './components/PaywallDialog';
export { AlternativeRecommender, AlternativeCandidate } from './engine/AlternativeRecommender';
export { AllergenAutoDetector, SuspectedAllergen, AdverseReactionRecord, AllergenCheckResult } from './engine/AllergenAutoDetector';
export { AdditiveInteractionEngine, AdditiveInteraction, InteractionAssessmentResult } from './engine/AdditiveInteractionEngine';
export { OnDeviceInferenceEngine, InferenceResult } from './engine/OnDeviceInferenceEngine';
export { AdditiveSafetyEngine, AdditiveRiskLevel as AdditiveSafetyRiskLevel, AdditiveAssessment, FoodAdditiveReport } from './engine/AdditiveSafetyEngine';
export { AllergenCrossReactivityEngine, CrossReactivityPair, AllergenCrossReport, CrossReactiveRisk } from './engine/AllergenCrossReactivityEngine';
export { IngredientDeepAnalyzer, IngredientAnalysis } from './engine/IngredientDeepAnalyzer';

// ===== T-068 entry瘦身迁移: 端侧AI引擎 =====
export { OnDeviceAiEngine, IngredientAnalysis as AiIngredientAnalysis, PersonalizedAdviceOutput } from './engine/OnDeviceAiEngine';

// ===== T-068 entry瘦身迁移: 扫描服务 =====
export { OcrService } from './service/OcrService';
export { OnlineShoppingParser, ParsedShoppingItem } from './service/OnlineShoppingParser';
