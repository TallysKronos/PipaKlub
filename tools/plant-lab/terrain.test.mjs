import test from 'node:test';
import assert from 'node:assert/strict';
import {initialLayout,validateLayout,clone} from './model.mjs';
import {heightAt,project,pickTerrain,topRect,faceRect,pickSupport,moveOnTerrain,occluders,isOccluded} from './terrain.mjs';
test('legacy layouts migrate without changing plants',()=>{const a=initialLayout();delete a.levels;delete a.ramps;delete a.cliffs;const b=validateLayout(a);assert(b.levels.every(x=>x===0));assert.deepEqual(b.objects,a.objects);});
test('no internal walls; ramp mouth has no wall',()=>{const a=initialLayout(),w=a.width;assert.equal(faceRect(a,3*w+5),null);assert.equal(faceRect(a,4*w+5),null);assert.equal(faceRect(a,6*w+5),null);assert.equal(faceRect(a,6*w+4).h,16);});
test('ramp is continuous at both ends and pick inverts projection',()=>{const a=initialLayout();for(const y of [224,224.01,239,255.99,256]){const p={x:176,y},screen=project(a,p),pick=pickTerrain(a,screen);assert(Math.abs(pick.point.y-y)<.02);assert.equal(pick.kind,'top');}assert(heightAt(a,176,224.001)>.999);assert(heightAt(a,176,255.999)<.001);});
test('Kael climbs both terraces and descends; cannot cross cliff',()=>{const a=initialLayout();let p=moveOnTerrain(a,{x:176,y:280},{x:0,y:-170});assert.equal(p.y,110);assert.equal(heightAt(a,p.x,p.y),2);p=moveOnTerrain(a,p,{x:0,y:170});assert.equal(p.y,280);const blocked=moveOnTerrain(a,{x:144,y:280},{x:0,y:-100});assert(blocked.y>=220);assert.equal(heightAt(a,blocked.x,blocked.y),0);const r=moveOnTerrain(a,{x:592,y:340},{x:0,y:-150});assert.equal(heightAt(a,r.x,r.y),2);});
test('higher foreground occludes actor, same level preserves leaves',()=>{const a=initialLayout(),p={x:140,y:85};assert(isOccluded(a,p,{x:140,y:75}));assert(occluders(a,p).length>0);const flat=clone(a);flat.levels.fill(0);flat.ramps.fill(null);assert.equal(occluders(flat,p).length,0);});
test('reject malformed heights and disconnected ramps',()=>{const a=initialLayout();a.levels[0]=13;assert.throws(()=>validateLayout(a));a.levels[0]=0;a.ramps[0]='n';assert.throws(()=>validateLayout(a));});


test('12 storeys survive import; buried support can be picked independently',()=>{const a=initialLayout();a.levels[6*24+10]=12;assert.equal(validateLayout(a).levels[6*24+10],12);const p={x:336,y:145},visible=pickTerrain(a,p),behind=pickSupport(a,p,0);assert.notEqual(visible.cell,behind.cell);assert.equal(behind.cell,4*24+10);assert.equal(behind.point.y,145);assert.equal(pickSupport(a,{x:-10,y:0},0),null);});
