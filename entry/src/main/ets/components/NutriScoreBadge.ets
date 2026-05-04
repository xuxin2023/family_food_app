// NutriScoreBadge.ets
// 大号圆形评分徽章组件 - 支持渐变背景和入场动效，内部嵌入适配等级标签

import { curves } from '@kit.ArkUI';
import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING } from '../constants/AppTheme';

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
  if (score >= 80) return COLORS.WHITE;
  if (score >= 60) return COLORS.WHITE;
  if (score >= 40) return COLORS.TEXT_GRAY_3333;
  if (score >= 20) return COLORS.WHITE;
  return COLORS.WHITE;
}

@Component
export struct NutriScoreBadge {
  @Prop score: number = 50;        // 评分 0-100
  @Prop diameter: number = 120;    // 徽章直径
  @Prop animating: boolean = true; // 是否播放入场动效

  // 嵌入的 LevelBadge 信息
  @Prop levelText: string = '';     // 适配等级文本（如"适合"）
  @Prop levelBgColor: string = '';  // 适配等级背景色

  @State badgeScale: number = 0.3;
  @State badgeOpacity: number = 0;
  @State isHovered: boolean = false;
  @State overlayScale: number = 0;

  aboutToAppear(): void {
    if (this.animating) {
      this.badgeScale = 0.3;
      this.badgeOpacity = 0;
      animateTo({
        duration: 600,
        curve: curves.springMotion(0.4, 0.6)
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
    Stack() {
      // 主徽章
      Column() {
        // 评分数字
        Text(`${Math.round(this.score)}`)
          .fontSize(this.diameter <= 120 ? 28 : 32)
          .fontWeight(FontWeight.Bold)
          .fontColor(getGradeTextColor(this.score))
          .margin({ bottom: 2 })
        // 等级字母
        Text(getGradeLetter(this.score))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getGradeTextColor(this.score))
          .opacity(0.9)

        // 嵌入的 LevelBadge（底部居中）
        if (this.levelText.length > 0 && this.levelBgColor.length > 0) {
          Text(this.levelText)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLORS.WHITE)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
            .backgroundColor(this.levelBgColor)
            .margin({ top: 6 })
        }
      }
      .width(this.diameter)
      .height(this.diameter)
      .borderRadius(this.diameter / 2)
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

      // Hover 放大覆盖层 - 点击时显示铭牌放大效果
      if (this.isHovered) {
        Column() {
          Text(`${Math.round(this.score)}`)
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
          Text(getGradeLetter(this.score))
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLORS.WHITE)
            .opacity(0.9)
            .margin({ top: 4 })
          if (this.levelText.length > 0) {
            Text(this.levelText)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(COLORS.WHITE)
              .padding({ left: 14, right: 14, top: 4, bottom: 4 })
              .borderRadius(12)
              .backgroundColor(this.levelBgColor)
              .margin({ top: 10 })
              .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
          }
        }
        .width(this.diameter * 1.5)
        .height(this.diameter * 1.5)
        .borderRadius(this.diameter * 1.5 / 2)
        .backgroundColor('#000000')
        .opacity(0.85)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .scale({ x: this.overlayScale, y: this.overlayScale })
        .transition({
          type: TransitionType.Insert,
          opacity: 0,
          scale: { x: 0.3, y: 0.3 }
        })
      }
    }
    .width(this.diameter * 1.5)
    .height(this.diameter * 1.5)
    .alignContent(Alignment.Center)
    .onClick(() => {
      if (!this.isHovered) {
        this.overlayScale = 0;
        this.isHovered = true;
        animateTo({ duration: 300, curve: curves.springMotion(0.4, 0.6) }, () => {
          this.overlayScale = 1.0;
        });
      } else {
        animateTo({ duration: 200 }, () => {
          this.overlayScale = 0;
        });
        setTimeout(() => {
          this.isHovered = false;
        }, 200);
      }
    })
  }
}
