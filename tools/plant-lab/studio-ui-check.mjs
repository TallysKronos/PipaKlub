import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {initialLayout} from './model.mjs';
const b=await chromium.launch({headless:true}),page=await b.newPage({viewport:{width:1440,height:900}});
const key='soulmonsters.plant-lab.v1',errors=[],out='documentation/plant-lab-v1/captures/';
page.on('pageerror',e=>errors.push(e.message));
const read=()=>page.evaluate(k=>JSON.parse(localStorage.getItem(k)),key);
const settle=()=>page.waitForTimeout(300);
async function point(x,y){const r=await page.locator('#canvas').boundingBox();return {x:r.x+Math.round((r.width-768)/2)+x,y:r.y+Math.round((r.height-512)/2)+y};}
async function click(x,y){const p=await point(x,y);await page.mouse.click(p.x,p.y);await settle();}
async function load(a){await page.locator('#file').setInputFiles({name:'studio.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await page.waitForFunction(()=>document.getElementById('saveState').textContent.startsWith('Salvo'));}
try{
await page.goto('http://127.0.0.1:5256');await page.waitForSelector('#loading[hidden]',{state:'attached'});
const a=initialLayout();a.objects=[];a.floors.fill('grass');a.levels.fill(0);a.ramps.fill(null);a.player={x:650,y:450};await load(a);
await page.locator('#assetSearch').fill('bromélia');assert.equal(await page.locator('.plant').count(),3);await page.locator('#assetSearch').fill('inexistente');assert(await page.locator('#emptyAssets').isVisible());await page.locator('#assetSearch').fill('');
await page.locator('[data-asset="bromelia-do-vento-b"]').click();await click(320,320);await click(400,320);assert.equal((await read()).objects.length,2);
await page.locator('button[data-tool=select]').click();const start=await point(285,260),end=await point(435,340);await page.mouse.move(start.x,start.y);await page.mouse.down();await page.mouse.move(end.x,end.y,{steps:10});await page.mouse.up();assert.equal(await page.locator('#selectionCount').textContent(),'2 selecionados');
await page.keyboard.press('Control+d');await settle();assert.equal((await read()).objects.length,4);await page.keyboard.press('Control+z');await settle();assert.equal((await read()).objects.length,2);
// Re-select the group and exercise copy/paste independently.
await page.keyboard.press('Control+a');await page.keyboard.press('Control+c');await page.keyboard.press('Control+v');await settle();assert.equal((await read()).objects.length,4);await page.keyboard.press('Control+z');await settle();
await page.keyboard.press('Control+a');await page.locator('#collision').check();await settle();assert((await read()).objects.every(o=>o.collidable));await page.locator('#objectLayer').selectOption('objects');await settle();assert((await read()).objects.every(o=>o.layer==='objects'));
await page.getByRole('button',{name:'Bloquear Objetos',exact:true}).click();await page.locator('button[data-tool=erase]').click();await click(320,309);assert.equal((await read()).objects.length,2);await page.getByRole('button',{name:'Desbloquear Objetos',exact:true}).click();
await page.getByRole('button',{name:'Ocultar Objetos',exact:true}).click();assert.equal(await page.getByRole('button',{name:'Mostrar Objetos',exact:true}).getAttribute('aria-pressed'),'false');await page.getByRole('button',{name:'Mostrar Objetos',exact:true}).click();
await page.locator('[data-floor=dirt]').click();await page.locator('button[data-tool=fill]').click();await click(450,350);assert((await read()).floors.every(f=>f==='dirt'));await page.locator('#undo').click();await settle();assert((await read()).floors.some(f=>f==='grass'));
await page.locator('button[data-tool=eyedrop]').click();await click(320,309);assert.equal(await page.locator('body').getAttribute('data-tool'),'plant');
await page.locator('button[data-tool=height]').click();await page.locator('#brushSize').selectOption('1');await page.locator('#heightMode').selectOption('raise');await click(500,350);await click(500,334);assert.equal((await read()).levels[10*24+15],2);await page.locator('#heightMode').selectOption('lower');await click(500,318);assert.equal((await read()).levels[10*24+15],1);
let edited=await read();edited.player={x:320,y:350};await load(edited);await page.locator('#play').click();await page.keyboard.down('w');await page.waitForTimeout(650);await page.keyboard.up('w');await page.locator('#play').click();await settle();assert((await read()).player.y>=332,'object collision should stop Kael before root');
await page.locator('#help').click();assert(await page.locator('#helpDialog').isVisible());await page.keyboard.press('Escape');assert(!(await page.locator('#helpDialog').isVisible()));
await page.reload();await page.waitForSelector('#loading[hidden]',{state:'attached'});assert((await read()).objects.every(o=>o.layer==='objects'&&o.collidable));assert.deepEqual(errors,[]);
// Exercise HTML drag/drop, then camera movement without changing map data.
await page.locator('[data-category=plants]').click();const countBeforeDrop=(await read()).objects.length,target=await point(480,400),canvasBox=await page.locator('#canvas').boundingBox();await page.locator('[data-asset="capim-rabiola-a"]').dragTo(page.locator('#canvas'),{targetPosition:{x:target.x-canvasBox.x,y:target.y-canvasBox.y}});await settle();assert.equal((await read()).objects.length,countBeforeDrop+1);
const beforePan=await read(),imageBefore=await page.locator('#canvas').evaluate(c=>c.toDataURL());await page.locator('button[data-tool=hand]').click();await page.mouse.move(canvasBox.x+canvasBox.width/2,canvasBox.y+canvasBox.height/2);await page.mouse.down();await page.mouse.move(canvasBox.x+canvasBox.width/2+45,canvasBox.y+canvasBox.height/2+25,{steps:5});await page.mouse.up();await settle();assert.deepEqual(await read(),beforePan);assert.notEqual(await page.locator('#canvas').evaluate(c=>c.toDataURL()),imageBefore);
// Final visual uses a fresh copy of the demonstration, only in this isolated test browser.
await load(initialLayout());await page.locator('[data-asset="bromelia-do-vento-b"]').click();await click(456,352);await page.locator('button[data-tool=select]').click();await click(456,338);await page.mouse.move(10,10);await page.waitForTimeout(3500);await page.screenshot({path:out+'studio-propriedades-1440x900.png'});
await fs.writeFile(out+'studio-verificacao.json',JSON.stringify({passed:true,checks:['busca e estado vazio','seleção por área','duplicação em grupo','copiar/colar','colisão e camada persistentes','bloquear/ocultar','preenchimento conectado','conta-gotas','subir/baixar relevo','colisão ao jogar','ajuda com Escape','arrastar asset','mover câmera sem alterar o mapa'],browserErrors:errors},null,2));console.log('PASS Studio: 14 cenários de ferramentas, camadas, seleção e colisão.');
}finally{await b.close();}


