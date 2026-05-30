// 购物篮检查页 - 连续扫描后检查一篮子食品

import { safeBack, safePushUrl, FoodLabel, PaywallTrigger, BUTTON, COLORS } from 'hsp_core';
import { BasketCheckResult, BasketCheckEngine } from 'hsp_service';
import { AppState } from '../AppState';
import { PaywallDialog } from 'feature_scan';

@Entry
@ComponentV2
struct BasketCheckPage {
  @Local basketItems: FoodLabel[] = []
  @Local checkResult: BasketCheckResult | null = null
  @Local showPaywallDialog: boolean = false
  @Local paywallTrigger: PaywallTrigger | null = null
  @Local isLoading: boolean = true

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.isLoading = true;
    try {
    const trigger = this.appState.member.getPaywallTrigger('basket_check')
    if (trigger !== null) {
      this.paywallTrigger = trigger
      this.showPaywallDialog = true
      return
    }

    this.basketItems = this.appState.basket.getBasketItems()
    if (this.basketItems.length > 0) {
      const checkEngine = new BasketCheckEngine();
      this.checkResult = checkEngine.check(this.basketItems, [])
    }
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Stack() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(48).height(48).color(COLORS.PRIMARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            Row() {
              Text($r('app.string.back_arrow')).fontSize(24).fontColor(COLORS.PRIMARY)
                .onClick(() => { safeBack() })
                .accessibilityText('返回')
                .accessibilityLevel('yes')
              Text($r('app.string.basket_button')).fontSize(20).fontWeight(FontWeight.Bold)
                .margin({ left: 16 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })

            if (this.basketItems.length === 0) {
              Column() {
                Text('🛒').fontSize(48).margin({ bottom: 16 })
                Text('购物篮为空').fontSize(16).fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 24 })
                Button('扫码添加')
                  .height(BUTTON.HEIGHT_MD)
                  .backgroundColor(COLORS.PRIMARY)
                  .borderRadius(BUTTON.RADIUS_MD)
                  .onClick(() => { safePushUrl('pages/ScanPage') })
                  .accessibilityText('扫描添加')
                  .accessibilityLevel('yes')
              }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            } else {
              Column() {
                Row() {
                  Text(`🛒 ${this.basketItems.length}款食品`).fontSize(16).fontWeight(FontWeight.Medium)
                  Blank()
                  if (this.checkResult && this.checkResult.hasRisk()) {
                    Text($r('app.string.basket_attention')).fontSize(14).fontColor(COLORS.ACCENT_ORANGE).fontWeight(FontWeight.Medium)
                  } else {
                    Text($r('app.string.basket_ok')).fontSize(14).fontColor(COLORS.ACCENT_GREEN_4CAF)
                  }
                }
                .width('100%')
                .padding({ left: 16, right: 16 })
                .margin({ bottom: 12 })

                if (this.checkResult && this.checkResult.warnings.length > 0) {
                  Column() {
                    Text($r('app.string.basket_warning')).fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
                    ForEach(this.checkResult.warnings, (warning: string) => {
                      Row() {
                        Text('•').fontSize(14).fontColor(COLORS.ACCENT_ORANGE).margin({ right: 6 })
                        Text(warning).fontSize(14).fontColor(COLORS.TEXT_GRAY_2121)
                      }
                      .margin({ bottom: 6 })
                      .width('100%')
                    }, (warning: string, index: number) => `${index}`)
                  }
                  .width('100%')
                  .padding(16)
                  .backgroundColor(COLORS.BG_WARM_ORANGE)
                  .borderRadius(12)
                  .margin({ left: 16, right: 16, bottom: 12 })
                  .alignItems(HorizontalAlign.Start)
                }

                if (this.checkResult && this.checkResult.suggestions.length > 0) {
                  Column() {
                    Text($r('app.string.basket_suggestion')).fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
                    ForEach(this.checkResult.suggestions, (suggestion: string) => {
                      Row() {
                        Text('•').fontSize(14).fontColor(COLORS.ACCENT_GREEN_4CAF).margin({ right: 6 })
                        Text(suggestion).fontSize(14).fontColor(COLORS.TEXT_GRAY_2121)
                      }
                      .margin({ bottom: 6 })
                      .width('100%')
                    }, (suggestion: string, index: number) => `${index}`)
                  }
                  .width('100%')
                  .padding(16)
                  .backgroundColor(COLORS.BG_LIGHT_GREEN)
                  .borderRadius(12)
                  .margin({ left: 16, right: 16, bottom: 12 })
                  .alignItems(HorizontalAlign.Start)
                }

                Text($r('app.string.basket_items')).fontSize(14).fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ left: 16, top: 8, bottom: 8 })

                ForEach(this.basketItems, (item: FoodLabel) => {
                  Row() {
                    Column() {
                      Text(item.foodName).fontSize(14).fontWeight(FontWeight.Medium)
                      Row() {
                        if (item.isHighSodium()) { Text($r('app.string.risk_high_salt')).fontSize(11).fontColor(COLORS.WHITE).backgroundColor(COLORS.ACCENT_ORANGE).padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(8).margin({ right: 4 }) }
                        if (item.isHighSugar()) { Text($r('app.string.risk_high_sugar')).fontSize(11).fontColor(COLORS.WHITE).backgroundColor('#FF9800').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(8).margin({ right: 4 }) }
                        if (item.isHighFat()) { Text($r('app.string.risk_high_fat')).fontSize(11).fontColor(COLORS.WHITE).backgroundColor('#F44336').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(8) }
                      }
                      .margin({ top: 4 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(COLORS.WHITE)
                  .borderRadius(8)
                  .margin({ left: 16, right: 16, bottom: 4 })
                }, (item: FoodLabel) => item.foodId)

                Button('继续扫描添加')
                  .width('90%')
                  .height(BUTTON.HEIGHT_MD)
                  .backgroundColor(COLORS.PRIMARY)
                  .borderRadius(BUTTON.RADIUS_MD)
                  .margin({ top: 16, bottom: 32 })
                  .onClick(() => { safePushUrl('pages/ScanPage') })
                  .accessibilityText('继续扫描添加')
                  .accessibilityLevel('yes')
              }
              .width('100%')
            }
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FAFAFA')
      }

      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: this.showPaywallDialog,
          onUpdateShowDialog: (val: boolean) => { this.showPaywallDialog = val }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

}
