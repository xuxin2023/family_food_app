import { readFileSync, writeFileSync } from 'node:fs';
const base = JSON.parse(readFileSync('entry/src/main/resources/base/element/string.json', 'utf-8'));
const zh = JSON.parse(readFileSync('entry/src/main/resources/zh_CN/element/string.json', 'utf-8'));
const bk = {}, zk = {};
base.string.forEach(i => bk[i.name] = i.value);
zh.string.forEach(i => zk[i.name] = i.value);
// Merge: keep zh values where exist, use base for missing
const merged = [];
base.string.forEach(item => {
  if (zk[item.name] !== undefined) {
    merged.push({ name: item.name, value: zk[item.name] });
  } else {
    merged.push({ name: item.name, value: item.value });
  }
});
writeFileSync('entry/src/main/resources/zh_CN/element/string.json', JSON.stringify({ string: merged }) + '\n', 'utf-8');
console.log('Merged ' + merged.length + ' entries, added ' + (merged.length - zh.string.length) + ' missing keys');
