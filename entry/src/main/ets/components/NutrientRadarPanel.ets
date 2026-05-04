// NutrientRadarPanel.ets
// 营养素均衡雷达面板 - 整合雷达图与概览数据的仪表板卡片
// 展示单个成员的营养素均衡状况、当前预算完成度

import { DailyNutritionSummary, NutrientTrendData } from '../engine/NutritionTrendEngine';
import { RadarChart, RadarAxis } from './RadarChart';
import { RingChart, RingData } from './RingChart';
import { COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT } from '../constants/AppTheme';

export interface NutrientRadarData {
  memberId: string;
  memberName: string;
  memberEmoji: string;
  summary: DailyNutritionSummary | null;
  budgetSodium: number;
  budgetSugar: number;
  budgetCalorie: number;
  budgetFat: number;
  trends: NutrientTrendData[];
}

@Component
export struct NutrientRadarPanel {
  @Prop data: NutrientRadarData | null = null
  @Prop compact: boolean = false

  build() {
    if (this.data === null) {
      Column() {
        Text('暂无数据')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .padding(SPACING.LG)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
    } else {
      Column() {
        // 成员标题
        Row() {
          Text(this.data.memberEmoji)
            .fontSize(FONT_SIZE.XXL)
            .margin({ right: SPACING.SM })
          Text(this.data.memberName + ' 的营养均衡')
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
        }
        .width('100%')
        .margin({ bottom: SPACING.MD })

        if (this.compact) {
          // 紧凑模式：横向环形进度 + 雷达
          Row({ space: SPACING.MD }) {
            // 环形进度环 2x2
            Column({ space: SPACING.SM }) {
              Row({ space: SPACING.SM }) {
                RingChart({
                  data: this.buildRingData('钠', this.data.summary?.sodium || 0, this.data.budgetSodium, 'mg', COLORS.ACCENT_RED_F443, COLORS.BG_LIGHT_GRAY_F5),
                  ringSize: 64,
                  strokeWidth: 6,
                  showLabel: true
                })
                RingChart({
                  data: this.buildRingData('糖', this.data.summary?.sugar || 0, this.data.budgetSugar, 'g', COLORS.ORANGE_ACCENT, COLORS.BG_LIGHT_GRAY_F5),
                  ringSize: 64,
                  strokeWidth: 6,
                  showLabel: true
                })
              }
              Row({ space: SPACING.SM }) {
                RingChart({
                  data: this.buildRingData('热量', this.data.summary?.calorie || 0, this.data.budgetCalorie, 'kcal', COLORS.ACCENT_GREEN_66BB, COLORS.BG_LIGHT_GRAY_F5),
                  ringSize: 64,
                  strokeWidth: 6,
                  showLabel: true
                })
                RingChart({
                  data: this.buildRingData('脂肪', this.data.summary?.fat || 0, this.data.budgetFat, 'g', COLORS.ACCENT_PURPLE_9C27, COLORS.BG_LIGHT_GRAY_F5),
                  ringSize: 64,
                  strokeWidth: 6,
                  showLabel: true
                })
              }
            }

            // 雷达图
            RadarChart({
              axes: this.buildRadarAxes(),
              chartSize: 150,
              showLabels: true
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          // 完整模式
          Column() {
            // 环形进度四象限
            Row({ space: SPACING.MD }) {
              RingChart({
                data: this.buildRingData('钠', this.data.summary?.sodium || 0,
                  this.data.budgetSodium, 'mg', COLORS.ACCENT_RED_F443, COLORS.BG_LIGHT_GRAY_F5),
                ringSize: 72,
                strokeWidth: 7,
                showLabel: true
              })
              RingChart({
                data: this.buildRingData('糖', this.data.summary?.sugar || 0,
                  this.data.budgetSugar, 'g', COLORS.ORANGE_ACCENT, COLORS.BG_LIGHT_GRAY_F5),
                ringSize: 72,
                strokeWidth: 7,
                showLabel: true
              })
              RingChart({
                data: this.buildRingData('热量', this.data.summary?.calorie || 0,
                  this.data.budgetCalorie, 'kcal', COLORS.ACCENT_GREEN_66BB, COLORS.BG_LIGHT_GRAY_F5),
                ringSize: 72,
                strokeWidth: 7,
                showLabel: true
              })
              RingChart({
                data: this.buildRingData('脂肪', this.data.summary?.fat || 0,
                  this.data.budgetFat, 'g', COLORS.ACCENT_PURPLE_9C27, COLORS.BG_LIGHT_GRAY_F5),
                ringSize: 72,
                strokeWidth: 7,
                showLabel: true
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
            .padding({ bottom: SPACING.MD })

            // 均衡雷达图
            RadarChart({
              axes: this.buildRadarAxes(),
              chartSize: 180,
              showLabels: true
            })
          }
          .width('100%')
        }

        // 均衡评分摘要
        this.buildBalanceSummary()
      }
      .width('100%')
      .padding(SPACING.LG)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
      .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
    }
  }

  @Builder
  buildBalanceSummary() {
    if (this.data === null || this.data.summary === null) {
      return
    }
    // 计算四维均衡度评分（越接近100%越好，但不超过120%最佳）
    const scores: number[] = [];
    const targets = [
      this.data.budgetSodium, this.data.budgetSugar,
      this.data.budgetCalorie, this.data.budgetFat
    ];
    const actuals = [
      this.data.summary.sodium, this.data.summary.sugar,
      this.data.summary.calorie, this.data.summary.fat
    ];
    let avgScore = 0;
    for (let i = 0; i < targets.length; i++) {
      if (targets[i] > 0) {
        const ratio = actuals[i] / targets[i];
        // 60%~100%为绿色，超过100%扣分
        if (ratio <= 0.6) {
          scores.push(60 + ratio * 40);
        } else if (ratio <= 1.0) {
          scores.push(100);
        } else if (ratio <= 1.2) {
          scores.push(100 - (ratio - 1.0) * 100);
        } else {
          scores.push(60);
        }
      }
    }
    if (scores.length > 0) {
      let sum = 0;
      for (let i = 0; i < scores.length; i++) {
        sum += scores[i];
      }
      avgScore = sum / scores.length;
    }

    const scoreColor = avgScore >= 85 ? COLORS.ACCENT_GREEN_4CAF :
      avgScore >= 70 ? COLORS.ORANGE_ACCENT : COLORS.ACCENT_RED_F443;
    const scoreLabel = avgScore >= 85 ? '优秀' :
      avgScore >= 70 ? '良好' : '注意';

    Row() {
      Text('均衡评分')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
      Blank()
      Row() {
        Text(avgScore.toFixed(0))
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(scoreColor)
        Text('分')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .margin({ left: 2 })
          .alignSelf(ItemAlign.End)
        Text(scoreLabel)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(scoreColor)
          .margin({ left: SPACING.SM })
          .backgroundColor(scoreColor === COLORS.ACCENT_GREEN_4CAF ? COLORS.BG_LIGHT_GREEN :
            scoreColor === COLORS.ORANGE_ACCENT ? COLORS.BG_WARM_YELLOW : COLORS.BG_WARM_PINK)
          .padding({ left: SPACING.SM, right: SPACING.SM, top: 2, bottom: 2 })
          .borderRadius(RADIUS.FULL)
      }
    }
    .width('100%')
    .padding({ top: SPACING.SM })
  }

  private buildRingData(label: string, current: number, target: number,
    unit: string, color: string, bgColor: string): RingData {
    const d: RingData = {
      label: label,
      current: current,
      target: target || 1,
      unit: unit,
      color: color,
      bgColor: bgColor
    };
    return d;
  }

  private buildRadarAxes(): RadarAxis[] {
    if (this.data === null || this.data.summary === null) {
      return [];
    }
    const axes: RadarAxis[] = [];
    const pairs: [string, number, number, string][] = [
      ['钠', this.data.summary.sodium, this.data.budgetSodium, COLORS.ACCENT_RED_F443],
      ['糖', this.data.summary.sugar, this.data.budgetSugar, COLORS.ORANGE_ACCENT],
      ['热量', this.data.summary.calorie, this.data.budgetCalorie, COLORS.ACCENT_GREEN_66BB],
      ['脂肪', this.data.summary.fat, this.data.budgetFat, COLORS.ACCENT_PURPLE_9C27]
    ];
    for (let i = 0; i < pairs.length; i++) {
      const pair = pairs[i];
      axes.push({
        label: pair[0],
        value: Math.min(pair[1], pair[2]),
        maxValue: pair[2] || 1,
        color: pair[3]
      });
    }
    return axes;
  }
}
