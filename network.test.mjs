import test from 'node:test';
import assert from 'node:assert/strict';
import {createEngine} from './src/engine.js';
import {createNetworkView} from './src/network-view.js';

test('local controls respond before any network reply and stale input cannot pull them back',()=>{
  const e=createEngine(),v=createNetworkView(e),s=e.create(0),p=e.player('You',0,'you',0);p.x=400;p.y=200;p.input={x:0,y:0,cut:false};s.players=[p];
  v.receive(s,'you',0,300);
  const first=v.render(16,{x:1,y:0,cut:true},.016)[0];assert.ok(first.x>402);assert.ok(first.attack);
  v.receive(structuredClone(s),'you',50,300);
  const next=v.render(66,{x:1,y:0,cut:true},.016)[0];assert.ok(next.x>first.x);
  assert.equal(s.players[0].x,400);assert.equal(s.players[0].attack,false);
});
test('remote movement interpolates between snapshots, death and respawn do not interpolate across the arena',()=>{
  const e=createEngine(),v=createNetworkView(e),s=e.create(0);s.players=[e.player('You',0,'you',0),e.player('Other',1,'other',0)];s.players[1].x=100;s.players[1].y=200;s.wind=0;
  v.receive(structuredClone(s),'you',0);s.players[1].x=200;v.receive(structuredClone(s),'you',50);
  const other=v.render(110,{x:0,y:0},.016).find(p=>p.id==='other');assert.equal(other.x,160);
  s.players[0].respawn=3000;s.players[0].hp=0;v.receive(structuredClone(s),'you',120);assert.equal(v.render(136,{x:1,y:0},.016)[0].hp,0);
  s.players[0].respawn=0;s.players[0].hp=100;s.players[0].x=900;v.receive(structuredClone(s),'you',160);assert.equal(v.render(160,{x:0,y:0},0)[0].x,900);
});
test('prediction stays bounded during lost packets and freezes once disconnected',()=>{
  const e=createEngine(),v=createNetworkView(e),s=e.create(0);s.players=[e.player('You',0,'you',0)];s.players[0].x=944;s.wind=0;v.receive(s,'you',0);
  assert.ok(v.render(16,{x:1,y:0},10)[0].x<=945);
  const a=v.render(900,{x:-1,y:0},.016)[0].x,b=v.render(1100,{x:-1,y:0},.016)[0].x;assert.equal(a,b);
});
