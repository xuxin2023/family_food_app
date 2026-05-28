// submit-feedback 云函数
// 接收 FeedbackSubmission，生成工单ID，存储到 CloudDB，返回 FeedbackResult

interface FeedbackSubmission {
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

interface FeedbackResult {
  success: boolean;
  ticketId: string;
  message: string;
}

function generateTicketId(): string {
  const ts = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `FB-${ts}-${rand}`;
}

function validateSubmission(data: FeedbackSubmission): string | null {
  if (!data.content || data.content.trim().length === 0) {
    return '反馈内容不能为空';
  }
  if (data.content.length > 2000) {
    return '反馈内容不能超过2000字';
  }
  if (!data.type || !['bug', 'feature', 'complaint', 'praise', 'other'].includes(data.type)) {
    return '无效的反馈类型';
  }
  return null;
}

export const handler = async (event: { body?: string }, context: Record<string, Object>): Promise<FeedbackResult> => {
  try {
    const submission: FeedbackSubmission = typeof event.body === 'string'
      ? JSON.parse(event.body)
      : (event.body ?? event) as unknown as FeedbackSubmission;

    const validationError = validateSubmission(submission);
    if (validationError) {
      return { success: false, ticketId: '', message: validationError };
    }

    const ticketId = generateTicketId();

    // TODO: 存储 CloudDB feedback_tickets 集合
    // const record = {
    //   ticketId,
    //   userId: submission.userId,
    //   type: submission.type,
    //   title: submission.title,
    //   content: submission.content,
    //   contact: submission.contact ?? '',
    //   appVersion: submission.appVersion,
    //   deviceModel: submission.deviceModel,
    //   osVersion: submission.osVersion,
    //   screenshots: submission.screenshots ?? [],
    //   status: 'open',
    //   createdAt: new Date().toISOString(),
    //   updatedAt: new Date().toISOString()
    // };

    return {
      success: true,
      ticketId,
      message: '反馈已提交，感谢您的建议！'
    };
  } catch (e) {
    return {
      success: false,
      ticketId: '',
      message: `处理失败: ${(e as Error).message}`
    };
  }
};
