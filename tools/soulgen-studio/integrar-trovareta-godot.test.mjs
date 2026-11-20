import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {buildEntry} from './integrar-trovareta-godot.mjs';
const root=new URL('../../',import.meta.url);
test('Godot Trovareta preserves the approved Soulgen atlas and every clip',()=>{
 const content=JSON.parse(fs.readFileSync(new URL('godot/assets/campaign/content.json',root)));
 assert.deepEqual(content.combat.trovareta,buildEntry());
 const source=fs.readFileSync(new URL('art/soulgen/keys/trovareta/cutout-rig-v1/study-atlas.png',root));
 assert.deepEqual(fs.readFileSync(new URL('godot/assets/campaign/trovareta-v1/soulgen-atlas.png',root)),source);
 assert.equal(Object.values(buildEntry().animations).reduce((n,a)=>n+a.length,0),123);
 assert.deepEqual(Object.keys(buildEntry().animations),['idle','flight','attack','hurt','victory','defeat']);
});
