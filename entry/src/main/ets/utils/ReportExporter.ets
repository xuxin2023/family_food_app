// ReportExporter.ets
// 健康报告导出工具 - 将周报/营养数据导出为文本文件

import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WeeklyReport, NutrientComparison, NutrientStatus } from '../engine/WeeklyReportEngine';
import { FamilyProfile, HILOG_DOMAIN, DietRecord } from 'hsp_core';


const TAG = 'ReportExporter';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class ReportExporter {
  static exportWeeklyReportAsText(report: WeeklyReport, profile: FamilyProfile): string {
    const lines: string[] = [];
    lines.push('=== 家庭饮食健康周报 ===');
    lines.push(`成员：${profile.nickname} | 周期：${report.weekRange}`);
    lines.push('');
    lines.push('【本周概要】');
    lines.push(report.summary);
    lines.push('');

    if (report.nutrientComparisons.length > 0) {
      lines.push('【营养素对比（日均/目标）】');
      for (const nc of report.nutrientComparisons) {
        const statusMark = nc.status === NutrientStatus.EXCELLENT || nc.status === NutrientStatus.GOOD ? '✓' : '✗';
        lines.push(`- ${nc.name}：${nc.dailyAvg.toFixed(0)}${nc.unit} / ${nc.target.toFixed(0)}${nc.unit} (${ReportExporter.getStatusLabel(nc.status)} ${statusMark})`);
      }
      lines.push('');
    }

    if (report.highlights.length > 0) {
      lines.push('【本周关注】');
      for (const h of report.highlights) {
        lines.push(`- ${h}`);
      }
      lines.push('');
    }

    if (report.suggestions.length > 0) {
      lines.push('【建议】');
      let idx = 1;
      for (const s of report.suggestions) {
        lines.push(`${idx}. ${s}`);
        idx++;
      }
      lines.push('');
    }

    if (report.buyLess.length > 0 || report.buyMore.length > 0) {
      lines.push('【采购建议】');
      if (report.buyLess.length > 0) {
        lines.push(`- 建议少买：${report.buyLess.join('、')}`);
      }
      if (report.buyMore.length > 0) {
        lines.push(`- 建议增加：${report.buyMore.join('、')}`);
      }
      lines.push('');
    }

    lines.push(`生成时间：${new Date().toLocaleString()}`);
    return lines.join('\n');
  }

  static exportNutritionSummaryAsText(
    nickname: string,
    date: string,
    records: DietRecord[],
    sodiumBudget: number,
    sugarBudget: number,
    calorieBudget: number,
    fatBudget: number
  ): string {
    const lines: string[] = [];
    lines.push('=== 每日营养概览 ===');
    lines.push(`成员：${nickname} | 日期：${date}`);
    lines.push('');

    let totalSodium = 0;
    let totalSugar = 0;
    let totalCalorie = 0;
    let totalFat = 0;
    for (const r of records) {
      totalSodium += r.sodiumIntake;
      totalSugar += r.sugarIntake;
      totalCalorie += r.calorieIntake;
      totalFat += r.fatIntake;
    }

    lines.push('【摄入汇总】');
    lines.push(`- 钠：${totalSodium.toFixed(0)}mg / ${sodiumBudget}mg (${totalSodium <= sodiumBudget ? '达标 ✓' : '超标 ✗'})`);
    lines.push(`- 糖：${totalSugar.toFixed(1)}g / ${sugarBudget}g (${totalSugar <= sugarBudget ? '达标 ✓' : '超标 ✗'})`);
    lines.push(`- 热量：${totalCalorie.toFixed(0)}kcal / ${calorieBudget}kcal (${totalCalorie <= calorieBudget ? '达标 ✓' : '超标 ✗'})`);
    lines.push(`- 脂肪：${totalFat.toFixed(1)}g / ${fatBudget}g (${totalFat <= fatBudget ? '达标 ✓' : '超标 ✗'})`);
    lines.push('');

    if (records.length > 0) {
      lines.push('【饮食记录】');
      for (const r of records) {
        const mealLabel = ReportExporter.getMealLabel(r.mealType);
        lines.push(`- [${mealLabel}] ${r.scenario || '未知'} ${r.amountG.toFixed(0)}g (钠${r.sodiumIntake.toFixed(0)}mg 糖${r.sugarIntake.toFixed(1)}g)`);
      }
      lines.push('');
    }

    lines.push(`生成时间：${new Date().toLocaleString()}`);
    return lines.join('\n');
  }

  static async exportToFile(content: string, filename: string, context: common.Context): Promise<string> {
    const dir = context.filesDir;
    const fullPath = `${dir}/${filename}`;
    try {
      const file = fs.openSync(fullPath, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
      hilog.info(DOMAIN_ZERO, TAG, 'Exported to: %{public}s', fullPath);
      return fullPath;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Export to file failed: %{public}s', JSON.stringify(e));
      throw new Error('Export failed');
    }
  }

  private static getStatusLabel(status: string): string {
    const map: Map<string, string> = new Map();
    map.set('excellent', '优秀');
    map.set('good', '达标');
    map.set('warning', '偏高');
    map.set('over', '超标');
    map.set('under', '不足');
    return map.get(status) ?? '未知';
  }

  private static getMealLabel(mealType: string): string {
    const map: Map<string, string> = new Map();
    map.set('breakfast', '早餐');
    map.set('lunch', '午餐');
    map.set('dinner', '晚餐');
    map.set('snack', '加餐');
    return map.get(mealType) ?? '其他';
  }
}
