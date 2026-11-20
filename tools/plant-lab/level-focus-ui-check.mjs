import fs from 'node:fs/promises';import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {initialLayout} from './model.mjs';import {pointOnLevel} from './level-focus.mjs';
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1440,height:900}}),errors=[];p.on('pageerror',e=>errors.push(e.message));
const read=async()=>{await p.waitForTimeout(320);return p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));};
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached',timeout:15000});
 const a=initialLayout();a.objects=[{id:1,asset:'capim-rabiola-a',x:400,y:380,flip:false,layer:'vegetation',collidable:false},{id:2,asset:'capim-rabiola-a',x:208,y:208,flip:false,layer:'vegetation',collidable:false}];a.levels.fill(0);a.ramps.fill(null);a.floors.fill('grass');a.nextId=3;
 for(let y=4;y<=8;y++)for(let x=4;x<=8;x++)a.levels[y*a.width+x]=3;
 await p.locator('#file').setInputFiles({name:'foco.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await read();await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();
 await p.locator('#focusLevel').selectOption('3');assert.equal(await p.locator('#focusToggle').getAttribute('aria-pressed'),'true');assert.equal(await p.locator('#focusLock').getAttribute('aria-pressed'),'true');assert.match(await p.locator('#focusBadge').textContent(),/protegidos/);
 await p.locator('#terrainTab').click();await p.locator('[data-floor="dirt"]').click();await p.locator('#brushSize').selectOption('4');const box=await p.locator('#canvas').boundingBox(),ox=box.x+Math.round((box.width-768)/2),oy=box.y+Math.round((box.height-512)/2);
 const before=await read();await p.mouse.move(ox+400,oy+192);await p.waitForTimeout(200);assert.match(await p.locator('#previewHint').textContent(),/protegido/);await p.mouse.click(ox+400,oy+192);assert.deepEqual(await read(),before);
 await p.mouse.click(ox+240,oy+192);const painted=await read();assert(painted.floors.some((k,i)=>k==='dirt'&&a.levels[i]===3));for(let i=0;i<a.levels.length;i++)if(a.levels[i]===0)assert.equal(painted.floors[i],'grass');
 await p.mouse.move(10,10);await p.screenshot({path:'documentation/plant-lab-v1/captures/focus-level-locked.png'});
 await p.locator('[data-tool="height"]').click();await p.locator('#heightMode').selectOption('raise');await p.mouse.click(ox+240,oy+192);const raised=await read();assert(raised.levels.some((z,i)=>z>a.levels[i]));for(let i=0;i<a.levels.length;i++)if(a.levels[i]===0)assert.equal(raised.levels[i],0);await p.locator('#undo').click();assert.deepEqual((await read()).levels,a.levels);
 await p.locator('[data-tool="select"]').click();await p.locator('#canvas').focus();await p.keyboard.press('Control+a');await p.keyboard.press('Delete');const deleted=await read();assert(deleted.objects.some(o=>o.id===1));assert(!deleted.objects.some(o=>o.id===2));await p.locator('#undo').click();
 await p.locator('#focusLock').click();await p.locator('[data-floor="dirt"]').click();await p.mouse.click(ox+400,oy+192);const free=await read();assert.equal(free.floors[6*a.width+12],'dirt');assert.match(await p.locator('#focusBadge').textContent(),/livre/);await p.locator('#focusLock').click();
 const document=await read();await p.reload();await p.waitForSelector('#loading[hidden]',{state:'attached'});assert.equal(await p.locator('#focusLevel').inputValue(),'3');assert.equal(await p.locator('#focusLock').getAttribute('aria-pressed'),'true');assert.deepEqual(await read(),document);
 await p.locator('#play').click();assert.equal(await p.locator('#focusBadge').isVisible(),false);await p.locator('#play').click();assert.equal(await p.locator('#focusBadge').isVisible(),true);
 const state=await read();assert.equal('focus' in state,false);assert(state.objects.every(o=>o.id!==2||pointOnLevel(state,o,3)));
 await p.locator('#focusToggle').click();assert.equal(await p.locator('#focusBadge').isVisible(),false);assert.deepEqual(await read(),state);
 assert.deepEqual(errors,[]);await fs.writeFile('documentation/plant-lab-v1/captures/level-focus-check.json',JSON.stringify({passed:true,checks:['locked lower floor','large floor and height brushes clipped','protected objects retained','unlock permits editing','preferences survive reload','play mode has no focus overlay','focus does not enter map JSON'],errors},null,2));console.log('PASS: focus lock, brush clipping, protected objects, unlock, preference persistence and play/JSON isolation.');
}finally{await b.close();}
