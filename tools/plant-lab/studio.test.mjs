import test from 'node:test';
import assert from 'node:assert/strict';
import {initialLayout,validateLayout} from './model.mjs';
import {fillFloor,blockedByObjects,layerFor} from './studio.mjs';
test('floor fill respects connectivity and height; is no-op on same material',()=>{const a=initialLayout();a.floors.fill('grass');a.levels.fill(0);a.ramps.fill(null);for(let y=0;y<a.height;y++)a.levels[y*a.width+8]=1;assert.equal(fillFloor(a,0,'dirt'),8*a.height);assert.equal(a.floors[9],'grass');assert.equal(fillFloor(a,0,'dirt'),0);});
test('collision blocks approach, allows exit and respects supporting height',()=>{const a=initialLayout();a.levels.fill(0);a.ramps.fill(null);a.objects=[{id:1,asset:'capim-rabiola-a',x:300,y:300,collidable:true,layer:'objects'}];assert(blockedByObjects(a,{x:300,y:315},{x:300,y:310}));assert(!blockedByObjects(a,{x:300,y:310},{x:300,y:315}));a.levels[9*a.width+9]=2;assert(!blockedByObjects(a,{x:300,y:325},{x:300,y:321}));});
test('legacy objects default to vegetation without collision; edits round trip',()=>{const a=initialLayout();delete a.objects[0].layer;delete a.objects[0].collidable;let b=validateLayout(a);assert.equal(b.objects[0].layer,'vegetation');assert.equal(b.objects[0].collidable,false);b.objects[0].layer='objects';b.objects[0].collidable=true;assert.deepEqual(validateLayout(b),b);assert.equal(layerFor({id:-1}),'characters');});

