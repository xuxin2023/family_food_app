// hsp-core: AppTheme 增强 — 护眼模式(Eye Care)联动
// 新增 EyeCareMode: 蓝光过滤色温调整 + 系统暗色模式联动

import { configuration, common } from '@kit.AbilityKit';

export enum ColorScheme {
  LIGHT = 'light',
  DARK = 'dark',
  EYE_CARE = 'eyeCare',
}

@Observed
export class AppThemeState {
  static readonly INSTANCE = new AppThemeState();
  colorScheme: ColorScheme = ColorScheme.LIGHT;
  eyeCareEnabled: boolean = false;
  eyeCareIntensity: number = 0.5;

  applySystemColorMode(mode: configuration.ColorMode): void {
    if (mode === configuration.ColorMode.COLOR_MODE_DARK) {
      this.colorScheme = ColorScheme.DARK;
    } else {
      this.colorScheme = this.eyeCareEnabled ? ColorScheme.EYE_CARE : ColorScheme.LIGHT;
    }
    this.syncToAppStorage();
  }

  enableEyeCare(enabled: boolean): void {
    this.eyeCareEnabled = enabled;
    if (!enabled) {
      this.colorScheme = ColorScheme.LIGHT;
    } else if (this.colorScheme !== ColorScheme.DARK) {
      this.colorScheme = ColorScheme.EYE_CARE;
    }
    this.syncToAppStorage();
  }

  setEyeCareIntensity(intensity: number): void {
    this.eyeCareIntensity = Math.max(0.1, Math.min(1.0, intensity));
  }

  getEyeCareColorFilter(): string {
    if (!this.eyeCareEnabled || this.colorScheme !== ColorScheme.EYE_CARE) {
      return 'transparent';
    }
    const alpha = (this.eyeCareIntensity * 0.35).toFixed(2);
    return `rgba(255, 220, 180, ${alpha})`;
  }

  getEffectiveColorScheme(): 'light' | 'dark' {
    return this.colorScheme === ColorScheme.DARK ? 'dark' : 'light';
  }

  private syncToAppStorage(): void {
    AppStorage.setOrCreate<boolean>('eyeCareEnabled', this.eyeCareEnabled);
    AppStorage.setOrCreate<number>('eyeCareIntensity', this.eyeCareIntensity);
    AppStorage.setOrCreate<string>('colorScheme', this.colorScheme);
  }
}