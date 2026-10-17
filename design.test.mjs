import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {artConfig} from './scripts/art-build.mjs';
import {createTrails} from './src/trails.js';
function renderer(reduced=false){const draws=[],config=artConfig(),context=vm.createContext({matchMedia:()=>({matches:reduced}),Image:class{set src(value){queueMicrotask(()=>this.onload());}}});vm.runInContext(fs.readFileSync('src/art-client.js','utf8').replace('export function','function'),context);const art=context.createArtAssets(config);return {art,config,draws,ctx:{imageSmoothingEnabled:true,drawImage(...a){draws.push(a);},save(){},restore(){},translate(){},scale(){}}};}
test('all new pack images are registered, shipped and use integer rectangles inside their real PNG',()=>{
 const config=artConfig(),pack=JSON.parse(fs.readFileSync('assets/packs/auditoria-v1/manifest.json','utf8'));assert.equal(pack.integrated,true);
 for(const entry of pack.entries){const atlas=Object.values(config.atlases).find(a=>a.meta.image===entry.meta.image);assert.ok(atlas,entry.id);const bytes=fs.readFileSync('assets/'+entry.meta.image);assert.equal(bytes.readUInt32BE(16),atlas.meta.size.w);assert.equal(bytes.readUInt32BE(20),atlas.meta.size.h);assert.deepEqual(fs.readFileSync('docs/assets/'+entry.meta.image),bytes);
  for(const {frame:r}of Object.values(atlas.frames)){assert.ok(Object.values(r).every(Number.isInteger));assert.ok(r.x>=0&&r.y>=0&&r.x+r.w<=atlas.meta.size.w&&r.y+r.h<=atlas.meta.size.h);}
 }
 assert.equal(config.atlases.kael,undefined,'Kael remains out of the game');
});
test('four basic species render each real state and mirror while reduced motion holds the frame',async()=>{
 for(const reduced of [false,true]){const {art,config,draws,ctx}=renderer(reduced);for(let colour=0;colour<4;colour++){const id=config.designs.basics[colour],atlas=art.atlases[id];await art.load(id);assert.equal(art.basic(colour),id);
  for(const [state,player,victory]of [['idle',{},false],['flight',{input:{x:1}},false],['skill',{skillCooldown:6.8},false],['hurt',{hitFlash:.2},false],['victory',{},true]]){
   art.creature(ctx,colour,300,0,0,112,{...player,facing:-1},victory);const actual=draws.at(-1).slice(1,5);assert.ok(atlas.animations[state].some(key=>JSON.stringify(Object.values(atlas.frames[key].frame))===JSON.stringify(actual)),id+' '+state);assert.equal(ctx.imageSmoothingEnabled,true);
   if(reduced){art.creature(ctx,colour,600,0,0,112,{...player,facing:-1},victory);assert.deepEqual(draws.at(-1).slice(1,5),actual);}
  }
 }}
});
test('backgrounds cover the arena without distortion and icon lookup refuses unknown frames',async()=>{
 const {art,config,ctx,draws}=renderer();for(const id of Object.values(config.designs.scenes)){await art.load(id);assert.equal(art.background(ctx,id,0,0,1000,600),true);const args=draws.at(-1);assert.ok(Math.abs(args[3]/args[4]-1000/600)<1e-9);assert.deepEqual(args.slice(5),[0,0,1000,600]);}
 for(const id of ['coin','locked','completed','boss','trade','summon','tail-ready','tail-damaged','wind','wax','rain','fog'])assert.match(art.icon(id),/simbolos-12-v1\.png\?v=/);
 assert.equal(art.icon('<img src=x>'),'');assert.equal(await art.load('missing'),false);
});
test('leaders use the expected trails while stage ids, opponents species and first-clear drops stay stable',()=>{
 const trails=createTrails();assert.deepEqual(trails.trails.map(t=>t.leaderName),['Mikka','Lohan','Kleie']);assert.deepEqual(trails.stages.filter(s=>s.boss).map(s=>[s.id,s.drop,s.foes[0].soul||null,s.level,s.coins]),[['morro-5','rabiola-raio-de-sol',null,4,30],['praia-5','rabiola-chaspiral','chaspiral',6,50],['torres-5','rabiola-flautrevo','flautrevo',8,80]]);
});

test('user supplied Javali keeps all sixteen exact cells, a stable scale and no neighbour sampling',async()=>{
 const {art,config,ctx,draws}=renderer(),a=config.atlases['javali-biscoito'];await art.load('javali-biscoito');
 assert.deepEqual(a.meta.size,{w:1254,h:1254});assert.equal(Object.keys(a.frames).length,16);
 const cuts=[0,314,627,941,1254];let area=0;
 for(let i=0;i<16;i++){const key='javali-biscoito_'+String(i).padStart(2,'0'),f=a.frames[key].frame,col=i%4,row=Math.floor(i/4);assert.deepEqual(f,{x:cuts[col],y:cuts[row],w:cuts[col+1]-cuts[col],h:cuts[row+1]-cuts[row]});area+=f.w*f.h;
  assert.equal(art.draw(ctx,'javali-biscoito',key,0,0,314,314),true);const r=draws.at(-1).slice(1);assert.deepEqual(r.slice(0,4),[f.x,f.y,f.w,f.h]);assert.deepEqual(r.slice(4),[0,0,f.w,f.h],'one common pixel scale, no per-pose zoom');
 }
 assert.equal(area,1254*1254);assert.deepEqual(Object.values(a.animations).map(seq=>seq.length),[4,4,4,2,2]);
 for(const [state,p,victory]of [['idle',{},false],['flight',{input:{x:1}},false],['skill',{skillCooldown:6.8},false],['hurt',{hitFlash:.2},false],['victory',{},true]]){art.creature(ctx,1,300,0,0,112,{...p,soul:'javali-biscoito',facing:-1},victory);const rect=draws.at(-1).slice(1,5);assert.ok(a.animations[state].some(key=>JSON.stringify(Object.values(a.frames[key].frame))===JSON.stringify(rect)),state);}
 assert.ok(config.dex.entries.find(e=>e.id==='javali-biscoito'));assert.deepEqual(fs.readFileSync('assets/'+a.meta.image),fs.readFileSync('docs/assets/'+a.meta.image));
});
