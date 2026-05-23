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

export class NutritionTarget {
  memberId: string = '';
  sodiumMax_mg: number = 2000;
  sugarMax_g: number = 50;
  caloriesTarget: number = 2000;
  fatMax_g: number = 65;
  proteinTarget_g: number = 60;
  fiberTarget_g: number = 25;
  fiberMin_g: number = 10;
  presetName: string = '';
}

export function createDefaultNutritionTarget(memberId: string): NutritionTarget {
  const t = new NutritionTarget();
  t.memberId = memberId;
  return t;
}
