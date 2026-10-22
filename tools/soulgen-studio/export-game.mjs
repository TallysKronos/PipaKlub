// Exports approved Studio rigs to the game's assets (assets/creatures/rig-v1/). The game draws them only with ?rig.
// Usage: node tools/soulgen-studio/export-game.mjs   (re-run after changing a preset or its PNGs)
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createCarcara} from './carcara.mjs';
import {validate} from './model.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url)), out = path.join(root, 'assets/creatures/rig-v1');
const size = async src => { const png = fs.readFileSync(path.join(root, src)); return {width: png.readUInt32BE(16), height: png.readUInt32BE(20)}; };

// color: the basic Pipamon slot the rig replaces (0 = Carcará, as in assets/designs.json basics).
const rigs = {carcara: {color: 0, scale: 1.55, offsetY: 4, build: createCarcara}};
const manifest = {version: 1, kind: 'soulgen-rig', note: 'Desenhados no jogo apenas com ?rig. Gerado por tools/soulgen-studio/export-game.mjs.', rigs: {}};
for (const [id, def] of Object.entries(rigs)) {
  const project = await def.build(size), check = validate(project);
  if (!check.ok) throw Error(id + ': ' + check.errors.join(' '));
  fs.mkdirSync(path.join(out, id), {recursive: true});
  for (const [assetId, asset] of Object.entries(project.assets)) {
    const file = id + '/' + assetId + '.png';
    fs.copyFileSync(path.join(root, asset.src), path.join(out, file));
    asset.src = 'creatures/rig-v1/' + file;
  }
  manifest.rigs[id] = {color: def.color, scale: def.scale, offsetY: def.offsetY, project};
}
fs.writeFileSync(path.join(out, 'manifest.json'), JSON.stringify(manifest, null, 1) + '\n');
console.log('Rigs exportados:', Object.keys(manifest.rigs).join(', '), '→', path.relative(root, out));
