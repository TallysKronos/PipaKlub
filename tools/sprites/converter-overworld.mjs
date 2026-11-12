#!/usr/bin/env node
// Folhas de overworld v2 dos Soulmonsters a partir das gerações originais do ImageGen.
//
// Por que: as folhas v1 (80×80) foram reduzidas por redimensionamento direto. O ImageGen desenha
// numa grade de pixels bem maior (o Farpim tem grade real de 90×89; o sprite saiu com 30×32), e a
// redução sem respeitar essa grade apaga olhos e contornos. Aqui:
//   1. separa as duas vistas da geração (frente SW e costas NW);
//   2. recupera a grade real com o xprite-pixelate (um pixel limpo por célula);
//   3. reduz para a altura final com o método "structure" do xprite e paleta de 20 cores;
//   4. monta a folha 224×112 (duas células 112×112, apoio em (56, 100)).
// A altura final mantém o tamanho aprovado no jogo (folha v1 × 1,25), mas na densidade de pixel do
// Kael: altura_v2 = altura_v1 × 1,25 / 0,952. Frente e costas usam o mesmo fator.
//
//   cd tools/sprites && npm install && node converter-overworld.mjs [id ...]
// Saída: godot/assets/campaign/overworld-companions-v2/<id>.png e overworld-companions-v2.json
//        tools/sprites/relatorio-v2.md (o que converteu e o que não)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { PNG } from "pngjs";
import * as X from "@xprite/pixelate";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const ART = path.join(ROOT, "art/creatures");
const V1 = path.join(ROOT, "godot/assets/campaign/overworld-companions");
const OUT = path.join(ROOT, "godot/assets/campaign/overworld-companions-v2");
const CELL = 112, PIVOT = 100;
const KAEL_SCALE = 0.85 * 1.12, V1_SIZE = 1.25;

// id → geração (relativa a art/creatures). Só entram criaturas com as duas vistas lado a lado.
const SOURCES = {
  "farpim": "alvacordo-family-v1/farpim/overworld-diagonal-v1/geracao.png",
  "papisco": "alvacordo-family-v1/papisco/overworld-diagonal-v1/geracao.png",
  "velcao": "alvacordo-family-v1/velcao/overworld-diagonal-v1/geracao.png",
  "alvacordo": "alvacordo-family-v1/alvacordo/overworld-diagonal-v1/geracao-v2.png",
  "gambalhote-baby": "gambalhote/gambalhote-baby/overworld-diagonal-v1/geracao.png",
  "gambalhote": "gambalhote/overworld-diagonal-v1/geracao.png",
  "gambalhote-young": "gambalhote/gambalhote-young/overworld-diagonal-v1/geracao.png",
  "gambalhote-adult": "gambalhote/gambalhote-adult/overworld-diagonal-v1/geracao-alpha-v2.png",
};

const read = p => { const png = PNG.sync.read(fs.readFileSync(p)); return { width: png.width, height: png.height, data: new Uint8ClampedArray(png.data) }; };
const write = (p, im) => { const o = new PNG({ width: im.width, height: im.height }); o.data = Buffer.from(im.data); fs.writeFileSync(p, PNG.sync.write(o)); };
const crop = (im, x, y, w, h) => {
  const d = new Uint8ClampedArray(w * h * 4);
  for (let r = 0; r < h; r++) d.set(im.data.subarray(((y + r) * im.width + x) * 4, ((y + r) * im.width + x + w) * 4), r * w * 4);
  return { width: w, height: h, data: d };
};
const opaque = (im, x, y) => im.data[(y * im.width + x) * 4 + 3] > 128;
function bbox(im) {
  let x0 = Infinity, y0 = Infinity, x1 = -1, y1 = -1;
  for (let y = 0; y < im.height; y++) for (let x = 0; x < im.width; x++) if (opaque(im, x, y)) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
  return x1 < 0 ? null : [x0, y0, x1 + 1, y1 + 1];
}
const trim = im => { const b = bbox(im); return crop(im, b[0], b[1], b[2] - b[0], b[3] - b[1]); };

// As duas vistas: recorte gravado na normalização da v1 ou, sem ele, o maior vão vazio no meio.
function views(file, image) {
  const norm = path.join(path.dirname(file), "normalizacao.json");
  if (fs.existsSync(norm)) {
    const regions = JSON.parse(fs.readFileSync(norm, "utf8")).regions;
    if (regions?.length === 2) return regions.map(r => crop(image, r.x, r.y, r.width, r.height));
  }
  const used = Array.from({ length: image.width }, (_, x) => { for (let y = 0; y < image.height; y++) if (opaque(image, x, y)) return true; return false; });
  let best = null;
  for (let x = Math.floor(image.width * .3); x < image.width * .7; x++) {
    if (used[x]) continue;
    let end = x; while (end < image.width && !used[end]) end++;
    if (!best || end - x > best[1] - best[0]) best = [x, end];
    x = end;
  }
  if (!best) throw new Error("não achei o vão entre as duas vistas");
  const cut = Math.floor((best[0] + best[1]) / 2);
  return [crop(image, 0, 0, cut, image.height), crop(image, cut, 0, image.width - cut, image.height)];
}

// sourceHeight: altura da vista na geração, para frente e costas terem a mesma escala mesmo
// quando o xprite acha grades diferentes (ou nenhuma) em cada uma.
function recover(view) {
  const clean = X.removeBackground(view);
  const sourceHeight = trim(clean).height;
  const grid = X.detectWithAlgorithm(clean, X.PixelationAlgorithm.Auto);
  if (!grid.reliable) return { art: trim(clean), grid: null, sourceHeight };
  const art = X.pixelateImage(clean, { mode: X.PixelationMode.RecoverGrid, grid, colorPicker: X.CellColorPicker.TwoStage, paletteSnap: { adaptive: true } });
  return { art: trim(art), grid: [grid.width, grid.height], sourceHeight };
}

const shrink = (art, height) => trim(X.pixelateImage(art, {
  mode: X.PixelationMode.Convert, targetWidth: Math.max(1, Math.round(art.width * height / art.height)), targetHeight: height,
  method: X.PixelationMethod.Structure, paletteSnap: { colors: 20 },
}));

function v1Height(id) {
  const sheet = read(path.join(V1, id + ".png")), front = crop(sheet, 0, 0, 80, 80), b = bbox(front);
  return b[3] - b[1];
}

function compose(front, back) {
  const sheet = { width: CELL * 2, height: CELL, data: new Uint8ClampedArray(CELL * 2 * CELL * 4) };
  [front, back].forEach((art, cell) => {
    if (art.width > CELL || art.height > PIVOT) throw new Error(`vista ${cell} ${art.width}×${art.height} não cabe na célula`);
    const ox = cell * CELL + Math.floor((CELL - art.width) / 2), oy = PIVOT - art.height;
    for (let y = 0; y < art.height; y++) for (let x = 0; x < art.width; x++) {
      const s = (y * art.width + x) * 4, d = ((oy + y) * sheet.width + ox + x) * 4;
      if (art.data[s + 3] > 128) { sheet.data.set(art.data.subarray(s, s + 3), d); sheet.data[d + 3] = 255; }
    }
  });
  return sheet;
}

await X.preloadWasm();
process.env.XPRITE_AC_RL_WORKER ??= "0";
fs.mkdirSync(OUT, { recursive: true });
const registryPath = OUT + ".json";
const registry = fs.existsSync(registryPath) ? JSON.parse(fs.readFileSync(registryPath, "utf8")) : {};
const wanted = process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(SOURCES);
const report = ["# Folhas de overworld v2", "", "| Criatura | Grade real (frente) | Altura v1 → v2 | Tamanho v2 (frente, costas) |", "| --- | --- | --- | --- |"];
for (const id of wanted) {
  const file = path.join(ART, SOURCES[id] ?? "");
  if (!SOURCES[id] || !fs.existsSync(file)) { report.push(`| ${id} | sem geração | — | — |`); continue; }
  try {
    const [frontView, backView] = views(file, read(file)).map(recover);
    const target = Math.round(v1Height(id) * V1_SIZE / KAEL_SCALE);
    const front = shrink(frontView.art, target);
    const back = shrink(backView.art, Math.max(1, Math.round(target * backView.sourceHeight / frontView.sourceHeight)));
    write(path.join(OUT, id + ".png"), compose(front, back));
    registry[id] = { cell: CELL, pivots: [PIVOT, PIVOT], source: path.relative(ROOT, file) };
    report.push(`| ${id} | ${frontView.grid ? frontView.grid.join("×") : "sem grade"} | ${v1Height(id)} → ${front.height} px | ${front.width}×${front.height}, ${back.width}×${back.height} |`);
    console.log("ok", id, front.width + "×" + front.height, back.width + "×" + back.height);
  } catch (error) {
    report.push(`| ${id} | erro: ${error.message} | — | — |`);
    console.log("falhou", id, error.message);
  }
}
fs.writeFileSync(registryPath, JSON.stringify(registry, null, 1) + "\n");
fs.writeFileSync(path.join(path.dirname(fileURLToPath(import.meta.url)), "relatorio-v2.md"), report.join("\n") + "\n");
