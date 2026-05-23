// LocaleManager.ets
// 多语言运行时切换管理器 — 支持中/英/日/韩等语言动态切换
// 基于 @kit.LocalizationKit + AppStorage 联动刷新

import { i18n } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'LocaleManager';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export const SUPPORTED_LOCALES: string[] = [
  'zh-Hans',
  'en',
  'ja',
  'ko'
];

export const LOCALE_DISPLAY_NAMES: Map<string, string> = new Map([
  ['zh-Hans', '简体中文'],
  ['en', 'English'],
  ['ja', '日本語'],
  ['ko', '한국어']
]);

export class LocaleInfo {
  code: string = '';
  name: string = '';
  isCurrent: boolean = false;
}

export class LocaleManager {
  private static instance: LocaleManager | null = null;
  private currentLocale: string = 'zh-Hans';

  static getInstance(): LocaleManager {
    if (!LocaleManager.instance) {
      LocaleManager.instance = new LocaleManager();
    }
    return LocaleManager.instance;
  }

  init(): void {
    const systemLocale: string = i18n.System.getAppPreferredLanguage();
    if (SUPPORTED_LOCALES.includes(systemLocale)) {
      this.currentLocale = systemLocale;
    } else {
      const lang: string = systemLocale.split('-')[0];
      const matched: string | undefined = SUPPORTED_LOCALES.find((l: string): boolean => l.startsWith(lang));
      this.currentLocale = matched ?? 'zh-Hans';
    }
    AppStorage.setOrCreate('currentLocale', this.currentLocale);
    hilog.info(DOMAIN_ZERO, TAG, 'Locale init: %{public}s', this.currentLocale);
  }

  getCurrentLocale(): string {
    return this.currentLocale;
  }

  switchLocale(locale: string): boolean {
    if (!SUPPORTED_LOCALES.includes(locale)) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Unsupported locale: %{public}s', locale);
      return false;
    }

    try {
      i18n.System.setAppPreferredLanguage(locale);
      this.currentLocale = locale;
      AppStorage.setOrCreate('currentLocale', locale);
      AppStorage.setOrCreate('localeChangedTime', Date.now());
      hilog.info(DOMAIN_ZERO, TAG, 'Locale switched to: %{public}s', locale);
      return true;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Locale switch failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  getLocaleDisplayName(locale: string): string {
    return LOCALE_DISPLAY_NAMES.get(locale) ?? locale;
  }

  isChinese(): boolean {
    return this.currentLocale.startsWith('zh');
  }

  isEnglish(): boolean {
    return this.currentLocale.startsWith('en');
  }

  formatNumber(value: number): string {
    try {
      const fmt: Intl.NumberFormat = new Intl.NumberFormat(this.currentLocale);
      return fmt.format(value);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'formatNumber failed: %{public}s', JSON.stringify(e));
      return String(value);
    }
  }

  formatDate(date: Date, style: string = 'medium'): string {
    try {
      const dateStyleMap: Map<string, string> = new Map();
      dateStyleMap.set('full', 'full');
      dateStyleMap.set('long', 'long');
      dateStyleMap.set('medium', 'medium');
      dateStyleMap.set('short', 'short');
      const dateStyle: string = dateStyleMap.get(style) ?? 'medium';
      const fmt: Intl.DateTimeFormat = new Intl.DateTimeFormat(this.currentLocale, {
        dateStyle: dateStyle as 'full' | 'long' | 'medium' | 'short'
      });
      return fmt.format(date);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'formatDate failed: %{public}s', JSON.stringify(e));
      return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
    }
  }

  getSupportedLocales(): LocaleInfo[] {
    return SUPPORTED_LOCALES.map((code: string): LocaleInfo => {
      const info: LocaleInfo = new LocaleInfo();
      info.code = code;
      info.name = this.getLocaleDisplayName(code);
      info.isCurrent = code === this.currentLocale;
      return info;
    });
  }
}
