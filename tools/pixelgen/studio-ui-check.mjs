// Functional DOM check. The canvas is simulated; this does not validate browser layout.
import fs from 'node:fs';import vm from 'node:vm';import assert from 'node:assert/strict';import {parseHTML} from 'linkedom';
import * as core from './core.mjs';import * as doc from './document.mjs';import * as animation from './animation.mjs';
import * as legibility from './legibility.mjs';import {aseprite} from './aseprite.mjs';import {qualityReport} from './quality.mjs';import {godotResource} from './godot.mjs';
import * as skeleton from './skeleton.mjs';
import * as characterStyle from './character-style.mjs';
import {initAlbum} from './album.mjs';
const read=file=>fs.readFileSync(new URL(file,import.meta.url),'utf8');
const {window,document}=parseHTML(read('index.html'));
const painter={putImageData(){},drawImage(){},clearRect(){},fillRect(){},beginPath(){},moveTo(){},lineTo(){},stroke(){},strokeRect(){},save(){},restore(){},setLineDash(){}};
window.HTMLCanvasElement.prototype.getContext=()=>({...painter});
for(const e of document.querySelectorAll('select'))Object.defineProperty(e,'value',{value:e.querySelector('option[selected]')?.getAttribute('value')||e.querySelector('option')?.getAttribute('value'),writable:true});
const dialog=document.getElementById('libraryDialog');dialog.showModal=()=>{dialog.open=true;};dialog.close=()=>{dialog.open=false;};
const sample=JSON.parse(read('examples/kael-walk.pixelgen.json'));let saved,automatic=sample;
const storage={restore:async previous=>previous?undefined:automatic,automatic:async value=>automatic=value,save:async value=>{saved={...value,id:'saved-kael'};return saved.id;},list:async()=>saved?[{id:saved.id,name:saved.name,width:saved.width,height:saved.height,frames:saved.frames.length}]:[],load:async()=>saved};
let timerId=0;const timers=new Map(),downloads=[];
const context=vm.createContext({document,console,Uint8Array,Uint8ClampedArray,Map,Set,Number,Math,JSON,Array,String,Object,Error,Blob,File,
 URL:{createObjectURL:blob=>{downloads.push(blob);return 'blob:test';},revokeObjectURL:()=>{}},
 setTimeout:(fn,ms)=>{timers.set(++timerId,{fn,ms});return timerId;},clearTimeout:i=>timers.delete(i),localStorage:{getItem:()=>null},
 ImageData:class{constructor(data,width,height){Object.assign(this,{data,width,height});}},...core,...doc,...animation,...legibility,...characterStyle,...skeleton,structuredClone,initAlbum:options=>initAlbum({...options,request:null}),animationAtlas:animation.atlas,aseprite,qualityReport,godotResource,createStorage:()=>storage});
await vm.runInContext(read('app.mjs').replace(/^import .*;\r?\n/gm,'')+';ready',context);
const evaluate=code=>vm.runInContext(code,context),click=id=>document.getElementById(id).onclick();
assert.equal(document.querySelectorAll('.layer-row').length,2);assert.equal(document.querySelectorAll('.frame').length,4);
const before=evaluate('Array.from(project.frames[0].indices)');evaluate('selection={x:0,y:30,w:48,h:34}');document.getElementById('extractAll').checked=true;
click('extractPart');assert.equal(document.querySelectorAll('.layer-row').length,3);assert.deepEqual(evaluate('Array.from(project.frames[0].indices)'),before);
document.querySelector('.layer-row.active').children[2].onclick();click('nudgeRight');assert.deepEqual(evaluate('Array.from(project.frames[0].indices)'),before);assert.match(document.getElementById('status').textContent,/Desbloqueie/);click('undo');
document.getElementById('layerName').value='Corpo articulado';document.getElementById('layerName').onchange();assert.equal(evaluate('project.layers[activeLayer].name'),'Corpo articulado');click('layerToSequence');
click('duplicateFrame');assert.equal(document.querySelectorAll('.frame').length,5);click('undo');assert.equal(document.querySelectorAll('.frame').length,4);
document.getElementById('sequenceDirection').value='pingpong';document.getElementById('sequenceStart').value='1';document.getElementById('sequenceEnd').value='4';document.getElementById('sequenceLoop').checked=true;click('saveSequence');assert.equal(evaluate('sequence().direction'),'pingpong');
click('play');assert.equal(evaluate('playing'),true);click('play');
await click('saveLibrary');assert.equal(saved.frames.length,4);assert.equal(saved.layers.length,3);assert.equal(document.querySelectorAll('.project-entry').length,1);
click('saveProject');assert.equal(JSON.parse(await downloads.at(-1).text()).layers.length,3);click('exportGodot');assert.match(await downloads.at(-1).text(),/SpriteFrames/);
document.getElementById('newPreset').value='32x32';await click('createProject');assert.equal(evaluate('project.width'),32);assert.equal(document.querySelectorAll('.frame').length,1);click('deleteFrame');assert.match(document.getElementById('status').textContent,/Mantenha/);
await document.querySelector('.project-entry').onclick();assert.equal(evaluate('project.width'),48);assert.equal(evaluate('project.layers.length'),3);
click('outlineOuter');assert.equal(evaluate("project.layers.at(-1).name"),'Contorno');click('undo');
click('legibilityCheck');assert.ok(document.getElementById('legibilityResult').children.length>=5);
for(const b of document.querySelectorAll('[data-view]'))if(b.dataset.view==='silhouette')b.onclick();assert.equal(evaluate('view'),'silhouette');for(const b of document.querySelectorAll('[data-view]'))if(b.dataset.view==='pixel')b.onclick();
console.log('PASS DOM: layers, selection, locked edits, undo, propagation, frame controls, ping-pong, library, new/reopen, file and Godot export. Canvas simulated; visual layout not verified.');
// Full-sized directional library must remain selectable without changing its art or tags.
const kaelLibrary=read('../../art/characters/kael-eight-directions-v1/kael-library.pixelgen.json');
document.getElementById('onlySequence').checked=true; // linkedom does not reflect the HTML checked property.
context.kaelLibrary=kaelLibrary;await evaluate("openProject(new File([kaelLibrary],'kael-library.pixelgen.json'))");
assert.equal(evaluate('project.frames.length'),256);assert.equal(document.getElementById('directionBrowser').hidden,false);
document.getElementById('facingChoice').value='NE';document.getElementById('motionChoice').value='run';document.getElementById('facingChoice').onchange();
assert.equal(evaluate('sequence().name'),'run-NE');assert.equal(Array.from(document.querySelectorAll('.frame')).filter(f=>!f.hidden).length,6);
click('play');document.getElementById('facingChoice').value='SO';document.getElementById('motionChoice').value='walk';document.getElementById('motionChoice').onchange();
assert.equal(evaluate('playing'),true);assert.equal(evaluate('sequence().name'),'walk-SO');click('play');
document.getElementById('onlySequence').checked=false;document.getElementById('onlySequence').onchange();assert.equal(Array.from(document.querySelectorAll('.frame')).filter(f=>!f.hidden).length,256);
console.log('PASS Kael library DOM: 256 frames, direction/motion switching, six-frame run, filtered timeline and playback continuity.');
document.getElementById('newPreset').value='ds-48x64';document.getElementById('newBody').value='adulto';document.getElementById('newName').value='Professor DS';await click('createProject');
assert.equal(evaluate('project.style.body'),'adulto');assert.equal(evaluate('project.frames.length'),8);assert.equal(document.getElementById('previewScale').value,'1');
assert.equal(document.getElementById('characterStylePanel').hidden,false);assert.match(document.getElementById('characterStyleSummary').textContent,/3.5 cabeças/);
const dsBefore=evaluate('JSON.stringify(serialize(project))');document.getElementById('characterGuides').checked=false;document.getElementById('characterGuides').onchange();assert.equal(evaluate('JSON.stringify(serialize(project))'),dsBefore);
document.getElementById('baseReviewed').checked=true;document.getElementById('baseReviewed').onchange();assert.equal(evaluate('project.style.baseReviewed'),false);
click('saveProject');assert.equal(JSON.parse(await downloads.at(-1).text()).style.id,'soulmon-ds-v1');
console.log('PASS DS profile DOM: fresh base, anatomy guides, 1x preview, persistence and empty-art review guard.');

// Real event handlers, simulated canvas: moving a joint must never paint a pixel.
const rigNative=evaluate('Array.from(project.frames[0].indices)'),rigPose=evaluate('JSON.stringify(project.frames[0].pose)');
document.getElementById('skeletonEdit').checked=true;document.getElementById('skeletonEdit').onchange();
const canvas=document.getElementById('editor');canvas.getBoundingClientRect=()=>({left:0,top:0,width:48,height:64});canvas.setPointerCapture=()=>{};
const event=(type,x,y)=>{const e=new window.Event(type);Object.assign(e,{clientX:x,clientY:y,button:0,buttons:1,pointerId:1});canvas.dispatchEvent(e);};
const hand=evaluate('project.frames[0].pose.maoFrente');event('pointerdown',...hand);event('pointermove',hand[0]-3,hand[1]-4);event('pointerup',hand[0]-3,hand[1]-4);
assert.notEqual(evaluate('JSON.stringify(project.frames[0].pose)'),rigPose);assert.deepEqual(evaluate('Array.from(project.frames[0].indices)'),rigNative);
click('undo');assert.equal(evaluate('JSON.stringify(project.frames[0].pose)'),rigPose);
click('skeletonCopy');click('duplicateFrame');click('skeletonPaste');assert.equal(evaluate('Object.keys(project.frames[selected].pose).length'),14);
document.getElementById('supportFront').checked=false;document.getElementById('supportFront').onchange();assert.equal(evaluate('project.frames[selected].support.includes("peFrente")'),false);click('undo');assert.equal(evaluate('project.frames[selected].support.includes("peFrente")'),true);
click('skeletonExport');const rigExport=JSON.parse(await downloads.at(-1).text());assert.equal(rigExport.kind,'pixelgen-skeleton');assert.equal(rigExport.parents.maoFrente,'cotoveloFrente');
click('saveProject');const rigSaved=JSON.parse(await downloads.at(-1).text());assert.equal(Object.keys(rigSaved.frames[1].pose).length,14);assert.equal(rigSaved.frames[1].support.length,2);
console.log('PASS skeleton DOM: joint drag, IK, undo, duplicate/copy/paste, foot support, native pixels preserved, skeleton and project export.');
