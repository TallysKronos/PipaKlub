import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validateProject,serialize,pixels} from './core.mjs';
import {cloneDocument,extract,transform,compositeAll,addLayer,moveLayer,removeLayer} from './document.mjs';
import {duplicateFrame,deleteFrame,playbackOrder} from './animation.mjs';
import {qualityReport} from './quality.mjs';
import {godotResource} from './godot.mjs';
import {createStorage} from './storage.mjs';
const fixture=JSON.parse(fs.readFileSync(new URL('examples/kael-walk.pixelgen.json',import.meta.url)));
const raw={...fixture,version:1,layers:undefined,frames:fixture.frames.map(({cels,...f})=>f)};
const sample=()=>validateProject(raw);

test('legacy pixels survive migration, layer extraction and serialization',()=>{
 const p=sample();assert.equal(p.version,2);assert.equal(p.layers.length,1);
 p.frames.forEach((f,i)=>assert.deepEqual([...f.indices],raw.frames[i].indices));
 const before=p.frames.map(f=>[...f.indices]);const layer=extract(p,0,0,{x:0,y:0,w:48,h:30},true);
 assert.equal(layer,1);assert.equal(p.layers.length,2);p.frames.forEach((f,i)=>assert.deepEqual([...f.indices],before[i]));
 const restored=validateProject(serialize(p));restored.frames.forEach((f,i)=>{assert.deepEqual([...f.indices],before[i]);assert.deepEqual(f.cels,p.frames[i].cels);});
 assert.ok(restored.frames[0].cels[0].slice(0,48*30).every(v=>v===0));assert.ok(restored.frames[0].cels[1].some(Boolean));
 restored.layers[1].locked=true;assert.throws(()=>transform(restored,0,1,null,'move',1,0),/Desbloqueie/);
 restored.layers[1].visible=false;compositeAll(restored);assert.notDeepEqual([...restored.frames[0].indices],before[0]);
});
test('layer order, removal and cloned documents retain independent data',()=>{
 const p=sample(),q=cloneDocument(p);addLayer(q);q.frames[0].cels[1][0]=1;compositeAll(q);assert.equal(p.frames[0].indices[0],0);assert.equal(q.frames[0].indices[0],1);
 assert.equal(moveLayer(q,1,-1),0);assert.equal(q.layers.length,2);removeLayer(q,0);assert.equal(q.layers.length,1);assert.throws(()=>removeLayer(q,0));
});
test('native selection transforms are reversible and clip at the canvas edge',()=>{
 const p=sample(),original=[...p.frames[0].indices],r={x:5,y:10,w:32,h:40};transform(p,0,0,r,'flip-x');transform(p,0,0,r,'flip-x');assert.deepEqual([...p.frames[0].indices],original);
 transform(p,0,0,r,'flip-y');transform(p,0,0,r,'flip-y');assert.deepEqual([...p.frames[0].indices],original);
 transform(p,0,0,null,'move',100,0);assert.ok(p.frames[0].indices.every(v=>v===0));
});
test('frame insertion and deletion preserve cels and animation bounds',()=>{
 const p=sample();extract(p,0,0,{x:0,y:0,w:48,h:30},true);const i=duplicateFrame(p,1);assert.equal(i,2);assert.equal(p.frames.length,5);assert.equal(p.sequences[0].end,4);
 p.frames[2].cels[1][20]=10;assert.notEqual(p.frames[1].cels[1][20],10);deleteFrame(p,2);assert.equal(p.frames.length,4);assert.equal(p.sequences[0].end,3);
 for(let n=0;n<3;n++)deleteFrame(p,0);assert.equal(p.sequences[0].start,0);assert.equal(p.sequences[0].end,0);assert.throws(()=>deleteFrame(p,0));validateProject(serialize(p));
});
test('forward, reverse, ping-pong and single-shot playback orders are explicit',()=>{
 const s={start:1,end:3,loop:true};assert.deepEqual(playbackOrder(s),[1,2,3]);assert.deepEqual(playbackOrder({...s,direction:'reverse'}),[3,2,1]);assert.deepEqual(playbackOrder({...s,direction:'pingpong'}),[1,2,3,2]);assert.deepEqual(playbackOrder({...s,direction:'pingpong',loop:false}),[1,2,3,2,1]);assert.deepEqual(playbackOrder({start:0,end:0,direction:'pingpong'}),[0]);
});
test('malformed layered projects and invalid ranges fail before editing',()=>{
 const p=serialize(sample());p.frames[0].cels[0][0]=255;assert.throws(()=>validateProject(p),/camada/);assert.throws(()=>validateProject({...raw,sequences:[{start:0,end:100}]}),/Intervalo/);
});
test('quality metrics and Godot export preserve timing and safe resource strings',()=>{
 const p=sample(),report=qualityReport(p);assert.equal(report.frames.length,4);assert.equal(report.sequences[0].totalMs,500);assert.equal(report.sequences[0].groundVariation,0);
 p.sequences[0].direction='pingpong';const tres=godotResource(p,'res://art/kael-sheet.png');assert.match(tres,/type="SpriteFrames"/);assert.match(tres,/"duration": 0.14/);assert.equal((tres.match(/"texture": SubResource/g)||[]).length,6);assert.throws(()=>godotResource(p,'outside.png'),/res:\/\//);
 assert.equal(pixels(p,p.frames[0]).length,48*64*4);
});
test('autosave fallback keeps a recoverable previous revision and reports quota failures',async()=>{
 const values=new Map(),local={getItem:k=>values.get(k),setItem:(k,v)=>values.set(k,v)},s=createStorage(null,local);
 await s.automatic({name:'first'});await s.automatic({name:'second'});assert.equal((await s.restore()).name,'second');assert.equal((await s.restore(true)).name,'first');
 const failed=createStorage(null,{getItem:()=>null,setItem:()=>{throw Error('quota');}});await assert.rejects(failed.automatic({}),/quota/);
});
test('legibility: outline layer, selective outline and contrast report stay inside the palette',async()=>{
 const {addOutline,selectiveOutline,legibilityReport,edgeMask,outsideRing,darker,contrast}=await import('./legibility.mjs');
 const p=sample(),before=p.frames.map(f=>[...f.indices]),w=p.width,h=p.height;
 const ring=outsideRing(p.frames[0].indices,w,h);assert.ok(ring.some(Boolean));ring.forEach((v,i)=>{if(v)assert.equal(p.frames[0].indices[i],0);});
 const layer=addOutline(p,{frames:0});assert.equal(p.layers[layer].name,'Contorno');assert.equal(p.layers.length,2);
 p.frames[0].indices.forEach((v,i)=>{if(before[0][i])assert.equal(v,before[0][i]);});assert.deepEqual([...p.frames[1].indices],before[1]);
 p.layers[layer].visible=false;compositeAll(p);assert.deepEqual([...p.frames[0].indices],before[0]);
 const q=sample(),edge=edgeMask(q.frames[0].indices,w,h),changed=selectiveOutline(q,0,{frames:0});assert.ok(changed>0);
 q.frames[0].indices.forEach((v,i)=>{if(!edge[i])assert.equal(v,before[0][i]);else if(v!==before[0][i])assert.ok(contrast(q.palette[v],[0,0,0])<=contrast(q.palette[before[0][i]],[0,0,0]));});
 for(let i=1;i<q.palette.length;i++)assert.ok(darker(q.palette,i)>0);
 const r=legibilityReport(sample());assert.equal(r.frames.length,4);assert.ok(r.darkEdge>=0&&r.darkEdge<=1);assert.deepEqual(Object.keys(r.grounds).sort(),['calcada','grama','noite','terra']);
 const outlined=legibilityReport(p,{frames:0});assert.ok(outlined.darkEdge>=legibilityReport(sample(),{frames:0}).darkEdge);
});
