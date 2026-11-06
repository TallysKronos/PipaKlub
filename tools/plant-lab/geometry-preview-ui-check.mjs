import fs from 'node:fs/promises';import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {initialLayout} from './model.mjs';import {geometryEdit} from './geometry-edit.mjs';
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1440,height:900}}),errors=[];p.on('pageerror',e=>errors.push(e.message));
const read=async()=>{await p.waitForTimeout(300);return p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));};
const ready=async(text)=>p.waitForFunction(text=>{const e=document.getElementById('previewHint');return !e.hidden&&!e.textContent.includes('Calculando')&&e.textContent.includes(text);},text);
async function load(a){await p.locator('#file').setInputFiles({name:'volume.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await read();await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();await p.waitForTimeout(100);}
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached',timeout:15000});
 const a=initialLayout();a.objects=[];await load(a);await p.locator('[data-tool="height"]').click();await p.locator('#brushSize').selectOption('2');await p.locator('#heightMode').selectOption('raise');
 const box=await p.locator('#canvas').boundingBox(),ox=box.x+Math.round((box.width-768)/2),oy=box.y+Math.round((box.height-512)/2);
 const saved=await read();await p.mouse.move(ox+112,oy+192);await ready('Subir');assert.deepEqual(await read(),saved);assert.equal(await p.locator('#previewHint').getAttribute('data-state'),'valid');await p.screenshot({path:'documentation/plant-lab-v1/captures/preview-height-volume.png'});
 await p.mouse.click(ox+112,oy+192);const raised=await read(),expected=geometryEdit(a,{tool:'height',cell:6*a.width+3,size:2,mode:'raise'}).next;assert.deepEqual(raised.levels,expected.levels);assert.deepEqual(raised.ramps,expected.ramps);assert.deepEqual(raised.cliffs,a.cliffs);
 await p.locator('#undo').click();assert.deepEqual((await read()).levels,a.levels);await p.locator('#redo').click();assert.deepEqual((await read()).levels,expected.levels);
 const ramp=structuredClone(a);ramp.ramps[7*a.width+5]=null;ramp.ramps[7*a.width+6]=null;await load(ramp);await p.locator('[data-tool="ramp"]').click();await p.mouse.move(ox+176,oy+240);await ready('ligação válida');assert.deepEqual((await read()).ramps,ramp.ramps);await p.screenshot({path:'documentation/plant-lab-v1/captures/preview-ramp-volume.png'});
 await p.mouse.click(ox+176,oy+240);const placed=await read();assert.equal(placed.ramps[7*a.width+5],'n');await p.keyboard.down('Shift');await ready('Remover rampa');await p.screenshot({path:'documentation/plant-lab-v1/captures/preview-ramp-remove.png'});await p.mouse.click(ox+176,oy+240);await p.keyboard.up('Shift');assert.equal((await read()).ramps[7*a.width+5],null);
 // The final pointer target must win even if an older worker calculation finishes later.
 for(let i=0;i<8;i++)await p.mouse.move(ox+112+i*16,oy+120);
 await p.mouse.move(ox+336,oy+400);await ready('subida');assert.equal(await p.locator('#previewHint').getAttribute('data-state'),'invalid');const invalid=await read();await p.mouse.click(ox+336,oy+400);assert.deepEqual(await read(),invalid);await p.screenshot({path:'documentation/plant-lab-v1/captures/preview-ramp-invalid.png'});
 assert.deepEqual(errors,[]);await fs.writeFile('documentation/plant-lab-v1/captures/geometry-preview-check.json',JSON.stringify({passed:true,checks:['read-only height hover','height commit matches preview plan','undo redo','ramp creation preview','shift removal preview','invalid ramp reason','stale worker results rejected'],errors},null,2));console.log('PASS: height/ramp volume previews, unchanged hover, matching commit, undo/redo and invalid-ramp explanation.');
}finally{await b.close();}
