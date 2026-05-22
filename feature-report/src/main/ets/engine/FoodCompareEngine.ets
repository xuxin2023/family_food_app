import { FoodLabel, FamilyProfile, HealthSignal, Recommendation } from 'hsp_core';
// FoodCompareEngine.ets
// 食品对比引擎 — 计算两个食品的营养差异、适配差异、综合结论


export class NutrientComparison {
  name: string = '';
  unit: string = '';
  value1: number = 0;
  value2: number = 0;
  diff: number = 0;
  percentDiff: number = 0;
  betterSide: 1 | 2 | 0 = 0;

  constructor(name: string, unit: string, value1: number, value2: number, diff: number, percentDiff: number, betterSide: 1 | 2 | 0) {
    this.name = name;
    this.unit = unit;
    this.value1 = value1;
    this.value2 = value2;
    this.diff = diff;
    this.percentDiff = percentDiff;
    this.betterSide = betterSide;
  }
}

export class MemberAdaptDiff {
  memberId: string = '';
  memberName: string = '';
  food1Level: string = '';
  food2Level: string = '';
  recommendation: string = '';

  constructor(memberId: string, memberName: string, food1Level: string, food2Level: string, recommendation: string) {
    this.memberId = memberId;
    this.memberName = memberName;
    this.food1Level = food1Level;
    this.food2Level = food2Level;
    this.recommendation = recommendation;
  }
}

export class FoodCompareResult {
  nutrientDiffs: NutrientComparison[] = [];
  memberAdaptDiffs: MemberAdaptDiff[] = [];
  overallWinner: 1 | 2 | 0 = 0;
  summary: string = '';

  constructor(nutrientDiffs: NutrientComparison[], memberAdaptDiffs: MemberAdaptDiff[], overallWinner: 1 | 2 | 0, summary: string) {
    this.nutrientDiffs = nutrientDiffs;
    this.memberAdaptDiffs = memberAdaptDiffs;
    this.overallWinner = overallWinner;
    this.summary = summary;
  }
}

export class FoodCompareEngine {
  compare(food1: FoodLabel, food2: FoodLabel): FoodCompareResult {
    const nutrientDiffs = this.buildNutrientDiffs(food1, food2);
    const winner = this.determineWinner(nutrientDiffs);
    const summary = this.buildSummary(food1, food2, nutrientDiffs, winner);
    return new FoodCompareResult(nutrientDiffs, [], winner, summary);
  }

  compareWithMembers(
    food1: FoodLabel,
    food2: FoodLabel,
    members: FamilyProfile[],
    recommendations1: Recommendation[],
    recommendations2: Recommendation[]
  ): FoodCompareResult {
    const nutrientDiffs = this.buildNutrientDiffs(food1, food2);
    const memberAdaptDiffs = this.buildMemberAdaptDiffs(members, recommendations1, recommendations2);
    const winner = this.determineWinner(nutrientDiffs);
    const summary = this.buildSummaryWithMembers(food1, food2, nutrientDiffs, memberAdaptDiffs, winner);
    return new FoodCompareResult(nutrientDiffs, memberAdaptDiffs, winner, summary);
  }

  private buildNutrientDiffs(f1: FoodLabel, f2: FoodLabel): NutrientComparison[] {
    const n1 = f1.nutrition;
    const n2 = f2.nutrition;
    return [
      this.diffItem('热量', 'kcal', n1.calories, n2.calories, true),
      this.diffItem('蛋白质', 'g', n1.protein, n2.protein, false),
      this.diffItem('脂肪', 'g', n1.fat, n2.fat, true),
      this.diffItem('饱和脂肪', 'g', n1.saturatedFat, n2.saturatedFat, true),
      this.diffItem('碳水化合物', 'g', n1.carbohydrate, n2.carbohydrate, true),
      this.diffItem('糖', 'g', n1.sugar, n2.sugar, true),
      this.diffItem('钠', 'mg', n1.sodium, n2.sodium, true),
      this.diffItem('膳食纤维', 'g', n1.fiber, n2.fiber, false),
    ];
  }

  private diffItem(name: string, unit: string, v1: number, v2: number, lowerIsBetter: boolean): NutrientComparison {
    const diff = v2 - v1;
    const base = Math.max(Math.abs(v1), Math.abs(v2), 0.01);
    const percentDiff = (diff / base) * 100;
    let betterSide: 1 | 2 | 0 = 0;
    if (Math.abs(diff) > 0.01) {
      betterSide = lowerIsBetter ? (diff > 0 ? 1 : 2) : (diff > 0 ? 2 : 1);
    }
    return new NutrientComparison(name, unit, v1, v2, diff, percentDiff, betterSide);
  }

  private buildMemberAdaptDiffs(
    members: FamilyProfile[],
    recs1: Recommendation[],
    recs2: Recommendation[]
  ): MemberAdaptDiff[] {
    const diffs: MemberAdaptDiff[] = [];
    for (const member of members) {
      const r1 = recs1.find(r => r.memberId === member.memberId);
      const r2 = recs2.find(r => r.memberId === member.memberId);
      if (r1 && r2) {
        let recommendation = '';
        if (r1.score > r2.score) {
          recommendation = `食品A更适配(${r1.score} vs ${r2.score})`;
        } else if (r2.score > r1.score) {
          recommendation = `食品B更适配(${r2.score} vs ${r1.score})`;
        } else {
          recommendation = '两食品适配度相当';
        }
        diffs.push(new MemberAdaptDiff(
          member.memberId,
          member.nickname,
          r1.level,
          r2.level,
          recommendation
        ));
      }
    }
    return diffs;
  }

  private determineWinner(diffs: NutrientComparison[]): 1 | 2 | 0 {
    const b1 = diffs.filter(d => d.betterSide === 1).length;
    const b2 = diffs.filter(d => d.betterSide === 2).length;
    if (b1 > b2) return 1;
    if (b2 > b1) return 2;
    return 0;
  }

  private buildSummary(f1: FoodLabel, f2: FoodLabel, diffs: NutrientComparison[], winner: 1 | 2 | 0): string {
    const better1 = diffs.filter(d => d.betterSide === 1);
    const better2 = diffs.filter(d => d.betterSide === 2);
    const name1 = f1.foodName || '食品A';
    const name2 = f2.foodName || '食品B';
    if (winner === 1) {
      return `${name1}在${better1.map(d => d.name).join('、')}方面更优；${name2}在${better2.map(d => d.name).join('、') || '暂无明显优势'}方面领先。`;
    } else if (winner === 2) {
      return `${name2}在${better2.map(d => d.name).join('、')}方面更优；${name1}在${better1.map(d => d.name).join('、') || '暂无明显优势'}方面领先。`;
    }
    return '两食品营养指标基本相当，建议结合个人健康目标选择。';
  }

  private buildSummaryWithMembers(
    f1: FoodLabel, f2: FoodLabel,
    diffs: NutrientComparison[], memberDiffs: MemberAdaptDiff[], winner: 1 | 2 | 0
  ): string {
    let summary = this.buildSummary(f1, f2, diffs, winner);
    if (memberDiffs.length > 0) {
      summary += '\n\n家庭适配：' + memberDiffs.map(d => `${d.memberName}: ${d.recommendation}`).join('；');
    }
    return summary;
  }
}
