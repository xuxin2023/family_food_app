import { router, promptAction } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { SubscriptionTier, PRICING_PLANS } from '../model/PricingModel';
import { IapService, IapProduct, PurchaseResult } from '../service/IapService';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

@Entry
@Component
struct SubscriptionPage {
  @State currentTier: SubscriptionTier = SubscriptionTier.FREE
  @State products: IapProduct[] = []
  @State isPurchasing: boolean = false
  @State selectedProductId: string = ''

  private appState: AppState = AppState.getInstance()
  private iapService: IapService = new IapService()

  async aboutToAppear() {
    this.currentTier = this.appState.getCurrentTier()
    this.products = await this.iapService.getAvailableProducts()
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('←')
            .fontSize(FONT_SIZE.LARGE)
            .fontColor(COLORS.PRIMARY)
            .onClick(() => { router.back() })
          Text('升级家庭版')
            .fontSize(FONT_SIZE.TITLE_LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ left: 12 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        Column() {
          Text('为什么升级？')
            .fontSize(FONT_SIZE.SUBTITLE)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 12 })

          Text('免费版每天只能扫3次，只有1个家庭成员。')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ bottom: 6 })
          Text('升级后，爸爸/妈妈/孩子/我，每个人都有专属建议。')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ bottom: 6 })
          Text('卖的不是"无限扫码"，而是"更懂你家每个人"。')
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.PRIMARY_DARK)
        }
        .width('90%')
        .padding(SPACING.LG)
        .backgroundColor(COLORS.BG_CARD)
        .borderRadius(RADIUS.LG)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 16 })
        .shadow({ radius: 8, color: COLORS.SHADOW_LIGHT, offsetX: 0, offsetY: 2 })

        ForEach(PRICING_PLANS, (plan: SubscriptionPlan, index: number) => {
          this.PlanCard(plan, index)
        }, (plan: SubscriptionPlan, index: number) => `${index}`)

        if (this.currentTier !== SubscriptionTier.FREE) {
          Row() {
            Text('🔄 恢复购买')
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.ACCENT_BLUE)
              .onClick(() => { this.handleRestore() })
          }
          .margin({ top: 12, bottom: 24 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[COLORS.BG_GRADIENT_START, 0], [COLORS.BG_GRADIENT_END, 1]]
    })
  }

  @Builder
  PlanCard(plan: SubscriptionPlan, index: number) {
    Column() {
      Row() {
        Column() {
          Text(plan.tier)
            .fontSize(FONT_SIZE.TITLE)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(plan.price + (plan.isYearly ? '/年' : ''))
            .fontSize(FONT_SIZE.SUBTITLE)
            .fontColor(COLORS.PRIMARY_DARK)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.currentTier === plan.tier) {
          Text('当前')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_WHITE)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(COLORS.SUCCESS)
            .borderRadius(RADIUS.SM)
        } else if (index === 1) {
          Text('推荐')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_WHITE)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(COLORS.PRIMARY)
            .borderRadius(RADIUS.SM)
        }
      }
      .width('100%')

      Column() {
        ForEach(plan.features, (feature: string) => {
          Row() {
            Text('✓')
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.SUCCESS)
              .margin({ right: 8 })
            Text(feature)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_SECONDARY)
          }
          .margin({ bottom: 4 })
        }, (feature: string) => feature)
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(HorizontalAlign.Start)

      if (this.currentTier !== plan.tier && index > 0) {
        Button(this.isPurchasing && this.selectedProductId === this.getProductId(plan.tier)
          ? '处理中...' : '立即订阅')
          .width('100%')
          .height(44)
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(COLORS.TEXT_WHITE)
          .borderRadius(RADIUS.XXL)
          .fontSize(FONT_SIZE.BODY)
          .margin({ top: 12 })
          .enabled(!this.isPurchasing)
          .onClick(() => { this.handlePurchase(plan.tier) })
      }
    }
    .width('90%')
    .padding(SPACING.LG)
    .backgroundColor(index === 1 ? COLORS.BG_CARD_HIGHLIGHT : COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .border(index === 1 ? { width: 2, color: COLORS.PRIMARY } : undefined)
    .shadow({ radius: 6, color: COLORS.SHADOW_LIGHT, offsetX: 0, offsetY: 2 })
  }

  private getProductId(tier: SubscriptionTier): string {
    const map: Map<string, string> = new Map([
      [SubscriptionTier.TRIAL_7DAY, 'com.familyfood.trial_7day'],
      [SubscriptionTier.PERSONAL_YEAR, 'com.familyfood.personal_year'],
      [SubscriptionTier.FAMILY_EARLY, 'com.familyfood.family_early'],
      [SubscriptionTier.FAMILY_STANDARD, 'com.familyfood.family_standard'],
      [SubscriptionTier.FAMILY_PREMIUM, 'com.familyfood.family_premium']
    ]);
    return map.get(tier) || '';
  }

  private async handlePurchase(tier: SubscriptionTier) {
    const productId = this.getProductId(tier);
    if (productId.length === 0) return;

    this.isPurchasing = true;
    this.selectedProductId = productId;

    const result: PurchaseResult = await this.iapService.purchase(productId);

    if (result.success) {
      this.appState.setTier(result.tier);
      this.currentTier = result.tier;
      promptAction.showToast({ message: '订阅成功！感谢支持 🎉' });
      setTimeout(() => { router.back(); }, 1500);
    } else {
      promptAction.showToast({ message: result.message });
    }

    this.isPurchasing = false;
    this.selectedProductId = '';
  }

  private async handleRestore() {
    promptAction.showToast({ message: '正在恢复购买记录...' });
    const tier = await this.iapService.verifyAndRestorePurchases();
    if (tier !== SubscriptionTier.FREE) {
      this.appState.setTier(tier);
      this.currentTier = tier;
      promptAction.showToast({ message: '已恢复订阅：' + tier });
    } else {
      promptAction.showToast({ message: '未找到有效订阅记录' });
    }
  }
}

class SubscriptionPlan {
  tier: SubscriptionTier = SubscriptionTier.FREE;
  price: string = '';
  priceValue: number = 0;
  isYearly: boolean = false;
  features: string[] = [];
  limitations: string[] = [];
}
