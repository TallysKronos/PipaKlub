#!/usr/bin/env node
// Converte uma pintura de cenário (prédio, prop) para pixel art na densidade de pixel dos
// personagens, presa à paleta mestra (art/overworld/estilo/paleta-mestra.hex). Ver
// documentation/art/GUIA-DE-ESTILO-CENARIO.md.
//
//   node converter-cenario.mjs <entrada.png> <saida.png> <altura-em-px-na-tela> [cores-extras]
// A altura é a que a peça tem no jogo com zoom 1 (o Kael tem 67 px). Sem redimensionar depois.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { PNG } from "pngjs";
import * as X from "@xprite/pixelate";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const [,, input, output, heightArg] = process.argv;
if (!input || !output || !heightArg) { console.log("uso: node converter-cenario.mjs <entrada.png> <saida.png> <altura>"); process.exit(1); }
const palette = fs.readFileSync(path.join(ROOT, "art/overworld/estilo/paleta-mestra.hex"), "utf8").trim().split(/\s+/)
  .map(h => [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16), 255]);
const png = PNG.sync.read(fs.readFileSync(input));
const image = { width: png.width, height: png.height, data: new Uint8ClampedArray(png.data) };
await X.preloadWasm();
const height = Number(heightArg), width = Math.max(1, Math.round(image.width * height / image.height));
const art = X.pixelateImage(image, { mode: X.PixelationMode.Convert, targetWidth: width, targetHeight: height,
  method: X.PixelationMethod.Structure, paletteSnap: { palette } });
const out = new PNG({ width: art.width, height: art.height }); out.data = Buffer.from(art.data);
fs.writeFileSync(output, PNG.sync.write(out));
console.log("ok", path.basename(output), art.width + "×" + art.height, palette.length, "cores da paleta");
