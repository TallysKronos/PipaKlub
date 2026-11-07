import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
const a=JSON.parse(await fs.readFile('documentation/plant-lab-v1/cases/ramp-user-2026-11-06.json','utf8'));a.objects=[];
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1920,height:1080}}),errors=[],out='documentation/plant-lab-v1/captures/';
p.on('pageerror',e=>errors.push(e.message));
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached'});
 await p.locator('#file').setInputFiles({name:'bordas.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await p.waitForFunction(()=>document.getElementById('saveState').textContent.startsWith('Salvo'));
 await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();await p.mouse.move(10,10);await p.screenshot({path:out+'relief-rim-studio.png'});
 await p.locator('#zoomIn').click();const box=await p.locator('#canvas').boundingBox();await p.mouse.move(box.x+box.width/2,box.y+box.height/2);await p.mouse.down({button:'middle'});await p.mouse.move(box.x+box.width/2,box.y+box.height/2+140);await p.mouse.up({button:'middle'});await p.mouse.move(10,10);
 const ox=box.x+Math.round((box.width-1536)/2),oy=box.y+Math.round((box.height-1024)/2)+140;
 await p.screenshot({path:out+'relief-rim-detail.png',clip:{x:ox+45*2,y:oy+55*2,width:285*2,height:220*2}});
 assert.deepEqual(errors,[]);console.log('PASS contorno no editor: captura geral e detalhe 2× sem vegetação; sem erros de página.');
}finally{await b.close();}
