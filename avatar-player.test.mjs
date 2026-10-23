import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {avatarConfig} from './scripts/avatar-build.mjs';
import {createAvatarPlayer,avatarFrameIndex,validAvatarAppearance} from './src/avatar-player.js';
import {createAvatarActivity,createHomeStairActivity,createHomeSeatActivity,advanceAvatarWalk,AVATAR_HOME_CONTACTS,homeStairLanding} from './src/avatar-activity.js';
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
 let calls=0;const a=createHomeStairActivity('kael-home',{x:1424,y:1104},()=>calls++);for(let i=0;i<72;i++)a.tick(.01);assert.ok(Math.abs(a.pose().lift-16)<.001);assert.equal(a.pose().action,'subir');assert.equal(calls,0);for(let i=0;i<400;i++)a.tick(.01);assert.equal(calls,1);assert.equal(a.pose().lift,128);assert.equal(a.pose().y,768);
 const down=createHomeStairActivity('kael-bedroom',{x:528,y:816});for(let i=0;i<39;i++)down.tick(.1);assert.equal(down.pose().action,'descer');assert.equal(down.pose().lift,-128);assert.equal(down.pose().y,1008);assert.equal(down.pose().clip,'stairwell');
});
test('sitting plays once then breathes at the same seat; one-shot bag never wraps from the final pose',()=>{
 const a=createAvatarActivity({kind:'seat',start:{x:0,y:0},seat:{x:550,y:860},dir:'se'});for(let i=0;i<8;i++)a.tick(.1);assert.equal(a.pose().action,'sentado');assert.equal(a.pose().x,550);assert.deepEqual(model.laggedMount([[128,100],[128,130]],0,1,false),[128,100]);assert.deepEqual(model.laggedMount([[128,100],[128,130]],1,1,false),[128,128]);
});
test('sitting and rising have continuous feet, retain the seat until standing, and queue movement after landing',()=>{
 let returned=null,queued=false;const start={x:700,y:930},a=createHomeSeatActivity(start,p=>returned=p);assert.equal(a.pose().x,start.x);assert.equal(a.pose().lift,0);
 for(let i=0;i<90;i++)a.tick(.01);assert.equal(a.state.phase,'seated');const before=a.pose();a.leave(()=>queued=true);assert.deepEqual(a.pose().x,before.x);assert.equal(a.pose().lift,before.lift);assert.equal(a.state.done,false);assert.equal(queued,false);
 a.tick(.1);assert.ok(a.pose().lift>0&&a.pose().lift<before.lift);assert.equal(a.pose().support,'sofa');for(let i=0;i<6;i++)a.tick(.1);assert.equal(a.pose().lift,0);assert.deepEqual(returned,AVATAR_HOME_CONTACTS.seat.approach);assert.equal(queued,true);
});
test('every descent sample remains inside the authored opening and uses the stairwell occlusion',()=>{
 const a=createHomeStairActivity('kael-bedroom',{x:528,y:816});for(let i=0;i<400;i++){a.tick(.01);const p=a.pose();if(p.action!=='descer')continue;assert.ok(p.x>=384&&p.x<=672);assert.ok(p.y>=864&&p.y<=1056);assert.equal(p.clip,'stairwell');assert.equal(p.support,'abertura-escada');}
});
test('footfall phase depends on travelled distance, independent of frame rate and pauses',()=>{
 const a={},b={};for(let i=0;i<60;i++)advanceAvatarWalk(a,2,1);for(let i=0;i<10;i++)advanceAvatarWalk(b,12,6);assert.ok(Math.abs(a.avatarWalkTime-b.avatarWalkTime)<1e-8);const stopped=a.avatarWalkTime;for(let i=0;i<100;i++)advanceAvatarWalk(a,0,0);assert.equal(a.avatarWalkTime,stopped);
});
test('both home stair landings are reachable, clear of furniture and close to their destination stairs',async()=>{
 const {artConfig}=await import('./scripts/art-build.mjs'),{createWorldNavigation}=await import('./src/world-navigation.js');
 const scenes=artConfig().courtyard.world.scenes;
 for(const id of ['kael-home','kael-bedroom']){const n=createWorldNavigation(scenes[id]),p=homeStairLanding(id),a=n.create();assert.equal(n.geometry.safe(p),true,id);n.target(a,p,true);assert.equal(a.x,p.x);assert.equal(a.y,p.y);const entrance=id==='kael-home'?{x:1424,y:1104}:{x:528,y:816};assert.ok(n.distance(a,entrance)<=82,id);assert.equal(n.geometry.segment(a,entrance),true,id);assert.equal(a.path.length,0);}
 assert.equal(homeStairLanding('quintal'),null);
});
test('descending renderer clips the actor at the stair opening without fading the bed, restores clip afterwards',async()=>{
 const {createBedroomIsometricRenderer}=await import('./src/bedroom-isometric.js'),ctx=new Proxy({canvas:{width:960,height:720}},{get:(o,k)=>k in o?o[k]:()=>{}}),bed={},r=createBedroomIsometricRenderer({village:'kael-bedroom'},{'bedroom-cama':bed},{},null,()=>({getContext:()=>ctx})),a=createHomeStairActivity('kael-bedroom',{x:528,y:816});for(let i=0;i<20;i++)a.tick(.1);const pose=a.pose(),stack=[];let clipped=false,seen=false;
 const g=new Proxy({globalAlpha:1,save(){stack.push({clipped,alpha:this.globalAlpha});},restore(){const s=stack.pop();clipped=s.clipped;this.globalAlpha=s.alpha;},clip(){clipped=true;},drawImage(im){if(im===bed)assert.equal(this.globalAlpha,1);}},{get:(o,k)=>k in o?o[k]:()=>{}});
 r.draw(g,{x:528,y:816},[{...pose,type:'player',avatarPose:pose,draw(){seen=true;assert.equal(clipped,true);}}]);assert.equal(seen,true);assert.equal(clipped,false);assert.equal(stack.length,0);
});
test('all 52 drawings have opaque keyed pixels, fixed foot pivot, attached hair and readable bag',async()=>{
 const p=JSON.parse(await fs.readFile('art/avatar/kael-v1/kael.avatarstudio.json','utf8'));let count=0;
 for(const [action,a]of Object.entries(p.actions))for(const [dir,d]of Object.entries(a.dirs)){if(!d.frames?.length)continue;const hair=p.layers.find(l=>l.slot==='cabelo'),bag=p.layers.find(l=>l.slot==='mochila'),layer=async l=>({image:await read(Buffer.from(l.images[dir].split(',')[1],'base64')),anchor:l.anchors[dir]}),hl=await layer(hair),bl=await layer(bag);
  for(const [i,f]of d.frames.entries()){const base=await read(Buffer.from(f.src.split(',')[1],'base64')),m=model.metrics(base),torso=model.laggedMount(d.frames.map(v=>v.torso),i,1,a.loop!==false);assert.equal(m.baseline,224);assert.equal(m.off,0);assert.equal(m.semi,0);assert.equal(model.auditHeadLayer(base,f.head,hl).level,'ok');assert.equal(model.auditTorsoLayer(base,torso,bl).level,'ok',`${action}/${dir}/${i}`);assert.equal(model.auditBackpack({base,torso,bag:bl,straps:true,dir}).level,'ok');count++;}
 }assert.equal(count,52);
 for(const dir of ['se','ne'])assert.equal(p.actions.sentar.dirs[dir].frames[3].src,p.actions.sentado.dirs[dir].frames[0].src);
});
