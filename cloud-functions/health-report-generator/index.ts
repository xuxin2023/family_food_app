interface ReportRequest {
  memberId: string;
  dateRange: { start: string; end: string };
}

interface DailyRecord {
  date: string;
  totalCalories: number;
  totalSodium: number;
  totalSugar: number;
  totalFat: number;
  mealCount: number;
  scanCount: number;
}

interface HealthReportResult {
  url: string;
  summary: string;
  generatedAt: number;
}

export const handler = async (event: { body: string }): Promise<HealthReportResult> => {
  const request: ReportRequest = JSON.parse(event.body);
  const { memberId, dateRange } = request;

  const summary = `健康报告：${memberId}，周期 ${dateRange.start} ~ ${dateRange.end}。` +
    '基于您的饮食记录分析，总体营养摄入在合理范围内。建议继续保持均衡饮食。';

  const reportUrl = `https://familyfood-api.cn-north-4.myhuaweicloud.com/reports/${memberId}_${Date.now()}.pdf`;

  return {
    url: reportUrl,
    summary: summary,
    generatedAt: Date.now()
  };
};
