// 家庭饮食报告页 - V6 极简重构
// 沉浸式呈现：营养评分 | 家庭差异 | 替代信息卡
import {
  safeBack, safePushUrl, FamilyProfile, FoodLabel, Recommendation, RecommendLevel, LevelColor, getLevelColorValue, AlternativeFood, ChildProtection, CredibilityResult, PaywallTrigger, MemberTier, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON, SHADOWS, AccessibilityUtil, NavigationManager, PageResourceTracker, createPageTracker, HILOG_DOMAIN_DEFAULT, HealthGoal, ToastHelper,   ThemeReactive, themeReactive, ThemeColors, ThemeMode, HapticHelper
} from 'hsp_core';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { promptAction, curves, componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { BackButton } from '../components/BackButton';
import { GlassCard, GlassDepth } from '../components/GlassCard';
import { GradientArc } from '../components/GradientArc';
import { AppState } from '../AppState';
import { AllergenHighlightList, PaywallDialog, AdditiveTrafficLightList, AdditiveClassifier } from 'feature_scan';
import { AdditiveSafetyEngine, FoodAdditiveReport, AdditiveAssessment, AdditiveSafetyRiskLevel } from 'feature_scan';
import { AdditiveInteractionEngine } from 'feature_scan';
import { AllergyEngine, AllergyHint } from 'hsp_allergy';
import { NovaGroupBadge, EcoScoreBadge, EcoScore, RiskAssessmentPanel, ShareCardGenerator, MemberShareInfo, ShareImageParams, ComprehensiveRatingPanel } from 'feature_report';
import { NutriScore } from 'hsp_core';
import { InteractionAssessmentResult, NovaGroup } from 'feature_scan';
import { AdditiveInteractionCard } from '../components/AdditiveInteractionCard';
import { NutrientTag } from '../components/NutrientTag';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ReportPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

// ===== 页面级数据类 =====

/** ReportPage 路由参数接口，通过 AppState.setReportParams 设置 */
export class ReportPageParams {
  foodLabel: FoodLabel = new FoodLabel();
  recommendations: Recommendation[] = [];
  members: FamilyProfile[] = [];
  alternatives: AlternativeFood[] = [];
  nutriScore: number = 50;
  credibilityResult: CredibilityResult = new CredibilityResult();
  childProtection: ChildProtection[] = [];
}

class NutritionTip {
  text: string = '';
  color: string = '';
}

@Entry
@ComponentV2
export struct ReportPage {
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
  @Local additiveSafetyReport: FoodAdditiveReport | null = null
  @Local allergyHints: AllergyHint[] = []


  private appState: AppState = AppState.getInstance()
  private credibilityResult: CredibilityResult = new CredibilityResult()
  private childProtections: ChildProtection[] = []
  private swiperController: SwiperController = new SwiperController()
  private componentActive: boolean = true

  private tracker: PageResourceTracker = createPageTracker('ReportPage')
  // ==================== 生命周期 ====================

  private themeRef: ThemeReactive = themeReactive

  async aboutToAppear() {
        this.tracker.onAppear()
    // 优先从路由缓存获取参数（router params 内存缓存机制）
    const cachedFoodLabel = this.appState.reportCache.consumeFoodLabel()
    const cachedRecs = this.appState.reportCache.consumeRecommendations()
    const cachedAlts = this.appState.reportCache.consumeAlternatives()
    
    if (cachedFoodLabel !== null) {
      this.foodLabel = cachedFoodLabel
      this.recommendations = cachedRecs ?? []
      this.alternatives = cachedAlts ?? []
    } else {
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

    this.runEngineAnalysis();

    this.showSkeleton = false
    this.showNutriAnim = true
  }

  private async runEngineAnalysis(): Promise<void> {
    try {
      if (this.foodLabel.ingredients.length > 0) {
        const additiveEngine: AdditiveSafetyEngine = AdditiveSafetyEngine.getInstance();
        const ctx = getContext(this);
        await additiveEngine.loadCnDatabase(ctx);
        this.additiveSafetyReport = additiveEngine.assessFood(this.foodLabel);
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AdditiveSafetyEngine failed: %{public}s', JSON.stringify(e));
    }

    try {
      if (this.foodLabel.ingredients.length >= 2) {
        this.interactionResult = AdditiveInteractionEngine.getInstance().assessInteractions(this.foodLabel.ingredients);
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AdditiveInteractionEngine failed: %{public}s', JSON.stringify(e));
    }

    try {
      if (this.familyMembers.length > 0) {
        const allergyEngine: AllergyEngine = new AllergyEngine();
        this.allergyHints = allergyEngine.detectAllergens(this.foodLabel, this.familyMembers);
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AllergyEngine failed: %{public}s', JSON.stringify(e));
    }
  }

  aboutToDisappear(): void {
        this.tracker.onDisappear()
    this.componentActive = false
  }

  // ==================== 计算属性 ====================

  private get selectedRec(): Recommendation {
    if (this.recommendations.length === 0) {
      const fallback: Recommendation = new Recommendation()
      fallback.memberId = 'none'
      fallback.level = RecommendLevel.SUITABLE
      fallback.levelColor = LevelColor.GREEN
      fallback.reasons = ['根据成分无明显风险']
      return fallback
    }
    const idx = Math.min(this.selectedMemberIndex, this.recommendations.length - 1)
    return this.recommendations[idx]
  }

  private get levelColorHex(): string {
    return getLevelColorValue(this.selectedRec.levelColor)
  }

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] }
    }
    return { angle: 180, colors: [['#FFF8E1', 0.0], ['#FFF3E0', 0.3], ['#FCE4EC', 0.7], ['#F3E5F5', 1.0]] }
  }

  private get nutriScoreLetter(): string {
    if (this.nutriScore >= 80) return 'A'
    if (this.nutriScore >= 60) return 'B'
    if (this.nutriScore >= 40) return 'C'
    if (this.nutriScore >= 20) return 'D'
    return 'E'
  }

  // ==================== 主 UI ====================

  build() {
    Column() {
      // 骨架屏 - 使用系统渲染机制
      if (this.showSkeleton) {
        Stack() {
          this.SkeletonScreen()
        }
      }

      Scroll() {
        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { value: ['320vp', '600vp'], reference: BreakpointsReference.WindowSize }
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- 顶部导航 ----
            Row() {
              this.TopNavBar()
            }
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- 核心测评板块（Hero）----
            Column() {
              this.HeroSection()
            }
            .id('report_hero')
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- 家庭差异分析 ----
            Column() {
              this.FamilyMatrixSection()
            }
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- 辅助信息卡 ----
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
      .scrollBar(BarState.Off)

      // 付费墙弹窗（覆盖于内容之上）
      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: this.showPaywallDialog
        })
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
    }


// ==================== 顶部导航 ====================

  @Builder
  TopNavBar() {
     Row() {
       BackButton({ fontSize: FONT_SIZE.LARGE, fontColor: COLORS.WHITE })
       .margin({ left: 4 })

      Blank()

      // 食品名称
      Text(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : $r('app.string.report_default_title'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()

      // 截图按钮
      Row() {
        Text('\uD83D\uDCF8')
          .fontSize(FONT_SIZE.XL)
      }
      .width(40)
      .height(BUTTON.HEIGHT_MD)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { HapticHelper.light(); this.handleSaveImage() })
      .margin({ right: 4 })
    }
    .width('100%')
    .height(BUTTON.HEIGHT_LG)
    .padding({ left: 8, right: 8, top: 44 })
    .linearGradient({
      angle: 135,
      colors: [['#E65100', 0.0], ['#F57C00', 0.3], ['#FF9800', 0.7], ['#FFB300', 1.0]]
    })
    .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  // ==================== Hero 核心区 ====================

  @Builder
  HeroSection() {
    Column({ space: SPACING.MD }) {
      GlassCard({
        depth: GlassDepth.HERO,
        radiusVal: RADIUS.XL,
        paddingVal: 20,
        glowColor: '#2243A047'
      }) {
        Column({ space: SPACING.MD }) {
          Row() {
            GradientArc({
              value: this.nutriScore,
              maxValue: 100,
              sizeVal: 160,
              lineWidth: 14,
              centerText: this.nutriScoreLetter,
              label: this.nutriScore.toString() + '/100',
              glowEnabled: true
            })

            Blank()

            Column() {
              if (this.selectedRec.maxAmount > 0) {
                Row() {
                  Text($r('app.string.today_ref'))
                    .fontSize(FONT_SIZE.SMALL)
                    .fontColor(COLORS.TEXT_TERTIARY)
                  Text(this.selectedRec.maxAmount.toString() + 'g')
                    .fontSize(FONT_SIZE.XL)
                    .fontWeight(FONT_WEIGHT.BOLD)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .margin({ left: 4 })
                  Text($r('app.string.report_per_100g_unit'))
                    .fontSize(FONT_SIZE.TINY)
                    .fontColor(COLORS.TEXT_TERTIARY)
                    .margin({ left: 2 })
                }
              }
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.selectedRec.reasons.length > 0) {
            Row() {
              Text('💡 ')
                .fontSize(FONT_SIZE.SMALL)
              Text(this.selectedRec.reasons[0])
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
                .lineHeight(18)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(RADIUS.LG)
            .backgroundColor(this.isDark ? '#1FFFFFFF' : '#33FFFFFF')
          }

          this.MemberCapsuleSwitcher()
        }
        .width('100%')
      }

      Row({ space: 12 }) {
        Column() {
          GlassCard({
            depth: GlassDepth.SURFACE,
            radiusVal: RADIUS.LG,
            paddingVal: 12
          }) {
            Column({ space: 6 }) {
              Text('超加工分级')
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_TERTIARY)
              NovaGroupBadge({ group: (this.foodLabel.novaGroup ?? 0) as NovaGroup })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
        }
        .layoutWeight(1)

        Column() {
          GlassCard({
            depth: GlassDepth.SURFACE,
            radiusVal: RADIUS.LG,
            paddingVal: 12
          }) {
            Column({ space: 6 }) {
              Text('生态评分')
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_TERTIARY)
              EcoScoreBadge({ grade: (this.foodLabel.ecoScoreGrade ?? 'unknown') as EcoScore })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.allergyHints.length > 0) {
        Column() {
          Text('过敏原与交叉反应检测')
            .fontSize(FONT_SIZE.SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 8 })
          ForEach(this.allergyHints, (hint: AllergyHint) => {
            Row() {
              Column() {
                Text(hint.memberNickname + ' - ' + hint.allergen)
                  .fontSize(FONT_SIZE.BODY)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(hint.severity === 'HIGH' ? COLORS.ERROR : COLORS.WARNING)
                Text(hint.detail)
                  .fontSize(FONT_SIZE.BODY_SM)
                  .fontColor(COLORS.TEXT_SECONDARY)
                  .margin({ top: 2 })
                if (hint.isCrossReactivity) {
                  Text('交叉反应')
                    .fontSize(10)
                    .fontColor(COLORS.WARNING)
                    .backgroundColor(COLORS.BG_WARM_ORANGE)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(8)
                    .margin({ top: 4 })
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.isDark ? '#1A2F1C' : '#FFFDE7')
            .borderRadius(RADIUS.LG)
            .margin({ bottom: 8 })
          }, (hint: AllergyHint, index: number) => hint.memberId + '_' + hint.allergen + '_' + index.toString())
        }
        .width('100%')
        .margin({ bottom: 12 })
      } else if (this.foodLabel.allergens.length > 0) {
        AllergenHighlightList({ allergenHints: this.foodLabel.allergens, ingredients: this.foodLabel.ingredients })
          .accessibilityText('过敏原列表')
      }

      if (this.foodLabel.ingredients.length > 0) {
        if (this.additiveSafetyReport !== null && this.additiveSafetyReport.assessments.length > 0) {
          Column() {
            Text('添加剂安全分析（国标）')
              .fontSize(FONT_SIZE.SUBTITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.TEXT_PRIMARY)
              .margin({ bottom: 8 })

            Row() {
              Text('整体风险: ' + this.additiveSafetyReport.overallRisk)
                .fontSize(FONT_SIZE.BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(
                  this.additiveSafetyReport.overallRisk === AdditiveSafetyRiskLevel.AVOID ? COLORS.ERROR :
                  this.additiveSafetyReport.overallRisk === AdditiveSafetyRiskLevel.CAUTION ? COLORS.WARNING :
                  COLORS.SUCCESS
                )
              Blank()
              Text(this.additiveSafetyReport.assessments.length.toString() + ' 种添加剂')
                .fontSize(FONT_SIZE.BODY_SM)
                .fontColor(COLORS.TEXT_TERTIARY)
            }
            .width('100%')

            ForEach(this.additiveSafetyReport.assessments, (a: AdditiveAssessment) => {
              Row() {
                Column() {
                  Row() {
                    Text(a.name)
                      .fontSize(FONT_SIZE.BODY)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(COLORS.TEXT_PRIMARY)
                    if (a.eNumber.length > 0) {
                      Text(a.eNumber)
                        .fontSize(10)
                        .fontColor(COLORS.TEXT_TERTIARY)
                        .backgroundColor(this.isDark ? '#1A2F1C' : '#F5F5F5')
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .borderRadius(4)
                        .margin({ left: 6 })
                    }
                    Blank()
                    Text(a.riskLevel)
                      .fontSize(FONT_SIZE.BODY_SM)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(
                        a.riskLevel === AdditiveSafetyRiskLevel.AVOID ? COLORS.ERROR :
                        a.riskLevel === AdditiveSafetyRiskLevel.CAUTION ? COLORS.WARNING :
                        COLORS.SUCCESS
                      )
                  }
                  .width('100%')

                  if (a.description.length > 0) {
                    Text(a.description)
                      .fontSize(FONT_SIZE.BODY_SM)
                      .fontColor(COLORS.TEXT_SECONDARY)
                      .margin({ top: 2 })
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }

                  if (a.cnMaxUsage !== undefined && a.cnMaxUsage.length > 0) {
                    Text('国标用量: ' + a.cnMaxUsage)
                      .fontSize(11)
                      .fontColor(COLORS.TEXT_TERTIARY)
                      .margin({ top: 2 })
                  }

                  if (a.childRestriction !== undefined && a.childRestriction.length > 0) {
                    Text('儿童限制: ' + a.childRestriction)
                      .fontSize(11)
                      .fontColor(COLORS.WARNING)
                      .margin({ top: 2 })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .margin({ top: 6 })
              .borderRadius(RADIUS.MD)
              .backgroundColor(this.isDark ? '#1A1A1A' : '#FAFAFA')
            }, (a: AdditiveAssessment, index: number) => (a.eNumber !== '' ? a.eNumber : a.name) + '_' + index.toString())
          }
          .width('100%')
          .margin({ bottom: 12 })
        } else {
          AdditiveTrafficLightList({
            entries: AdditiveClassifier.classifyIngredients(this.foodLabel.ingredients),
            showSummary: true,
            maxDisplay: 8
          })
        }
      }

      if (this.selectedRec !== null && this.interactionResult !== null && this.interactionResult.overallRiskScore > 0) {
        RiskAssessmentPanel({ riskResult: null })
      }

      ComprehensiveRatingPanel({
        nutriScore: this.scoreToNutriScore(this.nutriScore),
        novaGroup: this.foodLabel.novaGroup ?? 0,
        ecoScoreGrade: (this.foodLabel.ecoScoreGrade ?? 'unknown') as string
      })

      AdditiveInteractionCard({ result: this.interactionResult })
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.MD, bottom: SPACING.MD })
  }

  // ==================== 工具方法 ====================

  /** 根据成员ID获取对应的emoji头像 */
  private getMemberEmoji(memberId: string): string {
    const member = this.familyMembers.find((m: FamilyProfile) => m.memberId === memberId)
    if (!member) {
      return '👤'
    }
    const goals = member.healthGoals
    if (goals.includes(HealthGoal.CONTROL_BP) || goals.includes(HealthGoal.CONTROL_FAT)) {
      return '🧮'
    }
    if (goals.includes(HealthGoal.CHILD)) {
      return '🧒'
    }
    if (goals.includes(HealthGoal.LOSE_FAT)) {
      return '🏃'
    }
    if (goals.includes(HealthGoal.CONTROL_SUGAR)) {
      return '🍬'
    }
    return '👤'
  }

  /** 根据成员ID获取昵称 */
  private getMemberName(memberId: string): ResourceStr {
    const member = this.familyMembers.find((m: FamilyProfile) => m.memberId === memberId)
    return member ? member.nickname : $r('app.string.report_default_title')
  }

  /** 根据成员ID获取健康目标描述 */
  private getMemberGoal(memberId: string): string {
    const member = this.familyMembers.find((m: FamilyProfile) => m.memberId === memberId)
    if (!member || member.healthGoals.length === 0 || member.healthGoals[0] === HealthGoal.NONE) {
      return '均衡营养'
    }
    return member.healthGoals[0] as string
  }

  /** 根据推荐等级获取颜色hex值 */
  private getMemberLevelColor(rec: Recommendation): string {
    return getLevelColorValue(rec.levelColor)
  }

  /** 将数值评分(0-100)转换为NutriScore等级 */
  private scoreToNutriScore(score: number): NutriScore {
    if (score >= 80) return NutriScore.A
    if (score >= 60) return NutriScore.B
    if (score >= 40) return NutriScore.C
    if (score >= 20) return NutriScore.D
    return NutriScore.E
  }

  private buildNutritionTips(): NutritionTip[] {
    const tips: NutritionTip[] = []
    const n = this.foodLabel.nutrition
    if (n.sodium > 600) {
      const t: NutritionTip = new NutritionTip()
      t.text = '钠含量较高，建议控制每日摄入量'
      t.color = '#F44336'
      tips.push(t)
    }
    if (n.sugar > 12.5) {
      const t: NutritionTip = new NutritionTip()
      t.text = '糖含量偏高，注意控制食用量'
      t.color = '#FF9800'
      tips.push(t)
    }
    if (n.fat > 17.5) {
      const t: NutritionTip = new NutritionTip()
      t.text = '脂肪含量较高，建议适量食用'
      t.color = '#FF9800'
      tips.push(t)
    }
    if (n.protein > 10) {
      const t: NutritionTip = new NutritionTip()
      t.text = '蛋白质含量丰富，有助于肌肉健康'
      t.color = '#4CAF50'
      tips.push(t)
    }
    if (n.fiber > 3) {
      const t: NutritionTip = new NutritionTip()
      t.text = '膳食纤维充足，有益肠道健康'
      t.color = '#4CAF50'
      tips.push(t)
    }
    if (tips.length === 0) {
      const t: NutritionTip = new NutritionTip()
      t.text = '营养成分均衡，可适量食用'
      t.color = '#4CAF50'
      tips.push(t)
    }
    return tips
  }

  /** 从NavigationManager或路由缓存获取页面参数 */
  private getPageParams(): ReportPageParams | null {
    const cached = this.appState.reportCache.consumeFoodLabel()
    if (cached !== null) {
      const params: ReportPageParams = new ReportPageParams()
      params.foodLabel = cached
      const recs = this.appState.reportCache.consumeRecommendations()
      const alts = this.appState.reportCache.consumeAlternatives()
      if (recs !== null) params.recommendations = recs
      if (alts !== null) params.alternatives = alts
      return params
    }
    return null
  }

  /** 保存当前报告核心区域为截图 */
  private async handleSaveImage(): Promise<void> {
    hilog.info(DOMAIN_ZERO, TAG, 'handleSaveImage: screenshot requested for %{public}s',
      this.foodLabel.foodName)
    try {
      ToastHelper.show(this.getUIContext(), '正在生成截图...')

      const pixmap: image.PixelMap = await componentSnapshot.get('report_hero')

      const imagePacker: image.ImagePacker = image.createImagePacker()
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100
      }
      const data: ArrayBuffer = await imagePacker.packing(pixmap, packOpts)
      imagePacker.release()

      const context = getContext(this) as common.Context
      const helper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context)
      const uri: string = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png')
      const file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      fileIo.writeSync(file.fd, data)
      fileIo.closeSync(file.fd)

      ToastHelper.show(this.getUIContext(), '截图已保存到相册')
      hilog.info(DOMAIN_ZERO, TAG, 'Screenshot saved to gallery')
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'handleSaveImage failed: %{public}s', JSON.stringify(e))
      ToastHelper.show(this.getUIContext(), '截图保存失败')
    }
  }

  // ==================== 骨架屏 ====================

  @Builder
  SkeletonScreen() {
    LoadingSkeleton({ variant: 'detail' })
  }

  // ==================== 辅助信息区 ====================

  @Builder
  AuxiliarySection() {
    GlassCard({
      depth: GlassDepth.SURFACE,
      radiusVal: RADIUS.XL,
      paddingVal: 16,
      marginVal: { top: 12, left: '4%', right: '4%' },
      glowColor: '#22FFA726'
    }) {
      Column() {
        Text('营养建议')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 10 })

        ForEach(this.buildNutritionTips(), (tip: NutritionTip) => {
          Row({ space: 8 }) {
            Text('●')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(tip.color)
            Text(tip.text)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_SECONDARY)
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 6 })
          .alignItems(VerticalAlign.Center)
        }, (tip: NutritionTip, index: number) => index.toString())
      }
      .width('100%')
    }
  }

  // ==================== 成员切换胶囊 ====================

  @Builder
  MemberCapsuleSwitcher() {
    if (this.familyMembers.length <= 1) {
      Column() {}.height(1)
    } else {
      Row({ space: 8 }) {
        ForEach(this.familyMembers, (member: FamilyProfile, index: number) => {
          Row({ space: 4 }) {
            Text(this.getMemberEmoji(member.memberId))
              .fontSize(14)
            Text(member.nickname)
              .fontSize(12)
              .fontColor(this.selectedMemberIndex === index ? COLORS.WHITE : COLORS.TEXT_SECONDARY)
              .maxLines(1)
          }
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(14)
          .backgroundColor(this.selectedMemberIndex === index ? COLORS.PRIMARY : (this.isDark ? '#1FFFFFFF' : '#33FFFFFF'))
          .onClick(() => {
            HapticHelper.light()
            this.selectedMemberIndex = index
          })
        }, (member: FamilyProfile) => member.memberId)
      }
      .width('100%')
      .margin({ top: 8, bottom: 4 })
    }
  }

  // ==================== 家庭矩阵区域 ====================

  @Builder
  FamilyMatrixSection() {
    if (this.familyMembers.length === 0) {
      Column() {}.height(1)
    } else {
      Column() {
        Text('家庭差异分析')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ left: '4%', right: '4%', top: 16, bottom: 8 })

        ForEach(this.recommendations, (rec: Recommendation, index: number) => {
          this.MemberMatrixCard(rec, index)
        }, (rec: Recommendation) => rec.memberId)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  // ==================== 成员矩阵卡片 ====================

  @Builder
  MemberMatrixCard(rec: Recommendation, index: number) {
    GlassCard({
      depth: GlassDepth.SURFACE,
      radiusVal: RADIUS.LG,
      paddingVal: 12,
      marginVal: { top: 6, left: '4%', right: '4%' },
      glowColor: this.getMemberLevelColor(rec)
    }) {
      Row() {
        Column() {
          Text(this.getMemberEmoji(rec.memberId))
            .fontSize(18)
          Text(this.getMemberName(rec.memberId))
            .fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 2 })
          Text(this.getMemberGoal(rec.memberId))
            .fontSize(10)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 1 })
        }
        .alignItems(HorizontalAlign.Center)
        .width(60)

        Blank()

        Column() {
          Row() {
            Text(rec.level as string)
              .fontSize(FONT_SIZE.TINY)
              .fontWeight(FONT_WEIGHT.BOLD)
              .fontColor(COLORS.WHITE)
          }
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor(this.getMemberLevelColor(rec))

          if (rec.maxAmount > 0) {
            Text('建议 ≤' + rec.maxAmount + 'g')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }
}
