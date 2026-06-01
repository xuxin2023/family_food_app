import { hilog } from '@kit.PerformanceAnalysisKit';
import { accessibility } from '@kit.AccessibilityKit';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'AccessibilityManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class A11yNode {
  id: string = '';
  accessibilityText: string = '';
  accessibilityLevel: string = 'auto';
  accessibilityGroup: boolean = false;
  accessibilityDescription: string = '';
}

export class AccessibilityManager {
  private static instance: AccessibilityManager | null = null;
  private context: common.Context | null = null;
  private isScreenReaderActive: boolean = false;
  private statusChangeCallback: ((isActive: boolean) => void) | null = null;

  static getInstance(): AccessibilityManager {
    if (!AccessibilityManager.instance) {
      AccessibilityManager.instance = new AccessibilityManager();
    }
    return AccessibilityManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.checkScreenReaderStatus();
    this.registerStatusListener();
    hilog.info(DOMAIN_ZERO, TAG, 'screenReader: %{public}s', this.isScreenReaderActive);
  }

  private async checkScreenReaderStatus(): Promise<void> {
    if (!this.context) return;
    try {
      const abilityLists: accessibility.AccessibilityExtensionInfo[] =
        await accessibility.getAccessibilityExtensionList(
          'spoken',
          'enable'
        );
      this.isScreenReaderActive = abilityLists !== undefined && abilityLists.length > 0;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'checkScreenReader failed: %{public}s', JSON.stringify(e));
      this.isScreenReaderActive = false;
    }
  }

  private registerStatusListener(): void {
    try {
      accessibility.on('accessibilityEnableChange', (state: boolean) => {
        const prev = this.isScreenReaderActive;
        this.isScreenReaderActive = state;
        if (prev !== state) {
          hilog.info(DOMAIN_ZERO, TAG, 'screenReader status changed: %{public}s', state);
          if (this.statusChangeCallback) {
            this.statusChangeCallback(state);
          }
        }
      });
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'registerStatusListener failed: %{public}s', JSON.stringify(e));
    }
  }

  onScreenReaderStatusChange(callback: (isActive: boolean) => void): void {
    this.statusChangeCallback = callback;
  }

  isScreenReaderEnabled(): boolean {
    return this.isScreenReaderActive;
  }

  getScreenReaderActive(): boolean {
    return this.isScreenReaderActive;
  }

  announceForAccessibility(message: string): void {
    if (!this.isScreenReaderActive || message.length === 0) return;
    try {
      accessibility.sendEvent({
        type: 'announceForAccessibility',
        bundleName: this.context?.applicationInfo?.bundleName ?? '',
        eventType: 'touchEnd',
        text: message
      });
      hilog.debug(DOMAIN_ZERO, TAG, 'announceForAccessibility: %{public}s', message);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'announceForAccessibility failed: %{public}s', JSON.stringify(e));
    }
  }

  getRecommendedMinTouchTarget(): number {
    return this.isScreenReaderActive ? 56 : 48;
  }

  buildA11yText(parts: (string | number | null | undefined)[]): string {
    return parts.filter(p => p != null && p !== '').map(String).join('，');
  }

  buildNutritionA11y(label: string, value: number, unit: string, budget?: number): string {
    let text = `${label}：${value}${unit}`;
    if (budget !== undefined && budget > 0) {
      const percent = Math.round((value / budget) * 100);
      text += `，占每日预算${percent}%`;
    }
    return text;
  }

  buildFoodAdaptA11y(memberName: string, level: string, reason: string): string {
    return `${memberName}适配等级${level}，${reason}`;
  }

  buildChartA11y(title: string, dataPoints: number, trend?: string): string {
    let text = `${title}图表，共${dataPoints}个数据点`;
    if (trend) {
      text += `，趋势${trend}`;
    }
    return text;
  }

  buildMemberCardA11y(name: string, ageGroup: string, healthGoal: string, tier: string): string {
    return `${name}，${ageGroup}，健康目标${healthGoal}，会员${tier}`;
  }

  buildScanResultA11y(foodName: string, nutriScore: number, memberCount: number): string {
    return `扫描结果：${foodName}，营养评分${nutriScore}分，${memberCount}位家庭成员适配结果`;
  }
}
