'use strict';
// The report is a single static page: all state lives in the URL hash so any
// view can be linked to from another view or shared as-is.
const data = JSON.parse(document.getElementById('report-data').textContent);
for (const key of ['manifests', 'shapes', 'coverage', 'comparisons', 'features', 'scenarios']) data[key] = data[key] || [];
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
    title: 'Instrumentation status',
    question: 'What did this repository’s end-to-end suite actually assert?',
    states: {
      verified: ['ok', '✓', 'The listed assertion passed with accepted evidence from this build.'],
      known_gap: ['bad', '✕', 'The report explicitly records an implementation gap.'],
      not_exercised: ['neutral', '?', 'This report has no accepted proof for the feature.'],
      not_applicable: ['neutral', '–', 'The profile explicitly marks the feature as inapplicable.'],
    },
  },
  coverage: {
    title: 'Scenario coverage',
    question: 'Which telemetry checks are defined for this scenario?',
    states: {
      exact_shape: ['neutral', '■', 'A saved expectation specifies the trace and span structure; it does not establish a passing run.'],
      contract_only: ['neutral', '▣', 'Shared capture checks are defined; a scenario trace structure is not specified.'],
      unavailable: ['neutral', '○', 'No telemetry checks are defined for this declared scenario.'],
      excluded: ['neutral', '–', 'The profile does not declare this scenario; it does not count as missing tests.'],
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
      xfail: ['neutral', '○', 'The run failed as expected; it is recorded but proves nothing.'],
      missing: ['neutral', '?', 'No accepted receipt records a result for this build.'],
    },
  },
};

const LABELS = {
  verification: { verified: 'Verified here', known_gap: 'Documented gap', not_exercised: 'Unknown', not_applicable: 'Not applicable' },
  coverage: { exact_shape: 'Trace structure specified', contract_only: 'Shared telemetry checks only', unavailable: 'No telemetry checks defined', excluded: 'Not in this test suite' },
  receipt: { verified: 'Passed', xfail: 'Expected failure', missing: 'No result for this build' },
};
function stateLabel(vocabulary, state) {
  return (LABELS[vocabulary] || {})[state] || String(state || '-').replace(/_/g, ' ');
}
function badge(vocabulary, state) {
  const group = VOCAB[vocabulary];
  const entry = (group && group.states[state]) || ['neutral', '–', ''];
  const label = stateLabel(vocabulary, state);
  return '<span class="badge state-' + entry[0] + '" title="' + esc(group.title + ': ' + entry[2]) +
    '"><span class="icon" aria-hidden="true">' + entry[1] + '</span>' + esc(label) + '</span>';
}

// ------------------------------------------------------------------ indexing
const manifestByProfile = new Map(data.manifests.map((m) => [m.profile, m]));
const shapeByKey = new Map(data.shapes.map((s) => [s.profile + ' ' + s.scenario, s]));
const coverageByKey = new Map(data.coverage.map((c) => [c.profile + ' ' + c.scenario, c]));
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
function writeHash(section, params, replace = false) {
  const query = params && params.toString();
  const next = '#' + section + (query ? '?' + query : '');
  if (location.hash !== next) {
    history[replace ? 'replaceState' : 'pushState'](null, '', next);
    updateNavigation(section);
  }
}
const defaultProfile = (data.manifests.find((m) => (data.receipts || []).some((r) =>
  r.profile === m.profile && r.outcome === 'verified')) || data.manifests[0] || {}).profile || '';
let selectedProfile = defaultProfile;
function updateNavigation(section) {
  for (const link of document.querySelectorAll('nav.top a')) {
    const destination = link.hash.split('?')[0].slice(1);
    if (destination === section) link.setAttribute('aria-current', 'page');
    else link.removeAttribute('aria-current');
    if (destination === 'overview' || destination === 'coverage') {
      link.hash = destination + '?' + new URLSearchParams({ profile: selectedProfile });
    }
  }
}
function verificationFor(feature, profile) {
  return (data.verification[feature.id] || {})[profile] || { state: 'not_exercised', evidence: [] };
}
function verificationCounts(profile, features = data.features) {
  const counts = { verified: 0, known_gap: 0, not_exercised: 0, not_applicable: 0 };
  for (const feature of features) counts[verificationFor(feature, profile).state] += 1;
  return counts;
}
function coverageState(profile, scenario) {
  const cell = coverageByKey.get(profile + ' ' + scenario);
  return cell && cell.declared ? cell.state : 'excluded';
}
function receiptFor(profile, scenario) {
  return (data.receipts || []).find((r) => r.profile === profile && r.scenario === scenario);
}
function categoryNames() {
  const priority = ['Traces', 'Metrics', 'Logs'];
  return [...new Set(data.features.map((f) => f.category))].sort((a, b) => {
    const rank = (name) => priority.includes(name) ? priority.indexOf(name) : priority.length;
    return rank(a) - rank(b) || a.localeCompare(b);
  });
}
function statusLink(state, category) {
  const params = new URLSearchParams({ profile: selectedProfile, verification: state });
  if (category) params.set('category', category);
  return '#overview?' + params;
}
function featureDetails(feature, state) {
  const evidence = (state.evidence || []).map((item) =>
    '<a class="evidence" href="' + esc(item.href) + '">' + esc(item.label) + '</a>').join('');
  return '<details><summary>Assertion and evidence</summary>' +
    '<p>' + esc(VOCAB.verification.states[state.state][2]) + '</p>' +
    (state.assertion ? '<code>' + esc(state.assertion) + '</code>' : '') +
    (state.basis ? '<p>' + badge('basis', state.basis) + '</p>' : '') +
    (state.scenarios && state.scenarios.length ? '<p>Scenarios: ' + esc(state.scenarios.join(', ')) + '</p>' : '') +
    evidence + '<a class="evidence" href="' + esc(feature.source) + '">Catalog: ' + esc(feature.id) + '</a></details>';
}
function renderOverview() {
  const manifest = manifestByProfile.get(selectedProfile);
  if (!manifest) return;
  const counts = verificationCounts(selectedProfile);
  const receipts = (data.receipts || []).filter((r) => r.profile === selectedProfile);
  $('profile-status').textContent = receipts.some((r) => r.outcome === 'verified')
    ? 'Accepted passing receipts are available for this implementation.'
    : receipts.length ? 'Only expected failures were recorded. This implementation remains unverified.'
      : 'No results for this build. This implementation remains unverified; saved expectations do not prove a run passed.';
  $('status-counts').innerHTML = ['verified', 'known_gap', 'not_exercised'].map((state) =>
    '<a class="tile" href="' + esc(statusLink(state)) + '"><span class="value">' + counts[state] +
    '</span><span class="label">' + (state === 'known_gap' ? 'Documented gaps' : stateLabel('verification', state)) +
    '</span><span class="definition">' + esc(VOCAB.verification.states[state][2]) + '</span></a>').join('');
  $('gap-summary').textContent = (counts.known_gap === 0 ? 'No implementation gaps recorded. ' : counts.known_gap + ' documented gaps. ') +
    counts.not_exercised + ' unknown features. The current assembler does not populate documented gaps.';
  $('not-applicable').innerHTML = '<a href="' + esc(statusLink('not_applicable')) + '">' + counts.not_applicable +
    ' Not applicable</a> — The profile explicitly marks these features as inapplicable.';
  const params = readHash().params;
  const filter = params.get('verification');
  const category = params.get('category');
  $('capabilities').innerHTML = categoryNames().map((name) => {
    const features = data.features.filter((f) => f.category === name);
    const totals = verificationCounts(selectedProfile, features);
    const reveal = filter && (!category || category === name);
    const shown = features.filter((f) => !filter || verificationFor(f, selectedProfile).state === filter);
    const summary = ['verified', 'known_gap', 'not_exercised'].map((state) => totals[state] + ' ' +
      (state === 'known_gap' ? 'documented gaps' : stateLabel('verification', state).toLowerCase())).join(' · ');
    return '<details class="capability-category"' + (reveal && shown.length ? ' open' : '') + '><summary><strong>' +
      esc(name) + '</strong><span class="category-counts">' + summary + ' · ' + totals.not_applicable + ' not applicable</span></summary>' +
      (filter ? '<p>' + esc(stateLabel('verification', filter)) + ' features · <a href="#overview?' +
        new URLSearchParams({ profile: selectedProfile }) + '">Show all statuses</a></p>' : '') +
      (shown.length ? '<ul class="feature-list">' + shown.map((feature) => {
        const state = verificationFor(feature, selectedProfile);
        return '<li><div><strong>' + esc(feature.name) + '</strong> ' + badge('verification', state.state) + '</div>' +
          (feature.group ? '<div class="muted">' + esc(feature.group) + '</div>' : '') + featureDetails(feature, state) + '</li>';
      }).join('') + '</ul>' : '<p>No features with this status in this category.</p>') + '</details>';
  }).join('');
  $('implementation-details').innerHTML = '<p>' + esc(manifest.shortLabel || manifest.displayName) + ' · ' +
    esc(manifest.version || manifest.instrumentationVersion) + '</p>' + (manifest.profileEvidence || []).map((item) =>
      '<a class="evidence" href="' + esc(item.href) + '">' + esc(item.label) + '</a>').join('');
}

// ------------------------------------------------------------- test coverage
function otherProfileWithShape(profile, scenario) {
  for (const manifest of data.manifests) {
    if (manifest.profile !== profile && shapeByKey.has(manifest.profile + ' ' + scenario)) return manifest.profile;
  }
  const fallback = data.manifests.find((m) => m.profile !== profile);
  return fallback ? fallback.profile : profile;
}

function renderCoverageGrid() {
  const declared = data.coverage.filter((c) => c.profile === selectedProfile && c.declared);
  $('coverage-summary').textContent = declared.length + ' scenarios in this test suite; ' +
    declared.filter((c) => c.state === 'unavailable').length + ' have no telemetry checks defined. ' +
    (data.scenarios.length - declared.length) + ' scenarios are outside this suite.';
  $('coverage-grid').innerHTML = '<thead><tr><th>Scenario</th><th>Checks defined</th><th>Result in this build</th></tr></thead><tbody>' +
    data.scenarios.map((scenario) => {
      const state = coverageState(selectedProfile, scenario);
      const receipt = receiptFor(selectedProfile, scenario);
      const params = new URLSearchParams({ left: selectedProfile, right: otherProfileWithShape(selectedProfile, scenario), scenario });
      return '<tr><th scope="row">' + esc(scenario) + '</th><td>' + badge('coverage', state) +
        (state === 'exact_shape' ? '<a class="evidence" href="#compare?' + params + '">Compare saved trace expectations</a>' : '') +
        '</td><td>' + (state === 'excluded' ? 'Not in this test suite' : badge('receipt', receipt ? receipt.outcome : 'missing')) +
        (receipt && receipt.xfailReason ? '<div class="muted">' + esc(receipt.xfailReason) + '</div>' : '') + '</td></tr>';
    }).join('') + '</tbody>';
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

// Alignment rows are a pre-order traversal. Keep every differing/one-sided row
// together with its ancestor chain so indentation never loses its tree context.
function differenceRows(rows, hideScope) {
  const keep = new Set();
  const ancestors = [];
  rows.forEach((row, index) => {
    ancestors.length = row.depth;
    if (row.kind !== 'matched' || visibleDiffs(row, hideScope).length > 0) {
      for (const ancestor of ancestors) keep.add(ancestor);
      keep.add(index);
    }
    ancestors[row.depth] = index;
  });
  return rows.filter((_, index) => keep.has(index));
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
    const visibleRows = options.differencesOnly
      ? differenceRows(trace.spans, options.hideScope)
      : trace.spans;
    const rows = visibleRows.map((row) => {
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
    const traceCardDiffers = kind === 'matched' && left && right && left.card !== right.card;
    const traceCoverageDiffers = kind === 'matched' && left && right && left.coverage !== right.coverage;
    if (options.differencesOnly && kind === 'matched' && !rows && !traceCardDiffers && !traceCoverageDiffers) return '';
    const label = (left && left.label) || (right && right.label) || 'trace';
    const kindBadge = kind === 'matched'
      ? '<span class="badge state-neutral"><span class="icon">↔</span>matched</span>'
      : (kind === 'left_only'
        ? '<span class="badge state-neutral"><span class="icon">◀</span>left only</span>'
        : '<span class="badge state-neutral"><span class="icon">▶</span>right only</span>');
    const cards = traceCardDiffers
      ? (left.card || '×1') + ' / ' + (right.card || '×1')
      : [left && left.card, right && right.card].filter(Boolean).join(' / ');
    const coverage = [left && left.coverage, right && right.coverage].filter(Boolean).join(' / ');
    return '<details class="trace-group"><summary>' + kindBadge +
      '<strong>' + esc(label) + '</strong>' +
      (cards ? '<span class="badge state-neutral">' + esc(cards) + '</span>' : '') +
      (coverage ? '<span class="badge ' + (traceCoverageDiffers ? 'state-warn' : 'state-neutral') + '">coverage: ' + esc(coverage) + '</span>' : '') +
      '<span class="muted">trace group ' + (index + 1) + '</span></summary>' +
      '<table class="diff-table"><tbody>' + (rows || '<tr><td colspan="3" class="muted">' +
        (traceCardDiffers ? 'Trace cardinality differs.' : (traceCoverageDiffers ? 'Trace coverage differs.' : 'No rows match the current filters.')) + '</td></tr>') +
      '</tbody></table></details>';
  }).join('');
}

function renderScenarioOverview(scenario) {
  const header = '<thead><tr><th>Implementation</th><th>Checks defined</th><th class="numeric">Trace groups</th>' +
    '<th class="numeric">Traces</th><th class="numeric">Spans</th><th>Source</th></tr></thead>';
  const rows = data.manifests.map((manifest) => {
    const shape = shapeByKey.get(manifest.profile + ' ' + scenario);
    const state = coverageState(manifest.profile, scenario);
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
      const state = coverageState(profile, scenario);
      parts.push(esc(profileName(profile)) + ' is ' + esc(stateLabel('coverage', state)) + ' for this scenario');
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
      (scope && !options.hideScope ? '<p class="muted">scopes: ' + scope + '</p>' : '') +
      (status ? '<p class="muted">statuses: ' + status + '</p>' : '') + '</details>';
  }

  const headings = '<table class="diff-table"><thead><tr><th class="diff-side">' + esc(profileLabel(left)) +
    '</th><th class="diff-side">' + esc(profileLabel(right)) + '</th><th>Row</th></tr></thead></table>';
  $('compare-body').innerHTML = deltas + headings + renderAlignment(alignment, flipped, options);
}

// ------------------------------------------------------------ feature matrix
const collapsedCategories = new Set(categoryNames());

function renderFeatures() {
  const category = $('category').value;
  const language = $('language').value;
  const support = $('support').value;
  const verification = $('verification').value;
  const basis = $('basis').value;
  const search = $('search').value.trim().toLowerCase();
  const profile = $('feature-profile').value;
  const manifests = data.manifests.filter((m) => (!language || m.language === language) && (!profile || m.profile === profile));
  const upstreamLanguages = language ? [language] : [...new Set(manifests.map((m) => m.language))];

  const matches = data.features.filter((feature) => {
    if (category && feature.category !== category) return false;
    if (search && !(feature.name.toLowerCase().includes(search) || feature.id.toLowerCase().includes(search))) return false;
    if (support && !upstreamLanguages.some((lang) => ((feature.support || {})[lang] || 'unknown') === support)) return false;
    const states = manifests.map((m) => (data.verification[feature.id] || {})[m.profile] || { state: 'not_exercised' });
    if ((verification || basis) && !states.some((v) =>
      (!verification || v.state === verification) && (!basis || v.basis === basis))) return false;
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
      '<button type="button" aria-expanded="' + !collapsed + '" data-category="' + esc(name) + '">' + (collapsed ? '▸' : '▾') + ' ' +
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
      const upstream = upstreamLanguages.map((lang) =>
        '<div>' + esc(lang) + ' ' + badge('support', (feature.support || {})[lang] || 'unknown') + '</div>').join('');
      const optionality = feature.optional === 'X'
        ? '<span class="badge state-neutral" title="Optional in the upstream specification">optional</span>'
        : (feature.optional === '*'
          ? '<span class="badge state-neutral" title="At least one supported exporter format is required; additional formats are optional">one format required</span>'
          : (feature.optional
            ? '<span class="badge state-neutral" title="Upstream optionality">' + esc(feature.optional) + '</span>'
            : ''));
      return '<tr><td><strong>' + esc(feature.name) + '</strong>' +
        (feature.group ? '<div class="muted">' + esc(feature.group) + '</div>' : '') +
        (optionality ? '<div>' + optionality + '</div>' : '') +
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
      [...$('feature-matrix').querySelectorAll('button[data-category]')].find((b) => b.dataset.category === name).focus();
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
    button.addEventListener('click', async () => {
      const value = button.getAttribute('data-sha');
      try {
        if (!navigator.clipboard || !navigator.clipboard.writeText) throw new Error('Clipboard unavailable');
        await navigator.clipboard.writeText(value);
        button.textContent = 'copied';
      } catch (_) {
        button.textContent = 'copy failed';
      }
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

// ---------------------------------------------------------------- routing
const VIEWS = ['overview', 'coverage', 'compare', 'features', 'receipts', 'glossary'];
function syncControlsFromHash() {
  const state = readHash();
  const params = state.params;
  // Retain direct table anchors as well as the six view routes.
  const target = $(state.section);
  const parent = target && target.closest('section.panel');
  const section = VIEWS.includes(state.section) ? state.section : parent ? parent.id : 'overview';
  if (manifestByProfile.has(params.get('profile'))) selectedProfile = params.get('profile');
  else if (section === 'overview' || section === 'coverage') selectedProfile = defaultProfile;
  $('profile').value = selectedProfile;
  $('coverage-profile').value = selectedProfile;
  if (section === 'compare') {
    $('left').value = manifestByProfile.has(params.get('left')) ? params.get('left') : (data.manifests[0] || {}).profile || '';
    $('right').value = manifestByProfile.has(params.get('right')) ? params.get('right') : (data.manifests[1] || data.manifests[0] || {}).profile || '';
    $('scenario').value = data.scenarios.includes(params.get('scenario')) ? params.get('scenario') : data.scenarios[0] || '';
    $('differences-only').checked = params.get('differencesOnly') === '1';
    $('hide-scope').checked = params.get('hideScope') === '1';
  } else if (section === 'features') {
    for (const id of ['category', 'language', 'support', 'verification', 'basis']) $(id).value = params.get(id) || '';
    $('feature-profile').value = manifestByProfile.has(params.get('profile')) ? params.get('profile') : '';
    $('search').value = params.get('q') || '';
    if (params.get('verifiedOnly') === '1') $('verification').value = 'verified';
    $('verified-only').checked = $('verification').value === 'verified';
    // A filtered legacy link must reveal its matches even after manual collapse.
    if (params.toString()) collapsedCategories.clear();
  }
  updateNavigation(section);
  return section;
}
function applyHash(focus = true) {
  const section = syncControlsFromHash();
  for (const id of VIEWS) $(id).hidden = id !== section;
  if (section === 'overview') renderOverview();
  else if (section === 'coverage') renderCoverageGrid();
  else if (section === 'compare') renderCompare();
  else if (section === 'features') renderFeatures();
  const target = $(readHash().section);
  if (target && target.id !== section) {
    for (let parent = target.parentElement; parent; parent = parent.parentElement) {
      if (parent.tagName === 'DETAILS') parent.open = true;
    }
    target.scrollIntoView();
  } else if (focus) {
    $(section).querySelector('h2').focus({ preventScroll: true });
  }
}
function compareChanged() {
  const params = new URLSearchParams({ left: $('left').value, right: $('right').value, scenario: $('scenario').value });
  if ($('differences-only').checked) params.set('differencesOnly', '1');
  if ($('hide-scope').checked) params.set('hideScope', '1');
  writeHash('compare', params);
  renderCompare();
}
function featuresChanged(replace = false) {
  const params = new URLSearchParams();
  for (const [key, id] of [['profile', 'feature-profile'], ['category', 'category'], ['language', 'language'],
    ['support', 'support'], ['verification', 'verification'], ['basis', 'basis'], ['q', 'search']]) {
    if ($(id).value) params.set(key, $(id).value);
  }
  if ($('feature-profile').value) selectedProfile = $('feature-profile').value;
  writeHash('features', params, replace);
  if (params.toString()) collapsedCategories.clear();
  renderFeatures();
}
function setup() {
  const options = data.manifests.map((m) => '<option value="' + esc(m.profile) + '">' +
    esc(m.displayName) + (m.shortLabel ? ' — ' + esc(m.shortLabel) : '') + '</option>').join('');
  for (const id of ['profile', 'coverage-profile', 'left', 'right']) $(id).innerHTML = options;
  $('feature-profile').insertAdjacentHTML('beforeend', options);
  $('scenario').innerHTML = data.scenarios.map((scenario) => '<option>' + esc(scenario) + '</option>').join('');
  $('category').insertAdjacentHTML('beforeend', categoryNames().map((name) => '<option>' + esc(name) + '</option>').join(''));
  for (const id of ['profile', 'coverage-profile']) $(id).addEventListener('change', () => {
    selectedProfile = $(id).value;
    const params = readHash().params;
    params.set('profile', selectedProfile);
    writeHash(id === 'profile' ? 'overview' : 'coverage', params);
    applyHash(false);
  });
  for (const id of ['left', 'right', 'scenario', 'differences-only', 'hide-scope']) $(id).addEventListener('change', compareChanged);
  $('swap').addEventListener('click', () => {
    const left = $('left').value;
    $('left').value = $('right').value;
    $('right').value = left;
    compareChanged();
  });
  for (const id of ['feature-profile', 'category', 'language', 'support', 'basis']) $(id).addEventListener('change', () => featuresChanged());
  $('verification').addEventListener('change', () => {
    $('verified-only').checked = $('verification').value === 'verified';
    featuresChanged();
  });
  $('verified-only').addEventListener('change', () => {
    $('verification').value = $('verified-only').checked ? 'verified' : '';
    featuresChanged();
  });
  $('search').addEventListener('input', () => featuresChanged(true));
  window.addEventListener('hashchange', () => applyHash());
  const source = data.metadata.source;
  $('meta').innerHTML = '<a href="' + esc(source.url) + '">Catalog revision ' + esc(source.revision) + '</a>' +
    '<a href="' + esc(data.metadata.maturitySource) + '">Language maturity source</a>';
  $('maturity').innerHTML = '<thead><tr><th>Language</th><th>Traces</th><th>Metrics</th><th>Logs</th></tr></thead><tbody>' +
    Object.keys(data.metadata.maturity).sort().map((language) => {
      const m = data.metadata.maturity[language];
      return '<tr><th scope="row">' + esc(language) + '</th><td>' + esc(m.traces) + '</td><td>' + esc(m.metrics) + '</td><td>' + esc(m.logs) + '</td></tr>';
    }).join('') + '</tbody>';
  renderGlossary();
  renderReceipts();
  applyHash(false);
}
setup();
