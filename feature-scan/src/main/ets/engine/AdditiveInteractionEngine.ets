import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'AdditiveInteractionEngine';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface AdditiveInteraction {
  additiveA: string;
  additiveB: string;
  interactionType: 'synergistic' | 'antagonistic' | 'additive';
  riskLevel: number;
  description: string;
  affectedSystems: string[];
}

export interface InteractionAssessmentResult {
  overallRiskScore: number;
  riskyPairs: AdditiveInteraction[];
  safeAdditives: string[];
  warnings: string[];
  recommendations: string[];
}

const KNOWN_INTERACTIONS: AdditiveInteraction[] = [
  {
    additiveA: 'E621', additiveB: 'E627',
    interactionType: 'synergistic', riskLevel: 4,
    description: '谷氨酸钠与鸟苷酸二钠协同增强鲜味，过量刺激神经系统',
    affectedSystems: ['神经系统', '消化系统']
  },
  {
    additiveA: 'E250', additiveB: 'E251',
    interactionType: 'synergistic', riskLevel: 5,
    description: '亚硝酸钠与亚硝酸钾协同增加亚硝胺形成风险',
    affectedSystems: ['消化系统', '致癌风险']
  },
  {
    additiveA: 'E211', additiveB: 'E202',
    interactionType: 'synergistic', riskLevel: 3,
    description: '苯甲酸钠与山梨酸钾在酸性条件下可能形成微量苯',
    affectedSystems: ['致癌风险']
  },
  {
    additiveA: 'E102', additiveB: 'E110',
    interactionType: 'synergistic', riskLevel: 3,
    description: '柠檬黄与日落黄协同可能加重儿童多动症倾向',
    affectedSystems: ['神经系统']
  },
  {
    additiveA: 'E320', additiveB: 'E321',
    interactionType: 'synergistic', riskLevel: 4,
    description: 'BHA与BHT协同抗氧化效果增强，但致癌风险也协同增加',
    affectedSystems: ['致癌风险', '内分泌系统']
  },
];

export class AdditiveInteractionEngine {
  private static instance: AdditiveInteractionEngine | null = null;

  static getInstance(): AdditiveInteractionEngine {
    if (!AdditiveInteractionEngine.instance) {
      AdditiveInteractionEngine.instance = new AdditiveInteractionEngine();
    }
    return AdditiveInteractionEngine.instance;
  }

  assessInteractions(additives: string[]): InteractionAssessmentResult {
    const result: InteractionAssessmentResult = {
      overallRiskScore: 0,
      riskyPairs: [],
      safeAdditives: [...additives],
      warnings: [],
      recommendations: []
    };

    if (additives.length < 2) {
      result.overallRiskScore = 0;
      return result;
    }

    for (let i = 0; i < additives.length; i++) {
      for (let j = i + 1; j < additives.length; j++) {
        const interaction = this.findInteraction(additives[i], additives[j]);
        if (interaction) {
          result.riskyPairs.push(interaction);
          const idxA = result.safeAdditives.indexOf(additives[i]);
          if (idxA !== -1) result.safeAdditives.splice(idxA, 1);
          const idxB = result.safeAdditives.indexOf(additives[j]);
          if (idxB !== -1) result.safeAdditives.splice(idxB, 1);
        }
      }
    }

    if (result.riskyPairs.length > 0) {
      const maxRisk = Math.max(...result.riskyPairs.map(p => p.riskLevel));
      const avgRisk = result.riskyPairs.reduce((s, p) => s + p.riskLevel, 0) / result.riskyPairs.length;
      result.overallRiskScore = Math.round(maxRisk * 0.6 + avgRisk * 0.4);

      for (const pair of result.riskyPairs) {
        result.warnings.push(`${pair.additiveA} + ${pair.additiveB}: ${pair.description}`);
      }

      if (result.overallRiskScore >= 4) {
        result.recommendations.push('存在高风险添加剂交互，建议减少该食品摄入频率');
      }
      if (result.riskyPairs.some(p => p.affectedSystems.includes('致癌风险'))) {
        result.recommendations.push('检测到潜在致癌交互组合，长期食用需谨慎');
      }
      if (result.riskyPairs.some(p => p.affectedSystems.includes('神经系统'))) {
        result.recommendations.push('含神经系统刺激交互组合，儿童及敏感人群应避免');
      }
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Interaction assessment: %{public}d pairs, risk=%{public}d',
      result.riskyPairs.length, result.overallRiskScore);
    return result;
  }

  private findInteraction(a: string, b: string): AdditiveInteraction | null {
    for (const interaction of KNOWN_INTERACTIONS) {
      if ((interaction.additiveA === a && interaction.additiveB === b) ||
        (interaction.additiveA === b && interaction.additiveB === a)) {
        return interaction;
      }
    }
    return null;
  }
}
