// [AC0] The documents screen opens with its heading.
// Run: BASE_URL=http://localhost:8000 node checks/ac0-page-title.js
const { chromium } = require('playwright');
const { expect } = require('playwright/test');

(async () => {
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage();
    await page.goto(process.env.BASE_URL + '/index.html');
    await expect(page.getByRole('heading', { name: 'Documents', level: 1 })).toBeVisible();
    console.log('[AC0] PASS');
  } catch (e) {
    console.log('[AC0] FAIL: ' + e.message.split('\n')[0]);
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
})();
