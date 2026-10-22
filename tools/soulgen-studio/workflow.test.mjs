import test from 'node:test';
import assert from 'node:assert/strict';
import {blankProject} from './carcara.mjs';
import {identity,clone,matrices} from './model.mjs';
import {adjacentKey,nudgePart,copiedPose,pastedPose,timelineMarks,visibleProject,opaqueBounds,trimPart} from './workflow.mjs';

const part=()=>({id:'body',name:'Corpo',rect:[20,30,40,20],source:[10,10,8,4],pivot:[30,40],visible:true,parent:null});
test('keyboard nudges preserve the anatomical pivot offset and locked parts refuse movement',()=>{
 const p={parts:[part()]};nudgePart(p,'body',-10,1);assert.deepEqual(p.parts[0].rect,[10,31,40,20]);assert.deepEqual(p.parts[0].pivot,[20,41]);
 const before=clone(p);p.parts[0].locked=true;assert.throws(()=>nudgePart(p,'body',1,0),/Desbloqueie/);assert.deepEqual(p.parts[0].rect,before.parts[0].rect);assert.throws(()=>nudgePart(p,'root',1,0));
});
test('copy and paste isolate the selected channel without mutating the saved pose or clipboard',()=>{
 const p=blankProject();p.parts=[part()];const id=Object.keys(p.clips)[0],draft={t:.2,face:'normal',values:{root:identity(),body:{...identity(),rotation:32}}};
 const saved=JSON.stringify(p),copied=copiedPose(p,id,.2,'body',draft);const next=pastedPose(p,id,.5,'root',copied);
 assert.equal(next.values.root.rotation,32);assert.equal(next.values.body.rotation,0);next.values.root.rotation=12;assert.equal(copied.rotation,32);assert.equal(draft.values.body.rotation,32);assert.equal(JSON.stringify(p),saved);
});
test('timeline positions are proportional and navigation skips the current key with bounded endpoints',()=>{
 const clip={seconds:2,frames:[{t:2},{t:0},{t:.4},{t:1.7}]};assert.equal(adjacentKey(clip,.4,1),1.7);assert.equal(adjacentKey(clip,.4,-1),0);assert.equal(adjacentKey(clip,2,1),2);assert.equal(adjacentKey(clip,0,-1),0);assert.deepEqual(timelineMarks(clip).map(m=>m.percent),[100,0,20,85]);
});
test('isolating the viewport retains parent transforms and never changes visibility for exports',()=>{
 const p=blankProject();p.parts=[part(),{...part(),id:'wing',parent:'body'}];const before=JSON.stringify(p),isolated=visibleProject(p,'wing');
 assert.equal(isolated.parts[0].visible,false);assert.equal(isolated.parts[1].visible,true);assert.equal(isolated.parts[1].parent,'body');assert.equal(JSON.stringify(p),before);
 const pose={values:{root:identity(),body:{...identity(),x:4},wing:identity()}};assert.deepEqual(matrices(isolated,pose),matrices(p,pose));assert.equal(visibleProject(p,null),p);
});
test('alpha trimming preserves the world position of visible pixels and keeps the fixed pivot',()=>{
 const pixels=new Uint8ClampedArray(8*4*4);for(let y=1;y<=2;y++)for(let x=2;x<=5;x++)pixels[(y*8+x)*4+3]=255;
 const bounds=opaqueBounds(pixels,8,4);assert.deepEqual(bounds,[2,1,4,2]);const p=part();trimPart(p,bounds);
 assert.deepEqual(p.source,[12,11,4,2]);assert.deepEqual(p.rect,[30,35,20,10]);assert.deepEqual(p.pivot,[30,40]);assert.equal(opaqueBounds(new Uint8Array(16),2,2),null);
});
test('auto trim refuses registered faces, locked art and empty crops without partial mutation',()=>{
 for(const changes of [{faces:{happy:{}}},{locked:true}]){const p={...part(),...changes},before=JSON.stringify(p);assert.throws(()=>trimPart(p,[0,0,1,1]));assert.equal(JSON.stringify(p),before);}
 const p=part(),before=JSON.stringify(p);assert.throws(()=>trimPart(p,null));assert.throws(()=>trimPart(p,[0,0,999,4]));assert.equal(JSON.stringify(p),before);
});
