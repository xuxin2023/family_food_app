import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { common } from '@kit.AbilityKit';

const TAG = 'IngredientDeepAnalyzer';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface IngredientAnalysis {
  name: string;
  safetyLevel: 'SAFE' | 'CAUTION' | 'HARMFUL' | 'UNKNOWN';
  trafficLight: 'GREEN' | 'YELLOW' | 'RED' | 'GRAY';
  isAllergen: boolean;
  isHighFodmap: boolean;
  isHighHistamine: boolean;
  isHighSalicylate: boolean;
  healthRiskDescription: string;
  regulatoryStatus: 'APPROVED' | 'RESTRICTED' | 'BANNED' | 'UNDER_REVIEW' | 'UNKNOWN';
  researchReferences: Record<string, Object>[];
  adi?: number;
  alternativeName?: string;
}

interface IngredientKbEntry {
  name: string;
  safetyLevel: string;
  trafficLight: string;
  isAllergen: boolean;
  isHighFodmap: boolean;
  isHighHistamine: boolean;
  isHighSalicylate: boolean;
  healthRiskDesc: string;
  regulatoryStatus: string;
  adi?: number;
  references: Record<string, Object>[];
}

export class IngredientDeepAnalyzer {
  private static instance: IngredientDeepAnalyzer | null = null;
  private knowledgeBase: Map<string, IngredientKbEntry> = new Map();
  private loaded: boolean = false;

  static getInstance(): IngredientDeepAnalyzer {
    if (!IngredientDeepAnalyzer.instance) {
      IngredientDeepAnalyzer.instance = new IngredientDeepAnalyzer();
    }
    return IngredientDeepAnalyzer.instance;
  }

  async loadKnowledgeBase(context: common.Context): Promise<void> {
    if (this.loaded) return;

    try {
      const resMgr = context.resourceManager;
      const raw = resMgr.getRawFileContentSync('cn_additive_database.json');
      const text = String.fromCharCode(...raw);
      const data = JSON.parse(text);

      if (data.additives && Array.isArray(data.additives)) {
        for (const item of data.additives) {
          const entry: IngredientKbEntry = {
            name: item.name ?? item.code ?? '',
            safetyLevel: item.riskLevel ?? 'UNKNOWN',
            trafficLight: item.riskLevel === 'SAFE' ? 'GREEN' :
              item.riskLevel === 'CAUTION' ? 'YELLOW' :
              item.riskLevel === 'HARMFUL' ? 'RED' : 'GRAY',
            isAllergen: false,
            isHighFodmap: false,
            isHighHistamine: false,
            isHighSalicylate: false,
            healthRiskDesc: item.description ?? '',
            regulatoryStatus: item.regulatoryStatus ?? 'UNKNOWN',
            adi: item.adi,
            references: item.references ?? []
          };
          if (entry.name) {
            this.knowledgeBase.set(entry.name.toLowerCase(), entry);
          }
        }
      }

      this.loaded = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Knowledge base loaded: %{public}d entries', this.knowledgeBase.size);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Failed to load KB: %{public}s', JSON.stringify(error));
    }
  }

  analyzeIngredient(ingredientName: string): IngredientAnalysis {
    const normalized = ingredientName.trim().toLowerCase();

    const kbEntry = this.knowledgeBase.get(normalized);
    if (kbEntry) {
      return this.kbEntryToAnalysis(kbEntry);
    }

    for (const [key, entry] of this.knowledgeBase) {
      if (normalized.includes(key) || key.includes(normalized)) {
        return this.kbEntryToAnalysis(entry);
      }
    }

    return {
      name: ingredientName,
      safetyLevel: 'UNKNOWN',
      trafficLight: 'GRAY',
      isAllergen: false,
      isHighFodmap: false,
      isHighHistamine: false,
      isHighSalicylate: false,
      healthRiskDescription: '该成分安全性数据待补充，建议谨慎',
      regulatoryStatus: 'UNKNOWN',
      researchReferences: []
    };
  }

  analyzeIngredients(ingredients: string[]): IngredientAnalysis[] {
    return ingredients.map(i => this.analyzeIngredient(i));
  }

  getHarmfulCount(results: IngredientAnalysis[]): number {
    return results.filter(r => r.safetyLevel === 'HARMFUL').length;
  }

  getCautionCount(results: IngredientAnalysis[]): number {
    return results.filter(r => r.safetyLevel === 'CAUTION').length;
  }

  getUnknownCount(results: IngredientAnalysis[]): number {
    return results.filter(r => r.safetyLevel === 'UNKNOWN').length;
  }

  private kbEntryToAnalysis(entry: IngredientKbEntry): IngredientAnalysis {
    return {
      name: entry.name,
      safetyLevel: entry.safetyLevel as IngredientAnalysis.safetyLevel,
      trafficLight: entry.trafficLight as IngredientAnalysis.trafficLight,
      isAllergen: entry.isAllergen,
      isHighFodmap: entry.isHighFodmap,
      isHighHistamine: entry.isHighHistamine,
      isHighSalicylate: entry.isHighSalicylate,
      healthRiskDescription: entry.healthRiskDesc,
      regulatoryStatus: entry.regulatoryStatus as IngredientAnalysis.regulatoryStatus,
      researchReferences: entry.references,
      adi: entry.adi
    };
  }
}
