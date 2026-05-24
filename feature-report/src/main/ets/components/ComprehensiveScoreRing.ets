// ComprehensiveScoreRing.ets
// 综合健康评分圆环组件 - 基于 NutriScore/EcoScore/NovaGroup 加权计算

import { COLORS, FONT_SIZE, SCORE_COLORS, ScoreWeightProfile } from 'hsp_core';
import { curves } from '@kit.ArkUI';

export class ComprehensiveScoreInput {
  nutriScore: number = 50;
  ecoScore: number = 50;
  novaGroup: number = 1;
  weightProfile: ScoreWeightProfile = ScoreWeightProfile.forDefault();

  constructor(nutriScore: number, ecoScore: number, novaGroup: number,
    weightProfile?: ScoreWeightProfile) {
    this.nutriScore = nutriScore;
    this.ecoScore = ecoScore;
    this.novaGroup = novaGroup;
    if (weightProfile) this.weightProfile = weightProfile;
  }
}

function calculateComprehensiveScore(input: ComprehensiveScoreInput): number {
  const novaScore = (4 - input.novaGroup + 1) / 4 * 100;
  const score = input.weightProfile.calculateComprehensiveScore(
    input.nutriScore, input.ecoScore, novaScore
  );
  return Math.max(0, Math.min(100, Math.round(score)));
}

function getScoreColor(score: number): string {
  if (score >= 80) return SCORE_COLORS.GRADE_A;
  if (score >= 60) return '#66BB6A';
  if (score >= 40) return SCORE_COLORS.GRADE_D;
  if (score >= 20) return '#FF7043';
  return SCORE_COLORS.GRADE_E;
}

function getScoreGrade(score: number): string {
  if (score >= 80) return '优秀';
  if (score >= 60) return '良好';
  if (score >= 40) return '一般';
  if (score >= 20) return '较差';
  return '避免';
}

@ComponentV2
export struct ComprehensiveScoreRing {
  @Param nutriScore: number = 50;
  @Param ecoScore: number = 50;
  @Param novaGroup: number = 1;
  @Param ringSize: number = 80;
  @Param animating: boolean = true;

  @Local animatedScore: number = 0;
  @Local ringOpacity: number = 0;
  private animDelayTimer: number = -1;

  aboutToAppear(): void {
    const target = calculateComprehensiveScore(new ComprehensiveScoreInput(
      this.nutriScore, this.ecoScore, this.novaGroup
    ));
    if (this.animating) {
      this.ringOpacity = 0;
      animateTo({ duration: 400, curve: curves.springMotion(0.4, 0.6) }, () => {
        this.ringOpacity = 1;
      });
      this.animDelayTimer = setTimeout(() => {
        animateTo({ duration: 800, curve: curves.springMotion(0.3, 0.8) }, () => {
          this.animatedScore = target;
        });
      }, 200);
    } else {
      this.animatedScore = target;
      this.ringOpacity = 1;
    }
  }

  aboutToDisappear(): void {
    if (this.animDelayTimer !== -1) {
      clearTimeout(this.animDelayTimer);
      this.animDelayTimer = -1;
    }
  }

  build() {
    Column() {
      Stack() {
        Progress({ value: this.animatedScore, total: 100, type: ProgressType.Ring })
          .width(this.ringSize)
          .height(this.ringSize)
          .style({ strokeWidth: 6 })
          .color(getScoreColor(this.animatedScore))
          .backgroundColor('#F0F0F0')

        Column() {
          Text(`${Math.round(this.animatedScore)}`)
            .fontSize(this.ringSize <= 80 ? 20 : 24)
            .fontWeight(FontWeight.Bold)
            .fontColor(getScoreColor(this.animatedScore))
          Text(getScoreGrade(this.animatedScore))
            .fontSize(10)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 1 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(this.ringSize)
      .height(this.ringSize)
      .alignContent(Alignment.Center)

      Text('综合健康评分')
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
    .opacity(this.ringOpacity)
    .accessibilityText(`综合健康评分${Math.round(this.animatedScore)}分，${getScoreGrade(this.animatedScore)}`)
    .accessibilityLevel('yes')
  }
}
