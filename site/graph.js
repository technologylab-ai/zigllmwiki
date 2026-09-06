const SVG = 'http://www.w3.org/2000/svg';
const LAYERS = {wiki: 'Wiki', source: 'Sources', proof: 'Proofs', project: 'Project'};
let mounts = 0;

const CSS = `
.wiki-graph{--wg-paper:#fffdf7;--wg-ink:#172936;--wg-muted:#64716e;--wg-accent:#b4432d;--wg-line:#dedfd5;color:var(--wg-ink);font:14px/1.5 system-ui,-apple-system,'Segoe UI',sans-serif;min-width:0}
.wiki-graph *{box-sizing:border-box}.wiki-graph button,.wiki-graph input{font:inherit}.wiki-graph button{cursor:pointer}.wiki-graph button:disabled{cursor:default;opacity:.45}.wiki-graph button:focus-visible,.wiki-graph input:focus-visible,.wiki-graph summary:focus-visible,.wiki-graph svg:focus-visible{outline:3px solid var(--wg-accent);outline-offset:3px}
.wiki-graph .wg-toolbar{display:flex;align-items:center;flex-wrap:wrap;gap:14px 22px;margin:0 0 16px}.wiki-graph .wg-find{display:flex;align-items:center;gap:10px;flex:1 1 220px}.wiki-graph .wg-find span{font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--wg-muted);white-space:nowrap}.wiki-graph .wg-find input{width:100%;min-width:100px;border:1px solid var(--wg-line);border-radius:6px;padding:9px 12px;background:var(--wg-paper);color:var(--wg-ink)}
.wiki-graph .wg-layers{display:flex;flex-wrap:wrap;gap:12px;border:0;padding:0;margin:0}.wiki-graph .wg-layers legend{position:absolute;width:1px;height:1px;overflow:hidden;clip-path:inset(50%)}.wiki-graph .wg-layers label{display:flex;align-items:center;gap:5px;cursor:pointer;font-size:12px}.wiki-graph .wg-layers input{accent-color:var(--wg-accent);margin:0}.wiki-graph .wg-layer-dot{width:7px;height:7px;border-radius:50%;display:inline-block;background:#172936}.wiki-graph [data-layer=source]{--wg-node:#6f9388}.wiki-graph [data-layer=proof]{--wg-node:#b99855}.wiki-graph [data-layer=project]{--wg-node:#8a8094}.wiki-graph [data-layer=wiki]{--wg-node:#172936}.wiki-graph .wg-layer-dot{background:var(--wg-node)}
.wiki-graph .wg-button{border:1px solid var(--wg-line);border-radius:5px;padding:8px 12px;background:var(--wg-paper);color:var(--wg-ink);font-size:12px;line-height:1.3}.wiki-graph .wg-button[aria-pressed=true]{background:var(--wg-ink);border-color:var(--wg-ink);color:var(--wg-paper)}
.wiki-graph .wg-meta{display:flex;justify-content:space-between;flex-wrap:wrap;gap:8px;margin-bottom:10px;color:var(--wg-muted);font-size:12px}.wiki-graph .wg-frame{position:relative;height:500px;border:1px solid var(--wg-line);border-radius:10px;background:radial-gradient(ellipse at 50% 45%,#fffefb 0%,#f5f2e9 100%);overflow:hidden;isolation:isolate}.wiki-graph .wg-svg{display:block;width:100%;height:100%;touch-action:none;cursor:grab}.wiki-graph .wg-svg.wg-dragging{cursor:grabbing}.wiki-graph .wg-controls{position:absolute;top:14px;right:14px;display:flex;gap:5px}.wiki-graph .wg-controls button{min-width:34px;background:#fffdf7ed;box-shadow:0 1px 4px #17293608}.wiki-graph .wg-help{position:absolute;left:16px;bottom:12px;right:16px;pointer-events:none;font-size:11px;color:var(--wg-muted);margin:0}.wiki-graph .wg-empty{position:absolute;inset:40% 20px auto;text-align:center;color:var(--wg-muted);pointer-events:none}
.wiki-graph .wg-edge{stroke:#87968d;stroke-width:.85;stroke-opacity:.27;vector-effect:non-scaling-stroke}.wiki-graph .wg-edge[data-type=source]{stroke:#729085;stroke-dasharray:3 3}.wiki-graph .wg-edge[data-type=proof]{stroke:#ab8a50;stroke-dasharray:1 4}.wiki-graph .wg-edge.wg-hot{stroke:var(--wg-accent);stroke-width:1.35;stroke-opacity:.7}.wiki-graph .wg-edge.wg-dim{stroke-opacity:.065}.wiki-graph .wg-node{cursor:pointer}.wiki-graph .wg-dot{fill:var(--wg-node);stroke:var(--wg-paper);stroke-width:1.5;vector-effect:non-scaling-stroke}.wiki-graph .wg-halo{fill:none;stroke:var(--wg-accent);stroke-width:1.5;stroke-opacity:0;vector-effect:non-scaling-stroke}.wiki-graph .wg-node.wg-hot .wg-dot,.wiki-graph .wg-node.wg-selected .wg-dot{fill:var(--wg-accent)}.wiki-graph .wg-node.wg-selected .wg-halo{stroke-opacity:.7}.wiki-graph .wg-node.wg-dim{opacity:.22}.wiki-graph .wg-label{fill:var(--wg-ink);font-family:system-ui,-apple-system,'Segoe UI',sans-serif;paint-order:stroke;stroke:var(--wg-paper);stroke-linejoin:round;pointer-events:none}.wiki-graph .wg-label.wg-hot{fill:var(--wg-accent);font-weight:650}
.wiki-graph .wg-details{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:14px 26px;align-items:center;padding:21px 0;border-bottom:1px solid var(--wg-line)}.wiki-graph .wg-details h3{font:400 23px/1.25 Georgia,serif;margin:0 0 8px;overflow-wrap:anywhere}.wiki-graph .wg-details p{margin:0;color:var(--wg-muted);font-size:13px;max-width:76ch}.wiki-graph .wg-detail-meta{display:block;font-size:10px;letter-spacing:.06em;text-transform:uppercase;color:var(--wg-muted);margin-bottom:7px}.wiki-graph .wg-open{background:var(--wg-accent);border-color:var(--wg-accent);color:white;padding:10px 17px;white-space:nowrap}.wiki-graph .wg-key{display:flex;flex-wrap:wrap;gap:8px 18px;font-size:11px;color:var(--wg-muted);padding:13px 0}.wiki-graph .wg-key span{display:inline-flex;align-items:center;gap:6px}.wiki-graph .wg-key i{display:inline-block;width:19px;height:0;border-top:1px solid #87968d}.wiki-graph .wg-key [data-type=source]{border-color:#729085;border-top-style:dashed}.wiki-graph .wg-key [data-type=proof]{border-color:#ab8a50;border-top-style:dotted}
.wiki-graph .wg-list{border-top:1px solid var(--wg-line);margin-top:4px}.wiki-graph .wg-list summary{cursor:pointer;padding:15px 0;font-size:13px}.wiki-graph .wg-list ul{list-style:none;display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:0 22px;padding:0;margin:0;max-height:360px;overflow:auto}.wiki-graph .wg-list li{display:flex;align-items:center;gap:8px;border-top:1px solid var(--wg-line);min-width:0}.wiki-graph .wg-list button{border:0;background:none;color:var(--wg-ink);text-align:left;padding:12px 0}.wiki-graph .wg-list .wg-pick{flex:1;min-width:0;overflow-wrap:anywhere}.wiki-graph .wg-list .wg-pick[aria-pressed=true]{color:var(--wg-accent)}.wiki-graph .wg-list small{display:block;font-size:10px;color:var(--wg-muted);margin-top:3px}.wiki-graph .wg-list .wg-list-open{color:var(--wg-accent);font-size:11px;white-space:nowrap}.wiki-graph .wg-list-empty{color:var(--wg-muted);padding:10px 0}
@media(max-width:600px){.wiki-graph .wg-toolbar{gap:12px}.wiki-graph .wg-find{flex-basis:100%}.wiki-graph .wg-layers{gap:12px}.wiki-graph .wg-frame{height:420px}.wiki-graph .wg-details{grid-template-columns:minmax(0,1fr)}.wiki-graph .wg-open{justify-self:start}.wiki-graph .wg-list ul{grid-template-columns:minmax(0,1fr)}.wiki-graph .wg-help{font-size:10px}.wiki-graph .wg-meta{font-size:11px}}
@media(prefers-reduced-motion:reduce){.wiki-graph *{scroll-behavior:auto!important;transition:none!important;animation:none!important}}
`;

function element(tag, attributes = {}, text = '') {
  const node = document.createElement(tag);
  for (const [name, value] of Object.entries(attributes)) node.setAttribute(name, value);
  if (text) node.textContent = text;
  return node;
}

function vector(tag, attributes = {}) {
  const node = document.createElementNS(SVG, tag);
  for (const [name, value] of Object.entries(attributes)) node.setAttribute(name, value);
  return node;
}

function compare(a, b) { return a < b ? -1 : a > b ? 1 : 0; }

function hash(value) {
  let result = 2166136261;
  for (let index = 0; index < value.length; index++) result = Math.imul(result ^ value.charCodeAt(index), 16777619);
  return result >>> 0;
}

function model(data) {
  const documents = new Map();
  for (const entry of data.documents || []) {
    if (typeof entry.path !== 'string' || documents.has(entry.path)) continue;
    const layer = Object.hasOwn(LAYERS, entry.layer) ? entry.layer : 'project';
    documents.set(entry.path, {...entry, layer, title: entry.title || entry.path});
  }
  const edges = new Map();
  const neighbors = new Map([...documents.keys()].map(key => [key, new Set()]));
  function add(source, target, type) {
    if (source === target || !documents.has(source) || !documents.has(target)) return;
    const key = [source, target].sort(compare).join('\0');
    const rank = {link: 0, source: 1, proof: 2};
    const effective = Object.hasOwn(rank, type) ? type : 'link';
    if (!edges.has(key)) edges.set(key, {source, target, type: effective});
    else if (rank[effective] > rank[edges.get(key).type]) edges.get(key).type = effective;
    neighbors.get(source).add(target); neighbors.get(target).add(source);
  }
  for (const edge of data.edges || []) add(edge.source, edge.target, edge.type);
  for (const entry of documents.values()) {
    for (const target of entry.links || []) add(entry.path, target, documents.get(target)?.layer);
  }
  return {documents, edges: [...edges.values()], neighbors};
}

// Compute finite force targets. Rendering interpolates toward them and then stops.
function layout(documents, edges, focus, previous = new Map()) {
  const nodes = documents.map((note, index) => {
    const angle = index * 2.399963229728653 + (hash(note.path) % 100) / 400;
    const radius = 35 + 210 * Math.sqrt((index + 1) / Math.max(1, documents.length));
    const old = previous.get(note.path);
    return {path: note.path, x: old ? old.x : Math.cos(angle) * radius, y: old ? old.y : Math.sin(angle) * radius, vx: 0, vy: 0};
  });
  const byPath = new Map(nodes.map(node => [node.path, node]));
  const center = byPath.get(focus);
  if (center) { center.x = 0; center.y = 0; }
  const allPairs = nodes.length * (nodes.length - 1) / 2;
  const stride = Math.max(1, Math.ceil(allPairs / 100000));
  const pairs = Math.ceil(allPairs / stride) + nodes.length + edges.length + 1;
  const iterations = Math.max(1, Math.min(80, Math.floor(1500000 / pairs)));
  for (let turn = 0; turn < iterations; turn++) {
    for (let i = 0; i < nodes.length; i++) {
      const left = nodes[i];
      for (let j = i + 1; j < nodes.length; j += stride) {
        const right = nodes[j];
        const dx = left.x - right.x || .01, dy = left.y - right.y || .01;
        const squared = dx * dx + dy * dy + 100;
        const force = 1200 / (squared * Math.sqrt(squared));
        left.vx += dx * force; left.vy += dy * force;
        right.vx -= dx * force; right.vy -= dy * force;
      }
    }
    for (const edge of edges) {
      const left = byPath.get(edge.source), right = byPath.get(edge.target);
      const dx = right.x - left.x, dy = right.y - left.y;
      const distance = Math.max(1, Math.hypot(dx, dy));
      const force = (distance - 80) * .009 / distance;
      left.vx += dx * force; left.vy += dy * force;
      right.vx -= dx * force; right.vy -= dy * force;
    }
    for (const node of nodes) {
      if (node.path === focus) { node.x = 0; node.y = 0; node.vx = 0; node.vy = 0; continue; }
      node.vx = (node.vx - node.x * .001) * .76;
      node.vy = (node.vy - node.y * .001) * .76;
      node.x += Math.max(-8, Math.min(8, node.vx));
      node.y += Math.max(-8, Math.min(8, node.vy));
    }
  }
  return byPath;
}

/** Mount one graph. The caller owns navigation and must call the returned cleanup. */
export function mountGraph(container, data, {focus = null, onNavigate} = {}) {
  const id = 'wiki-graph-' + ++mounts;
  const graph = model(data);
  const activeLayers = new Set(Object.keys(LAYERS));
  let selected = graph.documents.has(focus) ? focus : null;
  if (selected) activeLayers.add(graph.documents.get(selected).layer);
  let neighborhood = false, query = '', hovered = null, disposed = false;
  let visible = [], visibleEdges = [], positions = new Map(), degree = new Map();
  const remembered = new Map();
  let nodeElements = new Map(), edgeElements = [], labelOrder = [];
  let width = 900, height = 500, view = {x: 450, y: 250, scale: 1};
  let pointer = null, dragged = false;
  let animation = null, animationFrame = null;
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const listeners = new AbortController();
  const listen = (target, event, handler, options = {}) => target.addEventListener(event, handler, {...options, signal: listeners.signal});
  const root = element('section', {class: 'wiki-graph', 'aria-label': 'Interactive note graph', 'data-motion': 'settled'});
  root.append(element('style', {}, CSS));
  const toolbar = element('div', {class: 'wg-toolbar'});
  const findLabel = element('label', {class: 'wg-find'});
  const find = element('input', {type: 'search', placeholder: 'Title, topic, or path', 'aria-label': 'Find a note', 'aria-describedby': id + '-search-help'});
  findLabel.append(element('span', {}, 'Find a note'), find); toolbar.append(findLabel);
  const layers = element('fieldset', {class: 'wg-layers'}); layers.append(element('legend', {}, 'Visible layers'));
  for (const [layer, name] of Object.entries(LAYERS)) {
    const label = element('label', {'data-layer': layer});
    const control = element('input', {type: 'checkbox', value: layer}); control.checked = activeLayers.has(layer);
    control.disabled = ![...graph.documents.values()].some(note => note.layer === layer);
    label.append(control, element('span', {class: 'wg-layer-dot', 'aria-hidden': 'true'}), document.createTextNode(name)); layers.append(label);
    listen(control, 'change', () => {
      if (control.checked) activeLayers.add(layer); else activeLayers.delete(layer);
      if (selected && !activeLayers.has(graph.documents.get(selected).layer)) { selected = null; neighborhood = false; }
      render();
    });
  }
  toolbar.append(layers);
  const local = element('button', {class: 'wg-button', type: 'button', 'aria-pressed': String(neighborhood)}, 'Neighborhood');
  toolbar.append(local); root.append(toolbar);
  const meta = element('div', {class: 'wg-meta'});
  const counts = element('span', {role: 'status', 'aria-live': 'polite'});
  const searchHelp = element('span', {id: id + '-search-help'}, 'Find highlights notes and narrows the list.');
  meta.append(counts, searchHelp); root.append(meta);
  const frame = element('div', {class: 'wg-frame'});
  const svg = vector('svg', {class: 'wg-svg', tabindex: '0', role: 'img', 'aria-label': 'Connected notes. Select a node to center and rearrange the graph. The note list supports keyboard selection.', 'aria-describedby': id + '-help'});
  const stage = vector('g'); svg.append(stage); frame.append(svg);
  const controls = element('div', {class: 'wg-controls', 'aria-label': 'Graph view controls'});
  const zoomIn = element('button', {class: 'wg-button', type: 'button', 'aria-label': 'Zoom in'}, '+');
  const zoomOut = element('button', {class: 'wg-button', type: 'button', 'aria-label': 'Zoom out'}, '−');
  const reset = element('button', {class: 'wg-button', type: 'button', 'aria-label': 'Fit all visible notes'}, 'Reset');
  controls.append(zoomIn, zoomOut, reset); frame.append(controls);
  frame.append(element('p', {class: 'wg-help', id: id + '-help'}, 'Select a node to center its connections. Drag to pan. + / − zoom. Arrow keys pan. Home resets.'));
  const empty = element('p', {class: 'wg-empty'}); frame.append(empty); root.append(frame);
  const details = element('div', {class: 'wg-details', 'aria-live': 'polite', 'aria-atomic': 'true'});
  const detailText = element('div'), detailMeta = element('span', {class: 'wg-detail-meta'});
  const title = element('h3'), description = element('p'); detailText.append(detailMeta, title, description);
  const open = element('button', {class: 'wg-button wg-open', type: 'button'}, 'Open note →');
  details.append(detailText, open); root.append(details);
  const legend = element('div', {class: 'wg-key', 'aria-label': 'Connection legend'});
  for (const [type, label] of [['link', 'Note link'], ['source', 'Source reference'], ['proof', 'Proof reference']]) {
    const item = element('span'); item.append(element('i', {'data-type': type, 'aria-hidden': 'true'}), document.createTextNode(label)); legend.append(item);
  }
  legend.append(element('span', {}, 'Larger dots have more visible links.')); root.append(legend);
  const list = element('details', {class: 'wg-list', open: ''}), listSummary = element('summary'), listItems = element('ul');
  const listEmpty = element('p', {class: 'wg-list-empty'}); list.append(listSummary, listItems, listEmpty); root.append(list);
  container.append(root);

  function matches(note) {
    if (!query) return true;
    return [note.title, note.path, note.summary, note.kind, ...(note.platforms || [])].join(' ').toLowerCase().includes(query);
  }

  function navigate(path) { if (typeof onNavigate === 'function') onNavigate(path); }

  function updateDetails() {
    const note = graph.documents.get(selected);
    detailMeta.textContent = note ? LAYERS[note.layer] + ' · ' + (degree.get(selected) || 0) + ' visible connections' : 'Explore the wiki';
    title.textContent = note ? note.title : 'Follow a connection.';
    description.textContent = note ? (note.summary || 'This note has no recorded summary.') : 'Select a dot to center its connections and read its summary. Open the note to inspect its guidance and evidence.';
    open.disabled = !note || typeof onNavigate !== 'function';
    local.disabled = !note; local.title = note ? 'Show this note and its direct neighbors' : 'Select a note first';
    local.setAttribute('aria-pressed', String(neighborhood));
  }

  function updateList() {
    const notes = visible.filter(matches).sort((a, b) => compare(a.title.toLowerCase(), b.title.toLowerCase()) || compare(a.path, b.path));
    listSummary.textContent = (query ? 'Matching notes' : 'Visible notes') + ' (' + notes.length + ')';
    listEmpty.textContent = notes.length ? '' : 'No notes match these controls.'; listEmpty.hidden = !!notes.length;
    listItems.replaceChildren();
    for (const note of notes) {
      const item = element('li');
      const pick = element('button', {class: 'wg-pick', type: 'button', 'data-wg-select': note.path, 'aria-pressed': String(note.path === selected)});
      pick.append(document.createTextNode(note.title), element('small', {}, LAYERS[note.layer] + ' · ' + (degree.get(note.path) || 0) + ' visible connections'));
      const go = element('button', {class: 'wg-list-open', type: 'button', 'data-wg-open': note.path, 'aria-label': 'Open ' + note.title}, 'Open →');
      go.disabled = typeof onNavigate !== 'function';
      item.append(pick, go); listItems.append(item);
    }
    const isolated = visible.filter(note => degree.get(note.path) === 0).length;
    counts.textContent = (query ? notes.length + ' matches · ' : '') + visible.length + ' notes · ' + visibleEdges.length + ' links' + (isolated ? ' · ' + isolated + ' unlinked in this view' : '');
  }

  function choose(path, fromList = false) {
    if (!graph.documents.has(path)) return;
    selected = path; hovered = null;
    if (neighborhood) render();
    else {
      const target = layout(visible, visibleEdges, selected, positions);
      transition(target, {x: width / 2, y: height / 2, scale: view.scale});
      paint(); updateDetails(); updateList();
    }
    if (fromList) open.focus({preventScroll: true});
  }

  function labels() {
    const hot = hovered || selected, used = [];
    const candidates = [...labelOrder].sort((a, b) => Number(b.path === hot) - Number(a.path === hot) || Number(b.path === selected) - Number(a.path === selected));
    let shown = 0;
    for (const note of candidates) {
      const item = nodeElements.get(note.path), position = positions.get(note.path);
      const radius = 4 + Math.min(5, Math.sqrt(degree.get(note.path) || 0));
      item.dot.setAttribute('r', radius / view.scale); item.halo.setAttribute('r', (radius + 5) / view.scale);
      const isHot = note.path === hot || note.path === selected;
      item.label.style.display = 'none';
      if (!isHot && (shown >= (width < 600 ? 6 : 13) || (query && !matches(note)))) continue;
      const text = note.title.length > 38 ? note.title.slice(0, 36) + '…' : note.title;
      const textWidth = text.length * 6.2;
      const screenX = position.x * view.scale + view.x, screenY = position.y * view.scale + view.y;
      const right = screenX + radius + 7 + textWidth <= width - 12;
      const x = right ? screenX + radius + 7 : screenX - radius - 7 - textWidth;
      const rectangle = {x, y: screenY - 9, right: x + textWidth, bottom: screenY + 10};
      if (rectangle.x < 8 || rectangle.right > width - 8 || rectangle.y < 10 || rectangle.bottom > height - 30) continue;
      if (!isHot && used.some(other => rectangle.x < other.right + 8 && rectangle.right > other.x - 8 && rectangle.y < other.bottom + 4 && rectangle.bottom > other.y - 4)) continue;
      used.push(rectangle); shown++;
      item.label.textContent = text; item.label.style.display = '';
      item.label.setAttribute('x', position.x + (right ? radius + 7 : -radius - 7) / view.scale);
      item.label.setAttribute('y', position.y + 4 / view.scale);
      item.label.setAttribute('text-anchor', right ? 'start' : 'end');
      item.label.setAttribute('font-size', 11 / view.scale); item.label.setAttribute('stroke-width', 4 / view.scale);
      item.label.classList.toggle('wg-hot', isHot);
    }
  }

  function applyView() {
    stage.setAttribute('transform', `translate(${view.x} ${view.y}) scale(${view.scale})`);
    labels();
  }

  function fitted(pointsByPath, center = false) {
    if (!pointsByPath.size) return {x: width / 2, y: height / 2, scale: 1};
    const points = [...pointsByPath.values()];
    const minX = Math.min(...points.map(point => point.x)), maxX = Math.max(...points.map(point => point.x));
    const minY = Math.min(...points.map(point => point.y)), maxY = Math.max(...points.map(point => point.y));
    const extentX = center ? 2 * Math.max(Math.abs(minX), Math.abs(maxX)) : maxX - minX;
    const extentY = center ? 2 * Math.max(Math.abs(minY), Math.abs(maxY)) : maxY - minY;
    const scale = Math.max(.15, Math.min(3, (width - 110) / Math.max(120, extentX), (height - 125) / Math.max(120, extentY)));
    return {x: width / 2 - (center ? 0 : (minX + maxX) * scale / 2), y: height / 2 - (center ? 0 : (minY + maxY) * scale / 2), scale};
  }

  function drawPositions() {
    for (const [path, point] of positions) {
      nodeElements.get(path)?.group.setAttribute('transform', `translate(${point.x} ${point.y})`);
      remembered.set(path, {path, x: point.x, y: point.y});
    }
    for (const {element: line, edge} of edgeElements) {
      const left = positions.get(edge.source), right = positions.get(edge.target);
      line.setAttribute('x1', left.x); line.setAttribute('y1', left.y);
      line.setAttribute('x2', right.x); line.setAttribute('y2', right.y);
    }
    applyView();
  }

  function stopMotion(finish = false) {
    if (animationFrame !== null) cancelAnimationFrame(animationFrame);
    animationFrame = null;
    if (finish && animation) {
      positions = animation.target;
      if (animation.camera) view = {...animation.camera};
      drawPositions();
    }
    animation = null;
    root.dataset.motion = 'settled';
  }

  function tick(now) {
    animationFrame = null;
    if (disposed || !animation) return;
    const progress = Math.max(0, Math.min(1, (now - animation.started) / 850));
    const eased = 1 - Math.pow(1 - progress, 3);
    for (const [path, target] of animation.target) {
      const start = animation.start.get(path), point = positions.get(path);
      point.x = start.x + (target.x - start.x) * eased;
      point.y = start.y + (target.y - start.y) * eased;
    }
    if (animation.camera) {
      const camera = animation.camera, start = animation.startView;
      view = {x: start.x + (camera.x - start.x) * eased, y: start.y + (camera.y - start.y) * eased, scale: start.scale + (camera.scale - start.scale) * eased};
    }
    drawPositions();
    if (progress === 1) { animation = null; root.dataset.motion = 'settled'; }
    else animationFrame = requestAnimationFrame(tick);
  }

  function transition(target, camera) {
    stopMotion();
    animation = {target, camera, start: new Map([...positions].map(([path, point]) => [path, {x: point.x, y: point.y}])), startView: {...view}, started: performance.now()};
    if (reducedMotion.matches || !target.size) { stopMotion(true); return; }
    root.dataset.motion = 'running';
    animationFrame = requestAnimationFrame(tick);
  }

  function takeCamera() {
    // Manual view controls never restart the layout or fight its camera tween.
    if (animation) animation.camera = null;
  }

  function fit() {
    stopMotion(true);
    view = fitted(positions, !!selected);
    applyView();
  }

  function zoom(factor, point = {x: width / 2, y: height / 2}) {
    takeCamera();
    const scale = Math.max(.15, Math.min(8, view.scale * factor)), ratio = scale / view.scale;
    view = {x: point.x - (point.x - view.x) * ratio, y: point.y - (point.y - view.y) * ratio, scale}; applyView();
  }

  function paint() {
    const hot = hovered || selected, neighbors = graph.neighbors.get(hot);
    for (const note of visible) {
      const group = nodeElements.get(note.path).group;
      group.classList.toggle('wg-selected', note.path === selected);
      group.classList.toggle('wg-hot', note.path === hot || (!!query && matches(note)));
      group.classList.toggle('wg-dim', !!query ? !matches(note) && note.path !== hot : !!hot && note.path !== hot && !neighbors?.has(note.path));
    }
    for (const {element: line, edge} of edgeElements) {
      const connected = edge.source === hot || edge.target === hot;
      line.classList.toggle('wg-hot', !!hot && connected);
      line.classList.toggle('wg-dim', (!!hot && !connected) || (!!query && !matches(graph.documents.get(edge.source)) && !matches(graph.documents.get(edge.target))));
    }
    labels();
  }

  function render() {
    stopMotion();
    hovered = null;
    for (const [path, point] of positions) remembered.set(path, {path, x: point.x, y: point.y});
    const neighborhoodPaths = neighborhood && selected ? new Set([selected, ...graph.neighbors.get(selected)]) : null;
    visible = [...graph.documents.values()].filter(note => activeLayers.has(note.layer) && (!neighborhoodPaths || neighborhoodPaths.has(note.path))).sort((a, b) => compare(a.path, b.path));
    const paths = new Set(visible.map(note => note.path));
    visibleEdges = graph.edges.filter(edge => paths.has(edge.source) && paths.has(edge.target));
    degree = new Map(visible.map(note => [note.path, 0]));
    for (const edge of visibleEdges) { degree.set(edge.source, degree.get(edge.source) + 1); degree.set(edge.target, degree.get(edge.target) + 1); }
    const oldPositions = positions;
    positions = new Map(visible.map((note, index) => {
      const old = oldPositions.get(note.path) || remembered.get(note.path);
      const angle = index * 2.399963229728653 + (hash(note.path) % 100) / 400;
      const radius = 35 + 210 * Math.sqrt((index + 1) / Math.max(1, visible.length));
      return [note.path, {path: note.path, x: old ? old.x : Math.cos(angle) * radius, y: old ? old.y : Math.sin(angle) * radius}];
    }));
    const target = layout(visible, visibleEdges, selected, positions);
    labelOrder = [...visible].sort((a, b) => degree.get(b.path) - degree.get(a.path) || compare(a.path, b.path));
    nodeElements = new Map(); edgeElements = [];
    const lines = vector('g', {'aria-hidden': 'true'}), nodes = vector('g'), names = vector('g', {'aria-hidden': 'true'});
    for (const edge of visibleEdges) {
      const left = positions.get(edge.source), right = positions.get(edge.target);
      const line = vector('line', {class: 'wg-edge', 'data-type': edge.type, x1: left.x, y1: left.y, x2: right.x, y2: right.y});
      lines.append(line); edgeElements.push({element: line, edge});
    }
    for (const note of visible) {
      const point = positions.get(note.path);
      const group = vector('g', {class: 'wg-node', 'data-layer': note.layer, 'data-wg-path': note.path, transform: `translate(${point.x} ${point.y})`});
      const halo = vector('circle', {class: 'wg-halo'}), dot = vector('circle', {class: 'wg-dot'});
      const tooltip = vector('title'); tooltip.textContent = note.title + ' · ' + LAYERS[note.layer];
      group.append(halo, dot, tooltip); nodes.append(group);
      const label = vector('text', {class: 'wg-label'}); names.append(label);
      nodeElements.set(note.path, {group, dot, halo, label});
    }
    stage.replaceChildren(lines, nodes, names);
    empty.textContent = activeLayers.size ? 'This view has no connected notes in the selected layers.' : 'Choose a layer to show notes.';
    empty.hidden = !!visible.length;
    updateDetails(); updateList();
    if (!oldPositions.size) view = fitted(positions);
    applyView(); paint();
    transition(target, fitted(target, !!selected));
  }

  function point(event) {
    const value = svg.createSVGPoint(); value.x = event.clientX; value.y = event.clientY;
    return value.matrixTransform(svg.getScreenCTM().inverse());
  }

  listen(find, 'input', () => { query = find.value.trim().toLowerCase(); updateList(); paint(); });
  listen(listItems, 'click', event => {
    const pick = event.target.closest('[data-wg-select]');
    const go = event.target.closest('[data-wg-open]');
    if (pick) choose(pick.getAttribute('data-wg-select'), true);
    else if (go) navigate(go.getAttribute('data-wg-open'));
  });
  listen(local, 'click', () => { neighborhood = !neighborhood; render(); });
  listen(open, 'click', () => { if (selected) navigate(selected); });
  listen(zoomIn, 'click', () => zoom(1.3)); listen(zoomOut, 'click', () => zoom(1 / 1.3)); listen(reset, 'click', fit);
  listen(svg, 'wheel', event => {
    if (!event.ctrlKey && !event.metaKey) return;
    event.preventDefault(); zoom(Math.exp(-Math.max(-100, Math.min(100, event.deltaY)) * .008), point(event));
  }, {passive: false});
  listen(svg, 'keydown', event => {
    if (event.key === '+' || event.key === '=') zoom(1.3);
    else if (event.key === '-') zoom(1 / 1.3);
    else if (event.key === 'Home' || event.key === '0') fit();
    else if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(event.key)) {
      takeCamera();
      view.x += event.key === 'ArrowLeft' ? 30 : event.key === 'ArrowRight' ? -30 : 0;
      view.y += event.key === 'ArrowUp' ? 30 : event.key === 'ArrowDown' ? -30 : 0; applyView();
    } else return;
    event.preventDefault();
  });
  listen(svg, 'pointerdown', event => {
    if (event.button !== 0 || pointer) return;
    takeCamera();
    const start = point(event), target = event.target.closest('[data-wg-path]')?.getAttribute('data-wg-path');
    pointer = {id: event.pointerId, start, x: view.x, y: view.y, target}; dragged = false;
    svg.setPointerCapture(event.pointerId);
  });
  listen(svg, 'pointermove', event => {
    if (pointer?.id === event.pointerId) {
      const current = point(event), dx = current.x - pointer.start.x, dy = current.y - pointer.start.y;
      if (Math.hypot(dx, dy) > 4) dragged = true;
      if (dragged) { view.x = pointer.x + dx; view.y = pointer.y + dy; svg.classList.add('wg-dragging'); applyView(); }
    }
  });
  function release(event) {
    if (pointer?.id !== event.pointerId) return;
    const target = pointer.target;
    pointer = null; svg.classList.remove('wg-dragging');
    if (svg.hasPointerCapture(event.pointerId)) svg.releasePointerCapture(event.pointerId);
    if (event.type === 'pointerup' && !dragged && target) choose(target);
  }
  listen(svg, 'pointerup', release); listen(svg, 'pointercancel', release);
  listen(svg, 'pointerover', event => {
    if (pointer) return;
    const node = event.target.closest('[data-wg-path]'); const next = node?.getAttribute('data-wg-path') || null;
    if (next !== hovered) { hovered = next; paint(); }
  });
  listen(svg, 'pointerleave', () => { if (hovered) { hovered = null; paint(); } });
  listen(reducedMotion, 'change', () => { if (reducedMotion.matches) stopMotion(true); });
  const resize = new ResizeObserver(() => {
    if (disposed) return;
    const nextWidth = Math.max(280, frame.clientWidth), nextHeight = Math.max(300, frame.clientHeight);
    if (nextWidth === width && nextHeight === height) return;
    width = nextWidth; height = nextHeight; svg.setAttribute('viewBox', `0 0 ${width} ${height}`); fit();
  });
  width = Math.max(280, frame.clientWidth); height = Math.max(300, frame.clientHeight);
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
  render(); resize.observe(frame);
  return () => { disposed = true; stopMotion(); listeners.abort(); resize.disconnect(); root.remove(); };
}
