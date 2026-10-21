import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createSwitchNav} from './src/switch-nav.js';
import {parseHTML} from 'linkedom';
import {createDetailPages} from './src/detail-pages.js';
const client=fs.readFileSync('src/pilot-ui-client.js','utf8'),css=fs.readFileSync('src/pilot-ui.css','utf8');
test('PIP-50 pilot ships in both builds and can be turned off with ?classico',()=>{
 for(const file of ['worker/index.js','docs/index.html']){const page=fs.readFileSync(file,'utf8');assert.ok(page.includes('pilotRenderMenu'),file);assert.ok(page.includes('.pilot-menu'),file);}
 assert.match(client,/classico/);
});
test('every device has glyphs for the footer commands X and Y',()=>{
 const nav=createSwitchNav();
 for(const [name,set] of Object.entries(nav.GLYPHS))for(const command of ['actionX','actionY','confirm','back','tabLeft','tabRight'])assert.ok(set[command],name+' '+command);
});
test('back from a screen opened by the menu returns to its option',()=>{
 for(const close of ['closeAccount','closeDex','closeModal','closeSchool'])assert.match(client,new RegExp(close+'=function'),close);
 assert.match(fs.readFileSync('src/courtyard-client.js','utf8'),/!\(typeof dexOpen!=='undefined'&&dexOpen\)/,'Escape over the Dex closes the Dex, not opens the menu');
});
test('pilot respects reduced motion',()=>{assert.match(css,/prefers-reduced-motion:reduce/);});

function detailFixture(){
 const {document}=parseHTML('<article id="detail"><div id="art"></div><button id="equip">Equipar</button><p id="lore">História</p></article>');
 let focused=null,changes=0;const art=document.getElementById('art'),equip=document.getElementById('equip'),lore=document.getElementById('lore');
 const pages=createDetailPages(document.getElementById('detail'),{id:'test-detail',label:'Páginas',pages:[{label:'Resumo',nodes:[equip]},{label:'História',nodes:[lore]}],onChange:()=>changes++});
 for(const el of [...pages.bar.children,...pages.panels])el.focus=()=>{focused=el;};
 return {document,pages,art,equip,lore,get focused(){return focused;},get changes(){return changes;}};
}
test('detail pages retain live actions and the creature while isolating the selected reading panel',()=>{
 const f=detailFixture();let equips=0;f.equip.onclick=()=>equips++;
 assert.equal(f.pages.panels[0].hidden,false);assert.equal(f.pages.panels[1].hidden,true);
 assert.equal(f.pages.bar.getAttribute('aria-label'),'Páginas');
 f.pages.step(-1);assert.equal(f.pages.active,1);assert.equal(f.focused,f.pages.bar.children[1]);
 assert.equal(f.art.parentElement.id,'detail');assert.equal(f.lore.parentElement,f.pages.panels[1]);assert.equal(equips,0);
 f.pages.step(1);assert.equal(f.equip,f.document.getElementById('equip'));f.equip.click();assert.equal(equips,1);
 for(const [i,tab]of [...f.pages.bar.children].entries()){
  assert.equal(tab.getAttribute('aria-controls'),f.pages.panels[i].id);
  assert.equal(tab.getAttribute('aria-selected'),String(i===f.pages.active));
  assert.equal(tab.getAttribute('tabindex'),String(i===f.pages.active?0:-1));
 }
});
test('keyboard details navigation wraps, enters reading and scrolls only the active panel',()=>{
 const f=detailFixture(),key=(key,target)=>({key,target,preventDefault(){},stopPropagation(){}});
 f.pages.bar.children[0].onkeydown(key('ArrowRight'));assert.equal(f.pages.active,1);
 f.pages.bar.children[1].onkeydown(key('ArrowDown'));assert.equal(f.focused,f.pages.panels[1]);
 const panel=f.pages.panels[1];panel.scrollTop=0;panel.onkeydown(key('ArrowDown',panel));assert.equal(panel.scrollTop,56);
 panel.onkeydown(key('ArrowDown',f.lore));assert.equal(panel.scrollTop,56);
 panel.onkeydown(key('ArrowLeft',panel));assert.equal(f.focused,f.pages.bar.children[1]);
 f.pages.bar.children[1].onkeydown(key('Home'));assert.equal(f.pages.active,0);
});
