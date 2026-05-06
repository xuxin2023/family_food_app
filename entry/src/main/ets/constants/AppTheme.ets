// AppTheme.ets
// 应用主题常量 - 鸿蒙6.1设计规范适配
//
// ⚠️ 颜色定义以 resources/base/element/color.json 为准
// 此文件仅做 ArkTS 层的便捷引用映射，避免重复定义
// ✅ 注意：修改颜色时请同步更新 color.json 和本文件对应值
// ✅ color.json 用于系统级引用（启动背景色等），本文件用于代码中使用
//
// 暗黑模式：使用 ThemeColors 类根据当前主题返回对应色值
// 例：const bg = ThemeColors.get(theme).BG_PAGE


class LightThemeColors {
  PRIMARY: string = '#E8A0BF';
  PRIMARY_LIGHT: string = '#F5D0E0';
  PRIMARY_DARK: string = '#C77D9E';
  SECONDARY: string = '#F5C6A0';
  SUCCESS: string = '#7EC8A0';
  WARNING: string = '#F0C060';
  ERROR: string = '#E88A8A';
  ACCENT_BLUE: string = '#80B8E0';
  ACCENT_PURPLE: string = '#B8A0D4';
  TEXT_PRIMARY: string = '#1A1A1A';
  TEXT_SECONDARY: string = '#666666';
  TEXT_TERTIARY: string = '#999999';
  TEXT_WHITE: string = '#FFFFFF';
  BG_PAGE: string = '#FAFAFA';
  BG_CARD: string = '#FFFFFF';
  BG_CARD_HIGHLIGHT: string = '#FFF5F8';
  BG_GRADIENT_START: string = '#FDE8F0';
  BG_GRADIENT_END: string = '#FFF0E0';
  BG_LIGHT: string = '#F5F5F5';
  BORDER: string = '#E0E0E0';
  DIVIDER: string = '#EEEEEE';
  SHADOW: string = '#1A000000';
}

class DarkThemeColors {
  PRIMARY: string = '#E8A0BF';
  PRIMARY_LIGHT: string = '#6B3A5E';
  PRIMARY_DARK: string = '#C77D9E';
  SECONDARY: string = '#8B6F50';
  SUCCESS: string = '#4A9E6A';
  WARNING: string = '#B89040';
  ERROR: string = '#B85A5A';
  ACCENT_BLUE: string = '#4080B0';
  ACCENT_PURPLE: string = '#8060A0';
  TEXT_PRIMARY: string = '#E0E0E0';
  TEXT_SECONDARY: string = '#A0A0A0';
  TEXT_TERTIARY: string = '#707070';
  TEXT_WHITE: string = '#E0E0E0';
  BG_PAGE: string = '#121212';
  BG_CARD: string = '#1E1E1E';
  BG_CARD_HIGHLIGHT: string = '#2A1E24';
  BG_GRADIENT_START: string = '#2A1A24';
  BG_GRADIENT_END: string = '#2A2018';
  BG_LIGHT: string = '#2C2C2C';
  BORDER: string = '#383838';
  DIVIDER: string = '#2E2E2E';
  SHADOW: string = '#33000000';
}

export type ThemeMode = 'light' | 'dark';

const LIGHT_INSTANCE: LightThemeColors = new LightThemeColors();
const DARK_INSTANCE: DarkThemeColors = new DarkThemeColors();

export class ThemeColors {
  private static currentTheme: ThemeMode = 'light';

  static setTheme(mode: ThemeMode): void {
    ThemeColors.currentTheme = mode;
    AppStorage.setOrCreate<ThemeMode>('currentThemeMode', mode);
  }

  static getTheme(): ThemeMode {
    return ThemeColors.currentTheme;
  }

  static get(mode?: ThemeMode): LightThemeColors {
    const active = mode ?? ThemeColors.currentTheme;
    return active === 'dark' ? DARK_INSTANCE : LIGHT_INSTANCE;
  }

  /** 便捷获取单个色值 */
  static color(key: string, mode?: ThemeMode): string {
    const colors: Record<string, string> = ThemeColors.get(mode) as Object as Record<string, string>;
    return colors[key] ?? '#000000';
  }
}

/**
 * 获取当前主题下对应的颜色值（动态版本，会响应主题切换）
 * 在页面中可配合 @StorageProp('currentThemeMode') 使用
 * 示例：.fontColor(TC('TEXT_PRIMARY'))
 */
export function TC(key: string): string {
  const stored: ThemeMode | undefined = AppStorage.get<ThemeMode>('currentThemeMode');
  const mode: ThemeMode = stored !== undefined ? stored : ThemeColors.getTheme();
  return ThemeColors.color(key, mode);
}

export class COLORS {
  // ===== 主色 =====
  static readonly PRIMARY: string = '#E8A0BF';
  static readonly PRIMARY_LIGHT: string = '#F5D0E0';
  static readonly PRIMARY_DARK: string = '#C77D9E';
  static readonly SECONDARY: string = '#F5C6A0';

  // ===== 功能色 =====
  static readonly SUCCESS: string = '#7EC8A0';
  static readonly WARNING: string = '#F0C060';
  static readonly ERROR: string = '#E88A8A';
  static readonly ACCENT_BLUE: string = '#80B8E0';
  static readonly ACCENT_PURPLE: string = '#B8A0D4';

  // ===== 文字色 =====
  static readonly TEXT_PRIMARY: string = '#1A1A1A';
  static readonly TEXT_SECONDARY: string = '#666666';
  static readonly TEXT_TERTIARY: string = '#999999';
  static readonly TEXT_WHITE: string = '#FFFFFF';
  static readonly TEXT_GRAY: string = '#757575';

  // ===== 背景色 =====
  static readonly BG_PAGE: string = '#FAFAFA';
  static readonly BG_CARD: string = '#FFFFFF';
  static readonly BG_CARD_HIGHLIGHT: string = '#FFF5F8';
  static readonly BG_GRADIENT_START: string = '#FDE8F0';
  static readonly BG_GRADIENT_END: string = '#FFF0E0';
  static readonly BG_LIGHT: string = '#F5F5F5';

  // ===== 食品适配等级色 =====
  static readonly LEVEL_GREEN: string = '#4CAF50';
  static readonly LEVEL_YELLOW: string = '#FF9800';
  static readonly LEVEL_ORANGE: string = '#FF5722';
  static readonly LEVEL_RED: string = '#F44336';

  // ===== 常用装饰色 =====
  static readonly ORANGE_ACCENT: string = '#FF9800';
  static readonly PURPLE_ACCENT: string = '#7B1FA2';
  static readonly WHITE: string = '#FFFFFF';
  static readonly BLACK: string = '#000000';
  static readonly BORDER: string = '#E0E0E0';
  static readonly DIVIDER: string = '#EEEEEE';
  static readonly DOT_INACTIVE: string = '#D0D0D0';
  static readonly SHADOW: string = '#1A000000';

  // ===== 扩展色（供别名引用） =====
  static readonly TEXT_GRAY_7575: string = '#757575';
  static readonly TEXT_GRAY_BDBD: string = '#BDBDBD';
  static readonly BORDER_LIGHT_E8: string = '#E8E8E8';
  static readonly BORDER_LIGHT_DD: string = '#DDDDDD';
  static readonly BG_LIGHT_GRAY_F9: string = '#F9F9F9';
  static readonly BG_LIGHTER_GRAY_F8: string = '#F8F9FA';
  static readonly BG_PAGE_LIGHT: string = '#F7F8FA';
  static readonly ACCENT_GREEN_4CAF: string = '#4CAF50';
  static readonly ACCENT_GREEN_66BB: string = '#66BB6A';
  static readonly ACCENT_RED_EF53: string = '#EF5350';
  static readonly ACCENT_RED_F443: string = '#F44336';
  static readonly ACCENT_ORANGE_FFA7: string = '#FFA726';
  static readonly ACCENT_ORANGE: string = '#FF5722';
  static readonly ACCENT_PURPLE_9C27: string = '#9C27B0';
  static readonly ORANGE_DEEP: string = '#EF6C00';

  // ===== 场景背景色 =====
  static readonly BG_WARM_ORANGE: string = '#FFF3E0';
  static readonly BG_WARM_PINK: string = '#FCE4EC';
  static readonly BG_WARM_PURPLE: string = '#F3E5F5';
  static readonly BG_WARM_BLUE: string = '#E3F2FD';
  static readonly BG_WARM_YELLOW: string = '#FFF8E1';
  static readonly BG_LIGHT_GREEN: string = '#E8F5E9';

  // ===== 🔴 废弃别名（向后兼容 — 请使用规范名） =====
  // 说明：以下为旧版颜色名，新代码应使用上方规范名
  // 迁移计划：当所有引用替换为规范名后删除此区块
  static readonly TEXT_GRAY_2121: string = COLORS.TEXT_PRIMARY;
  static readonly TEXT_GRAY_6161: string = COLORS.TEXT_SECONDARY;
  static readonly TEXT_GRAY_9E9E: string = COLORS.TEXT_TERTIARY;
  static readonly TEXT_GRAY_3333: string = COLORS.TEXT_PRIMARY;
  static readonly TEXT_GRAY_8888: string = COLORS.TEXT_SECONDARY;
  static readonly TEXT_GRAY_4242: string = COLORS.TEXT_PRIMARY;
  static readonly SHADOW_LIGHT: string = COLORS.SHADOW;
  static readonly BORDER_LIGHT: string = COLORS.BORDER;
  static readonly BG_LIGHT_GRAY_F5: string = COLORS.BG_LIGHT;
  static readonly ACCENT_GREEN: string = COLORS.SUCCESS;
  static readonly BG_DIVIDER: string = COLORS.DIVIDER;
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
  static readonly HEIGHT_LG: number = 56;
  static readonly HEIGHT_MD: number = 48;
  static readonly HEIGHT_PRIMARY: number = 48;
  static readonly HEIGHT_SECONDARY: number = 44;
  static readonly HEIGHT_SMALL: number = 36;
  static readonly RADIUS_LG: number = 28;
  static readonly RADIUS_PRIMARY: number = 24;
  static readonly RADIUS_SECONDARY: number = 22;
  static readonly RADIUS_SMALL: number = 18;
  // 兼容别名
  static readonly RADIUS_MD: number = 24;  // = RADIUS_PRIMARY
}

// ===== 字号统一常量 =====
export class FONT_SIZE {
  static readonly TINY: number = 11;
  static readonly SMALL: number = 13;
  static readonly BODY: number = 14;
  static readonly SUBTITLE: number = 16;
  static readonly TITLE: number = 18;
  static readonly TITLE_LG: number = 20;
  static readonly LARGE: number = 22;
  static readonly XL: number = 28;
  // 兼容别名
  static readonly LG: number = 20;   // = TITLE_LG
  static readonly XXL: number = 28;  // = XL
}

// ===== 字重统一常量 =====
export class FONT_WEIGHT {
  static readonly REGULAR: number = 400;
  static readonly MEDIUM: number = 500;
  static readonly BOLD: number = 600;
  static readonly EXTRA_BOLD: number = 700;
}