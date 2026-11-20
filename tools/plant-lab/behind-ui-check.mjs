import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {initialLayout} from './model.mjs';
const browser=await chromium.launch({headless:true}),page=await browser.newPage({viewport:{width:1440,height:900}});
const errors=[];page.on('pageerror',e=>errors.push(e.message));
const key='soulmonsters.plant-lab.v1',out='documentation/plant-lab-v1/captures/';
const read=()=>page.evaluate(k=>JSON.parse(localStorage.getItem(k)),key);
async function clickWorld(x,y){const b=await page.locator('#canvas').boundingBox();await page.mouse.click(b.x+Math.round((b.width-768)/2)+x,b.y+Math.round((b.height-512)/2)+y);await page.waitForTimeout(350);}
try{
await page.goto('http://127.0.0.1:5256/');await page.waitForSelector('#loading[hidden]',{state:'attached'});
const a=initialLayout();a.objects=[];a.levels.fill(0);a.ramps.fill(null);a.levels[6*24+10]=12;a.player={x:400,y:350};
await page.locator('#file').setInputFiles({name:'12-andares.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await page.waitForTimeout(350);
await page.locator('#heightLevel').selectOption('12');assert.equal(await page.locator('#heightLevel').inputValue(),'12');
await page.locator('[data-asset="bromelia-do-vento-b"]').click();await page.locator('#behind').click();assert.equal(await page.locator('#behind').getAttribute('aria-pressed'),'true');await clickWorld(336,144);let b=await read();assert.equal(b.objects.length,1);assert.deepEqual([b.objects[0].x,b.objects[0].y],[336,144]);
const opaque=await page.evaluate(async()=>{const im=new Image();im.src='/assets/bromelia-do-vento-b.png';await im.decode();const c=document.createElement('canvas');c.width=c.height=64;const g=c.getContext('2d');g.drawImage(im,0,0);const data=g.getImageData(0,0,64,64).data;for(let y=40;y<52;y++)for(let x=25;x<40;x++)if(data[(y*64+x)*4+3]===255)return{x:x-32,y:y-52};});
await page.locator('[data-tool=select]').click();await clickWorld(336+opaque.x,144+opaque.y);assert.equal(await page.locator('#objX').inputValue(),'336');assert.equal(await page.locator('#objY').inputValue(),'144');
await page.waitForTimeout(3500);await page.mouse.move(10,10);await page.screenshot({path:out+'editar-atras-revelado.png'});
await page.locator('#play').click();assert(await page.locator('body').evaluate(e=>e.classList.contains('testing')));await page.mouse.move(10,10);await page.screenshot({path:out+'editar-atras-teste-normal.png'});await page.locator('#play').click();
await page.reload();await page.waitForSelector('#loading[hidden]',{state:'attached'});assert.equal((await read()).levels[6*24+10],12);assert.equal((await read()).objects[0].y,144);
const response=await page.request.post('http://127.0.0.1:5256/api/export-godot',{data:await read()});assert.equal(response.status(),200);const bytes=await response.body();let offset=0,layout;while(bytes.readUInt32LE(offset)===0x04034b50){const size=bytes.readUInt32LE(offset+18),n=bytes.readUInt16LE(offset+26),extra=bytes.readUInt16LE(offset+28),name=bytes.subarray(offset+30,offset+30+n).toString(),start=offset+30+n+extra;if(name==='layout.json')layout=JSON.parse(bytes.subarray(start,start+size));offset=start+size;}assert.equal(layout.levels[6*24+10],12);assert.equal(layout.objects[0].y,144);assert.deepEqual(errors,[]);
await fs.writeFile(out+'editar-atras-verificacao.json',JSON.stringify({passed:true,checks:['12 níveis na UI/importação/exportação','plantar no chão oculto','selecionar objeto oculto','teste restaura oclusão','persistência'],browserErrors:errors},null,2));console.log('PASS: 12 andares, apoio oculto, seleção, persistência e exportação.');
}finally{await browser.close();}

