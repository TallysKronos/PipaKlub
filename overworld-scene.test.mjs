import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {overworldScene} from './src/overworld-scene.js';
import {veredasTerrainPlan} from './src/veredas-region-renderer.js';
const sets={'rascunho.tsj':JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj','utf8'))};
const pilot=()=>JSON.parse(fs.readFileSync('art/overworld/mapas/veredas-piloto.tmj','utf8'));
// Caminho no grafo de navegação do jogo (o mesmo do clique para andar).
function route(scene,to){const adj=scene.nodes.map(()=>[]);for(const [a,b] of scene.edges){adj[a].push(b);adj[b].push(a);}const prev=new Map([[scene.spawn,-1]]),q=[scene.spawn];
 for(let i=0;i<q.length;i++)for(const b of adj[q[i]])if(!prev.has(b)){prev.set(b,q[i]);q.push(b);}if(!prev.has(to))return null;const path=[];for(let n=to;n>=0;n=prev.get(n))path.unshift(n);return path;}
test('a planta piloto vira cena do jogo com escada, ponte, água e saídas',()=>{
 const scene=overworldScene(pilot(),sets,{id:'veredas-piloto'}),walk=scene.tiled.layers.Walkable;
 assert.equal(scene.width,36*64);assert.equal(scene.height,30*64);assert.ok(scene.isometric);
 const stair=walk.filter(r=>r.properties.connects_to===1);assert.deepEqual(stair.map(r=>[r.x,r.y,r.w,r.h]),[[512,704,128,64]]);assert.equal(stair[0].properties.rise_to,96);
 assert.ok(walk.some(r=>r.properties.level===1&&r.properties.elevation===96));
 assert.deepEqual(scene.places.filter(p=>p.action==='street_scene').map(p=>p.target).sort(),['park-clearing','park-veredas']);
 const plan=veredasTerrainPlan(scene);assert.equal(plan.bridges.length,1);
 const water=scene.veredas.water.find(w=>plan.bridges[0].y>=w.y&&plan.bridges[0].y<w.y+w.h&&plan.bridges[0].x<w.x+w.w);assert.ok(water,'ponte sobre a água');assert.equal(plan.bridges[0].x,water.x-24);
 assert.ok(plan.cliffs.length>0);assert.ok(!plan.cliffs.some(e=>e.axis==='x'&&e.y===704&&e.x<640&&e.x+e.w>512),'barranco atravessa a boca da rampa');
});
test('o baú do mirante só é alcançado pela rampa, e a Nina pela ponte',()=>{
 const scene=overworldScene(pilot(),sets,{id:'veredas-piloto'}),levels=scene.tiled.levels,walk=scene.tiled.layers.Walkable;
 const chest=scene.places.find(p=>p.name==='Baú do mirante'),path=route(scene,chest.node);assert.ok(path,'baú inalcançável');assert.equal(levels[chest.node],1);
 const inStair=n=>{const [x,y]=scene.nodes[n];return walk.some(r=>r.properties.connects_to===1&&x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h);};assert.ok(path.some(inStair),'caminho sem a rampa');
 const nina=scene.places.find(p=>p.name==='Nina'),onBridge=n=>{const [x,y]=scene.nodes[n];return walk.some(r=>r.properties.ground_frame==='bridge'&&x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h);};assert.ok(route(scene,nina.node).some(onBridge),'caminho sem a ponte');
 // Baú e Nina ocupam a célula: o jogador fala de uma vizinha, sem pisar em cima.
 for(const name of ['Baú do mirante','Nina']){const solid=scene.tiled.layers.Solids.find(s=>s.name===name),[x,y]=scene.nodes[scene.places.find(p=>p.name===name).node];assert.ok(!(x>=solid.x&&x<=solid.x+solid.w&&y>=solid.y&&y<=solid.y+solid.h),name);}
});
test('o conversor recusa o que o jogo ainda não desenha',()=>{
 const map=pilot(),alt=map.layers.find(l=>l.name==='altura');alt.data[11*36+8]=21;alt.data[11*36+9]=21;
 assert.throws(()=>overworldScene(map,sets,{id:'x'}),/Overworld x:/);
 // Rampa u- válida na planta (sobe do 13,8 para o mirante), mas o jogo só sobe para o fundo (v-).
 const side=pilot();side.layers.find(l=>l.name==='altura').data[8*36+13]=22;
 assert.throws(()=>overworldScene(side,sets,{id:'x'}),/rampa u- /);
});
