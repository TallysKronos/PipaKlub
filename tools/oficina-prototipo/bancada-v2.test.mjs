import test from 'node:test';
import assert from 'node:assert/strict';
import {MOLDS} from './model.mjs';
import {createSheet, strike, revealScore, lightVisible, PAPERS, createDefects, work, repairScore, DEFECTS} from './bancada-v2.mjs';

const mold = MOLDS['rabbito-tradicional'];
// Jogador simulado: só trabalha onde ainda há cobertura, como alguém olhando a folha.
const sweep = (sheet, tool, step) => { for (let y = 8; y < 436; y += step) for (let x = 124; x < 480; x += step) { const c = sheet.cells.find(q => Math.abs(q.x - x) <= 3 && Math.abs(q.y - y) <= 3); if (c && c.cover > .05) strike(sheet, tool, x, y); } };
const brute = (sheet, tool, step) => { for (let y = 8; y < 436; y += step) for (let x = 124; x < 480; x += step) strike(sheet, tool, x, y); };

test('a folha é reproduzível pela semente e esconde a marca', () => {
  const a = createSheet(mold, 'manteiga', 42), b = createSheet(mold, 'manteiga', 42);
  assert.deepEqual(a.cells.map(c => c.cover), b.cells.map(c => c.cover));
  assert.equal(revealScore(a).revealed, 0);
});

test('tesourinha revela com pouco rasgo; estilete revela rápido e rasga a marca exposta', () => {
  const careful = createSheet(mold, 'manteiga', 5);for (let k = 0; k < 16; k++) sweep(careful, 'tesourinha', 6);
  const c = revealScore(careful);assert.ok(c.revealed > .95 && c.damage < .35, JSON.stringify(c));
  const rough = createSheet(mold, 'manteiga', 5);for (let k = 0; k < 4; k++) sweep(rough, 'estilete', 20);
  const r = revealScore(rough);assert.ok(r.revealed > .9 && r.damage > c.damage, JSON.stringify(r));
});

test('papel de seda rasga mais com o mesmo golpe; dano acima de 50% faz a peça ceder', () => {
  const seda = createSheet(mold, 'seda', 9), mant = createSheet(mold, 'manteiga', 9);
  for (let k = 0; k < 4; k++) { sweep(seda, 'estilete', 20); sweep(mant, 'estilete', 20); }
  assert.ok(revealScore(seda).damage > revealScore(mant).damage);
  const ruined = createSheet(mold, 'seda', 9);for (let k = 0; k < 8; k++) brute(ruined, 'estilete', 14);
  assert.equal(revealScore(ruined).failed, true);
});

test('papel encerado esconde a marca da Luz até tirar a camada de cima', () => {
  const sheet = createSheet(mold, 'encerado', 3), piece = sheet.cells.filter(c => c.piece);
  assert.ok(piece.filter(c => lightVisible(sheet, c)).length < piece.length * .2);
  assert.ok(PAPERS.seda.lightDepth > PAPERS.encerado.lightDepth);
});

test('reparo: ferramenta certa conclui, errada e excesso danificam', () => {
  const defects = createDefects('manteiga', 4), state = {damage: 0};
  for (const d of defects) work(state, d, DEFECTS[d.type].tool, DEFECTS[d.type].need);
  assert.deepEqual(repairScore(defects, state), {fixed: 1, damage: 0, score: 100, failed: false});
  const wrong = Object.keys(DEFECTS).find(t => t !== defects[0].type);work(state, defects[0], DEFECTS[wrong].tool, 50);
  assert.equal(state.damage, 6);
  work(state, defects[0], DEFECTS[defects[0].type].tool, DEFECTS[defects[0].type].need);assert.ok(state.damage > 6, 'trabalho além do necessário também danifica');
});

test('aparência excepcional aparece no material desde a revelação', () => {
  assert.ok(createSheet(mold, 'manteiga', 1, 'excepcional').cells.some(c => c.mark));
  assert.ok(!createSheet(mold, 'manteiga', 1, 'padrao').cells.some(c => c.mark));
});
