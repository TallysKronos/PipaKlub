import fs from 'node:fs/promises';import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {wallSample} from './wall-kit.mjs';import {initialLayout} from './model.mjs';
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1440,height:900}}),errors=[];
p.on('pageerror',e=>errors.push(e.message));const read=async()=>{await p.waitForTimeout(300);return p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));};
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached'});
 const a=wallSample(initialLayout());await p.locator('#file').setInputFiles({name:'paredes.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await read();
 await p.locator('#wallsTab').click();assert.equal(await p.locator('#wallProperties').isVisible(),true);assert.equal(await p.locator('.terrain-properties').isVisible(),false);assert.equal(await p.locator('#palette [data-asset]').count(),14);
 await p.locator('#palette [data-asset="face-tijolos"]').click();assert.equal(await p.locator('body').getAttribute('data-tool'),'face');assert.equal(await p.locator('#wallPick').inputValue(),'face-tijolos');
 await p.locator('#brushSize').selectOption('1');await p.waitForTimeout(150);const box=await p.locator('#canvas').boundingBox(),ox=box.x+Math.round((box.width-960)/2),oy=box.y+Math.round((box.height-512)/2),cell=5*30+2;
 await p.mouse.click(ox+80,oy+176);const painted=await read();assert.equal(painted.cliffs[cell],'face-tijolos');assert.deepEqual(painted.floors,a.floors);assert.deepEqual(painted.levels,a.levels);assert.deepEqual(painted.ramps,a.ramps);
 await p.mouse.move(10,10);await p.screenshot({path:'documentation/plant-lab-v1/captures/materials-walls-1440.png'});
 await p.locator('#terrainTab').click();assert.equal(await p.locator('#wallProperties').isVisible(),false);assert.equal(await p.locator('.terrain-properties').isVisible(),true);assert.equal(await p.locator('#palette [data-asset="face-tijolos"]').count(),0);
 await p.locator('#groundPick').selectOption('chao-gelo');await p.mouse.click(ox+80,oy+80);const floor=await read();assert.deepEqual(floor.cliffs,painted.cliffs);
 await p.locator('[data-tool="height"]').click();await p.locator('#heightMode').selectOption('raise');await p.mouse.click(ox+80,oy+80);const raised=await read();assert(raised.levels.some((z,i)=>z>floor.levels[i]));assert.deepEqual(raised.cliffs,floor.cliffs);
 await p.locator('#wallsTab').click();await p.setViewportSize({width:1280,height:720});await p.mouse.move(10,10);await p.screenshot({path:'documentation/plant-lab-v1/captures/materials-walls-1280.png'});
 assert.deepEqual(errors,[]);await fs.writeFile('documentation/plant-lab-v1/captures/material-panels-check.json',JSON.stringify({passed:true,checks:['separate terrain/wall panels','14 wall thumbnails','thumbnail activates wall brush','face paint preserves terrain','floor and height edits preserve wall material','1440 and 1280 screenshots'],errors},null,2));console.log('PASS: separated panels and libraries; wall painting by mouse; independent floor, height and wall materials.');
}finally{await b.close();}
