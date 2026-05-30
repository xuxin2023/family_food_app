// model/NutritionTarget.ets

export class NutritionPreset {
  id: string = '';
  name: string = '';
  sodiumMax_mg: number = 2000;
  sugarMax_g: number = 50;
  caloriesTarget: number = 2000;
  fatMax_g: number = 65;
  proteinTarget_g: number = 60;
  fiberTarget_g: number = 25;
}

export const NUTRITION_PRESETS: NutritionPreset[] = [
  ((): NutritionPreset => {
    const p = new NutritionPreset();
    p.id = 'balanced'; p.name = '均衡饮食';
    return p;
  })(),
  ((): NutritionPreset => {
    const p = new NutritionPreset();
    p.id = 'low_sodium'; p.name = '低钠控压'; p.sodiumMax_mg = 1500;
    return p;
  })(),
  ((): NutritionPreset => {
    const p = new NutritionPreset();
    p.id = 'low_sugar'; p.name = '低糖控糖'; p.sugarMax_g = 25;
    return p;
  })(),
];

export function applyPresetToTarget(target: NutritionTarget, preset: NutritionPreset): NutritionTarget {
  target.sodiumMax_mg = preset.sodiumMax_mg;
  target.sugarMax_g = preset.sugarMax_g;
  target.caloriesTarget = preset.caloriesTarget;
  target.fatMax_g = preset.fatMax_g;
  target.proteinTarget_g = preset.proteinTarget_g;
  target.fiberTarget_g = preset.fiberTarget_g;
  target.presetName = preset.name;
  return target;
}

/**
 * 营养目标
 *
 * 定义家庭成员每日各营养素的摄入目标和上限，
 * 用于饮食推荐、超标预警和膳食平衡计算。
 * 所有数值单位：钠(mg)、糖/脂肪/蛋白质/膳食纤维、热量(kcal)。
 *
 * @since 1.0.0
 */
export class NutritionTarget {
  /** 成员ID */
  memberId: string = '';
  /** 钠摄入上限(mg/天)，默认2000mg */
  sodiumMax_mg: number = 2000;
  /** 糖摄入上限(g/天)，默认50g */
  sugarMax_g: number = 50;
  /** 热量目标(kcal/天)，默认2000kcal */
  caloriesTarget: number = 2000;
  /** 脂肪摄入上限(g/天)，默认65g */
  fatMax_g: number = 65;
  /** 蛋白质目标(g/天)，默认60g */
  proteinTarget_g: number = 60;
  /** 膳食纤维目标(g/天)，默认25g */
  fiberTarget_g: number = 25;
  /** 膳食纤维下限(g/天)，默认10g */
  fiberMin_g: number = 10;
  /** 预设方案名称 */
  presetName: string = '';
}

export function createDefaultNutritionTarget(memberId: string): NutritionTarget {
  const t = new NutritionTarget();
  t.memberId = memberId;
  return t;
}
