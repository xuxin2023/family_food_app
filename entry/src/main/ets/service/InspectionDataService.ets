import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const TAG = 'InspectionDataService';
const DOMAIN_ZERO = 0;

const SAMR_API_BASE = 'https://spcjsac.gsxt.gov.cn';
const LOCAL_CACHE_KEY = 'inspection_cache';

export interface InspectionRecord {
  productName: string;
  manufacturer: string;
  batchNumber: string;
  inspectionType: string;
  inspectionDate: string;
  result: 'pass' | 'fail' | 'pending';
  unqualifiedItem: string;
  source: string;
  detailUrl: string;
}

export interface InspectionSummary {
  totalChecks: number;
  failCount: number;
  recentFailDate: string;
  failItems: string[];
  lastUpdate: number;
  riskLevel: 'low' | 'medium' | 'high';
}

export class InspectionDataService {
  private context: common.Context | null = null;
  private cache: Map<string, InspectionSummary> = new Map();
  private lastSyncTime: number = 0;
  private syncInterval: number = 24 * 60 * 60 * 1000;

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
      const httpRequest = http.createHttp();
      const url = `${SAMR_API_BASE}/api/inspection?manufacturer=${encodeURIComponent(manufacturer)}`;

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'FamilyFoodApp/1.0',
          'Accept': 'application/json'
        },
        connectTimeout: 10000,
        readTimeout: 10000
      });
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const records = this.parseInspectionResponse(response.result as string);
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
      const httpRequest = http.createHttp();
      const url = `${SAMR_API_BASE}/api/inspection?scNumber=${encodeURIComponent(scNumber)}`;

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'FamilyFoodApp/1.0',
          'Accept': 'application/json'
        },
        connectTimeout: 10000,
        readTimeout: 10000
      });
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const records = this.parseInspectionResponse(response.result as string);
        return this.buildSummary(records);
      }
      return this.emptySummary();
    } catch (error) {
      return this.emptySummary();
    }
  }

  async getRecentFails(limit: number = 20): Promise<InspectionRecord[]> {
    try {
      const httpRequest = http.createHttp();
      const url = `${SAMR_API_BASE}/api/inspection/recent_fails?limit=${limit}`;

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: { 'User-Agent': 'FamilyFoodApp/1.0' },
        connectTimeout: 10000,
        readTimeout: 10000
      });
      httpRequest.destroy();

      if (response.responseCode === 200) {
        return this.parseInspectionResponse(response.result as string);
      }
      return [];
    } catch (error) {
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
      const json = JSON.parse(responseBody);
      if (Array.isArray(json)) {
        return json as InspectionRecord[];
      }
      if (json.data && Array.isArray(json.data)) {
        return json.data as InspectionRecord[];
      }
      if (json.records && Array.isArray(json.records)) {
        return json.records as InspectionRecord[];
      }
      return [];
    } catch (error) {
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
      summary.riskLevel = 'low';
    } else if (summary.failCount <= 1 && summary.totalChecks > 5) {
      summary.riskLevel = 'medium';
    } else {
      summary.riskLevel = 'high';
    }

    return summary;
  }

  private emptySummary(): InspectionSummary {
    return {
      totalChecks: 0,
      failCount: 0,
      recentFailDate: '',
      failItems: [],
      lastUpdate: Date.now(),
      riskLevel: 'low'
    };
  }

  private async loadCache(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'inspection_cache');
      const cacheStr = prefs.getSync('cache', '') as string;
      if (cacheStr.length > 0) {
        const parsed = JSON.parse(cacheStr) as Record<string, InspectionSummary>;
        for (const key of Object.keys(parsed)) {
          this.cache.set(key, parsed[key]);
        }
      }
      this.lastSyncTime = prefs.getSync('last_sync', 0) as number;
    } catch (_) {}
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
    } catch (_) {}
  }
}

class InspectionSummaryImpl implements InspectionSummary {
  totalChecks: number = 0;
  failCount: number = 0;
  recentFailDate: string = '';
  failItems: string[] = [];
  lastUpdate: number = 0;
  riskLevel: 'low' | 'medium' | 'high' = 'low';
}
