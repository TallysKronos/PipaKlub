import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {initialLayout} from './model.mjs';
const a=initialLayout();a.objects=[];a.levels.fill(0);a.ramps.fill(null);a.floors.fill('grass');
for(let y=4;y<=8;y++)for(let x=4;x<=8;x++)a.levels[y*a.width+x]=3;
const browser=await chromium.launch({headless:true}),p=await browser.newPage({viewport:{width:1440,height:900}}),errors=[];
p.on('pageerror',e=>errors.push(e.message));
const read=async()=>{await p.waitForTimeout(300);return p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));};
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached'});
 for(const size of [1,2,4]){
  await p.locator('#file').setInputFiles({name:'andares.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await read();
  await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();
  await p.locator('[data-floor="dirt"]').click();await p.locator('#brushSize').selectOption(String(size));
  const box=await p.locator('#canvas').boundingBox(),ox=box.x+Math.round((box.width-768)/2),oy=box.y+Math.round((box.height-512)/2);
  await p.mouse.move(ox+240,oy+192);await p.mouse.down();
  await p.mouse.move(ox+400,oy+192,{steps:1});await p.mouse.move(ox+208,oy+192,{steps:1});await p.mouse.up();
  const high=await read();assert(high.floors.some((k,i)=>k==='dirt'&&a.levels[i]===3));
  for(let i=0;i<a.floors.length;i++)if(a.levels[i]===0)assert.equal(high.floors[i],'grass',`Brush ${size} leaked at ${i}`);
  assert.deepEqual(high.levels,a.levels);assert.deepEqual(high.ramps,a.ramps);
  await p.mouse.click(ox+400,oy+192);const low=await read();assert.equal(low.floors[6*a.width+12],'dirt');
  await p.locator('#undo').click();assert.deepEqual((await read()).floors,high.floors);
  await p.locator('#undo').click();assert.deepEqual((await read()).floors,a.floors);
  await p.locator('#redo').click();assert.deepEqual((await read()).floors,high.floors);
 }
 await p.mouse.move(10,10);await p.screenshot({path:'documentation/plant-lab-v1/captures/stroke-level-protected.png'});
 assert.deepEqual(errors,[]);console.log('PASS: brushes 1/2/4 stay on initial storey; new click paints lower floor; undo/redo preserves strokes.');
}finally{await browser.close();}
