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

  static getInstance(): AccessibilityManager {
    if (!AccessibilityManager.instance) {
      AccessibilityManager.instance = new AccessibilityManager();
    }
    return AccessibilityManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.checkScreenReaderStatus();
    hilog.info(DOMAIN_ZERO, TAG, 'screenReader: %{public}s', this.isScreenReaderActive);
  }

  private async checkScreenReaderStatus(): Promise<void> {
    if (!this.context) return;
    try {
      const abilityLists: accessibility.AccessibilityAbilityInfo[] =
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

  isScreenReaderEnabled(): boolean {
    return this.isScreenReaderActive;
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
