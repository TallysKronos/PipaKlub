// Escrita de arquivos .aseprite (formato documentado em
// https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md), no mesmo padrão dos
// arquivos do Codex: modo RGBA, uma camada "Criatura", um quadro por vista e o recorte "chao" com o
// ponto de apoio. A paleta traz as cores da criatura, para editar com elas à mão.
import fs from "node:fs";
import zlib from "node:zlib";

class Bytes {
  constructor() { this.parts = []; }
  u8(v) { const b = Buffer.alloc(1); b.writeUInt8(v); this.parts.push(b); return this; }
  u16(v) { const b = Buffer.alloc(2); b.writeUInt16LE(v); this.parts.push(b); return this; }
  i16(v) { const b = Buffer.alloc(2); b.writeInt16LE(v); this.parts.push(b); return this; }
  u32(v) { const b = Buffer.alloc(4); b.writeUInt32LE(v); this.parts.push(b); return this; }
  i32(v) { const b = Buffer.alloc(4); b.writeInt32LE(v); this.parts.push(b); return this; }
  zero(n) { this.parts.push(Buffer.alloc(n)); return this; }
  raw(buffer) { this.parts.push(buffer); return this; }
  text(s) { const b = Buffer.from(s, "utf8"); return this.u16(b.length).raw(b); }
  get buffer() { return Buffer.concat(this.parts); }
}

const chunk = (type, body) => new Bytes().u32(body.length + 6).u16(type).raw(body).buffer;

function bounds(frame, width, height) {
  let x0 = width, y0 = height, x1 = -1, y1 = -1;
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    if (frame[(y * width + x) * 4 + 3] === 0) continue;
    x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y);
  }
  return x1 < 0 ? [0, 0, 1, 1] : [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
}

function palette(frames) {
  const seen = new Map();
  for (const frame of frames) for (let i = 0; i < frame.length; i += 4) {
    if (frame[i + 3] === 0) continue;
    const key = frame.readUInt32BE ? frame.readUInt32BE(i) : ((frame[i] << 24) | (frame[i + 1] << 16) | (frame[i + 2] << 8) | frame[i + 3]) >>> 0;
    seen.set(key, (seen.get(key) ?? 0) + 1);
  }
  return [...seen.entries()].sort((a, b) => b[1] - a[1]).slice(0, 256).map(([key]) => [key >>> 24, (key >>> 16) & 255, (key >>> 8) & 255, key & 255]);
}

/**
 * frames: Buffer RGBA (width × height × 4) por quadro.
 * slice: { name, pivot: [x, y] } aplicado a todos os quadros.
 */
export function writeAseprite(file, { width, height, frames, layer = "Criatura", slice, durationMs = 100 }) {
  frames = frames.map(f => Buffer.from(f));
  const colors = palette(frames);
  const out = [];
  frames.forEach((frame, index) => {
    const chunks = [];
    if (index === 0) {
      chunks.push(chunk(0x2007, new Bytes().u16(1).u16(0).u32(0).zero(8).buffer)); // perfil sRGB
      const pal = new Bytes().u32(colors.length).u32(0).u32(Math.max(0, colors.length - 1)).zero(8);
      for (const [r, g, b, a] of colors) pal.u16(0).u8(r).u8(g).u8(b).u8(a);
      chunks.push(chunk(0x2019, pal.buffer));
      // camada visível e editável, opacidade 255
      chunks.push(chunk(0x2004, new Bytes().u16(3).u16(0).u16(0).u16(0).u16(0).u16(0).u8(255).zero(3).text(layer).buffer));
      if (slice) {
        const s = new Bytes().u32(1).u32(2).u32(0).text(slice.name)
          .u32(0).i32(0).i32(0).u32(width).u32(height).i32(slice.pivot[0]).i32(slice.pivot[1]);
        chunks.push(chunk(0x2022, s.buffer));
      }
    }
    const [x, y, w, h] = bounds(frame, width, height);
    const pixels = Buffer.alloc(w * h * 4);
    for (let r = 0; r < h; r++) frame.copy(pixels, r * w * 4, ((y + r) * width + x) * 4, ((y + r) * width + x + w) * 4);
    chunks.push(chunk(0x2005, new Bytes().u16(0).i16(x).i16(y).u8(255).u16(2).i16(0).zero(5).u16(w).u16(h).raw(zlib.deflateSync(pixels)).buffer));
    const body = Buffer.concat(chunks);
    out.push(new Bytes().u32(body.length + 16).u16(0xF1FA).u16(Math.min(chunks.length, 0xFFFF)).u16(durationMs).zero(2).u32(chunks.length).raw(body).buffer);
  });
  const frameData = Buffer.concat(out);
  const header = new Bytes().u32(128 + frameData.length).u16(0xA5E0).u16(frames.length).u16(width).u16(height).u16(32)
    .u32(1).u16(100).u32(0).u32(0).u8(0).zero(3).u16(colors.length || 256).u8(1).u8(1).i16(0).i16(0).u16(16).u16(16).zero(84).buffer;
  if (header.length !== 128) throw new Error("cabeçalho .aseprite com " + header.length + " bytes");
  fs.writeFileSync(file, Buffer.concat([header, frameData]));
}
