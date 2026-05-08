const fs = require('fs');
const basePath = 'E:/APP/family_food_app/entry/src/main/resources';
const base = JSON.parse(fs.readFileSync(basePath + '/base/element/string.json','utf8'));
const zh = JSON.parse(fs.readFileSync(basePath + '/zh_CN/element/string.json','utf8'));
const en = JSON.parse(fs.readFileSync(basePath + '/en_US/element/string.json','utf8'));

// Build lookup maps
const zhMap = new Map();
zh.string.forEach(x => zhMap.set(x.name, x.value));
const enMap = new Map();
en.string.forEach(x => enMap.set(x.name, x.value));

// New zh_CN: keep existing zh values, fallback to base
const newZh = base.string.map(x => ({ name: x.name, value: zhMap.has(x.name) ? zhMap.get(x.name) : x.value }));
// New en_US: keep existing en values, fallback to base
const newEn = base.string.map(x => ({ name: x.name, value: enMap.has(x.name) ? enMap.get(x.name) : x.value }));

// Write the output as a report file
const reportPath = 'E:/APP/family_food_app/_i18n_result.json';
const result = {
  summary: {
    zh_CN_total: newZh.length,
    zh_CN_original: zh.string.length,
    zh_CN_added: newZh.length - zh.string.length,
    en_US_total: newEn.length,
    en_US_original: en.string.length,
    en_US_added: newEn.length - en.string.length
  },
  added_zh_CN: base.string.filter(x => !zhMap.has(x.name)).map(x => ({name: x.name, value: x.value})),
  added_en_US: base.string.filter(x => !enMap.has(x.name)).map(x => ({name: x.name, value: x.value}))
};
fs.writeFileSync(reportPath, JSON.stringify(result, null, 2));
console.log('Report written to ' + reportPath);
