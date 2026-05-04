// AppTheme.ets
// 应用主题常量 - 鸿蒙6.1设计规范适配

export class COLORS {
  static readonly PRIMARY: string = '#E8A0BF';
  static readonly PRIMARY_LIGHT: string = '#F5D0E0';
  static readonly PRIMARY_DARK: string = '#C77D9E';
  static readonly SECONDARY: string = '#F5C6A0';
  static readonly ACCENT_GREEN: string = '#7EC8A0';
  static readonly ACCENT_PURPLE: string = '#B8A0D4';
  static readonly ACCENT_BLUE: string = '#80B8E0';
  static readonly SUCCESS: string = '#7EC8A0';
  static readonly WARNING: string = '#F0C060';
  static readonly ERROR: string = '#E88A8A';
  static readonly TEXT_PRIMARY: string = '#1A1A1A';
  static readonly TEXT_SECONDARY: string = '#666666';
  static readonly TEXT_TERTIARY: string = '#999999';
  static readonly TEXT_WHITE: string = '#FFFFFF';
  static readonly BG_PAGE: string = '#FAFAFA';
  static readonly BG_CARD: string = '#FFFFFF';
  static readonly BG_CARD_HIGHLIGHT: string = '#FFF5F8';
  static readonly BG_GRADIENT_START: string = '#FDE8F0';
  static readonly BG_GRADIENT_END: string = '#FFF0E0';
  static readonly SHADOW_LIGHT: string = '#1A000000';
  static readonly WHITE: string = '#FFFFFF';
  static readonly BLACK: string = '#000000';
  static readonly LEVEL_GREEN: string = '#00823F';
  static readonly LEVEL_YELLOW: string = '#FFCC00';
  static readonly LEVEL_ORANGE: string = '#EF7D00';
  static readonly LEVEL_RED: string = '#E03C31';
  // 常用颜色补充（方便统一替换）
  static readonly TEXT_GRAY_7575: string = '#757575';
  static readonly TEXT_GRAY_2121: string = '#212121';
  static readonly BG_LIGHT_GRAY_F5: string = '#F5F5F5';
  static readonly BORDER_LIGHT: string = '#E0E0E0';
  static readonly BG_WARM_ORANGE: string = '#FFF3E0';
  static readonly BG_WARM_PINK: string = '#FCE4EC';
  static readonly BG_WARM_PURPLE: string = '#F3E5F5';
  static readonly BG_WARM_BLUE: string = '#E3F2FD';
  static readonly ORANGE_ACCENT: string = '#FF9800';
  static readonly ORANGE_DEEP: string = '#EF6C00';
  static readonly PURPLE_ACCENT: string = '#7B1FA2';
  // 高频常用色补充
  static readonly BG_PAGE_LIGHT: string = '#F7F8FA';
  static readonly TEXT_GRAY_6161: string = '#616161';
  static readonly TEXT_GRAY_9E9E: string = '#9E9E9E';
  static readonly TEXT_GRAY_3333: string = '#333333';
  static readonly TEXT_GRAY_8888: string = '#888888';
  static readonly BG_DIVIDER: string = '#EEEEEE';
  static readonly ACCENT_ORANGE: string = '#FF5722';
  static readonly DOT_INACTIVE: string = '#D0D0D0';
  // Report/Stats 专用
  static readonly BG_LIGHT_GRAY_F9: string = '#F9F9F9';
  static readonly BG_LIGHTER_GRAY_F8: string = '#F8F9FA';
  static readonly BG_LIGHT_GREEN: string = '#E8F5E9';
  static readonly BG_WARM_YELLOW: string = '#FFF8E1';
  static readonly ACCENT_GREEN_4CAF: string = '#4CAF50';
  static readonly ACCENT_RED_EF53: string = '#EF5350';
  static readonly ACCENT_ORANGE_FFA7: string = '#FFA726';
  static readonly ACCENT_GREEN_66BB: string = '#66BB6A';
  static readonly BORDER_LIGHT_E8: string = '#E8E8E8';
  static readonly BORDER_LIGHT_DD: string = '#DDDDDD';
  static readonly TEXT_GRAY_4242: string = '#424242';
  static readonly TEXT_GRAY_BDBD: string = '#BDBDBD';
  static readonly ACCENT_RED_F443: string = '#F44336';
  static readonly ACCENT_PURPLE_9C27: string = '#9C27B0';
}

export class RADIUS {
  static readonly SM: number = 8;
  static readonly MD: number = 12;
  static readonly LG: number = 16;
  static readonly XL: number = 24;
  static readonly XXL: number = 32;
  static readonly FULL: number = 1000;
}

export class SPACING {
  static readonly XS: number = 4;
  static readonly SM: number = 8;
  static readonly MD: number = 12;
  static readonly LG: number = 16;
  static readonly XL: number = 24;
  static readonly XXL: number = 32;
}

// ===== 按钮尺寸统一常量 =====
export class BUTTON {
  /** 大按钮高度（拍食品标签、记录美食等核心操作） */
  static readonly HEIGHT_LG: number = 56;
  /** 中按钮高度（购物篮检查等次要操作） */
  static readonly HEIGHT_MD: number = 48;
  /** 主按钮高度（扫码、查看报告等核心操作） */
  static readonly HEIGHT_PRIMARY: number = 48;
  /** 次按钮高度（手动录入、保存草稿等次要操作） */
  static readonly HEIGHT_SECONDARY: number = 44;
  /** 小型按钮高度（底部导航链接等） */
  static readonly HEIGHT_SMALL: number = 36;
  /** 大按钮圆角 */
  static readonly RADIUS_LG: number = 28;
  /** 中按钮圆角 */
  static readonly RADIUS_MD: number = 24;
  /** 主按钮圆角 */
  static readonly RADIUS_PRIMARY: number = 24;
  /** 次按钮圆角 */
  static readonly RADIUS_SECONDARY: number = 22;
  /** 小型按钮圆角 */
  static readonly RADIUS_SMALL: number = 18;
}

export class FONT_SIZE {
  static readonly TINY: number = 10;
  static readonly SMALL: number = 12;
  static readonly BODY: number = 14;
  static readonly MD: number = 14;
  static readonly LG: number = 16;
  static readonly XL: number = 18;
  static readonly XXL: number = 22;
  static readonly TITLE: number = 20;
  static readonly TITLE_LG: number = 24;
  static readonly SUBTITLE: number = 16;
  static readonly LARGE: number = 28;
  static readonly HUGE: number = 32;
}

export class FONT_WEIGHT {
  static readonly REGULAR: number = 400;
  static readonly MEDIUM: number = 500;
  static readonly BOLD: number = 700;
}
