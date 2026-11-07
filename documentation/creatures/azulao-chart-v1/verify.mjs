// Verificação funcional em DOM local. Não realiza renderização nem abre navegador.
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { createRequire } from 'node:module';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const base=path.dirname(fileURLToPath(import.meta.url));
const candidates=[path.resolve(base,'../../../package.json'),path.resolve(base,'../../../../pipa-club/package.json'),path.resolve(base,'../../../../pipa-club-pip88/package.json')];
let parseHTML;
for(const entry of candidates){try{({parseHTML}=createRequire(entry)('linkedom'));break;}catch{}}
assert.ok(parseHTML,'Necessário linkedom em uma das instalações locais do projeto.');
const {window,document}=parseHTML(readFileSync(path.join(base,'index.html'),'utf8'));
vm.runInContext(readFileSync(path.join(base,'app.js'),'utf8'),vm.createContext({window,document,console}),{filename:'app.js'});
const click=id=>document.getElementById(id).dispatchEvent(new window.Event('click'));
const pick=id=>document.querySelector(`[data-node="${id}"]`).dispatchEvent(new window.Event('click'));
const current=()=>document.getElementById('current-name').textContent;
const complete=()=>{for(const input of document.querySelectorAll('#requirement-options input')){input.checked=true;input.dispatchEvent(new window.Event('change'));}};
const advance=(id,name)=>{pick(id);assert.equal(document.getElementById('simulate').disabled,true,'Critérios não podem vir aprovados');complete();assert.equal(document.getElementById('simulate').disabled,false);click('simulate');assert.equal(current(),name);};
assert.equal(document.querySelectorAll('[data-node]').length,11);
assert.equal(current(),'Azulão');
pick('azultor');complete();assert.equal(document.getElementById('simulate').disabled,true,'Não saltar Pipa → Pandorga');
for(const [branch,branchName,final,finalName] of [['azulfazo','Azulfazo','azultor','Azultor'],['azulineo','Azulíneo','azuligero','Azulígero'],['azulume','Azulume','azulaculo','Azuláculo']]){
 click('start-base');advance(branch,branchName);advance(final,finalName);click('return');assert.equal(current(),branchName);click('return');assert.equal(current(),'Azulão');
}
click('start-small');advance('azulao','Azulão');assert.match(document.getElementById('current-stage').textContent,/II · Pipa/);
for(const id of ['azulao-moncao','azulao-alisio']){
 click('start-base');pick(id);complete();click('simulate');assert.equal(current(),'Azulão');assert.match(document.getElementById('current-stage').textContent,/II · Pipa/);assert.match(document.getElementById('current-config').textContent,/Configuração:/);click('remove-config');assert.equal(document.getElementById('current-config').textContent,'Sem configuração especial');
}
click('start-base');pick('azulao-moncao');complete();click('simulate');advance('azulfazo','Azulfazo');assert.equal(document.getElementById('current-config').textContent,'Sem configuração especial');
pick('azulfazo-possuido');assert.equal(document.getElementById('simulate').disabled,true,'Estado de história indisponível por Remonta');click('simulate');assert.equal(current(),'Azulfazo');
for(const node of JSON.parse(document.getElementById('chart-data').textContent).nodes){pick(node.id);assert.equal(document.querySelector('#details h2').textContent,node.name);}
for(const element of document.querySelectorAll('img')){assert.ok(existsSync(path.resolve(base,element.getAttribute('src'))));}
console.log('OK: 11 fichas; três rotas completas; retorno; pré-evolução; duas configurações no mesmo estágio; remoção ao remontar; bloqueio de salto e de possessão. Sem validação de layout ou movimento.');
