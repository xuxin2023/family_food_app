// GradientIconButton.ets
// 交互式渐变图标按钮 — 带按压动画+触感反馈
// 使用emoji确保图标在所有设备可见

import { HapticHelper } from 'hsp_core';
import { GlassIcon, GlassIconSize, GlassIconGradient } from './GlassIcon';

@ComponentV2
export struct GradientIconButton {
  @Require @Param icon: string
  @Require @Param label: string
  @Param iconSizeLevel: GlassIconSize = GlassIconSize.MD
  @Param gradient: GlassIconGradient = GlassIconGradient.GREEN
  @Local pressed: boolean = false
  @Event onTap: () => void = (): void => {}

  build() {
    Column() {
      GlassIcon({
        icon: this.icon,
        iconSizeLevel: this.iconSizeLevel,
        gradient: this.gradient
      })

      Text(this.label)
        .fontSize(11)
        .fontColor('#555555')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 8 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding({ top: 16, bottom: 12 })
    .alignItems(HorizontalAlign.Center)
    .scale(this.pressed ? { x: 0.92, y: 0.92 } : { x: 1.0, y: 1.0 })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .onClick(() => {
      HapticHelper.light();
      this.onTap();
    })
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.pressed = true;
      }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
  }
}
