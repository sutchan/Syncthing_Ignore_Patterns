import fs from 'fs';

const raw = fs.readFileSync('.stignore', 'utf8');
const L = raw.split(/\r?\n/);
let cats = [], cur = null, rules = [], negs = [];
L.forEach((l, i) => {
  const s = l.trim();
  if (!s) return;
  if (s.startsWith('//')) {
    if (i > 2 && !s.startsWith('// ')) {
      cur = { name: s.slice(2).trim(), n: 0, line: i + 1 };
      cats.push(cur);
    }
    return;
  }
  if (cur) cur.n++;
  if (s.startsWith('!')) { negs.push(s); return; }
  rules.push(s);
});

console.log('分类数 = ' + cats.length);
cats.forEach((c, i) => console.log('  ' + (i + 1) + '. ' + c.name + '  (' + c.n + ')'));
console.log('规则数 = ' + (rules.length + negs.length) + '  正向=' + rules.length + ' 取反=' + negs.length);

const m = {};
rules.forEach(r => { m[r] = (m[r] || 0) + 1; });
console.log('重复规则 = ' + (JSON.stringify(Object.keys(m).filter(k => m[k] > 1))));

// 检查所有行是否纯 ASCII
const nonAscii = raw.split(/\r?\n/).map((l, i) => [i + 1, l]).filter(([, l]) => /[^\x00-\x7F]/.test(l));
console.log('非 ASCII 行 = ' + (nonAscii.length ? JSON.stringify(nonAscii.slice(0, 5)) : '无'));

// 缓存/临时相关规则盘点
console.log('\n--- cache / temp 相关规则 ---');
L.forEach((l, i) => {
  const s = l.trim();
  if (!s || s.startsWith('//')) return;
  if (/cache|temp|tmp|thumb|storage/i.test(s)) console.log('  ' + (i + 1) + ': ' + s);
});
