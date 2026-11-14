import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
const b=await chromium.launch({headless:true}),page=await b.newPage({viewport:{width:1440,height:900}});
const key='soulmonsters.plant-lab.v1',out='documentation/plant-lab-v1/captures/',errors=[];
page.on('pageerror',e=>errors.push(e.message));
const read=()=>page.evaluate(k=>JSON.parse(localStorage.getItem(k)),key);
const settle=()=>page.waitForTimeout(400);
async function center(){await page.locator('#fit').evaluate(e=>e.closest('details').open=true);await page.locator('#fit').click();}
try{
await page.goto('http://127.0.0.1:5256');await page.waitForSelector('#loading[hidden]',{state:'attached'});
const before=await read()??await page.evaluate(()=>null);await page.locator('#demoOrganic').click();await settle();let a=await read();assert.equal(a.autotiling,true);if(before)assert.deepEqual(a.objects,before.objects);assert(a.ramps.filter(Boolean).length>=4);
const levels=[...a.levels];await page.locator('#autoTile').uncheck();await settle();assert.equal((await read()).autotiling,false);assert.deepEqual((await read()).levels,levels);await page.locator('#undo').click();await settle();assert.equal((await read()).autotiling,true);
await center();await page.mouse.move(10,10);await page.waitForTimeout(3500);await page.screenshot({path:out+'autotile-organico-1440x900.png'});
await page.locator('#atlasOpen').click();assert(await page.locator('#atlasDialog').isVisible());await page.screenshot({path:out+'autotile-47-grama.png'});await page.locator('#atlasKind').selectOption('stone');await page.locator('#atlasVariant').selectOption('2');await page.screenshot({path:out+'autotile-47-pedra.png'});
const downloading=page.waitForEvent('download');await page.locator('#atlasDownload').click();const download=await downloading;await download.saveAs(out+'autotile-pedra-47x3.png');const png=await fs.readFile(out+'autotile-pedra-47x3.png');assert.equal(png.readUInt32BE(16),256);assert.equal(png.readUInt32BE(20),576);await page.keyboard.press('Escape');assert(!(await page.locator('#atlasDialog').isVisible()));
// Review geometry without foliage hiding the joints.
a=await read();a.objects=[];a.player={x:380,y:450};await page.locator('#file').setInputFiles({name:'juntas.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await settle();await page.setViewportSize({width:1920,height:1080});await center();await page.locator('#zoomIn').click();let box=await page.locator('#canvas').boundingBox();await page.mouse.move(box.x+box.width/2,box.y+box.height/2);await page.mouse.down({button:'middle'});await page.mouse.move(box.x+box.width/2,box.y+box.height/2+100);await page.mouse.up({button:'middle'});await page.mouse.move(10,10);await page.waitForTimeout(3500);
const ox=box.x+Math.round((box.width-1536)/2),oy=box.y+Math.round((box.height-1024)/2)+100;
for(const [name,x,y,w,h] of [['cantos-rampa',50,48,300,270],['terra-cantos',480,48,250,280]])await page.screenshot({path:out+'autotile-'+name+'-2x.png',clip:{x:ox+x*2,y:oy+y*2,width:w*2,height:h*2}});
assert.deepEqual(errors,[]);await fs.writeFile(out+'autotile-verificacao.json',JSON.stringify({passed:true,checks:['amostra preserva objetos','ligar/desligar e desfazer','atlas com 47 peças e 3 variações','download PNG 256×576','juntas 2x sem objetos','ausência de erros no navegador'],browserErrors:errors},null,2));console.log('PASS autotiling: controles, atlas, download e juntas.');
}finally{await b.close();}

