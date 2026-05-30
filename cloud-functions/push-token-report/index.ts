interface PushTokenReportRequest {
  pushToken: string;
  bundleName: string;
  platform: string;
  reportedAt: number;
  userId?: string;
}

interface PushTokenReportResponse {
  success: boolean;
  message: string;
}

export const handler = async (
  event: { body?: string },
  context: Record<string, Object>
): Promise<PushTokenReportResponse> => {
  const req: PushTokenReportRequest = typeof event.body === 'string'
    ? JSON.parse(event.body) : (event.body ?? event) as unknown as PushTokenReportRequest;

  if (!req.pushToken || req.pushToken.trim().length === 0) {
    return { success: false, message: 'pushToken 不能为空' };
  }

  if (!req.bundleName || req.bundleName.trim().length === 0) {
    return { success: false, message: 'bundleName 不能为空' };
  }

  // 生产环境：写入 CloudDB PushToken 集合
  // await cloudDb.collection('PushToken').upsert({
  //   bundleName: req.bundleName,
  //   pushToken: req.pushToken,
  //   platform: req.platform,
  //   userId: req.userId ?? '',
  //   updatedAt: Date.now()
  // }, { onConflict: 'merge' });

  return { success: true, message: 'Push Token 上报成功' };
};
