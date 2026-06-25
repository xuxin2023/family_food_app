import { COLORS, FONT_SIZE, SPACING, RADIUS } from 'hsp_core';

export class RiskFactor {
  name: string = '';
  severity: string = '';
  description: string = '';
  affectedMembers: string[] = [];
}

export class CrossRiskResult {
  riskFactors: RiskFactor[] = [];
  overallRisk: string = '';
  overallRiskLevel: string = '';
  summary: string = '';
}

@ComponentV2
export struct RiskAssessmentPanel {
  @Param riskResult: CrossRiskResult | null = null

  build() {
    if (this.riskResult !== null && this.riskResult.riskFactors.length > 0) {
      Column() {
        Text('⚠️ 风险评估')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: SPACING.SM })

        Text(this.riskResult.summary)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(this.getRiskColor())
          .margin({ bottom: SPACING.SM })

        ForEach(this.riskResult.riskFactors, (factor: RiskFactor, index: number) => {
          Row() {
            Text(this.getSeverityIcon(factor.severity))
              .fontSize(16)
              .margin({ right: SPACING.SM })
            Column() {
              Text(factor.description)
                .fontSize(FONT_SIZE.BODY)
                .fontColor(COLORS.TEXT_PRIMARY)
              if (factor.affectedMembers.length > 0) {
                Text('影响成员: ' + factor.affectedMembers.length + '人')
                  .fontSize(FONT_SIZE.TINY)
                  .fontColor(COLORS.TEXT_TERTIARY)
                  .margin({ top: 2 })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(SPACING.SM)
          .borderRadius(RADIUS.SM)
          .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
          .margin({ bottom: SPACING.XS })
        }, (_f: RiskFactor, i: number) => i.toString())
      }
      .width('100%')
      .padding(SPACING.MD)
      .borderRadius(RADIUS.MD)
      .backgroundColor(COLORS.BG_WHITE)
      .accessibilityText(this.riskResult.summary)
      .accessibilityLevel('yes')
    }
  }

  private getRiskColor(): string {
    if (this.riskResult === null) return COLORS.TEXT_TERTIARY;
    const level = this.riskResult.overallRiskLevel;
    if (level === 'critical') return '#F44336';
    if (level === 'high') return '#FF5722';
    if (level === 'medium') return '#FF9800';
    return '#4CAF50';
  }

  private getSeverityIcon(severity: string): string {
    if (severity === 'critical') return '🔴';
    if (severity === 'high') return '🟠';
    if (severity === 'medium') return '🟡';
    return '🟢';
  }
}
