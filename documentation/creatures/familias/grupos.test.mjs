import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

const atlas=readFileSync(new URL('./grupos.html',import.meta.url),'utf8');
const payload=JSON.parse(atlas.match(/<script id="catalog-data" type="application\/json">([\s\S]*?)<\/script>/)[1]);
const app=atlas.match(/<script>\s*('use strict';[\s\S]*?)<\/script>/)[1];
function runtime(){
  const elements=new Map();
  const element=id=>elements.get(id)||elements.set(id,{value:'',innerHTML:'',textContent:'',listeners:{},addEventListener(event,fn){this.listeners[event]=fn},scrollIntoView(){}}).get(id);
  const context=vm.createContext({URLSearchParams,console,history:{replaceState(){}},location:{hash:''},document:{getElementById(id){return id==='catalog-data'?{textContent:JSON.stringify(payload)}:element(id)},querySelectorAll(){return []},querySelector(){return element('main')},addEventListener(){}}});
  vm.runInContext(app,context);
  return {context,element,run:code=>vm.runInContext(code,context)};
}
test('charts repetidos não duplicam Rabbito ou as identidades do catálogo',()=>{
  assert.equal(payload.family_context.filter(f=>f.id==='rabbito').length,1);
  assert.equal(payload.records.length,payload.counts.unique_records);
  assert.equal(new Set(payload.records.map(n=>n.key)).size,payload.records.length);
  assert.equal(payload.records.filter(n=>n.id==='rabbito').length,1);
});
test('sobreposição Yaguarion preserva uma ficha em cavaleiros e mumificados',()=>{
  const n=payload.records.find(n=>n.id==='yaguarion');
  assert.ok(n.group_ids.includes('cavaleiros'));
  assert.ok(n.group_ids.includes('mumificados'));
  assert.equal(payload.records.filter(r=>r.key===n.key).length,1);
});
test('apelidos compartilhados permanecem separados por família',()=>{
  const brotins=payload.records.filter(n=>n.id==='brotim');
  assert.equal(brotins.length,2);assert.notEqual(brotins[0].key,brotins[1].key);
  const rt=runtime();rt.run("q.value='raivela';render()");
  assert.equal(rt.run('filtered().length'),2);
});
test('busca sem acento encontra a família Cervoráculo',()=>{
  const rt=runtime();rt.run("q.value='cervoraculo';render()");
  assert.equal(rt.run('filtered().length'),4);
});
test('filtro bebê nos mumificados exibe as cinco linhagens, não cavaleiros adultos',()=>{
  const rt=runtime();rt.run("chooseGroup('mumificados');stage.value='1';render()");
  assert.equal(rt.run('filtered().length'),5);
  assert.ok(rt.element('content').innerHTML.includes('Yaguim'));
  assert.ok(!rt.element('content').innerHTML.includes('<h3>Yaguarion</h3>'));
});
test('Conde aponta para v2 aprovado e não é estado possuído',()=>{
  const n=payload.records.find(n=>n.id==='rabbito-conde-da-ultima-hora');
  assert.ok(n.art.includes('/concept-v2/'));assert.match(n.status,/Aprovado/);
  assert.ok(!n.group_ids.includes('estados-narrativos'));
  const rt=runtime();rt.run("q.value='Conde da Última Hora';render()");
  assert.equal(rt.run('filtered().length'),1);
});
test('linhagem de Rabbito inclui suas duas novas alternativas, sem repetir bases',()=>{
  const rt=runtime();rt.run("activeFamily='rabbito';render()");
  assert.equal(rt.run('filtered().length'),8);
  assert.ok(rt.element('content').innerHTML.includes('Velocista Relâmpago'));
  assert.ok(rt.element('content').innerHTML.includes('Conde da Última Hora'));
});
test('entrelaços têm apenas dois resultados e reservas não entram nos Lords',()=>{
  const rt=runtime();rt.run("chooseGroup('entrelacos');kind.value='interweaving';render()");
  assert.equal(rt.run('filtered().length'),2);
  const lords=payload.groups.find(g=>g.id==='lords');assert.equal(lords.member_keys.length,32);
  assert.ok(!lords.member_keys.some(k=>k.includes('mantigardo')));
});
test('planilha de povoamento reserva decisões de área para o autor',()=>{
  const csv=readFileSync(new URL('./Plano-de-povoamento.csv',import.meta.url),'utf8').trim().split(/\r?\n/);
  assert.equal(csv.length,payload.records.length+1);assert.ok(csv[0].includes('Área a planejar'));
  for(const row of csv.slice(1))assert.ok(row.endsWith(';;;;'));
});
test('os quatro Demons mantêm as duas formas adultas com origem no mesmo jovem',()=>{
  const group=payload.groups.find(g=>g.id==='demons-do-folclore');
  assert.equal(group.member_keys.length,20);
  const rt=runtime();
  for(const [family,young,original,alternate] of [
    ['saciventim','Ventapulo','Rodamastro','Redemastro'],
    ['contrapira','Rastroavesso','Matavolta','Virarraiz'],
    ['lunarrufo','Umbrauivo','Lobumbrário','Eclipsarro'],
    ['botolume','Dobramaré','Festarrio','Vazantério'],
  ]){
    rt.run(`activeFamily=${JSON.stringify(family)};render()`);
    assert.equal(rt.run('filtered().length'),5);
    const html=rt.element('content').innerHTML;
    assert.ok(html.includes(young+' → '+original));
    assert.ok(html.includes(young+' → '+alternate));
  }
});
