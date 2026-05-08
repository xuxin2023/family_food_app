import { readFileSync, writeFileSync } from 'fs';

const base = JSON.parse(readFileSync('entry/src/main/resources/base/element/string.json', 'utf-8'));
const zh = JSON.parse(readFileSync('entry/src/main/resources/zh_CN/element/string.json', 'utf-8'));

const bk = {}, zk = {};
base.string.forEach(i => bk[i.name] = i.value);
zh.string.forEach(i => zk[i.name] = i.value);

const missing = [];
Object.keys(bk).forEach(k => {
  if (!zk[k]) missing.push({ name: k, value: bk[k] });
});

const result = [];
result.push('Missing count: ' + missing.length);
missing.forEach(m => result.push(m.name + '|' + m.value));
writeFileSync('__diff_result.txt', result.join('\n'), 'utf-8');
console.log('Done, wrote __diff_result.txt');
