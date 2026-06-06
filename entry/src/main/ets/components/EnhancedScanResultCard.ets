import {
  FoodLabel, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { NutriScoreBadge } from 'feature_scan';
import { curves } from '@kit.ArkUI';

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
  @Param color: string = COLORS.PRIMARY
  @Param animDelay: number = 0

  build() {
    Column() {
      Text(this.label)
        .fontSize(11)
        .fontColor(COLORS.TEXT_TERTIARY)
      Text(this.value)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.color)
        .margin({ top: 4 })
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(12)
    .shadow({
      radius: 2,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 1
    })
    .transition(TransitionEffect.OPACITY.animation({ duration: 300, delay: this.animDelay }))
  }
}

@ComponentV2
struct LoadingDots {
  @Local dotIndex: number = 0
  private timer: number = -1

  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.dotIndex = (this.dotIndex + 1) % 4
    }, 300)
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }
  }

  build() {
    Row() {
      ForEach([0, 1, 2], (i: number) => {
        Circle()
          .width(8)
          .height(8)
          .fill(this.dotIndex === i ? COLORS.PRIMARY : COLORS.TEXT_TERTIARY)
          .margin({ left: 4, right: 4 })
          .animation({ duration: 200, curve: curves.easeOut() })
      }, (i: number) => i.toString())
    }
    .justifyContent(FlexAlign.Center)
  }
}

@ComponentV2
struct SkeletonLoader {
  @Param width: number | string = '100%'
  @Param height: number = 20
  @Param borderRadius: number = 8

  build() {
    Row()
      .width(this.width)
      .height(this.height)
      .backgroundColor('#E0E0E0')
      .borderRadius(this.borderRadius)
      .linearGradient({
        angle: 90,
        colors: [['#E0E0E0', 0], ['#F0F0F0', 0.5], ['#E0E0E0', 1]]
      })
      .animation({
        duration: 1500,
        curve: curves.linear(),
        iterations: -1
      })
  }
}

@ComponentV2
struct ProgressStepIndicator {
  @Param steps: string[] = []
  @Param currentStep: number = 0

  build() {
    Row() {
      ForEach(this.steps, (step: string, index: number) => {
        Row() {
          if (index > 0) {
            Row()
              .width(24)
              .height(2)
              .backgroundColor(index <= this.currentStep ? COLORS.ACCENT_GREEN : COLORS.BG_LIGHT_GRAY_F5)
              .margin({ left: 4, right: 4 })
          }
          
          Column() {
            Circle()
              .width(12)
              .height(12)
              .fill(index < this.currentStep ? COLORS.ACCENT_GREEN :
                    index === this.currentStep ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
              .stroke(index === this.currentStep ? COLORS.PRIMARY : Color.Transparent)
              .strokeWidth(2)
            
            if (index === this.currentStep) {
              Text(step)
                .fontSize(10)
                .fontColor(COLORS.TEXT_TERTIARY)
                .margin({ top: 4 })
            }
          }
          .alignItems(HorizontalAlign.Center)
        }
        .alignItems(VerticalAlign.Center)
      }, (step: string) => step)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }
}

@ComponentV2
export struct EnhancedScanResultCard {
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
  @Local showScoreAnimation: boolean = false

  private isRecognizing(): boolean {
    return this.scanPhase === ScanPhase.RECOGNIZING ||
      this.scanPhase === ScanPhase.DB_QUERYING ||
      this.scanPhase === ScanPhase.API_QUERYING ||
      this.scanPhase === ScanPhase.SCORING;
  }

  private getNutrientColor(value: number, threshold: number): string {
    if (value <= threshold * 0.5) {
      return COLORS.ACCENT_GREEN
    } else if (value <= threshold) {
      return COLORS.WARNING
    } else {
      return COLORS.LEVEL_RED
    }
  }

  aboutToAppear(): void {
    if (this.scoreReady) {
      setTimeout(() => {
        this.showScoreAnimation = true
      }, 100)
    }
  }

  build() {
    Column() {
      if (this.isRecognizing()) {
        Column() {
          ProgressStepIndicator({
            steps: ['识别', '查询', '评分'],
            currentStep: this.scanPhase === ScanPhase.RECOGNIZING ? 0 :
                        this.scanPhase === ScanPhase.DB_QUERYING ? 1 :
                        this.scanPhase === ScanPhase.API_QUERYING ? 1 :
                        this.scanPhase === ScanPhase.SCORING ? 2 : 0
          })
          
          Column() {
            LoadingDots()
            
            Text(
              this.scanPhase === ScanPhase.RECOGNIZING ? '正在识别条码...' :
              this.scanPhase === ScanPhase.DB_QUERYING ? '查询本地数据库...' :
              this.scanPhase === ScanPhase.API_QUERYING ? '查询云端数据...' :
              '计算营养评分...'
            )
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.MD })
            
            if (this.isOffline && this.scanPhase === ScanPhase.API_QUERYING) {
              Row() {
                Text('📡')
                  .fontSize(12)
                Text('离线模式：仅使用本地数据')
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.WARNING)
              }
              .margin({ top: SPACING.XS })
            }
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding(SPACING.LG)
        .transition(TransitionEffect.opacity(1).animation({ duration: 300 }))
        
      } else if (this.foodLabel.foodId.length === 0) {
        if (this.frequentItems.length > 0) {
          Row() {
            Text('🔥')
              .fontSize(16)
            Text('快速选择历史商品')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_SECONDARY)
              .margin({ left: 4 })
          }
          .width('100%')
          .padding({ left: SPACING.LG })
          .margin({ bottom: SPACING.SM })
          
          Scroll() {
            Row() {
              ForEach(this.frequentItems, (item: FoodLabel, index: number) => {
                Column() {
                  Text(item.foodName)
                    .fontSize(FONT_SIZE.TINY)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .lineHeight(14)
                    .textAlign(TextAlign.Center)
                }
                .width(76)
                .height(64)
                .padding(SPACING.XS)
                .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
                .borderRadius(RADIUS.SM)
                .margin({ right: SPACING.SM })
                .onClick(() => { this.onFrequentItemTap(item) })
                .accessibilityText(`选择${item.foodName}`)
                .accessibilityLevel('yes')
                .transition(TransitionEffect.OPACITY.animation({ duration: 200, delay: index * 50 }))
              }, (item: FoodLabel) => item.foodId)
            }
          }
          .scrollBar(BarState.Off)
          .margin({ bottom: SPACING.MD })
        }

        if (this.scanPhase === ScanPhase.TIMEOUT) {
          Column() {
            Row() {
              Text('⏰')
                .fontSize(20)
              Text('扫码超时')
                .fontSize(16)
                .fontColor(COLORS.LEVEL_ORANGE)
                .fontWeight(FONT_WEIGHT.BOLD)
                .margin({ left: 8 })
            }
            
            Text('建议切换到拍照模式或手动输入')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 8 })
          }
          .padding(SPACING.MD)
          .backgroundColor('#FFF3E0')
          .borderRadius(RADIUS.MD)
          .margin({ bottom: SPACING.MD })
        }

        Column() {
          Text('准备扫描')
            .fontSize(18)
            .fontColor(COLORS.TEXT_TERTIARY)
            .textAlign(TextAlign.Center)
          
          Text('支持条码扫描、拍照识别、手动输入')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .textAlign(TextAlign.Center)
            .margin({ top: SPACING.SM })
        }
        .padding(SPACING.LG)
        
      } else {
        Column() {
          if (this.scoreReady) {
            Stack() {
              NutriScoreBadge({
                score: this.nutriScore,
                diameter: 140,
                animating: this.showScoreAnimation
              })
              
              if (this.showScoreAnimation) {
                Column() {
                  Text(this.nutriScore.toString())
                    .fontSize(32)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(COLORS.TEXT_PRIMARY)
                  
                  Text('分')
                    .fontSize(14)
                    .fontColor(COLORS.TEXT_SECONDARY)
                }
              }
            }
            .width(140)
            .height(140)
            .margin({ bottom: SPACING.MD })
          } else if (this.detailLoading) {
            Column() {
              LoadingProgress()
                .width(40)
                .height(40)
                .color(COLORS.ACCENT_GREEN)
              
              Row() {
                LoadingDots()
              }
              .margin({ top: SPACING.SM })
            }
            .margin({ bottom: SPACING.MD })
          }

          Text(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : '待识别食品')
            .fontSize(FONT_SIZE.TITLE)
            .fontWeight(FONT_WEIGHT.BOLD)
            .margin({ bottom: SPACING.SM })
            .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))

          if (typeof this.recognitionHint === 'string' && this.recognitionHint.length > 0) {
            Text(this.recognitionHint)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.PRIMARY)
              .textAlign(TextAlign.Center)
              .margin({ bottom: 8 })
          }

          if (this.recognizedText.length > 0) {
            Text(this.recognizedText)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .textAlign(TextAlign.Center)
              .margin({ bottom: SPACING.SM })
          }

          Column() {
            Row() {
              NutrientMetricChip({
                label: '钠',
                value: `${this.foodLabel.nutrition.sodium} mg`,
                color: this.getNutrientColor(this.foodLabel.nutrition.sodium, 600),
                animDelay: 0
              })
              
              NutrientMetricChip({
                label: '糖',
                value: `${this.foodLabel.nutrition.sugar} g`,
                color: this.getNutrientColor(this.foodLabel.nutrition.sugar, 25),
                animDelay: 100
              })
              
              NutrientMetricChip({
                label: '热量',
                value: `${this.foodLabel.nutrition.calories} kcal`,
                color: this.getNutrientColor(this.foodLabel.nutrition.calories, 400),
                animDelay: 200
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
            
            Row() {
              NutrientMetricChip({
                label: '脂肪',
                value: `${this.foodLabel.nutrition.fat} g`,
                color: this.getNutrientColor(this.foodLabel.nutrition.fat, 20),
                animDelay: 300
              })
              
              NutrientMetricChip({
                label: '蛋白质',
                value: `${this.foodLabel.nutrition.protein} g`,
                color: COLORS.ACCENT_GREEN,
                animDelay: 400
              })
              
              NutrientMetricChip({
                label: '碳水',
                value: `${this.foodLabel.nutrition.carbohydrate} g`,
                color: COLORS.PRIMARY,
                animDelay: 500
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
            .margin({ top: SPACING.SM })
          }
          .margin({ bottom: SPACING.MD })

          if (this.foodLabel.barcode.length > 0) {
            Row() {
              Text('条码：')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
              
              Text(this.foodLabel.barcode)
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
            }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(RADIUS.SM)
            .margin({ bottom: 8 })
          }

          Text(this.showEditPanel ? '请检查并保存' : '点击编辑完善信息')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .textAlign(TextAlign.Center)
        }
        .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
      }
    }
    .width('92%')
    .padding(20)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .alignItems(HorizontalAlign.Center)
  }
}