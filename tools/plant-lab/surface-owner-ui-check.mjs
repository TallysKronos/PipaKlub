import fs from 'node:fs/promises';import assert from 'node:assert/strict';
import {chromium} from 'file:///C:/Users/user/produto/perchance-image-proxy/node_modules/playwright/index.mjs';
import {initialLayout} from './model.mjs';import {rasterPlan} from './terrain-raster.mjs';
const a=initialLayout();a.objects=[];a.levels.fill(0);a.ramps.fill(null);a.floors.fill('grass');
for(let y=4;y<=11;y++)for(let x=5;x<=16;x++)if((y>=7&&y<=8)||(x>=10&&x<=11))a.levels[y*a.width+x]=3;
const b=await chromium.launch({headless:true}),p=await b.newPage({viewport:{width:1920,height:1080}}),errors=[];
p.on('pageerror',e=>errors.push(e.message));const read=async()=>{await p.waitForTimeout(350);return p.evaluate(()=>JSON.parse(localStorage.getItem('soulmonsters.plant-lab.v1')));};
try{
 await p.goto('http://127.0.0.1:5256/');await p.waitForSelector('#loading[hidden]',{state:'attached'});
 await p.locator('#file').setInputFiles({name:'cantos.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(a))});await read();
 await p.locator('#fit').evaluate(el=>el.closest('details').open=true);await p.locator('#fit').click();await p.locator('#zoomIn').click();
 const box=await p.locator('#canvas').boundingBox(),ox=box.x+Math.round((box.width-1536)/2),oy=box.y+Math.round((box.height-1024)/2);
 await p.locator('#groundPick').selectOption('chao-calcamento');await p.locator('[data-tool="fill"]').click();await p.mouse.click(ox+336*2,oy+192*2);
 const painted=await read();for(let i=0;i<a.floors.length;i++)assert.equal(painted.floors[i],a.levels[i]===3?'chao-calcamento':'grass');
 await fs.writeFile('documentation/plant-lab-v1/cases/surface-corners.json',JSON.stringify(painted,null,2));
 const r=rasterPlan(painted);let corner;
 for(let n=0;n<r.top.length;n++)if(r.top[n]&&r.zmap[n]===3){const x=n%r.width,y=Math.floor(n/r.width)-r.pad,raw=Math.floor((y+48)/32)*a.width+Math.floor(x/32);if(a.levels[raw]===0){corner={x,y,cell:r.owner[n]};break;}}
 assert(corner,'Fixture must expose a rounded top outside its logical cell');
 await p.locator('[data-floor="dirt"]').click();await p.locator('#brushSize').selectOption('1');await p.mouse.click(ox+(corner.x+.5)*2,oy+(corner.y+.5)*2);
 const edge=await read();assert.equal(edge.floors[corner.cell],'dirt');for(let i=0;i<a.floors.length;i++)if(a.levels[i]===0)assert.equal(edge.floors[i],'grass');
 await p.locator('#undo').click();assert.deepEqual((await read()).floors,painted.floors);await p.mouse.move(10,10);
 await p.screenshot({path:'documentation/plant-lab-v1/captures/surface-corners-corrected.png',clip:{x:ox+140*2,y:oy+70*2,width:850,height:730}});
 assert.deepEqual(errors,[]);console.log('PASS: paving fills convex/concave upper contours, lower floor remains grass, edge click selects elevated donor.');
}finally{await b.close();}
