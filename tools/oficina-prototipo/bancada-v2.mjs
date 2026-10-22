// Oficina das Almas · regras v2 (PIP-58): revelar a marca da alma escondida na folha bruta e reparar os materiais.
// Inspirado na limpeza de fósseis de Fossil Fighters e no reparo de DigiPlates de Digimon Story Lost Evolution
// (ver documentation/oficina-das-almas/REFERENCIAS.md). Funções puras; no jogo rodam no servidor.
import {pointInPolygon} from './model.mjs';

export const V2_VERSION = 'oficina-proto-2';
export const CELL = 6, AREA = {x: 120, y: 4, w: 360, h: 432};
export const REVEAL_SECONDS = 90, REPAIR_SECONDS = 60, FAIL_DAMAGE = .5;

// Tipos de papel = tipos de pedra: o de seda rasga fácil, o encerado não deixa a Luz atravessar a camada de cima.
export const PAPERS = {
  seda: {name: 'Papel de seda', fragility: 1.6, cover: [1, 2], lightDepth: 3, defects: 6},
  manteiga: {name: 'Papel manteiga', fragility: 1, cover: [1.2, 2.4], lightDepth: 3, defects: 4},
  encerado: {name: 'Papel encerado', fragility: 1, cover: [1.4, 2.6], lightDepth: 1.2, defects: 4}
};

// Gerador determinístico: o servidor sorteia a semente; o mesmo pedido reproduz a mesma folha.
export function rng(seed) { let s = seed >>> 0 || 1; return () => (s = (s * 1664525 + 1013904223) >>> 0) / 4294967296; }

// Folha bruta: cada célula tem camadas de retalhos (cover) e dano acumulado; "piece" é a marca da alma.
export function createSheet(mold, paperId, seed = 1, variant = 'padrao') {
  const paper = PAPERS[paperId], r = rng(seed), cols = AREA.w / CELL, rows = Math.floor(AREA.h / CELL), cells = [];
  const blobs = Array.from({length: 9}, () => ({x: AREA.x + r() * AREA.w, y: AREA.y + r() * AREA.h, s: 30 + r() * 70, a: r() * .9}));
  for (let j = 0; j < rows; j++) for (let i = 0; i < cols; i++) {
    const x = AREA.x + i * CELL + CELL / 2, y = AREA.y + j * CELL + CELL / 2, piece = pointInPolygon([x, y], mold.outline);
    let cover = paper.cover[0] + (paper.cover[1] - paper.cover[0]) * r() * .5;
    for (const b of blobs) { const d = Math.hypot(x - b.x, y - b.y); if (d < b.s) cover += b.a * (1 - d / b.s); }
    if (!piece) cover += .6;
    cells.push({x, y, piece, cover: Math.min(3, cover), damage: 0, mark: piece && variant === 'excepcional' && y < 104});
  }
  return {mold: mold.id, paper: paperId, seed, variant, cols, rows, cells};
}
export const cellAt = (sheet, x, y) => { const i = Math.floor((x - AREA.x) / CELL), j = Math.floor((y - AREA.y) / CELL); return i < 0 || j < 0 || i >= sheet.cols || j >= sheet.rows ? null : sheet.cells[j * sheet.cols + i]; };
function around(sheet, x, y, radius, fn) {
  const i0 = Math.max(0, Math.floor((x - radius - AREA.x) / CELL)), i1 = Math.min(sheet.cols - 1, Math.floor((x + radius - AREA.x) / CELL));
  const j0 = Math.max(0, Math.floor((y - radius - AREA.y) / CELL)), j1 = Math.min(sheet.rows - 1, Math.floor((y + radius - AREA.y) / CELL));
  for (let j = j0; j <= j1; j++) for (let i = i0; i <= i1; i++) { const c = sheet.cells[j * sheet.cols + i], d = Math.hypot(c.x - x, c.y - y); if (d <= radius) fn(c, d / radius); }
}

// Estilete (o martelo): tira uma camada inteira num raio largo. Onde a marca já está exposta, o golpe rasga; o tranco atinge um raio maior.
export const KNIFE = {radius: 22, shock: 32, layer: 1, tear: .45, shockTear: .12};
// Tesourinha (a broca): raio pequeno, tira pouco por passada, quase não rasga.
export const SNIPS = {radius: 8, layer: .3, tear: .008};
export function strike(sheet, tool, x, y) {
  const f = PAPERS[sheet.paper].fragility;
  if (tool === 'estilete') {
    around(sheet, x, y, KNIFE.shock, (c, t) => {
      const inner = t * KNIFE.shock <= KNIFE.radius;
      if (inner) { const removed = KNIFE.layer * (1 - .4 * t * KNIFE.shock / KNIFE.radius), left = c.cover - removed; if (left < 0 && c.piece) c.damage = Math.min(1, c.damage - left * KNIFE.tear * f); c.cover = Math.max(0, left); }
      else if (c.piece && c.cover < .3) c.damage = Math.min(1, c.damage + KNIFE.shockTear * f * (1 - t));
    });
  } else if (tool === 'tesourinha') {
    around(sheet, x, y, SNIPS.radius, c => { const left = c.cover - SNIPS.layer; if (left < 0 && c.piece) c.damage = Math.min(1, c.damage + SNIPS.tear * f); c.cover = Math.max(0, left); });
  }
  return revealScore(sheet);
}
// Luz do molde (o raio-X): mostra a marca onde a cobertura é rasa o bastante para a luz atravessar.
export const lightVisible = (sheet, c) => c.piece && c.cover <= PAPERS[sheet.paper].lightDepth;

// Nota da revelação: quanto da marca apareceu, descontado o rasgo. Rasgo médio de 50% faz a peça ceder.
export function revealScore(sheet) {
  let n = 0, shown = 0, dmg = 0;
  for (const c of sheet.cells) if (c.piece) { n++; if (c.cover <= .05) shown++; dmg += c.damage; }
  const revealed = shown / n, damage = dmg / n;
  return {revealed, damage, score: Math.round(100 * revealed * (1 - damage)), failed: damage >= FAIL_DAMAGE};
}

// Reparo (as DigiPlates): cada defeito pede uma ferramenta. Ferramenta errada ou trabalho demais danificam.
export const DEFECTS = {
  rasgo: {name: 'Rasgo', tool: 'remendo', need: 800, unit: 'ms'},
  ruga: {name: 'Ruga', tool: 'ferro', need: 140, unit: 'px'},
  farpa: {name: 'Farpa na vareta', tool: 'lixa', need: 100, unit: 'px'},
  mancha: {name: 'Mancha de barro', tool: 'pano', need: 160, unit: 'px'},
  embolada: {name: 'Linha embolada', tool: 'agulha', need: 3, unit: 'toques'}
};
export const TOOLS = {remendo: 'Remendo com cola', ferro: 'Ferro morno', lixa: 'Lixa', pano: 'Pano úmido', agulha: 'Agulha'};
// Farpas ficam nas varetas; os outros defeitos, no papel entre elas.
const STICK_SPOTS = [[300, 140], [300, 300], [228, 200], [372, 200]];
const PAPER_SPOTS = [[255, 160], [345, 160], [250, 260], [350, 260], [300, 345], [300, 240]];
export function createDefects(paperId, seed = 1) {
  const r = rng(seed * 7 + 3), types = Object.keys(DEFECTS), n = PAPERS[paperId].defects;
  const stick = [...STICK_SPOTS].sort(() => r() - .5), paper = [...PAPER_SPOTS].sort(() => r() - .5);
  return Array.from({length: n}, (_, i) => { const type = types[Math.floor(r() * types.length)], [x, y] = (type === 'farpa' ? stick : paper).shift() || paper.shift() || stick.shift(); return {id: i, type, x, y, r: 26, work: 0, done: false}; });
}
// amount: ms segurando (remendo), px arrastados (ferro, lixa, pano) ou 1 por toque (agulha).
export function work(state, defect, tool, amount) {
  const d = DEFECTS[defect.type];
  if (tool !== d.tool) { state.damage += 6; return {wrong: true}; }
  if (defect.done) { state.damage += d.unit === 'toques' ? 1 : amount / d.need * 1.5; return {overwork: true}; }
  defect.work += amount; if (defect.work >= d.need) defect.done = true;
  return {progress: Math.min(1, defect.work / d.need)};
}
export function repairScore(defects, state) {
  const fixed = defects.filter(d => d.done).length / defects.length, damage = Math.min(1, state.damage / 100);
  return {fixed, damage, score: Math.round(100 * fixed * (1 - damage)), failed: damage >= FAIL_DAMAGE};
}

// Artesão automático: conclui sem jogar, com nota limitada e sem consumir menos material.
export const AUTO_CAP = 60;
