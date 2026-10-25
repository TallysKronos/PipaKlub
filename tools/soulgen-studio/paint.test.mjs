import test from 'node:test';
import assert from 'node:assert/strict';
import {applyPaintAsset,restorePaintAsset,paintTarget,openPaintEditor,stabilizedPoint,drawPaintContext,paintContextMatrix,sourcePaintPoint,paletteFromPixels} from './paint.mjs';
import {validate,History,point as matrixPoint} from './model.mjs';
import {parseHTML} from 'linkedom';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const png=()=>createCanvas(4,4).toDataURL('image/png');
function fixture(){return {schema:'soulgen-studio',version:1,name:'Paint',width:100,height:100,rootPivot:[50,50],assets:{atlas:{src:png(),width:4,height:4}},parts:[{id:'body',name:'Corpo',asset:'atlas',source:[1,1,2,2],rect:[20,20,40,40],pivot:[40,40],parent:null,z:1,visible:true,faces:{happy:{asset:'atlas',source:[0,0,2,2]}}},{id:'copy',name:'Cópia',asset:'atlas',source:[1,1,2,2],rect:[60,60,20,20],pivot:[70,70],parent:null,z:0,visible:true}],clips:{idle:{seconds:1,loop:true,frames:[{t:0,values:{}},{t:1,values:{}}],expressions:[]}}};}
test('paint isolates shared atlas and expression assets without changing geometry, transforms or clips',()=>{
 const p=fixture(),before=structuredClone(p),history=new History();history.push(p);
 const id=applyPaintAsset(p,'body','normal',png());
 assert.notEqual(id,'atlas');assert.equal(p.parts[1].asset,'atlas');assert.deepEqual(p.parts[0].faces,before.parts[0].faces);
 assert.deepEqual(p.parts[0].rect,before.parts[0].rect);assert.deepEqual(p.parts[0].pivot,before.parts[0].pivot);assert.deepEqual(p.clips,before.clips);
 assert.deepEqual(p.parts[0].source,[0,0,2,2]);assert.equal(p.assets[id].width,2);
 assert.deepEqual(history.undo(p),before);assert.equal(validate(p).ok,true);
 const faceId=applyPaintAsset(p,'body','happy',png());assert.equal(p.parts[0].asset,id);assert.equal(p.parts[0].faces.happy.asset,faceId);
 applyPaintAsset(p,'body','normal',png());assert.deepEqual(p.parts[0].paintOriginals.normal,{asset:'atlas',source:[1,1,2,2]});
 assert.equal(restorePaintAsset(p,'body','normal'),true);assert.equal(p.parts[0].asset,'atlas');assert.equal(p.parts[0].faces.happy.asset,faceId);
 restorePaintAsset(p,'body','happy');assert.deepEqual(p.parts[0].faces,before.parts[0].faces);
 const imported=JSON.parse(JSON.stringify(p));assert.equal(restorePaintAsset(imported,'body','normal'),true);assert.throws(()=>paintTarget(p.parts[1],'hurt'));
});

test('paint dialog draws, erases, picks colors, undoes and returns actual cropped PNG pixels',async()=>{
 const prior=globalThis.document,{document,window}=parseHTML('<html><body></body></html>');globalThis.document=document;
 const backing=new WeakMap(),proto=window.HTMLCanvasElement.prototype;
 const get=c=>{if(!backing.has(c))backing.set(c,createCanvas(300,150));return backing.get(c);};
 for(const key of ['width','height'])Object.defineProperty(proto,key,{configurable:true,get(){return get(this)[key];},set(v){get(this)[key]=Number(v);}});
 proto.getContext=function(){const ctx=get(this).getContext('2d');if(!ctx._wrapped){const native=ctx.drawImage;ctx.drawImage=function(im,...args){return native.call(this,backing.has(im)?get(im):im,...args);};ctx._wrapped=true;}return ctx;};proto.toDataURL=function(){return get(this).toDataURL('image/png');};proto.setPointerCapture=()=>{};proto.getBoundingClientRect=function(){return {left:0,top:0,width:this.width,height:this.height};};
 document.createElement('dialog').constructor.prototype.showModal=function(){this.open=true;};
 document.createElement('dialog').constructor.prototype.close=function(){this.open=false;};
 Object.defineProperty(window.HTMLSelectElement.prototype,'value',{configurable:true,get(){return this.getAttribute('data-value')??this.querySelector('option')?.getAttribute('value')??'';},set(v){this.setAttribute('data-value',String(v));}});
 try{
  const source=createCanvas(4,4),sg=source.getContext('2d');sg.fillStyle='#0000ff';sg.fillRect(0,0,4,4);
  const p=fixture(),promise=openPaintEditor({part:p.parts[0],assets:p.assets,images:{atlas:source}}),d=document.querySelector('dialog'),c=d.querySelector('canvas'),$=id=>d.querySelector('[data-id="'+id+'"]');
  assert.equal(c.width,2);assert.equal(c.height,2);
  $('color').value='#ff0000';$('size').value='1';$('opacity').value='100';
  const point={button:0,pointerId:1,clientX:.5,clientY:.5,preventDefault(){}};
  c.onpointerdown(point);c.onpointerup();assert.ok(c.getContext('2d').getImageData(0,0,1,1).data[0]>0);
  $('undo').onclick();assert.equal(c.getContext('2d').getImageData(0,0,1,1).data[0],0);$('redo').onclick();
  $('tool').value='pick';c.onpointerdown(point);assert.match($('color').value,/^#[0-9a-f]{6}$/);
  $('tool').value='erase';$('size').value='8';c.onpointerdown(point);c.onpointerup();assert.equal(c.getContext('2d').getImageData(0,0,1,1).data[3],0);
  $('undo').onclick();$('apply').onclick();const result=await promise,im=await loadImage(result.src);assert.equal(im.width,2);assert.equal(im.height,2);assert.equal(result.face,'normal');assert.equal(document.querySelector('dialog'),null);
  const wide=createCanvas(32,32),part={...p.parts[0],source:[0,0,32,32]},pending=openPaintEditor({part,assets:p.assets,images:{atlas:wide}}),panel=document.querySelector('dialog'),pc=panel.querySelector('canvas'),control=id=>panel.querySelector('[data-id="'+id+'"]');
  const evt=(x,y)=>({button:0,pointerId:2,clientX:x,clientY:y,preventDefault(){}});
  control('tip').value='line';control('size').value='1';control('color').value='#ff0000';
  pc.onpointerdown(evt(2.5,2.5));pc.onpointermove(evt(25.5,2.5));assert.ok(pc.getContext('2d').getImageData(20,2,1,1).data[3]>0);
  pc.onpointermove(evt(2.5,25.5));assert.equal(pc.getContext('2d').getImageData(20,2,1,1).data[3],0);pc.onpointerup();
  control('undo').onclick();control('tip').value='soft';control('size').value='10';pc.onpointerdown(evt(16.5,16.5));pc.onpointerup();
  const center=pc.getContext('2d').getImageData(16,16,1,1).data[3],edge=pc.getContext('2d').getImageData(20,16,1,1).data[3];assert.ok(center>edge&&edge>0);
  control('undo').onclick();control('tip').value='pixel';control('size').value='1';pc.onpointerdown(evt(10.3,10.4));pc.onpointerup();assert.equal(pc.getContext('2d').getImageData(10,10,1,1).data[3],255);assert.equal(pc.getContext('2d').getImageData(11,10,1,1).data[3],0);
  control('undo').onclick();control('tip').value='watercolor';control('tip').onchange();control('size').value='10';pc.onpointerdown(evt(16.5,16.5));pc.onpointerup();const wash=pc.getContext('2d').getImageData(16,16,1,1).data[3];assert.ok(wash>0&&wash<255);
  control('undo').onclick();control('tip').value='ink';control('tip').onchange();control('smooth').value='0';control('pressure').checked=true;
  pc.onpointerdown({...evt(3,16),pointerType:'pen',pressure:.1});pc.onpointermove({...evt(10,16),pointerType:'pen',pressure:.1});pc.onpointermove({...evt(25,16),pointerType:'pen',pressure:1});pc.onpointerup();
  const thin=pc.getContext('2d').getImageData(6,14,1,1).data[3],thick=pc.getContext('2d').getImageData(20,14,1,1).data[3];assert.ok(thick>thin);
  control('tip').value='pixel';control('size').value='8';pc.getBoundingClientRect=()=>({left:0,top:0,width:64,height:64});pc.onpointermove(evt(32,32));assert.equal(control('cursor').style.width,'16px');assert.equal(control('cursor').style.borderRadius,'0');
  const eraser=panel.querySelector('[data-tool="erase"]');eraser.onclick();assert.equal(eraser.getAttribute('aria-pressed'),'true');assert.equal(control('cursor').dataset.tool,'erase');
  control('apply').onclick();assert.ok((await pending).src.startsWith('data:image/png;base64,'));
  const mounted=fixture();mounted.parts[0].source=[0,0,32,32];mounted.assets.atlas.width=32;mounted.assets.atlas.height=32;mounted.parts[0].artTransform={rotation:35,scale:1.2,flipX:true,flipY:false};
  const masked=createCanvas(32,32),mg=masked.getContext('2d');mg.fillStyle='#0000ff';mg.fillRect(8,8,16,16);mg.globalAlpha=.4;mg.fillRect(4,4,3,3);
  const next=openPaintEditor({part:mounted.parts[0],assets:mounted.assets,images:{atlas:masked},project:mounted}),dd=document.querySelector('dialog'),q=id=>dd.querySelector('[data-id="'+id+'"]'),main=dd.querySelector('canvas'),scene=q('contextCanvas');
  q('inPlace').checked=true;q('inPlace').onchange();assert.equal(q('contextPanel').hidden,false);assert.equal(dd.classList.contains('paint-in-place'),true);
  q('alphaLock').checked=true;q('alphaLock').onchange();q('color').value='#ff0000';q('size').value='160';const beforeAlpha=main.getContext('2d').getImageData(0,0,32,32).data;
  const matrix=paintContextMatrix(mounted,'body',scene.width,scene.height,32,32),where=matrixPoint(matrix,16,16);scene.onpointerdown(evt(where.x,where.y));scene.onpointerup();
  const afterAlpha=main.getContext('2d').getImageData(0,0,32,32).data;for(let i=3;i<afterAlpha.length;i+=4)assert.equal(afterAlpha[i],beforeAlpha[i]);assert.ok(afterAlpha[(16*32+16)*4]>0);
  assert.equal(dd.querySelector('[data-tool="erase"]').disabled,true);
  q('color').value='#123456';q('addColor').onclick();assert.ok(q('palette').querySelector('[aria-label="Usar cor #123456"]'));
  q('apply').onclick();const applied=await next;assert.ok(applied.palette.includes('#123456'));const restoredImage=await loadImage(applied.src);assert.equal(restoredImage.width,32);assert.equal(restoredImage.height,32);


 }finally{globalThis.document=prior;}
});

test('stabilization damps jumps without overshooting and can be disabled',()=>{assert.deepEqual(stabilizedPoint({x:0,y:0},{x:10,y:20},0),{x:10,y:20});const p=stabilizedPoint({x:0,y:0},{x:10,y:20},80);assert.ok(p.x>0&&p.x<10&&p.y>0&&p.y<20);});

test('context preview ghosts other parts, updates painted crop live, and never mutates project',()=>{
 const p=fixture(),before=structuredClone(p),atlas=createCanvas(4,4),g=atlas.getContext('2d');g.fillStyle='#0000ff';g.fillRect(0,0,4,4);
 const edited=createCanvas(2,2),e=edited.getContext('2d');e.fillStyle='#ff0000';e.fillRect(0,0,2,2);
 const out=createCanvas(100,100),ctx=out.getContext('2d');drawPaintContext(ctx,p,{atlas},'body','normal',edited,.25);
 assert.equal(ctx.getImageData(40,40,1,1).data[3],255);assert.ok(ctx.getImageData(68,68,1,1).data[3]<80);assert.ok(ctx.getImageData(68,68,1,1).data[2]>0);
 e.fillStyle='#00ff00';e.fillRect(0,0,2,2);drawPaintContext(ctx,p,{atlas},'body','normal',edited,.25);assert.equal(ctx.getImageData(40,40,1,1).data[1],255);assert.deepEqual(p,before);
 assert.ok(stabilizedPoint({x:0,y:0},{x:10,y:10},98).x<stabilizedPoint({x:0,y:0},{x:10,y:10},80).x);
});

test('montage coordinates invert flipped rotated artwork without changing source or geometry',()=>{
 const p=fixture();p.parts[0].artTransform={rotation:42,scale:1.8,flipX:true,flipY:true};const m=paintContextMatrix(p,'body',640,480,2,2),v=matrixPoint(m,.4,1.7),r=sourcePaintPoint(m,v.x,v.y);assert.ok(Math.abs(r.x-.4)<1e-9);assert.ok(Math.abs(r.y-1.7)<1e-9);
});
test('palette ignores transparent colors and returns actual source colors',()=>{
 const colors=paletteFromPixels([new Uint8ClampedArray([255,0,0,255,255,0,0,255,0,255,0,255,0,0,255,0])]);assert.deepEqual(colors,['#ff0000','#00ff00']);
});
