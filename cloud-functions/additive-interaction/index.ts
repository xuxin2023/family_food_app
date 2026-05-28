import cloudDB from '@hw-agcloud/cloud-database';

interface InteractionRequest {
  additives: string[];
  memberProfile?: Record<string, Object>;
}

interface InteractionPair {
  additive_a: string;
  additive_b: string;
  risk_level: number;
  description: string;
  affected_systems: string[];
}

interface InteractionResult {
  score: number;
  riskyPairs: InteractionPair[];
  recommendations: string[];
}

const INTERACTION_DB = new Map<string, InteractionPair>([
  ['E621|E627', { additive_a: 'E621', additive_b: 'E627', risk_level: 4, description: '谷氨酸钠与鸟苷酸二钠协同增强鲜味，过量刺激神经系统', affected_systems: ['神经系统'] }],
  ['E250|E251', { additive_a: 'E250', additive_b: 'E251', risk_level: 5, description: '亚硝酸钠与亚硝酸钾协同增加亚硝胺形成风险', affected_systems: ['致癌风险'] }],
  ['E211|E202', { additive_a: 'E211', additive_b: 'E202', risk_level: 3, description: '苯甲酸钠与山梨酸钾可能形成微量苯', affected_systems: ['致癌风险'] }],
]);

export const handler = async (event: { body: string }): Promise<InteractionResult> => {
  const request: InteractionRequest = JSON.parse(event.body);
  const { additives } = request;

  const riskyPairs: InteractionPair[] = [];

  for (let i = 0; i < additives.length; i++) {
    for (let j = i + 1; j < additives.length; j++) {
      const key1 = `${additives[i]}|${additives[j]}`;
      const key2 = `${additives[j]}|${additives[i]}`;
      const interaction = INTERACTION_DB.get(key1) ?? INTERACTION_DB.get(key2);
      if (interaction) {
        riskyPairs.push(interaction);
      }
    }
  }

  let score = 0;
  if (riskyPairs.length > 0) {
    score = Math.round(
      Math.max(...riskyPairs.map(p => p.risk_level)) * 0.6 +
      riskyPairs.reduce((s, p) => s + p.risk_level, 0) / riskyPairs.length * 0.4
    );
  }

  const recommendations: string[] = [];
  if (score >= 4) recommendations.push('存在高风险交互组合，建议减少摄入频率');
  if (riskyPairs.some(p => p.affected_systems.includes('致癌风险'))) {
    recommendations.push('检测到潜在致癌交互，长期食用需谨慎');
  }

  return { score, riskyPairs, recommendations };
};
