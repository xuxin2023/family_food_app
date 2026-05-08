@echo off
node -e "
const fs = require('fs');
const base = JSON.parse(fs.readFileSync('E:/APP/family_food_app/entry/src/main/resources/base/element/string.json','utf8'));
const zh = JSON.parse(fs.readFileSync('E:/APP/family_food_app/entry/src/main/resources/zh_CN/element/string.json','utf8'));
const en = JSON.parse(fs.readFileSync('E:/APP/family_food_app/entry/src/main/resources/en_US/element/string.json','utf8'));

// Build lookup maps
const zhMap = new Map();
zh.string.forEach(x => zhMap.set(x.name, x.value));
const enMap = new Map();
en.string.forEach(x => enMap.set(x.name, x.value));

// New zh_CN: keep existing zh values, use base values for missing
const newZh = base.string.map(x => ({
  name: x.name,
  value: zhMap.has(x.name) ? zhMap.get(x.name) : x.value
}));

// New en_US: keep existing en values, use base values for missing
const newEn = base.string.map(x => ({
  name: x.name,
  value: enMap.has(x.name) ? enMap.get(x.name) : x.value
}));

fs.writeFileSync('E:/APP/family_food_app/entry/src/main/resources/zh_CN/element/string.json', JSON.stringify({string: newZh}, null, 2));
fs.writeFileSync('E:/APP/family_food_app/entry/src/main/resources/en_US/element/string.json', JSON.stringify({string: newEn}, null, 2));
console.log('Done! zh_CN:', newZh.length, 'en_US:', newEn.length);

// Print what was added
console.log('=== Added to zh_CN ===');
base.string.forEach(x => { if (!zhMap.has(x.name)) console.log(x.name, ':', x.value); });
console.log('=== Added to en_US ===');
base.string.forEach(x => { if (!enMap.has(x.name)) console.log(x.name, ':', x.value); });
"
