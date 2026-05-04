// SubscriptionPage.ets
// 会员订阅页面 - 展示四种会员方案卡片
// 基于 MemberTier + ProductPlan 体系

import { router, promptAction, curves } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { MemberTier, PurchaseResult } from '../model/MemberStatus';
import { ProductPlan, PRODUCT_PLANS, getProductPlanForTier } from '../model/PricingModel';
import { IapService, PurchaseRecord } from '../service/IapService';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON } from '../constants/AppTheme';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SubscriptionPage';
const DOMAIN_ZERO = 0;

// 展示方案数据
interface PlanDisplay {
  index: number;
  tier: MemberTier;
  name: string;
  price: string;
  isYearly: boolean;
  features: string[];
  badge: string;
  borderColor: string;
  cardBg: string;
}

@Entry
@Component
struct SubscriptionPage {
  @State currentTier: MemberTier = MemberTier.FREE
  @State plans: PlanDisplay[] = []
  @State isPurchasing: boolean = false
  @State selectedPlanIndex: number = -1

  private appState: AppState = AppState.getInstance()
  private iapService: IapService = IapService.getInstance()

  async aboutToAppear() {
    this.currentTier = this.appState.memberStatus.tier
    this.plans = this.buildPlanDisplays()
  }

  build() {
    Scroll() {
      Column() {
        // ---- 顶部导航 ----
        Row() {
          Text('←')
            .fontSize(FONT_SIZE.LARGE)
            .fontColor(COLORS.PRIMARY)
            .onClick(() => {
              try { router.back() } catch (_e) { hilog.warn(DOMAIN_ZERO, TAG, 'router.back failed') }
            })
          Text($r('app.string.subscription'))
            .fontSize(FONT_SIZE.TITLE_LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ left: 12 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        // ---- 当前状态卡片 ----
        this.CurrentStatusCard()

        // ---- 方案卡片列表 ----
        ForEach(this.plans, (plan: PlanDisplay) => {
          this.PlanCard(plan)
        }, (plan: PlanDisplay) => plan.tier)

        // ---- 恢复购买 ----
        if (this.currentTier !== MemberTier.FREE) {
          Row() {
            Text($r('app.string.restore_purchase'))
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.ACCENT_BLUE)
              .onClick(() => { this.handleRestore() })
          }
          .margin({ top: 12, bottom: 8 })
        }

        // ---- 承诺文案 ----
        Column() {
          Row() {
            Text('🛡️ ').fontSize(FONT_SIZE.BODY)
            Text($r('app.string.refund_policy')).fontSize(FONT_SIZE.BODY).fontColor(COLORS.TEXT_PRIMARY)
              .fontWeight(FONT_WEIGHT.MEDIUM)
          }
          .margin({ bottom: 4 })
          Row() {
            Text('🔒 ').fontSize(FONT_SIZE.BODY)
            Text($r('app.string.secure_payment')).fontSize(FONT_SIZE.SMALL).fontColor(COLORS.TEXT_TERTIARY)
          }
          .margin({ bottom: 4 })
          Row() {
            Text('🔄 ').fontSize(FONT_SIZE.BODY)
            Text($r('app.string.cancel_anytime')).fontSize(FONT_SIZE.SMALL).fontColor(COLORS.TEXT_TERTIARY)
          }
        }
        .width('90%')
        .padding({ top: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // ---- 独立性声明 ----
        Column() {
          Text($r('app.string.unbiased_disclaimer'))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .textAlign(TextAlign.Center)
            .lineHeight(18)
        }
        .width('85%')
        .padding({ top: 16, bottom: 24 })
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

  // ==================== 当前状态卡片 ====================

  @Builder
  CurrentStatusCard() {
    Column() {
      if (this.currentTier === MemberTier.FREE) {
        Text($r('app.string.sub_free'))
          .fontSize(FONT_SIZE.SUBTITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 8 })

        Text($r('app.string.free_tier_desc'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ bottom: 6 })

        Text($r('app.string.upgrade_personal_desc'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY_DARK)
          .fontWeight(FONT_WEIGHT.MEDIUM)
      } else {
        Text('✨ ' + this.getTierDisplayName(this.currentTier) + ' 会员')
          .fontSize(FONT_SIZE.SUBTITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.SUCCESS)
          .margin({ bottom: 6 })

        Text($r('app.string.thanks_support'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_SECONDARY)
      }
    }
    .width('90%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 16 })
    .shadow({ radius: 8, color: COLORS.SHADOW_LIGHT, offsetX: 0, offsetY: 2 })
  }

  // ==================== 方案卡片 ====================

  @Builder
  PlanCard(plan: PlanDisplay) {
    Column() {
      // ---- 顶部：名称 + 价格 + 徽章 ----
      Row() {
        Column() {
          Text(plan.name)
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

        // 徽章
        if (this.currentTier === plan.tier) {
          Text($r('app.string.current_plan'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_WHITE)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(COLORS.SUCCESS)
            .borderRadius(RADIUS.SM)
            .shadow({ radius: 6, color: '#3300C853' })
        } else if (plan.badge.length > 0) {
          Text(plan.badge)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_WHITE)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(COLORS.ACCENT_ORANGE)
            .borderRadius(RADIUS.SM)
            .shadow({ radius: 8, color: '#44FF5722' })
        }
      }
      .width('100%')

      // ---- 权益列表 ----
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

      // ---- 订阅按钮 ----
      if (this.currentTier !== plan.tier) {
        Button((this.isPurchasing && this.selectedPlanIndex === plan.index) ? '处理中...' : '立即订阅')
          .width('100%')
          .height(BUTTON.HEIGHT_SECONDARY)
          .backgroundColor(plan.index === 1 ? COLORS.ACCENT_ORANGE : COLORS.PRIMARY)
          .fontColor(COLORS.TEXT_WHITE)
          .borderRadius(RADIUS.XXL)
          .fontSize(FONT_SIZE.BODY)
          .margin({ top: 12 })
          .enabled(!this.isPurchasing)
          .onClick(() => { this.handlePurchase(plan) })
      }
    }
    .width('90%')
    .padding(SPACING.LG)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[plan.cardBg, 0], [COLORS.WHITE, 1]]
    })
    .border({ width: plan.index === 1 ? 2 : 0, color: plan.borderColor })
    .shadow({ radius: plan.index === 1 ? 12 : 6, color: plan.index === 1 ? '#22FF5722' : COLORS.SHADOW_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 逻辑方法 ====================

  /** 构建展示方案数据 */
  private buildPlanDisplays(): PlanDisplay[] {
    return [
      {
        index: 0,
        tier: MemberTier.PERSONAL,
        name: '个人版',
        price: '29-49元/年',
        isYearly: true,
        features: ['无限扫码', '个人历史记录', '今日预算', '饮食平衡建议', '购物清单'],
        badge: '推荐',
        borderColor: COLORS.ACCENT_ORANGE,
        cardBg: COLORS.BG_WARM_ORANGE
      },
      {
        index: 1,
        tier: MemberTier.FAMILY,
        name: '家庭版',
        price: '89-129元/年',
        isYearly: true,
        features: ['最多4位家庭成员', '家庭购物清单', '家庭饮食周报', '儿童正餐保护', '美食平衡建议'],
        badge: '最惠',
        borderColor: COLORS.PRIMARY,
        cardBg: COLORS.BG_CARD
      },
      {
        index: 2,
        tier: MemberTier.PREMIUM,
        name: '高级版',
        price: '129-199元/年',
        isYearly: true,
        features: ['无限家庭成员', '动态健康数据联动', '深度可信度报告', '个性化周报', '外卖透明度'],
        badge: '全部功能',
        borderColor: '#9C27B0',
        cardBg: '#F3E5F5'
      }
    ];
  }

  private async handlePurchase(plan: PlanDisplay) {
    const productPlan = getProductPlanForTier(plan.tier);
    if (productPlan === null || productPlan.productId.length === 0) return;

    this.isPurchasing = true;
    this.selectedPlanIndex = plan.index;

    const result: PurchaseResult = await this.iapService.purchase(productPlan.productId);

    if (result.success) {
      this.appState.upgradeTier(plan.tier, 365);
      this.currentTier = plan.tier;
      promptAction.showToast({ message: '订阅成功！感谢支持 🎉' });
      setTimeout(() => {
        try {
          router.back();
        } catch (_e) {
          hilog.warn(DOMAIN_ZERO, TAG, 'router.back failed after purchase');
        }
      }, 1500);
    } else {
      promptAction.showToast({ message: result.errorMessage });
    }

    this.isPurchasing = false;
    this.selectedPlanIndex = -1;
  }

  private async handleRestore() {
    promptAction.showToast({ message: '正在恢复购买记录...' });
    await this.iapService.restorePurchases();
    const tierStr = await this.iapService.getSavedPurchaseTier();

    if (tierStr.length > 0 && tierStr !== 'free') {
      let tier: MemberTier = MemberTier.FREE;
      if (tierStr === 'personal') tier = MemberTier.PERSONAL;
      else if (tierStr === 'family') tier = MemberTier.FAMILY;
      else if (tierStr === 'premium') tier = MemberTier.PREMIUM;

      if (tier !== MemberTier.FREE) {
        this.appState.upgradeTier(tier, 365);
        this.currentTier = tier;
        this.plans = this.buildPlanDisplays();
        promptAction.showToast({ message: '已恢复订阅' });
      } else {
        promptAction.showToast({ message: '未找到有效订阅记录' });
      }
    } else {
      promptAction.showToast({ message: '未找到有效订阅记录' });
    }
  }

  private getTierDisplayName(tier: MemberTier): string {
    switch (tier) {
      case MemberTier.FREE: return '免费版';
      case MemberTier.PERSONAL: return '个人版';
      case MemberTier.FAMILY: return '家庭版';
      case MemberTier.PREMIUM: return '高级版';
      default: return '未知';
    }
  }
}
