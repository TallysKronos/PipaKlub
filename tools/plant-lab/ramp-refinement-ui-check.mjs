import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {terrainHeight} from './terrain-field.mjs';
const a=JSON.parse(await fs.readFile('documentation/plant-lab-v1/cases/ramp-user-2026-11-06.json','utf8'));
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1440,height:900}}),out='documentation/plant-lab-v1/captures/',errors=[];
p.on('pageerror',e=>errors.push(e.message));
async function load(a){await p.locator('#file').setInputFiles({name:'rampas.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await p.waitForFunction(()=>document.getElementById('saveState').textContent.startsWith('Salvo'));}
async function fit(){await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();await p.mouse.move(10,10);}
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached'});await load(a);await fit();await p.screenshot({path:out+'ramp-user-after-studio.png'});
 const bare=structuredClone(a);bare.objects=[];await load(bare);await p.setViewportSize({width:1920,height:1080});await fit();await p.locator('#zoomIn').click();
 const box=await p.locator('#canvas').boundingBox();await p.mouse.move(box.x+box.width/2,box.y+box.height/2);await p.mouse.down({button:'middle'});await p.mouse.move(box.x+box.width/2,box.y+box.height/2+140);await p.mouse.up({button:'middle'});await p.mouse.move(10,10);
 const ox=box.x+Math.round((box.width-1536)/2),oy=box.y+Math.round((box.height-1024)/2)+140;
 for(const [name,x,y,w,h]of [['terra',105,105,175,185],['rocha',510,155,185,195],['grama',320,0,145,275]])await p.screenshot({path:out+'ramp-user-joints-'+name+'.png',clip:{x:ox+x*2,y:oy+y*2,width:w*2,height:h*2}});
 await p.setViewportSize({width:1440,height:900});const routes=[];
 for(const [x,y]of [[176,350],[208,350],[592,390],[624,390]]){
  const m=structuredClone(bare);m.player={x,y};await load(m);await p.locator('#play').click();await p.keyboard.down('Shift');await p.keyboard.down('w');await p.waitForTimeout(2200);await p.keyboard.up('w');await p.keyboard.up('Shift');await p.locator('#play').click();
  await p.waitForFunction(()=>document.getElementById('saveState').textContent.startsWith('Salvo'));const upper=await p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));assert.equal(terrainHeight(upper,upper.player.x,upper.player.y),2);
  await p.locator('#play').click();await p.keyboard.down('Shift');await p.keyboard.down('s');await p.waitForTimeout(2200);await p.keyboard.up('s');await p.keyboard.up('Shift');await p.locator('#play').click();
  await p.waitForFunction(()=>document.getElementById('saveState').textContent.startsWith('Salvo'));const lower=await p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));assert.equal(terrainHeight(lower,lower.player.x,lower.player.y),0);routes.push({x,upper:upper.player,lower:lower.player});
 }
 assert.deepEqual(errors,[]);await fs.writeFile(out+'ramp-refinement-check.json',JSON.stringify({routes,errors,passed:true},null,2));console.log('PASS mapa do usuário: quatro percursos por teclado, ida e volta, capturas das juntas e zero erros.');
}finally{await b.close();}
