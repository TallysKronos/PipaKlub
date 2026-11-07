// Sintaxe e comportamento de filtros/comparação com DOM mínimo, sem simular renderização.
import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const d=path.dirname(fileURLToPath(import.meta.url)),page=fs.readFileSync(path.join(d,'index.html'),'utf8');
const script=page.match(/<script>([\s\S]*?)<\/script>/)[1];
new vm.Script(script);
class Element{constructor(){this.children=[];this.listeners={};this.dataset={};this.value='all';this.textContent='';}append(x){this.children.push(x)}replaceChildren(){this.children=[]}addEventListener(k,f){this.listeners[k]=f}scrollIntoView(){}}
const cases=JSON.parse(fs.readFileSync(path.join(d,'fichas.json'),'utf8'));
const sources=JSON.parse(fs.readFileSync(path.join(d,'coleta.json'),'utf8'));
const nodes=Object.fromEntries(['#stage','#arch','#count','#slots','#clear','#comparar'].map(k=>[k,new Element()]));
const cards=cases.map(c=>Object.assign(new Element(),{dataset:{stage:sources.find(s=>s.id===c.id).level.toLowerCase(),arch:c.architecture}}));
const buttons=cases.map(c=>Object.assign(new Element(),{dataset:{compare:c.id}}));
const document={querySelector:k=>nodes[k],querySelectorAll:k=>k==='article[data-stage]'?cards:buttons,createElement:()=>new Element()};
vm.runInNewContext(script,{document});
nodes['#stage'].value='mega';nodes['#stage'].listeners.change();assert.equal(cards.filter(c=>!c.hidden).length,20);
nodes['#arch'].value='quadrupede';nodes['#arch'].listeners.change();assert.equal(cards.filter(c=>!c.hidden).length,cards.filter(c=>c.dataset.stage==='mega'&&c.dataset.arch==='quadrupede').length);
buttons[0].listeners.click();buttons[1].listeners.click();assert.equal(nodes['#slots'].children.length,2);
buttons[2].listeners.click();assert.equal(nodes['#slots'].children.length,2);assert(nodes['#slots'].children[0].children[0].textContent.startsWith(sources[1].name));
nodes['#clear'].listeners.click();assert.equal(nodes['#slots'].children.length,1);
assert(sources.every(s=>!('profile' in s)));
const result=JSON.parse(fs.readFileSync(path.join(d,'validacao.json'),'utf8'));
result.javascript={syntax:true,stage_filter:true,combined_filter:true,comparison_fifo:true,clear:true,method:'Node vm e DOM mínimo; sem teste visual em navegador'};
fs.writeFileSync(path.join(d,'validacao.json'),JSON.stringify(result,null,2));
console.log('OK: sintaxe, filtros, comparação e coleção sem transcrições.');
