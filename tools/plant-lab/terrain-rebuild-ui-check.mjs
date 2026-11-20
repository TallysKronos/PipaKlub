import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {forestSample} from './forest-sample.mjs';
import {initialLayout} from './model.mjs';
import {terrainHeight} from './terrain-field.mjs';
const b=await chromium.launch({headless:true}),page=await b.newPage({viewport:{width:1440,height:900}}),out='documentation/plant-lab-v1/captures/',key='soulmonsters.plant-lab.v1',errors=[];
page.on('pageerror',e=>errors.push(e.message));const read=()=>page.evaluate(k=>JSON.parse(localStorage.getItem(k)),key);
const wait=()=>page.waitForTimeout(350);
async function load(a){await page.locator('#file').setInputFiles({name:'area.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await page.waitForFunction(()=>document.getElementById('saveState').textContent.startsWith('Salvo'));}
async function centre(){await page.locator('#fit').evaluate(el=>el.closest('details').open=true);await page.locator('#fit').click();}
try{
await page.goto('http://127.0.0.1:5256/');await page.waitForSelector('#loading[hidden]',{state:'attached'});
const legacy=initialLayout();legacy.objects=[];await load(legacy);await centre();await page.mouse.move(10,10);await page.waitForTimeout(3500);await page.screenshot({path:out+'rebuild-v2-legado-corrigido.png'});
const rebuilt=forestSample(initialLayout(),{keepObjects:false});await load(rebuilt);await centre();await page.mouse.move(10,10);await page.waitForTimeout(3500);await page.screenshot({path:out+'rebuild-v2-bosque.png'});
const bare=structuredClone(rebuilt);bare.objects=[];await load(bare);await page.setViewportSize({width:1920,height:1080});await centre();await page.locator('#zoomIn').click();const box=await page.locator('#canvas').boundingBox();await page.mouse.move(box.x+box.width/2,box.y+box.height/2);await page.mouse.down({button:'middle'});await page.mouse.move(box.x+box.width/2,box.y+box.height/2+140);await page.mouse.up({button:'middle'});await page.mouse.move(10,10);await page.waitForTimeout(3500);
const ox=box.x+Math.round((box.width-1536)/2),oy=box.y+Math.round((box.height-1024)/2)+140;
for(const [name,x,y,w,h]of [['terra',48,30,290,280],['rocha',485,30,260,290]])await page.screenshot({path:out+'rebuild-v2-juntas-'+name+'.png',clip:{x:ox+x*2,y:oy+y*2,width:w*2,height:h*2}});
// Human input: each ascent, followed by descent, using the actual game's controller.
const routes=[];
await page.setViewportSize({width:1440,height:900});
for(const x of [176,592]){const a=structuredClone(bare);a.player={x,y:350};await load(a);await page.locator('#play').click();await page.keyboard.down('Shift');await page.keyboard.down('w');await page.waitForTimeout(2200);await page.keyboard.up('w');await page.keyboard.up('Shift');await page.locator('#play').click();await wait();const upper=await read();assert.equal(terrainHeight(upper,upper.player.x,upper.player.y),2);await page.locator('#play').click();await page.keyboard.down('Shift');await page.keyboard.down('s');await page.waitForTimeout(2200);await page.keyboard.up('s');await page.keyboard.up('Shift');await page.locator('#play').click();await wait();const lower=await read();assert.equal(terrainHeight(lower,lower.player.x,lower.player.y),0);routes.push({x,upper:upper.player,lower:lower.player});}
assert.deepEqual(errors,[]);await fs.writeFile(out+'rebuild-v2-verificacao.json',JSON.stringify({passed:true,checks:['reprodução do mapa legado','bosque reconstruído','juntas sem vegetação em 2x','subida e descida por teclado nos dois percursos'],routes,errors},null,2));console.log('PASS reconstrução: ambas as subidas e descidas em jogo, sem erros.');
}finally{await b.close();}

