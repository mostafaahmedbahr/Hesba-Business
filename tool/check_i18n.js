// Verifies every easy_localization key used in lib/ exists in BOTH
// translation files. Reports missing keys (exit 1) or unused supplier keys.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const ar = JSON.parse(fs.readFileSync(path.join(root, 'assets/translations/ar.json'), 'utf8'));
const en = JSON.parse(fs.readFileSync(path.join(root, 'assets/translations/en.json'), 'utf8'));

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(p, out);
    else if (entry.name.endsWith('.dart')) out.push(p);
  }
  return out;
}

const used = new Set();
for (const file of walk(path.join(root, 'lib'))) {
  const src = fs.readFileSync(file, 'utf8');
  for (const m of src.matchAll(/'([A-Za-z0-9_]+)'\s*\.tr\b/g)) used.add(m[1]);
  // labelKey:/hintKey:/titleKey: string literals that end in .tr() elsewhere.
  for (const m of src.matchAll(/(?:labelKey|hintKey|titleKey|messageKey):\s*'([A-Za-z0-9_]+)'/g)) {
    used.add(m[1]);
  }
  // error keys thrown as Exception('x') and passed through translateError.
  for (const m of src.matchAll(/Exception\('(supplierErr[A-Za-z0-9_]+)'\)/g)) used.add(m[1]);
}

const missing = [...used].filter((k) => !(k in ar) || !(k in en)).sort();
const supplierUsed = [...used].filter((k) => k.startsWith('supplier')).sort();
const supplierUnused = Object.keys(ar)
  .filter((k) => k.startsWith('supplier') && !used.has(k))
  .sort();

console.log(`keys used in lib/: ${used.size}`);
console.log(`supplier keys used: ${supplierUsed.length}`);
if (missing.length) {
  console.log('\nMISSING FROM TRANSLATIONS:');
  for (const k of missing) console.log('  ' + k);
} else {
  console.log('\nAll used keys exist in both ar.json and en.json.');
}
if (supplierUnused.length) {
  console.log('\nSupplier keys defined but never referenced:');
  for (const k of supplierUnused) console.log('  ' + k);
}
process.exit(missing.length ? 1 : 0);
