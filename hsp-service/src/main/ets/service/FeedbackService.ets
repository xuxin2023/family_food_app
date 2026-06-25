import { HILOG_DOMAIN_DEFAULT, API_CONFIG } from 'hsp_core';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { ConfigManager } from './ConfigManager';
import { http } from '@kit.NetworkKit';

const TAG = 'FeedbackService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface FeedbackSubmission {
  userId: string;
  type: 'bug' | 'feature' | 'complaint' | 'praise' | 'other';
  title: string;
  content: string;
  contact?: string;
  appVersion: string;
  deviceModel: string;
  osVersion: string;
  screenshots?: string[];
}

export interface FeedbackResult {
  success: boolean;
  ticketId: string;
  message: string;
}

export class FeedbackService {
  private static instance: FeedbackService | null = null;

  static getInstance(): FeedbackService {
    if (!FeedbackService.instance) {
      FeedbackService.instance = new FeedbackService();
    }
    return FeedbackService.instance;
  }

  async submitFeedback(submission: FeedbackSubmission, context: common.Context): Promise<FeedbackResult> {
    try {
      const header: Map<string, string> = new Map();
      header.set('Content-Type', 'application/json');
      const options: SecureRequestOptions = {
        url: ConfigManager.getInstance().getFeedbackUrl(),
        method: http.RequestMethod.POST,
        header: header,
        extraData: JSON.stringify(submission),
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response = await SecureHttpClient.getInstance().request(options);
      if (response.responseCode === 200 || response.responseCode === 201) {
        const rawResult: Record<string, Object> = typeof response.result === 'string' ? JSON.parse(response.result) as Record<string, Object> : response.result as Record<string, Object>;
        hilog.info(DOMAIN_ZERO, TAG, 'Feedback submitted, ticket: %{public}s', rawResult.ticketId ?? 'N/A');
        const feedbackResult: FeedbackResult = {
          success: true,
          ticketId: (rawResult.ticketId as string) ?? `FB_${Date.now()}`,
          message: '反馈已提交，感谢您的建议！'
        };
        return feedbackResult;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'Feedback submit failed: %{public}d', response.responseCode);
      const errorResult: FeedbackResult = { success: false, ticketId: '', message: '提交失败，请稍后重试' };
      return errorResult;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Feedback error: %{public}s', JSON.stringify(e));
      const errorResult: FeedbackResult = { success: false, ticketId: '', message: '网络异常，请检查网络后重试' };
      return errorResult;
    }
  }
}
