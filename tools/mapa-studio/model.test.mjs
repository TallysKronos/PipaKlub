import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {parseTiled,audit,verdict,canStep,findPath,heightAt,cliffs,reachable} from './model.mjs';
const tileset=JSON.parse(fs.readFileSync(new URL('../../art/overworld/tiles/rascunho.tsj',import.meta.url))),sets={'rascunho.tsj':tileset};
const G={'.':1,'#':2,'m':3,'~':4,'R':5,'=':6,'p':7};
// Mapa a partir de texto: linhas = v, colunas = u. Altura: dígito = nível, < > ^ v = rampa (u-, u+, v-, v+).
function map(ground,height=null,{events=[['entrada',0,0]],pieces=[]}={}){
 const rows=ground.trim().split('\n').map(r=>r.trim()),H=rows.length,W=rows[0].length,hr=height?.trim().split('\n').map(r=>r.trim());
 const ramp={'>':21,'<':22,'v':23,'^':24},lvl={'1':17,'2':18,'3':19};
 const chao=rows.flatMap(r=>[...r].map(ch=>G[ch])),altura=hr?hr.flatMap(r=>[...r].map(ch=>ramp[ch]||lvl[ch]||0)):Array(W*H).fill(0);
 const obj=(list)=>list.map(([type,u,v,props={}],i)=>({id:i+1,name:props.name||type,type,x:(u+.5)*32,y:(v+.5)*32,point:true,properties:Object.entries(props).map(([name,value])=>({name,value}))}));
 return parseTiled({orientation:'isometric',tilewidth:64,tileheight:32,width:W,height:H,tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],
  layers:[{type:'tilelayer',name:'chao',data:chao},{type:'tilelayer',name:'altura',data:altura},{type:'objectgroup',name:'pecas',objects:obj(pieces).map(o=>({...o,type:'peca'}))},{type:'objectgroup',name:'eventos',objects:obj(events)}]},sets);
}
const fails=m=>audit(m).filter(i=>i.level==='fail').map(i=>i.rule);
test('lê só mapas isométricos 64×32 e entende chão, altura e objetos',()=>{
 assert.throws(()=>parseTiled({orientation:'orthogonal',tilewidth:64,tileheight:32}),/isométrico/);
 assert.throws(()=>parseTiled({orientation:'isometric',tilewidth:32,tileheight:16}),/64×32/);
 const m=map('..#\n.~=',null,{pieces:[['peca',0,1,{asset:'arvore'}]]});assert.equal(m.cells[2].material,'terra');assert.equal(m.cells[5].material,'ponte');assert.equal(m.pieces[0].asset,'arvore');assert.deepEqual([m.spawn.u,m.spawn.v],[0,0]);
});
test('rampa liga os dois níveis só no sentido da seta; o lado é barranco',()=>{
 const m=map('.....\n.....\n.....\n.....','11111\n11111\n..^..\n.....');
 // Rampa em (2,2) sobe para v- até (2,1), que é nível 1.
 assert.equal(canStep(m,{u:2,v:2},{u:2,v:1}),true);assert.equal(canStep(m,{u:1,v:2},{u:1,v:1}),false);
 assert.equal(canStep(m,{u:2,v:2},{u:1,v:2}),false);assert.equal(fails(m).length,0);
 assert.ok(findPath(m,{u:0,v:2},{u:0,v:0}));assert.equal(heightAt(m,2.5,2.5),.5);
 // A face do barranco some só onde a rampa encosta.
 const faces=cliffs(m).filter(c=>c.side==='v');assert.equal(faces.length,4);assert.ok(!faces.some(f=>f.u===2));
 const bad=map('.....\n.....\n.....\n.....','.....\n.....\n..^..\n.....');assert.ok(fails(bad).includes('Rampa'));
});
test('ponte precisa encostar em terra firme nas duas pontas',()=>{
 const ok=map('..~~..\n.====.\n..~~..');assert.equal(fails(ok).length,0);
 const half=map('..~~~.\n.===~.\n..~~~.',null,{events:[['entrada',0,1]]});assert.ok(fails(half).includes('Ponte'));
});
test('evento sem acesso reprova; área isolada avisa',()=>{
 const m=map('....~...\n....~...\n....~...',null,{events:[['entrada',0,0],['npc',7,1,{name:'Nina'}]]});
 const items=audit(m);assert.ok(items.some(i=>i.rule==='Acesso'&&i.level==='fail'&&/Nina/.test(i.text)));assert.ok(items.some(i=>i.rule==='Acesso'&&i.level==='warn'));
 assert.equal(reachable(m,m.spawn).reduce((s,x)=>s+x,0),12);
});
test('árvore bloqueia a célula; baú precisa ser alcançável',()=>{
 const m=map('...\n...',null,{pieces:[['peca',1,0,{asset:'arvore'}],['peca',2,1,{asset:'bau',interacao:'abrir'}]]});
 assert.equal(canStep(m,{u:0,v:0},{u:1,v:0}),false);assert.equal(fails(m).length,0);
 const shut=map('.~.\n.~R',null,{pieces:[['peca',2,0,{asset:'bau',interacao:'abrir'}]]});assert.ok(fails(shut).includes('Acesso'));
});
test('o mapa piloto das Veredas passa na conferência',()=>{
 const m=parseTiled(JSON.parse(fs.readFileSync(new URL('../../art/overworld/mapas/veredas-piloto.tmj',import.meta.url))),sets);
 assert.equal(verdict(audit(m)),'ok',JSON.stringify(audit(m)));assert.ok(cliffs(m).length>0);
 const chest=m.pieces.find(p=>p.name==='Baú do mirante');assert.ok(findPath(m,m.spawn,{u:chest.u,v:chest.v+1}));
});
