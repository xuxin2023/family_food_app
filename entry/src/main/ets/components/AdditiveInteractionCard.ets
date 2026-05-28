import { InteractionAssessmentResult, AdditiveInteraction } from 'feature_scan';
import { COLORS, RADIUS } from 'hsp_core';

@ComponentV2
export struct AdditiveInteractionCard {
  @Param result: InteractionAssessmentResult | null = null;

  build() {
    if (this.result !== null && this.result.riskyPairs.length > 0) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text(this.result.overallRiskScore >= 4 ? '🔴' : '🟡')
            .fontSize(18)
          Text('添加剂交互毒性')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.riskColor)
            .layoutWeight(1)
          Text(`风险 ${this.result.overallRiskScore}/5`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.riskColor)
        }
        .width('100%')

        ForEach(this.result.riskyPairs, (pair: AdditiveInteraction) => {
          Column({ space: 4 }) {
            Row({ space: 6 }) {
              Text(`${pair.additiveA} + ${pair.additiveB}`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(COLORS.TEXT_PRIMARY)
              Text(`风险${pair.riskLevel}`)
                .fontSize(11)
                .fontColor(this.levelColor(pair.riskLevel))
                .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                .backgroundColor(this.levelColor(pair.riskLevel) + '1A')
                .borderRadius(4)
            }
            Text(pair.description)
              .fontSize(12)
              .fontColor('#666666')
            Text(`影响: ${pair.affectedSystems.join('、')}`)
              .fontSize(11)
              .fontColor('#999999')
          }
          .width('100%')
          .padding(8)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
        }, (pair: AdditiveInteraction) => `${pair.additiveA}_${pair.additiveB}`)

        if (this.result.recommendations.length > 0) {
          Column({ space: 4 }) {
            ForEach(this.result.recommendations, (rec: string) => {
              Text(`💡 ${rec}`)
                .fontSize(12)
                .fontColor('#666666')
            })
          }
          .margin({ top: 4 })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(RADIUS.MD)
      .border({ width: 1, color: '#EEEEEE' })
    }
  }

  private get riskColor(): string {
    if (this.result === null) return '#999999';
    if (this.result.overallRiskScore >= 4) return '#E53935';
    if (this.result.overallRiskScore >= 2) return '#FF9800';
    return '#4CAF50';
  }

  private levelColor(level: number): string {
    if (level >= 4) return '#E53935';
    if (level >= 2) return '#FF9800';
    return '#4CAF50';
  }
}
