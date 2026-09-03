'use strict';
// The report is a single static page: all state lives in the URL hash so any
// view can be linked to from another view or shared as-is.
const data = JSON.parse(document.getElementById('report-data').textContent);
const $ = (id) => document.getElementById(id);

function esc(value) {
  return String(value === undefined || value === null ? '' : value)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

// ---------------------------------------------------------------- vocabulary
// Each badge state carries a tone, an icon and a definition. Nothing is ever
// distinguished by colour alone: the icon and the words carry the same meaning.
const VOCAB = {
  support: {
    title: 'Upstream claim',
    question: 'What does the OpenTelemetry compliance matrix say this language supports?',
    states: {
      supported: ['ok', '●', 'The upstream matrix lists this feature as implemented for the language.'],
      unsupported: ['bad', '✕', 'The upstream matrix lists this feature as not implemented.'],
      'n/a': ['neutral', '–', 'The feature does not apply to this language.'],
      unknown: ['warn', '?', 'The upstream matrix does not state a position.'],
    },
  },
  verification: {
    title: 'Corpus verification',
    question: 'What did this repository’s end-to-end suite actually assert?',
    states: {
      verified: ['ok', '✓', 'An executable proof plan asserted this feature and a current-revision receipt accepted it.'],
      known_gap: ['bad', '✕', 'The corpus deliberately records this feature as missing in the implementation.'],
      not_exercised: ['warn', '○', 'No scenario in this corpus exercises the feature; nothing is claimed either way.'],
      not_applicable: ['neutral', '–', 'The feature does not apply to this profile.'],
    },
  },
  coverage: {
    title: 'Scenario coverage',
    question: 'How tightly does the corpus pin this scenario for this implementation?',
    states: {
      exact_shape: ['ok', '■', 'A checked-in scenario shape pins the exact trace and span structure.'],
      contract_only: ['warn', '▣', 'Only the shared capture contract is asserted; the exact shape is not pinned.'],
      unavailable: ['bad', '✕', 'The scenario is not exercised for this implementation.'],
    },
  },
  basis: {
    title: 'Evidence basis',
    question: 'How was the claim proved?',
    states: {
      observed: ['ok', '◉', 'The assertion was observed directly in a captured telemetry payload.'],
      corroborated: ['info', '◈', 'The observation is backed by an additional immutable upstream source.'],
    },
  },
  receipt: {
    title: 'Receipt outcome',
    question: 'How did the end-to-end run that produced this evidence end?',
    states: {
      verified: ['ok', '✓', 'The run passed and its digests matched the assembled plan, capture and shape.'],
      xfail: ['warn', '○', 'The run failed as expected; it is recorded but proves nothing.'],
    },
  },
};

function badge(vocabulary, state) {
  const group = VOCAB[vocabulary];
  const entry = (group && group.states[state]) || ['neutral', '–', ''];
  const label = String(state || '-').replace(/_/g, ' ');
  return '<span class="badge state-' + entry[0] + '" title="' + esc(group.title + ': ' + entry[2]) +
    '"><span class="icon" aria-hidden="true">' + entry[1] + '</span>' + esc(label) + '</span>';
}

// ------------------------------------------------------------------ indexing
const manifestByProfile = new Map(data.manifests.map((m) => [m.profile, m]));
const shapeByKey = new Map(data.shapes.map((s) => [s.profile + ' ' + s.scenario, s]));
const coverageByKey = new Map(data.coverage.map((c) => [c.profile + ' ' + c.scenario, c.state]));
const comparisonByKey = new Map(data.comparisons.map((c) => [c.leftProfile + ' ' + c.rightProfile + ' ' + c.scenario, c]));

function profileName(profile) {
  const manifest = manifestByProfile.get(profile);
  return manifest ? manifest.displayName : profile;
}
function profileLabel(profile) {
  const manifest = manifestByProfile.get(profile);
  if (!manifest) return profile;
  return manifest.shortLabel || manifest.displayName;
}
function comparisonFor(left, right, scenario) {
  const direct = comparisonByKey.get(left + ' ' + right + ' ' + scenario);
  if (direct) return { comparison: direct, flipped: false };
  const reverse = comparisonByKey.get(right + ' ' + left + ' ' + scenario);
  if (reverse) return { comparison: reverse, flipped: true };
  return null;
}

// -------------------------------------------------------------- hash routing
function readHash() {
  const raw = location.hash.replace(/^#/, '');
  const parts = raw.split('?');
  return { section: parts[0] || 'overview', params: new URLSearchParams(parts[1] || '') };
}
function writeHash(section, params) {
  const query = params && params.toString();
  const next = '#' + section + (query ? '?' + query : '');
  if (location.hash !== next) history.replaceState(null, '', next);
}
function markNav(section) {
  for (const link of document.querySelectorAll('nav.top a')) {
    link.setAttribute('aria-current', String(link.getAttribute('href') === '#' + section));
  }
}

// ------------------------------------------------------------------ overview
function coverageCounts(profile) {
  const counts = { exact_shape: 0, contract_only: 0, unavailable: 0 };
  for (const scenario of data.scenarios) {
    const state = coverageByKey.get(profile + ' ' + scenario) || 'unavailable';
    counts[state] = (counts[state] || 0) + 1;
  }
  return counts;
}

function verificationCounts(profile) {
  const counts = { verified: 0, known_gap: 0, not_exercised: 0, not_applicable: 0 };
  for (const feature of data.features) {
    const state = (data.verification[feature.id] || {})[profile];
    if (state) counts[state.state] = (counts[state.state] || 0) + 1;
  }
  return counts;
}

function renderOverview() {
  const source = data.metadata.source;
  $('meta').innerHTML =
    '<span class="pill">' + data.features.length + ' upstream features</span>' +
    '<span class="pill">' + data.manifests.length + ' implementations</span>' +
    '<span class="pill">' + data.shapes.length + ' checked-in shapes</span>' +
    '<span class="pill">' + (data.receipts || []).length + ' accepted receipts</span>' +
    '<a class="pill" href="' + esc(source.url) + '">spec ' + esc(String(source.revision).slice(0, 12)) + '</a>' +
    '<a class="pill" href="' + esc(data.metadata.maturitySource) + '">maturity source</a>';

  $('how-to-read').innerHTML =
    'Read this report in three layers. An <a href="#glossary">upstream claim</a> is what the ' +
    'OpenTelemetry compliance matrix says a language supports. A <a href="#glossary">corpus ' +
    'verification</a> is what this repository’s end-to-end suite actually asserted about a ' +
    'running implementation. An <a href="#glossary">evidence basis</a> says how that assertion was ' +
    'proved: observed in a capture, or corroborated by an immutable upstream source. The three ' +
    'never substitute for one another, and this report makes no parity judgement of its own.';

  const totals = { verified: 0, known_gap: 0, not_exercised: 0, exact_shape: 0, contract_only: 0, unavailable: 0 };
  for (const manifest of data.manifests) {
    const verification = verificationCounts(manifest.profile);
    totals.verified += verification.verified;
    totals.known_gap += verification.known_gap;
    totals.not_exercised += verification.not_exercised;
    const coverage = coverageCounts(manifest.profile);
    totals.exact_shape += coverage.exact_shape;
    totals.contract_only += coverage.contract_only;
    totals.unavailable += coverage.unavailable;
  }
  const receipts = data.receipts || [];
  const verifiedReceipts = receipts.filter((r) => r.outcome === 'verified').length;
  const tiles = [
    ['#features?verification=verified', totals.verified, 'verified feature claims'],
    ['#features?verification=known_gap', totals.known_gap, 'known gaps'],
    ['#features?verification=not_exercised', totals.not_exercised, 'not exercised'],
    ['#coverage', totals.exact_shape, 'exact-shape cells'],
    ['#coverage', totals.contract_only, 'contract-only cells'],
    ['#receipts', verifiedReceipts + ' / ' + receipts.length, 'receipts verified'],
  ];
  $('kpis').innerHTML = tiles.map((tile) =>
    '<a class="tile" href="' + tile[0] + '"><span class="value">' + esc(tile[1]) + '</span>' +
    '<span class="label">' + esc(tile[2]) + '</span></a>').join('');

  $('implementations').innerHTML = data.manifests.map((manifest) => {
    const coverage = coverageCounts(manifest.profile);
    const verification = verificationCounts(manifest.profile);
    const total = data.scenarios.length || 1;
    const width = (count) => (100 * count / total).toFixed(1) + '%';
    const evidence = (manifest.profileEvidence || []).map((item) =>
      '<a class="evidence" href="' + esc(item.href) + '">' + esc(item.label) + '</a>').join('');
    const unexercised = manifest.unexercised
      ? '<div class="signals"><span class="badge state-warn" title="This profile is declared in the corpus, but its ' +
        'container images are unpublished, so no end-to-end run produced receipts in this build. Its checked-in ' +
        'shapes are still comparable; none of its features can reach verified.">' +
        '<span class="icon" aria-hidden="true">○</span>not exercised in this build</span></div>'
      : '';
    return '<article class="card"><h3>' + esc(manifest.displayName) + '</h3>' +
      '<div class="version">' + esc(manifest.shortLabel || (manifest.language + ' / ' + manifest.framework)) + '</div>' +
      '<div class="version">' + esc(manifest.version || manifest.instrumentationVersion) + '</div>' +
      '<div class="bar" role="img" aria-label="' + coverage.exact_shape + ' exact, ' + coverage.contract_only +
        ' contract-only, ' + coverage.unavailable + ' unavailable">' +
        '<span class="seg-exact" style="width:' + width(coverage.exact_shape) + '"></span>' +
        '<span class="seg-contract" style="width:' + width(coverage.contract_only) + '"></span>' +
        '<span class="seg-unavailable" style="width:' + width(coverage.unavailable) + '"></span></div>' +
      '<div class="bar-key"><span>' + coverage.exact_shape + ' exact shape</span>' +
        '<span>' + coverage.contract_only + ' contract only</span>' +
        '<span>' + coverage.unavailable + ' unavailable</span></div>' +
      unexercised +
      '<div class="signals">' + badge('verification', 'verified') +
        '<span class="pill">' + verification.verified + ' verified claims</span></div>' +
      evidence + '</article>';
  }).join('');

  const languages = Object.keys(data.metadata.maturity).sort();
  $('maturity').innerHTML =
    '<thead><tr><th>Language</th><th>Traces</th><th>Metrics</th><th>Logs</th></tr></thead><tbody>' +
    languages.map((language) => {
      const maturity = data.metadata.maturity[language];
      return '<tr><td>' + esc(language) + '</td><td>' + esc(maturity.traces) + '</td><td>' +
        esc(maturity.metrics) + '</td><td>' + esc(maturity.logs) + '</td></tr>';
    }).join('') + '</tbody>';
}

// ------------------------------------------------------------- coverage grid
const COVERAGE_CLASS = { exact_shape: 'cell-exact', contract_only: 'cell-contract', unavailable: 'cell-unavailable' };

function otherProfileWithShape(profile, scenario) {
  for (const manifest of data.manifests) {
    if (manifest.profile !== profile && shapeByKey.has(manifest.profile + ' ' + scenario)) return manifest.profile;
  }
  const fallback = data.manifests.find((m) => m.profile !== profile);
  return fallback ? fallback.profile : profile;
}

function renderCoverageGrid() {
  const header = '<thead><tr><th>Scenario</th>' + data.manifests.map((m) =>
    '<th>' + esc(m.displayName) + '<br><small>' + esc(m.shortLabel || '') +
    (m.unexercised ? ' · not exercised' : '') + '</small></th>').join('') +
    '<th class="numeric">Exact</th></tr></thead>';
  const rows = data.scenarios.map((scenario) => {
    let exact = 0;
    const cells = data.manifests.map((manifest) => {
      const state = coverageByKey.get(manifest.profile + ' ' + scenario) || 'unavailable';
      if (state === 'exact_shape') exact += 1;
      const entry = VOCAB.coverage.states[state];
      const params = new URLSearchParams({ left: manifest.profile, right: otherProfileWithShape(manifest.profile, scenario), scenario: scenario });
      return '<td class="grid-cell"><a class="' + COVERAGE_CLASS[state] + '" href="#compare?' + params.toString() +
        '" title="' + esc(entry[2]) + '"><span aria-hidden="true">' + entry[1] + '</span> ' +
        esc(state.replace(/_/g, ' ')) + '</a></td>';
    }).join('');
    return '<tr><th scope="row">' + esc(scenario) + '</th>' + cells + '<td class="numeric">' + exact + '</td></tr>';
  }).join('');
  const footer = '<tr><th scope="row">Exact shapes</th>' + data.manifests.map((m) =>
    '<td class="numeric">' + coverageCounts(m.profile).exact_shape + '</td>').join('') + '<td></td></tr>';
  $('coverage-grid').innerHTML = header + '<tbody>' + rows + footer + '</tbody>';
}

// -------------------------------------------------------------------- compare
function spanCell(node, card, diffs, hideScope) {
  if (!node) return '<span class="empty-side">not present</span>';
  const differing = new Set(diffs || []);
  const attr = (key, value, label) => {
    if (!value) return '';
    const cls = differing.has(key) ? ' class="attr-diff"' : '';
    return '<span' + cls + '>' + esc(label ? label + ' ' + value : value) + '</span>';
  };
  const nameClass = differing.has('name') ? 'span-name attr-diff' : 'span-name';
  return '<div class="span-line">' + (card ? '<span class="badge state-neutral">' + esc(card) + '</span>' : '') +
    '<span class="' + nameClass + '">' + esc(node.name || '(unnamed)') + '</span></div>' +
    '<div class="span-attrs">' + (hideScope ? '' : attr('scope', node.scope)) + attr('kind', node.kind) +
    attr('status', node.status, 'status') + attr('httpStatus', node.httpStatus, 'http') + '</div>';
}

function visibleDiffs(row, hideScope) {
  const diffs = row.diffs || [];
  return hideScope ? diffs.filter((d) => d !== 'scope') : diffs;
}

function visibleDifferingGroups(alignment, hideScope) {
  return alignment.traces.reduce((total, trace) => total + trace.spans.filter((row) =>
    row.kind === 'matched' && visibleDiffs(row, hideScope).length > 0).length, 0);
}

function renderAlignment(alignment, flipped, options) {
  if (!alignment || !alignment.traces.length) {
    return '<p class="muted">No traces to align.</p>';
  }
  const flipKind = (kind) => {
    if (!flipped) return kind;
    if (kind === 'left_only') return 'right_only';
    if (kind === 'right_only') return 'left_only';
    return kind;
  };
  return alignment.traces.map((trace, index) => {
    const left = flipped ? trace.right : trace.left;
    const right = flipped ? trace.left : trace.right;
    const kind = flipKind(trace.kind);
    const rows = trace.spans.filter((row) => {
      const diffs = visibleDiffs(row, options.hideScope);
      if (!options.differencesOnly) return true;
      return row.kind !== 'matched' || diffs.length > 0;
    }).map((row) => {
      const diffs = visibleDiffs(row, options.hideScope);
      const rowKind = flipKind(row.kind);
      const tone = rowKind === 'matched' ? (diffs.length ? 'row-differs' : 'row-matched') : 'row-' + rowKind;
      const flag = rowKind === 'matched'
        ? (diffs.length ? 'differs: ' + diffs.join(', ') : 'identical')
        : (rowKind === 'left_only' ? 'left only' : 'right only');
      const indent = 'padding-left:' + (10 + row.depth * 18) + 'px';
      const leftNode = flipped ? row.right : row.left;
      const rightNode = flipped ? row.left : row.right;
      const leftCard = flipped ? row.rightCard : row.leftCard;
      const rightCard = flipped ? row.leftCard : row.rightCard;
      return '<tr class="' + tone + '"><td class="diff-side" style="' + indent + '">' +
        spanCell(leftNode, leftCard, diffs, options.hideScope) + '</td>' +
        '<td class="diff-side" style="' + indent + '">' +
        spanCell(rightNode, rightCard, diffs, options.hideScope) + '</td>' +
        '<td class="row-flag">' + esc(flag) + '</td></tr>';
    }).join('');
    if (options.differencesOnly && kind === 'matched' && !rows) return '';
    const label = (left && left.label) || (right && right.label) || 'trace';
    const kindBadge = kind === 'matched'
      ? '<span class="badge state-ok"><span class="icon">✓</span>matched</span>'
      : (kind === 'left_only'
        ? '<span class="badge state-bad"><span class="icon">◀</span>left only</span>'
        : '<span class="badge state-ok"><span class="icon">▶</span>right only</span>');
    const cards = [left && left.card, right && right.card].filter(Boolean).join(' / ');
    return '<details class="trace-group" open><summary>' + kindBadge +
      '<strong>' + esc(label) + '</strong>' +
      (cards ? '<span class="badge state-neutral">' + esc(cards) + '</span>' : '') +
      '<span class="muted">trace group ' + (index + 1) + '</span></summary>' +
      '<table class="diff-table"><tbody>' + (rows || '<tr><td colspan="3" class="muted">No rows match the current filters.</td></tr>') +
      '</tbody></table></details>';
  }).join('');
}

function renderScenarioOverview(scenario) {
  const header = '<thead><tr><th>Implementation</th><th>Coverage</th><th class="numeric">Trace groups</th>' +
    '<th class="numeric">Traces</th><th class="numeric">Spans</th><th>Source</th></tr></thead>';
  const rows = data.manifests.map((manifest) => {
    const shape = shapeByKey.get(manifest.profile + ' ' + scenario);
    const state = coverageByKey.get(manifest.profile + ' ' + scenario) || 'unavailable';
    const dash = '–';
    const counts = shape
      ? [shape.traces.length, shape.exactCounts ? shape.traceCount : dash, shape.exactCounts ? shape.spanCount : dash]
      : [dash, dash, dash];
    const source = shape ? '<a href="' + esc(shape.source) + '">shape source</a>' : '<span class="muted">no checked-in shape</span>';
    return '<tr><td>' + esc(manifest.displayName) + '</td><td>' + badge('coverage', state) + '</td>' +
      counts.map((value) => '<td class="numeric">' + esc(value) + '</td>').join('') +
      '<td>' + source + '</td></tr>';
  }).join('');
  $('scenario-overview').innerHTML = header + '<tbody>' + rows + '</tbody>';
}

function renderCompare() {
  const left = $('left').value;
  const right = $('right').value;
  const scenario = $('scenario').value;
  const options = { differencesOnly: $('differences-only').checked, hideScope: $('hide-scope').checked };
  if (readHash().section === 'compare') {
    writeHash('compare', new URLSearchParams({ left: left, right: right, scenario: scenario }));
  }
  renderScenarioOverview(scenario);

  const leftShape = shapeByKey.get(left + ' ' + scenario);
  const rightShape = shapeByKey.get(right + ' ' + scenario);

  if (left === right) {
    $('compare-summary').innerHTML = '';
    $('compare-body').innerHTML = '<p class="muted">Choose two different implementations to compare.</p>';
    return;
  }
  if (!leftShape || !rightShape) {
    const parts = [];
    for (const profile of [left, right]) {
      if (shapeByKey.has(profile + ' ' + scenario)) continue;
      const state = coverageByKey.get(profile + ' ' + scenario) || 'unavailable';
      parts.push(esc(profileName(profile)) + ' is ' + esc(state.replace(/_/g, ' ')) + ' for this scenario');
    }
    const available = [leftShape, rightShape].filter(Boolean)
      .map((shape) => '<a href="' + esc(shape.source) + '">' + esc(profileName(shape.profile)) + ' shape source</a>').join(' / ');
    $('compare-summary').innerHTML = '';
    $('compare-body').innerHTML = '<p>No aligned diff: ' + parts.join(', and ') + '. A scenario shape must be ' +
      'checked in on both sides before spans can be paired.</p>' + (available ? '<p>' + available + '</p>' : '');
    return;
  }

  const found = comparisonFor(left, right, scenario);
  const comparison = found ? found.comparison : null;
  const flipped = found ? found.flipped : false;
  const alignment = comparison && comparison.alignment;
  const summary = alignment ? alignment.summary : null;
  if (summary) {
    const traceLeft = flipped ? summary.traceRightOnly : summary.traceLeftOnly;
    const traceRight = flipped ? summary.traceLeftOnly : summary.traceRightOnly;
    const spanLeft = flipped ? summary.rightOnly : summary.leftOnly;
    const spanRight = flipped ? summary.leftOnly : summary.rightOnly;
    const differing = visibleDifferingGroups(alignment, options.hideScope);
    const tiles = [
      [summary.traceMatched, 'matched trace groups'],
      [traceLeft + ' / ' + traceRight, 'trace groups only left / right'],
      [summary.matched, 'matched span groups'],
      [differing, 'matched span groups that differ'],
      [spanLeft, 'span groups only in ' + profileName(left)],
      [spanRight, 'span groups only in ' + profileName(right)],
    ];
    $('compare-summary').innerHTML = tiles.map((tile) =>
      '<div class="tile"><span class="value">' + esc(tile[0]) + '</span><span class="label">' +
      esc(tile[1]) + '</span></div>').join('');
  } else {
    $('compare-summary').innerHTML = '';
  }

  let deltas = '';
  if (comparison && comparison.available) {
    const sign = flipped ? -1 : 1;
    const signed = (value) => (sign * value > 0 ? '+' : '') + (sign * value);
    const list = (deltaMap) => Object.keys(deltaMap || {}).sort()
      .map((key) => esc(key) + ' ' + signed(deltaMap[key])).join(', ');
    const scope = list(comparison.scopeDelta);
    const status = list(comparison.statusDelta);
    deltas = '<details><summary>Raw count deltas (right minus left)</summary>' +
      '<p class="muted">traces ' + signed(comparison.traceDelta) + ' / spans ' + signed(comparison.spanDelta) +
      ' / trace groups ' + signed(comparison.countDelta) + '</p>' +
      (scope ? '<p class="muted">scopes: ' + scope + '</p>' : '') +
      (status ? '<p class="muted">statuses: ' + status + '</p>' : '') + '</details>';
  }

  const headings = '<table class="diff-table"><thead><tr><th class="diff-side">' + esc(profileLabel(left)) +
    '</th><th class="diff-side">' + esc(profileLabel(right)) + '</th><th>Row</th></tr></thead></table>';
  $('compare-body').innerHTML = deltas + headings + renderAlignment(alignment, flipped, options);
}

// ------------------------------------------------------------ feature matrix
const collapsedCategories = new Set();

function renderFeatures() {
  const category = $('category').value;
  const language = $('language').value;
  const support = $('support').value;
  const verification = $('verification').value;
  const basis = $('basis').value;
  const search = $('search').value.trim().toLowerCase();
  const verifiedOnly = $('verified-only').checked;
  if (readHash().section === 'features') {
    const params = new URLSearchParams();
    const pairs = [['category', category], ['language', language], ['support', support],
      ['verification', verification], ['basis', basis], ['q', search]];
    for (const pair of pairs) {
      if (pair[1]) params.set(pair[0], pair[1]);
    }
    if (verifiedOnly) params.set('verifiedOnly', '1');
    writeHash('features', params);
  }

  const manifests = language ? data.manifests.filter((m) => m.language === language) : data.manifests;
  const wantedVerification = verifiedOnly ? 'verified' : verification;

  const matches = data.features.filter((feature) => {
    if (category && feature.category !== category) return false;
    if (search && !(feature.name.toLowerCase().includes(search) || feature.id.toLowerCase().includes(search))) return false;
    if (support && !manifests.some((m) => (feature.support[m.language] || 'unknown') === support)) return false;
    const states = manifests.map((m) => (data.verification[feature.id] || {})[m.profile] || { state: 'not_exercised' });
    if (wantedVerification && !states.some((v) => v.state === wantedVerification)) return false;
    if (basis && !states.some((v) => v.basis === basis)) return false;
    return true;
  });

  const header = '<thead><tr><th>Feature</th><th>Upstream</th>' + manifests.map((m) => {
    const counts = verificationCounts(m.profile);
    return '<th>' + esc(m.displayName) + '<br><small>' + counts.verified + ' verified</small></th>';
  }).join('') + '</tr></thead>';

  const byCategory = new Map();
  for (const feature of matches) {
    if (!byCategory.has(feature.category)) byCategory.set(feature.category, []);
    byCategory.get(feature.category).push(feature);
  }

  let body = '';
  for (const entry of byCategory) {
    const name = entry[0];
    const features = entry[1];
    let verified = 0;
    for (const feature of features) {
      for (const manifest of manifests) {
        const state = (data.verification[feature.id] || {})[manifest.profile];
        if (state && state.state === 'verified') verified += 1;
      }
    }
    const collapsed = collapsedCategories.has(name);
    body += '<tr class="category-row"><td colspan="' + (manifests.length + 2) + '">' +
      '<button type="button" data-category="' + esc(name) + '">' + (collapsed ? '▸' : '▾') + ' ' +
      esc(name) + '</button> <span class="muted">' + features.length + ' features, ' + verified +
      ' verified cells</span></td></tr>';
    if (collapsed) continue;
    body += features.map((feature) => {
      const cells = manifests.map((manifest) => {
        const state = (data.verification[feature.id] || {})[manifest.profile] || { state: 'not_exercised', evidence: [] };
        const evidence = (state.evidence || []).map((item) =>
          '<a class="evidence" href="' + esc(item.href) + '">' + esc(item.label) + '</a>').join('');
        const basisBadge = state.basis ? ' ' + badge('basis', state.basis) : '';
        const assertion = state.assertion
          ? '<details><summary class="assertion">assertion</summary><code>' + esc(state.assertion) + '</code>' +
            (state.scenarios && state.scenarios.length ? '<div class="assertion">' + esc(state.scenarios.join(', ')) + '</div>' : '') +
            '</details>'
          : '';
        return '<td>' + badge('verification', state.state) + basisBadge + assertion + evidence + '</td>';
      }).join('');
      const seen = [];
      for (const manifest of manifests) {
        if (!seen.includes(manifest.language)) seen.push(manifest.language);
      }
      const upstream = seen.map((lang) =>
        '<div>' + esc(lang) + ' ' + badge('support', feature.support[lang] || 'unknown') + '</div>').join('');
      return '<tr><td><strong>' + esc(feature.name) + '</strong>' +
        (feature.group ? '<div class="muted">' + esc(feature.group) + '</div>' : '') +
        '<a class="evidence" href="' + esc(feature.source) + '">' + esc(feature.id) + '</a></td>' +
        '<td>' + upstream + '</td>' + cells + '</tr>';
    }).join('');
  }
  if (!matches.length) {
    body = '<tr><td colspan="' + (manifests.length + 2) + '" class="muted">No feature matches these filters.</td></tr>';
  }
  $('feature-matrix').innerHTML = header + '<tbody>' + body + '</tbody>';
  for (const button of $('feature-matrix').querySelectorAll('button[data-category]')) {
    button.addEventListener('click', () => {
      const name = button.getAttribute('data-category');
      if (collapsedCategories.has(name)) collapsedCategories.delete(name); else collapsedCategories.add(name);
      renderFeatures();
    });
  }
}

// ------------------------------------------------------------------ receipts
function renderReceipts() {
  const receipts = data.receipts || [];
  const header = '<thead><tr><th>Implementation</th><th>Scenario</th><th>Outcome</th><th>Mode</th>' +
    '<th>Proofs</th><th>Capture SHA-256</th></tr></thead>';
  const rows = receipts.map((receipt) => {
    const manifest = manifestByProfile.get(receipt.profile);
    const other = otherProfileWithShape(receipt.profile, receipt.scenario);
    const params = new URLSearchParams({ left: receipt.profile, right: other, scenario: receipt.scenario });
    const proofs = (receipt.proofs || []).map((proof) =>
      '<li>' + esc(proof.featureId) + ' <code>' + esc(proof.assertion) + '</code> ' +
      badge('basis', proof.basis) + ' <span class="muted">' + esc(proof.result) + '</span></li>').join('');
    return '<tr><td>' + esc(manifest ? manifest.displayName : receipt.profile) +
      '<div class="muted">' + esc(manifest ? (manifest.shortLabel || '') : '') + '</div></td>' +
      '<td><a href="#compare?' + params.toString() + '">' + esc(receipt.scenario) + '</a></td>' +
      '<td>' + badge('receipt', receipt.outcome) +
      (receipt.xfailReason ? '<div class="muted">' + esc(receipt.xfailReason) + '</div>' : '') + '</td>' +
      '<td>' + badge('coverage', receipt.validationMode === 'exact' ? 'exact_shape' : 'contract_only') + '</td>' +
      '<td>' + ((receipt.proofs || []).length
        ? '<details><summary>' + (receipt.proofs || []).length + ' proofs</summary><ul>' + proofs + '</ul></details>'
        : '<span class="muted">0</span>') + '</td>' +
      '<td><code title="' + esc(receipt.captureSha256) + '">' + esc(String(receipt.captureSha256).slice(0, 16)) + '…</code> ' +
      '<button type="button" class="copy" data-sha="' + esc(receipt.captureSha256) + '">copy</button></td></tr>';
  }).join('');
  $('receipts-table').innerHTML = header + '<tbody>' +
    (rows || '<tr><td colspan="6" class="muted">No receipts were collected for this build.</td></tr>') + '</tbody>';
  for (const button of $('receipts-table').querySelectorAll('button.copy')) {
    button.addEventListener('click', () => {
      const value = button.getAttribute('data-sha');
      if (navigator.clipboard) navigator.clipboard.writeText(value);
      button.textContent = 'copied';
      setTimeout(() => { button.textContent = 'copy'; }, 1500);
    });
  }
}

// ------------------------------------------------------------------ glossary
function renderGlossary() {
  const sections = Object.keys(VOCAB).map((name) => {
    const vocabulary = VOCAB[name];
    const items = Object.keys(vocabulary.states).map((state) =>
      '<dt>' + badge(name, state) + '</dt><dd>' + esc(vocabulary.states[state][2]) + '</dd>').join('');
    return '<div><h3>' + esc(vocabulary.title) + '</h3><p class="muted">' + esc(vocabulary.question) + '</p>' +
      '<dl>' + items + '</dl></div>';
  }).join('');
  const trust = '<div><h3>The trust rule</h3><p class="muted">A feature reaches <em>verified</em> only when a ' +
    'receipt from the current repository revision matches the assembled proof plan, capture, and scenario ' +
    'shape digests. Manifests cannot declare a feature verified by hand, and an expected failure never ' +
    'produces one.</p>' +
    '<h3>Not exercised in this build</h3><p class="muted">Every language stays in this report even when its ' +
    'container images are unpublished, so the matrix never silently drops an implementation. Such a profile ' +
    'contributes no receipts: its checked-in shapes stay comparable and its upstream claims stay visible, ' +
    'but a proof plan alone proves nothing, so none of its features can reach verified.</p></div>';
  $('glossary-body').innerHTML = sections + trust;
}

// ---------------------------------------------------------------- bootstrap
// syncControlsFromHash copies deep-link parameters into the form controls
// without rendering, so bootstrap can seed the controls before the first paint
// and never overwrite an incoming link with the defaults.
function syncControlsFromHash() {
  const state = readHash();
  markNav(state.section);
  const params = state.params;
  if (state.section === 'compare') {
    if (params.get('left') && manifestByProfile.has(params.get('left'))) $('left').value = params.get('left');
    if (params.get('right') && manifestByProfile.has(params.get('right'))) $('right').value = params.get('right');
    if (params.get('scenario') && data.scenarios.includes(params.get('scenario'))) $('scenario').value = params.get('scenario');
  } else if (state.section === 'features') {
    const pairs = [['category', 'category'], ['language', 'language'], ['support', 'support'],
      ['verification', 'verification'], ['basis', 'basis']];
    for (const pair of pairs) {
      if (params.get(pair[0]) !== null) $(pair[1]).value = params.get(pair[0]);
    }
    if (params.get('q') !== null) $('search').value = params.get('q');
    $('verified-only').checked = params.get('verifiedOnly') === '1';
  }
  return state.section;
}

function applyHash() {
  const section = syncControlsFromHash();
  if (section === 'compare') renderCompare();
  else if (section === 'features') renderFeatures();
}

function setup() {
  const options = data.manifests.map((m) =>
    '<option value="' + esc(m.profile) + '">' + esc(m.displayName) + (m.shortLabel ? ' — ' + esc(m.shortLabel) : '') +
    (m.unexercised ? ' (not exercised)' : '') + '</option>').join('');
  $('left').innerHTML = options;
  $('right').innerHTML = options;
  $('left').value = data.manifests[0].profile;
  $('right').value = (data.manifests[1] || data.manifests[0]).profile;
  $('scenario').innerHTML = data.scenarios.map((scenario) => {
    const states = data.manifests.map((m) => coverageByKey.get(m.profile + ' ' + scenario) || 'unavailable');
    const exact = states.filter((s) => s === 'exact_shape').length;
    return '<option value="' + esc(scenario) + '">' + esc(scenario) + ' — ' + exact + ' exact of ' +
      data.manifests.length + '</option>';
  }).join('');

  const categories = [];
  for (const feature of data.features) {
    if (!categories.includes(feature.category)) categories.push(feature.category);
  }
  $('category').insertAdjacentHTML('beforeend', categories.map((v) => '<option>' + esc(v) + '</option>').join(''));

  for (const id of ['left', 'right', 'scenario', 'differences-only', 'hide-scope']) {
    $(id).addEventListener('change', renderCompare);
  }
  $('swap').addEventListener('click', () => {
    const left = $('left').value;
    $('left').value = $('right').value;
    $('right').value = left;
    renderCompare();
  });
  for (const id of ['category', 'language', 'support', 'verification', 'basis', 'verified-only']) {
    $(id).addEventListener('change', renderFeatures);
  }
  $('search').addEventListener('input', renderFeatures);
  window.addEventListener('hashchange', applyHash);

  renderOverview();
  renderCoverageGrid();
  renderGlossary();
  renderReceipts();
  syncControlsFromHash();
  renderFeatures();
  renderCompare();
}

setup();
