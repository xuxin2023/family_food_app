import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const TAG = 'ElderModeManager';
const DOMAIN_ZERO = 0;

export class ElderModeManager {
  private static instance: ElderModeManager | null = null;
  private isEnabled: boolean = false;
  private context: common.Context | null = null;

  static readonly SCALE_NORMAL: number = 1.0;
  static readonly SCALE_ELDER: number = 1.35;
  static readonly MIN_TOUCH_TARGET: number = 48;

  private constructor() {}

  static getInstance(): ElderModeManager {
    if (!ElderModeManager.instance) {
      ElderModeManager.instance = new ElderModeManager();
    }
    return ElderModeManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      const prefs = await preferences.getPreferences(context, 'app_state');
      this.isEnabled = prefs.getSync('elder_mode', false) as boolean;
      hilog.info(DOMAIN_ZERO, TAG, 'Elder mode: %{public}s', this.isEnabled);
    } catch (error) {
      this.isEnabled = false;
    }
  }

  isEnabledMode(): boolean {
    return this.isEnabled;
  }

  async setEnabled(enabled: boolean): Promise<void> {
    this.isEnabled = enabled;
    if (this.context) {
      try {
        const prefs = await preferences.getPreferences(this.context, 'app_state');
        prefs.putSync('elder_mode', enabled);
        await prefs.flush();
        hilog.info(DOMAIN_ZERO, TAG, 'Elder mode set to: %{public}s', enabled);
      } catch (error) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Save elder mode failed: %{public}s', JSON.stringify(error));
      }
    }
  }

  getFontScale(): number {
    return this.isEnabled ? ElderModeManager.SCALE_ELDER : ElderModeManager.SCALE_NORMAL;
  }

  scaleFontSize(baseSize: number): number {
    return Math.round(baseSize * this.getFontScale());
  }

  getTouchTarget(): number {
    return this.isEnabled ? 56 : 44;
  }

  getCardPadding(): number {
    return this.isEnabled ? 24 : 16;
  }

  getLineSpacing(): number {
    return this.isEnabled ? 8 : 4;
  }

  simplifyNavigation(): boolean {
    return this.isEnabled;
  }

  showVoiceButton(): boolean {
    return this.isEnabled;
  }

  getWelcomeText(): string {
    if (this.isEnabled) {
      return '长辈模式已开启，字体更大、操作更简单';
    }
    return '';
  }
}
