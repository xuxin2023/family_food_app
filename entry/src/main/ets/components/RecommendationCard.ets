import { Recommendation, getLevelColorValue, COLORS, NullGuard } from 'hsp_core';
// 适配结论卡组件 @ReusableV2 高频复用

@ReusableV2
@ComponentV2
export struct RecommendationCard {
  @Param recommendation: Recommendation = new Recommendation();
  @Param memberName: string = '';
  @Param showDetails: boolean = true;

  private get safeLevel(): string {
    return this.recommendation?.level ?? '';
  }

  private get safeLevelColor(): string {
    return this.recommendation?.levelColor ?? '';
  }

  private get safeMaxAmount(): number {
    return this.recommendation?.maxAmount ?? 0;
  }

  private get safeReasons(): string[] {
    return NullGuard.safeArray(this.recommendation?.reasons);
  }

  private get safeReminders(): string[] {
    return NullGuard.safeArray(this.recommendation?.reminders);
  }

  build() {
    Column() {
      Row() {
        Text(this.memberName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width(50)

        Text(this.safeLevel)
          .fontSize(14)
          .fontColor(COLORS.WHITE)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor(this.safeLevelColor)
          .margin({ left: 8 })

        if (this.safeMaxAmount > 0) {
          Text(`最多${this.safeMaxAmount}g`)
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

      if (this.showDetails && this.safeReasons.length > 0) {
        Column() {
          ForEach(this.safeReasons, (reason: string) => {
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

      if (this.showDetails && this.safeReminders.length > 0) {
        Column() {
          ForEach(this.safeReminders, (reminder: string) => {
            Row() {
              Text('!').fontSize(12).margin({ right: 4 })
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
    .accessibilityText(`适配建议：${this.memberName}，${this.safeLevel}，${this.safeReasons.join('，')}`)
    .accessibilityLevel('yes')
  }
}
