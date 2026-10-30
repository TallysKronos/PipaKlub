import test from 'node:test';
import assert from 'node:assert/strict';
import {auditZeroBreak,wideEdge,wideReachable} from './conferencia-bosque.mjs';
const cell=(material='terra',level=0)=>({material,level,ramp:null});
function model(w=8,h=8){const spawn={type:'entrada',name:'entrada',u:1,v:1,props:{}};return {name:'Teste',w,h,cells:Array.from({length:w*h},()=>cell()),pieces:[],events:[spawn,...Array.from({length:3},(_,i)=>({id:i+2,type:'item',name:'Item '+i,u:2+i,v:2,props:{item:'papel-seda',visibilidade:i?'visivel':'escondido'}}))],spawn};}
const rules=(m,options={})=>auditZeroBreak(m,options).issues.filter(i=>i.level==='fail').map(i=>i.rule);
const fill=(m,u,v,c)=>m.cells[v*m.w+u]=c;
test('two-lane check rejects a one-cell throat even when both rooms are reachable',()=>{
 const m=model();for(let v=0;v<m.h;v++)if(v!==3)fill(m,4,v,cell('rocha'));
 assert.equal(wideEdge(m,{u:3,v:3},{u:4,v:3}),false);assert.equal(wideReachable(m,{u:2,v:3}).has(3*m.w+6),false);
 assert.ok(rules(m,{requiredRoute:[{u:2,v:3},{u:6,v:3}]}).includes('Corredor estreito'));
 fill(m,4,4,cell());assert.equal(wideReachable(m,{u:2,v:3}).has(3*m.w+6),true);
});
test('forbidden ramps, isolated raised cells, and single-cell unreachable pockets are errors',()=>{
 const m=model();fill(m,3,3,{...cell(),ramp:'u+'});fill(m,5,5,cell('grama',1));
 const result=rules(m,{requiredRoute:[]});assert.ok(result.includes('Rampa para a câmera'));assert.ok(result.includes('Degrau solto'));assert.ok(result.includes('Bolsão inalcançável'));
});
test('ramps require terrain at the foot, two landing cells, and no decorative or event obstruction',()=>{
 const m=model();for(let v=0;v<3;v++)for(let u=0;u<8;u++)fill(m,u,v,cell('grama',1));
 fill(m,3,3,{...cell(),ramp:'v-'});fill(m,3,4,cell('grama'));m.pieces.push({id:9,name:'Mureta',asset:'mureta',u:3,v:2,fu:1,fv:1,blocks:false});m.events.push({id:8,type:'item',name:'Item na boca',u:3,v:3,props:{}});
 const result=rules(m,{requiredRoute:[]});assert.ok(result.includes('Pé da rampa'));assert.ok(result.includes('Mureta cruzando acesso'));assert.ok(result.includes('Evento sobre acesso'));
 fill(m,3,4,cell());m.pieces=[];m.events.pop();assert.ok(!rules(m,{requiredRoute:[]}).includes('Pé da rampa'));
 fill(m,3,1,cell('bosque',1));assert.ok(rules(m,{requiredRoute:[]}).includes('Chegada da rampa'));
});
test('regional audit verifies three parts, reciprocal exits, direction, material and elevation',()=>{
 const region=['A','B','C'].map(part=>({id:'area-'+part.toLowerCase(),part,map:model()}));
 const exit=(r,dest,u,v)=>r.map.events.push({type:'saida',name:'Saída',u,v,props:{destino:dest}});
 exit(region[0],region[1].id,4,1);exit(region[1],region[0].id,4,6);exit(region[1],region[2].id,5,1);exit(region[2],region[1].id,5,6);
 const links=[{from:{area:'area-a',u:4,v:1,direction:'v-'},to:{area:'area-b',u:4,v:6,direction:'v+'}},{from:{area:'area-b',u:5,v:1,direction:'v-'},to:{area:'area-c',u:5,v:6,direction:'v+'}}];
 let result=rules(region[0].map,{region,links,requiredRoute:[]});assert.ok(!result.some(r=>/Ligação|ligação|região/.test(r)));
 links[0].to.direction='v-';fill(region[1].map,4,6,cell('piso',1));region[2].map.events=region[2].map.events.filter(e=>e.type!=='saida');
 result=rules(region[0].map,{region,links,requiredRoute:[]});for(const r of ['Direção de ligação','Cota/material da ligação','Ligação entre partes'])assert.ok(result.includes(r),r);
 assert.ok(rules(region[0].map,{region:region.slice(0,2),links,requiredRoute:[]}).includes('Partes da região'));
});
test('items and tree density remain explicit warnings; inaccessible items are errors',()=>{
 const m=model(30,20);m.events=m.events.slice(0,1);for(const [u,v]of [[3,3],[6,3],[9,3]])m.pieces.push({id:u,name:'Árvore',asset:'arvore',u,v,fu:1,fv:1,blocks:true});
 let report=auditZeroBreak(m,{requiredRoute:[]});for(const rule of ['Itens por parte','Item escondido','Platôs','Árvore solta'])assert.ok(report.issues.some(i=>i.rule===rule&&i.level==='warn'),rule);
 m.events.push({type:'item',name:'Ilha',u:20,v:10,props:{}});for(const [du,dv]of [[1,0],[-1,0],[0,1],[0,-1],[0,0]])fill(m,20+du,10+dv,cell('rocha'));assert.ok(rules(m,{requiredRoute:[]}).includes('Item inalcançável'));
 assert.match(report.lines[0],/CONFERÊNCIA ZERO QUEBRA/);
});
