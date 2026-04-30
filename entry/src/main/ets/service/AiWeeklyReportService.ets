import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import { WeeklyReport, WeeklyDietData } from '../engine/WeeklyReportEngine';
import { FamilyProfile } from '../model/FamilyProfile';

const TAG = 'AiWeeklyReportService';
const DOMAIN_ZERO = 0;

const AGENT_ARTS_ENDPOINT = 'https://agentarts.cloud.huawei.com/v1/chat/completions';
const AGENT_ARTS_MODEL = 'agentarts-food-polish';

export interface AiWeeklyReportResult {
  summary: string;
  highlights: string[];
  suggestions: string[];
  personalizedTip: string;
  motivationalMessage: string;
}

export class AiWeeklyReportService {
  private apiKey: string = '';
  private isEnabled: boolean = true;
  private tokensUsed: number = 0;
  private readonly MAX_WEEKLY_TOKENS: number = 50000;

  setApiKey(key: string): void {
    this.apiKey = key;
  }

  setEnabled(enabled: boolean): void {
    this.isEnabled = enabled;
  }

  async enhanceWeeklyReport(
    report: WeeklyReport,
    data: WeeklyDietData,
    profile: FamilyProfile
  ): Promise<AiWeeklyReportResult> {
    if (!this.isEnabled || this.apiKey.length === 0 || this.tokensUsed >= this.MAX_WEEKLY_TOKENS) {
      return this.buildFallbackResult(report);
    }

    try {
      const prompt = this.buildWeeklyPrompt(report, data, profile);
      const aiResult = await this.callAgentArts(prompt);

      if (aiResult && aiResult.text.length > 0) {
        this.tokensUsed += aiResult.tokensUsed;
        return this.parseAiResponse(aiResult.text, report);
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
      if (!jsonMatch) {
        return this.buildFallbackResult(fallback);
      }
      const parsed = JSON.parse(jsonMatch[0]) as Record<string, Object>;
      return {
        summary: (parsed.summary as string) || fallback.summary,
        highlights: (parsed.highlights as string[]) || fallback.highlights,
        suggestions: (parsed.suggestions as string[]) || fallback.suggestions,
        personalizedTip: (parsed.personalizedTip as string) || '',
        motivationalMessage: (parsed.motivationalMessage as string) || '坚持记录，全家更安心'
      };
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

  private async callAgentArts(prompt: string): Promise<{ text: string; tokensUsed: number } | null> {
    try {
      const httpRequest = http.createHttp();
      const requestBody = JSON.stringify({
        model: AGENT_ARTS_MODEL,
        messages: [
          {
            role: 'system',
            content: '你是家庭饮食周报润色助手。输出必须是合法JSON。语气温和鼓励，不恐吓。'
          },
          { role: 'user', content: prompt }
        ],
        temperature: 0.6,
        max_tokens: 500
      });

      const response = await httpRequest.request(AGENT_ARTS_ENDPOINT, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        extraData: requestBody,
        connectTimeout: 15000,
        readTimeout: 20000
      });
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as {
          choices: Array<{ message: { content: string } }>;
          usage: { total_tokens: number };
        };
        if (result.choices && result.choices.length > 0) {
          return {
            text: result.choices[0].message.content,
            tokensUsed: result.usage?.total_tokens || 0
          };
        }
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AgentArts call failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }
}
