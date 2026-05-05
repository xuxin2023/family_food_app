// SubscriptionPage.ets
// 会员订阅页面 - 展示四种会员方案卡片
// 基于 MemberTier + ProductPlan 体系

import { router, promptAction, curves } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { MemberTier, PurchaseResult } from '../model/MemberStatus';
import { ProductPlan, PRODUCT_PLANS, getProductPlanForTier } from '../model/PricingModel';
import { IapService } from '../service/IapService';
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
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.WHITE)
            .backgroundColor(COLORS.SUCCESS)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      // ---- 功能列表 ----
      ForEach(plan.features, (feature: string) => {
        Row() {
          Text('✓')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.SUCCESS)
            .margin({ right: 8 })
          Text(feature)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_SECONDARY)
        }
        .margin({ bottom: 4 })
      })

      // ---- 购买按钮 ----
      Button() {
        Text(plan.price === '免费' ? '当前方案' : '立即订阅')
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.WHITE)
          .fontWeight(FONT_WEIGHT.MEDIUM)
      }
      .width('100%')
      .height(44)
      .backgroundColor(plan.borderColor)
      .borderRadius(22)
      .margin({ top: 12 })
      .onClick(() => { this.handlePurchase(plan.index) })
      .enabled(!this.isPurchasing)
    }
    .width('90%')
    .padding(SPACING.MD)
    .backgroundColor(plan.cardBg)
    .borderRadius(RADIUS.MD)
    .border({ width: 1, color: plan.borderColor })
    .margin({ bottom: 12 })
  }

  // ==================== 构建方案列表 ====================

  private buildPlanDisplays(): PlanDisplay[] {
    const tiers: MemberTier[] = [
      MemberTier.FREE,
      MemberTier.PERSONAL,
      MemberTier.FAMILY,
      MemberTier.PREMIUM
    ]
    const result: PlanDisplay[] = []
    for (let i = 0; i < tiers.length; i++) {
      const tier = tiers[i]
      const plan = getProductPlanForTier(tier)
      if (!plan) continue
      result.push({
        index: i,
        tier: tier,
        name: this.getTierDisplayName(tier),
        price: plan.price,
        isYearly: plan.isYearly,
        features: plan.features,
        badge: plan.badge,
        borderColor: plan.tier === MemberTier.PREMIUM ? '#FFD700' : (plan.tier === MemberTier.FAMILY ? '#4CAF50' : (plan.tier === MemberTier.PERSONAL ? '#2196F3' : '#E0E0E0')),
        cardBg: plan.tier === MemberTier.PREMIUM ? '#FFFDE7' : (plan.tier === MemberTier.FAMILY ? '#F1F8E9' : (plan.tier === MemberTier.PERSONAL ? '#E3F2FD' : '#FFFFFF'))
      })
    }
    return result
  }

  // ==================== 购买/升级逻辑 ====================

  private async handlePurchase(index: number) {
    if (index < 0 || index >= this.plans.length) return
    const plan = this.plans[index]
    if (plan.tier === this.currentTier) {
      promptAction.showToast({ message: '已是当前方案' })
      return
    }
    if (this.isPurchasing) return
    this.isPurchasing = true
    this.selectedPlanIndex = index

    try {
      promptAction.showToast({ message: '正在处理...' })
      const productPlan = getProductPlanForTier(plan.tier)
      if (!productPlan) {
        promptAction.showToast({ message: '方案信息加载失败' })
        return
      }
      if (productPlan.price === '免费') {
        this.appState.upgradeTier(plan.tier, 365)
        this.currentTier = plan.tier
        this.plans = this.buildPlanDisplays()
        promptAction.showToast({ message: '已切换到 ' + plan.name })
        return
      }
      const result: PurchaseResult = await this.iapService.purchase(productPlan.productId)
      if (result.success) {
        const days = 365; // 默认 365 天
        this.appState.upgradeTier(plan.tier, days)
        this.currentTier = plan.tier
        this.plans = this.buildPlanDisplays()
        promptAction.showToast({ message: '升级成功！' })
      } else {
        promptAction.showToast({ message: result.errorMessage || '购买失败' })
      }
    } catch (_e) {
      promptAction.showToast({ message: '购买过程异常' })
    } finally {
      this.isPurchasing = false
      this.selectedPlanIndex = -1
    }
  }

  // ==================== 恢复购买 ====================

  private async handleRestore() {
    promptAction.showToast({ message: '正在恢复购买记录...' })
    await this.iapService.restorePurchases()
    const tierStr = await this.iapService.getSavedPurchaseTier()

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

  // ==================== 会员等级显示名称 ====================

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