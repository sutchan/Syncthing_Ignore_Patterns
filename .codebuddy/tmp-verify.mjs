import fs from 'fs';
const p = '.stignore';
let s = fs.readFileSync(p, 'utf8');
const before = (s.match(/[^\x00-\x7F]/g) || []).length;
s = s.replace(/\u2014/g, '-');
fs.writeFileSync(p, s, 'utf8');
const after = (fs.readFileSync(p, 'utf8').match(/[^\x00-\x7F]/g) || []).length;
console.log('em dash 替换: ' + before + ' -> ' + after + ' 个非 ASCII 字符');
