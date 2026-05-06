// AiWeeklyReportService.ets
// AI 周报服务 - 为每周饮食报告生成个性化总结和建议

import { hilog } from '@kit.PerformanceAnalysisKit';
import { WeeklyReport, WeeklyDietData } from '../engine/WeeklyReportEngine';
import { FamilyProfile } from '../model/FamilyProfile';
import { AiServiceBase } from './ai/AiServiceBase';
import { AI_SERVICE_DEFAULTS, SYSTEM_PROMPTS } from './ai/AiConfig';

const TAG = 'AiWeeklyReportService';
const DOMAIN_ZERO = 0;

export interface AiWeeklyReportResult {
  summary: string;
  highlights: string[];
  suggestions: string[];
  personalizedTip: string;
  motivationalMessage: string;
}

export class AiWeeklyReportService extends AiServiceBase {
  protected getTag(): string {
    return TAG;
  }

  protected getDefaultTemperature(): number {
    return AI_SERVICE_DEFAULTS.WEEKLY_TEMPERATURE;
  }

  protected getDefaultMaxTokens(): number {
    return AI_SERVICE_DEFAULTS.WEEKLY_MAX_TOKENS;
  }

  protected getSystemPrompt(): string {
    return SYSTEM_PROMPTS.WEEKLY;
  }

  async enhanceWeeklyReport(
    report: WeeklyReport,
    data: WeeklyDietData,
    profile: FamilyProfile
  ): Promise<AiWeeklyReportResult> {
    if (!this.shouldUseAi()) {
      return this.buildFallbackResult(report);
    }

    try {
      const prompt = this.buildWeeklyPrompt(report, data, profile);
      const aiText = await this.callAi(prompt);

      if (aiText !== null && aiText.length > 0) {
        return this.parseAiResponse(aiText, report);
      }

      return this.buildFallbackResult(report);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI weekly enhance failed: %{public}s', JSON.stringify(error));
      return this.buildFallbackResult(report);
    }
  }

  private buildWeeklyPrompt(
    report: WeeklyReport,
    data: WeeklyDietData,
    profile: FamilyProfile
  ): string {
    return `你是一个家庭饮食健康周报润色助手。请根据以下规则引擎生成的周报数据，生成个性化的周报文案。

要求：
1. 语气温暖、鼓励为主，不使用恐吓式表达
2. 不使用绝对化表述（如"一定有害""完全不能吃"）
3. 每个成员的建议要具体，不要泛泛而谈
4. 采购建议要实用，能在超市直接找到
5. 总结不超过80字，每条建议不超过40字
6. 加一句鼓励语（如"坚持记录，全家更安心"）

成员：${profile.nickname}（${profile.ageGroup}）
健康目标：${profile.healthGoals.join('、')}
本周数据：
- 扫描次数：${data.totalScans}
- 高盐天数：${data.highSodiumDays}/7
- 高糖天数：${data.highSugarDays}/7
- 高脂天数：${data.highFatDays}/7
- 甜食近正餐：${data.sweetNearMealCount}次
- 夜宵：${data.lateNightSnackCount}次
- 重口味：${data.heavyFlavorCount}次

规则引擎总结：${report.summary}
规则引擎重点：${report.highlights.join('；')}
规则引擎建议：${report.suggestions.join('；')}
少买：${report.buyLess.join('、')}
建议备：${report.buyMore.join('、')}

请输出JSON格式：
{
  "summary": "个性化一句话总结",
  "highlights": ["重点1", "重点2"],
  "suggestions": ["建议1", "建议2"],
  "personalizedTip": "针对该成员的个性化提醒",
  "motivationalMessage": "鼓励语"
}`;
  }

  private parseAiResponse(text: string, fallback: WeeklyReport): AiWeeklyReportResult {
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch === null) {
        return this.buildFallbackResult(fallback);
      }
      const parsed = JSON.parse(jsonMatch[0]) as Record<string, Object>;
      const result: AiWeeklyReportResult = {
        summary: (parsed.summary as string) || fallback.summary,
        highlights: (parsed.highlights as string[]) || fallback.highlights,
        suggestions: (parsed.suggestions as string[]) || fallback.suggestions,
        personalizedTip: (parsed.personalizedTip as string) || '',
        motivationalMessage: (parsed.motivationalMessage as string) || '坚持记录，全家更安心'
      };
      return result;
    } catch (error) {
      return this.buildFallbackResult(fallback);
    }
  }

  private buildFallbackResult(report: WeeklyReport): AiWeeklyReportResult {
    return {
      summary: report.summary,
      highlights: report.highlights,
      suggestions: report.suggestions,
      personalizedTip: '',
      motivationalMessage: '坚持记录，全家更安心'
    };
  }
}
