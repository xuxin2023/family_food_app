// PromptBuilder.ets
// 端侧大模型提示词构建器
// 为5种推理场景构建结构化prompt：成分分析/营养建议/过敏预警/替代推荐/综合报告

import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

export class PromptTemplate {
  task: string = '';
  systemPrompt: string = '';
  maxTokens: number = 512;
  temperature: number = 0.7;
}

export class PromptContext {
  foodName: string = '';
  ingredients: string[] = [];
  nutritionPer100g: string = '';
  nutriScore: string = '';
  memberAllergies: string[] = [];
  memberIntolerances: string[] = [];
  healthGoals: string[] = [];
  scanHistorySummary: string = '';
}

export class PromptBuilder {
  private static SYSTEM_INGREDIENT = '你是食品安全与营养分析专家。请基于配料表和营养成分，客观评估食品的健康影响。回答应简洁、准确、有科学依据。';
  private static SYSTEM_DIET = '你是一位注册营养师，擅长为中国家庭提供个性化饮食建议。请结合用户成员的健康目标，给出具体可行的建议。';
  private static SYSTEM_ALLERGEN = '你是过敏与免疫学专家。请根据用户过敏原档案，精准评估食品的安全风险，区分过敏（免疫反应）与不耐受（非免疫反应）。';
  private static SYSTEM_RECOMMEND = '你是食品替代品推荐专家。请基于当前产品的营养评级和成分，推荐更健康、成分更简洁的替代品。优先推荐中国市场上可购买的产品。';
  private static SYSTEM_REPORT = '你是健康数据分析师。请基于用户的饮食记录数据，生成结构化的营养趋势报告和改进建议。';

  buildIngredientPrompt(context: PromptContext): PromptTemplate {
    const template = new PromptTemplate();
    template.task = 'ingredient_analysis';
    template.systemPrompt = PromptBuilder.SYSTEM_INGREDIENT;
    template.maxTokens = 512;
    template.temperature = 0.3;

    const parts: string[] = [];
    parts.push(`请分析以下食品的成分安全性：`);
    parts.push(`食品名称：${context.foodName}`);
    parts.push(`配料表：${context.ingredients.join('、')}`);
    parts.push(`每100g营养成分：${context.nutritionPer100g}`);
    parts.push(`请按以下格式回答：`);
    parts.push(`1. 核心成分风险等级（高/中/低）`);
    parts.push(`2. 需要特别关注的添加剂（如有）`);
    parts.push(`3. 综合建议（2-3句话）`);

    return template;
  }

  buildDietAdvicePrompt(context: PromptContext): PromptTemplate {
    const template = new PromptTemplate();
    template.task = 'diet_advice';
    template.systemPrompt = PromptBuilder.SYSTEM_DIET;
    template.maxTokens = 384;
    template.temperature = 0.6;

    const parts: string[] = [];
    parts.push(`用户正在评估食品：${context.foodName}`);
    parts.push(`营养评级：${context.nutriScore}`);
    parts.push(`配料：${context.ingredients.slice(0, 5).join('、')}${context.ingredients.length > 5 ? '等' : ''}`);
    if (context.healthGoals.length > 0) {
      parts.push(`用户健康目标：${context.healthGoals.join('、')}`);
    }
    parts.push(`请给出基于中国居民膳食指南的个性化食用建议（2-3句）`);

    return template;
  }

  buildAllergenPrompt(context: PromptContext): PromptTemplate {
    const template = new PromptTemplate();
    template.task = 'allergen_risk';
    template.systemPrompt = PromptBuilder.SYSTEM_ALLERGEN;
    template.maxTokens = 384;
    template.temperature = 0.2;

    const parts: string[] = [];
    parts.push(`请评估以下食品的过敏风险：`);
    parts.push(`食品：${context.foodName}`);
    parts.push(`配料：${context.ingredients.join('、')}`);
    if (context.memberAllergies.length > 0) {
      parts.push(`用户过敏原：${context.memberAllergies.join('、')}`);
    }
    if (context.memberIntolerances.length > 0) {
      parts.push(`用户不耐受：${context.memberIntolerances.join('、')}`);
    }
    parts.push(`请判断是否存在过敏或不耐受风险，并给出具体建议。`);

    return template;
  }

  buildRecommendPrompt(context: PromptContext): PromptTemplate {
    const template = new PromptTemplate();
    template.task = 'alternative_recommend';
    template.systemPrompt = PromptBuilder.SYSTEM_RECOMMEND;
    template.maxTokens = 512;
    template.temperature = 0.5;

    const parts: string[] = [];
    parts.push(`当前产品：${context.foodName}`);
    parts.push(`营养评级：${context.nutriScore}`);
    parts.push(`配料特点：${context.ingredients.slice(0, 5).join('、')}`);
    parts.push(`请推荐3款同类但更健康的产品方向，说明每款的推荐理由。优先考虑低钠、低糖、高蛋白、配料简洁的产品。`);

    return template;
  }

  buildReportPrompt(context: PromptContext): PromptTemplate {
    const template = new PromptTemplate();
    template.task = 'health_report';
    template.systemPrompt = PromptBuilder.SYSTEM_REPORT;
    template.maxTokens = 640;
    template.temperature = 0.4;

    const parts: string[] = [];
    parts.push(`请根据以下饮食数据生成营养趋势报告：`);
    parts.push(`饮食摘要：${context.scanHistorySummary}`);
    parts.push(`营养评级分布：${context.nutriScore}`);
    if (context.healthGoals.length > 0) {
      parts.push(`健康目标：${context.healthGoals.join('、')}`);
    }
    parts.push(`请给出：1)总体评估 2)关键趋势 3)3条改进建议`);

    return template;
  }

  toPromptString(template: PromptTemplate, context: PromptContext): string {
    const parts: string[] = [];
    parts.push(`[系统指令] ${template.systemPrompt}`);
    parts.push(`[任务] 食品名称：${context.foodName}`);
    if (context.ingredients.length > 0) {
      parts.push(`配料：${context.ingredients.join('、')}`);
    }
    if (context.nutritionPer100g.length > 0) {
      parts.push(`营养(${context.nutritionPer100g})`);
    }
    if (context.nutriScore.length > 0) {
      parts.push(`评级：${context.nutriScore}`);
    }
    return parts.join('\n');
  }
}