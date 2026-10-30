// Verify the produced files, not a reimplementation of the sampler.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {validateProject,pixels} from '../core.mjs';
import {decodePNG} from '../png.mjs';
import {atlas} from '../animation.mjs';
import {buildSheetPack} from '../sheet-pack.mjs';
import {aseprite} from '../aseprite.mjs';
import {godotResource} from '../godot.mjs';
const out=new URL('../../../art/characters/kael-video-eight-directions-v1/pacote/',import.meta.url);
const p=validateProject(JSON.parse(fs.readFileSync(new URL('kael-eight.pixelgen.json',out))));
assert.equal(p.frames.length,64);assert.equal(p.sequences.length,8);
assert.equal(p.width,64);assert.equal(p.height,96);assert.equal(p.palette.length,33);
const sheet=decodePNG(fs.readFileSync(new URL('kael-walk-eight.png',out)));
assert.equal(sheet.width,512);assert.equal(sheet.height,768);
const directions=['S','SO','O','NO','N','NE','E','SE'],unique=[],projects=[];
for(const [row,d]of directions.entries()){
 const source=validateProject(JSON.parse(fs.readFileSync(new URL(`walk-${d}.pixelgen.json`,out))));projects.push(source);
 assert.deepEqual(source.palette,p.palette);assert.equal(source.frames.length,8);
 assert.equal(p.sequences[row].name,`walk-${d}`);assert.equal(p.sequences[row].start,row*8);
 const names=new Set();
 for(let col=0;col<8;col++){
  const f=p.frames[row*8+col],rgba=pixels(p,f);assert.equal(f.name,`walk-${d}-${col+1}`);assert.ok(f.indices.some(Boolean));
  assert.ok(f.duration>=20&&f.duration<=2000);assert.deepEqual(source.frames[col].indices,f.indices);
  names.add(crypto.createHash('sha256').update(f.indices).digest('hex'));
  for(let y=0;y<96;y++)for(let x=0;x<64;x++){
   const at=(y*64+x)*4;assert.ok(rgba[at+3]===0||rgba[at+3]===255);
   const dst=((row*96+y)*512+col*64+x)*4;
   for(let c=0;c<4;c++)assert.equal(rgba[at+c],sheet.data[dst+c]);
   if(!x||x===63||!y||y===95)assert.equal(rgba[at+3],0,'Arte cortada na borda da célula.');
  }
 }
 unique.push({direction:d,uniqueFrames:names.size,durationMs:p.frames.slice(row*8,row*8+8).reduce((n,f)=>n+f.duration,0)});
}
const packed=buildSheetPack(projects,{columns:8});assert.equal(packed.width,512);assert.equal(packed.height,768);assert.deepEqual(packed.rgba,sheet.data);
fs.writeFileSync(new URL('kael-walk-eight.atlas.json',out),JSON.stringify(atlas(p,'kael-walk-eight.png'),null,2));
fs.writeFileSync(new URL('kael-walk-eight.aseprite',out),aseprite(p));
fs.writeFileSync(new URL('kael-walk-eight.tres',out),godotResource(p,'res://assets/review/kael-walk-eight.png'));
const report={pass:true,frames:64,cell:[64,96],sheet:[512,768],opaqueColors:32,alpha:[0,255],pivot:[32,94],directions:unique,exactPNGMatchesProject:true,separateSheetsReassembleExactly:true,artStatus:'rascunho para revisão; verificação de pixels não certifica anatomia ou loops perfeitos'};
fs.writeFileSync(new URL('qa.json',out),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
