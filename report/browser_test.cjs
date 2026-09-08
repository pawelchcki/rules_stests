// Run with NODE_PATH pointing to a Playwright installation. The HTML fixture is
// emitted by //report:report_test; no web server or external report assets needed.
const {chromium} = require('playwright');
const assert = require('node:assert/strict');
const {pathToFileURL} = require('node:url');
const path = require('node:path');
(async () => {
  const browser = await chromium.launch({headless:true, executablePath:process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE});
  const page = await browser.newPage({viewport:{width:1440,height:1000}});
  const errors=[]; page.on('pageerror',e=>{errors.push(e.message);console.error('Browser error:',e.message);});
  const url=pathToFileURL(path.resolve(process.argv[2])).href;
  const route=async hash=>{await page.goto(url+hash);await page.waitForTimeout(100);};
  await route('#parity?left=go&right=python&scenario=case');
  const pythonOverviewLink=await page.locator('#parity-overview tbody tr td').nth(1).locator('a').getAttribute('href');
  assert.match(pythonOverviewLink,/left=python/);assert.match(pythonOverviewLink,/right=go/);
  await page.evaluate(()=>{const trace=data.captureComparisons[0].traces[0];trace.left.card='';trace.right.card='';renderCompare();});
  assert.match(await page.locator('.capture-trace > summary').innerText(),/×1 \/ ×1/);
  await page.evaluate(()=>{data.scenarios.push('undeclared');renderParityOverview();});
  const excludedCell=await page.locator('#parity-overview tbody tr').last().locator('td').first().innerText();
  assert.match(excludedCell,/Not in this test suite/);assert.doesNotMatch(excludedCell,/No result for this build/);
  await page.goto('about:blank');
  await route('#health?profile=python');
  await page.click('nav a[href*="#parity"]');await page.waitForTimeout(100);
  assert.equal(await page.inputValue('#coverage-profile'),'go');
  await page.goto('about:blank');
  await route('#parity?profile=python');
  await page.click('nav a[href*="#health"]');await page.waitForTimeout(100);
  assert.equal(await page.inputValue('#profile'),'go');
  const crossProfileMatch=await page.evaluate(()=>{
    const feature=data.features[0];
    data.verification[feature.id].go={state:'not_exercised',evidence:[]};
    plannedByKey.delete('go '+feature.id);
    $('check-coverage').value='none';$('verification').value='verified';renderFeatures();
    return document.querySelectorAll('[data-feature="'+feature.id+'"]').length;
  });
  assert.equal(crossProfileMatch,0,'cell filters must match the same implementation');
  await page.goto('about:blank');
  await route('');
  assert.equal(await page.locator('#features').isVisible(),true);
  assert.match(await page.locator('#feature-matrix').innerText(),/assertions defined/);
  await page.selectOption('#language','python');
  await page.fill('#search','root');
  await page.click('nav a[href*="#parity"]');await page.waitForTimeout(100);
  assert.equal(await page.inputValue('#comparison-source'),'captured');
  assert.match(await page.locator('#compare-summary').innerText(),/0 differing/);
  assert.equal(await page.locator('.capture-tree tr').count(),0,'tree must be lazy');
  await page.click('.capture-trace > summary');await page.waitForSelector('[data-row]');
  assert.equal(await page.locator('[data-row]').count(),2);
  assert.match(await page.locator('.capture-trace > summary').innerText(),/×200 \/ ×200/);
  await page.click('[data-row="1"] > summary');await page.waitForSelector('[data-refs]');
  assert.match(await page.locator('[data-row="1"]').innerText(),/SELECT 0 <\/script>/);
  assert.equal(await page.locator('script').count(),2,'captured text must not escape JSON or HTML');
  await page.locator('[data-refs] > summary').first().click();await page.waitForSelector('[data-occurrence]');
  await page.locator('[data-occurrence]').first().click();
  assert.match(await page.locator('.occurrence-detail').innerText(),/18446744073709551615/);
  await page.selectOption('#field-view','raw');
  assert.match(await page.locator('#compare-summary').innerText(),/2 differing/);
  const before=await page.locator('#compare-summary').innerText();
  await page.click('#swap');assert.equal(await page.locator('#compare-summary').innerText(),before);
  await page.goBack();assert.equal(await page.inputValue('#left'),'go');
  await page.click('nav a[href*="#health"]');await page.waitForTimeout(100);
  assert.equal(await page.inputValue('#language'),'python');assert.equal(await page.inputValue('#search'),'root');
  await page.click('nav a[href*="#parity"]');await page.waitForTimeout(100);assert.equal(await page.inputValue('#field-view'),'raw');
  await route('#parity?left=go&right=python&scenario=case&trace=0&row=1');
  await page.waitForSelector('[data-row="1"][open]');
  assert.match(await page.locator('[data-row="1"]').innerText(),/span.attributes/);
  await route('#compare?left=go&right=python&scenario=case');assert.equal(await page.inputValue('#comparison-source'),'saved');
  await page.click('nav a[href*="#health"]');await page.waitForTimeout(100);await page.click('nav a[href*="#parity"]');await page.waitForTimeout(100);assert.equal(await page.inputValue('#comparison-source'),'saved');
  await route('#coverage?profile=python');assert.equal(await page.locator('#compare').isVisible(),true);assert.equal(await page.locator('#coverage').getAttribute('open'),'');
  await route('#overview?profile=python&verification=verified');assert.equal(await page.locator('#features').isVisible(),true);assert.equal(await page.inputValue('#verification'),'verified');
  await route('#health?profile=python&feature=traces.span.create-root-span');assert.equal(await page.locator('[data-feature][open]').count(),1);
  // Semantic comparison must ignore only protocol identities/timestamps, retain
  // array and event order, attribute spelling, types, scope, and relationships.
  const checks=await page.evaluate(()=>{
    const l=captureByKey.get('go/case'),r=JSON.parse(JSON.stringify(l)),row={left:[0],right:[0]};
    const diff=(raw=false,hide=false)=>captureRowDiff(l,r,row,raw,hide).diffs;
    const result={};
    r.spans[0].fields.traceId='f'.repeat(32);r.spans[0].fields.startTimeUnixNano='1';
    result.semantic=diff();result.raw=diff(true);
    r.scopes[0].metadata.name='other';result.scope=diff();result.hiddenScope=diff(false,true);
    r.spans[0].parent='external parent';result.parent=diff();
    r.spans[0].fields.attributes=[{key:'literal.name',value:{arrayValue:{values:[{intValue:'9223372036854775807'},{stringValue:'1'}]}}}];result.attributes=diff();
    return result;
  });
  assert.equal(checks.semantic.length,0);assert.ok(checks.raw.includes('span.traceId'));assert.ok(checks.scope.includes('scope.metadata.name'));assert.equal(checks.hiddenScope.length,0);assert.ok(checks.parent.includes('span.parentRelationship'));assert.ok(checks.attributes.includes('span.attributes'));
  // Remove a capture to exercise one-sided inspection, without saved shapes.
  await route('#parity');
  await page.evaluate(()=>{captureByKey.delete('python/case');data.captureComparisons=[];renderCompare();});
  assert.match(await page.locator('#compare-body').innerText(),/Capture unavailable/);
  await page.locator('.capture-trace > summary').first().click();await page.waitForSelector('[data-row]');assert.ok(await page.locator('[data-row]').count()>0);
  // Native summary and button controls remain operable from the keyboard.
  await page.locator('[data-row="0"] > summary').focus();await page.keyboard.press('Enter');
  assert.equal(await page.locator('[data-row="0"]').getAttribute('open'),'');
  await page.screenshot({path:'/tmp/otel-parity-browser.png',fullPage:true});
  await route('#health');
  assert.equal(await page.evaluate(()=>document.querySelector('#features h2').getBoundingClientRect().top >= document.querySelector('nav.top').getBoundingClientRect().bottom),true,'heading obscured by navigation');
  await page.screenshot({path:'/tmp/otel-health-browser.png',fullPage:true});
  for (const destination of ['health','parity']) {
    await page.setViewportSize({width:375,height:812});await route('#'+destination);
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth <= innerWidth),true,'mobile page overflow: '+destination);
  }
  assert.deepEqual(errors,[]);
  await browser.close();console.log('Report browser checks passed');
})().catch(e=>{console.error(e);process.exit(1);});
