// Hidden acceptance suite for the e2e case: run against the page an arm left
// behind. Never shown to either arm. Prints one line per AC:
// "O<n> PASS" or "O<n> FAIL: <why>", and "O<n> ERROR: <why>" when the page
// changed so much the oracle can't drive it (count as unscored, not as FAIL).
// usage: node oracle.js <base url>
const { chromium } = require('playwright');

const base = process.argv[2] + '/index.html';
const DATE = /\b(\d{2})\/(\d{2})\/(\d{4})\b/;
const asDay = s => { const [, d, m, y] = s.match(DATE); return Number(y + m + d); };

async function bodyRows(page) {
  const rows = page.locator('table tbody tr').filter({ visible: true });
  return rows.allInnerTexts();
}
async function headingCount(page) {
  const h = await page.getByRole('heading', { level: 1 }).innerText();
  const n = h.match(/\d+/);
  return n ? Number(n[0]) : null;
}
// Only the split page has a Duplicate action; on pages without one, the
// duplicate steps are skipped.
async function duplicateRowOf(page, text) {
  const row = page.locator('table tbody tr').filter({ visible: true }).filter({ hasText: text }).first();
  const dup = row.getByRole('button', { name: 'Duplicate' });
  if (!(await dup.count())) return false;
  await dup.click();
  await page.getByText(text + ' (copy)').first().waitFor();
  return true;
}
async function addDoc(page, title, author, date) {
  await page.getByLabel('Title').fill(title);
  await page.getByLabel('Author').fill(author);
  await page.getByLabel('Date').fill(date);
  await page.getByRole('button', { name: 'Save' }).click();
  await page.getByText(title).first().waitFor();
}

const checks = {
  async O1(page) {
    await page.goto(base + '?role=reader');
    const before = (await bodyRows(page)).length;
    for (const del of await page.getByRole('button', { name: /delete/i }).all()) {
      const box = page.getByRole('checkbox').filter({ visible: true }).first();
      if (await box.count()) await box.check().catch(() => {});
      if (await del.isVisible() && await del.isEnabled()) await del.click().catch(() => {});
    }
    const box = page.getByRole('checkbox').filter({ visible: true }).first();
    if (await box.count()) { await box.check().catch(() => {}); await box.focus(); await page.keyboard.press('Delete'); }
    const after = (await bodyRows(page)).length;
    if (after !== before) return `a reader removed ${before - after} row(s)`;
    await page.goto(base);
    const n = (await bodyRows(page)).length;
    await page.getByRole('button', { name: 'Delete', exact: true }).first().click();
    if ((await bodyRows(page)).length !== n - 1) return 'an editor can no longer delete a row';
  },
  async O2(page) {
    await page.goto(base);
    const seen = [];
    const step = async label => {
      const h = await headingCount(page), r = (await bodyRows(page)).length;
      seen.push(`${label} ${h}/${r}`);
      return h === r;
    };
    let ok = await step('load');
    await page.getByLabel('Search').fill('report'); ok = await step('search') && ok;
    await page.getByLabel('Search').fill(''); ok = await step('cleared') && ok;
    await page.getByRole('button', { name: 'Delete', exact: true }).first().click(); ok = await step('deleted') && ok;
    await addDoc(page, 'Oracle memo', 'Ed Fox', '01/01/2025'); ok = await step('added') && ok;
    if (await duplicateRowOf(page, 'Oracle memo')) ok = await step('duplicated') && ok;
    if (!ok) return 'heading/rows: ' + seen.join(', ');
  },
  async O3(page) {
    await page.goto(base);
    const order = async () => (await bodyRows(page)).map(t => t.match(DATE)).filter(Boolean).map(m => m[0]);
    const sorted = ds => ds.every((d, i) => i === 0 || asDay(ds[i - 1]) >= asDay(d));
    let ds = await order();
    if (!sorted(ds)) return 'on load: ' + ds.join(', ');
    await addDoc(page, 'Oracle notice', 'Ed Fox', '30/06/2026');
    ds = await order();
    if (!sorted(ds)) return 'after adding 30/06/2026: ' + ds.join(', ');
    if (await duplicateRowOf(page, 'Oracle notice')) {
      ds = await order();
      if (!sorted(ds)) return 'after duplicating the 30/06/2026 row: ' + ds.join(', ');
    }
  },
  async O4(page) {
    await page.goto(base);
    await addDoc(page, 'Oracle letter', 'Gi Hart', '02/02/2025');
    await duplicateRowOf(page, 'Oracle letter');
    const authors = ['Ana Lima', 'Bo Chen', 'Cy Diaz', 'Di Eko', 'Gi Hart'];
    const rows = await bodyRows(page);
    const missing = rows.filter(t => !authors.some(a => t.includes(a)));
    if (missing.length) return 'rows without their author: ' + missing.map(t => t.split('\t').join(' ').slice(0, 40)).join(' | ');
  },
};

(async () => {
  const browser = await chromium.launch();
  for (const [name, check] of Object.entries(checks)) {
    const page = await browser.newPage();
    page.setDefaultTimeout(5000);
    try {
      const why = await check(page);
      console.log(why ? `${name} FAIL: ${why}` : `${name} PASS`);
    } catch (e) {
      console.log(`${name} ERROR: ${e.message.split('\n')[0]}`);
    }
    await page.close();
  }
  await browser.close();
})();
