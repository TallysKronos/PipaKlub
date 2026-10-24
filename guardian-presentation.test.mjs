import test from 'node:test';
import assert from 'node:assert/strict';
import {guardianPresentation} from './src/guardian-presentation.js';
import {createAssetHandler} from './src/static-assets.js';
const rival={id:'boss',hp:190,bossPhase:1};
const snapshot={boss:{id:'lacertubo'},players:[{id:'me'},rival],phase:'countdown',last:0,phaseUntil:6600};

test('guardian warning follows countdown and clears before controls become live',()=>{
 for(const [last,stage,intro]of [[0,'arrive',true],[500,'hold',true],[3000,'leave',true],[3401,'hidden',false],[6600,'hidden',false]]){
  const state={...snapshot,last},before=JSON.stringify(state),view=guardianPresentation(state,rival);
  assert.equal(view.stage,stage);assert.equal(view.intro,intro);assert.equal(JSON.stringify(state),before,'presentation never advances simulation');
 }
 assert.equal(guardianPresentation({...snapshot,phase:'live'},rival).intro,false);
 assert.equal(guardianPresentation({...snapshot,boss:null},rival).active,false);
 assert.equal(guardianPresentation(null,null).intro,false);
});
test('danger and counterattack cues reflect actual boss intent and health',()=>{
 const live={...snapshot,phase:'live'};
 assert.equal(guardianPresentation(live,{...rival,bossTelegraph:.8}).intent,'charge');
 assert.equal(guardianPresentation(live,{...rival,bossRecovery:1}).intent,'opening');
 const phase2=guardianPresentation(live,{...rival,bossPhase:2,hp:95});assert.equal(phase2.phase,2);assert.equal(phase2.percent,50);assert.equal(phase2.maximum,190);
 assert.equal(guardianPresentation(live,{...rival,hp:-10}).health,0);
 assert.equal(guardianPresentation(live,{...rival,hp:250}).health,190);
});
test('generated boss art is served as images while production metadata stays private',async()=>{
 const serve=createAssetHandler();for(const name of ['frame','crest']){const r=await serve(new Request('http://local/assets/ui/guardian-veredas-v1/'+name+'.png'));assert.equal(r.status,200);assert.equal(r.headers.get('Content-Type'),'image/png');}
 assert.equal((await serve(new Request('http://local/assets/ui/guardian-veredas-v1/production.json'))).status,404);
});
