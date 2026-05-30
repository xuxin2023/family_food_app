interface FoodSafetyAlertRequest {
  alertType: 'recall' | 'contamination' | 'expired_batch' | 'regulatory_warning';
  productName: string;
  brand: string;
  barcode?: string;
  reason: string;
  actionRequired: string;
  sourceUrl?: string;
  region: string;
  targetUserIds?: string[];
}

interface FoodSafetyAlertResponse {
  success: boolean;
  alertId: string;
  notifiedCount: number;
  message: string;
}

export const handler = async (
  event: { body?: string },
  context: Record<string, Object>
): Promise<FoodSafetyAlertResponse> => {
  const req: FoodSafetyAlertRequest = typeof event.body === 'string'
    ? JSON.parse(event.body) : (event.body ?? event) as unknown as FoodSafetyAlertRequest;

  if (!req.productName || req.productName.trim().length === 0) {
    return { success: false, alertId: '', notifiedCount: 0, message: 'productName 不能为空' };
  }

  if (!req.alertType) {
    return { success: false, alertId: '', notifiedCount: 0, message: 'alertType 不能为空' };
  }

  const alertId = `alert_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
  const issuedAt = Date.now();

  // 生产环境：
  // 1. 写入 CloudDB FoodSafetyAlert 集合
  // 2. 查询订阅了 foodSafetyAlert 的用户 Push Token
  //    - 若 targetUserIds 指定，则定向推送
  //    - 否则查询所有 foodSafetyAlert=true 的 PushToken
  // 3. 调用华为 Push Kit 服务端 API 下发推送消息
  //    POST https://push-api.cloud.huawei.com/v2/{appId}/messages:send
  //    Body: {
  //      validate_only: false,
  //      message: {
  //        notification: { title: `食品安全预警: ${req.productName}`, body: req.reason },
  //        android: { urgency: 'HIGH', collapse_key: -1 },
  //        data: JSON.stringify({ type: 'food_safety_alert', alertId, ...req, issuedAt }),
  //        token: [token1, token2, ...]
  //      }
  //    }

  const notifiedCount = 0;

  return {
    success: true,
    alertId,
    notifiedCount,
    message: `食品安全预警已创建，待推送到 ${notifiedCount} 个用户`
  };
};
