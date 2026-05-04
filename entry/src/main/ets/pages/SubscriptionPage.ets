// SubscriptionPage.ets
// 会员订阅页面 - 展示四种会员方案卡片

import { router, promptAction, curves } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { SubscriptionTier, PRICING_PLANS } from '../model/PricingModel';
import { IapService, PurchaseRecord } from '../service/IapService';
import { PurchaseResult, MemberTier } from '../model/MemberStatus';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON } from '../constants/AppTheme';

// 本地方案数据（不含免费版，仅展示付费方案）
interface PlanDisplay {
  index: number;
  tier: SubscriptionTier;
  name: string;
  price: string;
  isYearly: boolean;
  features: string[];
  badge: string;        // 徽章文字：''表示无，'推荐'、'最惠'等
  borderColor: string;  // 边框颜色
  cardBg: string;       // 卡片背景
}

@Entry
@Component
struct SubscriptionPage {
  @State currentTier: SubscriptionTier = SubscriptionTier.FREE
  @State plans: PlanDisplay[] = []
  @State isPurchasing: boolean = false
  @State selectedPlanIndex: number = -1

  private appState: AppState = AppState.getInstance()
  private iapService: IapService = IapService.getInstance()

  async aboutToAppear() {
    this.currentTier = this.appState.getCurrentTier()
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
            .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })
          Text('选择会员方案')
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
        if (this.currentTier !== SubscriptionTier.FREE) {
          Row() {
            Text('🔄 恢复购买')
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
            Text('7天无理由退款').fontSize(FONT_SIZE.BODY).fontColor(COLORS.TEXT_PRIMARY)
              .fontWeight(FONT_WEIGHT.MEDIUM)
          }
          .margin({ bottom: 4 })
          Row() {
            Text('🔒 ').fontSize(FONT_SIZE.BODY)
            Text('支付信息加密传输').fontSize(FONT_SIZE.SMALL).fontColor(COLORS.TEXT_TERTIARY)
          }
          .margin({ bottom: 4 })
          Row() {
            Text('🔄 ').fontSize(FONT_SIZE.BODY)
            Text('随时取消 · 不会自动续费').fontSize(FONT_SIZE.SMALL).fontColor(COLORS.TEXT_TERTIARY)
          }
        }
        .width('90%')
        .padding({ top: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // ---- 独立性声明 ----
        Column() {
          Text('本评分与建议不接受品牌付费影响，仅供饮食选择参考')
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
      if (this.currentTier === SubscriptionTier.FREE) {
        Text('当前是免费版')
          .fontSize(FONT_SIZE.SUBTITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 8 })

        Text('每天3次扫码 · 1个成员 · 基础功能')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ bottom: 6 })

        Text('升级后，爸爸/妈妈/孩子/我，每个人都有专属建议')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY_DARK)
          .fontWeight(FONT_WEIGHT.MEDIUM)
      } else {
        Text('✨ ' + this.currentTier + ' 会员')
          .fontSize(FONT_SIZE.SUBTITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.SUCCESS)
          .margin({ bottom: 6 })

        Text('感谢你的支持，让关爱趁早 ❤️')
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

        // 徽章（带发光效果）
        if (this.currentTier === plan.tier) {
          Text('当前方案')
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

  /**
   * 构建展示方案数据（仅付费版，不含免费版）
   */
  private buildPlanDisplays(): PlanDisplay[] {
    const allPlans = PRICING_PLANS;
    const displays: PlanDisplay[] = [];

    // 方案1：7天体验（index 0）
    const trial = allPlans.find(p => p.tier === SubscriptionTier.TRIAL_7DAY);
    if (trial !== undefined) {
      displays.push({
        index: 0,
        tier: trial.tier,
        name: '7天免费体验',
        price: '限时' + trial.price,
        isYearly: trial.isYearly,
        features: trial.features,
        badge: '限时体验',
        borderColor: COLORS.ORANGE_ACCENT,
        cardBg: COLORS.BG_WARM_YELLOW
      });
    }

    // 方案2：个人年卡（index 1）— 推荐
    const personal = allPlans.find(p => p.tier === SubscriptionTier.PERSONAL_YEAR);
    if (personal !== undefined) {
      displays.push({
        index: 1,
        tier: personal.tier,
        name: '个人年卡',
        price: personal.price,
        isYearly: personal.isYearly,
        features: personal.features,
        badge: '推荐',
        borderColor: COLORS.ACCENT_ORANGE,
        cardBg: COLORS.BG_WARM_ORANGE
      });
    }

    // 方案3：家庭正式版（index 2）
    const family = allPlans.find(p => p.tier === SubscriptionTier.FAMILY_STANDARD);
    if (family !== undefined) {
      displays.push({
        index: 2,
        tier: family.tier,
        name: '家庭正式版',
        price: family.price,
        isYearly: family.isYearly,
        features: family.features,
        badge: '最多选择',
        borderColor: COLORS.PRIMARY,
        cardBg: COLORS.BG_CARD
      });
    }

    // 方案4：高级家庭版（index 3）
    const premium = allPlans.find(p => p.tier === SubscriptionTier.FAMILY_PREMIUM);
    if (premium !== undefined) {
      displays.push({
        index: 3,
        tier: premium.tier,
        name: '高级家庭版',
        price: premium.price,
        isYearly: premium.isYearly,
        features: premium.features,
        badge: '全部功能',
        borderColor: '#9C27B0',
        cardBg: '#F3E5F5'
      });
    }

    return displays;
  }

  private getProductId(tier: SubscriptionTier): string {
    const map: Map<string, string> = new Map([
      [SubscriptionTier.TRIAL_7DAY, 'family_food_personal_monthly'],
      [SubscriptionTier.PERSONAL_YEAR, 'family_food_personal_yearly'],
      [SubscriptionTier.FAMILY_STANDARD, 'family_food_family_yearly'],
      [SubscriptionTier.FAMILY_PREMIUM, 'family_food_premium_yearly']
    ]);
    return map.get(tier) || '';
  }

  private async handlePurchase(plan: PlanDisplay) {
    const productId = this.getProductId(plan.tier);
    if (productId.length === 0) return;

    this.isPurchasing = true;
    this.selectedPlanIndex = plan.index;

    const result: PurchaseResult = await this.iapService.purchase(productId);

    if (result.success) {
      // 使用新版 AppState 的 upgradeTier 方法
      const tier = this.getMemberTierForProductId(productId);
      if (tier !== MemberTier.FREE) {
        const days = productId === 'family_food_personal_monthly' ? 30 : 365;
        this.appState.upgradeTier(tier, days);
      }
      this.currentTier = plan.tier;
      promptAction.showToast({ message: '订阅成功！感谢支持 🎉' });
      setTimeout(() => {
        try {
          router.back();
        } catch (_e) {
          // ignore router.back() error
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
      if (tierStr === 'personal') {
        tier = MemberTier.PERSONAL;
      } else if (tierStr === 'family') {
        tier = MemberTier.FAMILY;
      } else if (tierStr === 'premium') {
        tier = MemberTier.PREMIUM;
      }
      if (tier !== MemberTier.FREE) {
        this.appState.upgradeTier(tier, 365);
        this.currentTier = this.getSubscriptionTierForMemberTier(tier);
        this.plans = this.buildPlanDisplays();
        promptAction.showToast({ message: '已恢复订阅' });
      } else {
        promptAction.showToast({ message: '未找到有效订阅记录' });
      }
    } else {
      promptAction.showToast({ message: '未找到有效订阅记录' });
    }
  }

  private getMemberTierForProductId(productId: string): MemberTier {
    if (productId.startsWith('family_food_personal')) return MemberTier.PERSONAL;
    if (productId.startsWith('family_food_family')) return MemberTier.FAMILY;
    if (productId.startsWith('family_food_premium')) return MemberTier.PREMIUM;
    return MemberTier.FREE;
  }

  private getSubscriptionTierForMemberTier(tier: MemberTier): SubscriptionTier {
    switch (tier) {
      case MemberTier.PERSONAL: return SubscriptionTier.PERSONAL_YEAR;
      case MemberTier.FAMILY: return SubscriptionTier.FAMILY_STANDARD;
      case MemberTier.PREMIUM: return SubscriptionTier.FAMILY_PREMIUM;
      default: return SubscriptionTier.FREE;
    }
  }
}
