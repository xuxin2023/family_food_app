// ReportPage.ets
// ��ͥ���䱨��??- V6 �����ع�
// ����ʽ���֣����������� | ��ͥ����??| ������Ϣ??
import {
  safeBack, safePushUrl, FamilyProfile, FoodLabel, Recommendation, RecommendLevel, LevelColor, getLevelColorValue, AlternativeFood, ChildProtection, CredibilityResult, PaywallTrigger, MemberTier, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON, AccessibilityUtil, NavigationManager, PageResourceTracker, createPageTracker, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { promptAction, curves } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { NutriScoreBadge, AllergenHighlightList, PaywallDialog, AdditiveTrafficLightList, AdditiveClassifier } from 'feature_scan';
import { NovaGroupBadge, EcoScoreBadge, EcoScore, RiskAssessmentPanel, ShareCardGenerator, MemberShareInfo, ShareImageParams, ComprehensiveRatingPanel } from 'feature_report';
import { NutriScore } from 'hsp_core';
import { InteractionAssessmentResult, NovaGroup } from 'feature_scan';
import { AdditiveInteractionCard } from '../components/AdditiveInteractionCard';
import { NutrientTag } from '../components/NutrientTag';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ReportPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

// ===== ҳ�漶������ =====

/** ReportPage ·�ɲ����ӿڣ�ͨ�� AppState.setReportParams ����??*/
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


  private appState: AppState = AppState.getInstance()
  private credibilityResult: CredibilityResult = new CredibilityResult()
  private childProtections: ChildProtection[] = []
  private swiperController: SwiperController = new SwiperController()
  private componentActive: boolean = true

  private tracker: PageResourceTracker = createPageTracker('ReportPage')
  // ==================== �������� ====================

  async aboutToAppear() {
        this.tracker.onAppear()
    // ���ȴ�·�ɻ����ȡ������ router params ���л����������ƣ�
    const cachedFoodLabel = this.appState.reportCache.consumeFoodLabel()
    const cachedRecs = this.appState.reportCache.consumeRecommendations()
    const cachedAlts = this.appState.reportCache.consumeAlternatives()
    
    if (cachedFoodLabel !== null) {
      this.foodLabel = cachedFoodLabel
      this.recommendations = cachedRecs ?? []
      this.alternatives = cachedAlts ?? []
    } else {
      // �������� router params ��ȡ�����ݾ���ת??      const params = this.getPageParams()
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

    // ��鸶��ǽ ??���Ʒ�Ƽ���Ҫ��ͥ��
    const altTrigger = this.appState.member.getPaywallTrigger('upgrade_member')
    if (altTrigger !== null && altTrigger.requiredTier !== MemberTier.FREE &&
        this.alternatives.length > 0) {
      this.showAlternativesLocked = true
    }

    // ���ݾ�����رչǼ�����չʾ��??    this.showSkeleton = false
    this.showNutriAnim = true
  }

  aboutToDisappear(): void {
        this.tracker.onDisappear()
    this.componentActive = false
  }

  // ==================== ������??====================

  private get selectedRec(): Recommendation {
    if (this.recommendations.length === 0) {
      const fallback: Recommendation = new Recommendation()
      fallback.memberId = 'none'
      fallback.level = RecommendLevel.SUITABLE
      fallback.levelColor = LevelColor.GREEN
      fallback.reasons = ['������������']
      return fallback
    }
    const idx = Math.min(this.selectedMemberIndex, this.recommendations.length - 1)
    return this.recommendations[idx]
  }

  private get levelColorHex(): string {
    return getLevelColorValue(this.selectedRec.levelColor)
  }

  // ==================== ���� UI ====================

  build() {
    Column() {
      // �Ǽ�??- ʹ��������Ⱦ����
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
            // ---- �������� ----
            Row() {
              this.TopNavBar()
            }
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- ??������������Hero??----
            Column() {
              this.HeroSection()
            }
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- ??��ͥ����??----
            Column() {
              this.FamilyMatrixSection()
            }
          }

          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // ---- ??������Ϣ??----
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

      // ����ǽ����������������֮�ϣ�
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


// ==================== ??��������??====================

  @Builder
  TopNavBar() {
    Row() {
      // ���ذ�ť
      Row() {
        BackButton({ fontSize: FONT_SIZE.LARGE, fontColor: COLORS.TEXT_PRIMARY })
      }
      .width(40)
      .height(BUTTON.HEIGHT_MDALL)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { safeBack() })
      .accessibilityText($r('app.string.back_arrow'))
      .accessibilityDescription($r('app.string.report_back_desc'))
      .margin({ left: 4 })

      Blank()

      // ʳƷ����
      Text(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : $r('app.string.report_default_title'))
        .fontSize(FONT_SIZE.LG)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()

      // ������ť
      Row() {
        Text('\uD83D\uDCF8')
          .fontSize(FONT_SIZE.XL)
      }
      .width(40)
      .height(BUTTON.HEIGHT_MDALL)
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

  // ==================== ??Hero ����??====================

  @Builder
  HeroSection() {
    Column() {
      Row() {
        // ��ࣺNutriScore ���£����հ�??        NutriScoreBadge({
          score: this.nutriScore,
          diameter: 100,
          animating: this.showNutriAnim,
          levelText: this.selectedRec.level as string,
          levelBgColor: getLevelColorValue(this.selectedRec.levelColor)
        })


        // Nova �ӹ��ּ� + EcoScore ��̬��??        Column({ space: 4 }) {
          NovaGroupBadge({ group: (this.foodLabel.novaGroup ?? 0) as NovaGroup })
          EcoScoreBadge({ grade: (this.foodLabel.ecoScoreGrade ?? 'unknown') as EcoScore })
        }.margin({ left: 8 })

        // ����ԭ�����б�
        if (this.foodLabel.allergens.length > 0) {
          AllergenHighlightList({ allergenHints: this.foodLabel.allergens, ingredients: this.foodLabel.ingredients })
            .accessibilityText(`����ԭ�б���${this.foodLabel.allergens.join('��')}`)
        }

        // ���Ӽ����̵ƿ��ӻ����Ա� Yuka/Olive??        if (this.foodLabel.ingredients.length > 0) {
          AdditiveTrafficLightList({
            entries: AdditiveClassifier.classifyIngredients(this.foodLabel.ingredients),
            showSummary: true,
            maxDisplay: 8
          })
        }

        // �������/��������Ԥ��
        if (this.selectedRec !== null) {
          RiskAssessmentPanel({ riskResult: null })
        }

        // ������������壨NutriScore + Nova + EcoScore �ۺ�����??        ComprehensiveRatingPanel({
          nutriScore: this.scoreToNutriScore(this.nutriScore),
          novaGroup: this.foodLabel.novaGroup ?? 0,
          ecoScoreGrade: (this.foodLabel.ecoScoreGrade ?? 'unknown') as string
        })

        // ���Ӽ��������Կ�??        AdditiveInteractionCard({ result: this.interactionResult })

        // �Ҳࣺ������� + ���ɳ��� + ��Ա����
        Column() {
          // ���ɳ����У�����ͻ����ʾ??          if (this.selectedRec.maxAmount > 0) {
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

          // ��Ҫԭ���У�һ�仰ժҪ??          if (this.selectedRec.reasons.length > 0) {
            Row() {
              Text('?? ')
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

          // ��ͥ��Ա�������л�??          this.MemberCapsuleSwitcher()
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

      // �����б�������չʾ��
      if (this.selectedRec.reminders.length > 0) {
        Column() {
          ForEach(this.selectedRec.reminders, (reminder: string, index: number) => {
            Row() {
              Text('??')
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

      // Ӫ���ɷֿ���ժ??      this.NutritionQuickSummary()
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .margin({ top: 4 })
  }

  // ==================== ��ͥ��Ա�����л�??====================

  @Builder
  MemberCapsuleSwitcher() {
    if (this.familyMembers.length > 0) {
      Scroll() {
        Row({ space: 6 }) {
          ForEach(this.familyMembers, (member: FamilyProfile, index: number) => {
            // ���ս��� - 100x32px
            Row() {
              // �ȼ�СԲ�㣨�򻯣�����Բ���ʾ??              if (index < this.recommendations.length) {
                Row()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(getLevelColorValue(this.recommendations[index].levelColor))
                  .margin({ right: 4 })
              }
              // ��Ա�ǳ���д
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

  // ==================== Ӫ���ɷֿ���ժ??====================

  // Ӫ����ÿ�ղο�ֵ�������й�������ʳӪ���زο���������
  private static readonly NUTRIENT_REFERENCE: Record<string, number> = {
    '����': 2000,
    '��': 2000,
    '��': 50,
    '֬��': 65,
    '������': 65
  };

  // ��ȡָ��Ӫ���ر�ǩ��Ӧ��ʳƷ����
  private getNutrientValue(label: string): number {
    const n = this.foodLabel?.nutrition;
    if (!n) return 0;
    switch (label) {
      case '����': return n.calories ?? 0;
      case '��': return n.sodium ?? 0;
      case '��': return n.sugar ?? 0;
      case '֬��': return n.fat ?? 0;
      case '������': return n.protein ?? 0;
      default: return 0;
    }
  }

  // ��ȡӪ���ذٷֱȣ������ÿ�ղο�ֵ��
  private getNutrientPercentage(label: string): number {
    const ref = ReportPage.NUTRIENT_REFERENCE[label];
    if (!ref || ref === 0) return 0;
    return Math.min(100, Math.round(this.getNutrientValue(label) / ref * 100));
  }

  @Builder
  NutritionQuickSummary() {
    Scroll() {
      Row({ space: SPACING.XS }) {
        NutrientTag({ label: $r('app.string.calorie'), value: `${this.foodLabel?.nutrition?.calories ?? 0}`, unit: 'kcal', percentage: this.getNutrientPercentage('����') })
        NutrientTag({ label: $r('app.string.sodium'), value: `${this.foodLabel?.nutrition?.sodium ?? 0}`, unit: 'mg', percentage: this.getNutrientPercentage('??) })
        NutrientTag({ label: $r('app.string.sugar'), value: `${this.foodLabel?.nutrition?.sugar ?? 0}`, unit: 'g', percentage: this.getNutrientPercentage('??) })
        NutrientTag({ label: $r('app.string.fat'), value: `${this.foodLabel?.nutrition?.fat ?? 0}`, unit: 'g', percentage: this.getNutrientPercentage('֬��') })
        NutrientTag({ label: $r('app.string.protein'), value: `${this.foodLabel?.nutrition?.protein ?? 0}`, unit: 'g', percentage: this.getNutrientPercentage('����??) })
      }
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(68)
    .scrollBar(BarState.Off)
    .margin({ bottom: 4 })
  }

  // ==================== ??��ͥ����??====================

  @Builder
  FamilyMatrixSection() {
    Column() {
      // ����??      Row() {
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

      // Swiper ���򻬶�����
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

      // ָʾ��Բ??      if (this.recommendations.length > 1) {
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
      // ��ࣺ��Աͷ����
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

      // �Ҳࣺ�������
      Column() {
        // �ȼ�����
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

        // �����
        if (rec.maxAmount > 0) {
          Text($r('app.string.report_max_amount', rec.maxAmount))
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 4 })
        }

        // ԭ��ժҪ
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
    // �����볡���������Ҳ໬��+͸���ȱ仯��
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.translate({ x: 80 }).combine(TransitionEffect.opacity(0))
          .animation({ curve: curves.springMotion(0.5, 0.7) }),
        TransitionEffect.translate({ x: -30 }).combine(TransitionEffect.opacity(0))
          .animation({ curve: curves.springMotion() })
      )
    )
  }

  // ==================== ??������Ϣ??====================

  @Builder
  AuxiliarySection() {
    Column() {
      // ���Ʒ��??      if (this.alternatives.length > 0) {
        this.AlternativeSection()
      }

      // ʳƷ�Ա����
      if (this.foodLabel.barcode.length > 0) {
        Row() {
          Text($r('app.string.compare_foods'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.PRIMARY)
            .fontWeight(FONT_WEIGHT.MEDIUM)
        }
        .width('90%')
        .height(44)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.MD)
        .margin({ top: 12, bottom: 12 })
        .onClick(() => {
          safePushUrl(`pages/FoodComparePage?barcode=${this.foodLabel.barcode}`)
        })
        .accessibilityText($r('app.string.compare_foods_accessibility'))
        .accessibilityLevel('yes')
      }
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .margin({ top: 8 })
    .padding({ bottom: 16 })
  }

  @Builder
  AlternativeSection() {
    Column() {
      Row() {
        Text($r('app.string.alternative_recommendations'))
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Text(`${this.alternatives.length}${$r('app.string.alternative_count_unit').toString()}`)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      if (this.showAlternativesLocked) {
        // ����ǽ����״̬
        Row() {
          Column() {
            Text('??')
              .fontSize(32)
              .margin({ bottom: 8 })
            Text($r('app.string.alternatives_locked_title'))
              .fontSize(FONT_SIZE.BODY)
              .fontWeight(FONT_WEIGHT.MEDIUM)
              .fontColor(COLORS.TEXT_PRIMARY)
              .margin({ bottom: 4 })
            Text($r('app.string.alternatives_locked_desc'))
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .textAlign(TextAlign.Center)
          }
        }
        .width('90%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(RADIUS.LG)
        .margin({ left: 20, right: 20 })
        .onClick(() => {
          this.showPaywallDialog = true
        })
      } else {
        // ���Ʒ�б�
        Scroll() {
          Row({ space: SPACING.SM }) {
            ForEach(this.alternatives, (alt: AlternativeFood, index: number) => {
              this.AlternativeCard(alt)
            }, (alt: AlternativeFood) => alt.barcode ?? alt.name)
          }
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .height(160)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .margin({ top: 8 })
  }

  @Builder
  AlternativeCard(item: AlternativeFood) {
    Column() {
      Text(item.name)
        .fontSize(FONT_SIZE.SMALL)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .height(36)

      if (item.nutriScore !== undefined) {
        Text(`NutriScore: ${item.nutriScore}`)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
      }
    }
    .width(120)
    .height(100)
    .padding(SPACING.SM)
    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(RADIUS.MD)
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      if (item.barcode) {
        safePushUrl(`pages/ReportPage?barcode=${item.barcode}`)
      }
    })
    .accessibilityText(item.name)
    .accessibilityLevel('yes')
  }

  // ==================== �Ǽ��� ====================

  @Builder
  SkeletonScreen() {
    Column() {
      // ���������Ǽ�
      Row()
        .width('100%')
        .height(56)
        .backgroundColor(COLORS.WHITE)

      // Hero���Ǽ�
      Column() {
        Row() {
          // NutriScore�Ǽ�
          Column()
            .width(100)
            .height(100)
            .borderRadius(50)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)

          Column({ space: 8 }) {
            Row().width(60).height(24).backgroundColor(COLORS.BG_LIGHT_GRAY_F5).borderRadius(4)
            Row().width(60).height(24).backgroundColor(COLORS.BG_LIGHT_GRAY_F5).borderRadius(4)
          }
          .margin({ left: 12 })

          Column({ space: 8 }) {
            Row().width('80%').height(20).backgroundColor(COLORS.BG_LIGHT_GRAY_F5).borderRadius(4)
            Row().width('60%').height(20).backgroundColor(COLORS.BG_LIGHT_GRAY_F5).borderRadius(4)
            Row().width('70%').height(20).backgroundColor(COLORS.BG_LIGHT_GRAY_F5).borderRadius(4)
          }
          .layoutWeight(1)
          .margin({ left: 16 })
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .backgroundColor(COLORS.WHITE)
      .margin({ top: 8 })

      // ��ͥ����Ǽ�
      Column() {
        Row().width(120).height(24).backgroundColor(COLORS.BG_LIGHT_GRAY_F5).borderRadius(4)
          .margin({ left: 20, top: 20, bottom: 12 })
        Row()
          .width('90%')
          .height(170)
          .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
          .borderRadius(RADIUS.LG)
          .margin({ left: 20, right: 20 })
      }
      .width('100%')
      .backgroundColor(COLORS.WHITE)
      .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  // ==================== �������� ====================

  private getMemberEmoji(memberId: string): string {
    const member = this.familyMembers.find((m: FamilyProfile) => m.memberId === memberId)
    return member?.emoji ?? '??'
  }

  private getMemberName(memberId: string): ResourceStr {
    const member = this.familyMembers.find((m: FamilyProfile) => m.memberId === memberId)
    return member?.name ?? $r('app.string.unknown_member')
  }

  private getMemberGoal(memberId: string): string {
    const member = this.familyMembers.find((m: FamilyProfile) => m.memberId === memberId)
    return member?.healthGoal ?? ''
  }

  private getMemberLevelColor(rec: Recommendation): string {
    return getLevelColorValue(rec.levelColor)
  }

  private scoreToNutriScore(score: number): NutriScore {
    if (score <= 40) return NutriScore.A
    if (score <= 60) return NutriScore.B
    if (score <= 70) return NutriScore.C
    if (score <= 80) return NutriScore.D
    return NutriScore.E
  }

  private getPageParams(): ReportPageParams | null {
    // ��·�ɲ�����ȡҳ�����
    return null
  }

  private async handleSaveImage(): Promise<void> {
    if (this.isImageSaving) return
    this.isImageSaving = true
    try {
      const generator = new ShareCardGenerator()
      const params: ShareImageParams = {
        foodLabel: this.foodLabel,
        recommendations: this.recommendations,
        members: this.familyMembers,
        alternatives: this.alternatives,
        nutriScore: this.nutriScore,
        credibilityResult: this.credibilityResult,
        childProtection: this.childProtections
      }
      await generator.generateShareImage(params)
      promptAction.showToast({ message: $r('app.string.report_image_saved').toString() })
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'handleSaveImage failed: %{public}s', JSON.stringify(e))
      promptAction.showToast({ message: $r('app.string.report_image_save_failed').toString() })
    } finally {
      this.isImageSaving = false
    }
  }
}
