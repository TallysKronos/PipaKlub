import {readFileSync,writeFileSync} from "node:fs";
import {removeBackground,RemoveBackgroundMode} from "../../tmp/xprite-azulfazo/node_modules/@xprite/pixelate/dist/index.js";
const meta=JSON.parse(readFileSync("tmp/overworld-xprite-v2/glacerol-source.json"));
const data=new Uint8ClampedArray(readFileSync("tmp/overworld-xprite-v2/glacerol-source.rgba"));
const clear=removeBackground({...meta,data},{mode:RemoveBackgroundMode.Manual,keyColor:[255,255,255,255],tolerance:28});
writeFileSync("tmp/overworld-xprite-v2/glacerol-clean.rgba",clear.data);
