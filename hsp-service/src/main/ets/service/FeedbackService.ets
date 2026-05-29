import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

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
      const options: SecureRequestOptions = {
        url: 'https://familyfood-api.cn-north-4.myhuaweicloud.com/api/feedback',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(submission),
        connectTimeout: 10000,
        readTimeout: 10000
      };
      const response = await SecureHttpClient.request(options);
      if (response.responseCode === 200 || response.responseCode === 201) {
        const result = typeof response.result === 'string' ? JSON.parse(response.result) : response.result;
        hilog.info(DOMAIN_ZERO, TAG, 'Feedback submitted, ticket: %{public}s', result.ticketId ?? 'N/A');
        return {
          success: true,
          ticketId: result.ticketId ?? `FB_${Date.now()}`,
          message: '反馈已提交，感谢您的建议！'
        };
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'Feedback submit failed: %{public}d', response.responseCode);
      return { success: false, ticketId: '', message: '提交失败，请稍后重试' };
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Feedback error: %{public}s', JSON.stringify(e));
      return { success: false, ticketId: '', message: '网络异常，请检查网络后重试' };
    }
  }
}
