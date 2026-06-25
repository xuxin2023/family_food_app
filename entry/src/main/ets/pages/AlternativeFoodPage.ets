import {
  ToastHelper, safeBack, safePushUrl, FoodLabel, NutritionPer100g, FamilyProfile, AlternativeFood, COLORS, SHADOWS, FONT_SIZE, RADIUS, SPACING, ROUTE_ALTERNATIVE_FOOD_PAGE, IOfflineFoodProvider, PageResourceTracker, createPageTracker, HILOG_DOMAIN_DEFAULT, ThemeReactive, themeReactive
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { AppState } from '../AppState';
import { AlternativeRecommender, AlternativeCandidate, alternativeFoodRecommender } from 'feature_scan';
import { OfflineFoodProvider } from 'hsp_core';
import { EmptyState } from '../components/EmptyState';
import { OnlineAlternativeSearchService } from 'hsp_service';
import { AlternativeComparePanel } from 'feature_report';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LoadingSkeleton } from '../components/SkeletonScreen';

const TAG = 'AlternativeFoodPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
export struct AlternativeFoodPage {
  @Local foodLabel: FoodLabel = new FoodLabel()
  @Local candidates: AlternativeCandidate[] = []
  @Local legacyAlternatives: AlternativeFood[] = []
  @Local familyMembers: FamilyProfile[] = []
  @Local isLoading: boolean = true
  @Local recommendReady: boolean = false
  @Local onlineAlternatives: AlternativeFood[] = []
  @Local currentBreakpoint: string = 'md'

  private appState: AppState = AppState.getInstance()
  private componentActive: boolean = true
  private tracker: PageResourceTracker = createPageTracker('AlternativeFoodPage')

  private themeRef: ThemeReactive = themeReactive

  aboutToAppear(): void {
    this.tracker.onAppear()
    const cachedFoodLabel = this.appState.reportCache.consumeFoodLabel()
    if (cachedFoodLabel !== null) {
      this.foodLabel = cachedFoodLabel as FoodLabel
    }
    this.familyMembers = this.appState.getAllMembersSync()
    this.loadAlternatives()
  }

  private loadAlternatives(): void {
    this.isLoading = true
    this.recommendReady = false
    const recommender: AlternativeRecommender = new AlternativeRecommender(new OfflineFoodProvider())
    this.candidates = recommender.recommend(this.foodLabel)
    alternativeFoodRecommender.recommendAlternatives(
      this.foodLabel, this.familyMembers, 5
    ).then((alts: AlternativeFood[]) => {
      this.legacyAlternatives = alts
      this.isLoading = false
      this.recommendReady = true
      this.loadOnlineAlternatives()
    }).catch(() => {
      this.isLoading = false
      this.recommendReady = true
      this.loadOnlineAlternatives()
    })
  }

  private async loadOnlineAlternatives(): Promise<void> {
    try {
      const onlineService = OnlineAlternativeSearchService.getInstance()
      const results = await onlineService.searchAlternatives(this.foodLabel, undefined, 5)
      this.onlineAlternatives = onlineService.toAlternativeFoods(results)
    } catch (_) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'loadOnlineAlternatives failed');
      this.onlineAlternatives = []
    }
  }

  build() {
    Scroll() {
      Column() {
        GradientHeader({ title: $r('app.string.alternative_food_title') })

        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { value: ['320vp', '600vp'], reference: BreakpointsReference.WindowSize }
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 10 }, offset: { sm: 0, md: 0, lg: 1 } }) {
            Column() {
              this.CurrentFoodCard()

              if (this.isLoading) {
                Column() {
                  LoadingSkeleton({ variant: 'list' })
                }
                .width('92%')
                .height(200)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              } else if (this.recommendReady) {
                if (this.candidates.length === 0 && this.legacyAlternatives.length === 0) {
                  EmptyState({
                    icon: '🔍',
                    title: $r('app.string.alt_food_no_alternative'),
                    subtitle: $r('app.string.alt_food_no_alternative_hint'),
                    topPadding: 40
                  })
                } else {
                  this.AlternativeListSection()
                  if (this.candidates.length > 0) {
                    AlternativeComparePanel({
                      originalFood: this.foodLabel,
                      alternativeFood: this.buildAltLabel()
                    })
                  }
                  this.LegacyAlternativeSection()
                }
              }

              Text($r('app.string.alt_food_disclaimer'))
                .fontSize(12)
                .fontColor(COLORS.TEXT_TERTIARY)
                .width('92%')
                .textAlign(TextAlign.Center)
                .margin({ top: 16, bottom: 24 })
                .padding(12)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .onBreakpointChange((bp: string) => { this.currentBreakpoint = bp })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  CurrentFoodCard() {
    Column() {
      Text(this.foodLabel.foodName || $r('app.string.alt_food_unknown'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 8 })

      Row() {
        this.NutritionBadge($r('app.string.alt_food_calories'), this.foodLabel.nutrition.calories, 'kcal')
        this.NutritionBadge($r('app.string.alt_food_sodium'), this.foodLabel.nutrition.sodium, 'mg')
        this.NutritionBadge($r('app.string.alt_food_sugar'), this.foodLabel.nutrition.sugar, 'g')
        this.NutritionBadge($r('app.string.alt_food_fat'), this.foodLabel.nutrition.fat, 'g')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      if (this.foodLabel.manufacturer.length > 0) {
        Text(this.foodLabel.manufacturer)
          .fontSize(12)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ top: 8 })
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .shadow(SHADOWS.MD)
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 14 })
  }

  @Builder
  NutritionBadge(label: ResourceStr, value: number, unit: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor(COLORS.TEXT_TERTIARY)
      Text(value.toFixed(0) + unit)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  AlternativeListSection() {
    if (this.candidates.length > 0) {
      Column() {
        Text($r('app.string.alt_food_healthier_alternative'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 12 })

        if (this.currentBreakpoint === 'lg') {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.candidates, (item: AlternativeCandidate, index: number) => {
              Column() {
                this.AlternativeItemCardContent(item)
              }
              .width('48%')
              .margin({ right: index % 2 === 0 ? '2%' : 0, bottom: 8 })
            }, (item: AlternativeCandidate, index: number) => item.barcode + index)
          }
          .width('100%')
        } else {
          ForEach(this.candidates, (item: AlternativeCandidate, index: number) => {
            this.AlternativeItemCard(item, index)
          }, (item: AlternativeCandidate, index: number) => item.barcode + index)
        }
      }
      .width('92%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
      .shadow(SHADOWS.MD)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 14 })
    }
  }

  @Builder
  AlternativeItemCardContent(item: AlternativeCandidate) {
    Row() {
      Column() {
        Text(item.foodName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
        if (item.brand.length > 0) {
          Text(item.brand)
            .fontSize(12)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 2 })
        }
        Row() {
          ForEach(item.improvements, (imp: string) => {
            Text(imp)
              .fontSize(11)
              .fontColor(COLORS.WHITE)
              .backgroundColor(COLORS.SUCCESS)
              .borderRadius(10)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ right: 4, top: 4 })
          }, (imp: string, idx: number) => imp + idx)
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (item.nutriGrade.length > 0) {
        Text(item.nutriGrade)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AlternativeFoodPage.gradeColor(item.nutriGrade))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AlternativeFoodPage.gradeBgColor(item.nutriGrade))
      }

      Text('更多')
        .fontSize(20)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(8)
  }

  @Builder
  AlternativeItemCard(item: AlternativeCandidate, index: number) {
    Row() {
      Column() {
        Text(item.foodName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
        if (item.brand.length > 0) {
          Text(item.brand)
            .fontSize(12)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 2 })
        }
        Row() {
          ForEach(item.improvements, (imp: string) => {
            Text(imp)
              .fontSize(11)
              .fontColor(COLORS.WHITE)
              .backgroundColor(COLORS.SUCCESS)
              .borderRadius(10)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ right: 4, top: 4 })
          }, (imp: string, idx: number) => imp + idx)
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (item.nutriGrade.length > 0) {
        Text(item.nutriGrade)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AlternativeFoodPage.gradeColor(item.nutriGrade))
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AlternativeFoodPage.gradeBgColor(item.nutriGrade))
      }

      Text('→')
        .fontSize(20)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(8)
    .onClick(() => {
      this.onAlternativeClick(item)
    })
    .accessibilityText(item.foodName)
    .accessibilityLevel('yes')
    .gesture(LongPressGesture().onAction(() => {
      ToastHelper.show(this.getUIContext(), item.foodName + ': ' + item.improvements.join(', '))
    }))
  }

  @Builder
  LegacyAlternativeSection() {
    if (this.legacyAlternatives.length > 0) {
      Column() {
        Text($r('app.string.alt_food_general_advice'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 12 })

        ForEach(this.legacyAlternatives, (alt: AlternativeFood, index: number) => {
          Row() {
            Column() {
              Text(alt.productName)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(COLORS.TEXT_PRIMARY)
              Text(alt.brand)
                .fontSize(12)
                .fontColor(COLORS.TEXT_TERTIARY)
                .margin({ top: 2 })
              Text(alt.reason)
                .fontSize(12)
                .fontColor(COLORS.TEXT_SECONDARY)
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text(`${alt.healthScore}分`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLORS.SUCCESS)
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
        }, (alt: AlternativeFood, index: number) => alt.productName + index)
      }
      .width('92%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
      .shadow(SHADOWS.MD)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 14 })
    }
  }

  private buildAltLabel(): FoodLabel {
    const altLabel: FoodLabel = new FoodLabel()
    altLabel.foodName = this.candidates[0].foodName;
    altLabel.manufacturer = this.candidates[0].brand;
    altLabel.barcode = this.candidates[0].barcode;
    altLabel.nutrition = this.candidates[0].nutrition;
    return altLabel;
  }

  private onAlternativeClick(item: AlternativeCandidate): void {
    if (item.barcode && item.barcode.length > 0) {
      const params: Record<string, string> = { 'barcode': item.barcode };
      safePushUrl('pages/ReportPage', params)
    } else {
      ToastHelper.show(this.getUIContext(), '已选择: ' + item.foodName)
    }
  }

  private static gradeColor(grade: string): string {
    if (grade === 'A') return '#4CAF50';
    if (grade === 'B') return '#8BC34A';
    if (grade === 'C') return '#FFC107';
    if (grade === 'D') return '#FF9800';
    return '#F44336';
  }

  private static gradeBgColor(grade: string): string {
    if (grade === 'A') return '#E8F5E9';
    if (grade === 'B') return '#F1F8E9';
    if (grade === 'C') return '#FFF8E1';
    if (grade === 'D') return '#FFF3E0';
    return '#FFEBEE';
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
    this.componentActive = false;
  }
}
