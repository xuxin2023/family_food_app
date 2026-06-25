// feature-profile: 个人档案ViewModel
// 管理用户资料、营养摘要、扫描历史等数据

import { FoodLabel, DailyBudget, NutritionSnapshot, HILOG_DOMAIN_DEFAULT, SCORE_COLORS } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ProfileViewModel';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@ObservedV2
export class ProfileViewModel {
  @Trace isLoading: boolean = false;
  @Trace userAvatar: string = '';
  @Trace userNickname: string = '';
  @Trace familyMemberCount: number = 0;
  @Trace weekNutritionScore: number = 0;
  @Trace weekCalorieAvg: number = 0;
  @Trace weekSodiumAvg: number = 0;
  @Trace weekSugarAvg: number = 0;
  @Trace recentScans: FoodLabel[] = [];
  @Trace totalScanCount: number = 0;

  loadFromData(
    nickname: string,
    avatar: string,
    memberCount: number,
    recentFoodLabels: FoodLabel[],
    budget: DailyBudget | null,
    snapshot: NutritionSnapshot | null
  ): void {
    this.isLoading = false;
    this.userNickname = nickname;
    this.userAvatar = avatar;
    this.familyMemberCount = memberCount;
    this.recentScans = recentFoodLabels.slice(0, 5);
    this.totalScanCount = recentFoodLabels.length;

    if (budget !== null) {
      const calBudget: number = budget.calorieBudget > 0 ? budget.calorieBudget : 2000;
      const sodBudget: number = budget.sodiumBudget > 0 ? budget.sodiumBudget : 2000;
      const sugBudget: number = budget.sugarBudget > 0 ? budget.sugarBudget : 50;
      this.weekCalorieAvg = Math.round((calBudget - budget.calorieRemaining) * 100 / calBudget);
      this.weekSodiumAvg = Math.round((sodBudget - budget.sodiumRemaining) * 100 / sodBudget);
      this.weekSugarAvg = Math.round((sugBudget - budget.sugarRemaining) * 100 / sugBudget);
    }

    if (snapshot !== null) {
      this.weekNutritionScore = this.gradeToScore(snapshot.nutriGrade);
    }
  }

  reset(): void {
    this.isLoading = true;
    this.userAvatar = '';
    this.userNickname = '';
    this.familyMemberCount = 0;
    this.weekNutritionScore = 0;
    this.weekCalorieAvg = 0;
    this.weekSodiumAvg = 0;
    this.weekSugarAvg = 0;
    this.recentScans = [];
    this.totalScanCount = 0;
  }

  getScoreColor(): string {
    if (this.weekNutritionScore >= 80) return SCORE_COLORS.GRADE_A;
    if (this.weekNutritionScore >= 60) return SCORE_COLORS.GRADE_C;
    return SCORE_COLORS.GRADE_E;
  }

  getScoreLabel(): string {
    if (this.weekNutritionScore >= 80) return '优良';
    if (this.weekNutritionScore >= 60) return '一般';
    return '待改善';
  }

  private gradeToScore(grade: string): number {
    if (grade.length === 0) return 0;
    const ch: string = grade.substring(0, 1).toUpperCase();
    if (ch === 'A') return 90;
    if (ch === 'B') return 75;
    if (ch === 'C') return 55;
    if (ch === 'D') return 35;
    if (ch === 'E') return 15;
    return 0;
  }
}
