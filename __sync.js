const fs = require('fs');
const base = JSON.parse(fs.readFileSync('entry/src/main/resources/base/element/string.json', 'utf8'));
const zh = JSON.parse(fs.readFileSync('entry/src/main/resources/zh_CN/element/string.json', 'utf8'));
const zk = {};
zh.string.forEach(i => { zk[i.name] = i.value; });
const merged = base.string.map(item => ({
  name: item.name,
  value: zk[item.name] !== undefined ? zk[item.name] : item.value
}));
const out = JSON.stringify({ string: merged });
fs.writeFileSync('entry/src/main/resources/zh_CN/element/string.json', out, 'utf8');
// Also do the same for en_US
const en = JSON.parse(fs.readFileSync('entry/src/main/resources/en_US/element/string.json', 'utf8'));
const ek = {};
en.string.forEach(i => { ek[i.name] = i.value; });
const enMerged = base.string.map(item => ({
  name: item.name,
  value: ek[item.name] !== undefined ? ek[item.name] : item.value
}));
const enOut = JSON.stringify({ string: enMerged });
fs.writeFileSync('entry/src/main/resources/en_US/element/string.json', enOut, 'utf8');
console.log('Done: zh_CN=' + merged.length + ' en_US=' + enMerged.length);
