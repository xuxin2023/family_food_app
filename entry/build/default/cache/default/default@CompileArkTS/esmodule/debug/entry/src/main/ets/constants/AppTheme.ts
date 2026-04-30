/**
 * 应用主题常量 - 鸿蒙6.1设计规范适配
 * 设计理念：温暖、柔和、沉浸、动态
 * 主色调：玫瑰粉 (#E8A0BF) + 暖杏 (#F5C6A0)
 * 中性偏女性化风格：圆润、轻盈、柔光、留白
 * 支持深色模式自动适配
 * V2增强版：补充交互反馈、动效预设、状态色、渐变预设
 */
// ===== 颜色常量 =====
export class COLORS {
    // 品牌色系 - 柔和玫瑰粉 + 暖杏
    static readonly PRIMARY: string = '#E8A0BF';
    static readonly PRIMARY_LIGHT: string = '#F5D0E0';
    static readonly PRIMARY_DARK: string = '#C77D9E';
    static readonly PRIMARY_ULTRA_LIGHT: string = '#FDE8F0';
    static readonly SECONDARY: string = '#F5C6A0';
    static readonly SECONDARY_LIGHT: string = '#FDE8D0';
    static readonly SECONDARY_ULTRA_LIGHT: string = '#FFF0E0';
    // 功能色 - 柔和版
    static readonly ACCENT_GREEN: string = '#7EC8A0';
    static readonly ACCENT_GREEN_LIGHT: string = '#D4F0E0';
    static readonly ACCENT_GREEN_ULTRA_LIGHT: string = '#EEF8F0';
    static readonly ACCENT_PURPLE: string = '#B8A0D4';
    static readonly ACCENT_PURPLE_LIGHT: string = '#E8DCF4';
    static readonly ACCENT_PURPLE_ULTRA_LIGHT: string = '#F4EEF8';
    static readonly ACCENT_BLUE: string = '#80B8E0';
    static readonly ACCENT_BLUE_LIGHT: string = '#D0E8F8';
    static readonly ACCENT_BLUE_ULTRA_LIGHT: string = '#EAF4FA';
    // 语义色 - 柔和版
    static readonly SUCCESS: string = '#7EC8A0';
    static readonly SUCCESS_LIGHT: string = '#D4F0E0';
    static readonly SUCCESS_ULTRA_LIGHT: string = '#EEF8F0';
    static readonly WARNING: string = '#F0C060';
    static readonly WARNING_LIGHT: string = '#F8E8C0';
    static readonly WARNING_ULTRA_LIGHT: string = '#FCF4E0';
    static readonly DANGER: string = '#E88A8A';
    static readonly DANGER_LIGHT: string = '#F8D0D0';
    static readonly DANGER_ULTRA_LIGHT: string = '#FCE8E8';
    static readonly INFO: string = '#80B8E0';
    static readonly INFO_LIGHT: string = '#D0E8F8';
    // 中性色 - 浅色模式（暖灰调）
    static readonly TEXT_PRIMARY: string = '#3D2C2E';
    static readonly TEXT_SECONDARY: string = '#7A6A6C';
    static readonly TEXT_HINT: string = '#B0A0A2';
    static readonly TEXT_WHITE: string = '#FFFFFF';
    static readonly TEXT_LINK: string = '#C77D9E';
    // 背景色 - 浅色模式（暖白调）
    static readonly BG_GRADIENT_START: string = '#FFF5F0';
    static readonly BG_GRADIENT_END: string = '#FDE8F0';
    static readonly BG_PAGE: string = '#FFF8F5';
    static readonly BG_CARD: string = '#FFFFFF';
    static readonly BG_CARD_HIGHLIGHT: string = '#FFF0F5';
    static readonly BG_SECTION: string = '#FFF5F8';
    static readonly BG_TAG: string = '#F5E8EC';
    // 边框与分割线
    static readonly BORDER: string = '#F0E0E4';
    static readonly BORDER_LIGHT: string = '#F8EEF0';
    static readonly DIVIDER: string = '#F5E8EC';
    // 阴影 - 暖粉色系
    static readonly SHADOW_LIGHT: string = 'rgba(200, 150, 160, 0.10)';
    static readonly SHADOW_MEDIUM: string = 'rgba(200, 150, 160, 0.18)';
    static readonly SHADOW_DARK: string = 'rgba(200, 150, 160, 0.28)';
    static readonly SHADOW_WARM: string = 'rgba(245, 198, 160, 0.15)';
    // 遮罩层
    static readonly OVERLAY: string = 'rgba(0, 0, 0, 0.35)';
    static readonly OVERLAY_LIGHT: string = 'rgba(0, 0, 0, 0.15)';
    // 交互反馈色
    static readonly PRESSED: string = 'rgba(200, 150, 160, 0.08)';
    static readonly HOVER: string = 'rgba(200, 150, 160, 0.04)';
    static readonly FOCUS: string = 'rgba(200, 150, 160, 0.12)';
    static readonly RIPPLE: string = 'rgba(200, 150, 160, 0.20)';
    // 深色模式颜色
    static readonly DARK_BG_PAGE: string = '#1A1A1A';
    static readonly DARK_BG_CARD: string = '#2A2A2A';
    static readonly DARK_BG_SECTION: string = '#333333';
    static readonly DARK_TEXT_PRIMARY: string = '#E8E0E0';
    static readonly DARK_TEXT_SECONDARY: string = '#B0A8A8';
    static readonly DARK_TEXT_HINT: string = '#807878';
    static readonly DARK_BORDER: string = '#3A3A3A';
    static readonly DARK_DIVIDER: string = '#353535';
    static readonly DARK_GRADIENT_START: string = '#2A1A1A';
    static readonly DARK_GRADIENT_END: string = '#1A1A2A';
}
// ===== 圆角 - 更圆润 =====
export class RADIUS {
    static readonly XS: number = 6;
    static readonly SM: number = 10;
    static readonly MD: number = 14;
    static readonly LG: number = 18;
    static readonly XL: number = 22;
    static readonly XXL: number = 30;
    static readonly FULL: number = 1000;
}
// ===== 间距 =====
export class SPACING {
    static readonly XS: number = 4;
    static readonly SM: number = 8;
    static readonly MD: number = 12;
    static readonly LG: number = 16;
    static readonly XL: number = 20;
    static readonly XXL: number = 24;
    static readonly XXXL: number = 32;
    static readonly XXXXL: number = 40;
}
// ===== 字体大小 =====
export class FONT_SIZE {
    static readonly TINY: number = 10;
    static readonly SMALL: number = 12;
    static readonly BODY: number = 14;
    static readonly BODY_LG: number = 15;
    static readonly SUBTITLE: number = 16;
    static readonly TITLE: number = 18;
    static readonly TITLE_LG: number = 20;
    static readonly HEADER: number = 22;
    static readonly LARGE: number = 24;
    static readonly XLARGE: number = 28;
    static readonly HUGE: number = 32;
    static readonly MASSIVE: number = 40;
}
// ===== 字体粗细 =====
export class FONT_WEIGHT {
    static readonly REGULAR: number = FontWeight.Regular;
    static readonly MEDIUM: number = FontWeight.Medium;
    static readonly BOLD: number = FontWeight.Bold;
}
// ===== 动画 =====
export class ANIMATION {
    static readonly DURATION_FAST: number = 200;
    static readonly DURATION_NORMAL: number = 350;
    static readonly DURATION_SLOW: number = 500;
    static readonly CURVE_SMOOTH: Curve = Curve.Smooth;
    static readonly CURVE_FRICTION: Curve = Curve.Friction;
    static readonly CURVE_SHARP: Curve = Curve.Sharp;
    static readonly CURVE_EMPHASIZED: Curve = Curve.FastOutLinearIn;
}
// ===== 动效预设 =====
// 动效配置接口
export interface MotionConfig {
    duration: number;
    curve: Curve;
}
export class MOTION {
    // 淡入
    static readonly FADE_IN: MotionConfig = {
        duration: ANIMATION.DURATION_NORMAL,
        curve: ANIMATION.CURVE_SMOOTH
    };
    // 上滑淡入
    static readonly SLIDE_UP: MotionConfig = {
        duration: ANIMATION.DURATION_SLOW,
        curve: ANIMATION.CURVE_EMPHASIZED
    };
    // 缩放弹入
    static readonly SCALE_IN: MotionConfig = {
        duration: ANIMATION.DURATION_NORMAL,
        curve: ANIMATION.CURVE_FRICTION
    };
    // 卡片展开
    static readonly EXPAND: MotionConfig = {
        duration: ANIMATION.DURATION_SLOW,
        curve: ANIMATION.CURVE_SMOOTH
    };
}
// ===== 卡片阴影预设 =====
export class CARD_SHADOW {
    static readonly LIGHT_RADIUS: number = 8;
    static readonly LIGHT_COLOR: string = COLORS.SHADOW_LIGHT;
    static readonly MEDIUM_RADIUS: number = 12;
    static readonly MEDIUM_COLOR: string = COLORS.SHADOW_MEDIUM;
    static readonly WARM_RADIUS: number = 10;
    static readonly WARM_COLOR: string = COLORS.SHADOW_WARM;
}
// ===== 按钮样式预设 =====
export class BUTTON_STYLE {
    static readonly PRIMARY_HEIGHT: number = 52;
    static readonly SECONDARY_HEIGHT: number = 44;
    static readonly SMALL_HEIGHT: number = 36;
    static readonly PRIMARY_RADIUS: number = RADIUS.XXL;
    static readonly TAG_RADIUS: number = RADIUS.FULL;
}
// ===== 渐变预设 =====
// 渐变配置接口
export interface GradientConfig {
    direction: GradientDirection;
    colors: [
        string,
        number
    ][];
}
export class GRADIENT {
    static readonly PAGE_BG: GradientConfig = {
        direction: GradientDirection.Bottom,
        colors: [[COLORS.BG_GRADIENT_START, 0] as [
                string,
                number
            ], [COLORS.BG_GRADIENT_END, 1] as [
                string,
                number
            ]]
    };
    static readonly CARD_HEADER: GradientConfig = {
        direction: GradientDirection.Right,
        colors: [[COLORS.PRIMARY_ULTRA_LIGHT, 0] as [
                string,
                number
            ], [COLORS.BG_CARD, 1] as [
                string,
                number
            ]]
    };
    static readonly SUCCESS_BADGE: GradientConfig = {
        direction: GradientDirection.Right,
        colors: [[COLORS.ACCENT_GREEN_LIGHT, 0] as [
                string,
                number
            ], [COLORS.ACCENT_GREEN_ULTRA_LIGHT, 1] as [
                string,
                number
            ]]
    };
    static readonly WARNING_BADGE: GradientConfig = {
        direction: GradientDirection.Right,
        colors: [[COLORS.WARNING_LIGHT, 0] as [
                string,
                number
            ], [COLORS.WARNING_ULTRA_LIGHT, 1] as [
                string,
                number
            ]]
    };
    static readonly DANGER_BADGE: GradientConfig = {
        direction: GradientDirection.Right,
        colors: [[COLORS.DANGER_LIGHT, 0] as [
                string,
                number
            ], [COLORS.DANGER_ULTRA_LIGHT, 1] as [
                string,
                number
            ]]
    };
}
// ===== 营养进度颜色 =====
class NutrientColorEntry {
    key: string = '';
    value: string = '';
}
const nutrientColorEntries: NutrientColorEntry[] = [
    { key: '钠', value: COLORS.DANGER },
    { key: '糖', value: COLORS.WARNING },
    { key: '热量', value: COLORS.ACCENT_BLUE },
    { key: '脂肪', value: COLORS.PRIMARY },
    { key: '蛋白质', value: COLORS.SUCCESS },
    { key: '碳水', value: COLORS.ACCENT_PURPLE },
];
export function getNutrientColor(label: string): string {
    for (const entry of nutrientColorEntries) {
        if (entry.key === label) {
            return entry.value;
        }
    }
    return COLORS.PRIMARY;
}
// ===== 适配等级颜色 =====
class AdaptLevelEntry {
    key: string = '';
    value: string = '';
}
const adaptLevelEntries: AdaptLevelEntry[] = [
    { key: '推荐', value: COLORS.SUCCESS },
    { key: '适量', value: COLORS.ACCENT_BLUE },
    { key: '谨慎', value: COLORS.WARNING },
    { key: '避免', value: COLORS.DANGER },
    { key: 'AVOID', value: COLORS.DANGER },
    { key: 'CAUTION', value: COLORS.WARNING },
    { key: 'MODERATE', value: COLORS.ACCENT_BLUE },
    { key: 'GOOD', value: COLORS.SUCCESS },
];
export function getAdaptLevelColor(level: string): string {
    for (const entry of adaptLevelEntries) {
        if (entry.key === level) {
            return entry.value;
        }
    }
    return COLORS.TEXT_SECONDARY;
}
// ===== 健康评分颜色 =====
export function getScoreColor(score: number): string {
    if (score >= 80)
        return COLORS.SUCCESS;
    if (score >= 60)
        return COLORS.WARNING;
    return COLORS.DANGER;
}
// ===== 获取深色模式颜色 =====
export function getDarkColor(isDark: boolean, lightColor: string, darkColor: string): string {
    return isDark ? darkColor : lightColor;
}
// ===== 阴影样式 =====
class ShadowStyle {
    radius: number = 0;
    color: string = '';
    offsetX: number = 0;
    offsetY: number = 0;
}
// ===== 卡片样式 =====
class CardStyle {
    backgroundColor: string = '';
    borderRadius: number = 0;
    shadow: ShadowStyle = new ShadowStyle();
}
// ===== 标签样式 =====
class TagStyle {
    backgroundColor: string = '';
    borderRadius: number = 0;
    paddingLeft: number = 0;
    paddingRight: number = 0;
    paddingTop: number = 0;
    paddingBottom: number = 0;
}
// ===== 通用卡片样式 =====
export function cardStyle(bgColor?: string): CardStyle {
    const shadow = new ShadowStyle();
    shadow.radius = 8;
    shadow.color = COLORS.SHADOW_LIGHT;
    shadow.offsetX = 0;
    shadow.offsetY = 2;
    const style = new CardStyle();
    style.backgroundColor = bgColor || COLORS.BG_CARD;
    style.borderRadius = RADIUS.LG;
    style.shadow = shadow;
    return style;
}
// ===== 通用标签样式 =====
export function tagStyle(bgColor: string, textColor: string): TagStyle {
    const style = new TagStyle();
    style.backgroundColor = bgColor;
    style.borderRadius = RADIUS.FULL;
    style.paddingLeft = SPACING.MD;
    style.paddingRight = SPACING.MD;
    style.paddingTop = SPACING.XS;
    style.paddingBottom = SPACING.XS;
    return style;
}
