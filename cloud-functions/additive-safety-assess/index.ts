interface AdditiveAssessRequest {
  ingredients: string;
}

interface AdditiveInfo {
  eNumber: string;
  name: string;
  risk: 'safe' | 'caution' | 'avoid' | 'unknown';
  category: string;
}

interface AdditiveAssessResponse {
  assessments: AdditiveInfo[];
  overallRisk: 'safe' | 'caution' | 'avoid';
  summary: string;
}

const DB: Record<string, { name: string; risk: string; category: string }> = {
  'E102': { name: '柠檬黄', risk: 'caution', category: '着色剂' },
  'E110': { name: '日落黄', risk: 'caution', category: '着色剂' },
  'E120': { name: '胭脂红', risk: 'avoid', category: '着色剂' },
  'E171': { name: '二氧化钛', risk: 'avoid', category: '着色剂' },
  'E211': { name: '苯甲酸钠', risk: 'caution', category: '防腐剂' },
  'E250': { name: '亚硝酸钠', risk: 'avoid', category: '防腐剂' },
  'E320': { name: 'BHA', risk: 'avoid', category: '抗氧化剂' },
  'E321': { name: 'BHT', risk: 'caution', category: '抗氧化剂' },
  'E621': { name: '谷氨酸钠', risk: 'caution', category: '增味剂' },
  'E951': { name: '阿斯巴甜', risk: 'caution', category: '甜味剂' },
};

export const handler = async (event: { body?: string }, context: Record<string, Object>): Promise<AdditiveAssessResponse> => {
  const req: AdditiveAssessRequest = typeof event.body === 'string'
    ? JSON.parse(event.body) : (event.body ?? event) as unknown as AdditiveAssessRequest;

  const assessments: AdditiveInfo[] = [];
  const pattern = /\b(E\d{3}[a-z]?)\b/gi;
  let match: RegExpExecArray | null;
  const re = new RegExp(pattern.source, pattern.flags);
  while ((match = re.exec(req.ingredients)) !== null) {
    const eNum = match[1].toUpperCase();
    const info = DB[eNum];
    assessments.push({
      eNumber: eNum,
      name: info?.name ?? '未知',
      risk: (info?.risk as AdditiveInfo['risk']) ?? 'unknown',
      category: info?.category ?? '未知'
    });
  }

  const hasAvoid = assessments.some(a => a.risk === 'avoid');
  const hasCaution = assessments.some(a => a.risk === 'caution');
  const overallRisk: AdditiveAssessResponse['overallRisk'] = hasAvoid ? 'avoid' : hasCaution ? 'caution' : 'safe';

  return {
    assessments,
    overallRisk,
    summary: overallRisk === 'avoid' ? '含应避免添加剂' : overallRisk === 'caution' ? '含需注意添加剂' : '添加剂安全'
  };
};
