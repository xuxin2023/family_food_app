import { ExerciseType } from './ExerciseTypeDef';

export class CheckupItem {
  name: string = '';
  value: number = 0;
  unit: string = '';
  isAbnormal: boolean = false;
  referenceRange: string = '';
}

export class CheckupReport {
  items: CheckupItem[] = [];
  date: string = '';
  memberId: string = '';
  summary: string = '';
  riskScore: number = 0;
}

export class HealthArchiveUpdate {
  memberId: string = '';
  updates: Map<string, string> = new Map();
}

export class NutrientSupplement {
  name: string = '';
  amountMg: number = 0;
  reason: string = '';
}

export class ExerciseNutritionRecommendation {
  exerciseType: ExerciseType = ExerciseType.OTHER;
  recoveryPhase: string = '';
  supplements: NutrientSupplement[] = [];
  hydrationMl: number = 0;
  meals: string[] = [];
  reason: string = '';
  tips: string[] = [];
  totalRecommendedCalories: number = 0;
  timingAdvice: string[] = [];
  memberSpecificNote: string = '';
}

export class PersonalizedFactor {
  name: string = '';
  weight: number = 0;
  contribution: number = 0;
  description: string = '';
}

export class PersonalizedRecommendation {
  memberId: string = '';
  foodId: string = '';
  factors: PersonalizedFactor[] = [];
  overallScore: number = 50;
  level: string = '';
  dataConfidence: number = 0.5;
  personalizedSummary: string = '';
  urgencyNote: string = '';
  maxPortion: string = '';
}

export class ChildHealthAssessment {
  memberId: string = '';
  ageMonths: number = 0;
  bmiPercentile: number = 0;
  heightPercentile: number = 0;
  weightPercentile: number = 0;
  overallStatus: string = '';
  concerns: string[] = [];
  recommendations: string[] = [];
}
