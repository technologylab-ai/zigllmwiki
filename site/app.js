/* The browser reads generated data. Repository Markdown and proofs remain canonical. */
const $ = selector => document.querySelector(selector);
const view = $('#view');
const search = $('#search');
const controls = {layer: $('#layer-filter'), platform: $('#platform-filter'), status: $('#status-filter')};
const layers = {wiki: 'Wiki note', source: 'Source record', proof: 'Proof file', project: 'Project document'};
const statusNames = {'source-verified': 'Source verified', 'runtime-verified': 'Runtime verified', captured: 'Captured', draft: 'Draft', stub: 'Stub', superseded: 'Superseded'};
const state = {data: null, documents: new Map(), assets: new Set(), searchable: [], cleanup: null, generation: 0, shown: 40};
const entry = new URL(location.pathname, location.origin);
const allowedPath = /^[A-Za-z0-9_./-]+$/;

function element(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = String(text);
  return node;
}
function anchor(text, href, className) {
  const link = element('a', className, text);
  link.href = href;
  return link;
}
function escapeHTML(text) {
  return String(text).replace(/[&<>"']/g, char => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[char]));
}
function canonicalPath(value) {
  if (typeof value !== 'string' || !value || value.length > 600 || !allowedPath.test(value) || value.startsWith('/')) return null;
  if (value.split('/').some(part => !part || part === '.' || part === '..')) return null;
  return value;
}
function pageURL(path, fragment = '') {
  const url = new URL(entry);
  url.searchParams.set('page', path);
  if (fragment) url.hash = fragment;
  return url.href;
}
function graphURL(focus = '') {
  const url = new URL(entry);
  url.searchParams.set('view', 'graph');
  if (focus) url.searchParams.set('focus', focus);
  return url.href;
}
function repositoryURL(path, fragment = '') {
  const url = new URL(state.data.repository + '/blob/' + state.data.revision + '/' + path.split('/').map(encodeURIComponent).join('/'));
  if (fragment) url.hash = fragment;
  return url.href;
}
function externalURL(value) {
  try {
    const url = new URL(value);
    return ['http:', 'https:', 'mailto:'].includes(url.protocol) ? url.href : null;
  } catch (_) { return null; }
}
function relativePath(raw, source) {
  let path;
  try { path = decodeURIComponent(raw); } catch (_) { return null; }
  // Inspect components before a URL parser can erase traversal evidence.
  if (!path || path.startsWith('/') || !allowedPath.test(path)) return null;
  const parts = source.split('/').slice(0, -1);
  for (const part of path.split('/')) {
    if (!part || part === '.') continue;
    if (part === '..') {
      if (!parts.length) return null;
      parts.pop();
    } else parts.push(part);
  }
  return canonicalPath(parts.join('/'));
}
function slug(text) {
  return text.trim().toLowerCase().replace(/[^\p{L}\p{N}_ -]/gu, '').replace(/ /g, '-') || 'section';
}
function resolveTarget(target, source, wiki = false) {
  if (typeof target !== 'string' || target.length > 4000 || /[\x00-\x1f\x7f\\]/.test(target)) return null;
  target = target.trim();
  if (!target) return null;
  if (/^[a-z][a-z0-9+.-]*:/i.test(target)) return externalURL(target);
  if (target.startsWith('//')) return externalURL('https:' + target);
  const hashAt = target.indexOf('#');
  const fragment = hashAt >= 0 ? target.slice(hashAt + 1) : '';
  const raw = hashAt >= 0 ? target.slice(0, hashAt) : target;
  if (!raw) return pageURL(source, fragment);
  if (raw.includes('?')) return null;
  let path;
  if (wiki) {
    if (!canonicalPath(raw)) return null;
    const alias = Object.prototype.hasOwnProperty.call(state.data.aliases, raw) ? state.data.aliases[raw] : null;
    path = alias || (raw.endsWith('.md') ? raw : 'wiki/' + raw + '.md');
  } else path = relativePath(raw, source);
  if (!canonicalPath(path)) return null;
  const hash = wiki && fragment ? slug(fragment) : fragment;
  return state.documents.has(path) ? pageURL(path, hash) : repositoryURL(path, hash);
}
function navigate(url, replace = false) {
  const destination = new URL(url, entry);
  if (destination.origin !== entry.origin || destination.pathname !== entry.pathname) {
    location.assign(destination.href);
    return;
  }
  history[replace ? 'replaceState' : 'pushState'](null, '', destination.href);
  renderRoute();
}
function announce(text) { $('#announcement').textContent = text; }
function clearView() {
  if (state.cleanup) state.cleanup();
  state.cleanup = null;
  state.generation += 1;
  view.replaceChildren();
  $('#loading').hidden = true;
  document.documentElement.dataset.appReady = 'loading';
  document.documentElement.dataset.wikiReady = 'loading';
}
function showError(title, message) {
  clearView();
  const box = element('section', 'notice');
  box.setAttribute('role', 'alert');
  box.append(element('span', 'eyebrow', 'A small detour'), element('h1', '', title), element('p', '', message), anchor('Return to the field guide →', entry.href));
  view.append(box);
  document.documentElement.dataset.appReady = 'error';
  document.documentElement.dataset.wikiReady = 'error';
}
function badge(text, className = '') { return element('span', 'tag ' + className, text); }
function documentTags(doc) {
  const tags = element('div', 'result-meta');
  tags.append(badge(layers[doc.layer], 'layer-' + doc.layer));
  if (doc.status) tags.append(badge(statusNames[doc.status] || doc.status));
  for (const platform of doc.platforms) tags.append(element('span', '', platform === 'macos' ? 'macOS' : platform));
  return tags;
}
function plainText(body) {
  return body.replace(/^#+\s*/gm, '').replace(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/g, (_, target, label) => label || target)
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1').replace(/[`*_>|]/g, '').replace(/\s+/g, ' ').trim();
}
function highlightText(container, text, terms) {
  if (!terms.length) { container.textContent = text; return; }
  const escaped = [...new Set(terms)].sort((a, b) => b.length - a.length).map(term => term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
  const pattern = new RegExp(escaped.join('|'), 'gi');
  let last = 0;
  for (const match of text.matchAll(pattern)) {
    container.append(document.createTextNode(text.slice(last, match.index)), element('mark', '', match[0]));
    last = match.index + match[0].length;
  }
  container.append(document.createTextNode(text.slice(last)));
}
function snippet(item, terms) {
  if (!terms.length) return item.doc.summary || item.plain.slice(0, 190);
  const lower = item.plain.toLowerCase();
  const at = terms.map(term => lower.indexOf(term)).filter(index => index >= 0).sort((a, b) => a - b)[0] || 0;
  const start = Math.max(0, at - 65);
  return (start ? '…' : '') + item.plain.slice(start, start + 220) + (start + 220 < item.plain.length ? '…' : '');
}
function renderHome() {
  document.title = 'Zig LLM Wiki · A systems field guide';
  const hero = element('section', 'hero');
  const intro = element('div');
  intro.append(element('p', 'eyebrow', 'Field notes for systems programmers'));
  const title = element('h1');
  title.append(document.createTextNode('Systems knowledge.'), element('br'), element('em', '', 'Grounded in source.'));
  intro.append(title, element('p', 'hero-summary', 'A connected guide to Zig, bounded resources, and platform I/O. Start with a question. Follow the evidence.'));
  const art = element('div', 'hero-art');
  art.setAttribute('aria-hidden', 'true');
  art.append(element('b', '', 'Z'), element('span'), element('span'), element('span'));
  hero.append(intro, art);
  const stats = element('div', 'stats');
  const counts = [['wiki', 'Wiki notes'], ['source', 'Pinned records'], ['proof', 'Proof files']];
  for (const [layer, label] of counts) {
    const stat = element('div', 'stat');
    stat.append(element('strong', '', state.data.documents.filter(doc => doc.layer === layer).length), element('span', '', label));
    stats.append(stat);
  }
  const version = element('div', 'stat');
  version.append(element('strong', '', state.data.zig), element('span', '', 'Exact Zig target'));
  stats.append(version);
  const heading = element('div', 'section-heading');
  heading.append(element('h2', '', 'Choose a reading path'), anchor('All wiki notes →', '?layer=wiki'));
  const grid = element('div', 'topic-grid');
  const topics = [
    ['01', 'The I/O model', 'Understand scheduling, cancellation, and the limits behind std.Io.', 'wiki/std-io.md'],
    ['02', 'Design with limits', 'Connect TigerStyle to ownership, assertions, allocation, and failure.', 'wiki/tigerstyle.md'],
    ['03', 'Across operating systems', 'Compare Linux, macOS, and Windows by their actual contracts.', 'wiki/platform-io-backend-decision-table.md'],
    ['04', 'An HTTP server, in practice', 'Follow the bounded framework from its design to its measured experiments.', 'wiki/bounded-http-server-design.md']
  ];
  for (const [number, name, description, path] of topics) {
    if (!state.documents.has(path)) continue;
    const card = anchor('', pageURL(path), 'topic-card');
    card.append(element('span', 'topic-number', number + ' / READING PATH'), element('h3', '', name), element('p', '', description));
    const arrow = element('span', 'card-arrow', '↗'); arrow.setAttribute('aria-hidden', 'true'); card.append(arrow);
    grid.append(card);
  }
  const features = element('div', 'feature-row');
  const evidence = element('section', 'evidence-card');
  evidence.append(element('p', 'eyebrow', 'How to read this wiki'), element('h2', '', 'A claim needs a boundary.'), element('p', '', 'A source pin identifies evidence. A runtime result applies only to its recorded environment. Cross-compilation proves compilation alone.'));
  const list = element('ol');
  ['Read the note and its evidence status.', 'Inspect the pinned source and exact compiler.', 'Follow the proof and its platform limits.'].forEach(text => list.append(element('li', '', text)));
  evidence.append(list);
  const graph = element('section', 'feature-note');
  graph.append(element('p', 'eyebrow', 'Explore the connections'), element('h2', '', 'No note stands alone.'), element('p', '', 'Trace the links between concepts, primary sources, and executable proofs. Follow a neighborhood or explore the whole collection.'), anchor('Open the knowledge graph ↗', graphURL()));
  features.append(evidence, graph);
  view.append(hero, stats, heading, grid, features);
}
function readFilters(params) {
  return {q: (params.get('q') || '').slice(0, 300), layer: params.get('layer') || '', platform: params.get('platform') || '', status: params.get('status') || ''};
}
function renderSearch(filters) {
  document.title = (filters.q ? 'Search: ' + filters.q : 'Browse the collection') + ' · Zig LLM Wiki';
  const terms = filters.q.toLowerCase().split(/\s+/).filter(Boolean);
  const results = [];
  for (const item of state.searchable) {
    const doc = item.doc;
    if (filters.layer && doc.layer !== filters.layer) continue;
    if (filters.platform && !doc.platforms.includes(filters.platform)) continue;
    if (filters.status && doc.status !== filters.status) continue;
    if (!terms.every(term => item.haystack.includes(term))) continue;
    const score = terms.reduce((sum, term) => sum + (item.title.includes(term) ? 30 : 0) + (item.summary.includes(term) ? 12 : 0) + (doc.path.toLowerCase().includes(term) ? 8 : 0), doc.layer === 'wiki' ? 4 : 0);
    results.push({item, score});
  }
  results.sort((a, b) => b.score - a.score || a.item.doc.title.localeCompare(b.item.doc.title));
  const header = element('section', 'search-header');
  header.append(element('p', 'eyebrow', filters.q ? 'Search the collection' : 'Browse the collection'));
  const title = element('h1', '', filters.q ? 'Results for “' + filters.q + '”' : 'A closer look.');
  const count = results.length + (results.length === 1 ? ' document' : ' documents');
  header.append(title, element('p', '', count + ' match your current search and filters.'));
  const clear = element('button', '', 'Clear search and filters'); clear.type = 'button';
  clear.addEventListener('click', () => navigate(entry.href)); header.append(clear);
  const list = element('div', 'result-list');
  const renderResults = () => {
    list.replaceChildren();
    for (const {item} of results.slice(0, state.shown)) {
      const doc = item.doc;
      const card = anchor('', pageURL(doc.path), 'result-card');
      card.append(documentTags(doc));
      const h2 = element('h2'); highlightText(h2, doc.title, terms); card.append(h2);
      const description = element('p'); highlightText(description, snippet(item, terms), terms); card.append(description, element('small', '', doc.path));
      list.append(card);
    }
    if (state.shown < results.length) {
      const more = element('button', 'more-results', 'Show more documents'); more.type = 'button';
      more.addEventListener('click', () => { state.shown += 40; renderResults(); }); list.append(more);
    }
  };
  renderResults();
  view.append(header, list);
  if (!results.length) {
    const empty = element('div', 'notice');
    empty.append(element('h2', '', 'Try a broader question.'), element('p', '', 'Use fewer words or remove a filter. Search also includes source records and proof text.'));
    view.append(empty);
  }
  announce(count + ' found.');
}
function sourceMetadata(doc, container) {
  const metadata = doc.metadata || {};
  const fields = [['revision', 'Source revision'], ['captured', 'Captured'], ['url', 'Primary source'], ['sha256', 'Snapshot SHA-256'], ['snapshot', 'Snapshot']];
  const dl = element('dl', 'source-pin');
  for (const [key, label] of fields) {
    const value = metadata[key];
    if (typeof value !== 'string' && typeof value !== 'number') continue;
    const dt = element('dt', '', label); const dd = element('dd');
    const target = key === 'url' ? externalURL(String(value)) : key === 'snapshot' && canonicalPath(String(value)) ? repositoryURL(String(value)) : null;
    dd.append(target ? anchor(String(value), target) : document.createTextNode(String(value)));
    dl.append(dt, dd);
  }
  if (doc.sha256) dl.append(element('dt', '', 'File SHA-256'), element('dd', '', doc.sha256));
  if (dl.children.length) container.append(dl);
}
function registerMarkdown() {
  marked.use({renderer: {
    image(token) {
      return '<img data-image-target="' + escapeHTML(token.href) + '" alt="' + escapeHTML(token.text || 'Referenced image') + '">';
    }
  }, extensions: [{
    name: 'wikilink', level: 'inline',
    start(source) { return source.indexOf('[['); },
    tokenizer(source) {
      const match = /^\[\[([^\]\n]+)\]\]/.exec(source);
      if (!match) return undefined;
      const separator = match[1].indexOf('|');
      const target = (separator < 0 ? match[1] : match[1].slice(0, separator)).trim();
      const label = separator < 0 ? target : match[1].slice(separator + 1);
      return {type: 'wikilink', raw: match[0], target, label, alias: separator >= 0};
    },
    renderer(token) {
      const label = token.alias ? marked.parseInline(token.label) : escapeHTML(token.label);
      return '<a data-wiki-target="' + escapeHTML(token.target) + '">' + label + '</a>';
    }
  }]});
  // This grammar comes from the HTTP reader's exact Zig 0.16 tokenizer vocabulary.
  hljs.registerLanguage('zig', h => ({
    name: 'Zig', keywords: {
      keyword: 'addrspace align allowzero and anyframe anytype asm break callconv catch comptime const continue defer else enum errdefer error export extern fn for if inline noalias noinline nosuspend opaque or orelse packed pub resume return linksection struct suspend switch test threadlocal try union unreachable var volatile while',
      literal: 'true false null undefined', type: 'bool void noreturn type anyerror anyopaque usize isize comptime_int comptime_float f16 f32 f64 f80 f128'
    }, contains: [h.C_LINE_COMMENT_MODE, h.QUOTE_STRING_MODE, h.APOS_STRING_MODE,
      {scope: 'string', begin: /\\\\/, end: /$/},
      {scope: 'built_in', begin: /@[A-Za-z_][A-Za-z_0-9]*/},
      {scope: 'type', begin: /\b[ui]\d+\b/}, h.C_NUMBER_MODE]
  }));
}
function routeBodyLinks(article, doc) {
  for (const link of article.querySelectorAll('a')) {
    const wiki = link.hasAttribute('data-wiki-target');
    const raw = wiki ? link.getAttribute('data-wiki-target') : link.getAttribute('href');
    const resolved = resolveTarget(raw, doc.path, wiki);
    link.removeAttribute('data-wiki-target');
    if (resolved) {
      link.href = resolved;
      if (new URL(resolved).origin !== entry.origin) link.rel = 'noopener noreferrer';
    } else {
      link.removeAttribute('href');
      link.title = 'This target is unavailable in the published reader.';
    }
  }
  for (const image of article.querySelectorAll('img')) {
    const raw = image.getAttribute('data-image-target') || '';
    const path = relativePath(raw, doc.path);
    if (path && state.assets.has(path)) {
      image.src = new URL('files/' + path.split('/').map(encodeURIComponent).join('/'), entry).href;
      image.loading = 'lazy'; image.decoding = 'async';
      image.removeAttribute('data-image-target');
      continue;
    }
    const resolved = resolveTarget(raw, doc.path);
    const text = image.getAttribute('alt') || 'Referenced image';
    const replacement = resolved ? anchor('View image: ' + text + ' ↗', resolved, 'image-reference') : element('span', 'image-reference', text + ' — image unavailable.');
    image.replaceWith(replacement);
  }
}
function addContents(article, doc, toc) {
  const counts = new Map([[slug(doc.title), 1]]);
  let count = 0;
  for (const heading of article.querySelectorAll('h1,h2,h3,h4,h5,h6')) {
    const title = heading.textContent;
    const base = slug(title);
    const occurrence = counts.get(base) || 0;
    counts.set(base, occurrence + 1);
    heading.id = base + (occurrence ? '-' + occurrence : '');
    const permalink = anchor('#', pageURL(doc.path, heading.id), 'heading-anchor');
    permalink.setAttribute('aria-label', 'Link to ' + title); heading.append(permalink);
    if (heading.tagName === 'H2' || heading.tagName === 'H3') {
      const link = anchor(title, pageURL(doc.path, heading.id), heading.tagName === 'H3' ? 'sub' : '');
      link.dataset.heading = heading.id; toc.append(link); count += 1;
    }
  }
  if (!count) toc.append(element('p', 'empty-note', 'No section headings.'));
}
async function copyCode(button, code) {
  try {
    if (navigator.clipboard && window.isSecureContext) await navigator.clipboard.writeText(code.textContent);
    else {
      const input = element('textarea'); input.value = code.textContent; input.className = 'sr-only';
      document.body.append(input); input.select(); const copied = document.execCommand('copy'); input.remove();
      if (!copied) throw new Error('Copy unavailable');
    }
    button.textContent = 'Copied';
  } catch (_) { button.textContent = 'Select text to copy'; }
}
function decorateCode(article) {
  for (const code of article.querySelectorAll('pre code')) {
    const languageClass = [...code.classList].find(name => name.startsWith('language-'));
    const language = languageClass ? languageClass.slice(9) : '';
    if (language && hljs.getLanguage(language)) hljs.highlightElement(code);
    code.parentElement.append(element('span', 'code-language', language || 'text'));
    const button = element('button', 'copy-code', 'Copy'); button.type = 'button';
    button.addEventListener('click', () => copyCode(button, code)); code.parentElement.prepend(button);
  }
  for (const table of article.querySelectorAll('table')) {
    const wrapper = element('div', 'table-scroll'); wrapper.tabIndex = 0; wrapper.setAttribute('aria-label', 'Scrollable table');
    table.replaceWith(wrapper); wrapper.append(table);
  }
}
function linkedSection(container, title, paths, empty) {
  const section = element('section'); section.append(element('h2', '', title));
  const unique = [...new Set(paths)].filter(path => state.documents.has(path));
  if (unique.length) {
    const list = element('ul');
    for (const path of unique) {
      const item = element('li'); item.append(anchor(state.documents.get(path).title, pageURL(path))); list.append(item);
    }
    section.append(list);
  } else section.append(element('p', 'empty-note', empty));
  container.append(section);
}
function evidenceScope(doc) {
  if (doc.layer === 'proof') return 'This view displays the canonical proof file. Reading the file does not execute it. Platform results remain in the linked notes.';
  if (doc.layer === 'source') return 'This record identifies captured evidence. Its revision and stated limits govern the linked claims.';
  if (doc.status === 'runtime-verified') return 'Runtime evidence applies only to the environments and cases recorded in this note.';
  if (doc.status === 'source-verified') return 'Source verification traces claims to cited evidence. It does not establish runtime behavior on every platform.';
  if (doc.status === 'superseded') return 'This note is superseded. Follow its replacement links before applying the guidance.';
  return 'Read each claim with its source and platform limits. Draft guidance can retain unresolved questions.';
}
function renderDocument(path) {
  const doc = state.documents.get(path);
  if (!doc) { showError('That document is not in this edition.', 'Choose a note from search, or browse the repository for files outside this collection.'); return; }
  document.title = doc.title + ' · Zig LLM Wiki';
  const layout = element('div', 'document-layout'); const main = element('div', 'document-main');
  const header = element('header', 'document-header');
  const title = element('h1', '', doc.title); title.id = slug(doc.title);
  header.append(element('div', 'breadcrumb', doc.path), title);
  if (doc.summary) header.append(element('p', 'document-summary', doc.summary));
  header.append(documentTags(doc));
  const actions = element('div', 'document-actions');
  actions.append(anchor('View canonical file ↗', repositoryURL(doc.path)), anchor('See connections ↗', graphURL(doc.path)));
  const print = element('button', '', 'Print this note'); print.type = 'button'; print.addEventListener('click', () => window.print()); actions.append(print);
  header.append(actions, element('div', 'evidence-scope', evidenceScope(doc)));
  if (doc.updated) header.append(element('p', 'eyebrow', 'Updated ' + doc.updated));
  sourceMetadata(doc, header);
  const article = element('article', 'prose'); article.id = 'document';
  if (doc.path.endsWith('.md')) {
    const html = marked.parse(doc.body, {gfm: true, breaks: false});
    article.append(DOMPurify.sanitize(html, {RETURN_DOM_FRAGMENT: true, USE_PROFILES: {html: true}, FORBID_TAGS: ['style', 'script', 'iframe', 'form', 'input', 'button', 'textarea', 'select', 'link', 'meta'], FORBID_ATTR: ['style', 'id', 'name', 'srcdoc', 'src', 'srcset']}));
    routeBodyLinks(article, doc);
    const first = article.firstElementChild;
    if (first?.tagName === 'H1' && first.textContent.trim() === doc.title.trim()) first.remove();
  } else {
    const pre = element('pre'); const code = element('code');
    const extension = doc.path.split('.').pop();
    const language = {zon: 'zig', py: 'python', sh: 'bash', yml: 'yaml', js: 'javascript'}[extension] || extension;
    code.className = 'language-' + language; code.textContent = doc.body; pre.append(code); article.append(pre);
  }
  const aside = element('aside', 'document-aside'); aside.setAttribute('aria-label', 'On this page');
  const toc = element('nav', 'toc'); toc.id = 'contents'; toc.append(element('h2', '', 'On this page'));
  addContents(article, doc, toc); decorateCode(article); aside.append(toc);
  const links = element('div', 'evidence-links');
  if (doc.layer !== 'source' && doc.layer !== 'proof') {
    linkedSection(links, 'Pinned sources', doc.sources, 'No source record is listed for this document.');
    linkedSection(links, 'Executable proofs', doc.proofs, 'No executable proof is listed for this document.');
  }
  const backlinks = state.data.edges.filter(edge => edge.target === path && edge.source !== path).map(edge => edge.source);
  linkedSection(links, 'Linked from', backlinks, 'No included document links here yet.');
  main.append(header, article, links); layout.append(main, aside); view.append(layout);
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      for (const record of entries) if (record.isIntersecting) {
        for (const link of toc.querySelectorAll('a[data-heading]')) link.classList.toggle('active', link.dataset.heading === record.target.id);
      }
    }, {rootMargin: '-5% 0px -70% 0px'});
    article.querySelectorAll('h2,h3').forEach(heading => observer.observe(heading));
    state.cleanup = () => observer.disconnect();
  }
}
async function renderGraph(focus) {
  document.title = 'Knowledge graph · Zig LLM Wiki';
  const header = element('section', 'graph-heading');
  header.append(element('p', 'eyebrow', 'The collection, connected'), element('h1', '', 'Follow a thread.'), element('p', '', 'Explore the links between notes, source records, and proofs. A connection shows a reference, not an extra verification claim.'));
  const root = element('div'); root.id = 'graph-root'; root.append(element('p', 'empty-note', 'Loading the connection map…'));
  view.append(header, root);
  const generation = state.generation;
  try {
    const {mountGraph} = await import('./graph.js');
    if (generation !== state.generation) return;
    root.replaceChildren();
    state.cleanup = mountGraph(root, state.data, {focus, onNavigate: path => { if (state.documents.has(path)) navigate(pageURL(path)); }});
    document.documentElement.dataset.appReady = 'true';
    document.documentElement.dataset.wikiReady = 'true';
  } catch (_) {
    if (generation !== state.generation) return;
    root.replaceChildren(element('p', 'empty-note', 'The graph could not open. The notes and search remain available.'), anchor('Browse wiki notes →', '?layer=wiki'));
    document.documentElement.dataset.appReady = 'error';
    document.documentElement.dataset.wikiReady = 'error';
  }
}
function restoreFragment() {
  if (!location.hash) return;
  let fragment;
  try { fragment = decodeURIComponent(location.hash.slice(1)); } catch (_) { return; }
  requestAnimationFrame(() => {
    const heading = document.getElementById(fragment) || document.getElementById(slug(fragment));
    if (heading && view.contains(heading)) heading.scrollIntoView({block: 'start'});
  });
}
function renderRoute() {
  if (!state.data) return;
  const params = new URLSearchParams(location.search);
  const filters = readFilters(params);
  search.value = filters.q;
  for (const [name, control] of Object.entries(controls)) control.value = filters[name];
  clearView();
  state.shown = 40;
  const page = params.get('page'); const graph = params.get('view') === 'graph';
  $('#nav-explore').toggleAttribute('aria-current', !page && !graph);
  $('#nav-graph').toggleAttribute('aria-current', graph);
  $('#nav-explore').setAttribute('aria-current', !page && !graph ? 'page' : 'false');
  $('#nav-graph').setAttribute('aria-current', graph ? 'page' : 'false');
  for (const link of document.querySelectorAll('.browse-nav a')) {
    link.setAttribute('aria-current', new URL(link.href).searchParams.get('page') === page ? 'page' : 'false');
  }
  if (page !== null) {
    if (!canonicalPath(page)) showError('This document path is invalid.', 'Use a repository path from search or the navigation links.');
    else renderDocument(page);
  } else if (graph) {
    const focus = params.get('focus') || '';
    renderGraph(canonicalPath(focus) && state.documents.has(focus) ? focus : '');
  } else if (filters.q || filters.layer || filters.platform || filters.status) renderSearch(filters);
  else renderHome();
  window.scrollTo(0, 0);
  restoreFragment();
  if (!graph && document.documentElement.dataset.appReady !== 'error') {
    document.documentElement.dataset.appReady = 'true';
    document.documentElement.dataset.wikiReady = 'true';
  }
}
function filterChanged() {
  const url = new URL(entry);
  if (search.value.trim()) url.searchParams.set('q', search.value);
  for (const [name, control] of Object.entries(controls)) if (control.value) url.searchParams.set(name, control.value);
  navigate(url.href, true);
}
function validateData(data) {
  if (!data || data.version !== 1 || !Array.isArray(data.documents) || data.documents.length > 4096 || !Array.isArray(data.edges)) throw new Error('The wiki data format is not supported.');
  if (!/^https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(data.repository) || !/^[a-f0-9]{40,64}$/.test(data.revision) || typeof data.zig !== 'string') throw new Error('The wiki source identity is incomplete.');
  if (!data.aliases || typeof data.aliases !== 'object' || Array.isArray(data.aliases)) throw new Error('The wiki link map is unavailable.');
  const paths = new Set();
  for (const doc of data.documents) {
    if (!canonicalPath(doc.path) || paths.has(doc.path) || !Object.prototype.hasOwnProperty.call(layers, doc.layer) || typeof doc.title !== 'string' || typeof doc.body !== 'string' || doc.body.length > 2 * 1024 * 1024) throw new Error('A wiki document has invalid data.');
    if (![doc.sources, doc.proofs, doc.platforms, doc.links].every(list => Array.isArray(list) && list.every(value => typeof value === 'string'))) throw new Error('A wiki document has invalid metadata.');
    if (typeof doc.summary !== 'string' || typeof doc.status !== 'string' || typeof doc.updated !== 'string') throw new Error('A wiki document has incomplete metadata.');
    paths.add(doc.path);
  }
  for (const target of Object.values(data.aliases)) if (!paths.has(target)) throw new Error('The wiki link map has an unknown document.');
  if (data.assets !== undefined && (!Array.isArray(data.assets) || !data.assets.every(path => canonicalPath(path)))) throw new Error('The wiki image map is invalid.');
  for (const edge of data.edges) if (!paths.has(edge.source) || !paths.has(edge.target) || !['link', 'source', 'proof'].includes(edge.type)) throw new Error('The wiki graph has an invalid connection.');
  return data;
}
async function boot() {
  const controller = new AbortController(); const timer = setTimeout(() => controller.abort(), 15000);
  let data;
  try {
    const response = await fetch(new URL('data.json', entry), {signal: controller.signal, credentials: 'same-origin'});
    if (!response.ok) throw new Error('The wiki data could not be loaded. Please reload the published site.');
    if (Number(response.headers.get('Content-Length')) > 16 * 1024 * 1024) throw new Error('The wiki data exceeds this reader’s limit.');
    const text = await response.text();
    if (text.length > 16 * 1024 * 1024) throw new Error('The wiki data exceeds this reader’s limit.');
    data = validateData(JSON.parse(text));
  } finally { clearTimeout(timer); }
  state.data = data;
  state.documents = new Map(data.documents.map(doc => [doc.path, doc]));
  state.assets = new Set(data.assets || []);
  state.searchable = data.documents.map(doc => {
    const plain = plainText(doc.body); const title = doc.title.toLowerCase(); const summary = doc.summary.toLowerCase();
    return {doc, plain, title, summary, haystack: [title, summary, doc.path, doc.id || '', plain, ...doc.platforms, doc.status].join(' ').toLowerCase()};
  });
  const statuses = [...new Set(data.documents.map(doc => doc.status).filter(Boolean))].sort();
  for (const status of statuses) { const option = element('option', '', statusNames[status] || status); option.value = status; controls.status.append(option); }
  $('#zig-version').textContent = data.zig;
  const revision = $('#revision'); revision.replaceChildren(anchor('Revision ' + data.revision.slice(0, 12), data.repository + '/tree/' + data.revision));
  if (data.dirty) revision.append(document.createTextNode(' · development copy'));
  registerMarkdown();
  renderRoute();
}
let searchTimer;
search.addEventListener('input', () => { clearTimeout(searchTimer); searchTimer = setTimeout(filterChanged, 90); });
Object.values(controls).forEach(control => control.addEventListener('change', filterChanged));
window.addEventListener('popstate', renderRoute);
window.addEventListener('hashchange', restoreFragment);
document.addEventListener('keydown', event => {
  const typing = event.target instanceof HTMLElement && (event.target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(event.target.tagName));
  if (event.key === '/' && !typing && !event.metaKey && !event.ctrlKey && !event.altKey) { event.preventDefault(); search.focus(); search.select(); }
  if (event.key === 'Escape' && event.target === search) { clearTimeout(searchTimer); search.blur(); }
});
document.addEventListener('click', event => {
  if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  const link = event.target instanceof Element ? event.target.closest('a[href]') : null;
  if (!link || link.target === '_blank' || link.hasAttribute('download') || link.classList.contains('skip-link')) return;
  const destination = new URL(link.href, entry);
  if (destination.origin !== entry.origin || destination.pathname !== entry.pathname) return;
  event.preventDefault();
  clearTimeout(searchTimer);
  if (destination.search === location.search && destination.hash) {
    history.pushState(null, '', destination.href); restoreFragment();
  } else navigate(destination.href);
});
boot().catch(error => {
  showError('The field guide could not open.', error.name === 'AbortError' ? 'The data request timed out. Please reload the page.' : error.message || 'Please reload the published site.');
});
