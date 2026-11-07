import fs from 'node:fs/promises';import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {waterAt} from './water.mjs';
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1440,height:900}}),errors=[],out='documentation/plant-lab-v1/captures/';p.on('pageerror',e=>errors.push(e.message));
const saved=()=>p.waitForFunction(()=>document.getElementById('saveState').textContent.startsWith('Salvo'));
const read=()=>p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached'});await p.locator('#waterSample').click();await saved();const lake=await read();assert(lake.floors.includes('water'));
 await p.mouse.move(10,10);await p.waitForTimeout(500);await p.screenshot({path:out+'water-lake-studio.png'});
 const canvas=await p.locator('#canvas').boundingBox(),clip={x:canvas.x+300,y:canvas.y+150,width:220,height:180};const first=await p.screenshot({path:out+'water-frame-a.png',clip});await p.waitForTimeout(300);const second=await p.screenshot({path:out+'water-frame-b.png',clip});assert(!first.equals(second));
 await p.locator('#play').click();await p.keyboard.down('Shift');await p.keyboard.down('w');await p.waitForTimeout(2600);await p.keyboard.up('w');await p.keyboard.up('Shift');await p.locator('#play').click();await saved();const stopped=await read();assert(!waterAt(stopped,stopped.player.x,stopped.player.y));assert(stopped.player.y>220);assert(stopped.player.y<lake.player.y);
 await p.locator('#undo').click();await saved();assert(!(await read()).floors.includes('water'));await p.locator('#redo').click();await saved();assert((await read()).floors.includes('water'));
 await p.locator('[data-floor="water"]').click();await p.locator('#brushSize').selectOption('1');await p.mouse.click(canvas.x+Math.round((canvas.width-768)/2)+32,canvas.y+Math.round((canvas.height-512)/2)+32);await saved();assert((await read()).floors.filter(k=>k==='water').length>lake.floors.filter(k=>k==='water').length);
 await p.locator('#waterSample').click();await saved();await p.setViewportSize({width:1920,height:1080});await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();await p.locator('#zoomIn').click();await p.mouse.move(10,10);const box=await p.locator('#canvas').boundingBox(),ox=box.x+Math.round((box.width-1536)/2),oy=box.y+Math.round((box.height-1024)/2);await p.screenshot({path:out+'water-shore-detail.png',clip:{x:ox+145*2,y:oy+125*2,width:240*2,height:230*2}});
 assert.deepEqual(errors,[]);await fs.writeFile(out+'water-ui-check.json',JSON.stringify({passed:true,checks:['amostra reversível','animação visível em duas capturas','Kael bloqueado na margem por teclado','pintura de água pelo mouse','margem ampliada em 2×'],stopped:stopped.player,errors},null,2));console.log('PASS lago: pintura, animação, colisão e desfazer/refazer.');
}finally{await b.close();}
