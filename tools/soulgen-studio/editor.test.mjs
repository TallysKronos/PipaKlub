import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
import * as model from './model.mjs';
import * as workflow from './workflow.mjs';
import {blankProject,createCarcara} from './carcara.mjs';
import {BASIC_CREATURES} from './basics.mjs';

async function editor(){
 const p=blankProject();p.assets.art={src:'data:image/png;base64,AAAA',width:4,height:4};p.parts=[{id:'body',name:'Corpo',asset:'art',source:[0,0,4,4],rect:[20,20,30,30],pivot:[35,35],z:0,parent:null,visible:true}];
 const {document,window}=parseHTML(fs.readFileSync(new URL('./index.html',import.meta.url),'utf8'));
 Object.defineProperty(window.HTMLSelectElement.prototype,'value',{configurable:true,get(){return this.getAttribute('data-value')??this.querySelector('option')?.getAttribute('value')??'';},set(v){this.setAttribute('data-value',String(v));}});
 const contexts=new WeakMap();window.HTMLCanvasElement.prototype.getContext=function(){if(!contexts.has(this)){const noop=()=>{};contexts.set(this,{canvas:this,clearRect:noop,save:noop,restore:noop,translate:noop,scale:noop,transform:noop,drawImage:noop,strokeRect:noop,setLineDash:noop,beginPath:noop,arc:noop,fill:noop,moveTo:noop,lineTo:noop,stroke:noop,getImageData:()=>({data:new Uint8ClampedArray(64)})});}return contexts.get(this);};
 for(const id of ['viewport','stage','source','timelineTrack'])document.getElementById(id).getBoundingClientRect=()=>({width:640,height:400,left:0,top:0});
 for(const dialog of document.querySelectorAll('dialog')){dialog.showModal=()=>{dialog.open=true;dialog.setAttribute('open','');};dialog.close=()=>{dialog.open=false;dialog.removeAttribute('open');dialog.onclose?.();};}
 const listeners=new Map(),context=vm.createContext({...model,...workflow,blankProject,createCarcara,BASIC_CREATURES,URLSearchParams,createBasic:async id=>({...model.clone(p),name:BASIC_CREATURES[id],creatureId:id}),createEremor:async()=>({...model.clone(p),name:"Eremor · Elo das Ruínas"}),document,console,URL,Blob,FileReader:class{},Image:class{width=4;height=4;naturalWidth=4;naturalHeight=4;async decode(){}},localStorage:{getItem(key){return key==='soulgen-studio-project-v1'?JSON.stringify(p):null;},setItem(){}},requestAnimationFrame(){},setTimeout(){return 1;},clearTimeout(){},addEventListener(name,fn){listeners.set(name,fn);},confirm(){throw Error('Unexpected blocking confirmation');},location:{reload(){}}});
 let source=fs.readFileSync(new URL('./studio.mjs',import.meta.url),'utf8').replace(/^import .*;\r?\n/gm,'');
 const api=await vm.runInContext('(async()=>{'+source+';return {project:()=>project,pose:()=>poseNow(),isDraft:()=>!!draft,pick:(at)=>({selected:containsPart(currentPart(),at),opaque:project.parts.filter(p=>opaquePart(p,at)).map(p=>p.id)})};})()',context);
 return {document,api,listeners,$:id=>document.getElementById(id)};
}
test('workflow changes expose the right controls and an unrecorded pose blocks leaving without modal or data loss',async()=>{
 const e=await editor();e.$('stepAnimation').onclick();assert.equal(e.document.body.dataset.phase,'animation');
 e.$('resetPose').onclick();assert.equal(e.api.isDraft(),true);e.$('stepReview').onclick();assert.equal(e.document.body.dataset.phase,'animation');assert.match(e.$('message').textContent,/Grave a pose/);assert.equal(e.api.isDraft(),true);
 e.$('discardDraft').onclick();e.$('stepReview').onclick();assert.equal(e.document.body.dataset.phase,'review');assert.equal(e.$('actionLibrary').querySelectorAll('button').length,Object.keys(e.api.project().clips).length);assert.equal(e.$('reviewPanel').open,true);
});
test('locking disables geometry and keyboard movement; isolated inspection leaves stored visibility intact',async()=>{
 const e=await editor(),before=JSON.stringify(e.api.project().parts[0].rect);e.$('toggleLock').onclick();assert.equal(e.api.project().parts[0].locked,true);assert.ok([...e.$('inspector').querySelectorAll('input,select')].every(n=>n.disabled));
 e.listeners.get('keydown')({target:e.document.body,key:'ArrowLeft',preventDefault(){}});assert.equal(JSON.stringify(e.api.project().parts[0].rect),before);
 e.$('toggleLock').onclick();e.listeners.get('keydown')({target:e.document.body,key:'ArrowRight',shiftKey:true,preventDefault(){}});assert.equal(e.api.project().parts[0].rect[0],30);assert.equal(e.api.project().parts[0].pivot[0],45);
 e.$('soloPart').onclick();assert.equal(e.api.project().parts[0].visible,true);assert.match(e.$('stageBadge').textContent,/ISOLADA/);e.$('stepReview').onclick();assert.doesNotMatch(e.$('stageBadge').textContent,/ISOLADA/);
});
test('copy paste, record, timeline navigation and layer search form a working editing flow',async()=>{
 const e=await editor();e.$('stepAnimation').onclick();const rotation=[...e.$('poseFields').querySelectorAll('label')].find(n=>n.textContent.includes('Rotação')).querySelector('input');rotation.value='25';rotation.onchange();e.$('copyPose').onclick();e.$('record').onclick();assert.equal(e.api.isDraft(),false);assert.equal(e.api.pose().values.body.rotation,25);
 e.$('nextKey').onclick();e.$('pastePose').onclick();assert.equal(e.api.pose().values.body.rotation,25);e.$('record').onclick();assert.equal(e.api.project().clips.idle.frames.at(-1).values.body.rotation,25);
 e.$('partSearch').value='inexistente';e.$('partSearch').oninput();assert.match(e.$('partList').textContent,/Nenhuma peça encontrada/);e.$('partSearch').value='corpo';e.$('partSearch').oninput();assert.equal(e.$('partList').querySelectorAll('.filtered').length,0);
});
test('new animation and project replacement use cancellable in-editor dialogs instead of native prompts',async()=>{
 const e=await editor(),before=JSON.stringify(e.api.project());
 const canceled=e.$('blank').onclick();assert.equal(e.$('commandDialog').open,true);e.$('commandCancel').onclick();await canceled;assert.equal(JSON.stringify(e.api.project()),before);
 const creating=e.$('newClip').onclick();assert.equal(e.$('commandInput').required,true);e.$('commandInput').value='Investida';e.$('commandForm').onsubmit({preventDefault(){}});await creating;
 assert.equal(e.document.body.dataset.phase,'animation');assert.equal(e.api.project().clips.investida.label,'Investida');assert.equal(e.api.project().clips.investida.frames.length,2);assert.equal(e.$('commandDialog').open,false);
});

test('Eremor preset uses the existing safe project replacement flow and can be canceled',async()=>{
 const e=await editor(),before=JSON.stringify(e.api.project());
 const canceled=e.$('eremor').onclick();assert.equal(e.$('commandDialog').open,true);
 e.$('commandCancel').onclick();await canceled;assert.equal(JSON.stringify(e.api.project()),before);
 const opening=e.$('eremor').onclick();
 e.$('commandForm').onsubmit({preventDefault(){}});await opening;
 await new Promise(resolve=>setImmediate(resolve));
 assert.equal(e.api.project().name,'Eremor · Elo das Ruínas');
 assert.equal(e.document.body.dataset.phase,'assembly');
 assert.equal(e.$('undo').disabled,false);
});

test('audit surfaces anatomical warnings and does not show a green approval for a disproportionate head',async()=>{
 const e=await editor(),p=e.api.project();
 p.parts.push({...model.clone(p.parts[0]),id:'head',name:'Cabeça',rect:[20,20,80,30],parent:'body',z:1});
 p.anatomy={version:1,ratios:[{part:'head',relativeTo:'body',min:.3,max:.5,label:'Cabeça / tronco'}],joints:[],behind:[]};
 e.$('validate').onclick();assert.equal(e.$('auditResult').dataset.state,'warning');
 assert.match(e.$('audit').textContent,/Cabeça \/ tronco/);assert.match(e.$('auditResult').textContent,/aviso/);
 p.parts[1].rect[2]=12;e.$('validate').onclick();assert.equal(e.$('auditResult').dataset.state,'ok');
});


test('selected rear piece remains draggable underneath foreground pieces; transparent pixels do not capture selection',async()=>{
 const e=await editor(),p=e.api.project();
 p.parts.push({...model.clone(p.parts[0]),id:'cover',name:'Frente',z:10});
 const pick=e.api.pick({x:30,y:30});assert.equal(pick.selected,true);assert.deepEqual(Array.from(pick.opaque),[]);
 e.$('stage').setPointerCapture=()=>{};
 // The canvas is 640x400; default project is 96x96, scale is 3.5.
 const scale=Math.min(640/p.width,400/p.height)*.84*Number(e.$('zoom').value);
 const event=(x,y)=>({clientX:320+(x-p.width/2)*scale,clientY:200+(y-p.height/2)*scale,pointerId:1});
 e.$('stage').onpointerdown(event(30,30));e.$('stage').onpointermove(event(34,32));e.$('stage').onpointerup();
 assert.ok(Math.abs(p.parts[0].rect[0]-24)<1e-8);assert.ok(Math.abs(p.parts[0].rect[1]-22)<1e-8);assert.equal(p.parts[1].rect[0],20);
});


test('layer controls cross tied depths instead of getting stuck and preserve anatomy parenting',async()=>{
 const e=await editor(),p=e.api.project();
 p.parts.push({...model.clone(p.parts[0]),id:'hindNear',name:'Perna próxima',z:0,parent:'body'}, {...model.clone(p.parts[0]),id:'hindFar',name:'Perna distante',z:0,parent:'body'});
 e.$('partSearch').oninput();
 e.$('partList').querySelector('[data-part="hindFar"]').onclick();
 e.$('layerBack').onclick();e.$('layerBack').onclick();
 const parts=e.api.project().parts,leg=parts.find(p=>p.id==='hindFar');
 assert.ok(leg.z<parts.find(p=>p.id==='body').z);assert.equal(leg.parent,'body');assert.equal(new Set(parts.map(p=>p.z)).size,3);
 e.$('layerFront').onclick();e.$('layerFront').onclick();assert.ok(leg.z>parts.find(p=>p.id==='body').z);
 await e.$('undo').onclick();assert.ok(e.api.project().parts.find(p=>p.id==='hindFar').z<2);
});


test('per-piece size rotation and both flips preserve pivots, other parts and saved animation channels',async()=>{
 const e=await editor(),p=e.api.project(),pivot=JSON.stringify(p.parts[0].pivot),clips=JSON.stringify(p.clips);
 p.parts.push({...model.clone(p.parts[0]),id:'leg',name:'Pata',z:1});
 const click=label=>{const b=[...e.$('inspector').querySelectorAll('button')].find(b=>b.textContent===label);assert.ok(b,label);b.onclick();};
 click('+ Tamanho');click('↷ 15°');click('↔ Inverter horizontal');click('↕ Inverter vertical');
 assert.equal(p.parts[0].artTransform.scale,1.1);assert.equal(p.parts[0].artTransform.rotation,15);assert.equal(p.parts[0].artTransform.flipX,true);assert.equal(p.parts[0].artTransform.flipY,true);
 assert.equal(p.parts[1].artTransform,undefined);assert.equal(JSON.stringify(p.parts[0].pivot),pivot);assert.equal(JSON.stringify(p.clips),clips);assert.equal(model.validate(p).ok,true);
 const center=model.point(model.artworkMatrix(p.parts[0]),...p.parts[0].pivot);assert.ok(Math.abs(center.x-35)<1e-8&&Math.abs(center.y-35)<1e-8);
 const original={x:22,y:28},world=model.point(model.artworkMatrix(p.parts[0]),original.x,original.y),back=model.artworkPoint(p.parts[0],world);assert.ok(Math.abs(back.x-original.x)<1e-8&&Math.abs(back.y-original.y)<1e-8);
 await e.$('undo').onclick();assert.equal(e.api.project().parts[0].artTransform.flipY,false);
 click('Restaurar tamanho, giro e inversões');assert.equal(e.api.project().parts[0].artTransform.scale,1);assert.equal(e.api.project().parts[0].artTransform.rotation,0);
});
