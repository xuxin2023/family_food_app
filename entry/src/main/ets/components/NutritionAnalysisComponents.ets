import { COLORS, RADIUS, SPACING, FONT_SIZE } from 'hsp_core';
import { curves } from '@kit.ArkUI';

export interface NutritionTrendPoint {
  date: string
  value: number
  label?: string
}

export interface NutritionTrendData {
  nutrient: string
  unit: string
  data: NutritionTrendPoint[]
  targetValue?: number
  color?: string
}

@ComponentV2
struct TrendChartPoint {
  @Param x: number = 0
  @Param y: number = 0
  @Param value: number = 0
  @Param color: string = COLORS.PRIMARY
  @Param isHighlighted: boolean = false
  @Param showLabel: boolean = false

  build() {
    Stack() {
      if (this.isHighlighted) {
        Column() {
          Text(this.value.toString())
            .fontSize(11)
            .fontColor(this.color)
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .backgroundColor(Color.White)
        .borderRadius(4)
        .shadow({
          radius: 4,
          color: '#1A000000',
          offsetX: 0,
          offsetY: 2
        })
        .position({ x: this.x - 15, y: this.y - 30 })
      }

      Circle()
        .width(this.isHighlighted ? 12 : 8)
        .height(this.isHighlighted ? 12 : 8)
        .fill(this.color)
        .stroke(Color.White)
        .strokeWidth(2)
        .position({ x: this.x - (this.isHighlighted ? 6 : 4), y: this.y - (this.isHighlighted ? 6 : 4) })
    }
  }
}

@ComponentV2
export struct NutritionTrendChart {
  @Param trendData: NutritionTrendData = {
    nutrient: '',
    unit: '',
    data: [],
    color: COLORS.PRIMARY
  }
  @Param width: number = 300
  @Param height: number = 200
  @Param showTargetLine: boolean = true
  @Local selectedPointIndex: number = -1
  @Local animationProgress: number = 0
  private padding: number = 40
  private timer: number = -1

  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.animationProgress = Math.min(this.animationProgress + 0.05, 1)
      if (this.animationProgress >= 1) {
        clearInterval(this.timer)
        this.timer = -1
      }
    }, 33)
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }
  }

  private getMinValue(): number {
    if (this.trendData.data.length === 0) return 0
    const values = this.trendData.data.map(d => d.value)
    return Math.min(...values) * 0.9
  }

  private getMaxValue(): number {
    if (this.trendData.data.length === 0) return 100
    const values = this.trendData.data.map(d => d.value)
    return Math.max(...values) * 1.1
  }

  private getX(index: number): number {
    const chartWidth = this.width - this.padding * 2
    const step = chartWidth / Math.max(this.trendData.data.length - 1, 1)
    return this.padding + step * index
  }

  private getY(value: number): number {
    const chartHeight = this.height - this.padding * 2
    const min = this.getMinValue()
    const max = this.getMaxValue()
    const ratio = (value - min) / (max - min)
    return this.padding + chartHeight * (1 - ratio)
  }

  private buildPath(): string {
    if (this.trendData.data.length === 0) {
      return ''
    }

    const points = this.trendData.data.slice(0, Math.ceil(this.trendData.data.length * this.animationProgress))
    if (points.length === 0) {
      return ''
    }

    let path = `M ${this.getX(0)} ${this.getY(points[0].value)}`
    
    for (let i = 1; i < points.length; i++) {
      const x = this.getX(i)
      const y = this.getY(points[i].value)
      path += ` L ${x} ${y}`
    }

    return path
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text(this.trendData.nutrient)
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          Text(`(${this.trendData.unit})`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ left: 4 })
        }
        .width('100%')
        .padding({ left: this.padding, right: this.padding })
        .margin({ bottom: 8 })
      }
      .width('100%')

      Stack() {
        Column() {
          Row() {
            Text(Math.round(this.getMaxValue()).toString())
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
          .width(this.padding)
          .justifyContent(FlexAlign.End)

          Blank()

          Row() {
            Text(Math.round(this.getMinValue()).toString())
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
          .width(this.padding)
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .height('100%')

        Column() {
          Row()
            .width('100%')
            .height(1)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)

          Blank()

          Row()
            .width('100%')
            .height(1)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        }
        .width('100%')
        .height('100%')
        .padding({ top: this.padding, bottom: this.padding })

        if (this.showTargetLine && this.trendData.targetValue !== undefined) {
          Row()
            .width(this.width - this.padding * 2)
            .height(2)
            .backgroundColor(COLORS.WARNING)
            .position({ x: this.padding, y: this.getY(this.trendData.targetValue) })
        }

        Path()
          .width(this.width)
          .height(this.height)
          .commands(this.buildPath())
          .stroke(this.trendData.color || COLORS.PRIMARY)
          .strokeWidth(3)
          .fill(Color.Transparent)

        ForEach(this.trendData.data.slice(0, Math.ceil(this.trendData.data.length * this.animationProgress)), 
          (point: NutritionTrendPoint, index: number) => {
            TrendChartPoint({
              x: this.getX(index),
              y: this.getY(point.value),
              value: point.value,
              color: this.trendData.color || COLORS.PRIMARY,
              isHighlighted: index === this.selectedPointIndex
            })
          }, (point: NutritionTrendPoint, index: number) => index.toString())

        Column() {
          Blank()
          
          Row() {
            ForEach(this.trendData.data, (point: NutritionTrendPoint, index: number) => {
              Text(point.date)
                .fontSize(9)
                .fontColor(COLORS.TEXT_TERTIARY)
                .width((this.width - this.padding * 2) / this.trendData.data.length)
                .textAlign(TextAlign.Center)
            }, (point: NutritionTrendPoint, index: number) => index.toString())
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 10 })
      }
      .width(this.width)
      .height(this.height)
      .gesture(
        PanGesture()
          .onActionUpdate((event: GestureEvent) => {
            const x = event.localX
            const chartWidth = this.width - this.padding * 2
            const step = chartWidth / Math.max(this.trendData.data.length - 1, 1)
            const index = Math.round((x - this.padding) / step)
            if (index >= 0 && index < this.trendData.data.length) {
              this.selectedPointIndex = index
            }
          })
      )
    }
    .width(this.width)
    .height(this.height)
  }
}

@ComponentV2
export struct NutritionComparisonBar {
  @Param label: string = ''
  @Param currentValue: number = 0
  @Param previousValue: number = 0
  @Param unit: string = ''
  @Param maxValue: number = 100
  @Param color: string = COLORS.PRIMARY

  private getChangePercent(): number {
    if (this.previousValue === 0) {
      return 0
    }
    return ((this.currentValue - this.previousValue) / this.previousValue) * 100
  }

  private getChangeColor(): string {
    const change = this.getChangePercent()
    if (change > 10) {
      return COLORS.LEVEL_RED
    } else if (change < -10) {
      return COLORS.ACCENT_GREEN
    } else {
      return COLORS.WARNING
    }
  }

  private getChangeIcon(): string {
    const change = this.getChangePercent()
    if (change > 0) {
      return '↑'
    } else if (change < 0) {
      return '↓'
    } else {
      return '→'
    }
  }

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(14)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        Row() {
          Text(this.getChangeIcon())
            .fontSize(14)
            .fontColor(this.getChangeColor())

          Text(`${Math.abs(this.getChangePercent()).toFixed(1)}%`)
            .fontSize(13)
            .fontColor(this.getChangeColor())
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Column() {
          Row() {
            Row()
              .width(`${(this.previousValue / this.maxValue) * 100}%`)
              .height(8)
              .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
              .borderRadius(4)
          }
          .width('100%')
          .height(8)
          .backgroundColor('#E8E8E8')
          .borderRadius(4)

          Text(`之前: ${this.previousValue}${this.unit}`)
            .fontSize(11)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Column() {
          Row() {
            Row()
              .width(`${(this.currentValue / this.maxValue) * 100}%`)
              .height(8)
              .backgroundColor(this.color)
              .borderRadius(4)
          }
          .width('100%')
          .height(8)
          .backgroundColor('#E8E8E8')
          .borderRadius(4)

          Text(`现在: ${this.currentValue}${this.unit}`)
            .fontSize(11)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
  }
}

@ComponentV2
export struct NutritionAnalysisDashboard {
  @Param trendDatas: NutritionTrendData[] = []
  @Param comparisonData: Array<{
    label: string
    currentValue: number
    previousValue: number
    unit: string
    maxValue: number
  }> = []
  @Local selectedChartIndex: number = 0

  build() {
    Scroll() {
      Column() {
        Text('营养趋势分析')
          .fontSize(18)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: SPACING.LG })

        if (this.trendDatas.length > 0) {
          Scroll() {
            Row() {
              ForEach(this.trendDatas, (data: NutritionTrendData, index: number) => {
                Column() {
                  Text(data.nutrient)
                    .fontSize(13)
                    .fontColor(index === this.selectedChartIndex ? COLORS.PRIMARY : COLORS.TEXT_SECONDARY)
                    .fontWeight(index === this.selectedChartIndex ? FontWeight.Medium : FontWeight.Normal)
                }
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor(index === this.selectedChartIndex ? '#E3F2FD' : COLORS.BG_LIGHT_GRAY_F5)
                .borderRadius(16)
                .margin({ right: 8 })
                .onClick(() => {
                  this.selectedChartIndex = index
                })
              }, (data: NutritionTrendData) => data.nutrient)
            }
          }
          .scrollBar(BarState.Off)
          .width('100%')
          .margin({ bottom: SPACING.MD })

          NutritionTrendChart({
            trendData: this.trendDatas[this.selectedChartIndex],
            width: 320,
            height: 200,
            showTargetLine: true
          })
          .margin({ bottom: SPACING.LG })
        }

        if (this.comparisonData.length > 0) {
          Column() {
            Text('历史对比')
              .fontSize(16)
              .fontColor(COLORS.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: SPACING.MD })

            ForEach(this.comparisonData, (item: {
              label: string
              currentValue: number
              previousValue: number
              unit: string
              maxValue: number
            }) => {
              NutritionComparisonBar({
                label: item.label,
                currentValue: item.currentValue,
                previousValue: item.previousValue,
                unit: item.unit,
                maxValue: item.maxValue,
                color: COLORS.PRIMARY
              })
              .margin({ bottom: SPACING.SM })
            }, (item: {
              label: string
              currentValue: number
              previousValue: number
              unit: string
              maxValue: number
            }) => item.label)
          }
          .width('100%')
          .padding(SPACING.MD)
          .backgroundColor(COLORS.BG_CARD)
          .borderRadius(RADIUS.LG)
        }
      }
      .width('100%')
      .padding(SPACING.LG)
    }
    .scrollBar(BarState.Auto)
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }
}

const COLORS = {
  PRIMARY: '#1976D2',
  ACCENT_GREEN: '#4CAF50',
  WARNING: '#FF9800',
  LEVEL_RED: '#F44336',
  TEXT_PRIMARY: '#212121',
  TEXT_SECONDARY: '#757575',
  TEXT_TERTIARY: '#9E9E9E',
  BG_PAGE: '#FAFAFA',
  BG_CARD: '#FFFFFF',
  BG_LIGHT_GRAY_F5: '#F5F5F5',
  RADIUS: { SM: 4, MD: 8, LG: 12 },
  SPACING: { XS: 4, SM: 8, MD: 12, LG: 16 }
}