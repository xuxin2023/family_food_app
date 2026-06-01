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
      return { status: ContentSafetyStatus.APPROVED, confidence: 1.0 };
    }
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(this.endpoint, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ text: content })
      });
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        if (result.pass === true) {
          return { status: ContentSafetyStatus.APPROVED, confidence: result.confidence ?? 0.95 };
        } else {
          return {
            status: ContentSafetyStatus.REJECTED,
            reason: result.reason ?? '内容审核未通过',
            confidence: result.confidence ?? 0.95
          };
        }
      }
      return { status: ContentSafetyStatus.ERROR, confidence: 0 };
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Content safety review failed: %{public}s', JSON.stringify(e));
      return { status: ContentSafetyStatus.PENDING, confidence: 0 };
    }
  }
}