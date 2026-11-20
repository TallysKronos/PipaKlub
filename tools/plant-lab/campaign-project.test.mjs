import assert from 'node:assert/strict';
import test from 'node:test';
import {projectFromCampaign,repairImportedRamps,validateLayout} from './model.mjs';
import {heightAt,moveOnTerrain} from './terrain.mjs';

test('campaign maps become editable projects with an entry point and protected footprints',()=>{
  const w=8,h=8,cells=Array.from({length:w*h},()=>({material:'piso',level:0,ramp:null}));
  cells[3*w+3]={material:'terra',level:0,ramp:'v-',rampFrom:.5,rampTo:1};
  cells[4*w+3]={material:'terra',level:0,ramp:'v-',rampFrom:0,rampTo:.5};
  const native={schema:'overworld-godot-1',w,h,cells,spawn:{u:2,v:5},
    events:[{type:'saida',name:'Voltar',u:2,v:6,props:{destino:'centro'}}],
    pieces:[{asset:'arbusto',u:3,v:5,fu:2,fv:1,blocks:true}]};
  const before=JSON.stringify(native);
  const layout=projectFromCampaign(native);
  assert.equal(JSON.stringify(native),before);
  assert.deepEqual(layout.player,{x:80,y:176});
  assert.equal(layout.ramps[4*w+3],'n');
  assert.equal(layout.levels[3*w+3],0);
  assert.deepEqual(layout.rampProfiles[3*w+3],[.5,1]);
  assert.equal(layout.events[0].targetMap,'campaign-centro');
  assert.equal(layout.objects[0].asset,'arbusto-folha-pipa-a');
  assert.equal(layout.campaignBlocked[5*w+4],true);
  assert.ok(moveOnTerrain(validateLayout(layout),layout.player,{x:80,y:0}).x<96);
});

test('four native segments survive import and an existing painted copy is repaired without losing edits',()=>{
  const w=8,h=8;
  const cells=Array.from({length:w*h},(_,i)=>({material:'piso',level:i<2*w?1:0,ramp:null}));
  for(let row=2;row<=5;row++){
    cells[row*w+3]={material:'terra',level:0,ramp:'v-',rampFrom:(5-row)/4,rampTo:(6-row)/4};
  }
  const map={schema:'overworld-godot-1',w,h,cells,spawn:{u:3,v:6},pieces:[],events:[]};
  const legacy=projectFromCampaign(map,{legacyRamps:true});
  assert.equal(legacy.ramps.filter(Boolean).length,0);
  legacy.floors[0]='grass';
  const fixed=repairImportedRamps(legacy,map);
  assert.equal(fixed.floors[0],'grass');
  assert.equal(fixed.ramps.filter(Boolean).length,4);
  assert.equal(heightAt(fixed,112,112),.625);
  assert.equal(heightAt(fixed,112,144),.375);
  assert.ok(moveOnTerrain(fixed,fixed.player,{x:0,y:-170}).y<64);
  legacy.levels[2*w+3]=3;
  assert.throws(()=>repairImportedRamps(legacy,map),/edições no relevo/);
});
