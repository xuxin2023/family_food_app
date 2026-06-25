import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from 'hsp_core';
import { curves } from '@kit.ArkUI';

@ComponentV2
struct NutrientBar {
  @Param label: string = ''
  @Param value: number = 0
  @Param maxValue: number = 100
  @Param unit: string = ''
  @Param color: string = COLORS.PRIMARY
  @Param showValue: boolean = true

  private getPercentage(): number {
    return Math.min((this.value / this.maxValue) * 100, 100)
  }

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(13)
          .fontColor(COLORS.TEXT_SECONDARY)
          .layoutWeight(1)
        
        if (this.showValue) {
          Text(`${this.value}${this.unit}`)
            .fontSize(13)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .margin({ bottom: 6 })
      
      Stack() {
        Row()
          .width('100%')
          .height(8)
          .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
          .borderRadius(4)
        
        Row()
          .width(`${this.getPercentage()}%`)
          .height(8)
          .backgroundColor(this.color)
          .borderRadius(4)
          .animation({
            duration: 800,
            curve: curves.springMotion(0.6, 0.8),
            delay: 100
          })
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: SPACING.SM })
  }
}

@ComponentV2
struct ScoreRing {
  @Param score: number = 50
  @Param maxValue: number = 100
  @Param ringSize: number = 120
  @Param strokeWidth: number = 12
  @Param animating: boolean = false
  @Local displayScore: number = 0

  private getColor(): string {
    if (this.score >= 70) {
      return COLORS.ACCENT_GREEN
    } else if (this.score >= 50) {
      return COLORS.WARNING
    } else if (this.score >= 30) {
      return COLORS.LEVEL_ORANGE
    } else {
      return COLORS.LEVEL_RED
    }
  }

  onScoreChange(): void {
    if (this.animating) {
      this.displayScore = 0
      const step = this.score / 30
      let current = 0
      const timer = setInterval(() => {
        current += step
        if (current >= this.score) {
          this.displayScore = this.score
          clearInterval(timer)
        } else {
          this.displayScore = Math.floor(current)
        }
      }, 33)
    } else {
      this.displayScore = this.score
    }
  }

  aboutToAppear(): void {
    this.displayScore = this.animating ? 0 : this.score
    if (this.animating) {
      this.onScoreChange()
    }
  }

  build() {
    Stack() {
      Column() {
        Text(this.displayScore.toString())
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getColor())
          .animation({
            duration: 300,
            curve: curves.initCurve(Curve.EaseOut)
          })
        
        Text('分')
          .fontSize(14)
          .fontColor(COLORS.TEXT_SECONDARY)
      }
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
}

@ComponentV2
struct HealthLevelBadge {
  @Param level: 'excellent' | 'good' | 'moderate' | 'poor' | 'bad' = 'moderate'
  @Param label: string = ''

  private getIcon(): string {
    switch (this.level) {
      case 'excellent':
        return '🌟'
      case 'good':
        return '✓'
      case 'moderate':
        return '!'
      case 'poor':
        return '⚠'
      case 'bad':
        return '✗'
      default:
        return '?'
    }
  }

  private getColor(): string {
    switch (this.level) {
      case 'excellent':
        return COLORS.ACCENT_GREEN
      case 'good':
        return '#66BB6A'
      case 'moderate':
        return COLORS.WARNING
      case 'poor':
        return COLORS.LEVEL_ORANGE
      case 'bad':
        return COLORS.LEVEL_RED
      default:
        return COLORS.TEXT_TERTIARY
    }
  }

  private getBgColor(): string {
    switch (this.level) {
      case 'excellent':
        return '#E8F5E9'
      case 'good':
        return '#F1F8E9'
      case 'moderate':
        return '#FFF8E1'
      case 'poor':
        return '#FFF3E0'
      case 'bad':
        return '#FFEBEE'
      default:
        return COLORS.BG_LIGHT_GRAY_F5
    }
  }

  build() {
    Row() {
      Text(this.getIcon())
        .fontSize(16)
      
      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(13)
          .fontColor(this.getColor())
          .fontWeight(FontWeight.Medium)
          .margin({ left: 6 })
      }
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.getBgColor())
    .borderRadius(RADIUS.MD)
  }
}

@ComponentV2
export struct EnhancedNutritionDisplay {
  @Param nutriScore: number = 50
  @Param sodium: number = 0
  @Param sugar: number = 0
  @Param calories: number = 0
  @Param fat: number = 0
  @Param protein: number = 0
  @Param carbohydrate: number = 0
  @Param showDetails: boolean = true
  @Param animating: boolean = true

  private getHealthLevel(): 'excellent' | 'good' | 'moderate' | 'poor' | 'bad' {
    if (this.nutriScore >= 80) {
      return 'excellent'
    } else if (this.nutriScore >= 65) {
      return 'good'
    } else if (this.nutriScore >= 50) {
      return 'moderate'
    } else if (this.nutriScore >= 35) {
      return 'poor'
    } else {
      return 'bad'
    }
  }

  private getHealthLabel(): string {
    switch (this.getHealthLevel()) {
      case 'excellent':
        return '优秀'
      case 'good':
        return '良好'
      case 'moderate':
        return '中等'
      case 'poor':
        return '较差'
      case 'bad':
        return '很差'
      default:
        return '未知'
    }
  }

  build() {
    Column() {
      Row() {
        ScoreRing({
          score: this.nutriScore,
          ringSize: 140,
          strokeWidth: 16,
          animating: this.animating
        })
        
        Column() {
          Text('营养评分')
            .fontSize(14)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ bottom: 8 })
          
          HealthLevelBadge({
            level: this.getHealthLevel(),
            label: this.getHealthLabel()
          })
          
          Text('基于营养成分综合评估')
            .fontSize(11)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ left: SPACING.LG })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: SPACING.LG })

      if (this.showDetails) {
        Column() {
          Text('营养成分详情')
            .fontSize(15)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: SPACING.MD })
          
          NutrientBar({
            label: '热量',
            value: this.calories,
            maxValue: 600,
            unit: ' kcal',
            color: this.calories > 400 ? COLORS.LEVEL_ORANGE : COLORS.ACCENT_GREEN
          })
          
          NutrientBar({
            label: '钠',
            value: this.sodium,
            maxValue: 1000,
            unit: ' mg',
            color: this.sodium > 600 ? COLORS.LEVEL_RED : 
                   this.sodium > 400 ? COLORS.WARNING : COLORS.ACCENT_GREEN
          })
          
          NutrientBar({
            label: '糖',
            value: this.sugar,
            maxValue: 50,
            unit: ' g',
            color: this.sugar > 25 ? COLORS.LEVEL_RED : 
                   this.sugar > 15 ? COLORS.WARNING : COLORS.ACCENT_GREEN
          })
          
          NutrientBar({
            label: '脂肪',
            value: this.fat,
            maxValue: 30,
            unit: ' g',
            color: this.fat > 20 ? COLORS.WARNING : COLORS.ACCENT_GREEN
          })
          
          NutrientBar({
            label: '蛋白质',
            value: this.protein,
            maxValue: 25,
            unit: ' g',
            color: COLORS.ACCENT_GREEN
          })
          
          NutrientBar({
            label: '碳水化合物',
            value: this.carbohydrate,
            maxValue: 60,
            unit: ' g',
            color: COLORS.PRIMARY
          })
        }
        .width('100%')
        .padding(SPACING.MD)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(RADIUS.MD)
      }
    }
    .width('100%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .shadow({
      radius: 6,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }
}