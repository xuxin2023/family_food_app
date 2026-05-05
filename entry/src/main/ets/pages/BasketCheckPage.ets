// 购物篮检查页 - 连续扫描后检查一篮子食品

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FoodLabel, FoodSource, NutritionPer100g } from '../model/FoodLabel';
import { BasketCheckResult } from '../engine/BasketCheckEngine';
import { AppState } from '../AppState';
import { PaywallTrigger, MemberTier } from '../model/MemberStatus';
import { PaywallDialog } from '../components/PaywallDialog';
import { BUTTON, COLORS } from '../constants/AppTheme';

@Entry
@Component
struct BasketCheckPage {
  @State basketItems: FoodLabel[] = []
  @State checkResult: BasketCheckResult | null = null
  @State showPaywallDialog: boolean = false
  @State paywallTrigger: PaywallTrigger | null = null

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    // 检查付费墙 - 购物篮检查需要家庭版以上
    const trigger = this.appState.getPaywallTrigger('basket_check')
    if (trigger !== null && trigger.requiredTier !== MemberTier.FREE) {
      // 当前等级无权限，显示付费墙
      this.paywallTrigger = trigger
      this.showPaywallDialog = true
      return
    }

    // 从AppState获取购物篮数据
    this.basketItems = this.appState.getBasketItems()
    if (this.basketItems.length === 0) {
      // 无数据时使用示例
      this.basketItems = this.createFallbackBasket()
    }
    this.checkResult = this.appState.checkBasket()
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          // 顶部导航
          Row() {
            Text('←').fontSize(24).fontColor(COLORS.PRIMARY)
              .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })
            Text($r('app.string.basket_button')).fontSize(20).fontWeight(FontWeight.Bold)
              .margin({ left: 16 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })

          // 篮子概览
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

          // 警告列表
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

          // 采购建议
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

          // 食品列表
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

          // 继续扫描按钮
          Button('继续扫描添加')
            .width('90%')
            .height(BUTTON.HEIGHT_MD)
            .backgroundColor(COLORS.PRIMARY)
            .borderRadius(BUTTON.RADIUS_MD)
            .margin({ top: 16, bottom: 32 })
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/ScanPage' })
              } catch (_e) {
                hilog.warn(0x0000, 'BasketCheckPage', 'router.pushUrl failed: ' + JSON.stringify(_e))
              }
            })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')
      .scrollable(ScrollDirection.Vertical)

      // 付费墙弹窗（覆盖在内容之上）
      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: $showPaywallDialog
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private createFallbackBasket(): FoodLabel[] {
    const items: FoodLabel[] = []
    const now = Date.now()

    const item1 = new FoodLabel()
    item1.foodId = 'b1'; item1.foodName = '即食鸡爪（香辣味）'
    item1.nutrition = new NutritionPer100g();
    item1.nutrition.sodium = 1200;
    item1.nutrition.sugar = 3;
    item1.nutrition.calories = 230;
    item1.nutrition.fat = 12;
    item1.nutrition.saturatedFat = 3;
    item1.nutrition.carbohydrate = 8;
    item1.nutrition.protein = 15;
    item1.ingredients = ['鸡爪', '食用盐', '酱油']; item1.source = FoodSource.USER_UPLOAD; item1.identifiedAt = now
    items.push(item1)

    const item2 = new FoodLabel()
    item2.foodId = 'b2'; item2.foodName = '儿童酸奶'
    item2.nutrition = new NutritionPer100g();
    item2.nutrition.sodium = 80;
    item2.nutrition.sugar = 18;
    item2.nutrition.calories = 90;
    item2.nutrition.fat = 3;
    item2.nutrition.saturatedFat = 1.5;
    item2.nutrition.carbohydrate = 15;
    item2.nutrition.protein = 3;
    item2.ingredients = ['生牛乳', '白砂糖', '果胶']; item2.source = FoodSource.USER_UPLOAD; item2.identifiedAt = now
    items.push(item2)

    const item3 = new FoodLabel()
    item3.foodId = 'b3'; item3.foodName = '火锅底料（牛油麻辣）'
    item3.nutrition = new NutritionPer100g();
    item3.nutrition.sodium = 3500;
    item3.nutrition.sugar = 5;
    item3.nutrition.calories = 450;
    item3.nutrition.fat = 35;
    item3.nutrition.saturatedFat = 18;
    item3.nutrition.carbohydrate = 10;
    item3.nutrition.protein = 5;
    item3.ingredients = ['牛油', '辣椒', '食用盐', '花椒']; item3.source = FoodSource.USER_UPLOAD; item3.identifiedAt = now
    items.push(item3)

    return items
  }
}
