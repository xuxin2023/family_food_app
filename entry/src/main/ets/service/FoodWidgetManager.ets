import { formInfo, formBindingData } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences, relationalStore } from '@kit.ArkData';

const TAG = 'FoodWidgetManager';
const DOMAIN_ZERO = 0;

export class FoodWidgetManager {
  static readonly WIDGET_ID_SMALL = 'food_adapt_small';
  static readonly WIDGET_ID_MEDIUM = 'food_adapt_medium';
  static readonly WIDGET_ID_LARGE = 'food_adapt_large';

  async onUpdateForm(formId: string, context: Context): Promise<formBindingData.FormBindingData> {
    try {
      const recentScan = await this.getRecentScanSummary(context);
      const memberCount = await this.getMemberCount(context);

      const smallData = {
        foodName: recentScan.foodName,
        level: recentScan.level,
        levelEmoji: recentScan.levelEmoji,
        lastScanTime: recentScan.timeText
      };

      const mediumData = {
        ...smallData,
        memberCount: memberCount,
        todayScanCount: recentScan.todayCount,
        remainingScans: recentScan.remainingScans,
        sodiumPercent: recentScan.sodiumPercent,
        sugarPercent: recentScan.sugarPercent
      };

      const largeData = {
        ...mediumData,
        caloriePercent: recentScan.caloriePercent,
        fatPercent: recentScan.fatPercent,
        summary: recentScan.summary,
        memberResults: recentScan.memberResults
      };

      const formData = {
        small: smallData,
        medium: mediumData,
        large: largeData,
        updatedAt: new Date().toLocaleTimeString()
      };

      return formBindingData.createFormBindingData(formData);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Update form failed: %{public}s', JSON.stringify(error));
      return formBindingData.createFormBindingData({
        small: { foodName: '暂无扫描', level: '', levelEmoji: '📱', lastScanTime: '' },
        medium: { foodName: '暂无扫描', level: '', memberCount: 0, todayScanCount: 0 },
        large: { foodName: '暂无扫描', level: '', memberCount: 0, summary: '' },
        updatedAt: new Date().toLocaleTimeString()
      });
    }
  }

  private async getRecentScanSummary(context: Context): Promise<ScanSummary> {
    const summary = new ScanSummary();
    try {
      const rdbConfig: relationalStore.StoreConfig = {
        name: 'food_helper.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };
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
    } catch (_) {
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
