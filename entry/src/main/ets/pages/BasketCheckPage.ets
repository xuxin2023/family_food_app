// 购物篮检查页 V8 — 接入 SmartBasketService 三引擎融合分析
// 成分危害 + 营养阈值 + AI 整篮建议 + 替代品推荐

import {
  safeBack, safePushUrl, FoodLabel, FamilyProfile, PaywallTrigger, BUTTON, COLORS,
  FONT_SIZE, RADIUS, SPACING, PageResourceTracker, createPageTracker, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { BasketCheckResult } from 'hsp_service';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  SmartBasketService, SmartBasketResult, SmartBasketItem, SwapSuggestion
} from 'hsp_service';

const TAG = 'BasketCheckPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
import { AppState } from '../AppState';
import { PaywallDialog } from 'feature_scan';

@Entry
@ComponentV2
export struct BasketCheckPage {
  @Local basketItems: FoodLabel[] = []
  @Local checkResult: BasketCheckResult | null = null
  @Local smartResult: SmartBasketResult | null = null
  @Local showPaywallDialog: boolean = false
  @Local paywallTrigger: PaywallTrigger | null = null
  @Local isLoading: boolean = true
  @Local overallScore: number = 0
  @Local aiAdvice: string = ''
  @Local topSwaps: SwapSuggestion[] = []

  private appState: AppState = AppState.getInstance()
  private smartService: SmartBasketService = SmartBasketService.getInstance()
  private tracker: PageResourceTracker = createPageTracker('BasketCheckPage')

  async aboutToAppear() {
    this.tracker.onAppear()
    this.isLoading = true
    try {
      const trigger = this.appState.member.getPaywallTrigger('basket_check')
      if (trigger !== null) {
        this.paywallTrigger = trigger
        this.showPaywallDialog = true
        return
      }

      this.basketItems = this.appState.basket.getBasketItems()
      if (this.basketItems.length > 0) {
        const profiles: FamilyProfile[] = this.appState.getAllMembersSync()
        const result = await this.smartService.analyze(this.basketItems, profiles)
        this.smartResult = result
        this.checkResult = result.basketCheck
        this.overallScore = result.overallScore
        this.aiAdvice = result.aiAdvice
        this.topSwaps = result.topSwaps
      }
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_));
      this.checkResult = null
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Stack() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(48).height(48).color(COLORS.PRIMARY)
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            Row() {
              Text($r('app.string.back_arrow')).fontSize(24).fontColor(COLORS.PRIMARY)
                .onClick(() => { safeBack() })
                .accessibilityText('返回').accessibilityLevel('yes')
              Text($r('app.string.basket_button')).fontSize(20).fontWeight(FontWeight.Bold)
                .margin({ left: 16 })
            }
            .width('100%').padding({ left: 16, right: 16, top: 16, bottom: 16 })

            if (this.basketItems.length === 0) {
              Column() {
                Text('🛒').fontSize(48).margin({ bottom: 16 })
                Text('购物篮为空').fontSize(16).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 24 })
                Button('扫码添加')
                  .height(BUTTON.HEIGHT_MD).backgroundColor(COLORS.PRIMARY)
                  .borderRadius(BUTTON.RADIUS_MD)
                  .onClick(() => { safePushUrl('pages/ScanPage') })
                  .accessibilityText('扫描添加').accessibilityLevel('yes')
              }
              .width('100%').layoutWeight(1)
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
            } else {
              Column() {
                this.ScoreHeader()
                this.AiAdviceCard()
                this.RiskWarningsCard()
                this.SwapSuggestionsCard()
                this.SuggestionsCard()
                this.FoodItemList()

                Button('继续扫描添加')
                  .width('90%').height(BUTTON.HEIGHT_MD)
                  .backgroundColor(COLORS.PRIMARY).borderRadius(BUTTON.RADIUS_MD)
                  .margin({ top: 16, bottom: 32 })
                  .onClick(() => { safePushUrl('pages/ScanPage') })
                  .accessibilityText('继续扫描添加').accessibilityLevel('yes')
              }
              .width('100%')
            }
          }
          .width('100%')
        }
        .width('100%').height('100%').backgroundColor('#FAFAFA')
      }

      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger, showDialog: this.showPaywallDialog,
          onUpdateShowDialog: (val: boolean) => { this.showPaywallDialog = val }
        })
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  ScoreHeader() {
    Row() {
      Text(`🛒 ${this.basketItems.length}款食品`).fontSize(16).fontWeight(FontWeight.Medium)
      Blank()
      if (this.smartResult) {
        Column() {
          Text(`${this.overallScore}`).fontSize(28).fontWeight(FontWeight.Bold)
            .fontColor(this.overallScore >= 70 ? COLORS.ACCENT_GREEN_4CAF :
              this.overallScore >= 40 ? COLORS.ACCENT_ORANGE : COLORS.ACCENT_RED_EF53)
          Text('综合分').fontSize(10).fontColor(COLORS.TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%').padding({ left: 16, right: 16 }).margin({ bottom: 12 })
  }

  @Builder
  AiAdviceCard() {
    if (this.aiAdvice.length > 0) {
      Column() {
        Row() {
          Text('🤖 AI 分析').fontSize(13).fontWeight(FontWeight.Medium)
            .fontColor(COLORS.PRIMARY).margin({ bottom: 4 })
        }
        Text(this.aiAdvice).fontSize(13).fontColor(COLORS.TEXT_SECONDARY).lineHeight(18)
      }
      .width('100%').padding(14)
      .backgroundColor('#E3F2FD').borderRadius(12)
      .margin({ left: 16, right: 16, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  RiskWarningsCard() {
    if (this.checkResult && this.checkResult.warnings.length > 0) {
      Column() {
        Text('⚠️ 风险提示').fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(COLORS.ACCENT_ORANGE).margin({ bottom: 8 })
        ForEach(this.checkResult.warnings, (warning: string) => {
          Row() {
            Text('•').fontSize(14).fontColor(COLORS.ACCENT_ORANGE).margin({ right: 6 })
            Text(warning).fontSize(13).fontColor(COLORS.TEXT_GRAY_2121)
          }.margin({ bottom: 4 }).width('100%')
        }, (_w: string, i: number) => `warn_${i}`)
      }
      .width('100%').padding(14)
      .backgroundColor(COLORS.BG_WARM_ORANGE).borderRadius(12)
      .margin({ left: 16, right: 16, bottom: 12 }).alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  SwapSuggestionsCard() {
    if (this.topSwaps.length > 0) {
      Column() {
        Text('🔄 更健康的替代品').fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor('#2E7D32').margin({ bottom: 8 })
        ForEach(this.topSwaps, (swap: SwapSuggestion) => {
          Row() {
            Column() {
              Text(`${swap.avoidFoodName} → ${swap.betterAlternative}`)
                .fontSize(13).fontWeight(FontWeight.Medium).fontColor(COLORS.TEXT_PRIMARY)
              Text(swap.benefit).fontSize(11).fontColor(COLORS.TEXT_TERTIARY)
                .margin({ top: 2 })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          }
          .width('100%').padding({ top: 6, bottom: 6 })
          .border({ width: { bottom: 0.5 }, color: COLORS.BORDER_LIGHT_E8 })
        }, (s: SwapSuggestion) => s.avoidFoodName)
      }
      .width('100%').padding(14)
      .backgroundColor('#E8F5E9').borderRadius(12)
      .margin({ left: 16, right: 16, bottom: 12 }).alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  SuggestionsCard() {
    if (this.checkResult && this.checkResult.suggestions.length > 0) {
      Column() {
        Text('💡 采购建议').fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(COLORS.ACCENT_GREEN_4CAF).margin({ bottom: 8 })
        ForEach(this.checkResult.suggestions, (suggestion: string) => {
          Row() {
            Text('•').fontSize(14).fontColor(COLORS.ACCENT_GREEN_4CAF).margin({ right: 6 })
            Text(suggestion).fontSize(13).fontColor(COLORS.TEXT_GRAY_2121)
          }.margin({ bottom: 4 }).width('100%')
        }, (_s: string, i: number) => `sug_${i}`)
      }
      .width('100%').padding(14)
      .backgroundColor(COLORS.BG_LIGHT_GREEN).borderRadius(12)
      .margin({ left: 16, right: 16, bottom: 12 }).alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  FoodItemList() {
    Column() {
      Text(`${this.basketItems.length}款食品`).fontSize(14).fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ left: 16, top: 8, bottom: 8 })

      ForEach(this.basketItems, (item: FoodLabel) => {
        Row() {
          Column() {
            Row() {
              Text(item.foodName).fontSize(14).fontWeight(FontWeight.Medium)
              if (this.smartResult) {
                const match = this.smartResult.items.find((si: SmartBasketItem) =>
                  si.food.barcode === item.barcode)
                if (match) {
                  Text(match.level === 'avoid' ? ' 🚫' : match.level === 'caution' ? ' ⚠️' : ' ✅')
                    .fontSize(13)
                }
              }
            }
            Row() {
              if (item.isHighSodium()) {
                Text($r('app.string.risk_high_salt')).fontSize(10).fontColor(COLORS.WHITE)
                  .backgroundColor(COLORS.ACCENT_ORANGE).padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .borderRadius(8).margin({ right: 4 })
              }
              if (item.isHighSugar()) {
                Text($r('app.string.risk_high_sugar')).fontSize(10).fontColor(COLORS.WHITE)
                  .backgroundColor('#FF9800').padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .borderRadius(8).margin({ right: 4 })
              }
              if (item.isHighFat()) {
                Text($r('app.string.risk_high_fat')).fontSize(10).fontColor(COLORS.WHITE)
                  .backgroundColor('#F44336').padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .borderRadius(8)
              }
            }.margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)

          if (item.nutriScore > 0) {
            Text(`${item.nutriScore}分`).fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(item.nutriScore >= 70 ? COLORS.ACCENT_GREEN_4CAF :
                item.nutriScore >= 40 ? COLORS.ACCENT_ORANGE : COLORS.ACCENT_RED_EF53)
          }
        }
        .width('100%').padding(10)
        .backgroundColor(COLORS.WHITE).borderRadius(8)
        .margin({ left: 16, right: 16, bottom: 4 })
      }, (item: FoodLabel) => item.foodId)
    }.width('100%')
  }

  aboutToDisappear(): void { this.tracker.onDisappear() }
}
