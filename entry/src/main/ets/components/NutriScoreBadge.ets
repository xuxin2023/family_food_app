// NutriScoreBadge.ets
// 大号圆形评分徽章组件 - 支持渐变背景和入场动效

import { COLORS, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

/**
 * 根据分数获取背景渐变色 (从绿色#66BB6A到红色#F44336)
 */
function getGradeColors(score: number): [string, string] {
  if (score >= 80) {
    return ['#66BB6A', '#81C784'];
  } else if (score >= 60) {
    return ['#81C784', '#AED581'];
  } else if (score >= 40) {
    return ['#FFD54F', '#FFB74D'];
  } else if (score >= 20) {
    return ['#FFB74F', '#FF8A65'];
  } else {
    return ['#F44336', '#E53935'];
  }
}

/**
 * 根据分数获取等级字母 (A-E)
 */
function getGradeLetter(score: number): string {
  if (score >= 80) return 'A';
  if (score >= 60) return 'B';
  if (score >= 40) return 'C';
  if (score >= 20) return 'D';
  return 'E';
}

/**
 * 根据分数获取等级文字颜色
 */
function getGradeTextColor(score: number): string {
  if (score >= 80) return '#FFFFFF';
  if (score >= 60) return '#FFFFFF';
  if (score >= 40) return '#333333';
  if (score >= 20) return '#FFFFFF';
  return '#FFFFFF';
}

@Component
export struct NutriScoreBadge {
  @Prop score: number = 50;        // 评分 0-100
  @Prop diameter: number = 120;    // 徽章直径
  @Prop animating: boolean = true; // 是否播放入场动效

  @State badgeScale: number = 0.3;
  @State badgeOpacity: number = 0;

  aboutToAppear(): void {
    if (this.animating) {
      // 弹出动画：快速弹出到1.1倍再回弹到1.0
      animateTo({
        duration: 400,
        curve: Curve.EaseOut
      }, () => {
        this.badgeScale = 1.0;
        this.badgeOpacity = 1.0;
      });
    } else {
      this.badgeScale = 1.0;
      this.badgeOpacity = 1.0;
    }
  }

  build() {
    Column() {
      // 评分数字
      Text(`${Math.round(this.score)}`)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(getGradeTextColor(this.score))
        .margin({ bottom: 2 })
      // 等级字母
      Text(getGradeLetter(this.score))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(getGradeTextColor(this.score))
        .opacity(0.9)
    }
    .width(this.diameter)
    .height(this.diameter)
    .borderRadius(this.diameter / 2)
    .backgroundColor('#66BB6A')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[getGradeColors(this.score)[0], 0.0], [getGradeColors(this.score)[1], 1.0]]
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({
      radius: 8,
      color: '#33000000',
      offsetX: 0,
      offsetY: 4
    })
    .scale({ x: this.badgeScale, y: this.badgeScale })
    .opacity(this.badgeOpacity)
  }
}
