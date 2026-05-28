interface CrossCheckRequest {
  userAllergens: string[];
  foodIngredients: string[];
}

interface CrossRisk {
  allergen: string;
  triggeredBy: string;
  riskLevel: 'high' | 'moderate' | 'low';
  mechanism: string;
}

interface CrossCheckResponse {
  directHits: string[];
  crossRisks: CrossRisk[];
  overallRisk: 'high' | 'moderate' | 'low' | 'none';
  recommendation: string;
}

const CROSS_MAP: Record<string, { target: string; risk: string; mechanism: string }[]> = {
  '花生': [{ target: '大豆', risk: 'moderate', mechanism: '豆科蛋白同源性' }, { target: '豌豆', risk: 'moderate', mechanism: '豆科蛋白同源性' }],
  '牛奶': [{ target: '山羊奶', risk: 'high', mechanism: '酪蛋白同源性>90%' }, { target: '绵羊奶', risk: 'high', mechanism: '酪蛋白同源性>90%' }],
  '小麦': [{ target: '大麦', risk: 'high', mechanism: '麸质蛋白同源性' }, { target: '黑麦', risk: 'high', mechanism: '麸质蛋白同源性' }],
  '虾': [{ target: '蟹', risk: 'high', mechanism: '原肌球蛋白同源' }, { target: '龙虾', risk: 'high', mechanism: '原肌球蛋白同源' }],
  '鸡蛋': [{ target: '鸭蛋', risk: 'moderate', mechanism: '卵白蛋白同源性' }],
  '鱼': [{ target: '虾', risk: 'moderate', mechanism: '原肌球蛋白同源性' }],
  '坚果': [{ target: '花生', risk: 'moderate', mechanism: '种子储存蛋白同源性' }, { target: '芝麻', risk: 'low', mechanism: '种子蛋白同源性' }],
  '芒果': [{ target: '腰果', risk: 'moderate', mechanism: '漆树科蛋白同源性' }],
};

export const handler = async (event: { body?: string }, context: Record<string, Object>): Promise<CrossCheckResponse> => {
  const req: CrossCheckRequest = typeof event.body === 'string'
    ? JSON.parse(event.body) : (event.body ?? event) as unknown as CrossCheckRequest;

  const directHits: string[] = [];
  for (const a of req.userAllergens) {
    if (req.foodIngredients.includes(a)) { directHits.push(a); }
  }

  const crossRisks: CrossRisk[] = [];
  for (const a of req.userAllergens) {
    const pairs = CROSS_MAP[a];
    if (!pairs) continue;
    for (const pair of pairs) {
      if (req.foodIngredients.includes(pair.target)) {
        crossRisks.push({
          allergen: pair.target,
          triggeredBy: a,
          riskLevel: pair.risk as CrossRisk['riskLevel'],
          mechanism: pair.mechanism
        });
      }
    }
  }

  const overallRisk: CrossCheckResponse['overallRisk'] =
    directHits.length > 0 ? 'high' :
    crossRisks.some(r => r.riskLevel === 'high') ? 'high' :
    crossRisks.some(r => r.riskLevel === 'moderate') ? 'moderate' :
    crossRisks.length > 0 ? 'low' : 'none';

  const recommendation = overallRisk === 'high' ? '含过敏原或高风险交叉反应性，强烈建议避免'
    : overallRisk === 'moderate' ? '存在中等风险交叉反应性，谨慎食用'
    : overallRisk === 'low' ? '存在低风险交叉反应性，大多数人可安全食用'
    : '未检测到过敏风险';

  return { directHits, crossRisks, overallRisk, recommendation };
};
