import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'RsUtil';
const DOMAIN_ZERO = 0x0001;

export class RsUtil {
  static getString(rs: relationalStore.ResultSet, col: string): string {
    try {
      const idx: number = rs.getColumnIndex(col);
      const val: string = rs.getString(idx);
      return val;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(e));
      return '';
    }
  }
  static getLong(rs: relationalStore.ResultSet, col: string): number {
    try {
      const idx: number = rs.getColumnIndex(col);
      const val: number = rs.getLong(idx);
      return val;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(e));
      return 0;
    }
  }
  static getDouble(rs: relationalStore.ResultSet, col: string): number {
    try {
      const idx: number = rs.getColumnIndex(col);
      const val: number = rs.getDouble(idx);
      return val;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(e));
      return 0;
    }
  }
}
