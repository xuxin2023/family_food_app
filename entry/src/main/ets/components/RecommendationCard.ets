import { Recommendation, getLevelColorValue, COLORS } from 'hsp_core';
// 适配结论卡组件 — @ReusableV2 高频复用


@ReusableV2
@ComponentV2
export struct RecommendationCard {
  @Param recommendation: Recommendation = new Recommendation();
  @Param memberName: string = '';
  @Param showDetails: boolean = true;

  build() {
    Column() {
      // 顶部：成员名 + 等级标识 + 可吃量
      Row() {
        Text(this.memberName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width(50)

        // 等级标识
        Text(this.recommendation.level)
          .fontSize(14)
          .fontColor(COLORS.WHITE)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor(getLevelColorValue(this.recommendation.levelColor))
          .margin({ left: 8 })

        // 可吃量
        if (this.recommendation.maxAmount > 0) {
          Text(`最多${this.recommendation.maxAmount}g`)
            .fontSize(14)
            .fontColor(COLORS.TEXT_GRAY_2121)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 12 })
        } else {
          Text($r('app.string.suggest_avoid'))
            .fontSize(14)
            .fontColor(COLORS.ACCENT_RED_F443)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 12 })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 详细原因
      if (this.showDetails && this.recommendation.reasons.length > 0) {
        Column() {
          ForEach(this.recommendation.reasons, (reason: string) => {
            Row() {
              Text('•').fontSize(12).fontColor(COLORS.TEXT_GRAY_7575).margin({ right: 4 })
              Text(reason).fontSize(12).fontColor(COLORS.TEXT_GRAY_6161)
            }
            .margin({ top: 4 })
          }, (reason: string, index: number) => `${index}`)
        }
        .width('100%')
        .margin({ top: 8, left: 58 })
        .alignItems(HorizontalAlign.Start)
      }

      // 提醒
      if (this.showDetails && this.recommendation.reminders.length > 0) {
        Column() {
          ForEach(this.recommendation.reminders, (reminder: string) => {
            Row() {
              Text('⚠').fontSize(12).margin({ right: 4 })
              Text(reminder).fontSize(12).fontColor(COLORS.ACCENT_ORANGE)
            }
            .margin({ top: 4 })
          }, (reminder: string, index: number) => `${index}`)
        }
        .width('100%')
        .margin({ top: 4, left: 58 })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
    .accessibilityRole('listItem')
    .accessibilityText(`适配建议：${this.memberName}，${this.recommendation.level}，${this.recommendation?.reasons?.join('，') ?? ''}`)
    .accessibilityLevel('yes')
  }
}