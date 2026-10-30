import fs from 'node:fs';
import assert from 'node:assert/strict';
import {validateProject} from '../core.mjs';
import {frameRGBA} from '../render.mjs';
import {decodePNG} from '../png.mjs';
const root=new URL('../../../',import.meta.url),dir=new URL('art/characters/kael-compatible-sheets-v2/',root);
const read=(name)=>JSON.parse(fs.readFileSync(new URL(name,dir)));
const manifest=read('manifest.json'),atlas=read('kael-completo.atlas.json'),master=decodePNG(fs.readFileSync(new URL('kael-completo.png',dir)));
let checked=0;
for(const sheet of manifest.sheets){
 const p=validateProject(read(sheet.source)),local=read(`kael-${sheet.motion}.atlas.json`),png=decodePNG(fs.readFileSync(new URL(sheet.image,dir)));
 assert.deepEqual(p.palette,manifest.palette);assert.equal(p.width,48);assert.equal(p.height,64);
 assert.equal(png.width,384);assert.equal(png.height,512);
 assert.deepEqual(local.meta.size,{w:png.width,h:png.height});
 for(let i=0;i<p.frames.length;i++){
  const expected=frameRGBA(p,i),rect=local.frames[i].frame,whole=atlas.frames.find(f=>f.sheet===sheet.image&&f.localFrame===i).frame;
  const actual=decodePNG(fs.readFileSync(new URL(`tmp/kael-v2-native/${sheet.motion}-${i+1}.png`,root)));
  assert.equal(actual.width,48);assert.equal(actual.height,64);
  for(let y=0;y<64;y++)for(let x=0;x<48;x++){
   const at=(y*48+x)*4,a=((rect.y+y)*png.width+rect.x+x)*4,b=((whole.y+y)*master.width+whole.x+x)*4;
   // RGB under fully transparent pixels is undefined in native indexed exports.
   assert.equal(actual.data[at+3],expected[at+3]);
   for(let k=0;k<4;k++){
    assert.equal(png.data[a+k],expected[at+k],`${sheet.motion}/${i} local PNG`);
    assert.equal(master.data[b+k],expected[at+k],`${sheet.motion}/${i} master PNG`);
    if(expected[at+3])assert.equal(actual.data[at+k],expected[at+k],`${sheet.motion}/${i} native Aseprite`);
   }
  }
  checked++;
 }
}
assert.equal(checked,manifest.master.frames);
assert.equal(new Set(atlas.sequences.map(s=>s.name)).size,74);
const report={frames:checked,sheets:manifest.sheets.length,sequences:atlas.sequences.length,cell:manifest.cell,pivot:manifest.pivot,asepriteRoundTrip:'exact RGBA on visible pixels; alpha exact',masterAssembly:'every frame identical to its source and individual sheet',passed:true};
fs.writeFileSync(new URL('native-verification.json',dir),JSON.stringify(report,null,2));
console.log(report);
