import fs from 'node:fs';
import assert from 'node:assert/strict';
import {validateProject,pixels} from '../core.mjs';
import {decodePNG} from '../png.mjs';
import {atlas} from '../animation.mjs';
const out=new URL('../../../art/characters/kael-video-item-v1/pacote/',import.meta.url);
const p=validateProject(JSON.parse(fs.readFileSync(new URL('kael-item.pixelgen.json',out))));
const png=decodePNG(fs.readFileSync(new URL('kael-item.png',out)));
const meta=JSON.parse(fs.readFileSync(new URL('item.json',out)));
assert.equal(p.frames.length,16);assert.equal(p.width,96);assert.equal(p.height,144);
assert.equal(p.sequences.length,1);assert.equal(p.sequences[0].loop,false);
assert.equal(p.frames.reduce((n,f)=>n+f.duration,0),1710);
assert.equal(meta.durationMs+meta.turnMs,1950);
assert.deepEqual(p.frames.map(f=>f.duration),meta.durationsMs);
assert.equal(png.width,1536);assert.equal(png.height,144);
for(let i=0;i<16;i++){
 const rgba=pixels(p,p.frames[i]);
 for(let y=0;y<144;y++)for(let x=0;x<96;x++){
  const at=(y*96+x)*4,dst=(y*1536+i*96+x)*4;
  for(let c=0;c<4;c++)assert.equal(rgba[at+c],png.data[dst+c]);
  assert.ok([0,255].includes(rgba[at+3]));
  if(!x||!y||x===95||y===143)assert.equal(rgba[at+3],0,'hand/feet must fit inside cell');
 }
 for(let y=111;y<132;y++)for(let x=32;x<65;x++)assert.ok(![7,8,9,21,25,26].includes(p.frames[i].indices[y*96+x]),'pants must keep the material ramp');
}
fs.writeFileSync(new URL('kael-item.atlas.json',out),JSON.stringify(atlas(p,'kael-item.png'),null,2));
fs.writeFileSync(new URL('qa.json',out),JSON.stringify({pass:true,frames:16,cell:[96,144],pivot:[48,142],paletteColors:p.palette.length-1,binaryAlpha:true,noClipping:true,exactPNGMatchesProject:true,pantsMaterialLocked:true,oneShot:true,poseMs:1710,totalWithTurnMs:1950},null,2));
console.log('Kael item: 16 frames, exact PNG/palette, unclipped raised finger, fixed pants ramp, timed one-shot: PASS');
