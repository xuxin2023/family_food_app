import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { TIME_INTERVAL_CONFIG, API_TIMEOUT_CONFIG } from '../constants/AppConfig';

const TAG = 'InspectionDataService';
const DOMAIN_ZERO = 0;

const SAMR_API_BASE = 'https://spcjsac.gsxt.gov.cn';

// 工具函数：获取对象所有键
function getObjectKeys(obj: Record<string, Object>): string[] {
  const keys: string[] = [];
  const objKeys = Object.keys(obj);
  for (let i = 0; i < objKeys.length; i++) {
    keys.push(objKeys[i]);
  }
  return keys;
}

// HTTP请求选项
class HttpRequestOption {
  method: http.RequestMethod = http.RequestMethod.GET;
  header: Record<string, string> = {};
  connectTimeout: number = API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS;
  readTimeout: number = API_TIMEOUT_CONFIG.DEFAULT_READ_TIMEOUT_MS;
}

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
      const httpRequest = http.createHttp();
      const url = `${SAMR_API_BASE}/api/inspection?manufacturer=${encodeURIComponent(manufacturer)}`;

      const reqOpts = new HttpRequestOption();
      reqOpts.method = http.RequestMethod.GET;
      const reqHeaders: Record<string, string> = {
        'User-Agent': 'FamilyFoodApp/1.0',
        'Accept': 'application/json'
      };
      reqOpts.header = reqHeaders;

      const response = await httpRequest.request(url, reqOpts);
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

      const reqOpts = new HttpRequestOption();
      reqOpts.method = http.RequestMethod.GET;
      const reqHeaders: Record<string, string> = {
        'User-Agent': 'FamilyFoodApp/1.0',
        'Accept': 'application/json'
      };
      reqOpts.header = reqHeaders;

      const response = await httpRequest.request(url, reqOpts);
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

      const reqOpts = new HttpRequestOption();
      reqOpts.method = http.RequestMethod.GET;
      const reqHeaders: Record<string, string> = {
        'User-Agent': 'FamilyFoodApp/1.0'
      };
      reqOpts.header = reqHeaders;

      const response = await httpRequest.request(url, reqOpts);
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
      const json = JSON.parse(responseBody) as Record<string, Object> | InspectionRecord[];
      if (Array.isArray(json)) {
        return json as InspectionRecord[];
      }
      const jsonObj = json as Record<string, Object>;
      if (jsonObj['data'] && Array.isArray(jsonObj['data'])) {
        return jsonObj['data'] as InspectionRecord[];
      }
      if (jsonObj['records'] && Array.isArray(jsonObj['records'])) {
        return jsonObj['records'] as InspectionRecord[];
      }
      return [];
    } catch (error) {
      return [];
    }
  }

  private buildSummary(records: InspectionRecord[]): InspectionSummary {
    const summary = new InspectionSummaryImpl();
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
    const summary = new InspectionSummaryImpl();
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
        const cacheKeys = getObjectKeys(parsed as Record<string, Object>);
        for (const key of cacheKeys) {
          this.cache.set(key, parsed[key]);
        }
      }
    } catch (e) {
      hilog.warn(0x0000, TAG, 'loadCache failed: %{public}s', JSON.stringify(e));
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
      hilog.warn(0x0000, TAG, 'persistCache failed: %{public}s', JSON.stringify(e));
    }
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
