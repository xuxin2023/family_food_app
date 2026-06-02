const cloudDb = require('@hw-agcloud/cloud-database');

const HAZARD_LEVELS = { 0: 'safe', 1: 'attention', 2: 'warning', 3: 'danger' };
const HAZARD_COLORS = { 0: '#2E7D32', 1: '#F9A825', 2: '#E65100', 3: '#C62828' };

exports.handler = async (event, context) => {
  try {
    const code = (event.queryStringParameters?.code || '').toUpperCase().trim();
    const locale = event.queryStringParameters?.locale || 'zh';

    if (!code || code.length < 3) {
      return { statusCode: 400, body: JSON.stringify({ error: 'Missing or invalid additive code' }) };
    }

    const db = cloudDb.database();
    const result = await db.collection('additive_entries').where({ code }).get();

    if (!result.data || result.data.length === 0) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          code,
          name: code,
          hazardLevel: 'unknown',
          hazardColor: '#9E9E9E',
          message: '该添加剂暂无评估数据',
          sources: []
        })
      };
    }

    const entry = result.data[0];
    return {
      statusCode: 200,
      body: JSON.stringify({
        code: entry.code,
        name: entry.name || entry.code,
        nameEn: entry.nameEn || '',
        hazardLevel: HAZARD_LEVELS[entry.hazard] || 'unknown',
        hazardColor: HAZARD_COLORS[entry.hazard] || '#9E9E9E',
        adi: entry.adi || '未设定',
        efsaRef: entry.efsaRef || '',
        gb2760Status: entry.gb2760Status || '未知',
        interactions: entry.interactions || [],
        description: entry.description || ''
      })
    };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: String(err) }) };
  }
};