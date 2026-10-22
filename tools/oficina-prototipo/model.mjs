// Oficina das Almas · protótipo de regras (PIP-58). Funções puras, sem DOM.
// No jogo real estas regras rodam no servidor; o cliente só envia as ações da bancada.

export const RULES_VERSION = 'oficina-proto-2';

// Molde do Rabbito (tradicional): vela com duas orelhas. Coordenadas da bancada (0..600 × 0..440).
export const MOLDS = {
  'rabbito-tradicional': {
    id: 'rabbito-tradicional', species: 'Rabbito', name: 'Tradicional', rarity: 'comum',
    outline: [[300, 70], [318, 20], [338, 18], [340, 92], [430, 200], [300, 380], [170, 200], [260, 92], [262, 18], [282, 20]],
    // Abas de colagem ao longo das varetas; articulações das orelhas não levam cola.
    tabs: [[292, 96, 16, 270], [190, 192, 220, 16]],
    joints: [[252, 58, 32, 30], [316, 58, 32, 30]],
    frame: {x: 300, y: 214, angle: 0},
    recipe: {papel: 2, vareta: 2, cola: 1},
    balance: {ideal: .38, spread: .22}
  },
  'rabbito-vela-leve': {
    id: 'rabbito-vela-leve', species: 'Rabbito', name: 'Vela leve', rarity: 'raro',
    outline: [[300, 64], [316, 14], [334, 14], [338, 88], [446, 196], [300, 392], [154, 196], [262, 88], [266, 14], [284, 14]],
    tabs: [[293, 92, 14, 286], [178, 189, 244, 14]],
    joints: [[254, 52, 32, 30], [314, 52, 32, 30]],
    frame: {x: 300, y: 216, angle: 0},
    recipe: {papel: 3, vareta: 2, cola: 1, fioEncerado: 1},
    balance: {ideal: .32, spread: .16}
  }
};

// Teto total de bônus (fração) por raridade do molde. Nível 50 dá +20% de linha; classe rank 3 dá até +24% de velocidade.
export const BUDGET = {comum: .04, raro: .06, epico: .08};
// Cada dimensão alimenta um atributo existente do combate (src/engine.js).
// v2: revelação (o corte da peça) e reparo dos materiais substituem corte e colagem do v1.
export const DIMENSIONS = {revelacao: 'speed', reparo: 'line', equilibrio: 'regen', elo: 'energy'};
// Falha só por dano estrutural: cortes para dentro da peça e cola nas articulações somam dano.
export const INTEGRITY = {max: 100, cutInsidePerPx: .9, glueOnJointPerCell: 2.5, insideTolerance: 6};
// Proposta: 1 em 256 no primeiro despertar bem-sucedido. Configurável; desligada até aprovação.
export const VARIANT_CHANCE = 1 / 256;

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

export function pointInPolygon([x, y], poly) {
  let inside = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const [xi, yi] = poly[i], [xj, yj] = poly[j];
    if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

function segmentDistance([px, py], [ax, ay], [bx, by]) {
  const dx = bx - ax, dy = by - ay, t = clamp(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy || 1), 0, 1);
  return Math.hypot(px - (ax + t * dx), py - (ay + t * dy));
}

// Distância com sinal até o contorno: negativa dentro da peça.
export function outlineDistance(p, poly) {
  let d = Infinity;
  for (let i = 0; i < poly.length; i++) d = Math.min(d, segmentDistance(p, poly[i], poly[(i + 1) % poly.length]));
  return pointInPolygon(p, poly) ? -d : d;
}

// Pontos igualmente espaçados ao longo do contorno, para medir cobertura do corte.
export function outlineSamples(poly, step = 8) {
  const out = [];
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i], b = poly[(i + 1) % poly.length], n = Math.max(1, Math.round(Math.hypot(b[0] - a[0], b[1] - a[1]) / step));
    for (let k = 0; k < n; k++) out.push([a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n]);
  }
  return out;
}

// Corte: cobertura do contorno, precisão média e dano por cortar para dentro.
export function scoreCut(mold, path, reach = 12) {
  const samples = outlineSamples(mold.outline);
  let covered = 0, errorSum = 0, near = 0, damage = 0;
  for (const s of samples) if (path.some(p => Math.hypot(p[0] - s[0], p[1] - s[1]) <= reach)) covered++;
  for (const p of path) {
    const d = outlineDistance(p, mold.outline);
    if (Math.abs(d) <= 30) { errorSum += Math.abs(d); near++; }
    if (d < -INTEGRITY.insideTolerance) damage += (-d - INTEGRITY.insideTolerance) * INTEGRITY.cutInsidePerPx / 10;
  }
  const coverage = covered / samples.length, meanError = near ? errorSum / near : 30;
  const score = Math.round(100 * clamp(coverage, 0, 1) * clamp(1 - (meanError - 2) / 14, 0, 1));
  return {coverage, meanError, damage, score, complete: coverage >= .9};
}

// Cola: grade de células pintadas (chave "x,y" de 8 px). Cobertura das abas, excesso fora delas e cola nas articulações.
export const GLUE_CELL = 8;
const inRect = ([x, y], [rx, ry, rw, rh]) => x >= rx && x < rx + rw && y >= ry && y < ry + rh;
export function scoreGlue(mold, cells) {
  let tabCells = 0, tabHit = 0, excess = 0, jointHit = 0;
  for (const r of mold.tabs) for (let x = r[0]; x < r[0] + r[2]; x += GLUE_CELL) for (let y = r[1]; y < r[1] + r[3]; y += GLUE_CELL) {
    tabCells++;
    if (cells.has(Math.floor(x / GLUE_CELL) + ',' + Math.floor(y / GLUE_CELL))) tabHit++;
  }
  for (const key of cells) {
    const [cx, cy] = key.split(',').map(Number), c = [cx * GLUE_CELL + GLUE_CELL / 2, cy * GLUE_CELL + GLUE_CELL / 2];
    if (mold.joints.some(j => inRect(c, j))) jointHit++;
    else if (!mold.tabs.some(t => inRect(c, [t[0] - GLUE_CELL, t[1] - GLUE_CELL, t[2] + 2 * GLUE_CELL, t[3] + 2 * GLUE_CELL]))) excess++;
  }
  const coverage = tabHit / tabCells, waste = excess / Math.max(1, tabCells);
  const score = Math.round(100 * clamp(coverage, 0, 1) * clamp(1 - waste * 1.5, 0, 1));
  return {coverage, waste, jointHit, damage: jointHit * INTEGRITY.glueOnJointPerCell, score, complete: coverage >= .6};
}

// Montagem com a pinça: erro de posição e de ângulo da vela sobre a armação.
export function scoreAssembly(mold, placed) {
  const dist = Math.hypot(placed.x - mold.frame.x, placed.y - mold.frame.y), angle = Math.abs(((placed.angle - mold.frame.angle + 540) % 360) - 180);
  const score = Math.round(100 * clamp(1 - dist / 40, 0, 1) * clamp(1 - angle / 20, 0, 1));
  return {dist, angle, score, complete: dist <= 40 && angle <= 20};
}

// Equilíbrio: o ponto ideal do nó depende do molde e do peso da cola aplicada.
export function idealKnot(mold, glue) { return clamp(mold.balance.ideal + (glue?.waste || 0) * .08 - (glue?.coverage || 0) * .02, .15, .7); }
export function flightTilt(mold, glue, knot) { return (knot - idealKnot(mold, glue)) / mold.balance.spread; } // -1..1 = inclinação legível
export function scoreBalance(mold, glue, knot) {
  const err = Math.abs(flightTilt(mold, glue, knot));
  return {err, score: Math.round(100 * clamp(1 - err, 0, 1)), complete: err <= 1};
}

// Elo: três toques sincronizados com o pulso do vento (período em ms). Erro medido até o pico mais próximo.
export function scoreLink(taps, period = 1200, phase = 0) {
  if (!taps.length) return {score: 0, complete: false, errors: []};
  const errors = taps.map(t => { const m = ((t - phase) % period + period) % period; return Math.min(m, period - m); });
  const mean = errors.reduce((a, b) => a + b, 0) / errors.length;
  return {errors, score: Math.round(100 * clamp(1 - (mean - 40) / 260, 0, 1)), complete: taps.length >= 3};
}

// Nota → fração do orçamento. Abaixo de 50 não dá bônus nem penalidade; 100 entrega a fatia inteira.
export function dimensionShare(score) { return Math.pow(clamp((score - 50) / 50, 0, 1), 1.2); }
export function craftBonus(mold, scores) {
  const budget = BUDGET[mold.rarity] ?? BUDGET.comum, slice = budget / Object.keys(DIMENSIONS).length, bonus = {};
  for (const [dim, stat] of Object.entries(DIMENSIONS)) bonus[stat] = +(slice * dimensionShare(scores[dim] ?? 0)).toFixed(4);
  return {budget, bonus, total: +Object.values(bonus).reduce((a, b) => a + b, 0).toFixed(4)};
}

// Atributos do nível 1 do combate (mesma fórmula do engine) com a contribuição da oficina separada.
export function statSheet(bonus, level = 1) {
  const f = (level - 1) / 49, base = {line: 100 + 20 * f, energy: 100 + 15 * f, speed: 165 * (1 + .08 * f), regen: 18 * (1 + .10 * f)};
  return Object.fromEntries(Object.entries(base).map(([k, v]) => [k, {base: +v.toFixed(2), craft: +(v * (bonus[k] || 0)).toFixed(2), total: +(v * (1 + (bonus[k] || 0))).toFixed(2)}]));
}

// Economia da tentativa: reserva antes de começar, consome na falha, rabiola só na união final.
export function canStart(stock, mold, rabiola) {
  const missing = Object.entries(mold.recipe).filter(([k, n]) => (stock[k] || 0) < n).map(([k, n]) => k + ' ' + (stock[k] || 0) + '/' + n);
  if (!rabiola) missing.push('rabiola compatível');
  return {ok: !missing.length, missing};
}
export function reserve(stock, mold) {
  const next = {...stock};for (const [k, n] of Object.entries(mold.recipe)) next[k] -= n;return next;
}
export function attemptOutcome({integrity, practice}) {
  if (integrity > 0) return null;
  return practice ? {kind: 'falha-treino', consumed: false, rabiolaKept: true} : {kind: 'falha', consumed: true, rabiolaKept: true};
}

// Sorteio da aparência rara: uma vez, no primeiro despertar bem-sucedido; o rng é injetado (servidor/teste).
export function rollVariant(rng, chance = VARIANT_CHANCE) { return rng() < chance ? 'excepcional' : 'padrao'; }
