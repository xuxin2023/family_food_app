interface AlternativeSearchRequest {
  query: string;
  allergens?: string[];
  maxResults?: number;
}

interface AlternativeItem {
  foodId: string;
  foodName: string;
  brand: string;
  nutriScore: number;
  matchReason: string;
  similarity: number;
}

interface AlternativeSearchResponse {
  alternatives: AlternativeItem[];
  total: number;
  query: string;
}

export const handler = async (
  event: { body?: string },
  context: Record<string, Object>
): Promise<AlternativeSearchResponse> => {
  const req: AlternativeSearchRequest = typeof event.body === 'string'
    ? JSON.parse(event.body) : (event.body ?? event) as unknown as AlternativeSearchRequest;

  const maxResults = req.maxResults ?? 10;
  const allergens = req.allergens ?? [];

  // GaussDB 向量检索占位 — 生产环境对接 GaussDB Vector Engine
  // SELECT food_id, food_name, brand, nutri_score,
  //   cosine_similarity(embedding, query_embedding) AS similarity
  // FROM food_vector_index
  // WHERE NOT EXISTS (SELECT 1 FROM unnest(allergen_list) a WHERE a = ANY($allergens))
  // ORDER BY similarity DESC
  // LIMIT $maxResults

  const alternatives: AlternativeItem[] = [];

  return {
    alternatives,
    total: alternatives.length,
    query: req.query
  };
};
