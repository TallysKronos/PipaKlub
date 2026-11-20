import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { detectWithAlgorithm, pixelateImage, PixelationAlgorithm, PixelationMode, CellColorPicker, preloadWasm } from "@xprite/pixelate";
const meta = JSON.parse(readFileSync(new URL("./source.json", import.meta.url)));
const image = { width: meta.width, height: meta.height, data: new Uint8ClampedArray(readFileSync(new URL("./source.rgba", import.meta.url))) };
await preloadWasm();
const started = performance.now();
const grid = detectWithAlgorithm(image, PixelationAlgorithm.Auto);
const info = { source: meta, grid, milliseconds: performance.now()-started };
writeFileSync(new URL("./detection.json", import.meta.url), JSON.stringify(info,null,2));
console.log(JSON.stringify({ reliable:grid.reliable, width:grid.width,height:grid.height, cellWidth:grid.cellWidth,cellHeight:grid.cellHeight,confidence:grid.confidence,milliseconds:info.milliseconds }));
if(!grid.reliable) process.exit(2);
for(const [label, options] of [
  ["recover", {mode:PixelationMode.RecoverGrid, grid, colorPicker:CellColorPicker.TwoStage}],
  ["recover-palette", {mode:PixelationMode.RecoverGrid,grid,colorPicker:CellColorPicker.TwoStage,paletteSnap:{colors:20}}],
]){
  const result=pixelateImage(image,options);
  writeFileSync(new URL("./"+label+".rgba",import.meta.url),result.data);
  writeFileSync(new URL("./"+label+".json",import.meta.url),JSON.stringify({width:result.width,height:result.height,options:{...options,grid:undefined}},null,2));
  console.log(label,result.width,result.height);
}
