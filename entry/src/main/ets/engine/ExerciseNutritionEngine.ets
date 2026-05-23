import { FamilyProfile, AgeGroup, HealthSignal, BpStatus, BsStatus, NutritionTarget, NutritionThreshold } from 'hsp_core';
// ExerciseNutritionEngine.ets
// 运动后实时营养推荐引擎
// 根据运动类型、时长、强度及成员健康状态，生成补水/补能/补蛋白等营养建议


/** 运动类型枚举 */
export enum ExerciseType {
  WALK = 'walk',
  RUN = 'run',
  CYCLE = 'cycle',
  SWIM = 'swim',
  STRENGTH = 'strength',
  YOGA = 'yoga',
  HIIT = 'hiit',
  OTHER = 'other'
}

/** 运动记录 */
export class ExerciseSession {
  type: ExerciseType = ExerciseType.OTHER;
  durationMinutes: number = 0;
  estimatedCalorieBurn: number = 0;
  stepCount: number = 0;
  timestamp: number = 0;
}

/** 营养补充项 */
export class NutrientSupplement {
  name: string = '';
  amount: string = '';
  reason: string = '';
  priority: number = 0;
}

/** 运动后营养推荐结果 */
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
  avoidItems: string[] = [];
}

/** 恢复阶段判定规则 */
interface RecoveryRule {
  minMin: number;
  minBurn: number;
  phase: string;
}

const RECOVERY_RULES: RecoveryRule[] = [
  { minMin: 75, minBurn: 500, phase: '高强度恢复' },
  { minMin: 45, minBurn: 300, phase: '深度恢复' },
  { minMin: 20, minBurn: 0, phase: '轻量恢复' },
];

function determineRecoveryPhase(minutes: number, calories: number): string {
  for (const rule of RECOVERY_RULES) {
    if (minutes >= rule.minMin && calories >= rule.minBurn) return rule.phase;
  }
  return '轻量恢复';
}

export class ExerciseNutritionEngine {

  /**
   * 根据运动记录、成员档案、健康信号和营养目标，生成运动后营养推荐
   */
  recommend(
    session: ExerciseSession,
    profile: FamilyProfile,
    signal: HealthSignal,
    _target: NutritionTarget
  ): ExerciseNutritionRecommendation {
    const result = new ExerciseNutritionRecommendation();
    result.exerciseType = session.type;
    result.recoveryPhase = determineRecoveryPhase(session.durationMinutes, session.estimatedCalorieBurn);

    // 补水建议（毫升）= 基础 200ml + 每 30 分钟 150ml
    result.hydrationMl = 200 + Math.floor(session.durationMinutes / 30) * 150;
    if (result.hydrationMl < 200) result.hydrationMl = 200;

    // 恢复热量 = 消耗的 30%~50%
    result.totalRecommendedCalories = Math.round(session.estimatedCalorieBurn * 0.4);

    // 运动营养补充
    result.supplements = this.buildSupplements(session, profile, signal);

    // 时间建议
    result.timingAdvice = this.buildTimingAdvice(session, result);

    // 成员特殊提示 & 避免项
    result.memberSpecificNote = this.buildMemberNote(profile, signal);
    result.avoidItems = this.buildAvoidItems(profile, signal, session);

    return result;
  }

  private buildSupplements(
    session: ExerciseSession,
    profile: FamilyProfile,
    signal: HealthSignal
  ): NutrientSupplement[] {
    const supplements: NutrientSupplement[] = [];

    // 补水
    const hyd = new NutrientSupplement();
    hyd.name = '水/电解质';
    hyd.amount = `${session.durationMinutes}分钟`;
    hyd.priority = 100;
    supplements.push(hyd);

    // 高强度力量训练 → 蛋白质
    if (session.type === ExerciseType.STRENGTH || session.type === ExerciseType.HIIT) {
      const pro = new NutrientSupplement();
      pro.name = '蛋白质';
      pro.amount = `${Math.round(session.durationMinutes * 0.4)}g`;
      pro.priority = 90;
      supplements.push(pro);
    }
    // 长时间有氧 → 碳水
    if (session.durationMinutes >= NutritionThreshold.LONG_EXERCISE_MINUTES && (session.type === ExerciseType.RUN || session.type === ExerciseType.CYCLE)) {
      const carb = new NutrientSupplement();
      carb.name = '碳水化合物';
      carb.amount = `${Math.round(session.estimatedCalorieBurn * 0.15)}g`;
      carb.priority = 80;
      supplements.push(carb);
    }

    return supplements.sort((a, b) => b.priority - a.priority);
  }

  private buildTimingAdvice(session: ExerciseSession, result: ExerciseNutritionRecommendation): string[] {
    const advice: string[] = ['运动后30分钟内补充水分'];
    if (session.durationMinutes >= 45) {
      advice.push('运动后1-2小时内补充蛋白质利于肌肉恢复');
    }
    if (result.totalRecommendedCalories > 0 && session.durationMinutes >= 30) {
      advice.push('补充适量碳水化合物恢复糖原');
    }
    return advice;
  }

  private buildMemberNote(profile: FamilyProfile, signal: HealthSignal): string {
    const notes: string[] = [];

    if (profile.ageGroup === AgeGroup.CHILD) {
      notes.push('儿童运动后应避免过度进补');
    } else if (profile.ageGroup === AgeGroup.OLD) {
      notes.push('老年阶段应注意关节保护，运动后充分拉伸');
    }

    if (signal.manualBpStatus === BpStatus.HIGH) {
      notes.push('血压偏高，运动后避免剧烈波动');
    }
    if (signal.manualBsStatus === BsStatus.HIGH) {
      notes.push('血糖偏高，选择低GI食物补充');
    }

    return notes.join('；') || '';
  }

  private buildAvoidItems(
    profile: FamilyProfile,
    signal: HealthSignal,
    _session: ExerciseSession
  ): string[] {
    const items: string[] = [];

    if (profile.ageGroup === AgeGroup.CHILD) {
      items.push('含咖啡因能量饮料');
    }
    if (signal.manualBpStatus === BpStatus.HIGH) {
      items.push('高钠运动饮料');
    }
    if (signal.manualBsStatus === BsStatus.HIGH) {
      items.push('高糖运动凝胶');
    }

    return items;
  }
}
