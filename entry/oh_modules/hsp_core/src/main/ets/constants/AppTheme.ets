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
  // 主色
  PRIMARY: string = '#E8A0BF';
  PRIMARY_LIGHT: string = '#F5D0E0';
  PRIMARY_DARK: string = '#C77D9E';
  SECONDARY: string = '#F5C6A0';
  // 功能色
  SUCCESS: string = '#7EC8A0';
  WARNING: string = '#F0C060';
  ERROR: string = '#E88A8A';
  ACCENT_BLUE: string = '#80B8E0';
  ACCENT_PURPLE: string = '#B8A0D4';
  // 文字色
  TEXT_PRIMARY: string = '#1A1A1A';
  TEXT_SECONDARY: string = '#666666';
  TEXT_TERTIARY: string = '#999999';
  TEXT_WHITE: string = '#FFFFFF';
  TEXT_GRAY: string = '#757575';
  TEXT_GRAY_BDBD: string = '#BDBDBD';
  // 背景色
  BG_PAGE: string = '#FAFAFA';
  BG_CARD: string = '#FFFFFF';
  BG_CARD_HIGHLIGHT: string = '#FFF5F8';
  BG_GRADIENT_START: string = '#FDE8F0';
  BG_GRADIENT_END: string = '#FFF0E0';
  BG_LIGHT: string = '#F5F5F5';
  BG_LIGHT_GRAY_F9: string = '#F9F9F9';
  BG_LIGHTER_GRAY_F8: string = '#F8F9FA';
  BG_PAGE_LIGHT: string = '#F7F8FA';
  // 边框/分割线
  BORDER: string = '#E0E0E0';
  DIVIDER: string = '#EEEEEE';
  BORDER_LIGHT_E8: string = '#E8E8E8';
  BORDER_LIGHT_DD: string = '#DDDDDD';
  DOT_INACTIVE: string = '#D0D0D0';
  // 阴影
  SHADOW: string = '#1A000000';
  // 食品等级色
  LEVEL_GREEN: string = '#4CAF50';
  LEVEL_YELLOW: string = '#FF9800';
  LEVEL_ORANGE: string = '#FF5722';
  LEVEL_RED: string = '#F44336';
  // 装饰色
  ORANGE_ACCENT: string = '#FF9800';
  ORANGE_DEEP: string = '#EF6C00';
  PURPLE_ACCENT: string = '#7B1FA2';
  WHITE: string = '#FFFFFF';
  BLACK: string = '#000000';
  // 扩展强调色
  ACCENT_GREEN_4CAF: string = '#4CAF50';
  ACCENT_GREEN_66BB: string = '#66BB6A';
  ACCENT_RED_EF53: string = '#EF5350';
  ACCENT_RED_F443: string = '#F44336';
  ACCENT_ORANGE_FFA7: string = '#FFA726';
  ACCENT_ORANGE: string = '#FF5722';
  ACCENT_PURPLE_9C27: string = '#9C27B0';
  // 场景背景色
  BG_WARM_ORANGE: string = '#FFF3E0';
  BG_WARM_PINK: string = '#FCE4EC';
  BG_WARM_PURPLE: string = '#F3E5F5';
  BG_WARM_BLUE: string = '#E3F2FD';
  BG_WARM_YELLOW: string = '#FFF8E1';
  BG_LIGHT_GREEN: string = '#E8F5E9';

  toMap(): Map<string, string> {
    const map = new Map<string, string>();
    map.set('PRIMARY', this.PRIMARY);
    map.set('PRIMARY_LIGHT', this.PRIMARY_LIGHT);
    map.set('PRIMARY_DARK', this.PRIMARY_DARK);
    map.set('SECONDARY', this.SECONDARY);
    map.set('SUCCESS', this.SUCCESS);
    map.set('WARNING', this.WARNING);
    map.set('ERROR', this.ERROR);
    map.set('ACCENT_BLUE', this.ACCENT_BLUE);
    map.set('ACCENT_PURPLE', this.ACCENT_PURPLE);
    map.set('TEXT_PRIMARY', this.TEXT_PRIMARY);
    map.set('TEXT_SECONDARY', this.TEXT_SECONDARY);
    map.set('TEXT_TERTIARY', this.TEXT_TERTIARY);
    map.set('TEXT_WHITE', this.TEXT_WHITE);
    map.set('TEXT_GRAY', this.TEXT_GRAY);
    map.set('TEXT_GRAY_BDBD', this.TEXT_GRAY_BDBD);
    map.set('BG_PAGE', this.BG_PAGE);
    map.set('BG_CARD', this.BG_CARD);
    map.set('BG_CARD_HIGHLIGHT', this.BG_CARD_HIGHLIGHT);
    map.set('BG_GRADIENT_START', this.BG_GRADIENT_START);
    map.set('BG_GRADIENT_END', this.BG_GRADIENT_END);
    map.set('BG_LIGHT', this.BG_LIGHT);
    map.set('BG_LIGHT_GRAY_F9', this.BG_LIGHT_GRAY_F9);
    map.set('BG_LIGHTER_GRAY_F8', this.BG_LIGHTER_GRAY_F8);
    map.set('BG_PAGE_LIGHT', this.BG_PAGE_LIGHT);
    map.set('BORDER', this.BORDER);
    map.set('DIVIDER', this.DIVIDER);
    map.set('BORDER_LIGHT_E8', this.BORDER_LIGHT_E8);
    map.set('BORDER_LIGHT_DD', this.BORDER_LIGHT_DD);
    map.set('DOT_INACTIVE', this.DOT_INACTIVE);
    map.set('SHADOW', this.SHADOW);
    map.set('LEVEL_GREEN', this.LEVEL_GREEN);
    map.set('LEVEL_YELLOW', this.LEVEL_YELLOW);
    map.set('LEVEL_ORANGE', this.LEVEL_ORANGE);
    map.set('LEVEL_RED', this.LEVEL_RED);
    map.set('ORANGE_ACCENT', this.ORANGE_ACCENT);
    map.set('ORANGE_DEEP', this.ORANGE_DEEP);
    map.set('PURPLE_ACCENT', this.PURPLE_ACCENT);
    map.set('WHITE', this.WHITE);
    map.set('BLACK', this.BLACK);
    map.set('ACCENT_GREEN_4CAF', this.ACCENT_GREEN_4CAF);
    map.set('ACCENT_GREEN_66BB', this.ACCENT_GREEN_66BB);
    map.set('ACCENT_RED_EF53', this.ACCENT_RED_EF53);
    map.set('ACCENT_RED_F443', this.ACCENT_RED_F443);
    map.set('ACCENT_ORANGE_FFA7', this.ACCENT_ORANGE_FFA7);
    map.set('ACCENT_ORANGE', this.ACCENT_ORANGE);
    map.set('ACCENT_PURPLE_9C27', this.ACCENT_PURPLE_9C27);
    map.set('BG_WARM_ORANGE', this.BG_WARM_ORANGE);
    map.set('BG_WARM_PINK', this.BG_WARM_PINK);
    map.set('BG_WARM_PURPLE', this.BG_WARM_PURPLE);
    map.set('BG_WARM_BLUE', this.BG_WARM_BLUE);
    map.set('BG_WARM_YELLOW', this.BG_WARM_YELLOW);
    map.set('BG_LIGHT_GREEN', this.BG_LIGHT_GREEN);
    return map;
  }
}

class DarkThemeColors {
  // 主色 (保持品牌色不变)
  PRIMARY: string = '#E8A0BF';
  PRIMARY_LIGHT: string = '#A86785'; // 暗色背景下提高对比度
  PRIMARY_DARK: string = '#C77D9E';
  SECONDARY: string = '#8B6F50';
  // 功能色 (暗色模式下略微降低亮度)
  SUCCESS: string = '#4A9E6A';
  WARNING: string = '#B89040';
  ERROR: string = '#B85A5A';
  ACCENT_BLUE: string = '#4080B0';
  ACCENT_PURPLE: string = '#8060A0';
  // 文字色 (反转)
  TEXT_PRIMARY: string = '#E0E0E0';
  TEXT_SECONDARY: string = '#A0A0A0';
  TEXT_TERTIARY: string = '#707070';
  TEXT_WHITE: string = '#E0E0E0';
  TEXT_GRAY: string = '#8A8A8A';
  TEXT_GRAY_BDBD: string = '#5A5A5A';
  // 背景色 (暗色)
  BG_PAGE: string = '#121212';
  BG_CARD: string = '#1E1E1E';
  BG_CARD_HIGHLIGHT: string = '#2A1E24';
  BG_GRADIENT_START: string = '#2A1A24';
  BG_GRADIENT_END: string = '#2A2018';
  BG_LIGHT: string = '#2C2C2C';
  BG_LIGHT_GRAY_F9: string = '#1A1A1A';
  BG_LIGHTER_GRAY_F8: string = '#181818';
  BG_PAGE_LIGHT: string = '#141618';
  // 边框/分割线 (加深)
  BORDER: string = '#383838';
  DIVIDER: string = '#2E2E2E';
  BORDER_LIGHT_E8: string = '#333333';
  BORDER_LIGHT_DD: string = '#3A3A3A';
  DOT_INACTIVE: string = '#484848';
  // 阴影 (深色模式下加重)
  SHADOW: string = '#1AFFFFFF'; // 暗色模式下使用亮色阴影营造悬浮感
  // 食品等级色 (保持语义不变，暗色下稍暗)
  LEVEL_GREEN: string = '#43A047';
  LEVEL_YELLOW: string = '#FB8C00';
  LEVEL_ORANGE: string = '#F4511E';
  LEVEL_RED: string = '#E53935';
  // 装饰色
  ORANGE_ACCENT: string = '#FB8C00';
  ORANGE_DEEP: string = '#E65100';
  PURPLE_ACCENT: string = '#8E24AA';
  WHITE: string = '#E0E0E0';
  BLACK: string = '#000000';
  // 扩展强调色 (暗色下略微提亮保持可辨识)
  ACCENT_GREEN_4CAF: string = '#43A047';
  ACCENT_GREEN_66BB: string = '#55A855';
  ACCENT_RED_EF53: string = '#D32F2F';
  ACCENT_RED_F443: string = '#D32F2F';
  ACCENT_ORANGE_FFA7: string = '#EF8C00';
  ACCENT_ORANGE: string = '#E64A19';
  ACCENT_PURPLE_9C27: string = '#AB47BC';
  // 场景背景色 (深度暗化)
  BG_WARM_ORANGE: string = '#2A2018';
  BG_WARM_PINK: string = '#2A1E24';
  BG_WARM_PURPLE: string = '#26202A';
  BG_WARM_BLUE: string = '#1A2228';
  BG_WARM_YELLOW: string = '#282418';
  BG_LIGHT_GREEN: string = '#1A2820';

  toMap(): Map<string, string> {
    const map = new Map<string, string>();
    map.set('PRIMARY', this.PRIMARY);
    map.set('PRIMARY_LIGHT', this.PRIMARY_LIGHT);
    map.set('PRIMARY_DARK', this.PRIMARY_DARK);
    map.set('SECONDARY', this.SECONDARY);
    map.set('SUCCESS', this.SUCCESS);
    map.set('WARNING', this.WARNING);
    map.set('ERROR', this.ERROR);
    map.set('ACCENT_BLUE', this.ACCENT_BLUE);
    map.set('ACCENT_PURPLE', this.ACCENT_PURPLE);
    map.set('TEXT_PRIMARY', this.TEXT_PRIMARY);
    map.set('TEXT_SECONDARY', this.TEXT_SECONDARY);
    map.set('TEXT_TERTIARY', this.TEXT_TERTIARY);
    map.set('TEXT_WHITE', this.TEXT_WHITE);
    map.set('TEXT_GRAY', this.TEXT_GRAY);
    map.set('TEXT_GRAY_BDBD', this.TEXT_GRAY_BDBD);
    map.set('BG_PAGE', this.BG_PAGE);
    map.set('BG_CARD', this.BG_CARD);
    map.set('BG_CARD_HIGHLIGHT', this.BG_CARD_HIGHLIGHT);
    map.set('BG_GRADIENT_START', this.BG_GRADIENT_START);
    map.set('BG_GRADIENT_END', this.BG_GRADIENT_END);
    map.set('BG_LIGHT', this.BG_LIGHT);
    map.set('BG_LIGHT_GRAY_F9', this.BG_LIGHT_GRAY_F9);
    map.set('BG_LIGHTER_GRAY_F8', this.BG_LIGHTER_GRAY_F8);
    map.set('BG_PAGE_LIGHT', this.BG_PAGE_LIGHT);
    map.set('BORDER', this.BORDER);
    map.set('DIVIDER', this.DIVIDER);
    map.set('BORDER_LIGHT_E8', this.BORDER_LIGHT_E8);
    map.set('BORDER_LIGHT_DD', this.BORDER_LIGHT_DD);
    map.set('DOT_INACTIVE', this.DOT_INACTIVE);
    map.set('SHADOW', this.SHADOW);
    map.set('LEVEL_GREEN', this.LEVEL_GREEN);
    map.set('LEVEL_YELLOW', this.LEVEL_YELLOW);
    map.set('LEVEL_ORANGE', this.LEVEL_ORANGE);
    map.set('LEVEL_RED', this.LEVEL_RED);
    map.set('ORANGE_ACCENT', this.ORANGE_ACCENT);
    map.set('ORANGE_DEEP', this.ORANGE_DEEP);
    map.set('PURPLE_ACCENT', this.PURPLE_ACCENT);
    map.set('WHITE', this.WHITE);
    map.set('BLACK', this.BLACK);
    map.set('ACCENT_GREEN_4CAF', this.ACCENT_GREEN_4CAF);
    map.set('ACCENT_GREEN_66BB', this.ACCENT_GREEN_66BB);
    map.set('ACCENT_RED_EF53', this.ACCENT_RED_EF53);
    map.set('ACCENT_RED_F443', this.ACCENT_RED_F443);
    map.set('ACCENT_ORANGE_FFA7', this.ACCENT_ORANGE_FFA7);
    map.set('ACCENT_ORANGE', this.ACCENT_ORANGE);
    map.set('ACCENT_PURPLE_9C27', this.ACCENT_PURPLE_9C27);
    map.set('BG_WARM_ORANGE', this.BG_WARM_ORANGE);
    map.set('BG_WARM_PINK', this.BG_WARM_PINK);
    map.set('BG_WARM_PURPLE', this.BG_WARM_PURPLE);
    map.set('BG_WARM_BLUE', this.BG_WARM_BLUE);
    map.set('BG_WARM_YELLOW', this.BG_WARM_YELLOW);
    map.set('BG_LIGHT_GREEN', this.BG_LIGHT_GREEN);
    return map;
  }
}

export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark'
}

const LIGHT_INSTANCE: LightThemeColors = new LightThemeColors();
const DARK_INSTANCE: DarkThemeColors = new DarkThemeColors();

export class ThemeColors {
  private static currentTheme: ThemeMode = ThemeMode.LIGHT;

  static setTheme(mode: ThemeMode): void {
    ThemeColors.currentTheme = mode;
    AppStorage.setOrCreate<ThemeMode>('currentThemeMode', mode);
  }

  static getTheme(): ThemeMode {
    return ThemeColors.currentTheme;
  }

  static get(mode?: ThemeMode): LightThemeColors {
    const active = mode ?? ThemeColors.currentTheme;
    return active === ThemeMode.DARK ? DARK_INSTANCE : LIGHT_INSTANCE;
  }

  /** 便捷获取单个色值 */
  static color(key: string, mode?: ThemeMode): string {
    const colors = ThemeColors.get(mode).toMap();
    return colors.get(key) ?? '#000000';
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

/**
 * COLORS — 主题感知颜色访问类
 * 所有 getter 委托给 TC()，自动响应 light/dark 主题切换
 * 用法不变：COLORS.PRIMARY 即可获取当前主题色
 * 弃用标记：新代码建议直接用 TC('PRIMARY')
 */
export class COLORS {
  // ===== 主色 =====
  static get PRIMARY(): string { return TC('PRIMARY'); }
  static get PRIMARY_LIGHT(): string { return TC('PRIMARY_LIGHT'); }
  static get PRIMARY_DARK(): string { return TC('PRIMARY_DARK'); }
  static get SECONDARY(): string { return TC('SECONDARY'); }

  // ===== 功能色 =====
  static get SUCCESS(): string { return TC('SUCCESS'); }
  static get WARNING(): string { return TC('WARNING'); }
  static get ERROR(): string { return TC('ERROR'); }
  static get ACCENT_BLUE(): string { return TC('ACCENT_BLUE'); }
  static get ACCENT_PURPLE(): string { return TC('ACCENT_PURPLE'); }

  // ===== 文字色 =====
  static get TEXT_PRIMARY(): string { return TC('TEXT_PRIMARY'); }
  static get TEXT_SECONDARY(): string { return TC('TEXT_SECONDARY'); }
  static get TEXT_TERTIARY(): string { return TC('TEXT_TERTIARY'); }
  static get TEXT_WHITE(): string { return TC('TEXT_WHITE'); }
  static get TEXT_GRAY(): string { return TC('TEXT_GRAY'); }

  // ===== 背景色 =====
  static get BG_PAGE(): string { return TC('BG_PAGE'); }
  static get BG_WHITE(): string { return TC('WHITE'); }
  static get BG_CARD(): string { return TC('BG_CARD'); }
  static get BG_CARD_HIGHLIGHT(): string { return TC('BG_CARD_HIGHLIGHT'); }
  static get BG_GRADIENT_START(): string { return TC('BG_GRADIENT_START'); }
  static get BG_GRADIENT_END(): string { return TC('BG_GRADIENT_END'); }
  static get BG_LIGHT(): string { return TC('BG_LIGHT'); }

  // ===== 食品适配等级色 =====
  static get LEVEL_GREEN(): string { return TC('LEVEL_GREEN'); }
  static get LEVEL_YELLOW(): string { return TC('LEVEL_YELLOW'); }
  static get LEVEL_ORANGE(): string { return TC('LEVEL_ORANGE'); }
  static get LEVEL_RED(): string { return TC('LEVEL_RED'); }

  // ===== 常用装饰色 =====
  static get ORANGE_ACCENT(): string { return TC('ORANGE_ACCENT'); }
  static get PURPLE_ACCENT(): string { return TC('PURPLE_ACCENT'); }
  static get WHITE(): string { return TC('WHITE'); }
  static get BLACK(): string { return TC('BLACK'); }
  static get BORDER(): string { return TC('BORDER'); }
  static get DIVIDER(): string { return TC('DIVIDER'); }
  static get DOT_INACTIVE(): string { return TC('DOT_INACTIVE'); }
  static get SHADOW(): string { return TC('SHADOW'); }

  // ===== 扩展色 =====
  static get TEXT_GRAY_7575(): string { return TC('TEXT_GRAY'); }
  static get TEXT_GRAY_BDBD(): string { return TC('TEXT_GRAY_BDBD'); }
  static get BORDER_LIGHT_E8(): string { return TC('BORDER_LIGHT_E8'); }
  static get BORDER_LIGHT_DD(): string { return TC('BORDER_LIGHT_DD'); }
  static get BG_LIGHT_GRAY_F9(): string { return TC('BG_LIGHT_GRAY_F9'); }
  static get BG_LIGHTER_GRAY_F8(): string { return TC('BG_LIGHTER_GRAY_F8'); }
  static get BG_PAGE_LIGHT(): string { return TC('BG_PAGE_LIGHT'); }
  static get ACCENT_GREEN_4CAF(): string { return TC('ACCENT_GREEN_4CAF'); }
  static get ACCENT_GREEN_66BB(): string { return TC('ACCENT_GREEN_66BB'); }
  static get ACCENT_RED_EF53(): string { return TC('ACCENT_RED_EF53'); }
  static get ACCENT_RED_F443(): string { return TC('ACCENT_RED_F443'); }
  static get ACCENT_ORANGE_FFA7(): string { return TC('ACCENT_ORANGE_FFA7'); }
  static get ACCENT_ORANGE(): string { return TC('ACCENT_ORANGE'); }
  static get ACCENT_PURPLE_9C27(): string { return TC('ACCENT_PURPLE_9C27'); }
  static get ORANGE_DEEP(): string { return TC('ORANGE_DEEP'); }

  // ===== 场景背景色 =====
  static get BG_WARM_ORANGE(): string { return TC('BG_WARM_ORANGE'); }
  static get BG_WARM_PINK(): string { return TC('BG_WARM_PINK'); }
  static get BG_WARM_PURPLE(): string { return TC('BG_WARM_PURPLE'); }
  static get BG_WARM_BLUE(): string { return TC('BG_WARM_BLUE'); }
  static get BG_WARM_YELLOW(): string { return TC('BG_WARM_YELLOW'); }
  static get BG_LIGHT_GREEN(): string { return TC('BG_LIGHT_GREEN'); }

  // ===== 废弃别名（向后兼容） =====
  static get TEXT_GRAY_2121(): string { return TC('TEXT_PRIMARY'); }
  static get TEXT_GRAY_6161(): string { return TC('TEXT_SECONDARY'); }
  static get TEXT_GRAY_9E9E(): string { return TC('TEXT_TERTIARY'); }
  static get TEXT_GRAY_3333(): string { return TC('TEXT_PRIMARY'); }
  static get TEXT_GRAY_8888(): string { return TC('TEXT_SECONDARY'); }
  static get TEXT_GRAY_4242(): string { return TC('TEXT_PRIMARY'); }
  static get SHADOW_LIGHT(): string { return TC('SHADOW'); }
  static get BORDER_LIGHT(): string { return TC('BORDER'); }
  static get BG_LIGHT_GRAY_F5(): string { return TC('BG_LIGHT'); }
  static get ACCENT_GREEN(): string { return TC('SUCCESS'); }
  static get BG_DIVIDER(): string { return TC('DIVIDER'); }
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
  static readonly CAPTION: number = 10;
  static readonly TINY: number = 11;
  static readonly BODY_SM: number = 12;
  static readonly SMALL: number = 13;
  static readonly BODY: number = 14;
  static readonly BODY_MD: number = 14;
  static readonly MEDIUM: number = 15;
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

export class SCORE_COLORS {
  static readonly GRADE_A: string = '#4CAF50';
  static readonly GRADE_B: string = '#8BC34A';
  static readonly GRADE_C: string = '#FFC107';
  static readonly GRADE_D: string = '#FF9800';
  static readonly GRADE_E: string = '#F44336';
  static readonly NOVA_1: string = '#4CAF50';
  static readonly NOVA_2: string = '#FFC107';
  static readonly NOVA_3: string = '#FF9800';
  static readonly NOVA_4: string = '#F44336';
  static readonly ECO_A: string = '#2E7D32';
  static readonly ECO_B: string = '#66BB6A';
  static readonly ECO_C: string = '#FFD54F';
  static readonly ECO_D: string = '#FF8A65';
  static readonly ECO_E: string = '#F44336';
}