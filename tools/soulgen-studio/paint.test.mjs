import test from 'node:test';
import assert from 'node:assert/strict';
import {applyPaintAsset,restorePaintAsset,paintTarget,openPaintEditor} from './paint.mjs';
import {validate,History} from './model.mjs';
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
 proto.getContext=function(){return get(this).getContext('2d');};proto.toDataURL=function(){return get(this).toDataURL('image/png');};proto.setPointerCapture=()=>{};proto.getBoundingClientRect=function(){return {left:0,top:0,width:this.width,height:this.height};};
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
 }finally{globalThis.document=prior;}
});
