import { HILOG_DOMAIN_DEFAULT, DB_NAME } from 'hsp_core';
import { formBindingData } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences, relationalStore } from '@kit.ArkData';

const TAG = 'FoodWidgetManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

// 小卡片数据类
class SmallWidgetData {
  foodName: string = '';
  level: string = '';
  levelEmoji: string = '';
  lastScanTime: string = '';
}

// 中卡片数据类
class MediumWidgetData extends SmallWidgetData {
  memberCount: number = 0;
  todayScanCount: number = 0;
  remainingScans: number = 0;
  sodiumPercent: number = 0;
  sugarPercent: number = 0;
}

// 大卡片数据类
class LargeWidgetData extends MediumWidgetData {
  caloriePercent: number = 0;
  fatPercent: number = 0;
  summary: string = '';
  memberResults: string[] = [];
}

// 表单数据类
class WidgetFormData {
  small: SmallWidgetData = new SmallWidgetData();
  medium: MediumWidgetData = new MediumWidgetData();
  large: LargeWidgetData = new LargeWidgetData();
  updatedAt: string = '';
}

export class FoodWidgetManager {
  static readonly WIDGET_ID_SMALL = 'food_adapt_small';
  static readonly WIDGET_ID_MEDIUM = 'food_adapt_medium';
  static readonly WIDGET_ID_LARGE = 'food_adapt_large';

  async onUpdateForm(formId: string, context: Context): Promise<formBindingData.FormBindingData> {
    try {
      const recentScan = await this.getRecentScanSummary(context);
      const memberCount = await this.getMemberCount(context);

      const smallData = new SmallWidgetData();
      smallData.foodName = recentScan.foodName;
      smallData.level = recentScan.level;
      smallData.levelEmoji = recentScan.levelEmoji;
      smallData.lastScanTime = recentScan.timeText;

      const mediumData = new MediumWidgetData();
      mediumData.foodName = recentScan.foodName;
      mediumData.level = recentScan.level;
      mediumData.levelEmoji = recentScan.levelEmoji;
      mediumData.lastScanTime = recentScan.timeText;
      mediumData.memberCount = memberCount;
      mediumData.todayScanCount = recentScan.todayCount;
      mediumData.remainingScans = recentScan.remainingScans;
      mediumData.sodiumPercent = recentScan.sodiumPercent;
      mediumData.sugarPercent = recentScan.sugarPercent;

      const largeData = new LargeWidgetData();
      largeData.foodName = recentScan.foodName;
      largeData.level = recentScan.level;
      largeData.levelEmoji = recentScan.levelEmoji;
      largeData.lastScanTime = recentScan.timeText;
      largeData.memberCount = memberCount;
      largeData.todayScanCount = recentScan.todayCount;
      largeData.remainingScans = recentScan.remainingScans;
      largeData.sodiumPercent = recentScan.sodiumPercent;
      largeData.sugarPercent = recentScan.sugarPercent;
      largeData.caloriePercent = recentScan.caloriePercent;
      largeData.fatPercent = recentScan.fatPercent;
      largeData.summary = recentScan.summary;
      largeData.memberResults = recentScan.memberResults;

      const formData = new WidgetFormData();
      formData.small = smallData;
      formData.medium = mediumData;
      formData.large = largeData;
      formData.updatedAt = new Date().toLocaleTimeString();

      return formBindingData.createFormBindingData(formData);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Update form failed: %{public}s', JSON.stringify(error));

      const fallbackSmall = new SmallWidgetData();
      fallbackSmall.foodName = '暂无扫描';
      fallbackSmall.levelEmoji = '📱';
      fallbackSmall.lastScanTime = '';

      const fallbackMedium = new MediumWidgetData();
      fallbackMedium.foodName = '暂无扫描';
      fallbackMedium.levelEmoji = '📱';
      fallbackMedium.lastScanTime = '';

      const fallbackLarge = new LargeWidgetData();
      fallbackLarge.foodName = '暂无扫描';
      fallbackLarge.levelEmoji = '📱';
      fallbackLarge.lastScanTime = '';

      const fallbackData = new WidgetFormData();
      fallbackData.small = fallbackSmall;
      fallbackData.medium = fallbackMedium;
      fallbackData.large = fallbackLarge;
      fallbackData.updatedAt = new Date().toLocaleTimeString();

      return formBindingData.createFormBindingData(fallbackData);
    }
  }

  private async getRecentScanSummary(context: Context): Promise<ScanSummary> {
    const summary = new ScanSummary();
    try {
      const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
      const store = await relationalStore.getRdbStore(context, rdbConfig);
      const resultSet = await store.querySql(
        'SELECT food_name, level FROM scan_history ORDER BY scanned_at DESC LIMIT 1'
      );
      if (resultSet.goToFirstRow()) {
        summary.foodName = resultSet.getString(0) || '暂无扫描';
        summary.level = resultSet.getString(1) || '';
        summary.levelEmoji = this.getLevelEmoji(summary.level);
      }
      resultSet.close();

      const countResult = await store.querySql(
        "SELECT COUNT(*) FROM scan_history WHERE date(scanned_at/1000,'unixepoch') = date('now')"
      );
      if (countResult.goToFirstRow()) {
        summary.todayCount = countResult.getLong(0);
      }
      countResult.close();
      store.close();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Query recent scan failed: %{public}s', JSON.stringify(error));
    }

    const now = new Date();
    summary.timeText = `${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;
    summary.remainingScans = Math.max(0, 3 - summary.todayCount);
    return summary;
  }

  private async getMemberCount(context: Context): Promise<number> {
    try {
      const prefs = await preferences.getPreferences(context, 'app_state');
      return prefs.getSync('member_count', 4) as number;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getCachedMemberCount failed: %{public}s', JSON.stringify(e));
      return 4;
    }
  }

  private getLevelEmoji(level: string): string {
    if (level.includes('适合')) return '✅';
    if (level.includes('少量')) return '🟡';
    if (level.includes('谨慎')) return '⚠️';
    if (level.includes('避免')) return '🚫';
    return '📱';
  }
}

class ScanSummary {
  foodName: string = '暂无扫描';
  level: string = '';
  levelEmoji: string = '📱';
  timeText: string = '';
  todayCount: number = 0;
  remainingScans: number = 3;
  sodiumPercent: number = 0;
  sugarPercent: number = 0;
  caloriePercent: number = 0;
  fatPercent: number = 0;
  summary: string = '';
  memberResults: string[] = [];
}