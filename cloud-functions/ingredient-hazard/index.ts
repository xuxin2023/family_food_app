const cloudDb = require('@hw-agcloud/cloud-database');

const HAZARD_SCORES = { safe: 0, attention: 1, warning: 2, danger: 3 };
const MAX_INGREDIENTS = 50;

function overallRisk(results) {
  const scores = results.map((r: { hazardScore: number }) => r.hazardScore);
  if (scores.length === 0) return 'safe';
  const max = Math.max(...scores);
  const avg = scores.reduce((a: number, b: number) => a + b, 0) / scores.length;
  if (max >= 3 && avg >= 2) return 'danger';
  if (max >= 2 || avg >= 1.5) return 'warning';
  if (avg >= 1) return 'attention';
  return 'safe';
}

exports.handler = async (event, context) => {
  try {
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    const ingredients = body.ingredients || [];

    if (!Array.isArray(ingredients) || ingredients.length === 0) {
      return { statusCode: 400, body: JSON.stringify({ error: 'Missing ingredients array' }) };
    }
    if (ingredients.length > MAX_INGREDIENTS) {
      return { statusCode: 400, body: JSON.stringify({ error: `Max ${MAX_INGREDIENTS} ingredients allowed` }) };
    }

    const db = cloudDb.database();
    const additiveCol = db.collection('additive_entries');

    const results = [];
    for (const ing of ingredients) {
      const code = (ing.code || '').toUpperCase().trim();
      if (!code) {
        results.push({ code, name: ing.name || code, hazardScore: 0, hazardLevel: 'unknown', riskFactor: null });
        continue;
      }
      const found = await additiveCol.where({ code }).get();
      if (found.data && found.data.length > 0) {
        const e = found.data[0];
        results.push({
          code: e.code, name: e.name || e.code, hazardScore: HAZARD_SCORES[e.hazard] || 0,
          hazardLevel: e.hazard || 'unknown', riskFactor: e.riskFactor || null,
          adi: e.adi, gb2760Status: e.gb2760Status
        });
      } else {
        results.push({ code, name: ing.name || code, hazardScore: 0, hazardLevel: 'unknown', riskFactor: null });
      }
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        overallRisk: overallRisk(results),
        totalIngredients: ingredients.length,
        riskFactors: results.filter((r: { riskFactor: unknown }) => r.riskFactor !== null).map((r: { riskFactor: unknown }) => r.riskFactor),
        results
      })
    };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: String(err) }) };
  }
};