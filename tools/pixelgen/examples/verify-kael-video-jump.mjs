import fs from 'node:fs';
import assert from 'node:assert/strict';
import {validateProject,pixels} from '../core.mjs';
import {decodePNG} from '../png.mjs';
import {atlas} from '../animation.mjs';
const out=new URL('../../../art/characters/kael-video-jump-v1/pacote/',import.meta.url);
const p=validateProject(JSON.parse(fs.readFileSync(new URL('kael-jump.pixelgen.json',out))));
const png=decodePNG(fs.readFileSync(new URL('kael-jump.png',out)));
const walk=JSON.parse(fs.readFileSync(new URL('../../../art/characters/kael-video-eight-directions-v1/pacote/kael-eight.pixelgen.json',import.meta.url)));
assert.deepEqual(p.palette,walk.palette);assert.equal(p.frames.length,32);
assert.equal(p.width,96);assert.equal(p.height,112);
for(const s of p.sequences){assert.equal(s.loop,false);assert.equal(p.frames.slice(s.start,s.end+1).reduce((n,f)=>n+f.duration,0),820);}
for(let i=0;i<32;i++){
 const rgba=pixels(p,p.frames[i]);
 for(let y=0;y<112;y++)for(let x=0;x<96;x++){
  const at=(y*96+x)*4,src=((Math.floor(i/16)*112+y)*png.width+(i%16)*96+x)*4;
  for(let c=0;c<4;c++)assert.equal(rgba[at+c],png.data[src+c]);
  assert.ok([0,255].includes(rgba[at+3]));
  if(!x||!y||x===95||y===111)assert.equal(rgba[at+3],0);
 }
}
// Verification must not overwrite the Aseprite document that the artist edited.
fs.writeFileSync(new URL('kael-jump.atlas.json',out),JSON.stringify(atlas(p,'kael-jump.png'),null,2));
fs.writeFileSync(new URL('qa.json',out),JSON.stringify({pass:true,frames:32,cell:[96,112],opaqueColors:p.palette.length-1,pivot:[48,110],binaryAlpha:true,noClipping:true,exactPNGMatchesProject:true,paletteMatchesWalk:true,oneShotDurationMs:820,artStatus:'rascunho extraído de vídeo; revisão visual separada'},null,2));
console.log('Kael jump: 32 poses, binary alpha, exact palette/PNG, 820 ms one-shot tags and unclipped borders: PASS');
