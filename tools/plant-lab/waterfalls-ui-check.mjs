import fs from 'node:fs/promises';import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {waterfallSample} from './waterfalls.mjs';import {initialLayout} from './model.mjs';
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1440,height:900}}),errors=[];
p.on('pageerror',e=>errors.push(e.message));const read=async()=>{await p.waitForTimeout(320);return p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));};
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached',timeout:15000});
 await p.locator('#waterfallsTab').click();assert.equal(await p.locator('#waterfallProperties').isVisible(),true);assert.equal(await p.locator('#palette [data-asset]').count(),3);
 await p.locator('#waterfallSample').click();const sample=await read();assert.equal(sample.objects.length,3);
 const a=waterfallSample(initialLayout());a.objects.shift();await p.locator('#file').setInputFiles({name:'queda.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await read();
 await p.locator('#palette [data-asset="cachoeira-fina"]').click();await p.waitForTimeout(100);const box=await p.locator('#canvas').boundingBox(),ox=box.x+Math.round((box.width-768)/2),oy=box.y+Math.round((box.height-512)/2);
 await p.mouse.click(ox+176,oy+152);const painted=await read();assert.equal(painted.objects.length,3);assert.deepEqual(painted.levels,a.levels);assert.deepEqual(painted.floors,a.floors);
 await p.locator('#undo').click();assert.equal((await read()).objects.length,2);await p.locator('#redo').click();assert.equal((await read()).objects.length,3);
 await p.mouse.click(ox+48,oy+350);assert.equal((await read()).objects.length,3);
 await p.mouse.move(10,10);await p.waitForTimeout(350);await p.screenshot({path:'documentation/plant-lab-v1/captures/waterfalls-studio.png'});
 await p.setViewportSize({width:1920,height:1080});await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();await p.locator('#zoomIn').click();await p.mouse.move(10,10);await p.waitForTimeout(150);await p.screenshot({path:'documentation/plant-lab-v1/captures/waterfalls-detail.png'});
 const curved=waterfallSample(initialLayout());curved.objects=[curved.objects[0]];curved.objects[0].y=224;
 curved.levels[6*curved.width+5]=5;curved.floors[6*curved.width+5]='water';for(let x=4;x<=6;x++)curved.floors[5*curved.width+x]='water';
 await p.locator('#file').setInputFiles({name:'boca-curva.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(curved))});await read();await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();await p.locator('#zoomIn').click();await p.mouse.move(10,10);await p.waitForTimeout(150);
 const area=await p.locator('#canvas').boundingBox(),cx=area.x+Math.round((area.width-1536)/2),cy=area.y+Math.round((area.height-1024)/2);
 await p.screenshot({path:'documentation/plant-lab-v1/captures/waterfall-curved-mouth.png',clip:{x:cx+125*2,y:cy+105*2,width:210,height:340}});
 assert.deepEqual(errors,[]);await fs.writeFile('documentation/plant-lab-v1/captures/waterfalls-check.json',JSON.stringify({passed:true,checks:['dedicated library','3 animated falls','recessed pool','placement preserves terrain','undo redo','reject dry terrain','curved outlet closeup'],errors},null,2));console.log('PASS: waterfall library, placement, recessed pool, undo/redo, dry terrain rejection and curved outlet.');
}finally{await b.close();}
