// AiNutritionistService.ets
// AI营养师服务 - 分析膳食记录、健康信号、预算使用，给出个性化营养建议和明日饮食计划
// 设计原则：
// 1. AI只做分析建议，不做诊断（所有医学判断由本地规则引擎完成）
// 2. 输入脱敏：只发送健康目标+营养素趋势+预算状态，不发送身份信息
// 3. 免费额度用完自动降级为规则引擎
// 4. 网络不可用时自动降级，不影响核心功能

import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import {
  AiNutritionAdvice, MealAnalysis, NutrientAnalysis,
  DietPatternAnalysis, AiNutritionCacheEntry,
  getHealthGoalDescription
} from '../model/AiModels';
import { FamilyProfile, HealthGoal } from '../model/FamilyProfile';
import { DailyBudget } from '../model/DailyBudget';
import { HealthSignal, BpStatus, BsStatus } from '../model/HealthSignal';
import { DietRecord } from '../repository/HistoryRepository';
import { NutritionTrendEngine, DailyNutritionSummary, MealGroup } from '../engine/NutritionTrendEngine';

const TAG = 'AiNutritionistService';
const DOMAIN_ZERO = 0;

const AGENT_ARTS_ENDPOINT = 'https://agentarts.cloud.huawei.com/v1/chat/completions';
const AGENT_ARTS_MODEL = 'agentarts-food-polish';
const CACHE_TTL_MS = 10 * 60 * 1000; // 缓存10分钟

class ChatMessage {
  role: string = '';
  content: string = '';
}

class HttpRequestOptions {
  method: http.RequestMethod = http.RequestMethod.POST;
  header: Record<string, string> = {};
  extraData: string | Object = '';
  connectTimeout: number = 15000;
  readTimeout: number = 20000;
}

interface AgentArtsCallResult {
  text: string;
  tokensUsed: number;
}

export class AiNutritionistService {
  private apiKey: string = '';
  private isEnabled: boolean = true;
  private tokensUsed: number = 0;
  private readonly MAX_TOKENS: number = 50000;
  private cache: Map<string, AiNutritionCacheEntry> = new Map();

  setApiKey(key: string): void {
    this.apiKey = key;
    hilog.info(DOMAIN_ZERO, TAG, 'API key configured');
  }

  setEnabled(enabled: boolean): void {
    this.isEnabled = enabled;
    hilog.info(DOMAIN_ZERO, TAG, 'AI nutritionist %{public}s', enabled ? 'enabled' : 'disabled');
  }

  /**
   * 获取AI营养师分析
   * @param member 家庭成员画像
   * @param signal 健康信号
   * @param budget 今日预算
   * @param records 近期膳食记录
   * @param days 分析天数
   * @param includeMealPlan 是否包含明日饮食计划
   */
  async getAdvice(
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number,
    includeMealPlan: boolean
  ): Promise<AiNutritionAdvice> {
    // 1. 规则引擎先做基础分析
    const baseResult = this.buildBaseAnalysis(member, signal, budget, records, days);

    // 2. 尝试AI增强
    if (this.isEnabled && this.apiKey.length > 0 && this.tokensUsed < this.MAX_TOKENS) {
      try {
        const aiResult = await this.enhanceWithAi(baseResult, member, signal, budget, records, days, includeMealPlan);
        if (aiResult) {
          this.tokensUsed += aiResult.tokensUsed;
          return aiResult.result;
        }
      } catch (error) {
        hilog.warn(DOMAIN_ZERO, TAG, 'AI enhance failed, use rule-based: %{public}s', JSON.stringify(error));
      }
    }

    return baseResult;
  }

  /**
   * 规则引擎基础分析（降级方案）
   */
  private buildBaseAnalysis(
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number
  ): AiNutritionAdvice {
    const summaries = NutritionTrendEngine.aggregateDaily(records);
    const mealGroups = NutritionTrendEngine.groupByMealType(records);

    const mealAnalyses = this.buildMealAnalyses(mealGroups, member);
    const nutrientAnalyses = this.buildNutrientAnalyses(summaries, budget, member, days);
    const patternAnalysis = this.buildPatternAnalysis(records, summaries, member);

    return {
      memberId: member.memberId,
      dateRange: `近${days}天`,
      summary: this.buildSummary(member, nutrientAnalyses, patternAnalysis),
      mealAnalyses: mealAnalyses,
      nutrientAnalyses: nutrientAnalyses,
      patternAnalysis: patternAnalysis,
      suggestions: this.buildSuggestions(member, signal, nutrientAnalyses, patternAnalysis),
      mealPlanSuggestions: [],
      motivationalMessage: '坚持记录每一餐，让饮食更有数！',
      isAiGenerated: false
    };
  }

  private buildMealAnalyses(mealGroups: MealGroup[], member: FamilyProfile): MealAnalysis[] {
    const analyses: MealAnalysis[] = [];

    for (const group of mealGroups) {
      const totalSodium = group.records.reduce((sum, r) => sum + r.sodiumIntake, 0);
      const totalSugar = group.records.reduce((sum, r) => sum + r.sugarIntake, 0);
      const totalCal = group.records.reduce((sum, r) => sum + r.calorieIntake, 0);
      const totalFat = group.records.reduce((sum, r) => sum + r.fatIntake, 0);

      let rating: 'good' | 'fair' | 'caution' = 'good';
      let comment = '';
      let suggestion = '';

      if (member.isControlBp() && totalSodium > member.dailyBudget.sodiumBudget * 0.4) {
        rating = 'caution';
        comment = '此餐钠含量较高，建议搭配清淡食物';
        suggestion = '下一餐减少盐和酱油用量';
      } else if (member.isControlSugar() && totalSugar > member.dailyBudget.sugarBudget * 0.4) {
        rating = 'caution';
        comment = '此餐糖分偏高，注意控制';
        suggestion = '选择低糖或无糖饮品搭配';
      } else if (totalCal > member.dailyBudget.calorieBudget * 0.5) {
        rating = 'fair';
        comment = '此餐热量较高';
        suggestion = '多吃蔬菜增加饱腹感';
      } else {
        comment = '此餐营养搭配合理';
        suggestion = '继续保持';
      }

      analyses.push({
        mealType: group.mealType,
        rating: rating,
        comment: comment,
        suggestion: suggestion
      });
    }

    return analyses;
  }

  private buildNutrientAnalyses(
    summaries: DailyNutritionSummary[],
    budget: DailyBudget,
    member: FamilyProfile,
    days: number
  ): NutrientAnalysis[] {
    const count = summaries.length || 1;
    const avgSodium = summaries.reduce((s, d) => s + d.sodium, 0) / count;
    const avgSugar = summaries.reduce((s, d) => s + d.sugar, 0) / count;
    const avgCal = summaries.reduce((s, d) => s + d.calories, 0) / count;
    const avgFat = summaries.reduce((s, d) => s + d.fat, 0) / count;

    const analyses: NutrientAnalysis[] = [];

    // 钠
    analyses.push(this.nutrientHelper(
      '钠', avgSodium, budget.sodiumBudget,
      avgSodium > budget.sodiumBudget ? 'over' : avgSodium > budget.sodiumBudget * 0.8 ? 'warning' : 'good'
    ));

    // 糖
    analyses.push(this.nutrientHelper(
      '糖', avgSugar, budget.sugarBudget,
      avgSugar > budget.sugarBudget ? 'over' : avgSugar > budget.sugarBudget * 0.8 ? 'warning' : 'good'
    ));

    // 热量
    analyses.push(this.nutrientHelper(
      '热量', avgCal, budget.calorieBudget,
      avgCal > budget.calorieBudget ? 'over' : avgCal > budget.calorieBudget * 0.8 ? 'warning' : 'good'
    ));

    // 脂肪
    analyses.push(this.nutrientHelper(
      '脂肪', avgFat, budget.fatBudget,
      avgFat > budget.fatBudget ? 'over' : avgFat > budget.fatBudget * 0.8 ? 'warning' : 'good'
    ));

    return analyses;
  }

  private nutrientHelper(
    name: string, avg: number, target: number, status: 'excellent' | 'good' | 'warning' | 'over'
  ): NutrientAnalysis {
    const unit = name === '钠' ? 'mg' : name === '热量' ? 'kcal' : 'g';
    const insightMap: Record<string, string> = {
      'excellent': `${name}摄入控制得很好，继续保持`,
      'good': `${name}摄入在合理范围内`,
      'warning': `${name}摄入偏高了，要注意控制`,
      'over': `${name}摄入超标了，建议减少高${name}食物`
    };
    return {
      name: name,
      averageDaily: Math.round(avg * 10) / 10,
      target: target,
      trend: 'stable',
      status: status,
      insight: insightMap[status] || `${name}摄入情况正常`
    };
  }

  private buildPatternAnalysis(
    records: DietRecord[],
    summaries: DailyNutritionSummary[],
    member: FamilyProfile
  ): DietPatternAnalysis {
    const issues: string[] = [];
    const highlights: string[] = [];

    const totalDays = summaries.length;
    const highSodiumDays = summaries.filter(s => s.sodium > member.dailyBudget.sodiumBudget).length;
    const highSugarDays = summaries.filter(s => s.sugar > member.dailyBudget.sugarBudget).length;

    if (highSodiumDays > totalDays * 0.3) {
      issues.push(`过去${totalDays}天中有${highSodiumDays}天钠超标`);
    }
    if (highSugarDays > totalDays * 0.3) {
      issues.push(`过去${totalDays}天中有${highSugarDays}天糖超标`);
    }
    if (records.filter(r => r.mealType === '夜宵').length > totalDays * 0.3) {
      issues.push('夜宵频率偏高');
    }

    if (highSodiumDays <= totalDays * 0.1) {
      highlights.push('钠摄入控制良好');
    }
    if (highSugarDays <= totalDays * 0.1) {
      highlights.push('糖摄入控制良好');
    }
    if (records.length > 0) {
      highlights.push(`共记录${records.length}次饮食（覆盖${totalDays}天）`);
    }

    const regularityScore = totalDays > 0 ? Math.round((records.length / totalDays) * 20) : 0;
    const diversityScore = records.length > 0
      ? Math.min(100, Math.round(new Set(records.map(r => r.mealType)).size * 15))
      : 0;

    return {
      regularityScore: Math.min(100, regularityScore),
      diversityScore: Math.min(100, diversityScore),
      issues: issues,
      highlights: highlights.length > 0 ? highlights : ['开始记录就是最好的第一步']
    };
  }

  private buildSummary(
    member: FamilyProfile,
    nutrientAnalyses: NutrientAnalysis[],
    pattern: DietPatternAnalysis
  ): string {
    const warnings = nutrientAnalyses.filter(n => n.status === 'warning' || n.status === 'over');
    const goods = nutrientAnalyses.filter(n => n.status === 'good' || n.status === 'excellent');

    let summary = `${member.nickname}：`;
    if (warnings.length > 0) {
      summary += `需关注${warnings.map(w => w.name).join('、')}的摄入；`;
    }
    if (goods.length > 0) {
      summary += `${goods.map(g => g.name).join('、')}控制良好；`;
    }
    if (pattern.issues.length > 0) {
      summary += `发现${pattern.issues.length}个饮食模式问题。`;
    } else {
      summary += '整体饮食模式健康。';
    }
    return summary;
  }

  private buildSuggestions(
    member: FamilyProfile,
    signal: HealthSignal,
    nutrientAnalyses: NutrientAnalysis[],
    pattern: DietPatternAnalysis
  ): string[] {
    const suggestions: string[] = [];

    for (const na of nutrientAnalyses) {
      if (na.status === 'warning' || na.status === 'over') {
        suggestions.push(`减少${na.name}摄入量，建议控制在${na.target}${na.name === '钠' ? 'mg' : na.name === '热量' ? 'kcal' : 'g'}以内`);
      }
    }

    if (member.isControlBp() && signal.manualBpStatus !== BpStatus.NORMAL) {
      suggestions.push('血压偏高期间，特别注意控盐，少吃腌制食品');
    }
    if (member.isControlSugar() && signal.manualBsStatus !== BsStatus.NORMAL) {
      suggestions.push('血糖偏高期间，建议选择低GI食物，避免含糖饮料');
    }

    if (pattern.issues.length > 0) {
      suggestions.push(pattern.issues[0]);
    }

    if (suggestions.length === 0) {
      suggestions.push('继续保持健康的饮食习惯');
      suggestions.push('多喝水，保持规律作息');
    }

    return suggestions.slice(0, 4);
  }

  /**
   * AI增强：调用AgentArts生成个性化营养分析
   */
  private async enhanceWithAi(
    baseResult: AiNutritionAdvice,
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number,
    includeMealPlan: boolean
  ): Promise<{ result: AiNutritionAdvice; tokensUsed: number } | null> {
    const prompt = this.buildNutritionistPrompt(
      baseResult, member, signal, budget, records, days, includeMealPlan
    );
    const aiResult = await this.callAgentArts(prompt);

    if (!aiResult || aiResult.text.length === 0) return null;

    const enhanced = this.parseAiResponse(aiResult.text, baseResult, member, includeMealPlan);
    if (enhanced) {
      return { result: enhanced, tokensUsed: aiResult.tokensUsed };
    }
    return null;
  }

  private buildNutritionistPrompt(
    baseResult: AiNutritionAdvice,
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number,
    includeMealPlan: boolean
  ): string {
    // 脱敏输入
    const budgetStatus = {
      sodiumPct: Math.round(((budget.sodiumBudget - budget.sodiumRemaining) / budget.sodiumBudget) * 100),
      sugarPct: Math.round(((budget.sugarBudget - budget.sugarRemaining) / budget.sugarBudget) * 100),
      calPct: Math.round(((budget.calorieBudget - budget.calorieRemaining) / budget.calorieBudget) * 100),
      fatPct: Math.round(((budget.fatBudget - budget.fatRemaining) / budget.fatBudget) * 100)
    };

    const healthStatus = {
      bp: signal.manualBpStatus,
      bs: signal.manualBsStatus,
      sleep: signal.sleepStatus,
      steps: signal.stepLevel
    };

    return `你是一个家庭AI营养师。请根据以下脱敏数据，为家庭成员提供个性化的营养分析和建议。

要求：
1. 输出必须是合法JSON格式
2. 语气温暖鼓励，不使用恐吓或医学诊断式语言
3. 建议要具体可执行，不要泛泛而谈
4. 每个分析要有数据支撑
5. 如果包含饮食计划，要具体到食物名称和大致份量
6. 总评不超过80字，每条建议不超过50字

成员信息（脱敏）：
- 年龄段：${member.ageGroup}
- 健康目标：${member.healthGoals.map(h => getHealthGoalDescription(h)).join('、')}
- 过敏原：${member.allergens.length > 0 ? member.allergens.join('、') : '无'}

今日预算使用（脱敏）：
- 钠：已用${budgetStatus.sodiumPct}%
- 糖：已用${budgetStatus.sugarPct}%
- 热量：已用${budgetStatus.calPct}%
- 脂肪：已用${budgetStatus.fatPct}%

近期健康状态：
- 血压：${healthStatus.bp}
- 血糖：${healthStatus.bs}
- 睡眠：${healthStatus.sleep}
- 活动量：${healthStatus.steps}

分析天数：${days}天
记录次数：${records.length}

规则引擎初步分析：
- 总评：${baseResult.summary}
- 问题：${baseResult.patternAnalysis.issues.join('；')}
- 亮点：${baseResult.patternAnalysis.highlights.join('；')}

${includeMealPlan ? '请包含明日饮食计划建议（3餐+加餐）' : ''}

请输出JSON格式：
{
  "summary": "个性化总评",
  "mealAnalyses": [
    {"mealType": "早餐", "rating": "good/fair/caution", "comment": "评语", "suggestion": "改进建议"}
  ],
  "nutrientInsights": [
    {"name": "钠", "insight": "个性化解读"}
  ],
  "patternIssues": ["问题1"],
  "patternHighlights": ["亮点1"],
  "suggestions": ["建议1", "建议2"],
  "motivationalMessage": "鼓励语",
  ${includeMealPlan ? `"mealPlanSuggestions": ["早餐建议", "午餐建议", "晚餐建议", "加餐建议"]` : '"mealPlanSuggestions": []'}
}`;
  }

  private parseAiResponse(
    text: string,
    baseResult: AiNutritionAdvice,
    member: FamilyProfile,
    includeMealPlan: boolean
  ): AiNutritionAdvice | null {
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) return null;

      const parsed = JSON.parse(jsonMatch[0]) as Record<string, Object>;

      // 合并AI结果和规则基础结果
      const aiMealAnalyses = parsed['mealAnalyses'] as Record<string, Object>[] || [];
      const nutrientInsights = parsed['nutrientInsights'] as Record<string, Object>[] || [];
      const aiPatternIssues = parsed['patternIssues'] as string[] || [];
      const aiPatternHighlights = parsed['patternHighlights'] as string[] || [];
      const aiSuggestions = parsed['suggestions'] as string[] || [];
      const aiMealPlan = parsed['mealPlanSuggestions'] as string[] || [];

      // 构建增强的mealAnalyses
      const mealAnalyses: MealAnalysis[] = aiMealAnalyses.map(a => ({
        mealType: (a['mealType'] as string) || '',
        rating: (a['rating'] as 'good' | 'fair' | 'caution') || 'fair',
        comment: (a['comment'] as string) || '',
        suggestion: (a['suggestion'] as string) || ''
      }));

      // 合并nutrient insight到基础分析
      const nutrientAnalyses = baseResult.nutrientAnalyses.map(na => {
        const aiInsight = nutrientInsights.find(i => i['name'] === na.name);
        return {
          ...na,
          insight: (aiInsight?.['insight'] as string) || na.insight
        };
      });

      return {
        memberId: member.memberId,
        dateRange: baseResult.dateRange,
        summary: (parsed['summary'] as string) || baseResult.summary,
        mealAnalyses: mealAnalyses.length > 0 ? mealAnalyses : baseResult.mealAnalyses,
        nutrientAnalyses: nutrientAnalyses,
        patternAnalysis: {
          regularityScore: baseResult.patternAnalysis.regularityScore,
          diversityScore: baseResult.patternAnalysis.diversityScore,
          issues: aiPatternIssues.length > 0 ? aiPatternIssues : baseResult.patternAnalysis.issues,
          highlights: aiPatternHighlights.length > 0 ? aiPatternHighlights : baseResult.patternAnalysis.highlights
        },
        suggestions: aiSuggestions.length > 0 ? aiSuggestions : baseResult.suggestions,
        mealPlanSuggestions: includeMealPlan && aiMealPlan.length > 0 ? aiMealPlan : [],
        motivationalMessage: (parsed['motivationalMessage'] as string) || baseResult.motivationalMessage,
        isAiGenerated: true
      };
    } catch (error) {
      return null;
    }
  }

  private async callAgentArts(prompt: string): Promise<AgentArtsCallResult | null> {
    try {
      const httpRequest = http.createHttp();

      const systemMsg = new ChatMessage();
      systemMsg.role = 'system';
      systemMsg.content = '你是家庭AI营养师。输出必须是合法JSON。语气温和鼓励，不恐吓。';

      const userMsg = new ChatMessage();
      userMsg.role = 'user';
      userMsg.content = prompt;

      const messages: ChatMessage[] = [systemMsg, userMsg];

      const requestBody = JSON.stringify({
        model: AGENT_ARTS_MODEL,
        messages: messages,
        temperature: 0.5,
        max_tokens: 1000
      });

      const reqHeaders: Record<string, string> = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`
      };

      const reqOptions: HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: reqHeaders,
        extraData: requestBody,
        connectTimeout: 15000,
        readTimeout: 25000
      };

      const response = await httpRequest.request(AGENT_ARTS_ENDPOINT, reqOptions);
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const parsedResult = JSON.parse(response.result as string) as Record<string, Object>;
        const choices = parsedResult['choices'] as Record<string, Object>[] ?? [];
        if (choices.length > 0) {
          const firstChoice = choices[0];
          const message = firstChoice['message'] as Record<string, Object> ?? {};
          const usage = parsedResult['usage'] as Record<string, Object> ?? {};

          const callResult: AgentArtsCallResult = {
            text: message['content'] as string ?? '',
            tokensUsed: usage['total_tokens'] as number ?? 0
          };
          return callResult;
        }
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AgentArts call failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }
}
