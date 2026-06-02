// cloud-functions/llm-chat-proxy/index.ts
// 华为云函数 — 盘古大模型食品分析代理
// 运行时: Node.js 18.17 | 内存: 512MB | 超时: 30s

interface ChatRequest {
  question: string;
  context: string[];
  memberProfile?: MemberHealthContext;
  analysisType?: 'nutrition' | 'allergen' | 'alternative' | 'general';
}

interface MemberHealthContext {
  age: number;
  gender: 'male' | 'female' | 'other';
  allergens: string[];
  healthGoal: string;
  conditions: string[];
  dietPreference: string;
}

interface ChatResponse {
  answer: string;
  source: 'pangu' | 'cache' | 'fallback';
  tokens: number;
  latency: number;
}

const PANGU_ENDPOINT = process.env.PANGU_ENDPOINT ?? 'https://pangu-api.huaweicloud.com/v1/chat/completions';
const PANGU_API_KEY = process.env.PANGU_API_KEY ?? '';
const PANGU_MODEL = process.env.PANGU_MODEL ?? 'pangu-nlp-3b';

function buildFoodSafetyPrompt(profile?: MemberHealthContext): string {
  let prompt = `你是"家庭食品适配助手"的AI营养师，具有以下专业能力:
1. 食品成分安全性评估（添加剂、防腐剂、色素等）
2. 营养成分分析（Nutri-Score / Nova加工度 / Eco-Score生态评分）
3. 过敏原识别与不耐受预警
4. 个性化健康替代品推荐
5. 基于用户健康档案的饮食建议

请用中文回答，保持专业、准确、易懂。`;

  if (profile) {
    prompt += `

当前用户健康档案:
- 年龄: ${profile.age}岁
- 性别: ${profile.gender}
- 过敏原: ${profile.allergens.length > 0 ? profile.allergens.join('、') : '无'}
- 健康目标: ${profile.healthGoal}
- 疾病状况: ${profile.conditions.length > 0 ? profile.conditions.join('、') : '无'}
- 饮食偏好: ${profile.dietPreference || '无特殊偏好'}

请在分析时特别关注以上过敏原和健康限制条件。`;
  }

  return prompt;
}

async function callPanguAPI(messages: Array<{ role: string; content: string }>): Promise<ChatResponse> {
  const startTime = Date.now();

  const response = await fetch(PANGU_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${PANGU_API_KEY}`,
      'X-HW-ProjectId': process.env.HUAWEI_CLOUD_PROJECT_ID ?? '',
    },
    body: JSON.stringify({
      model: PANGU_MODEL,
      messages: messages,
      temperature: 0.3,
      max_tokens: 600,
      top_p: 0.85,
    }),
  });

  interface PanguResponse {
    choices: Array<{ message: { content: string } }>;
    usage: { total_tokens: number };
  }
  const data = (await response.json()) as PanguResponse;
  const latency = Date.now() - startTime;

  return {
    answer: data.choices[0]?.message?.content ?? '抱歉，AI分析暂时不可用，请稍后重试。',
    source: 'pangu',
    tokens: data.usage?.total_tokens ?? 0,
    latency: latency,
  };
}

function fallbackResponse(question: string): string {
  const q = question.toLowerCase();
  if (q.includes('营养') || q.includes('评分')) {
    return '根据食品营养成分分析，我建议关注三大核心指标：钠含量（建议每100g低于400mg）、糖含量（建议低于10g）、饱和脂肪（建议低于3g）。如需详细评分，请提供具体食品信息。';
  }
  if (q.includes('过敏') || q.includes('不耐受')) {
    return '常见过敏原包括花生、牛奶、鸡蛋、大豆、小麦、坚果、鱼虾等。如果您有特定过敏史，请告知您的过敏原，我将帮您针对性分析食品配料表。';
  }
  if (q.includes('替代') || q.includes('推荐')) {
    return '对于高钠食品，推荐低钠替代品（如原味海苔替代薯片）；对于高糖食品，推荐无糖或低糖替代品。请提供当前食品信息，我将给出具体推荐。';
  }
  return '我是您的营养AI助手。您可以询问食品成分分析、营养评分、过敏原检测或健康替代品推荐。请描述您的具体需求。';
}

export async function handler(event: ChatRequest): Promise<ChatResponse> {
  const { question, context, memberProfile } = event;

  if (!question || question.trim().length === 0) {
    return { answer: '请问有什么可以帮助您的？', source: 'fallback', tokens: 0, latency: 0 };
  }

  const systemPrompt = buildFoodSafetyPrompt(memberProfile);
  const messages: Array<{ role: string; content: string }> = [
    { role: 'system', content: systemPrompt },
  ];

  if (context && context.length > 0) {
    for (const c of context.slice(-6)) {
      messages.push({ role: 'assistant', content: c });
    }
  }

  messages.push({ role: 'user', content: question });

  try {
    if (PANGU_API_KEY) {
      return await callPanguAPI(messages);
    }
  } catch (err) {
    console.warn('Pangu API failed, using fallback:', (err as Error).message);
  }

  return {
    answer: fallbackResponse(question),
    source: 'fallback',
    tokens: 0,
    latency: 0,
  };
}