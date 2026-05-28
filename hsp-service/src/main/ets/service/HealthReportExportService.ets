import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { HuaweiCloudBackend } from './HuaweiCloudBackend';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'HealthReportExportService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface HealthReportRequest {
  memberId: string;
  memberName: string;
  dateRange: { start: string; end: string };
  includeNutritionTrend: boolean;
  includeAllergenHistory: boolean;
  includeRiskPrediction: boolean;
}

export interface HealthReportResult {
  pdfUrl: string;
  localPath: string;
  summary: string;
  generatedAt: number;
}

export class HealthReportExportService {
  private static instance: HealthReportExportService | null = null;

  static getInstance(): HealthReportExportService {
    if (!HealthReportExportService.instance) {
      HealthReportExportService.instance = new HealthReportExportService();
    }
    return HealthReportExportService.instance;
  }

  async generateAndExport(
    context: common.Context,
    request: HealthReportRequest
  ): Promise<HealthReportResult | null> {
    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Generating health report for %{public}s',
        request.memberId.substring(0, 4) + '***');

      const reportData = await this.collectReportData(request);
      const pdfContent = this.renderPdfContent(reportData);
      const localPath = await this.saveToLocal(context, pdfContent, request.memberId);
      const cloudUrl = await this.uploadToCloud(request.memberId, pdfContent);

      return {
        pdfUrl: cloudUrl,
        localPath: localPath,
        summary: reportData.summary,
        generatedAt: Date.now()
      };
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'generateAndExport failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  async shareWithDoctor(report: HealthReportResult, doctorEmail: string): Promise<boolean> {
    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Sharing report with doctor: %{public}s', doctorEmail);
      return true;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'shareWithDoctor failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  private async collectReportData(request: HealthReportRequest): Promise<{
    summary: string;
    nutritionData: string;
    allergenData: string;
    riskData: string;
  }> {
    return {
      summary: `${request.memberName} 健康档案报告 (${request.dateRange.start}~${request.dateRange.end})`,
      nutritionData: request.includeNutritionTrend ? '营养趋势数据' : '',
      allergenData: request.includeAllergenHistory ? '过敏原历史数据' : '',
      riskData: request.includeRiskPrediction ? '健康风险预测数据' : ''
    };
  }

  private renderPdfContent(data: {
    summary: string;
    nutritionData: string;
    allergenData: string;
    riskData: string;
  }): string {
    return [
      '=== 健康档案报告 ===',
      data.summary,
      '---',
      data.nutritionData,
      data.allergenData,
      data.riskData,
      '---',
      `生成时间: ${new Date().toISOString()}`,
      '本报告由家庭食品适配助手自动生成，仅供健康参考，不作为医学诊断依据。'
    ].join('\n');
  }

  private async saveToLocal(
    context: common.Context,
    content: string,
    memberId: string
  ): Promise<string> {
    const dir = context.filesDir + '/health_reports/';
    try {
      fileIo.mkdirSync(dir, true);
    } catch (_e) {
      // 目录可能已存在
    }
    const fileName = `report_${memberId}_${Date.now()}.txt`;
    const filePath = dir + fileName;
    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    fileIo.writeSync(file.fd, content);
    fileIo.closeSync(file);
    return filePath;
  }

  private async uploadToCloud(memberId: string, content: string): Promise<string> {
    try {
      const backend = HuaweiCloudBackend.getInstance();
      const result = await backend.request({
        path: `/api/reports/${memberId}`,
        method: 'POST',
        extraData: content
      });
      return (result as Record<string, Object>)?.['url'] as string ?? '';
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Cloud upload failed: %{public}s', JSON.stringify(e));
      return '';
    }
  }
}
