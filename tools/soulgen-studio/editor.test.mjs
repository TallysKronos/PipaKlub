import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {parseHTML} from 'linkedom';
import * as model from './model.mjs';
import * as workflow from './workflow.mjs';
import {blankProject,createCarcara} from './carcara.mjs';

async function editor(){
 const p=blankProject();p.assets.art={src:'data:image/png;base64,AAAA',width:4,height:4};p.parts=[{id:'body',name:'Corpo',asset:'art',source:[0,0,4,4],rect:[20,20,30,30],pivot:[35,35],z:0,parent:null,visible:true}];
 const {document,window}=parseHTML(fs.readFileSync(new URL('./index.html',import.meta.url),'utf8'));
 Object.defineProperty(window.HTMLSelectElement.prototype,'value',{configurable:true,get(){return this.getAttribute('data-value')??this.querySelector('option')?.getAttribute('value')??'';},set(v){this.setAttribute('data-value',String(v));}});
 const contexts=new WeakMap();window.HTMLCanvasElement.prototype.getContext=function(){if(!contexts.has(this)){const noop=()=>{};contexts.set(this,{canvas:this,clearRect:noop,save:noop,restore:noop,translate:noop,scale:noop,transform:noop,drawImage:noop,strokeRect:noop,setLineDash:noop,beginPath:noop,arc:noop,fill:noop,moveTo:noop,lineTo:noop,stroke:noop,getImageData:()=>({data:new Uint8ClampedArray(64)})});}return contexts.get(this);};
 for(const id of ['viewport','stage','source','timelineTrack'])document.getElementById(id).getBoundingClientRect=()=>({width:640,height:400,left:0,top:0});
 for(const dialog of document.querySelectorAll('dialog')){dialog.showModal=()=>{dialog.open=true;dialog.setAttribute('open','');};dialog.close=()=>{dialog.open=false;dialog.removeAttribute('open');dialog.onclose?.();};}
 const listeners=new Map(),context=vm.createContext({...model,...workflow,blankProject,createCarcara,createEremor:async()=>({...model.clone(p),name:"Eremor · Elo das Ruínas"}),document,console,URL,Blob,FileReader:class{},Image:class{width=4;height=4;naturalWidth=4;naturalHeight=4;async decode(){}},localStorage:{getItem(key){return key==='soulgen-studio-project-v1'?JSON.stringify(p):null;},setItem(){}},requestAnimationFrame(){},setTimeout(){return 1;},clearTimeout(){},addEventListener(name,fn){listeners.set(name,fn);},confirm(){throw Error('Unexpected blocking confirmation');},location:{reload(){}}});
 let source=fs.readFileSync(new URL('./studio.mjs',import.meta.url),'utf8').replace(/^import .*;\r?\n/gm,'');
 const api=await vm.runInContext('(async()=>{'+source+';return {project:()=>project,pose:()=>poseNow(),isDraft:()=>!!draft};})()',context);
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
