// AiWeeklyReportService.ets
// AI 周报服务 - 为每周饮食报告生成个性化总结和建议

import { FamilyProfile, HILOG_DOMAIN_DEFAULT, JsonHelper, WeeklyReport, WeeklyDietData } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AiServiceBase, AI_SERVICE_DEFAULTS, SYSTEM_PROMPTS } from 'hsp_service';

const TAG = 'AiWeeklyReportService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class AiWeeklyReportResult {
  summary: string = '';
  highlights: string[] = [];
  suggestions: string[] = [];
  personalizedTip: string = '';
  motivationalMessage: string = '';
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
    return SYSTEM_PROMPTS.get('WEEKLY') ?? '你是家庭饮食周报润色助手。输出必须是合法JSON。语气温和鼓励，不恐吓。';
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
    return `You are a family diet health weekly report assistant. Generate personalized report text from rule engine data.

Requirements:
1. Warm, encouraging tone, no fear-based wording
2. No absolute statements
3. Member suggestions must be specific, not generic
4. Shopping tips practical, available in local stores
5. Summary <=80 chars, each tip <=40 chars
6. Add encouraging closing message

Member: ${profile.nickname} (${profile.ageGroup})
Health Goal: ${profile.healthGoals.join(', ')}
Data: Scans ${data.totalScans}, Na+ high ${data.highSodiumDays}/7d, Sugar high ${data.highSugarDays}/7d, Fat high ${data.highFatDays}/7d
Sweets near meals: ${data.sweetNearMealCount}, Late snacks: ${data.lateNightSnackCount}, Heavy flavor: ${data.heavyFlavorCount}

Engine Summary: ${report.summary}
Highlights: ${report.highlights.join('; ')}
Suggestions: ${report.suggestions.join('; ')}
Buy less: ${report.buyLess.join(', ')}
Buy more: ${report.buyMore.join(', ')}

Output JSON: {"summary":"...","highlights":"...","suggestions":"...","personalizedTip":"...","motivationalMessage":"..."}`;
  }

  private parseAiResponse(text: string, fallback: WeeklyReport): AiWeeklyReportResult {
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch === null) {
        return this.buildFallbackResult(fallback);
      }
      const rawParsed = JSON.parse(jsonMatch[0]) as Record<string, Object>;
      const parsed = JsonHelper.recordToMap(rawParsed);
      const result: AiWeeklyReportResult = new AiWeeklyReportResult()
      result.summary = (parsed.get('summary') as string) || fallback.summary;
      result.highlights = (parsed.get('highlights') as string[]) || fallback.highlights;
      result.suggestions = (parsed.get('suggestions') as string[]) || fallback.suggestions;
      result.personalizedTip = (parsed.get('personalizedTip') as string) || '';
      result.motivationalMessage = (parsed.get('motivationalMessage') as string) || '坚持记录，全家更安心';
      return result;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI weekly parse failed: %{public}s', JSON.stringify(error));
      return this.buildFallbackResult(fallback);
    }
  }

  private buildFallbackResult(report: WeeklyReport): AiWeeklyReportResult {
    const r: AiWeeklyReportResult = new AiWeeklyReportResult()
    r.summary = report.summary;
    r.highlights = report.highlights;
    r.suggestions = report.suggestions;
    r.personalizedTip = '';
    r.motivationalMessage = '坚持记录，全家更安心';
    return r;
  }
}
