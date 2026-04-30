import { router } from '@kit.ArkUI';
import { HotFoodItem, HOT_FOODS, DailyTip, DAILY_TIPS } from '../constants/HotFoods';
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
    if (this.tipTimer) clearInterval(this.tipTimer)
  }

  build() {
    Column() {
      if (this.scanHistoryCount === 0) {
        this.FirstTimeGuide()
      } else {
        this.DailyTipCard()
      }

      Column() {
        Text('🔥 热门食品')
          .fontSize(FONT_SIZE.SUBTITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: SPACING.SM })

        Scroll() {
          Row() {
            ForEach(HOT_FOODS, (item: HotFoodItem, index: number) => {
              this.HotFoodPill(item)
            }, (item: HotFoodItem, index: number) => `${index}`)
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
      Text('👋 第一次使用？')
        .fontSize(FONT_SIZE.TITLE)
        .fontWeight(FONT_WEIGHT.BOLD)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: SPACING.SM })

      Text('试试扫一包家里常吃的零食，看看对每位家人意味着什么。')
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
            router.pushUrl({ url: 'pages/ScanPage' })
          })

        Text('  或点击下方热门食品快速体验 →')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_HINT)
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
        .fontSize(FONT_SIZE.XLARGE)
        .margin({ right: SPACING.SM })
      Text(DAILY_TIPS[this.currentTipIndex].text)
        .fontSize(FONT_SIZE.BODY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_SECTION)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: SPACING.SM })
  }

  @Builder
  HotFoodPill(item: HotFoodItem) {
    Column() {
      Text(item.emoji)
        .fontSize(FONT_SIZE.XLARGE)
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
      router.pushUrl({
        url: 'pages/ReportPage',
        params: { hotFoodName: item.foodName }
      })
    })
  }
}
