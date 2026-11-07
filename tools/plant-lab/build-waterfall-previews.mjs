import fs from 'node:fs/promises';
import {waterfallSample,waterfallPixels} from './waterfalls.mjs';
import {initialLayout} from './model.mjs';
import {WATERFALL_RGBA} from './waterfall-data.mjs';
import {png} from './png.mjs';
const bytes=Uint8Array.from(atob(WATERFALL_RGBA),c=>c.charCodeAt(0)),atlas=new Uint32Array(bytes.buffer),a=waterfallSample(initialLayout());
for(const o of a.objects){const p=waterfallPixels(a,o,atlas,0);await fs.writeFile('art/environment/kronasta-waterfalls-v1/sprites/'+o.asset+'.png',png(p));}
