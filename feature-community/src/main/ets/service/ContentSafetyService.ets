import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';

const TAG = 'ContentSafetyService';
const DOMAIN_ZERO = 0x0001;

export enum ContentSafetyStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  ERROR = 'error'
}

export interface ContentSafetyResult {
  status: ContentSafetyStatus;
  reason?: string;
  confidence: number;
}

export class ContentSafetyService {
  private static instance: ContentSafetyService | null = null;
  private endpoint: string = '';

  private constructor() {}

  static getInstance(): ContentSafetyService {
    if (!ContentSafetyService.instance) {
      ContentSafetyService.instance = new ContentSafetyService();
    }
    return ContentSafetyService.instance;
  }

  setEndpoint(endpoint: string): void {
    this.endpoint = endpoint;
  }

  async reviewContent(content: string): Promise<ContentSafetyResult> {
    if (!this.endpoint) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Content safety endpoint not configured, auto-approving');
      const r: ContentSafetyResult = { status: ContentSafetyStatus.APPROVED, confidence: 1.0 };
      return r;
    }
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(this.endpoint, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ text: content })
      });
      if (response.responseCode === 200) {
        const result: Record<string, Object> = JSON.parse(response.result as string) as Record<string, Object>;
        if (result.pass === true) {
          const confidence = typeof result.confidence === 'number' ? result.confidence : 0.95;
          const r2: ContentSafetyResult = { status: ContentSafetyStatus.APPROVED, confidence: confidence };
          return r2;
        } else {
          const reason = typeof result.reason === 'string' ? result.reason : '内容审核未通过';
          const confidence = typeof result.confidence === 'number' ? result.confidence : 0.95;
          return {
            status: ContentSafetyStatus.REJECTED,
            reason: reason,
            confidence: confidence
          };
        }
      }
      const r3: ContentSafetyResult = { status: ContentSafetyStatus.ERROR, confidence: 0 };
      return r3;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Content safety review failed: %{public}s', JSON.stringify(e));
      const r4: ContentSafetyResult = { status: ContentSafetyStatus.PENDING, confidence: 0 };
      return r4;
    }
  }
}