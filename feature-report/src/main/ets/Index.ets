// feature-report 报告功能模块入口
// Sprint3: 源码已物理迁移至本模块
// 重复 Engine/Component 已删除，从 feature-scan 重新导出

// ===== 从 feature-scan 重新导出的共享引擎 =====
export { NutriScoreEngine } from 'feature-scan';
export { NovaGroupEngine, NovaGroup, NovaEvaluationResult } from 'feature-scan';
export { EcoScoreEngine, EcoScoreGrade, EcoScoreResult, EcoScoreFactor } from 'feature-scan';
export { AlternativeFoodRecommender } from 'feature-scan';
export { AlternativeRecommender } from 'feature-scan';
export { NutriScoreBadge } from 'feature-scan';

// ===== 报告引擎（本模块独有） =====
export { WeeklyReportEngine } from './src/main/ets/engine/WeeklyReportEngine';
export { NutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from './src/main/ets/engine/NutritionTrendEngine';
export { HealthTrendPredictor, TrendPrediction } from './src/main/ets/engine/HealthTrendPredictor';
export { CredibilityEngine, CredibilityResult } from './src/main/ets/engine/CredibilityEngine';
export { ChildProtectionEngine } from './src/main/ets/engine/ChildProtectionEngine';
export { PregnancySafetyEngine } from './src/main/ets/engine/PregnancySafetyEngine';
export { ElderFriendlyEngine, ElderFriendlyReport } from './src/main/ets/engine/ElderFriendlyEngine';
export { PositiveAdviceEngine, PositiveAdvice } from './src/main/ets/engine/PositiveAdviceEngine';
export { ExerciseNutritionEngine, ExerciseNutritionRecommendation } from './src/main/ets/engine/ExerciseNutritionEngine';
export { CheckupReportEngine, CheckupReport } from './src/main/ets/engine/CheckupReportEngine';
export { ChildHealthAssessmentEngine, ChildHealthAssessment } from './src/main/ets/engine/ChildHealthAssessmentEngine';
export { PersonalizedRecommendEngine, PersonalizedRecommendation } from './src/main/ets/engine/PersonalizedRecommendEngine';
export { FoodCompareEngine } from './src/main/ets/engine/FoodCompareEngine';
export { ShanghaiGradeEngine } from './src/main/ets/engine/ShanghaiGradeEngine';
export { RuleEngine } from './src/main/ets/engine/RuleEngine';

// ===== 报告组件 =====
export { NovaGroupBadge } from './src/main/ets/components/NovaGroupBadge';
export { NovaGroupDisplay } from './src/main/ets/components/NovaGroupDisplay';
export { EcoScoreBadge } from './src/main/ets/components/EcoScoreBadge';
export { EcoScoreDetail } from './src/main/ets/components/EcoScoreDetail';
export { ComprehensiveScoreRing } from './src/main/ets/components/ComprehensiveScoreRing';
export { NutrientRadarPanel, NutrientScores } from './src/main/ets/components/NutrientRadarPanel';
export { NutrientProgress } from './src/main/ets/components/NutrientProgress';
export { IntoleranceWarningCard } from './src/main/ets/components/IntoleranceWarningCard';
export { PregnancySafetyCard } from './src/main/ets/components/PregnancySafetyCard';
export { ChildProtectionCard } from './src/main/ets/components/ChildProtectionCard';
export { CredibilityCard } from './src/main/ets/components/CredibilityCard';
export { RiskAssessmentPanel } from './src/main/ets/components/RiskAssessmentPanel';
export { TrendPredictionBar } from './src/main/ets/components/TrendPredictionBar';
export { ShareCard, ShareCardGenerator, MemberShareInfo, ShareImageParams } from './src/main/ets/components/ShareCard';
