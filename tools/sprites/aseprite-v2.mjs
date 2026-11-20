#!/usr/bin/env node
// Gera um .aseprite editável para cada folha v2 (godot/assets/campaign/overworld-companions-v2/):
// dois quadros de 112×112 (1 = frente SW, 2 = costas NW), camada "Criatura", recorte "chao" com
// o ponto de apoio e a paleta da criatura. Confere cada arquivo relendo-o com o ase-parser.
//
//   cd tools/sprites && npm install && node aseprite-v2.mjs [id ...]
// Saída: art/creatures/overworld-v2/<id>/<id>-overworld-v2.aseprite
// Depois de editar no Aseprite: File > Export Sprite Sheet, By Rows, por cima do PNG em
// godot/assets/campaign/overworld-companions-v2/<id>.png (os pés na linha 100 de cada quadro).
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import zlib from "node:zlib";
import { PNG } from "pngjs";
import { writeAseprite } from "./aseprite.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../..");
const SHEETS = path.join(ROOT, "godot/assets/campaign/overworld-companions-v2");
const OUT = path.join(ROOT, "art/creatures/overworld-v2");
const registry = JSON.parse(fs.readFileSync(SHEETS + ".json", "utf8"));
const Aseprite = (() => { try { return createRequire(import.meta.url)("ase-parser"); } catch { return null; } })();

export function sheetToAseprite(id) {
  const entry = registry[id], cell = entry.cell;
  const png = PNG.sync.read(fs.readFileSync(path.join(SHEETS, id + ".png")));
  const frames = [0, 1].map(index => {
    const frame = Buffer.alloc(cell * cell * 4);
    for (let y = 0; y < cell; y++) png.data.copy(frame, y * cell * 4, (y * png.width + index * cell) * 4, (y * png.width + (index + 1) * cell) * 4);
    return frame;
  });
  const file = path.join(OUT, id, `${id}-overworld-v2.aseprite`);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  writeAseprite(file, { width: cell, height: cell, frames, slice: { name: "chao", pivot: [cell / 2, entry.pivots[0]] } });
  return { file, frames };
}

function check(file, frames, cell) {
  if (!Aseprite) return "sem ase-parser (npm install --no-save ase-parser@0.0.19)";
  const ase = new Aseprite(fs.readFileSync(file), path.basename(file));
  ase.parse();
  if (ase.width !== cell || ase.numFrames !== 2 || ase.layers[0]?.name !== "Criatura" || ase.slices[0]?.name !== "chao") return "estrutura diferente";
  for (const [index, frame] of frames.entries()) {
    const cel = ase.frames[index].cels[0];
    const pixels = cel.rawCelData ?? zlib.inflateSync(cel.rawCelData ?? Buffer.alloc(0));
    for (let y = 0; y < cel.h; y++) for (let x = 0; x < cel.w; x++) {
      const a = pixels.readUInt32BE((y * cel.w + x) * 4), b = frame.readUInt32BE(((cel.ypos + y) * cell + cel.xpos + x) * 4);
      if (a !== b) return `pixel diferente no quadro ${index + 1} (${cel.xpos + x}, ${cel.ypos + y})`;
    }
  }
  return "ok";
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const wanted = process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(registry);
  for (const id of wanted) {
    const { file, frames } = sheetToAseprite(id);
    console.log(id, path.relative(ROOT, file), check(file, frames, registry[id].cell));
  }
}
