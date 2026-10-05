// Run against an assembled report containing accepted Ruby matrix results.
const {chromium} = require('playwright');
const assert = require('node:assert/strict');
const {pathToFileURL} = require('node:url');
const path = require('node:path');

(async () => {
  const browser = await chromium.launch({headless:true, executablePath:process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE});
  const errors = [];
  try {
    for (const viewport of [{width:1440,height:1000},{width:375,height:812}]) {
      const page = await browser.newPage({viewport});
      page.on('pageerror', error => errors.push(error.message));
      const url = pathToFileURL(path.resolve(process.argv[2])).href;
      await page.goto(url+'#parity');
      await page.waitForSelector('#ruby-matrix-lead:not([hidden])');
      const matrix = await page.evaluate(() => data.rubyMatrix);
      assert.ok(matrix.versions.length > 1);
      assert.match(await page.locator('#ruby-matrix-lead').innerText(),new RegExp(matrix.versions.length+' Ruby versions'));
      assert.equal(await page.locator('#left').evaluate(el=>el.getBoundingClientRect().bottom < innerHeight),true);
      await page.click('nav a[href="#ruby-matrix"]');
      await page.waitForSelector('nav a[href="#ruby-matrix"][aria-current="page"]');
      assert.equal(await page.locator('nav a[href="#ruby-matrix"]').getAttribute('aria-current'),'page');
      assert.equal(await page.locator('#ruby-matrix-table tbody tr').count(),matrix.versions.length);
      for (const [index,entry] of matrix.versions.entries()) {
        const row = page.locator('#ruby-matrix-table tbody tr').nth(index);
        assert.match(await row.locator('th').innerText(),new RegExp(entry.runtime.version.replaceAll('.','\\.')));
        assert.match(await row.locator('td').first().innerText(),new RegExp(entry.tests.length+' passed'));
        if (entry.telemetry?.status === 'verified') {
          assert.match(await row.locator('.ruby-telemetry').innerText(),new RegExp(entry.telemetry.scenarios.length+' scenarios passed'));
          assert.ok(await page.locator('#left option').evaluateAll((options, profile)=>options.some(option=>option.value===profile),entry.telemetry.profile));
          const href = await row.locator('.ruby-telemetry a').getAttribute('href');
          await page.goto(url+href);
          await page.waitForFunction(profile=>document.querySelector('#left').value===profile,entry.telemetry.profile);
          assert.equal(await page.locator('#scenario').inputValue(),'articles');
          assert.doesNotMatch(await page.locator('#compare-body').innerText(),/Capture unavailable|no accepted capture/);
          assert.match(await page.locator('#compare-body').innerText(),/revision/);
          await page.goto(url+'#ruby-matrix');
        } else if (entry.telemetry?.status === 'unsupported') {
          assert.match(await row.locator('.ruby-telemetry').innerText(),/Unsupported/);
          assert.ok((await row.locator('.ruby-telemetry').innerText()).includes(entry.telemetry.reason));
          assert.equal(await row.locator('.ruby-telemetry a').count(),0);
        }
      }
      await page.locator('#ruby-matrix-table details > summary').first().click();
      assert.equal(await page.locator('#ruby-matrix-table details').first().locator('li').count(),matrix.versions[0].tests.length);
      await page.locator('#ruby-matrix-evidence').locator('..').locator('summary').click();
      assert.match(await page.locator('#ruby-matrix-evidence').innerText(),new RegExp(matrix.responseSha256));
      assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth <= innerWidth),true);
      await page.screenshot({path:'/tmp/rules-stests-ruby-matrix-'+viewport.width+'.png'});
      await page.close();
    }
    assert.deepEqual(errors,[]);
    console.log('Ruby matrix report browser checks passed at desktop and mobile widths.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exit(1); });
