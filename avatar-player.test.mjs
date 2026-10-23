import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {avatarConfig} from './scripts/avatar-build.mjs';
import {createAvatarPlayer,avatarFrameIndex,validAvatarAppearance} from './src/avatar-player.js';
import {createAvatarActivity} from './src/avatar-activity.js';
import * as model from './tools/avatar-studio/model.mjs';
import {read} from './scripts/extend-kael-avatar.mjs';
test('avatar timeline loops walking, clamps sit-down and resolves all four directions',()=>{
 assert.equal(avatarFrameIndex({length:8,ms:100,loop:true},850),0);assert.equal(avatarFrameIndex({length:4,ms:120,loop:false},5000),3);assert.equal(avatarFrameIndex({length:0},10),-1);
 const a=createAvatarPlayer(avatarConfig(),model,{storage:null});for(const dir of model.DIRS){assert.ok(a.sequence('andar',dir));assert.ok(a.sequence('sentado',dir));}assert.equal(a.sequence('correr','se'),null);
});
test('appearance is validated and isolated by account, including malformed storage',()=>{
 const config=avatarConfig(),saved=new Map(),storage={getItem:k=>saved.get(k),setItem:(k,v)=>saved.set(k,v)},a=createAvatarPlayer(config,model,{storage});a.setOwner('one');a.setAppearance({pele:3,cabelo:99,jaqueta:-1,contorno:2});assert.deepEqual(a.appearance,{pele:3});a.setOwner('two');assert.deepEqual(a.appearance,{});a.setOwner('one');assert.deepEqual(a.appearance,{pele:3});assert.deepEqual(validAvatarAppearance({pele:'3'},config.palette),{});
});
test('stairs use eight physical steps, two per cycle, invoke arrival only once',()=>{
 let calls=0;const a=createAvatarActivity({kind:'stairs',start:{x:1424,y:1104},dir:'ne',onComplete:()=>calls++});for(let i=0;i<44;i++)a.tick(.01);assert.ok(Math.abs(a.pose().lift-16)<.001);assert.equal(a.pose().action,'subir');assert.equal(calls,0);for(let i=0;i<400;i++)a.tick(.01);assert.equal(calls,1);assert.equal(a.pose().lift,128);assert.equal(a.pose().y,816);
 const down=createAvatarActivity({kind:'stairs',start:{x:528,y:816},dir:'sw'});for(let i=0;i<36;i++)down.tick(.1);assert.equal(down.pose().action,'descer');assert.equal(down.pose().lift,-128);
});
test('sitting plays once then breathes at the same seat; one-shot bag never wraps from the final pose',()=>{
 const a=createAvatarActivity({kind:'seat',start:{x:0,y:0},seat:{x:550,y:860},dir:'se'});for(let i=0;i<5;i++)a.tick(.1);assert.equal(a.pose().action,'sentado');assert.equal(a.pose().x,550);assert.deepEqual(model.laggedMount([[128,100],[128,130]],0,1,false),[128,100]);assert.deepEqual(model.laggedMount([[128,100],[128,130]],1,1,false),[128,128]);
});
test('all 52 drawings have opaque keyed pixels, fixed foot pivot, attached hair and readable bag',async()=>{
 const p=JSON.parse(await fs.readFile('art/avatar/kael-v1/kael.avatarstudio.json','utf8'));let count=0;
 for(const [action,a]of Object.entries(p.actions))for(const [dir,d]of Object.entries(a.dirs)){if(!d.frames?.length)continue;const hair=p.layers.find(l=>l.slot==='cabelo'),bag=p.layers.find(l=>l.slot==='mochila'),layer=async l=>({image:await read(Buffer.from(l.images[dir].split(',')[1],'base64')),anchor:l.anchors[dir]}),hl=await layer(hair),bl=await layer(bag);
  for(const [i,f]of d.frames.entries()){const base=await read(Buffer.from(f.src.split(',')[1],'base64')),m=model.metrics(base),torso=model.laggedMount(d.frames.map(v=>v.torso),i,1,a.loop!==false);assert.equal(m.baseline,224);assert.equal(m.off,0);assert.equal(m.semi,0);assert.equal(model.auditHeadLayer(base,f.head,hl).level,'ok');assert.equal(model.auditTorsoLayer(base,torso,bl).level,'ok',`${action}/${dir}/${i}`);assert.equal(model.auditBackpack({base,torso,bag:bl,straps:true,dir}).level,'ok');count++;}
 }assert.equal(count,52);
 for(const dir of ['se','ne'])assert.equal(p.actions.sentar.dirs[dir].frames[3].src,p.actions.sentado.dirs[dir].frames[0].src);
});
