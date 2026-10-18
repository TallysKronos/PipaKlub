import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import {zip} from './zip.js';
const root=new URL('../../',import.meta.url),read=p=>JSON.parse(fs.readFileSync(new URL(p,root),'utf8'));
let source=fs.readFileSync(new URL('./model.js',import.meta.url),'utf8');
for(const file of ['world-map.js','world-art.js'])source=source.replace('/src/'+file,pathToFileURL(new URL('src/'+file,root).pathname.replace(/^\/(?=[A-Z]:)/,'' )).href);
const model=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
const sample=()=>({schema:'pipaklub-atelier',version:1,name:'Teste local',kit:read('assets/world/morro-kit-v1/manifest.json'),map:read('assets/world/morro-pilot/blockout.tmj'),layout:read('assets/world/morro-pilot/art.json'),images:{}});
test('editor roundtrips actual Tiled pilot and leaves encounter identities intact',()=>{
 const project=sample(),scene=model.compile(JSON.parse(JSON.stringify(project)));
 assert.deepEqual(scene.places.filter(p=>p.stage).map(p=>p.stage),['morro-1','morro-2']);assert.ok(scene.art.objects.length>20);
 const item=model.place(project,'bench',1000,720,'object',0);assert.equal(model.validate(project).ok,true);
 model.move(project,item,-32,0);assert.equal(project.layout.bindings[item.id].footX,968);
 model.remove(project,item);assert.equal(project.layout.bindings[item.id],undefined);assert.equal(model.validate(project).ok,true);
});
test('new project compiles, invalid circulation prevents export, and undo restores a collision edit',()=>{
 const project=model.blankProject(sample().kit),history=new model.History();assert.ok(model.compile(project));
 history.push(project);const wall=model.rect(project,'Solids',{x:32,y:32,w:960,h:704},{level:0});project.layout.bindings[wall.id]={hidden:true};
 assert.equal(model.validate(project).ok,false);const restored=history.undo(project);assert.equal(model.validate(restored).ok,true);assert.equal(model.validate(history.redo(restored)).ok,false);
});
test('external references, bad crops, unsafe repeats and oversized maps fail before render',()=>{
 const p=sample();p.kit.frames['custom']={sheet:'ground',x:1200,y:1200,w:200,h:200,anchor:{x:.5,y:1}};assert.throws(()=>model.validateProject(p),/Recorte/);
 const q=sample();q.kit.sheets.ground.image='https://example.com/private.png';assert.throws(()=>model.validateProject(q),/Folha sem imagem local/);
 const r=sample();r.map.width=9999999;assert.throws(()=>model.validateProject(r),/mapa ortogonal/);
 const s=sample();s.layout.bindings[5].repeat='x';s.layout.bindings[5].step=0;assert.throws(()=>model.validateProject(s),/inválida|inválido/);
});
test('PNG imports stay embedded in a project and custom ground metadata survives compile',()=>{
 assert.deepEqual([...model.pngBytes('data:image/png;base64,iVBORw==')],[137,80,78,71]);
 const p=model.blankProject(sample().kit);p.images.custom='data:image/png;base64,AAAA';p.kit.sheets.custom={image:'world/atelier/custom.png',width:64,height:64};p.kit.frames.custom={sheet:'custom',x:0,y:0,w:64,h:64,anchor:{x:.5,y:1},layer:'ground'};
 model.prop(model.layer(p,'Walkable').objects[0],'ground_frame','custom');assert.equal(model.compile(p).tiled.layers.Walkable[0].properties.ground_frame,'custom');
});
test('ZIP produces a complete local file containing Unicode names and exact bytes',async()=>{
 const blob=zip([['pipa/peça.json','{"mapa":"sol"}'],['assets/a.png',Uint8Array.of(137,80,78,71)]]),buf=Buffer.from(await blob.arrayBuffer());
 assert.equal(buf.readUInt32LE(0),0x04034b50);assert.equal(buf.readUInt32LE(buf.length-22),0x06054b50);assert.equal(buf.readUInt16LE(buf.length-14),2);
 fs.mkdirSync(new URL('.local/',root),{recursive:true});fs.writeFileSync(new URL('.local/atelier-test.zip',root),buf);
});
