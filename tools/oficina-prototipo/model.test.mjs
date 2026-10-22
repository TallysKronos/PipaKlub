import test from 'node:test';
import assert from 'node:assert/strict';
import {MOLDS, BUDGET, outlineSamples, scoreCut, scoreGlue, GLUE_CELL, scoreAssembly, scoreBalance, idealKnot, scoreLink, craftBonus, statSheet, canStart, reserve, attemptOutcome, rollVariant} from './model.mjs';

const mold = MOLDS['rabbito-tradicional'];

test('corte seguindo o contorno pontua alto; cortar para dentro causa dano e perde nota', () => {
  const exact = outlineSamples(mold.outline, 4), good = scoreCut(mold, exact);
  assert.ok(good.complete && good.score >= 90 && good.damage === 0);
  const inward = exact.map(([x, y]) => [x + (300 - x) * .12, y + (210 - y) * .12]), bad = scoreCut(mold, inward);
  assert.ok(bad.damage > 0 && bad.score < good.score);
  assert.equal(scoreCut(mold, exact.slice(0, exact.length / 3)).complete, false, 'contorno incompleto não conclui');
});

test('cola: abas cobertas pontuam; articulações causam dano; excesso reduz a nota', () => {
  const tabs = new Set();
  for (const [x, y, w, h] of mold.tabs) for (let i = x; i < x + w; i += GLUE_CELL) for (let j = y; j < y + h; j += GLUE_CELL) tabs.add(Math.floor(i / GLUE_CELL) + ',' + Math.floor(j / GLUE_CELL));
  const clean = scoreGlue(mold, tabs);
  assert.ok(clean.complete && clean.score >= 95 && clean.damage === 0);
  const joint = new Set([...tabs, Math.floor(266 / GLUE_CELL) + ',' + Math.floor(70 / GLUE_CELL)]);
  assert.ok(scoreGlue(mold, joint).damage > 0);
  const messy = new Set(tabs);for (let i = 0; i < 40; i++) messy.add('5,' + i);
  assert.ok(scoreGlue(mold, messy).score < clean.score);
});

test('montagem, equilíbrio e elo medem o erro, não a quantidade de cliques', () => {
  assert.equal(scoreAssembly(mold, {...mold.frame}).score, 100);
  assert.equal(scoreAssembly(mold, {x: mold.frame.x + 60, y: mold.frame.y, angle: 0}).complete, false);
  assert.equal(scoreBalance(mold, null, idealKnot(mold, null)).score, 100);
  assert.ok(scoreBalance(mold, null, .7).score < 20);
  assert.equal(scoreLink([1200, 2400, 3600]).score, 100);
  assert.ok(scoreLink([1500, 2700, 3900]).score < 20);
});

test('bônus respeita o teto do molde e execuções diferentes geram exemplares diferentes', () => {
  const perfect = craftBonus(mold, {corte: 100, colagem: 100, equilibrio: 100, elo: 100});
  assert.equal(perfect.total, BUDGET.comum);
  const mid = craftBonus(mold, {corte: 75, colagem: 70, equilibrio: 80, elo: 60}), weak = craftBonus(mold, {corte: 40, colagem: 45, equilibrio: 30, elo: 10});
  assert.ok(mid.total > 0 && mid.total < perfect.total && weak.total === 0, 'abaixo de 50 não pune nem bonifica');
  assert.notDeepEqual(statSheet(mid.bonus), statSheet(perfect.bonus));
  assert.equal(statSheet(perfect.bonus).speed.base, 165, 'base separada da contribuição da oficina');
  assert.ok(craftBonus(MOLDS['rabbito-vela-leve'], {corte: 100, colagem: 100, equilibrio: 100, elo: 100}).total <= BUDGET.raro);
});

test('economia: sem materiais não inicia; falha consome o lote e preserva a rabiola; treino não consome', () => {
  assert.deepEqual(canStart({papel: 1, vareta: 2, cola: 1}, mold, true).missing, ['papel 1/2']);
  assert.equal(canStart({papel: 2, vareta: 2, cola: 1}, mold, false).ok, false);
  assert.deepEqual(reserve({papel: 3, vareta: 2, cola: 1}, mold), {papel: 1, vareta: 0, cola: 0});
  assert.equal(attemptOutcome({integrity: 20, practice: false}), null);
  assert.deepEqual(attemptOutcome({integrity: 0, practice: false}), {kind: 'falha', consumed: true, rabiolaKept: true});
  assert.equal(attemptOutcome({integrity: 0, practice: true}).consumed, false);
});

test('aparência rara: sorteio injetável, chance configurável', () => {
  assert.equal(rollVariant(() => 0), 'excepcional');
  assert.equal(rollVariant(() => .5), 'padrao');
  let seed = 7, hits = 0;const rng = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 256000; i++) if (rollVariant(rng) === 'excepcional') hits++;
  assert.ok(hits > 850 && hits < 1150, 'cerca de 1 em 256: ' + hits);
});
