import test from 'node:test';
import assert from 'node:assert/strict';
import {createSwitchNav} from './src/switch-nav.js';
const nav=createSwitchNav();
const box=(id,x,y,w=100,h=40)=>({id,x:x+w/2,y:y+h/2,left:x,right:x+w,top:y,bottom:y+h});
test('spatial focus moves to the nearest target in the pressed direction',()=>{
 const a=box('a',0,0),b=box('b',150,0),c=box('c',0,80),d=box('d',150,80),far=box('far',600,0);
 const all=[a,b,c,d,far];
 assert.equal(nav.pick(a,all,'right').id,'b');
 assert.equal(nav.pick(a,all,'down').id,'c');
 assert.equal(nav.pick(d,all,'up').id,'b');
 assert.equal(nav.pick(b,all,'left').id,'a');
 assert.equal(nav.pick(a,all,'up'),null,'nothing above the first row');
});
test('same-row targets win over closer diagonal ones',()=>{
 const a=box('a',0,100),row=box('row',300,100),diag=box('diag',160,10);
 assert.equal(nav.pick(a,[a,row,diag],'right').id,'row');
});
test('stick deadzone and glyph sets by device',()=>{
 assert.deepEqual(nav.stick(.1,-.15),{x:0,y:0});
 const s=nav.stick(1,0);assert.equal(s.x,1);assert.equal(s.y,0);
 assert.equal(nav.padKind('Sony Interactive Entertainment Wireless Controller (STANDARD GAMEPAD Vendor: 054c)'),'ps');
 assert.equal(nav.padKind('Steam Virtual Gamepad (Vendor: 28de)'),'xbox');
 assert.equal(nav.glyphSet('gamepad-ps').confirm,'ps-cross');
 assert.equal(nav.glyphSet('gamepad-xbox').dodge,'xbox-b');
 assert.equal(nav.glyphSet('keyboard').dodge,'key-shift','Shift dodges on the keyboard');
 assert.equal(nav.glyphSet('keyboard').maneuver,'key-r','R holds the rebicada');
});
test('held directions repeat like a console menu',()=>{
 const r=nav.repeater(300,100);
 assert.equal(r('up',true,0),true);assert.equal(r('up',true,200),false);assert.equal(r('up',true,300),true);assert.equal(r('up',true,350),false);assert.equal(r('up',true,400),true);
 assert.equal(r('up',false,410),false);assert.equal(r('up',true,420),true);
});
test('every glyph the command sets name exists in the kit',async()=>{
 const fs=await import('node:fs');const m=JSON.parse(fs.readFileSync('assets/ui/kit-switch-v1/manifest.json','utf8'));
 for(const set of Object.values(nav.GLYPHS))for(const id of Object.values(set))assert.ok(m.glyphs[id],id);
});
