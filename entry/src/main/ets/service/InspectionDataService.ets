import { TIME_INTERVAL_CONFIG, API_TIMEOUT_CONFIG, HILOG_DOMAIN, JsonHelper } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { SecureHttpHelper } from './SecureHttpHelper';

const TAG = 'InspectionDataService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

const SAMR_API_BASE = 'https://spcjsac.gsxt.gov.cn';

export enum InspectionResult {
  PASS = 'pass',
  FAIL = 'fail',
  PENDING = 'pending'
}

export class InspectionRecord {
  productName: string = '';
  manufacturer: string = '';
  batchNumber: string = '';
  inspectionType: string = '';
  inspectionDate: string = '';
  result: InspectionResult = InspectionResult.PENDING;
  unqualifiedItem: string = '';
  source: string = '';
  detailUrl: string = '';
}

export enum RiskLevel {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high'
}

export class InspectionSummary {
  totalChecks: number = 0;
  failCount: number = 0;
  recentFailDate: string = '';
  failItems: string[] = [];
  lastUpdate: number = 0;
  riskLevel: RiskLevel = RiskLevel.LOW;
}

export class InspectionDataService {
  private context: common.Context | null = null;
  private cache: Map<string, InspectionSummary> = new Map();
  private syncInterval: number = TIME_INTERVAL_CONFIG.INSPECTION_SYNC_INTERVAL_MS;

  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.loadCache();
  }

  async queryByManufacturer(manufacturer: string): Promise<InspectionSummary> {
    if (manufacturer.length === 0) {
      return this.emptySummary();
    }

    const cached = this.cache.get(manufacturer);
    if (cached && (Date.now() - cached.lastUpdate) < this.syncInterval) {
      return cached;
    }

    try {
      const url = `${SAMR_API_BASE}/api/inspection?manufacturer=${encodeURIComponent(manufacturer)}`;

      const reqHeader = new Map<string, string>();
      reqHeader.set('User-Agent', 'FamilyFoodApp/1.0');
      reqHeader.set('Accept', 'application/json');

      const resp = await SecureHttpHelper.get(url, reqHeader, API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS);

      if (resp.responseCode === 200 && resp.data !== null) {
        const records = this.parseInspectionResponse(JSON.stringify(resp.data));
        const summary = this.buildSummary(records);
        this.cache.set(manufacturer, summary);
        await this.persistCache();
        return summary;
      }

      return cached || this.emptySummary();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Query inspection failed: %{public}s', JSON.stringify(error));
      return cached || this.emptySummary();
    }
  }

  async queryByScNumber(scNumber: string): Promise<InspectionSummary> {
    if (scNumber.length === 0) {
      return this.emptySummary();
    }

    try {
      const url = `${SAMR_API_BASE}/api/inspection?scNumber=${encodeURIComponent(scNumber)}`;

      const reqHeader = new Map<string, string>();
      reqHeader.set('User-Agent', 'FamilyFoodApp/1.0');
      reqHeader.set('Accept', 'application/json');

      const resp = await SecureHttpHelper.get(url, reqHeader, API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS);

      if (resp.responseCode === 200 && resp.data !== null) {
        const records = this.parseInspectionResponse(JSON.stringify(resp.data));
        return this.buildSummary(records);
      }
      return this.emptySummary();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'queryByScNumber failed: %{public}s', JSON.stringify(error));
      return this.emptySummary();
    }
  }

  async getRecentFails(limit: number = 20): Promise<InspectionRecord[]> {
    try {
      const url = `${SAMR_API_BASE}/api/inspection/recent_fails?limit=${limit}`;

      const reqHeader = new Map<string, string>();
      reqHeader.set('User-Agent', 'FamilyFoodApp/1.0');

      const resp = await SecureHttpHelper.get(url, reqHeader, API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS);

      if (resp.responseCode === 200 && resp.data !== null) {
        return this.parseInspectionResponse(JSON.stringify(resp.data));
      }
      return [];
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getRecentFails failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  getPublicQueryUrl(scNumber: string): string {
    return `https://zwfw.samr.gov.cn/needSearch?scNumber=${encodeURIComponent(scNumber)}`;
  }

  getSpotCheckUrl(keyword: string): string {
    return `https://spcjsac.gsxt.gov.cn/?keyword=${encodeURIComponent(keyword)}`;
  }

  private parseInspectionResponse(responseBody: string): InspectionRecord[] {
    try {
      const jsonRaw = JSON.parse(responseBody) as Record<string, Object> | InspectionRecord[];
      if (Array.isArray(jsonRaw)) {
        return jsonRaw as InspectionRecord[];
      }
      const jsonObjRaw = jsonRaw as Record<string, Object>;
      const jsonObj = JsonHelper.recordToMap(jsonObjRaw);
      if (jsonObj.get('data') && Array.isArray(jsonObj.get('data'))) {
        return jsonObj.get('data') as InspectionRecord[];
      }
      if (jsonObj.get('records') && Array.isArray(jsonObj.get('records'))) {
        return jsonObj.get('records') as InspectionRecord[];
      }
      return [];
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'queryByKeyword failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  private buildSummary(records: InspectionRecord[]): InspectionSummary {
    const summary = new InspectionSummary();
    summary.totalChecks = records.length;
    summary.failCount = records.filter(r => r.result === 'fail').length;

    const failRecords = records.filter(r => r.result === 'fail');
    summary.failItems = failRecords.map(r => r.unqualifiedItem).filter(s => s.length > 0);

    if (failRecords.length > 0) {
      summary.recentFailDate = failRecords[0].inspectionDate;
    }

    summary.lastUpdate = Date.now();

    if (summary.failCount === 0) {
      summary.riskLevel = RiskLevel.LOW;
    } else if (summary.failCount <= 1 && summary.totalChecks > 5) {
      summary.riskLevel = RiskLevel.MEDIUM;
    } else {
      summary.riskLevel = RiskLevel.HIGH;
    }

    return summary;
  }

  private emptySummary(): InspectionSummary {
    const summary = new InspectionSummary();
    summary.totalChecks = 0;
    summary.failCount = 0;
    summary.recentFailDate = '';
    summary.failItems = [];
    summary.lastUpdate = Date.now();
    summary.riskLevel = 'low';
    return summary;
  }

  private async loadCache(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'inspection_cache');
      const cacheStr = prefs.getSync('cache', '') as string;
      if (cacheStr.length > 0) {
        const parsed = JSON.parse(cacheStr) as Record<string, InspectionSummary>;
        const cacheKeys = JsonHelper.recordKeys(parsed);
        for (const key of cacheKeys) {
          this.cache.set(key, parsed[key]);
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadCache failed: %{public}s', JSON.stringify(e));
    }
  }

  private async persistCache(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'inspection_cache');
      const cacheObj: Record<string, InspectionSummary> = {};
      this.cache.forEach((v, k) => { cacheObj[k] = v; });
      prefs.putSync('cache', JSON.stringify(cacheObj));
      prefs.putSync('last_sync', Date.now());
      await prefs.flush();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'persistCache failed: %{public}s', JSON.stringify(e));
    }
  }
}
