// hsp-core: 无障碍合规辅助工具
// 确保自定义组件符合 HarmonyOS 无障碍标准

import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo } from '@kit.BasicServicesKit';


const TAG = 'AccessibilityCompliance';

/** 无障碍属性配置 */
export class AccessibilityConfig {
  /** 组件语义描述 */
  label: string = '';
  /** 组件角色（button / image / text / listitem / tab / switch） */
  role: string = '';
  /** 组件状态描述 */
  stateDescription: string = '';
  /** 是否为装饰性元素（无实际交互意图） */
  isDecorative: boolean = false;
  /** 焦点顺序组名 */
  group: string = '';
  /** 是否为标题 */
  isHeading: boolean = false;
  /** 标题级别 (1-6) */
  headingLevel: number = 1;
  /** 操作语义描述 */
  actionLabel: string = '';
}

/**
 * 无障碍合规辅助工具
 * 提供标准无障碍属性配置，确保屏幕阅读器和辅助功能正常使用
 */
export class AccessibilityCompliance {
  /** 获取标准按钮无障碍配置 */
  static button(label: string, description?: string): AccessibilityConfig {
    const config: AccessibilityConfig = new AccessibilityConfig(
    config.label = label;
    config.role = 'button';
    config.stateDescription = description ?? '';
    config.actionLabel = `点击${label}`;
    return config;
  }

  /** 获取标准图片无障碍配置 */
  static image(label: string, isDecorative: boolean = false): AccessibilityConfig {
    const config: AccessibilityConfig = new AccessibilityConfig(
    config.label = label;
    config.role = 'image';
    config.isDecorative = isDecorative;
    return config;
  }

  /** 获取标准文本无障碍配置 */
  static text(label: string): AccessibilityConfig {
    const config: AccessibilityConfig = new AccessibilityConfig(
    config.label = label;
    config.role = 'text';
    return config;
  }

  /** 获取标题无障碍配置 */
  static heading(label: string, level: number = 1): AccessibilityConfig {
    const config: AccessibilityConfig = new AccessibilityConfig(
    config.label = label;
    config.role = 'text';
    config.isHeading = true;
    config.headingLevel = Math.max(1, Math.min(6, level));
    return config;
  }

  /** 获取列表项无障碍配置 */
  static listItem(label: string, index: number, total: number): AccessibilityConfig {
    const config: AccessibilityConfig = new AccessibilityConfig(
    config.label = label;
    config.role = 'listitem';
    config.stateDescription = `第${index + 1}项，共${total}项`;
    return config;
  }

  /** 获取开关无障碍配置 */
  static toggle(label: string, isOn: boolean): AccessibilityConfig {
    const config: AccessibilityConfig = new AccessibilityConfig(
    config.label = label;
    config.role = 'switch';
    config.stateDescription = isOn ? '已开启' : '已关闭';
    config.actionLabel = isOn ? `关闭${label}` : `开启${label}`;
    return config;
  }

  /** 生成评分/等级的无障碍描述 */
  static scoreLabel(score: number, scoreType: string = '评分'): string {
    return `${scoreType} ${score} 分`;
  }

  /** 生成营养成分的无障碍描述 */
  static nutritionLabel(name: string, value: number, unit: string): string {
    return `${name} ${value} ${unit}`;
  }

  /** 检测系统是否启用了无障碍服务 */
  static isAccessibilityEnabled(): boolean {
    try {
      return deviceInfo.isAccessibilityEnabled;
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      return false;
    }
  }
}

/**
 * 颜色对比度检查器（深色模式兼容）
 * 确保前景色在浅色/深色背景下均有足够对比度
 */
export class ColorContrastChecker {
  /** 检查对比度是否满足 WCAG AA 标准（>=4.5:1 for normal text） */
  static meetsAAStandard(foregroundHex: string, backgroundHex: string): boolean {
    const ratio = ColorContrastChecker.contrastRatio(foregroundHex, backgroundHex);
    return ratio >= 4.5;
  }

  /** 计算对比度 */
  static contrastRatio(hex1: string, hex2: string): number {
    const l1 = ColorContrastChecker.relativeLuminance(hex1);
    const l2 = ColorContrastChecker.relativeLuminance(hex2);
    const lighter = Math.max(l1, l2);
    const darker = Math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /** 获取深色模式下的安全文字颜色 */
  static safeTextColorForDarkMode(bgHex: string): string {
    const ratio = ColorContrastChecker.contrastRatio('#FFFFFF', bgHex);
    return ratio >= 4.5 ? '#FFFFFF' : '#E0E0E0';
  }

  /** 获取浅色模式下的安全文字颜色 */
  static safeTextColorForLightMode(bgHex: string): string {
    const ratio = ColorContrastChecker.contrastRatio('#333333', bgHex);
    return ratio >= 4.5 ? '#333333' : '#1A1A1A';
  }

  private static relativeLuminance(hex: string): number {
    const r = ColorContrastChecker.sRGBToLinear(hex.substring(1, 3));
    const g = ColorContrastChecker.sRGBToLinear(hex.substring(3, 5));
    const b = ColorContrastChecker.sRGBToLinear(hex.substring(5, 7));
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  private static sRGBToLinear(hex2: string): number {
    const v = parseInt(hex2, 16) / 255;
    return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  }
}
