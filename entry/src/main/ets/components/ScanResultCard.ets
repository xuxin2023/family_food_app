import {
  FoodLabel, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, HILOG_DOMAIN_DEFAULT, SCORE_COLORS
} from 'hsp_core';
import { NutriScoreBadge } from 'feature_scan';

enum ScanPhase {
  IDLE = 'idle',
  RECOGNIZING = 'recognizing',
  DB_QUERYING = 'db_querying',
  API_QUERYING = 'api_querying',
  SCORING = 'scoring',
  DONE = 'done',
  TIMEOUT = 'timeout',
  ERROR = 'error'
}

@ComponentV2
struct NutrientMetricChip {
  @Param label: ResourceStr = ''
  @Param value: string = ''

  build() {
    Column() {
      Text(this.label)
        .fontSize(11)
        .fontColor(COLORS.TEXT_TERTIARY)
      Text(this.value)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLORS.TEXT_GRAY_2121)
        .margin({ top: 2 })
    }
    .padding(8)
    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(10)
  }
}

@ComponentV2
export struct ScanResultCard {
  @Param scanPhase: ScanPhase = ScanPhase.IDLE
  @Param foodLabel: FoodLabel = new FoodLabel()
  @Param scoreReady: boolean = false
  @Param nutriScore: number = 50
  @Param detailLoading: boolean = false
  @Param recognizedText: string = ''
  @Param recognitionHint: ResourceStr = ''
  @Param isOffline: boolean = false
  @Param frequentItems: FoodLabel[] = []
  @Param showEditPanel: boolean = false
  @Param onFrequentItemTap: (item: FoodLabel) => void = (_item: FoodLabel) => {}

  private isRecognizing(): boolean {
    return this.scanPhase === ScanPhase.RECOGNIZING ||
      this.scanPhase === ScanPhase.DB_QUERYING ||
      this.scanPhase === ScanPhase.API_QUERYING ||
      this.scanPhase === ScanPhase.SCORING;
  }

  private getGradeScoreColor(score: number): string {
    if (score >= 80) return SCORE_COLORS.GRADE_A;
    if (score >= 60) return SCORE_COLORS.GRADE_B;
    if (score >= 40) return SCORE_COLORS.GRADE_C;
    if (score >= 20) return SCORE_COLORS.GRADE_D;
    return SCORE_COLORS.GRADE_E;
  }

  private getGradeLabel(score: number): string {
    if (score >= 80) return 'A 优秀';
    if (score >= 60) return 'B 良好';
    if (score >= 40) return 'C 一般';
    if (score >= 20) return 'D 较差';
    return 'E 不推荐';
  }

  build() {
    Column() {
      if (this.isRecognizing()) {
        if (this.scanPhase === ScanPhase.RECOGNIZING) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(44)
              .color(COLORS.ACCENT_BLUE)
            Text($r('app.string.scanning_barcode'))
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.MD })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(140)
          .transition(TransitionEffect.opacity(1))
        } else if (this.scanPhase === ScanPhase.DB_QUERYING) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(COLORS.ACCENT_GREEN)
            Text($r('app.string.scan_querying_local'))
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.MD })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(100)
          .transition(TransitionEffect.opacity(1))
        } else if (this.scanPhase === ScanPhase.API_QUERYING) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(COLORS.ACCENT_PURPLE)
            Text($r('app.string.scan_querying_remote'))
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.MD })
            if (this.isOffline) {
              Text($r('app.string.scan_offline_local_only'))
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.WARNING)
                .margin({ top: SPACING.XS })
            }
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(120)
          .transition(TransitionEffect.opacity(1))
        } else if (this.scanPhase === ScanPhase.SCORING) {
          Column() {
            LoadingProgress()
              .width(32)
              .height(32)
              .color(COLORS.ACCENT_GREEN)
            Text($r('app.string.scan_evaluating_score'))
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.SM, bottom: SPACING.MD })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(80)
          .transition(TransitionEffect.opacity(1))
        }
      } else if (this.foodLabel.foodId.length === 0) {
        if (this.frequentItems.length > 0) {
          Text() { Span('🔥 '); Span($r('app.string.scan_quick_select_history')) }
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ bottom: SPACING.SM })
          Scroll() {
            Row() {
              ForEach(this.frequentItems, (item: FoodLabel) => {
                Column() {
                  Text(item.foodName)
                    .fontSize(FONT_SIZE.TINY)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .lineHeight(14)
                    .textAlign(TextAlign.Center)
                }
                .width(72)
                .height(60)
                .padding(SPACING.XS)
                .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
                .borderRadius(RADIUS.SM)
                .margin({ right: SPACING.SM })
                .onClick(() => { this.onFrequentItemTap(item) })
                .accessibilityText('选择' + item.foodName)
                .accessibilityLevel('yes')
              }, (item: FoodLabel) => item.foodId)
            }
          }
          .scrollBar(BarState.Off)
          .margin({ bottom: SPACING.MD })
        }

        if (this.scanPhase === ScanPhase.TIMEOUT) {
          Column() {
            Text() { Span('⏰ '); Span($r('app.string.scan_timeout')) }
              .fontSize(15)
              .fontColor(COLORS.LEVEL_ORANGE)
              .fontWeight(FONT_WEIGHT.BOLD)
            Text($r('app.string.scan_timeout_hint'))
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 4 })
          }
          .margin({ bottom: SPACING.MD })
        }

        Text($r('app.string.scan_draft_hint'))
          .fontSize(15)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
        Text() { Span($r('app.string.scan_mode_barcode')); Span(' '); Span($r('app.string.scan_today_remaining')); Span('...') }
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
          .margin({ top: SPACING.SM })
      } else {
        if (this.scoreReady) {
          Row() {
            Column() {
              Text(Math.round(this.nutriScore).toString())
                .fontSize(42)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getGradeScoreColor(this.nutriScore))
              Text(this.getGradeLabel(this.nutriScore))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.getGradeScoreColor(this.nutriScore))
                .opacity(0.85)
                .margin({ top: 2 })
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .margin({ bottom: SPACING.SM })

          NutriScoreBadge({
            score: this.nutriScore,
            diameter: 100,
            animating: true
          })
          .margin({ bottom: SPACING.MD })
        } else if (this.detailLoading) {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(COLORS.ACCENT_GREEN)
          Text($r('app.string.scan_evaluating_score'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: SPACING.SM, bottom: SPACING.MD })
        }

        Text(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : $r('app.string.scan_pending_food_name'))
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .margin({ bottom: SPACING.SM })

        if (typeof this.recognitionHint === 'string' && this.recognitionHint.length > 0) {
          Text(this.recognitionHint)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.PRIMARY)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 6 })
        }

        if (this.recognizedText.length > 0) {
          Text(this.recognizedText)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .textAlign(TextAlign.Center)
            .margin({ bottom: SPACING.SM })
        }

        Row() {
          NutrientMetricChip({ label: $r('app.string.sodium') as ResourceStr, value: this.foodLabel.nutrition.sodium.toString() + ' mg' })
          NutrientMetricChip({ label: $r('app.string.sugar') as ResourceStr, value: this.foodLabel.nutrition.sugar.toString() + ' g' })
          NutrientMetricChip({ label: $r('app.string.calorie') as ResourceStr, value: this.foodLabel.nutrition.calories.toString() + ' kcal' })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ bottom: SPACING.SM })

        if (this.foodLabel.barcode.length > 0) {
          Text() { Span($r('app.string.scan_barcode_label')); Span('：' + this.foodLabel.barcode) }
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ bottom: 6 })
        }

        Text(this.showEditPanel ? $r('app.string.scan_check_and_save') : $r('app.string.scan_edit_to_complete'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
      }
    }
    .width('92%')
    .padding(20)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .alignItems(HorizontalAlign.Center)
    .border(this.scoreReady ? { width: { left: 4, top: 0, right: 0, bottom: 0 }, color: this.getGradeScoreColor(this.nutriScore) } : { width: 0 })
  }
}
