import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
const a=JSON.parse(await fs.readFile('documentation/plant-lab-v1/cases/ramp-paint-tall-cliff.json','utf8'));
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1440,height:900}}),errors=[],out='documentation/plant-lab-v1/captures/';
p.on('pageerror',e=>errors.push(e.message));
const saved=()=>p.waitForFunction(()=>document.getElementById('saveState').textContent.startsWith('Salvo'));
async function load(a){await p.locator('#file').setInputFiles({name:'bordas.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await saved();}
async function fit(){await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();await p.mouse.move(10,10);}
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached'});
 const probe=structuredClone(a),i=7*a.width+11;probe.floors[i]='grass';await load(probe);await fit();
 await p.locator('#brushSize').selectOption('4');await p.locator('[data-floor="dirt"]').click();
 const box=await p.locator('#canvas').boundingBox(),ox=box.x+Math.round((box.width-768)/2),oy=box.y+Math.round((box.height-512)/2);
 await p.mouse.click(ox+368,oy+232);await saved();
 const edited=await p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));
 assert.equal(edited.floors[i],'dirt');assert.deepEqual(edited.floors.map((v,j)=>v!==probe.floors[j]?j:null).filter(v=>v!==null),[i]);
 await load(a);await fit();await p.screenshot({path:out+'paint-height-studio-after.png'});
 await p.setViewportSize({width:1920,height:1080});await fit();await p.locator('#zoomIn').click();
 const r=await p.locator('#canvas').boundingBox(),px=r.x+Math.round((r.width-1536)/2),py=r.y+Math.round((r.height-1024)/2);
 await p.mouse.move(10,10);
 await p.screenshot({path:out+'paint-ramp-detail-after.png',clip:{x:px+330*2,y:py+190*2,width:85*2,height:110*2}});
 await p.mouse.move(r.x+r.width/2,r.y+r.height/2);await p.mouse.down({button:'middle'});await p.mouse.move(r.x+r.width/2,r.y+r.height/2-120);await p.mouse.up({button:'middle'});await p.mouse.move(10,10);await p.screenshot({path:out+'height-wall-detail-after.png',clip:{x:px+330*2,y:py-120+355*2,width:260*2,height:110*2}});
 assert.deepEqual(errors,[]);await fs.writeFile(out+'paint-height-check.json',JSON.stringify({passed:true,checks:['pincel 4×4 altera somente a rampa de 1 tile','captura no editor','detalhes ampliados de terra pintada e barranco de 2 andares'],errors},null,2));console.log('PASS pintura real: pincel 4×4 contido na rampa; capturas ampliadas e sem erros.');
}finally{await b.close();}
