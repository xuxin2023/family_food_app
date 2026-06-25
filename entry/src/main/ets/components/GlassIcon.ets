import { COLORS } from 'hsp_core';

export enum GlassIconSize {
  SM = 0,
  MD = 1,
  LG = 2
}

export enum GlassIconGradient {
  GREEN = 0,
  BLUE = 1,
  ORANGE = 2,
  PURPLE = 3,
  CYAN = 4,
  PINK = 5
}

@ComponentV2
export struct GlassIcon {
  @Require @Param icon: string
  @Param iconSizeLevel: GlassIconSize = GlassIconSize.MD
  @Param gradient: GlassIconGradient = GlassIconGradient.GREEN
  @Param iconColor: ResourceColor = '#FFFFFF'
  @Local pressed: boolean = false

  private getEmojiForIcon(): string {
    const emojiMap: Record<string, string> = {
      'chart': '\u{1F4CA}',
      'clock': '\u{1F552}',
      'fork_knife': '\u{1F374}',
      'calendar': '\u{1F4C6}',
      'info': '\u2139\uFE0F',
      'community': '\u{1F465}',
      'camera': '\u{1F4F8}',
      'scan': '\u{1F4F1}',
      'flame': '\u{1F525}',
      'drop': '\u{1F4A7}',
      'leaf': '\u{1F343}',
      'heart': '\u2764\uFE0F',
      'star': '\u2B50',
      'home': '\u{1F3E0}',
      'diary': '\u{1F4D3}',
      'ai': '\u{1F916}',
      'profile': '\u{1F464}',
      'back': '\u2190',
      'settings': '\u2699\uFE0F',
      'plus': '\u2795',
      'search': '\u{1F50E}',
      'check': '\u2705',
      'warning': '\u26A0\uFE0F',
      'close': '\u2716',
      'share': '\u{1F4E4}',
      'mic': '\u{1F3A4}',
      'edit': '\u270F\uFE0F',
      'trash': '\u{1F5D1}',
      'refresh': '\u{1F504}',
      'chevron_right': '\u203A',
      'chevron_down': '\u2304',
      'shield': '\u{1F6E1}',
      'doc': '\u{1F4C4}',
      'bell': '\u{1F514}',
      'location': '\u{1F4CD}',
      'lock': '\u{1F512}',
      'eye': '\u{1F441}',
      'thumbsup': '\u{1F44D}',
      'chat': '\u{1F4AC}',
      'photo': '\u{1F5FC}',
      'list': '\u{1F4CB}',
      'cart': '\u{1F6D2}',
      'report': '\u{1F4DD}',
      'target': '\u{1F3AF}',
      'book': '\u{1F4DA}',
      'family': '\u{1F46A}',
      'cloud': '\u2601\uFE0F',
      'feedback': '\u{1F4AC}',
      'fitness': '\u{1F3CB}'
    };
    const emoji: string | undefined = emojiMap[this.icon];
    if (emoji !== undefined) {
      return emoji;
    }
    return this.icon;
  }

  private get containerSize(): number {
    if (this.iconSizeLevel === GlassIconSize.LG) {
      return 52;
    }
    if (this.iconSizeLevel === GlassIconSize.SM) {
      return 36;
    }
    return 44;
  }

  private get emojiFontSize(): number {
    if (this.iconSizeLevel === GlassIconSize.LG) {
      return 24;
    }
    if (this.iconSizeLevel === GlassIconSize.SM) {
      return 16;
    }
    return 20;
  }

  private get gradientColors(): LinearGradient {
    if (this.gradient === GlassIconGradient.BLUE) {
      return { angle: 135, colors: [['#90CAF9', 0.0], ['#64B5F6', 0.5], ['#42A5F5', 1.0]] };
    }
    if (this.gradient === GlassIconGradient.ORANGE) {
      return { angle: 135, colors: [['#FFE0B2', 0.0], ['#FFCC80', 0.5], ['#FFB74D', 1.0]] };
    }
    if (this.gradient === GlassIconGradient.PURPLE) {
      return { angle: 135, colors: [['#CE93D8', 0.0], ['#BA68C8', 0.5], ['#AB47BC', 1.0]] };
    }
    if (this.gradient === GlassIconGradient.CYAN) {
      return { angle: 135, colors: [['#80CBC4', 0.0], ['#4DB6AC', 0.5], ['#26A69A', 1.0]] };
    }
    if (this.gradient === GlassIconGradient.PINK) {
      return { angle: 135, colors: [['#F8BBD0', 0.0], ['#F48FB1', 0.5], ['#F06292', 1.0]] };
    }
    return { angle: 135, colors: [['#FFCCBC', 0.0], ['#FFAB91', 0.5], ['#FF8A65', 1.0]] };
  }

  private get glowShadow(): ShadowOptions {
    if (this.gradient === GlassIconGradient.BLUE) {
      return { radius: 8, color: '#224FC3F7', offsetX: 0, offsetY: 3 };
    }
    if (this.gradient === GlassIconGradient.ORANGE) {
      return { radius: 8, color: '#22FFB74D', offsetX: 0, offsetY: 3 };
    }
    if (this.gradient === GlassIconGradient.PURPLE) {
      return { radius: 8, color: '#22BA68C8', offsetX: 0, offsetY: 3 };
    }
    if (this.gradient === GlassIconGradient.CYAN) {
      return { radius: 8, color: '#224DB6AC', offsetX: 0, offsetY: 3 };
    }
    if (this.gradient === GlassIconGradient.PINK) {
      return { radius: 8, color: '#22F48FB1', offsetX: 0, offsetY: 3 };
    }
    return { radius: 8, color: '#2281C784', offsetX: 0, offsetY: 3 };
  }

  build() {
    Column() {
      Text(this.getEmojiForIcon())
        .fontSize(this.emojiFontSize)
        .textAlign(TextAlign.Center)
    }
    .width(this.containerSize)
    .height(this.containerSize)
    .borderRadius(this.containerSize / 2)
    .linearGradient(this.gradientColors)
    .shadow(this.glowShadow)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .scale(this.pressed ? { x: 0.92, y: 0.92 } : { x: 1.0, y: 1.0 })
    .animation({ duration: 150, curve: Curve.EaseOut })
  }
}
