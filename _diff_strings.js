const fs = require('fs');
const base = JSON.parse(fs.readFileSync('E:/APP/family_food_app/entry/src/main/resources/base/element/string.json','utf8'));
const zh = JSON.parse(fs.readFileSync('E:/APP/family_food_app/entry/src/main/resources/zh_CN/element/string.json','utf8'));
const en = JSON.parse(fs.readFileSync('E:/APP/family_food_app/entry/src/main/resources/en_US/element/string.json','utf8'));
const baseKeys = new Set(base.string.map(x => x.name));
const zhKeys = new Set(zh.string.map(x => x.name));
const enKeys = new Set(en.string.map(x => x.name));

const missingZH = [...baseKeys].filter(k => !zhKeys.has(k)).sort();
const missingEN = [...baseKeys].filter(k => !enKeys.has(k)).sort();

console.log('=== Missing in zh_CN (' + missingZH.length + ') ===');
missingZH.forEach(k => console.log(k));
console.log('\n=== Missing in en_US (' + missingEN.length + ') ===');
missingEN.forEach(k => console.log(k));
