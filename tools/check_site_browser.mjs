// Optional browser smoke checks. Acquire the shared host reservation before use.
// Usage: node tools/check_site_browser.mjs BASE_URL OUTPUT_DIRECTORY
// BROWSER can select an installed Chromium or Chrome executable.
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';

const [baseArgument, outputArgument] = process.argv.slice(2);
if (!baseArgument || !outputArgument) throw new Error('Provide the site URL and an output directory.');
const base = new URL(baseArgument);
if (!['http:', 'https:'].includes(base.protocol)) throw new Error('Serve the artifact over HTTP.');
const output = path.resolve(outputArgument);
const executable = process.env.BROWSER || (process.platform === 'darwin'
  ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : '/usr/bin/chromium');
const cases = [];
const exceptions = [];
const pending = new Map();
let browser, socket, session, sequence = 0;
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(fn, description, timeout = 15000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    try { if (await fn()) return; } catch (_) { /* Navigation can replace a JavaScript context. */ }
    await delay(50);
  }
  throw new Error(description);
}
function send(method, params = {}, target = session) {
  const id = ++sequence;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { pending.delete(id); reject(new Error('CDP timeout: ' + method)); }, 10000);
    pending.set(id, {resolve, reject, timer});
    socket.send(JSON.stringify({id, method, params, ...(target ? {sessionId: target} : {})}));
  });
}
async function evaluate(expression) {
  const result = await send('Runtime.evaluate', {expression, returnByValue: true, awaitPromise: true});
  if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
async function navigate(query = '') {
  await send('Page.navigate', {url: 'about:blank'});
  await until(() => evaluate('location.href === "about:blank"'), 'Blank navigation failed');
  await send('Page.navigate', {url: new URL(query, base).href});
  await until(() => evaluate('!!document.documentElement.dataset.wikiReady'), 'Wiki failed to finish its route');
}
async function screenshot(name) {
  const shot = await send('Page.captureScreenshot', {format: 'png', captureBeyondViewport: false});
  await writeFile(path.join(output, name + '.png'), Buffer.from(shot.data, 'base64'));
}
async function check(name, fn) {
  try {
    const evidence = await fn();
    cases.push({name, ok: true, evidence});
    console.log('PASS ' + name);
  } catch (error) {
    cases.push({name, ok: false, error: error.message});
    console.log('FAIL ' + name + ': ' + error.message);
    await screenshot('failure-' + name).catch(() => {});
  }
}
function stopBrowser() {
  if (browser?.pid && browser.exitCode === null) {
    try { process.kill(-browser.pid, 'SIGTERM'); } catch (_) {}
  }
}
for (const signal of ['SIGTERM', 'SIGINT']) process.once(signal, () => { stopBrowser(); process.exit(130); });

try {
  await mkdir(output, {recursive: true});
  browser = spawn(executable, ['--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--disable-background-networking', '--remote-debugging-port=0', '--user-data-dir=' + path.join(output, 'profile'), 'about:blank'],
  {detached: true, stdio: ['ignore', 'ignore', 'pipe']});
  let diagnostics = '', spawnError;
  browser.on('error', error => { spawnError = error; });
  browser.stderr.on('data', chunk => { diagnostics += chunk.toString(); });
  await until(() => { if (spawnError) throw spawnError; return /DevTools listening on (ws:\/\/\S+)/.test(diagnostics); }, 'Browser did not start');
  socket = new WebSocket(diagnostics.match(/DevTools listening on (ws:\/\/\S+)/)[1]);
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, {once: true});
    socket.addEventListener('error', reject, {once: true});
  });
  socket.addEventListener('message', event => {
    const message = JSON.parse(event.data), job = pending.get(message.id);
    if (message.method === 'Runtime.exceptionThrown') exceptions.push(message.params.exceptionDetails);
    if (!job) return;
    clearTimeout(job.timer); pending.delete(message.id);
    if (message.error) job.reject(new Error(JSON.stringify(message.error))); else job.resolve(message.result);
  });
  const target = await send('Target.createTarget', {url: 'about:blank'}, null);
  session = (await send('Target.attachToTarget', {targetId: target.targetId, flatten: true}, null)).sessionId;
  await send('Page.enable'); await send('Runtime.enable');
  const version = await send('Browser.getVersion', {}, null);
  await send('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'no-preference'}]});
  await send('Emulation.setDeviceMetricsOverride', {width: 1440, height: 1040, deviceScaleFactor: 1, mobile: false});

  await check('home-and-navigation', async () => {
    await navigate();
    const state = await evaluate(`({title:document.title,ready:document.documentElement.dataset.wikiReady,topics:document.querySelectorAll('.topic-card').length,revision:document.querySelector('#revision').textContent})`);
    assert.equal(state.ready, 'true'); assert(state.topics >= 4); assert.match(state.revision, /[0-9a-f]{7}/);
    await screenshot('home-desktop'); return state;
  });
  await check('search-and-layer-filter', async () => {
    await evaluate(`document.querySelector('#search').value='cancellation';document.querySelector('#search').dispatchEvent(new Event('input',{bubbles:true}))`);
    await until(() => evaluate(`document.querySelectorAll('.result-card').length > 0`), 'Search returned no results');
    await evaluate(`document.querySelector('#layer-filter').value='wiki';document.querySelector('#layer-filter').dispatchEvent(new Event('change',{bubbles:true}))`);
    await delay(250);
    const state = await evaluate(`({count:document.querySelectorAll('.result-card').length,paths:[...document.querySelectorAll('.result-card')].map(a=>new URL(a.href).searchParams.get('page'))})`);
    assert(state.count > 0); assert(state.paths.every(value => value?.startsWith('wiki/')));
    await screenshot('search'); return state;
  });
  await check('multiword-search-preserves-typing', async () => {
    await evaluate(`document.querySelector('#search').focus();document.querySelector('#search').value='bounded ';document.querySelector('#search').dispatchEvent(new Event('input',{bubbles:true}))`);
    await delay(250);
    assert.equal(await evaluate(`document.querySelector('#search').value`), 'bounded ');
    await evaluate(`document.querySelector('#search').value+='resources';document.querySelector('#search').dispatchEvent(new Event('input',{bubbles:true}))`);
    await delay(250);
    const state=await evaluate(`({value:document.querySelector('#search').value,count:document.querySelectorAll('.result-card').length})`);
    assert.equal(state.value,'bounded resources'); assert(state.count>0); return state;
  });
  await check('reader-wikilinks-evidence-backlinks', async () => {
    await navigate('?page=wiki/std-io.md');
    const state = await evaluate(`({heading:document.querySelector('.document-header h1')?.textContent,prose:document.querySelector('.prose')?.textContent.length,links:[...document.querySelectorAll('.prose a')].map(a=>a.href),evidence:document.querySelector('.evidence-links')?.textContent})`);
    assert(state.prose > 500); assert(state.links.some(value => new URL(value).searchParams.get('page')?.startsWith('wiki/')));
    assert.match(state.evidence, /source/i); assert.match(state.evidence, /backlink|linked from/i);
    await screenshot('reader'); return {...state, links:state.links.slice(0, 5)};
  });
  await check('heading-links-and-history', async () => {
    const href = await evaluate(`document.querySelector('#contents a').href`);
    await navigate(href);
    const state = await evaluate(`({hash:location.hash,heading:!!document.getElementById(decodeURIComponent(location.hash.slice(1))),scroll:scrollY})`);
    assert(state.hash && state.heading);
    await until(() => evaluate('scrollY>0'), 'Heading link did not scroll');
    const original=await evaluate('location.href');
    await evaluate(`[...document.querySelectorAll('.prose a')].find(a=>new URL(a.href).searchParams.get('page')?.startsWith('wiki/') && new URL(a.href).searchParams.get('page')!=='wiki/std-io.md').click()`);
    await until(()=>evaluate(`new URL(location.href).searchParams.get('page')!=='wiki/std-io.md'`),'Internal navigation failed');
    await evaluate('history.back()');
    await until(()=>evaluate('location.href==='+JSON.stringify(original)),'Browser history failed'); return state;
  });
  await check('source-provenance', async () => {
    await navigate('?page=sources/zig-0.16.0-stdlib.md');
    const state = await evaluate(`({pin:document.querySelector('.source-pin')?.textContent,prose:document.querySelector('.prose')?.textContent.length})`);
    assert(state.prose > 100); assert.match(state.pin, /0\.16\.0/); return state;
  });
  await check('proof-highlighting-and-original-bytes', async () => {
    const data = await (await fetch(new URL('data.json', base))).json();
    const proof = data.documents.find(doc => doc.layer === 'proof');
    assert(proof);
    await navigate('?page=' + encodeURIComponent(proof.path));
    const state = await evaluate(`({code:document.querySelector('.prose pre code')?.textContent,tokens:document.querySelectorAll('.prose .hljs-keyword').length})`);
    assert.equal(state.code, proof.body); assert(state.tokens > 0);
    await screenshot('proof'); return {path:proof.path,tokens:state.tokens,bytes:state.code.length};
  });
  await check('graph-and-node-navigation', async () => {
    await navigate('?view=graph');
    await until(() => evaluate(`document.querySelectorAll('#graph-root svg circle').length > 0`), 'Graph did not render');
    const state = await evaluate(`({circles:document.querySelectorAll('#graph-root svg circle').length,controls:document.querySelectorAll('#graph-root button,#graph-root input').length,layers:[...document.querySelectorAll('.wg-layers input:checked')].map(input=>input.value),text:document.querySelector('#graph-root').textContent.slice(0,800)})`);
    assert(state.circles >= 40); assert(state.controls >= 4);
    assert.deepEqual(state.layers,['wiki','source','proof','project']);
    assert.equal(await evaluate(`document.querySelector('.wg-list').open`),true);
    await evaluate(`document.querySelector('.wg-find input').value='io';document.querySelector('.wg-find input').dispatchEvent(new Event('input',{bubbles:true}))`);
    assert.match(await evaluate(`document.querySelector('.wg-list summary').textContent`),/Matching notes/);
    assert.equal(await evaluate(`document.querySelector('.wg-list').open`),true);
    await evaluate(`document.querySelector('.wg-find input').value='';document.querySelector('.wg-find input').dispatchEvent(new Event('input',{bubbles:true}))`);
    const initial=await evaluate(`[...document.querySelectorAll('.wg-node')].map(node=>node.getAttribute('transform'))`);
    await delay(180);
    assert.notDeepEqual(await evaluate(`[...document.querySelectorAll('.wg-node')].map(node=>node.getAttribute('transform'))`),initial,'Startup should animate the layout');
    await until(()=>evaluate(`document.querySelector('.wiki-graph').dataset.motion==='settled'`),'Graph did not settle');
    await screenshot('graph-desktop'); return state;
  });
  await check('graph-selection-zoom-layers-and-keyboard-list', async () => {
    await until(()=>evaluate(`document.querySelector('.wiki-graph').dataset.motion==='settled'`),'Initial graph did not settle');
    const original=await evaluate(`[...document.querySelectorAll('.wg-node')].map(node=>node.getAttribute('transform'))`);
    const point=await evaluate(`(()=>{const r=document.querySelector('[data-wg-path="wiki/std-io.md"] .wg-dot').getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2}})()`);
    await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,...point});
    await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,...point});
    assert.equal(await evaluate(`document.querySelector('.wg-details h3').textContent`),'std.Io');
    const start=await evaluate(`[...document.querySelectorAll('.wg-node')].map(node=>node.getAttribute('transform'))`);
    await delay(200);
    const middle=await evaluate(`[...document.querySelectorAll('.wg-node')].map(node=>node.getAttribute('transform'))`);
    assert.notDeepEqual(middle,start,'Nodes must move during the transition');
    await until(()=>evaluate(`document.querySelector('.wiki-graph').dataset.motion==='settled'`),'Selection did not settle');
    const rearranged=await evaluate(`[...document.querySelectorAll('.wg-node')].map(node=>node.getAttribute('transform'))`);
    assert.equal(rearranged.length,original.length); assert.notDeepEqual(rearranged,original);
    const centered=await evaluate(`(()=>{const node=document.querySelector('[data-wg-path="wiki/std-io.md"] .wg-dot').getBoundingClientRect(),frame=document.querySelector('.wg-svg').getBoundingClientRect();return{dx:node.x+node.width/2-frame.x-frame.width/2,dy:node.y+node.height/2-frame.y-frame.height/2}})()`);
    assert(Math.abs(centered.dx)<3 && Math.abs(centered.dy)<3,JSON.stringify(centered));
    const before=await evaluate(`document.querySelector('.wg-svg>g').getAttribute('transform')`);
    await evaluate(`document.querySelector('[aria-label="Zoom in"]').click()`);
    assert.notEqual(await evaluate(`document.querySelector('.wg-svg>g').getAttribute('transform')`),before);
    await evaluate(`document.querySelector('.wg-layers input[value=source]').click()`);
    assert.equal(await evaluate(`document.querySelectorAll('.wg-node[data-layer=source]').length`),0);
    await evaluate(`document.querySelector('.wg-layers input[value=source]').click()`);
    const evidence=await evaluate(`({sources:document.querySelectorAll('.wg-node[data-layer=source]').length,proofs:document.querySelectorAll('.wg-node[data-layer=proof]').length,sourceEdges:document.querySelectorAll('.wg-edge[data-type=source]').length,proofEdges:document.querySelectorAll('.wg-edge[data-type=proof]').length})`);
    assert(Object.values(evidence).every(value=>value>0));
    await evaluate(`document.querySelector('[data-wg-select="wiki/std-io.md"]').focus()`);
    await send('Input.dispatchKeyEvent',{type:'keyDown',key:'Enter',code:'Enter',windowsVirtualKeyCode:13});
    await send('Input.dispatchKeyEvent',{type:'keyUp',key:'Enter',code:'Enter',windowsVirtualKeyCode:13});
    await evaluate(`document.querySelector('.wg-open').click()`);
    await until(()=>evaluate(`!!document.querySelector('.document-header h1')`),'Graph note navigation failed');
    assert.equal(await evaluate(`new URL(location.href).searchParams.get('page')`),'wiki/std-io.md');
    await navigate('?view=graph&focus=wiki/std-io.md');
    assert.equal(await evaluate(`document.querySelectorAll('.wg-node').length`),original.length);
    await evaluate(`document.querySelector('.wg-toolbar button').click()`);
    const focused=await evaluate(`({nodes:document.querySelectorAll('.wg-node').length,local:document.querySelector('.wg-toolbar button').getAttribute('aria-pressed')})`);
    assert(focused.nodes>1 && focused.nodes<original.length); assert.equal(focused.local,'true');
    return {evidence,focused,centered};
  });
  await check('graph-reduced-motion-and-cleanup', async()=>{
    await send('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'reduce'}]});
    await navigate('?view=graph&focus=wiki/std-io.md');
    assert.equal(await evaluate(`document.querySelector('.wiki-graph').dataset.motion`),'settled');
    const initial=await evaluate(`document.querySelector('[data-wg-path="wiki/std-io.md"]').getAttribute('transform')`);
    await delay(100);
    assert.equal(await evaluate(`document.querySelector('[data-wg-path="wiki/std-io.md"]').getAttribute('transform')`),initial);
    await send('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'no-preference'}]});
    await navigate('?view=graph');
    await evaluate(`document.querySelector('#nav-explore').click()`);
    await delay(1000);
    assert.equal(await evaluate(`document.querySelectorAll('.wiki-graph').length`),0);
    assert.equal(await evaluate(`document.querySelectorAll('.topic-card').length`),4);
    return {reducedMotion:'settled',unmounted:true};
  });
  await check('hostile-markdown-is-inert', async () => {
    const fixture=await (await fetch(new URL('data.json',base))).json();
    const doc=fixture.documents.find(item=>item.path==='index.md');
    doc.body='# Browser fixture\n\n<script>window.__wikiXSS=1</script>\n<img src="bad.png" onerror="window.__wikiXSS=2">\n<a href="javascript:window.__wikiXSS=3">unsafe</a>\n<iframe srcdoc="<script>parent.__wikiXSS=4</script>"></iframe>\n\n[[std-io|`std.Io`]]\n\n[Relative note](wiki/std-io.md#remember)\n';
    const intercepted=async event=>{
      const message=JSON.parse(event.data);
      if(message.method!=='Fetch.requestPaused')return;
      await send('Fetch.fulfillRequest',{requestId:message.params.requestId,responseCode:200,responseHeaders:[{name:'Content-Type',value:'application/json'}],body:Buffer.from(JSON.stringify(fixture)).toString('base64')}).catch(()=>{});
    };
    socket.addEventListener('message',intercepted);
    await send('Fetch.enable',{patterns:[{urlPattern:'*data.json*',requestStage:'Request'}]});
    try{
      await navigate('?page=index.md');
      const state=await evaluate(`({xss:window.__wikiXSS||0,unsafe:document.querySelectorAll('.prose script,.prose iframe,.prose [onerror],.prose a[href^="javascript:"]').length,alias:document.querySelector('.prose a code')?.textContent,link:[...document.querySelectorAll('.prose a')].find(a=>a.textContent==='Relative note')?.href})`);
      assert.equal(state.xss,0);assert.equal(state.unsafe,0);assert.equal(state.alias,'std.Io');
      assert.equal(new URL(state.link).searchParams.get('page'),'wiki/std-io.md');assert.equal(new URL(state.link).hash,'#remember');return state;
    }finally{await send('Fetch.disable');socket.removeEventListener('message',intercepted);}
  });
  await check('invalid-paths-and-missing-document', async () => {
    const results = [];
    for (const page of ['../index.md','wiki/../index.md','wiki/%2e%2e/index.md','https://example.com/index.md','missing.md']) {
      await navigate('?page=' + encodeURIComponent(page));
      const state = await evaluate(`({article:!!document.querySelector('.prose'),text:document.querySelector('#view').textContent.slice(0,400)})`);
      assert.equal(state.article, false, page); results.push({page,...state});
    }
    return results;
  });
  await check('mobile-layout', async () => {
    await send('Emulation.setDeviceMetricsOverride', {width:390,height:844,deviceScaleFactor:1,mobile:true});
    const results=[];
    for (const query of ['', '?page=wiki/windows-iocp-and-overlapped-io.md', '?view=graph']) {
      await navigate(query);
      if (query.includes('graph')) await until(() => evaluate(`document.querySelectorAll('#graph-root svg circle').length > 0`), 'Mobile graph did not mount');
      const state = await evaluate(`({viewport:innerWidth,width:document.documentElement.scrollWidth,body:document.body.scrollWidth})`);
      assert(state.width <= state.viewport+1 && state.body <= state.viewport+1);
      results.push({query,...state}); await screenshot('mobile-' + (query.includes('page') ? 'reader' : query ? 'graph' : 'home'));
    }
    return results;
  });
  await writeFile(path.join(output,'receipt.json'), JSON.stringify({base:base.href,browser:version.product,cases,exceptions},null,2)+'\n');
  if (cases.some(test=>!test.ok) || exceptions.length) process.exitCode=1;
} finally {
  if (socket?.readyState === WebSocket.OPEN) {
    await send('Browser.close', {}, null).catch(()=>{}); socket.close();
  }
  stopBrowser();
  for (const job of pending.values()) clearTimeout(job.timer);
}
