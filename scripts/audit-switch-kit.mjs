import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
let chromium;try{({chromium}=require('playwright'));}catch{({chromium}=require(path.join(process.env.PIPA_KIT_NODE_MODULES||'','playwright')));}
const root=fileURLToPath(new URL('../',import.meta.url)),out=path.join(root,'art/ui-kit-switch-v1');
await fs.mkdir(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true});
const errors=[],requests=[];
const page=await browser.newPage({viewport:{width:1280,height:1000},deviceScaleFactor:1});
page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400&&!r.url().endsWith('favicon.ico'))requests.push({url:r.url(),status:r.status()});});
await page.goto('http://127.0.0.1:'+(process.env.PIPA_KIT_PORT||5195)+'/ui/kit-switch-v1/index.html');
await page.waitForFunction(()=>!!window.kitManifest);
await page.evaluate(async()=>{for(const image of document.images){image.loading='eager';try{await image.decode();}catch{}}});
const counts=await page.evaluate(()=>({components:Object.keys(kitManifest.components).length,glyphs:Object.keys(kitManifest.glyphs).length,icons:Object.keys(kitManifest.icons).length,brokenImages:[...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.src)}));
const cases=[];
for(const viewport of [{width:1280,height:800},{width:1920,height:1080},{width:844,height:390},{width:390,height:844}]){
 await page.setViewportSize(viewport);
 cases.push(await page.evaluate(({width,height})=>({width,height,pageOverflow:document.documentElement.scrollWidth>innerWidth,verification:verifyKit(),smallTargets:[...document.querySelectorAll('.pk-button,.pk-tab,.pk-menu,.pk-action,.pk-code input')].filter(e=>e.getBoundingClientRect().height>0&&(e.getBoundingClientRect().height<44||e.getBoundingClientRect().width<44)).map(e=>e.className)}),viewport));
 if(viewport.width===844)await page.locator('.menu-stage').screenshot({path:path.join(out,'menu-landscape.png')});
 if(viewport.width===390)await page.screenshot({path:path.join(out,'mobile.png'),fullPage:true});
}
await page.setViewportSize({width:1280,height:1000});
await page.evaluate(()=>window.scrollTo(0,0));
await page.screenshot({path:path.join(root,'assets/ui/kit-switch-v1/preview.png')});
await page.locator('#buttons').screenshot({path:path.join(out,'buttons.png')});
await page.locator('#resize').screenshot({path:path.join(out,'resize.png')});
await page.locator('#battle').screenshot({path:path.join(out,'battle.png')});
const menu=page.locator('#menuGrid button').first();await menu.focus();await page.keyboard.press('ArrowRight');
const keyboard=await page.evaluate(()=>document.activeElement.dataset.label==='Parceiros');
await page.selectOption('#platform','ps');
const platform=await page.evaluate(()=>[...document.querySelectorAll('[data-command]')].every(i=>i.src.includes('/ps-')));
await page.locator('#tab-events').click();
const tabs=await page.evaluate(()=>document.querySelector('#tab-events').getAttribute('aria-selected')==='true'&&[...document.querySelectorAll('#cards button')].filter(e=>!e.hidden).length===2);
await page.evaluate(()=>{document.querySelector('#width').value='421';document.querySelector('#width').dispatchEvent(new Event('input'));document.documentElement.style.zoom='1.25';});
const fractional=await page.evaluate(()=>({caps:verifyKit(),overflow:document.documentElement.scrollWidth>innerWidth}));
await page.locator('#resizePanel').screenshot({path:path.join(out,'panel-125-percent.png')});
const content=await page.evaluate(()=>{
 document.documentElement.style.zoom='1';document.querySelector('#width').value='200';document.querySelector('#height').value='160';document.querySelector('#width').dispatchEvent(new Event('input'));
 const b=document.querySelector('#resizeButton'),t=b.querySelector('.pk-content'),r=b.getBoundingClientRect(),tr=t.getBoundingClientRect(),panel=document.querySelector('#resizePanel');
 return {buttonLabelFits:tr.left>=r.left&&tr.right<=r.right,panelContentScrolls:getComputedStyle(panel.querySelector('.pk-content')).overflow==='auto'};
});
await page.emulateMedia({reducedMotion:'reduce'});
const reducedMotion=await page.locator('.pk-focus').first().evaluate(e=>getComputedStyle(e).animationName==='none');
const report={counts,cases,keyboard,platform,tabs,fractional,content,reducedMotion,errors,requests};
await fs.writeFile(path.join(out,'audit.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));await browser.close();
if(counts.brokenImages.length||errors.length||requests.length||cases.some(c=>c.pageOverflow||c.verification.failures||c.smallTargets.length)||!keyboard||!platform||!tabs||!reducedMotion||fractional.caps.failures||!content.buttonLabelFits||!content.panelContentScrolls)process.exitCode=1;
