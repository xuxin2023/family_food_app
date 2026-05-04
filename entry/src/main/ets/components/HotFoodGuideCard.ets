import { router } from '@kit.ArkUI';
import { HotFoodItem, HOT_FOODS, DAILY_TIPS } from '../constants/HotFoods';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

@Component
export struct HotFoodGuideCard {
  @State currentTipIndex: number = 0
  @Prop scanHistoryCount: number = 0
  private tipTimer: number = 0

  aboutToAppear() {
    this.currentTipIndex = Math.floor(Math.random() * DAILY_TIPS.length)
    this.tipTimer = setInterval(() => {
      this.currentTipIndex = (this.currentTipIndex + 1) % DAILY_TIPS.length
    }, 6000)
  }

  aboutToDisappear() {
    if (this.tipTimer) {
      try {
        clearInterval(this.tipTimer);
      } catch (_e) {
        // ignore clearInterval error
      }
    }
  }

  build() {
    Column() {
      if (this.scanHistoryCount === 0) {
        this.FirstTimeGuide()
      } else {
        this.DailyTipCard()
      }

      Column() {
        Text($r('app.string.hot_foods'))
          .fontSize(FONT_SIZE.SUBTITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: SPACING.SM })

        Scroll() {
          Row() {
            ForEach(HOT_FOODS, (item: HotFoodItem) => {
              this.HotFoodPill(item)
            }, (item: HotFoodItem) => item.foodName)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .margin({ top: SPACING.MD })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  @Builder
  FirstTimeGuide() {
    Column() {
      Text($r('app.string.first_time_use'))
        .fontSize(FONT_SIZE.TITLE)
        .fontWeight(FONT_WEIGHT.BOLD)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: SPACING.SM })

      Text($r('app.string.first_time_hint'))
        .fontSize(FONT_SIZE.BODY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ bottom: SPACING.MD })

      Row() {
        Button('立即扫码')
          .height(36)
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(COLORS.TEXT_WHITE)
          .borderRadius(RADIUS.XXL)
          .fontSize(FONT_SIZE.BODY)
          .onClick(() => {
            try {

              router.pushUrl({ url: 'pages/ScanPage' })

            } catch (_e) {
              // ignore router.pushUrl error
            }
          })

        Text($r('app.string.quick_experience'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
      }
      .width('100%')
    }
    .width('100%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
    .borderRadius(RADIUS.MD)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: SPACING.SM })
  }

  @Builder
  DailyTipCard() {
    Row() {
      Text(DAILY_TIPS[this.currentTipIndex].emoji)
        .fontSize(FONT_SIZE.XL)
        .margin({ right: SPACING.SM })
      Text(DAILY_TIPS[this.currentTipIndex].text)
        .fontSize(FONT_SIZE.BODY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: SPACING.SM })
  }

  @Builder
  HotFoodPill(item: HotFoodItem) {
    Column() {
      Text(item.emoji)
        .fontSize(FONT_SIZE.XL)
        .margin({ bottom: SPACING.XS })
      Text(item.foodName)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: 80 })
    }
    .width(88)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
    .margin({ right: SPACING.SM })
    .shadow({ radius: 4, color: COLORS.SHADOW_LIGHT, offsetX: 0, offsetY: 1 })
    .onClick(() => {
      try {
      router.pushUrl({
        url: 'pages/ReportPage',
        params: { hotFoodName: item.foodName }
      })
      } catch (_e) {
        // ignore router.pushUrl error
      }
    })
  }
}
