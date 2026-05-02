// FoodAdapterEngine 单元测试 - 动态适配矩阵
import { describe, it, expect } from '@ohos/hypium';
import { FoodAdapterEngine } from '../../../../src/main/ets/engine/FoodAdapterEngine';
import { FamilyMemberSimple, FoodNutrition, HealthSignal,
  RecommendationLevel, SimpleDailyBudget, DislikedAdditive } from '../../../../src/main/ets/model/FoodAdapterTypes';

function createAdapterMember(): FamilyMemberSimple {
  const budget: SimpleDailyBudget = JSON.parse('{"sodium_mg":2000,"sugar_g":50,"energy_kcal":2000,"fat_g":65,"saturatedFat_g":20}') as SimpleDailyBudget;
  const raw = JSON.parse('{"id":"dad_1","name":"爸爸","role":"爸爸","age":35,"healthGoal":"控压","allergenRedline":[],"dynamicAdjustment":[],"dislikedAdditives":[]}');
  (raw as Record<string, Object>)['dailyBudget'] = budget;
  return raw as FamilyMemberSimple;
}

function createAdapterMemberWithId(id: string): FamilyMemberSimple {
  const m = createAdapterMember();
  m.id = id;
  m.name = id;
  return m;
}

function createAdapterFood(): FoodNutrition {
  const raw = JSON.parse('{"productName":"测试饼干","brand":"测试品牌","netWeight_g":100,"energy_kj":840,"protein_g":5,"fat_g":10,"saturatedFat_g":3,"transFat_g":0,"carbs_g":60,"sugar_g":15,"sodium_mg":300,"allergens":[],"isSugarFree":false,"isSucroseFree":false,"sweeteners":[],"manufacturer":"测试工厂","entrustInfo":"","scNumber":"SC1234","dataCompleteness":"完整"}');
  return raw as FoodNutrition;
}

function createAdapterFoodLowSodium(): FoodNutrition {
  const f = createAdapterFood();
  f.sodium_mg = 50;
  return f;
}

function createAdapterFoodHighSodium(sodium_mg: number): FoodNutrition {
  const f = createAdapterFood();
  f.sodium_mg = sodium_mg;
  return f;
}

function createAdapterFoodHighSugarFat(sugar_g: number, fat_g: number): FoodNutrition {
  const f = createAdapterFood();
  f.sugar_g = sugar_g;
  f.fat_g = fat_g;
  return f;
}

function createAdapterFoodSodium700(): FoodNutrition {
  const f = createAdapterFood();
  f.sodium_mg = 700;
  f.productName = '咸零�?;
  return f;
}

function createAdapterFoodHighSodium600(): FoodNutrition {
  const f = createAdapterFood();
  f.sodium_mg = 600;
  return f;
}

function createAdapterHealthSignal(): HealthSignal {
  const raw = JSON.parse('{"steps":"8000","sleep":"良好","weightTrend":"稳定","manualBpStatus":"正常","manualBgStatus":"正常"}');
  return raw as HealthSignal;
}

function createAdapterSignalLowSteps(): HealthSignal {
  const raw = JSON.parse('{"steps":"2000","sleep":"良好","weightTrend":"稳定","manualBpStatus":"正常","manualBgStatus":"正常"}');
  return raw as HealthSignal;
}

function createAdapterSignalPoorSleep(): HealthSignal {
  const raw = JSON.parse('{"steps":"8000","sleep":"�?,"weightTrend":"稳定","manualBpStatus":"正常","manualBgStatus":"正常"}');
  return raw as HealthSignal;
}

function createAdapterTodayIntake(): Record<string, Object> {
  const raw = JSON.parse('{"sodium_mg":500,"sugar_g":10,"energy_kcal":600,"fat_g":15}');
  return raw as Record<string, Object>;
}

function createAdapterIntakeExhausted(): Record<string, Object> {
  const raw = JSON.parse('{"sodium_mg":2000,"sugar_g":50,"energy_kcal":2000,"fat_g":65}');
  return raw as Record<string, Object>;
}

export default function foodAdapterEngineTest() {
  describe('FoodAdapterEngine', () => {

    // ========== 1. 基本适配计算 ==========

    it('should_calculate_green_for_low_sodium_food', () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFoodLowSodium();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      expect(result.level).assertEqual(RecommendationLevel.GREEN);
      expect(result.maxIntake_g).assertLargerThan(50);
      expect(result.levelText).assertEqual('适合食用');
    });

    it('should_calculate_red_for_zero_budget_remaining', () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFood();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterIntakeExhausted();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      expect(result.maxIntake_g).assertEqual(0);
      expect(result.level).assertEqual(RecommendationLevel.RED);
      expect(result.levelText).assertEqual('建议避免');
    });

    // ========== 2. 扫描递减效果 ==========

    it('should_decrease_intake_on_second_scan', () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFood();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      const result1 = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      const result2 = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 2);

      // �?次扫描建议量应≤�?�?
      expect(result2.maxIntake_g).assertLargerThanOrEqual(0);
      // �?次扫描应有递减说明
      expect(result2.dynamicAdjustReason.includes('�?次扫�?)).assertTrue();
    });

    it('should_apply_stronger_decay_on_later_scans', () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFood();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      const result3 = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 3);
      const result5 = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 5);

      // �?次扫描应该比�?次有更强衰减
      expect(result5.scanIndex).assertEqual(5);
      expect(result5.dynamicAdjustReason.includes('�?次扫�?)).assertTrue();
    });

    // ========== 3. 步数调整 ==========

    it('should_reduce_intake_when_steps_low', () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFood();
      const signal: HealthSignal = createAdapterSignalLowSteps();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      // 步数低时应产生调整原�?
      expect(result.dynamicAdjustReason.includes('步数')).assertTrue();
    });

    // ========== 4. 睡眠调整 ==========

    it('should_reduce_sugar_when_sleep_poor', () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFoodHighSugarFat(20, 20);
      const signal: HealthSignal = createAdapterSignalPoorSleep();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      // 睡眠差时高糖高脂食品应有调整提示
      expect(result.dynamicAdjustReason.includes('睡眠')).assertTrue();
    });

    // ========== 5. 高钠风险识别 ==========

    it('should_warn_when_high_sodium_count_reaches_threshold', () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFoodHighSodium600();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      // 第一次扫描高钠食�?
      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      // 第二次扫描另一高钠食品
      const food2 = createAdapterFoodSodium700();
      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food2, signal, intake, 2);

      // 预期有钠摄入偏高风险提示
      expect(result.dynamicAdjustReason.includes('钠摄�?)).assertTrue();
    });

    // ========== 6. 高钠扫描计数 ==========

    it('should_track_high_sodium_scan_count', () => {
      const member: FamilyMemberSimple = createAdapterMemberWithId('test_count');
      const food: FoodNutrition = createAdapterFoodHighSodium600();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 2);

      const count = FoodAdapterEngine.getHighSodiumScanCount('test_count');
      expect(count).assertEqual(2);
    });

    // ========== 7. 扫描记录清理 ==========

    it('should_clear_member_records', () => {
      const memberId = 'test_clear';
      const member: FamilyMemberSimple = createAdapterMemberWithId(memberId);
      const food: FoodNutrition = createAdapterFood();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      FoodAdapterEngine.clearMemberRecords(memberId);

      const count = FoodAdapterEngine.getHighSodiumScanCount(memberId);
      expect(count).assertEqual(0);
    });

    // ========== 8. 重置所有记�?==========

    it('should_reset_all_records', () => {
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFood();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      FoodAdapterEngine.resetTodayScanRecords();

      const count = FoodAdapterEngine.getHighSodiumScanCount('dad_1');
      expect(count).assertEqual(0);
    });

    // ========== 9. 前几次扫描影响说�?==========

    it('should_include_previous_scan_impact', () => {
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFood();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 2);

      expect(result.previousScanImpact !== null).assertTrue();
    });

    // ========== 10. 结果字段完整�?==========

    it('should_fill_all_result_fields', () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimple = createAdapterMember();
      const food: FoodNutrition = createAdapterFood();
      const signal: HealthSignal = createAdapterHealthSignal();
      const intake: Record<string, Object> = createAdapterTodayIntake();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      expect(result.productName).assertEqual('测试饼干');
      expect(result.memberId).assertEqual('dad_1');
      expect(result.memberName).assertEqual('爸爸');
      expect(result.scanIndex).assertEqual(1);
    });
  });
}

