import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {initialLayout} from './model.mjs';
const browser=await chromium.launch({headless:true}),page=await browser.newPage({viewport:{width:1440,height:900}});
const key='soulmonsters.plant-lab.v1',out='documentation/plant-lab-v1/captures/';
const errors=[];page.on('pageerror',e=>errors.push(e.message));
const read=()=>page.evaluate(k=>JSON.parse(localStorage.getItem(k)),key);
const saved=()=>page.waitForTimeout(350);
async function at(x,y){const b=await page.locator('#canvas').boundingBox();return {x:b.x+Math.round((b.width-768)/2)+x,y:b.y+Math.round((b.height-512)/2)+y};}
async function click(x,y){const p=await at(x,y);await page.mouse.click(p.x,p.y);await saved();}
try{
await page.goto('http://127.0.0.1:5256');await page.waitForSelector('#loading[hidden]',{state:'attached'});
await page.locator('#file').setInputFiles({name:'terrain.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(initialLayout()))});await saved();
await page.locator('[data-tool=height]').click();await page.locator('#blockBrush').uncheck();await page.locator('#heightLevel').selectOption('2');await page.locator('#cliffMaterial').selectOption('rock');await click(400,400);let a=await read();assert.equal(a.levels[12*24+12],2);assert.equal(a.cliffs[12*24+12],'rock');await page.locator('#undo').click();await saved();assert.equal((await read()).levels[12*24+12],0);
// Remove and repaint one existing ramp, then restore the undoable demo.
await page.locator('[data-tool=ramp]').click();await page.keyboard.down('Shift');await click(176,232);await page.keyboard.up('Shift');assert.equal((await read()).ramps[7*24+5],null);await click(176,240);assert.equal((await read()).ramps[7*24+5],'n');
const before=(await read()).objects;await page.locator('#demoRelief').click();await saved();assert.deepEqual((await read()).objects,before);
await page.mouse.move(10,10);await page.waitForTimeout(3500);await page.locator('#fit').click();await page.screenshot({path:out+'morros-geral.png'});
await page.locator('#heights').click();await page.screenshot({path:out+'morros-cotas.png'});await page.locator('#heights').click();
// Dedicated unobstructed junction captures: hide plants through import only in this test browser.
a=await read();a.objects=[];a.player={x:380,y:450};await page.locator('#file').setInputFiles({name:'juntas.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await saved();await page.mouse.move(10,10);await page.waitForTimeout(3500);
await page.setViewportSize({width:1920,height:1080});await page.locator('#fit').click();await page.locator('#zoomIn').click();await page.waitForTimeout(100);const b=await page.locator('#canvas').boundingBox(),ox=b.x+Math.round((b.width-768*2)/2),oy=b.y+Math.round((b.height-512*2)/2);
for(const [name,x,y,w,h]of [['terra',55,60,280,205],['rocha',500,60,220,275]]){
const shot=await page.screenshot({clip:{x:ox+x*2,y:oy+y*2,width:w*2,height:h*2}});await fs.writeFile(out+'juntas-'+name+'.png',shot);
}
assert.deepEqual(errors,[]);await fs.writeFile(out+'relevo-verificacao.json',JSON.stringify({passed:true,checks:['pintar altura/material','desfazer altura','remover/criar rampa','exemplo preserva plantas','capturas de cotas e juntas sem personagens'],errors},null,2));
console.log('PASS relevo: ferramentas, undo, rampas e capturas.');
}finally{await browser.close();}


