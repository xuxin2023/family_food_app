// feature-report 报告功能模块入口
// Sprint3: 源码已物理迁移至本模块
// 重复 Engine/Component 已删除，从 feature-scan 重新导出

// ===== 从 feature-scan 重新导出的共享引擎 =====
export { NutriScoreEngine, NutriScoreBreakdown, NutriScoreInput } from 'feature_scan';
export { NovaGroupEngine, NovaGroup, NovaEvaluationResult } from 'feature_scan';
export { EcoScoreEngine, EcoScoreGrade, EcoScoreResult, EcoScoreFactor } from 'feature_scan';
export { AlternativeFoodRecommender, alternativeFoodRecommender } from 'feature_scan';
export { AlternativeRecommender, AlternativeCandidate } from 'feature_scan';
export { NutriScoreBadge } from 'feature_scan';

// ===== 报告引擎（本模块独有） =====
export { WeeklyReportEngine, WeeklyReport, WeeklyDietData, NutrientComparison, NutrientStatus, PurchaseAdvice } from './engine/WeeklyReportEngine';
export { NutritionTrendEngine, nutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, DailyNutrientPoint, TrendDirection, MealGroup } from './engine/NutritionTrendEngine';
export { HealthTrendPredictor, TrendPrediction } from './engine/HealthTrendPredictor';
export { CredibilityEngine } from './engine/CredibilityEngine';
export { ChildProtectionEngine, MealTimeParams } from './engine/ChildProtectionEngine';
export { PregnancySafetyEngine } from './engine/PregnancySafetyEngine';
export { ElderFriendlyEngine, ElderFriendlyReport } from './engine/ElderFriendlyEngine';
export { PositiveAdviceEngine, PositiveAdvice } from './engine/PositiveAdviceEngine';
export { ExerciseNutritionEngine, ExerciseNutritionRecommendation, ExerciseSession, NutrientSupplement } from './engine/ExerciseNutritionEngine';
export { CheckupReportEngine, CheckupReport, CheckupItem, HealthArchiveUpdate } from './engine/CheckupReportEngine';
export { ChildHealthAssessmentEngine, ChildHealthAssessment, SnackImpactAssessment, AdditiveSafetyResult, AdditiveSafetyLevel } from './engine/ChildHealthAssessmentEngine';
export { PersonalizedRecommendEngine, PersonalizedRecommendation, RecommendationContext, PersonalizedContext, PersonalizedFactor } from './engine/PersonalizedRecommendEngine';
export { FoodCompareEngine } from './engine/FoodCompareEngine';
export { ShanghaiGradeEngine, ShanghaiGradeResult } from './engine/ShanghaiGradeEngine';
export { RuleEngine } from './engine/RuleEngine';

// ===== 报告组件 =====
export { NovaGroupBadge } from './components/NovaGroupBadge';
export { NovaGroupDisplay } from './components/NovaGroupDisplay';
export { EcoScoreBadge, EcoScore } from './components/EcoScoreBadge';
export { EcoScoreDetail } from './components/EcoScoreDetail';
export { ComprehensiveScoreRing } from './components/ComprehensiveScoreRing';
export { NutrientRadarPanel, NutrientScores } from './components/NutrientRadarPanel';
export { NutrientProgress } from './components/NutrientProgress';
export { IntoleranceWarningCard } from './components/IntoleranceWarningCard';
export { PregnancySafetyCard } from './components/PregnancySafetyCard';
export { ChildProtectionCard } from './components/ChildProtectionCard';
export { CredibilityCard } from './components/CredibilityCard';
export { RiskAssessmentPanel } from './components/RiskAssessmentPanel';
export { TrendPredictionBar } from './components/TrendPredictionBar';
export { ShareCard, ShareCardGenerator, MemberShareInfo, ShareImageParams } from './components/ShareCard';
export { ComprehensiveRatingPanel } from './components/ComprehensiveRatingPanel';
export { AlternativeComparePanel, AlternativeCompareItem, computeNutritionDelta } from './components/AlternativeComparePanel';

// ===== T-068 entry瘦身迁移: 报告引擎 =====
export { MealBalanceEngine } from './engine/MealBalanceEngine';
export { RecommendationEngine } from './engine/RecommendationEngine';

// ===== T-068 entry瘦身迁移: 报告服务 =====
export { AiWeeklyReportService } from './service/AiWeeklyReportService';
export { InspectionDataService } from './service/InspectionDataService';
export { MilestoneService } from './service/MilestoneService';
export { HealthRefreshScheduler } from './service/HealthRefreshScheduler';
export { HealthService } from './service/HealthService';
