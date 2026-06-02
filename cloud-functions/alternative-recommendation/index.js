const cloudDb = require('@hw-agcloud/cloud-database');

const WEIGHTS = { nutriScore: 40, allergenSafe: 30, additiveReduction: 20, price: 10 };

function calcScore(candidate, original) {
  let total = 0;
  total += (candidate.nutriScoreValue - original.nutriScoreValue) * 10 * WEIGHTS.nutriScore / 100;
  total += (candidate.allergenSafe ? 1 : 0) * WEIGHTS.allergenSafe;
  total += Math.min(candidate.additiveReduction / 2, 10) * WEIGHTS.additiveReduction / 100;
  total += Math.max((original.priceValue - candidate.priceValue) / original.priceValue * 10, 0) * WEIGHTS.price / 100;
  return total;
}

exports.handler = async (event, context) => {
  try {
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    const foodId = body.foodId;
    const allergenProfile = body.allergenProfile || [];

    if (!foodId) { return { statusCode: 400, body: JSON.stringify({ error: 'Missing foodId' }) }; }

    const db = cloudDb.database();
    const cacheCol = db.collection('alternative_cache');
    const cacheKey = `alt_${foodId}_${allergenProfile.sort().join('_')}`;
    const cached = await cacheCol.where({ key: cacheKey }).get();

    if (cached.data && cached.data.length > 0) {
      const entry = cached.data[0];
      if (Date.now() - entry.updatedAt < 24 * 60 * 60 * 1000) {
        return { statusCode: 200, body: JSON.stringify({ source: 'cache', alternatives: entry.data }) };
      }
    }

    const foodCol = db.collection('food_labels');
    const original = await foodCol.where({ foodId }).get();
    if (!original.data || original.data.length === 0) {
      return { statusCode: 404, body: JSON.stringify({ error: 'Food not found' }) };
    }
    const origFood = original.data[0];

    const candidates = await foodCol.where({
      category: origFood.category,
      _id: { $ne: origFood._id }
    }).limit(50).get();

    const ranked = (candidates.data || [])
      .map((c: { nutriScoreValue: number; allergenSafe: boolean; additiveReduction: number; priceValue: number }) => ({
        ...c,
        score: calcScore(c, origFood),
        nutriScoreDiff: c.nutriScoreValue - origFood.nutriScoreValue,
        allergenSafe: !c.allergenList?.some((a: string) => allergenProfile.includes(a))
      }))
      .filter((c: { score: number; nutriScoreDiff: number }) => c.score > 0 && c.nutriScoreDiff >= 1)
      .sort((a: { score: number }, b: { score: number }) => b.score - a.score)
      .slice(0, 5);

    await cacheCol.add({
      key: cacheKey,
      data: ranked,
      updatedAt: Date.now()
    });

    return { statusCode: 200, body: JSON.stringify({ source: 'fresh', alternatives: ranked }) };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: String(err) }) };
  }
};