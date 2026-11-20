import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {revisionOf, saveCampaignMap} from './campaign-files.mjs';
import {campaignFloorOptions, paintCampaignFloor} from './isometric.mjs';
import {serve} from './server.mjs';

test('urban maps offer compatible street materials', () => {
  const map = {cells: [{material: 'calcada'}, {material: 'construcao'}]};
  assert.deepEqual(campaignFloorOptions(map), ['calcada', 'asfalto']);
  assert.equal(paintCampaignFloor(map, 0, 'grama'), false);
  assert.equal(paintCampaignFloor(map, 1, 'asfalto'), false);
  assert.equal(paintCampaignFloor(map, 0, 'asfalto'), true);
});

test('saves compatible changes and preserves campaign data on disk', async t => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'plant-lab-map-'));
  t.after(() => fs.rm(dir, {recursive: true, force: true}));
  const file = path.join(dir, 'map.json');
  const map = {
    schema: 'overworld-godot-1', w: 3, h: 1,
    cells: [{material: 'terra'}, {material: 'grama'}, {material: 'terra', ramp: 'v-'}],
    pieces: [{id: 3, asset: 'flores', blocks: false, u: 0, v: 0}],
    events: [{type: 'saida', u: 2, v: 0}],
    forest: {stairs: [{u: 2, v: 0}]},
    oracle: {walkable: [0, 1, 2]},
  };
  const raw = JSON.stringify(map);
  const revision = revisionOf(raw);
  await fs.writeFile(file, raw);

  const floor = {type: 'floor', index: 0, material: 'piso'};
  await assert.rejects(saveCampaignMap(file, {
    revision, edits: [floor, {...floor, index: 2}],
  }), {status: 422});
  assert.equal(await fs.readFile(file, 'utf8'), raw);

  const result = await saveCampaignMap(file, {
    revision, edits: [floor, {type: 'decoration', id: 3, u: 1, v: 0}],
  });
  const saved = await fs.readFile(file, 'utf8');
  assert.equal(result.revision, revisionOf(saved));
  map.cells[0].material = 'piso';
  map.pieces[0].u = 1;
  assert.deepEqual(JSON.parse(saved), map);
  await assert.rejects(saveCampaignMap(file, {revision, edits: [floor]}), {status: 409});
  assert.deepEqual(await fs.readdir(dir), ['map.json']);
});

test('the editor can reopen an HTTP save from the configured campaign directory', async t => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'plant-lab-api-'));
  const previous = process.env.PLANT_LAB_MAPS_DIR;
  const server = http.createServer(serve);
  t.after(async () => {
    if (previous === undefined) delete process.env.PLANT_LAB_MAPS_DIR;
    else process.env.PLANT_LAB_MAPS_DIR = previous;
    await new Promise(resolve => server.close(resolve));
    await fs.rm(dir, {recursive: true, force: true});
  });
  process.env.PLANT_LAB_MAPS_DIR = dir;
  await fs.writeFile(path.join(dir, 'aracati.json'), JSON.stringify({
    schema: 'overworld-godot-1', w: 1, h: 1, cells: [{material: 'terra'}],
  }));
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = 'http://127.0.0.1:' + server.address().port;
  const route = origin + '/api/campaign-maps';
  assert.deepEqual((await (await fetch(route)).json()).map(map => map.id), ['aracati']);
  const original = await fetch(route + '/aracati');
  await original.json();
  const body = JSON.stringify({
    revision: original.headers.get('X-Map-Revision'),
    edits: [{type: 'floor', index: 0, material: 'piso'}],
  });
  const save = source => fetch(route + '/aracati', {
    method: 'PUT', headers: {origin: source, 'content-type': 'application/json'}, body,
  });
  assert.equal((await save('http://example.invalid')).status, 403);
  assert.equal((await save(origin)).status, 200);
  assert.equal((await (await fetch(route + '/aracati')).json()).cells[0].material, 'piso');
  assert.equal((await save(origin)).status, 409);
});
