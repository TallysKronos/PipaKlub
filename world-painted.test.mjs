import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {parseWorldMap,worldRenderQueue,drawWorldObject} from './src/world-map.js';
import {createWorldNavigation} from './src/world-navigation.js';
import {validateWorldPaintedImages,drawWorldPaintedGround} from './src/world-art.js';
import {artConfig} from './scripts/art-build.mjs';
const root='assets/world/morro-plaza-v1/',read=()=>JSON.parse(fs.readFileSync(root+'plaza.tmj')),sheets=JSON.parse(fs.readFileSync(root+'manifest.json')).sheets;
function scene(){return Object.assign(validateWorldPaintedImages(parseWorldMap(read()),sheets),{painted:true});}

test('native Tiled images match published PNG dimensions and the foreground has real alpha',async()=>{
 const s=scene(),config=artConfig();assert.equal(s.width,1536);assert.equal(s.height,1024);assert.equal(s.tiled.images.length,2);
 const {createAssetHandler}=await import('./src/static-assets.js'),handler=createAssetHandler();
 for(const [id,image]of Object.entries(sheets)){const b=fs.readFileSync('assets/'+image.image);assert.equal(b.readUInt32BE(16),image.width);assert.equal(b.readUInt32BE(20),image.height);if(id.endsWith('tree'))assert.equal(b[25],6);const asset=config.courtyard.images['world-kit-'+id];assert.match(asset.url,/\?v=[a-f0-9]{12}$/);const r=await handler(new Request('http://test/'+asset.url,{method:'HEAD'}));assert.equal(r.status,200);assert.match(r.headers.get('cache-control'),/immutable/);}
 assert.equal(config.courtyard.world.scenes.morro.places.filter(p=>p.stage).length,5);assert.equal(config.courtyard.world.paintedPilot.places.filter(p=>p.stage).length,2);
});

test('entry, workshop, stair landing and exit are connected with safe feet and follower',()=>{
 const s=scene(),nav=createWorldNavigation(s),a=nav.create();
 for(const place of [...s.places.filter(p=>p.action==='pilot_story'),...s.places.filter(p=>p.stage==='morro-2'),...s.places.filter(p=>p.action==='quintal')]){
  assert.ok(nav.target(a,nav.nodes[place.node]).length);let steps=0;while(a.path.length&&steps++<3000){nav.step(a,.1);assert.ok(nav.geometry.safe(a));assert.ok(nav.geometry.safe(nav.follower(a)));}assert.ok(steps<3000);assert.deepEqual({x:a.x,y:a.y},nav.nodes[place.node]);
 }
 const before=structuredClone(a.path);assert.deepEqual(nav.target(a,{x:1000,y:400}),[]);assert.deepEqual(a.path,before);assert.match(a.navigationMessage,/bloqueada/);
});

test('painted walls cannot be crossed as a shortcut between heights',()=>{
 const s=scene(),n=createWorldNavigation(s),g=n.geometry;assert.ok(!g.safe({x:600,y:400}));assert.ok(!g.segment({x:848,y:592},{x:1056,y:208}));assert.ok(g.segment({x:848,y:560},{x:848,y:208}));
});

test('foreground roof and tree sort around feet; tree fades only for its own floor',()=>{
 const s=scene(),q=worldRenderQueue(s,[{id:'player',x:1200,y:640,level:0},{id:'front',x:1200,y:832,level:0}]),tree=q.findIndex(e=>e.kind==='painted');
 assert.ok(q.findIndex(e=>e.id==='player')<tree);assert.ok(q.findIndex(e=>e.id==='front')>tree);assert.equal(q[tree].opacity,.55);
 assert.equal(worldRenderQueue(s,[{id:'player',x:1200,y:640,level:1}]).find(e=>e.kind==='painted').opacity,1);
 const roof=worldRenderQueue(s,[{id:'behind',x:280,y:784,level:0},{id:'front',x:280,y:848,level:0}]);const ri=roof.findIndex(e=>e.rect?.name==='Cobertura do portao');assert.ok(roof.findIndex(e=>e.id==='behind')<ri&&roof.findIndex(e=>e.id==='front')>ri);
});

test('image paths, repeat, bad dimensions, unsupported parallax and unknown registered assets fail builds',()=>{
 for(const patch of [{image:'../secret.png'},{image:'https://x.test/a.png'},{repeatx:true},{parallaxx:.5},{imagewidth:2000},{properties:[{name:'sheet',value:'unknown'},{name:'render',value:'ground'},{name:'level',value:0}]}]){const m=read();Object.assign(m.layers[0],patch);assert.throws(()=>validateWorldPaintedImages(parseWorldMap(m),sheets));}
 const m=read();m.layers.at(-1).properties.find(p=>p.name==='level').value=7;assert.throws(()=>parseWorldMap(m),/piso de imagem/);
});

test('painted draw restores alpha and draws ground before depth without painting collision masks',()=>{
 const s=scene(),calls=[],g={globalAlpha:1,fillRect(){},save(){this.saved=this.globalAlpha;},restore(){this.globalAlpha=this.saved;},drawImage(...args){calls.push(args);}},images=new Map(Object.keys(sheets).map(id=>['world-kit-'+id,{id}]));
 drawWorldPaintedGround(g,s,images);assert.equal(calls.length,1);assert.equal(calls[0][0].id,'plaza-slice-base');
 drawWorldObject(g,worldRenderQueue(s,[]).find(e=>e.kind==='painted'),images);assert.equal(calls.at(-1)[0].id,'plaza-slice-tree');assert.equal(g.globalAlpha,1);
 const before=calls.length;drawWorldObject(g,worldRenderQueue(s,[]).find(e=>e.rect?.name==='Contencao oeste'),images);assert.equal(calls.length,before);
});
