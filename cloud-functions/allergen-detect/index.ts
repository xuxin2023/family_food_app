interface AllergenDetectRequest {
  ingredients: string[];
  memberAllergens: string[];
}

interface SuspectedAllergenResult {
  allergen: string;
  confidence: number;
  source: string;
}

interface AllergenDetectResult {
  detected: SuspectedAllergenResult[];
  crossReactivity: string[];
  riskLevel: 'high' | 'medium' | 'low';
}

const CROSS_REACTIVITY_MAP: Record<string, string[]> = {
  '花生': ['大豆', '扁豆', '豌豆'],
  '牛奶': ['山羊奶', '绵羊奶'],
  '鸡蛋': ['鸭蛋', '鹅蛋'],
  '小麦': ['大麦', '黑麦'],
  '虾': ['蟹', '龙虾'],
  '鱼': ['鳕鱼', '三文鱼'],
};

export const handler = async (event: { body: string }): Promise<AllergenDetectResult> => {
  const request: AllergenDetectRequest = JSON.parse(event.body);
  const { ingredients, memberAllergens } = request;

  const detected: SuspectedAllergenResult[] = [];
  const crossReactivity: string[] = [];

  for (const allergen of memberAllergens) {
    for (const ingredient of ingredients) {
      if (ingredient.includes(allergen) || allergen.includes(ingredient)) {
        detected.push({ allergen, confidence: 0.95, source: '直接匹配' });
      }
    }
    const related = CROSS_REACTIVITY_MAP[allergen] ?? [];
    for (const rel of related) {
      for (const ingredient of ingredients) {
        if (ingredient.includes(rel)) {
          crossReactivity.push(`${allergen} ↔ ${rel}`);
          detected.push({ allergen: rel, confidence: 0.6, source: `交叉反应(${allergen})` });
        }
      }
    }
  }

  const uniqueDetected = detected.filter((d, i) =>
    detected.findIndex(x => x.allergen === d.allergen) === i
  );

  const riskLevel: 'high' | 'medium' | 'low' =
    uniqueDetected.some(d => d.confidence >= 0.8) ? 'high' :
    uniqueDetected.length > 0 ? 'medium' : 'low';

  return { detected: uniqueDetected, crossReactivity: [...new Set(crossReactivity)], riskLevel };
};
