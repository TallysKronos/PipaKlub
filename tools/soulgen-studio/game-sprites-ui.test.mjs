import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
import {createRequire} from 'node:module';
import {createGameSpritesService} from './game-sprites-service.mjs';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
test('editor opens correct direction, preserves unsaved work and sends only selected crop to save',async()=>{
 const root=new URL('../../',import.meta.url).pathname.replace(/^\/([A-Za-z]:)/,'$1');
 const service=createGameSpritesService(root),data=await service.list();
 const {window,document}=parseHTML(await fs.readFile(new URL('game-sprites.html',import.meta.url),'utf8'));
 const backing=new WeakMap();
 const native=element=>{let c=backing.get(element);if(!c||c.width!==element.width||c.height!==element.height){c=createCanvas(Number(element.width)||300,Number(element.height)||150);backing.set(element,c);}return c;};
 window.HTMLCanvasElement.prototype.getContext=function(){const ctx=native(this).getContext('2d');return new Proxy(ctx,{get(target,key){if(key==='drawImage')return (image,...args)=>target.drawImage(image?.tagName==='CANVAS'?native(image):image,...args);const value=target[key];return typeof value==='function'?value.bind(target):value;},set(target,key,value){target[key]=value;return true;}});};
 window.HTMLCanvasElement.prototype.toDataURL=function(){return native(this).toDataURL('image/png');};
 for(const select of document.querySelectorAll('select'))Object.defineProperty(select,'value',{writable:true,value:''});
 // The constructor returns an image handle native Canvas accepts after decode.
 function Image(){const holder={};return new Proxy(holder,{set(t,k,v){t[k]=v;return true;},get(t,k){if(k==='decode')return async()=>{const im=await loadImage(t.src.startsWith('data:')?t.src:await service.image(t.src.includes('kael-mounted')?'kael-mounted':'doberman-c'));t.image=im;t.width=im.width;t.height=im.height;};return t[k];}});}
 const previous=window.HTMLCanvasElement.prototype.getContext;
 window.HTMLCanvasElement.prototype.getContext=function(){const ctx=previous.call(this);return new Proxy(ctx,{get(t,k){if(k==='drawImage')return (im,...args)=>t.drawImage(im?.image||im,...args);return t[k];},set(t,k,v){t[k]=v;return true;}});};
 let painted=0,saved;
 const context=vm.createContext({document,window:{addEventListener(){}},Image,console,confirm:()=>false,
  fetch:async(url,options)=>({ok:true,json:async()=>{if(!options)return structuredClone(data);saved=JSON.parse(options.body);return {revision:'updated'};}}),
  openPaintEditor:async({part,images})=>{painted++;assert.equal(part.source[2],384);assert.equal(part.source[3],512);const c=createCanvas(384,512);const ctx=c.getContext('2d');ctx.drawImage(native(images.source),0,0);ctx.clearRect(20,20,2,2);return {src:c.toDataURL('image/png')};}
 });
 const source=(await fs.readFile(new URL('game-sprites.mjs',import.meta.url),'utf8')).replace(/^import[^\n]+\n/,'');
 vm.runInContext(source,context);
 for(let i=0;i<100&&document.getElementById('paint').disabled;i++)await new Promise(r=>setTimeout(r,10));
 assert.equal(document.getElementById('paint').disabled,false);assert.match(document.getElementById('title').textContent,/Kael montado.*SE/);
 await document.getElementById('paint').onclick();assert.equal(painted,1);assert.equal(document.getElementById('save').disabled,false);
 const direction=document.getElementById('direction');direction.value='n';direction.onchange();assert.equal(document.getElementById('save').disabled,true);
 direction.value='se';direction.onchange();assert.equal(document.getElementById('save').disabled,false);
 await document.getElementById('save').onclick();assert.equal(saved.direction,'se');assert.equal(saved.revision,data.assets.find(a=>a.id==='kael-mounted').revision);assert.match(saved.png,/^data:image\/png;base64,/);assert.equal(document.getElementById('save').disabled,true);assert.match(document.getElementById('status').textContent,/Salvo no jogo com backup/);
});
