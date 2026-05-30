// ReportPage.ets
// 家庭适配报告页 - V6 体验重构
// 三段式布局：顶部评测区 | 家庭矩阵区 | 辅助信息区

import {
  safeBack, safePushUrl, FamilyProfile, FoodLabel, Recommendation, RecommendLevel, LevelColor, getLevelColorValue, AlternativeFood, ChildProtection, CredibilityResult, PaywallTrigger, MemberTier, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON, AccessibilityUtil, NavigationManager
} from 'hsp_core';
import { promptAction, curves } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { ErrorBoundary } from '../components/ErrorBoundary';
import { common } from '@kit.AbilityKit';
import { AppState } from '../AppState';
import { NutriScoreBadge, AllergenHighlightList, PaywallDialog, AdditiveTrafficLightList, AdditiveClassifier } from 'feature_scan';
import { NovaGroupBadge, EcoScoreBadge, EcoScore, RiskAssessmentPanel, ShareCardGenerator, MemberShareInfo, ShareImageParams, ComprehensiveRatingPanel } from 'feature_report';
import { NutriScore } from 'hsp_core';
import { AdditiveInteractionEngine, InteractionAssessmentResult, NovaGroup } from 'feature_scan';
import { AdditiveInteractionCard } from '../components/AdditiveInteractionCard';

// ===== 页面级别类型 =====

/** ReportPage 路由参数接口（通过 AppState.setReportParams 传入） */
export class ReportPageParams {
  foodLabel: FoodLabel = new FoodLabel();
  recommendations: Recommendation[] = [];
  members: FamilyProfile[] = [];
  alternatives: AlternativeFood[] = [];
  nutriScore: number = 50;
  credibilityResult: CredibilityResult = new CredibilityResult();
  childProtection: ChildProtection[] = [];
}

@Entry
@ComponentV2
struct ReportPage {
  @Local foodLabel: FoodLabel = new FoodLabel()
  @Local recommendations: Recommendation[] = []
  @Local familyMembers: FamilyProfile[] = []
  @Local alternatives: AlternativeFood[] = []
  @Local nutriScore: number = 50
  @Local selectedMemberIndex: number = 0
  @Local showSkeleton: boolean = true
  @Local showNutriAnim: boolean = false
  @Local isImageSaving: boolean = false
  @Local showPaywallDialog: boolean = false
  @Local paywallTrigger: PaywallTrigger | null = null
  @Local showAlternativesLocked: boolean = false
  @Local currentBreakpoint: string = 'md'
  @Local interactionResult: InteractionAssessmentResult | null = null
  @Local hasPageError: boolean = false

  private appState: AppState = AppState.getInstance()
  private credibilityResult: CredibilityResult = new CredibilityResult()
  private childProtections: ChildProtection[] = []
  private swiperController: SwiperController = new SwiperController()
  private componentActive: boolean = true

  // ==================== 生命周期 ====================

  async aboutToAppear() {
    // 优先从路由缓存读取（避免 router params 序列化大对象的限制）
    const cachedFoodLabel = this.appState.reportCache.consumeFoodLabel()
    const cachedRecs = this.appState.reportCache.consumeRecommendations()
    const cachedAlts = this.appState.reportCache.consumeAlternatives()
    
    if (cachedFoodLabel !== null) {
      this.foodLabel = cachedFoodLabel
      this.recommendations = cachedRecs ?? []
      this.alternatives = cachedAlts ?? []
    } else {
      // 降级：从 router params 读取（兼容旧跳转）
      const params = this.getPageParams()
      if (params !== null) {
        this.foodLabel = params.foodLabel
        this.recommendations = params.recommendations
        this.familyMembers = params.members
        this.alternatives = params.alternatives
        this.nutriScore = params.nutriScore
        this.credibilityResult = params.credibilityResult
        this.childProtections = params.childProtection
      }
    }

    // 检查付费墙 — 替代品推荐需要家庭版
    const altTrigger = this.appState.member.getPaywallTrigger('upgrade_member')
    if (altTrigger !== null && altTrigger.requiredTier !== MemberTier.FREE &&
        this.alternatives.length > 0) {
      this.showAlternativesLocked = true
    }

    // 数据就绪后关闭骨架屏、展示内容
    this.showSkeleton = false
    this.showNutriAnim = true
  }

  aboutToDisappear(): void {
    this.componentActive = false
  }

  // ==================== 计算属性 ====================

  private get selectedRec(): Recommendation {
    if (this.recommendations.length === 0) {
      const fallback = new Recommendation()
      fallback.memberId = 'none'
      fallback.level = RecommendLevel.SUITABLE
      fallback.levelColor = LevelColor.GREEN
      fallback.reasons = ['暂无适配数据']
      return fallback
    }
    const idx = Math.min(this.selectedMemberIndex, this.recommendations.length - 1)
    return this.recommendations[idx]
  }

  private get levelColorHex(): string {
    return getLevelColorValue(this.selectedRec.levelColor)
  }

  // ==================== 构建 UI ====================

  build() {
    ErrorBoundary({
      fallbackMessage: $r('app.string.report_page_load_failed'),
      onRetry: () => { this.aboutToAppear() },
      hasError: this.hasPageError,
      boundaryName: 'ReportPage'
    }) {
      Stack() {
      // 骨架屏 - 使用条件渲染容器
      if (this.showSkeleton) {
        Stack() {
          this.SkeletonScreen()
        }
      }

      Scroll() {
        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] } as BreakPoints
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- 顶部导航 ----
            Row() {
              this.TopNavBar()
            }
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- ① 顶部评测区（Hero） ----
            Column() {
              this.HeroSection()
            }
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- ② 家庭矩阵区 ----
            Column() {
              this.FamilyMatrixSection()
            }
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- ③ 辅助信息区 ----
            Column() {
              this.AuxiliarySection()
            }
          }
        }
        .width('100%')
        .padding({ bottom: 32 })
        .onBreakpointChange((bp: string) => { this.currentBreakpoint = bp })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COLORS.BG_PAGE)
      .scrollBar(BarState.Off)

      // 付费墙弹窗（覆盖在内容之上）
      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: this.showPaywallDialog
        })
      }
    }
    .width('100%')
    .height('100%')
    }
  }

// ==================== ① 顶部导航栏 ====================

  @Builder
  TopNavBar() {
    Row() {
      // 返回按钮
      Row() {
        BackButton({ fontSize: FONT_SIZE.LARGE, fontColor: COLORS.TEXT_PRIMARY })
      }
      .width(40)
      .height(BUTTON.HEIGHT_SMALL)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { safeBack() })
      .accessibilityText($r('app.string.back_arrow'))
      .accessibilityDescription($r('app.string.report_back_desc'))
      .margin({ left: 4 })

      Blank()

      // 食品名称
      Text(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : $r('app.string.report_default_title'))
        .fontSize(FONT_SIZE.LG)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()

      // 分享按钮
      Row() {
        Text('\uD83D\uDCF8')
          .fontSize(FONT_SIZE.XL)
      }
      .width(40)
      .height(BUTTON.HEIGHT_SMALL)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.handleSaveImage() })
      .accessibilityText($r('app.string.report_save_image'))
      .accessibilityLevel('yes')
      .margin({ right: 4 })
    }
    .width('100%')
    .height(BUTTON.HEIGHT_LG)
    .padding({ left: 8, right: 8 })
    .backgroundColor(COLORS.WHITE)
  }

  // ==================== ② Hero 评测区 ====================

  @Builder
  HeroSection() {
    Column() {
      Row() {
        // 左侧：NutriScore 徽章（紧凑版）
        NutriScoreBadge({
          score: this.nutriScore,
          diameter: 100,
          animating: this.showNutriAnim,
          levelText: this.selectedRec.level as string,
          levelBgColor: getLevelColorValue(this.selectedRec.levelColor)
        })
        .accessibilityRole('meter')
        .accessibilityValue({ min: 0, max: 100, now: this.nutriScore })
        .accessibilityText(`营养评分${this.nutriScore}分`)

        // Nova 加工分级 + EcoScore 生态评级
        Column({ space: 4 }) {
          NovaGroupBadge({ group: (this.foodLabel.novaGroup ?? 0) as NovaGroup })
          EcoScoreBadge({ grade: (this.foodLabel.ecoScoreGrade ?? 'unknown') as EcoScore })
        }.margin({ left: 8 })

        // 过敏原高亮列表
        if (this.foodLabel.allergens.length > 0) {
          AllergenHighlightList({ allergenHints: this.foodLabel.allergens, ingredients: this.foodLabel.ingredients })
            .accessibilityRole('list')
            .accessibilityText(`过敏原列表：${this.foodLabel.allergens.join('、')}`)
        }

        // 添加剂红绿灯可视化（对标 Yuka/Olive）
        if (this.foodLabel.ingredients.length > 0) {
          AdditiveTrafficLightList({
            entries: AdditiveClassifier.classifyIngredients(this.foodLabel.ingredients),
            showSummary: true,
            maxDisplay: 8
          })
        }

        // 交叉过敏/健康风险预警
        if (this.selectedRec !== null) {
          RiskAssessmentPanel({ riskResult: null })
        }

        // 三评级联动面板（NutriScore + Nova + EcoScore 综合评级）
        ComprehensiveRatingPanel({
          nutriScore: this.scoreToNutriScore(this.nutriScore),
          novaGroup: this.foodLabel.novaGroup ?? 0,
          ecoScoreGrade: (this.foodLabel.ecoScoreGrade ?? 'unknown') as string
        })

        // 添加剂交互毒性卡片
        AdditiveInteractionCard({ result: this.interactionResult })

        // 右侧：适配结论 + 最大可吃量 + 成员胶囊
        Column() {
          // 最大可吃量行（紧凑突出显示）
          if (this.selectedRec.maxAmount > 0) {
            Row() {
              Text($r('app.string.today_ref'))
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_TERTIARY)
              Text(`${this.selectedRec.maxAmount}g`)
                .fontSize(FONT_SIZE.XL)
                .fontWeight(FONT_WEIGHT.BOLD)
                .fontColor(COLORS.TEXT_PRIMARY)
              Text($r('app.string.report_per_100g_unit'))
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_TERTIARY)
                .margin({ left: 2 })
                .alignSelf(ItemAlign.End)
            }
            .margin({ bottom: 4 })
          }

          // 主要原因行（一句话摘要）
          if (this.selectedRec.reasons.length > 0) {
            Row() {
              Text('📰 ')
                .fontSize(FONT_SIZE.SMALL)
              Text(this.selectedRec.reasons[0])
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
                .lineHeight(18)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .margin({ bottom: 4 })
          }

          // 家庭成员横向胶囊切换器
          this.MemberCapsuleSwitcher()
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16, top: 12, bottom: 6 })
      .backgroundColor(COLORS.WHITE)
      .borderRadius({
        topLeft: RADIUS.LG,
        topRight: RADIUS.LG
      })

      // 提醒列表（紧凑展示）
      if (this.selectedRec.reminders.length > 0) {
        Column() {
          ForEach(this.selectedRec.reminders, (reminder: string, index: number) => {
            Row() {
              Text('• ')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.ACCENT_BLUE)
              Text(reminder)
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
                .lineHeight(18)
            }
            .margin({ bottom: 2 })
            .width('100%')
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 6 })
      }

      // 营养成分快速摘要
      this.NutritionQuickSummary()
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .margin({ top: 4 })
  }

  // ==================== 家庭成员胶囊切换器 ====================

  @Builder
  MemberCapsuleSwitcher() {
    if (this.familyMembers.length > 0) {
      Scroll() {
        Row({ space: 6 }) {
          ForEach(this.familyMembers, (member: FamilyProfile, index: number) => {
            // 紧凑胶囊 - 100x32px
            Row() {
              // 等级小圆点（简化：仅留圆点表示）
              if (index < this.recommendations.length) {
                Row()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(getLevelColorValue(this.recommendations[index].levelColor))
                  .margin({ right: 4 })
              }
              // 成员昵称缩写
              Text(member.nickname.length > 3 ?
                member.nickname.substring(0, 2) : member.nickname)
                .fontSize(FONT_SIZE.TINY)
                .fontWeight(this.selectedMemberIndex === index ?
                  FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
                .fontColor(this.selectedMemberIndex === index ?
                  COLORS.TEXT_PRIMARY : COLORS.TEXT_TERTIARY)
                .maxLines(1)
            }
            .height(28)
            .padding({ left: 10, right: 10 })
            .borderRadius(14)
            .backgroundColor(this.selectedMemberIndex === index ?
              COLORS.BG_PAGE : COLORS.BG_LIGHT_GRAY_F9)
            .border({
              width: 1,
              color: this.selectedMemberIndex === index ?
                getLevelColorValue(this.recommendations[index]?.levelColor ?? LevelColor.GREEN) :
                COLORS.BORDER_LIGHT_E8
            })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.selectedMemberIndex = index
            })
            .accessibilityText($r('app.string.ai_chat_switch_member'))
            .accessibilityLevel('yes')
          })
        }
        .padding({ left: 2, right: 2 })
      }
      .width('100%')
      .height(34)
      .scrollBar(BarState.Off)
      .padding({ top: 0 })
    }
  }

  // ==================== 营养成分快速摘要 ====================

  // 营养素每日参考值（基于中国居民膳食营养素参考摄入量）
  private static readonly NUTRIENT_REFERENCE: Record<string, number> = {
    '热量': 2000,
    '钠': 2000,
    '糖': 50,
    '脂肪': 65,
    '蛋白质': 65
  };

  // 获取指定营养素标签对应的食品含量
  private getNutrientValue(label: string): number {
    const n = this.foodLabel?.nutrition;
    if (!n) return 0;
    switch (label) {
      case '热量': return n.calories ?? 0;
      case '钠': return n.sodium ?? 0;
      case '糖': return n.sugar ?? 0;
      case '脂肪': return n.fat ?? 0;
      case '蛋白质': return n.protein ?? 0;
      default: return 0;
    }
  }

  // 获取营养素百分比（相对于每日参考值）
  private getNutrientPercentage(label: string): number {
    const ref = ReportPage.NUTRIENT_REFERENCE[label];
    if (!ref || ref === 0) return 0;
    return Math.min(100, Math.round(this.getNutrientValue(label) / ref * 100));
  }

  @Builder
  NutritionQuickSummary() {
    Scroll() {
      Row({ space: SPACING.XS }) {
        this.NutrientTag($r('app.string.calorie'), `${this.foodLabel?.nutrition?.calories ?? 0}`, 'kcal', this.getNutrientPercentage('热量'))
        this.NutrientTag($r('app.string.sodium'), `${this.foodLabel?.nutrition?.sodium ?? 0}`, 'mg', this.getNutrientPercentage('钠'))
        this.NutrientTag($r('app.string.sugar'), `${this.foodLabel?.nutrition?.sugar ?? 0}`, 'g', this.getNutrientPercentage('糖'))
        this.NutrientTag($r('app.string.fat'), `${this.foodLabel?.nutrition?.fat ?? 0}`, 'g', this.getNutrientPercentage('脂肪'))
        this.NutrientTag($r('app.string.protein'), `${this.foodLabel?.nutrition?.protein ?? 0}`, 'g', this.getNutrientPercentage('蛋白质'))
      }
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(68)
    .scrollBar(BarState.Off)
    .margin({ bottom: 4 })
  }

  @Builder
  NutrientTag(label: ResourceStr, value: string, unit: string, percentage: number = 0) {
    Column() {
      Text(label)
        .fontSize(10)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ bottom: 1 })
      Row() {
        Text(value)
          .fontSize(FONT_SIZE.SMALL)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
        Text(unit)
          .fontSize(9)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ left: 1 })
          .alignSelf(ItemAlign.End)
      }
      .margin({ bottom: 4 })
      // 进度条 + 百分比
      Column() {
        Row()
          .width(percentage > 100 ? '100%' : `${Math.round(percentage)}%`)
          .height(3)
          .borderRadius(2)
          .backgroundColor(percentage > 80 ? COLORS.ACCENT_RED_EF53 : percentage > 50 ? COLORS.ACCENT_ORANGE_FFA7 : COLORS.ACCENT_GREEN_66BB)
        Text(`${Math.round(percentage)}%`)
          .fontSize(8)
          .fontColor(percentage > 80 ? COLORS.ACCENT_RED_EF53 : percentage > 50 ? COLORS.ACCENT_ORANGE_FFA7 : COLORS.TEXT_GRAY_9E9E)
          .lineHeight(10)
      }
      .width(40)
      .alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .backgroundColor(COLORS.BG_LIGHTER_GRAY_F8)
    .borderRadius(10)
    .alignItems(HorizontalAlign.Center)
    .height(60)
  }

  // ==================== ③ 家庭矩阵区 ====================  // ==================== ③ 家庭矩阵区 ====================

  @Builder
  FamilyMatrixSection() {
    Column() {
      // 标题行
      Row() {
        Text('\uD83D\uDC65')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text($r('app.string.family_diff_conclusion'))
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, top: 20, bottom: 12 })

      // Swiper 横向滑动矩阵
      Swiper(this.swiperController) {
        ForEach(this.recommendations, (rec: Recommendation, idx: number) => {
          this.MemberMatrixCard(rec, idx)
        }, (rec: Recommendation) => rec.memberId)
      }
      .width('100%')
      .height(200)
      .index(this.selectedMemberIndex)
      .autoPlay(false)
      .indicator(false)
      .loop(false)
      .onChange((index: number) => {
        this.selectedMemberIndex = index
      })

      // 指示器圆点
      if (this.recommendations.length > 1) {
        Row({ space: 8 }) {
          ForEach(this.recommendations, (rec: Recommendation, idx: number) => {
            Row()
              .width(idx === this.selectedMemberIndex ? 20 : 8)
              .height(8)
              .borderRadius(4)
              .backgroundColor(idx === this.selectedMemberIndex
                ? this.getMemberLevelColor(rec)
                : COLORS.BORDER_LIGHT_DD)
          }, (rec: Recommendation) => rec.memberId)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: 12 })
      }
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .margin({ top: 8 })
  }

  @Builder
  MemberMatrixCard(rec: Recommendation, index: number) {
    Row() {
      // 左侧：成员头像区
      Column() {
        Text(this.getMemberEmoji(rec.memberId))
          .fontSize(36)
          .margin({ bottom: 4 })
        Text(this.getMemberName(rec.memberId))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
        Text(this.getMemberGoal(rec.memberId))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
      }
      .width(80)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

      // 右侧：适配结论
      Column() {
        // 等级胶囊
        Row() {
          Circle()
            .width(12)
            .height(12)
            .fill(getLevelColorValue(rec.levelColor))
            .margin({ right: 6 })
          Text(rec.level)
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(getLevelColorValue(rec.levelColor))
        }
        .margin({ bottom: 6 })

        // 最大量
        if (rec.maxAmount > 0) {
          Text($r('app.string.report_max_amount', rec.maxAmount))
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 4 })
        }

        // 原因摘要
        if (rec.reasons.length > 0) {
          Text(rec.reasons[0])
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_SECONDARY)
            .lineHeight(18)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('90%')
    .height(170)
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_LIGHTER_GRAY_F8)
    .borderRadius(RADIUS.LG)
    .margin({ left: 20, right: 20 })
    .alignItems(VerticalAlign.Center)
    // 滑动入场动画（从右侧滑入+透明度变化）
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.translate({ x: 80 }).combine(TransitionEffect.opacity(0))
          .animation({ curve: curves.springMotion(0.5, 0.7) }),
        TransitionEffect.translate({ x: -30 }).combine(TransitionEffect.opacity(0))
          .animation({ curve: curves.springMotion() })
      )
    )
  }

  // ==================== ④ 辅助信息区 ====================

  @Builder
  AuxiliarySection() {
    Column() {
      // 替代品推荐
      if (this.alternatives.length > 0) {
        this.AlternativeSection()
      }

      // 食品对比入口
      if (this.foodLabel.barcode.length > 0) {
        Row() {
          Text($r('app.string.food_compare_title'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLORS.PRIMARY)
            .layoutWeight(1)
          Text('›')
            .fontSize(20)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
        .width('92%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(12)
        .margin({ top: 8 })
        .onClick(() => {
          safePushUrl(`pages/FoodComparePage?barcode=${this.foodLabel.barcode}`)
        })
        .accessibilityText($r('app.string.report_food_compare'))
      }

      // 可信度信息
      this.CredibilitySection()

      // 儿童面板
      this.ChildProtectionSection()

      // 品牌查询入口
      this.ManufacturerSection()

      // 底部独立性声明
      Column() {
        Text($r('app.string.disclaimer_report'))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
          .lineHeight(18)
      }
      .width('100%')
      .padding({ top: 20, bottom: 40 })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  // ==================== 替代品推荐区 ====================

  @Builder
  AlternativeSection() {
    Column() {
      Row() {
        Text('\uD83C\uDF1F')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text($r('app.string.alternative_section_title'))
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, top: 16, bottom: 8 })

      if (this.showAlternativesLocked) {
        // 锁定状态 — 引导用户升级
        Row() {
          Text('🔒')
            .fontSize(20)
            .margin({ right: 8 })
          Column() {
            Text($r('app.string.alternative_locked'))
              .fontSize(FONT_SIZE.BODY)
              .fontWeight(FONT_WEIGHT.MEDIUM)
              .fontColor(COLORS.TEXT_PRIMARY)
            Text($r('app.string.unlock_alt_desc'))
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          Button($r('app.string.unlock'), { type: ButtonType.Normal, stateEffect: true })
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.WHITE)
            .backgroundColor(COLORS.PRIMARY)
            .borderRadius(RADIUS.SM)
            .height(32)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.paywallTrigger = this.appState.member.getPaywallTrigger('upgrade_member')
              this.showPaywallDialog = true
            })
            .accessibilityText($r('app.string.unlock'))
            .accessibilityLevel('yes')
        }
        .width('92%')
        .padding(16)
        .backgroundColor(COLORS.BG_WARM_YELLOW)
        .borderRadius(RADIUS.MD)
        .margin({ bottom: 12 })
      } else {
        Scroll() {
          Row({ space: SPACING.MD }) {
            ForEach(this.alternatives, (item: AlternativeFood) => {
              this.AlternativeCard(item)
            }, (item: AlternativeFood) => item.productName)
          }
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .height(140)
        .accessibilityRole('list')
        .accessibilityText(`替代品推荐列表，共${this.alternatives.length}项`)
      }
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .margin({ top: 8 })
    .padding({ bottom: 12 })
  }

  @Builder
  AlternativeCard(item: AlternativeFood) {
    Column() {
      Text(item.productName)
        .fontSize(FONT_SIZE.BODY)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(item.reason)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .lineHeight(16)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
    }
    .width(140)
    .height(110)
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_LIGHT_GREEN)
    .borderRadius(RADIUS.MD)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }

  // ==================== 可信度区 ====================

  @Builder
  CredibilitySection() {
    Column() {
      Row() {
        Text('\uD83D\uDEE1\uFE0F')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text($r('app.string.report_data_credibility'))
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Text(`${this.credibilityResult.score}分`)
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(this.credibilityResult.score >= 60 ? COLORS.LEVEL_GREEN : COLORS.LEVEL_ORANGE)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      Text(this.credibilityResult.getLevelDesc())
        .fontSize(FONT_SIZE.BODY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .lineHeight(20)
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 8 })

      // 提示列表
      if (this.credibilityResult.tips.length > 0) {
        ForEach(this.credibilityResult.tips, (tip: string, index: number) => {
          Row() {
            Text('•')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.ACCENT_PURPLE)
              .margin({ right: 6 })
            Text(tip)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .lineHeight(18)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 4 })
        })
      }
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .margin({ top: 8 })
    .padding({ bottom: 12 })
  }

  // ==================== 儿童保护面板 ====================

  @Builder
  ChildProtectionSection() {
    if (this.childProtections.length > 0) {
      Column() {
        Row() {
          Text('\uD83D\uDC76')
            .fontSize(FONT_SIZE.LG)
            .margin({ right: 6 })
          Text($r('app.string.report_child_protection'))
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
        }
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 8 })

        ForEach(this.childProtections, (cp: ChildProtection, index: number) => {
          if (cp.hasAnyAdvice()) {
            Column() {
              if (cp.mealProtection.length > 0) {
                this.ProtectionRow('\uD83C\uDF7D', $r('app.string.report_meal') as ResourceStr, cp.mealProtection)
              }
              if (cp.bedtimeProtection.length > 0) {
                this.ProtectionRow('\uD83D\uDCA4', $r('app.string.report_bedtime') as ResourceStr, cp.bedtimeProtection)
              }
              if (cp.tasteProtection.length > 0) {
                this.ProtectionRow('\uD83D\uDC43', $r('app.string.report_taste') as ResourceStr, cp.tasteProtection)
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20 })
            .margin({ bottom: 8 })
          }
        })
      }
      .width('100%')
      .backgroundColor(COLORS.WHITE)
      .margin({ top: 8 })
      .padding({ bottom: 12 })
    }
  }

  @Builder
  ProtectionRow(icon: string, label: ResourceStr, text: string) {
    Row() {
      Text(label)
        .fontSize(FONT_SIZE.SMALL)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .width(60)
      Text(text)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .lineHeight(18)
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: 6 })
  }

  // ==================== 厂家信息 ====================

  @Builder
  ManufacturerSection() {
    if (this.foodLabel.manufacturer.length > 0 || this.foodLabel.scNumber.length > 0 || this.foodLabel.principal.length > 0) {
      Column() {
        Row() {
          Text('\uD83C\uDFED')
            .fontSize(FONT_SIZE.LG)
            .margin({ right: 6 })
          Text($r('app.string.report_production_info'))
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
        }
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 8 })

        if (this.foodLabel.manufacturer.length > 0) {
          Row() {
            Text($r('app.string.report_producer_label'))
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
            Text(this.foodLabel.manufacturer)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 4 })
        }

        if (this.foodLabel.scNumber.length > 0) {
          Row() {
            Text($r('app.string.report_sc_number_label'))
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
            Text(this.foodLabel.scNumber)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 4 })
        }

        if (this.foodLabel.principal.length > 0) {
          Row() {
            Text($r('app.string.report_principal_label'))
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
            Text(this.foodLabel.principal)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 4 })
        }
      }
      .width('100%')
      .backgroundColor(COLORS.WHITE)
      .margin({ top: 8 })
      .padding({ bottom: 12 })
    }
  }

  // ==================== 骨架屏 ====================

  @Builder
  SkeletonScreen() {
    Column() {
      // 顶部导航占位
      Row() {
        Row()
          .width(40).height(20).backgroundColor(COLORS.BORDER_LIGHT).borderRadius(4)
        Blank()
        Row()
          .width(120).height(20).backgroundColor(COLORS.BORDER_LIGHT).borderRadius(4)
        Blank()
        Row()
          .width(40).height(20).backgroundColor(COLORS.BORDER_LIGHT).borderRadius(4)
      }
      .width('100%')
      .height(BUTTON.HEIGHT_LG)
      .padding({ left: 16, right: 16 })

      // 主体占位
      Column() {
        Row() {
          Circle().width(110).height(110).fill(COLORS.BORDER_LIGHT_E8)
            .margin({ right: 20 })
          Column() {
            Row().width(80).height(24).backgroundColor(COLORS.BORDER_LIGHT_E8).borderRadius(12)
              .margin({ bottom: 8 })
            Row().width(100).height(18).backgroundColor(COLORS.BORDER_LIGHT_E8).borderRadius(4)
              .margin({ bottom: 6 })
            Row().width(60).height(14).backgroundColor(COLORS.BORDER_LIGHT_E8).borderRadius(4)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(20)
      }
      .width('100%')
      .height(180)
      .backgroundColor(COLORS.WHITE)
      .margin({ top: 4 })

      // 更多占位
      Column()
        .width('100%')
        .height(200)
        .backgroundColor(COLORS.WHITE)
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
    .accessibilityGroup(true)
    .accessibilityDescription($r('app.string.report_page_accessibility_desc'))
  }  // ==================== 业务逻辑方法 ====================

  /**
   * 从路由参数解析数据
   */
  private getPageParams(): ReportPageParams | null {
    try {
      const navStack = NavigationManager.getStack()
      const routerParams = navStack.getParamByName('ReportPage') as Object
      if (routerParams === null || routerParams === undefined) return null
      const params = routerParams as Record<string, Object>

      const foodLabel = (params['foodLabel'] as FoodLabel) || new FoodLabel()
      const recommendations = (params['recommendations'] as Recommendation[]) || []
      const members = (params['members'] as FamilyProfile[]) || []
      const alternatives = (params['alternatives'] as AlternativeFood[]) || []
      const nutriScore = (params['nutriScore'] as number) || 50

      const credJson = params['credibilityResult'] as CredibilityResult
      const credibilityResult = credJson || new CredibilityResult()

      const childJson = params['childProtection'] as ChildProtection[]
      const childProtection = childJson || []

      const pageParams = new ReportPageParams();
      pageParams.foodLabel = foodLabel;
      pageParams.recommendations = recommendations;
      pageParams.members = members;
      pageParams.alternatives = alternatives;
      pageParams.nutriScore = nutriScore;
      pageParams.credibilityResult = credibilityResult;
      pageParams.childProtection = childProtection;
      return pageParams;
    } catch (_error) {
      return null
    }
  }

  /**
   * 保存分享图片
   */
  private async handleSaveImage(): Promise<void> {
    if (this.isImageSaving || !this.componentActive) return
    this.isImageSaving = true

    try {
      const uiContext = this.getUIContext()
      if (uiContext === null || uiContext === undefined) {
        promptAction.showToast({ message: $r('app.string.report_save_failed') })
        this.isImageSaving = false
        return
      }
      const context = uiContext.getHostContext() as common.Context
      if (context === null || context === undefined) {
        promptAction.showToast({ message: $r('app.string.report_save_failed') })
        this.isImageSaving = false
        return
      }

      const memberResults: MemberShareInfo[] = this.recommendations.map((rec) => {
        const member = this.familyMembers.find(m => m.memberId === rec.memberId)
        const info = new MemberShareInfo()
        info.name = member?.nickname || ''
        info.levelText = rec.level
        info.levelColor = getLevelColorValue(rec.levelColor)
        info.maxIntake = rec.maxAmount > 0 ? $r('app.string.report_max_intake_format', rec.maxAmount) as string : ''
        return info
      })

      const params = new ShareImageParams()
      params.foodName = this.foodLabel.foodName
      params.nutriScore = this.nutriScore
      params.levelColor = this.levelColorHex
      params.memberResults = memberResults
      params.cardType = 'FAMILY_COMPARE'
      params.qrPlaceholder = '家庭食品适配助手'

      await ShareCardGenerator.generateShareImage(context, params)
      promptAction.showToast({ message: $r('app.string.report_image_saved') })
    } catch (_error) {
      promptAction.showToast({ message: $r('app.string.report_save_failed_retry') })
    }

    this.isImageSaving = false
  }

  /**
   * 获取成员表情
   */
  private getMemberEmoji(memberId: string): string {
    const member = this.familyMembers.find(m => m.memberId === memberId)
    if (member === undefined) return '🧑'
    if (member.nickname.includes('爸爸')) return '\uD83D\uDC68'
    if (member.nickname.includes('妈妈')) return '\uD83D\uDC69'
    if (member.nickname.includes('孩子') || member.nickname.includes('宝宝')) return '\uD83D\uDC76'
    return '\uD83E\uDDD1'
  }

  /**
   * 获取成员名称
   */
  private getMemberName(memberId: string): ResourceStr {
    const member = this.familyMembers.find(m => m.memberId === memberId)
    return member?.nickname || $r('app.string.report_member_default') as ResourceStr
  }

  /**
   * 获取成员健康目标
   */
  private getMemberGoal(memberId: string): string {
    const member = this.familyMembers.find(m => m.memberId === memberId)
    if (member === undefined || member.healthGoals.length === 0) return ''
    return member.healthGoals[0] as string
  }

  /**
   * 获取成员等级色值
   */
  private getMemberLevelColor(rec: Recommendation): string {
    return getLevelColorValue(rec.levelColor)
  }

  private scoreToNutriScore(score: number): NutriScore {
    if (score >= 80) return NutriScore.A;
    if (score >= 60) return NutriScore.B;
    if (score >= 40) return NutriScore.C;
    if (score >= 20) return NutriScore.D;
    return NutriScore.E;
  }

  pageTransition() {
    PageTransitionEnter({ duration: 400, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
