interface FoodSubmissionRequest {
  foodName: string;
  barcode?: string;
  brand?: string;
  ingredients?: string;
  nutritionPer100g?: {
    calories?: number;
    fat?: number;
    sugar?: number;
    sodium?: number;
    protein?: number;
    fiber?: number;
  };
  allergenHints?: string[];
  submittedBy: string;
  imageUrls?: string[];
}

interface FoodSubmissionResponse {
  success: boolean;
  submissionId: string;
  status: 'pending_review' | 'auto_approved' | 'rejected';
  message: string;
}

export const handler = async (
  event: { body?: string },
  context: Record<string, Object>
): Promise<FoodSubmissionResponse> => {
  const req: FoodSubmissionRequest = typeof event.body === 'string'
    ? JSON.parse(event.body) : (event.body ?? event) as unknown as FoodSubmissionRequest;

  if (!req.foodName || req.foodName.trim().length === 0) {
    return {
      success: false,
      submissionId: '',
      status: 'rejected',
      message: '食品名称不能为空'
    };
  }

  const submissionId = `sub_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

  // 基础验证通过，进入审核流程
  // 生产环境：写入 CloudDB FoodSubmission 集合，触发审核工作流
  // 高置信度数据（有条码+营养成分完整）可 auto_approved
  const hasBarcode = !!req.barcode && req.barcode.length > 0;
  const hasNutrition = !!req.nutritionPer100g && !!req.nutritionPer100g.calories;
  const status: FoodSubmissionResponse['status'] = (hasBarcode && hasNutrition)
    ? 'auto_approved' : 'pending_review';

  return {
    success: true,
    submissionId,
    status,
    message: status === 'auto_approved'
      ? '数据完整，已自动审核通过'
      : '已提交，等待人工审核'
  };
};
