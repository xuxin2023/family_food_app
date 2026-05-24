// NutrientProgress.ets
// 通用营养素进度条组件 — 统一 DashboardPage/ReportPage/DietDiaryPage 中的进度条展示

import { COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS } from 'hsp_core';

@ComponentV2
export struct NutrientProgress {
  @Param label: string = ''
  @Param current: number = 0
  @Param target: number = 0
  @Param unit: string = ''
  @Param color: string = '#4CAF50'
  @Param isCompact: boolean = false

  private getPercent(): number {
    if (this.target <= 0) return 0;
    return Math.min(100, Math.round((this.current / this.target) * 100));
  }

  private getProgressColor(): string {
    const pct = this.getPercent();
    if (pct > 80) return COLORS.ACCENT_RED_EF53;
    if (pct > 50) return COLORS.ACCENT_ORANGE_FFA7;
    return this.color;
  }

  build() {
    if (this.isCompact) {
      this.buildCompact()
    } else {
      this.buildFull()
    }
  }

  @Builder
  buildCompact() {
    Column() {
      Text(this.label)
        .fontSize(9)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ bottom: 2 })

      Stack() {
        Column()
          .width('100%')
          .height(4)
          .borderRadius(2)
          .backgroundColor(COLORS.DIVIDER)
        Column()
          .width(`${Math.min(100, this.getPercent())}%`)
          .height(4)
          .borderRadius(2)
          .backgroundColor(this.getProgressColor())
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
    }
    .layoutWeight(1)
  }

  @Builder
  buildFull() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)

        Blank()

        Text(`${this.current.toFixed(1)} ${this.unit}`)
          .fontSize(FONT_SIZE.TITLE_LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(this.color)

        Text(` / ${this.target.toFixed(0)}${this.unit}`)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ left: 2 })
          .alignSelf(ItemAlign.End)
      }
      .width('100%')
      .padding({ left: SPACING.SM, right: SPACING.SM, bottom: SPACING.XS })

      Row() {
        Row()
          .width(`${this.getPercent()}%`)
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.color)
        Blank()
      }
      .width('100%')
      .padding({ left: SPACING.SM, right: SPACING.SM })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
    .accessibilityText(`${this.label}：${this.current.toFixed(1)}${this.unit}，目标${this.target.toFixed(0)}${this.unit}，${this.getPercent()}%`)
    .accessibilityLevel('yes')
  }
}
