import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
import {hudAssets,hudSliceRects,hudSliceSample,hudSpriteCSS} from './scripts/hud-assets.mjs';
import {mountHudSkin} from './src/hud-skin.js';

test('HUD cuts cover their source without overlap or missing pixels',()=>{
 const atlas=hudAssets();
 for(const [id,spec] of Object.entries(atlas.slices)){
  const source=atlas.frames[id],parts=Object.values(hudSliceRects(atlas,id));
  assert.equal(parts.length,spec.mode==='three'?3:9,id);
  for(const [sheet,x,y,w,h] of parts){assert.equal(sheet,source[0]);assert.ok(w>0&&h>0);assert.ok(x>=source[1]&&y>=source[2]&&x+w<=source[1]+source[3]&&y+h<=source[2]+source[4],id);}
  if(spec.mirrorLeft)continue;
  assert.equal(parts.reduce((area,p)=>area+p[3]*p[4],0),source[3]*source[4],id);
  for(let i=0;i<parts.length;i++)for(let j=i+1;j<parts.length;j++)assert.ok(Math.min(parts[i][1]+parts[i][3],parts[j][1]+parts[j][3])<=Math.max(parts[i][1],parts[j][1])||Math.min(parts[i][2]+parts[i][4],parts[j][2]+parts[j][4])<=Math.max(parts[i][2],parts[j][2]),id);
 }
 const bad=structuredClone(atlas);bad.slices.ranking.insets=[200,200,80,200];assert.throws(()=>hudSliceRects(bad,'ranking'),/Invalid HUD slices/);
});

test('reusing a skin replaces only its decorative pieces, preserving content and handlers',()=>{
 const {document}=parseHTML('<button><span class="label">Jogar</span><span class="art"></span></button>'),button=document.querySelector('button'),layer=document.querySelector('.art'),label=document.querySelector('.label'),atlas=hudAssets(),click=()=>{};
 button.onclick=click;
 mountHudSkin(layer,'ranking',atlas);assert.equal(layer.children.length,9);
 mountHudSkin(layer,'button-normal',atlas);assert.equal(layer.children.length,3);
 mountHudSkin(layer,'button-normal',atlas);assert.equal(layer.children.length,3);
 assert.equal(button.querySelector('.label'),label);assert.equal(button.onclick,click);assert.equal(button.textContent,'Jogar');
 assert.ok([...layer.children].every(e=>e.getAttribute('aria-hidden')==='true'));
 mountHudSkin(layer,'clock',atlas);assert.equal(layer.children.length,0);assert.equal(layer.classList.contains('hud-sliced'),false);
});

test('seam gutters stay inside the atlas frame and leave fixed corners unchanged',()=>{
 const atlas=hudAssets();for(const id of Object.keys(atlas.slices))for(const [part,rect]of Object.entries(hudSliceRects(atlas,id))){const s=hudSliceSample(atlas,id,part,rect),[,x,y,w,h]=atlas.frames[id];assert.ok(s[1]>=x&&s[2]>=y&&s[1]+s[3]<=x+w&&s[2]+s[4]<=y+h);assert.ok(s[1]<=rect[1]&&s[2]<=rect[2]&&s[1]+s[3]>=rect[1]+rect[3]&&s[2]+s[4]>=rect[2]+rect[4]);if(part.length===2)assert.deepEqual(s,rect);}
 const css=hudSpriteCSS();assert.match(css,/--hud-seam:\.5px/);assert.match(css,/calc\(var\(--hud-cap-l\) - var\(--hud-seam\)\)/);
});

test('both published builds contain the reusable kit and use pixel-based caps',()=>{
 const css=hudSpriteCSS();assert.match(css,/--hud-cap-l:45px/);assert.match(css,/background-image:none!important/);assert.match(css,/!important;transform:scaleX\(-1\)/);
 for(const file of ['docs/index.html','worker/index.js']){const built=fs.readFileSync(file,'utf8');assert.match(built,/mountHudSkin/);assert.match(built,/hud-slice-tl/);}
 const kit=fs.readFileSync('docs/hud-kit.html','utf8');assert.match(kit,/Verificar cantos/);assert.doesNotThrow(()=>new vm.Script(kit.slice(kit.indexOf('<script>')+8,kit.lastIndexOf('</script>'))));
});
