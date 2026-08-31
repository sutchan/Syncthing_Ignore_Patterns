import fs from 'fs';

const L = fs.readFileSync('.stignore', 'utf8').split(/\r?\n/);
let cats = [], cur = null, rules = [], negs = [];
L.forEach((l, i) => {
  const s = l.trim();
  if (!s) return;
  if (s.startsWith('//')) {
    // 分类标题 = 非头部(前3行)且非 NOTE 续行
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
const dup = Object.keys(m).filter(k => m[k] > 1);
console.log('重复规则 = ' + (dup.length ? JSON.stringify(dup) : '无'));

// 风格检查：目录模式(含 /) 必须以 / 结尾；文件模式不应以 / 结尾
console.log('\n--- 风格异常 ---');
let bad = 0;
for (const r of rules) {
  const isDirName = /^[A-Za-z0-9._ @#\-+]+$/.test(r) && !r.includes('*');
  const hasSlash = r.includes('/');
  const endsSlash = r.endsWith('/');
  // 目录型：不含通配符且以 / 结尾 -> ok
  if (hasSlash && !endsSlash && !r.includes('*') && !r.includes('?')) {
    console.log('  目录缺尾斜杠? ' + r); bad++;
  }
  if (!hasSlash && endsSlash) { console.log('  异常: ' + r); bad++; }
}
console.log('风格异常数 = ' + bad);

// 取反规则前必须有同名族的正向规则
console.log('\n--- 取反检查 ---');
for (const n of negs) {
  const base = n.slice(1);
  const ok = rules.some(r => r.endsWith('.lock'));
  console.log('  ' + n + '   (前置正向 .lock 规则存在: ' + ok + ')');
}
