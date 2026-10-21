import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {once} from 'node:events';
import {DatabaseSync} from 'node:sqlite';
import WebSocket from 'ws';
import worker from './worker/index.js';
import {attachRealtime} from './src/realtime.js';

test('WebSocket authenticates sessions, broadcasts authoritative movement to both players, and rejects malformed messages',async t=>{
  const db=new DatabaseSync(':memory:');
  const DB={prepare(sql){let v=[];return {bind(...a){v=a;return this;},async run(){const r=db.prepare(sql).run(...v);return {meta:{changes:Number(r.changes)}};},async first(){return db.prepare(sql).get(...v);}};}};
  async function api(action,b){const r=await worker.fetch(new Request('http://test/api/'+action,{method:'POST',body:JSON.stringify(b)}),{DB});return r.json();}
  const a=await api('create',{name:'A'}),b=await api('join',{code:a.code,name:'B',color:1});
  const s=JSON.parse(db.prepare('SELECT state FROM pipa_rooms WHERE code=?').get(a.code).state);s.players[0].x=300;s.players[0].y=200;s.players[1].x=800;s.players[1].y=200;s.phase='live';s.phaseUntil=Date.now()+60000;db.prepare('UPDATE pipa_rooms SET state=? WHERE code=?').run(JSON.stringify(s),a.code);
  const server=http.createServer(),stop=attachRealtime(server,db);server.listen(0,'127.0.0.1');await once(server,'listening');
  t.after(()=>{stop();server.close();db.close();});
  async function client(token){
    const ws=new WebSocket('ws://127.0.0.1:'+server.address().port+'/realtime');const queue=[],waiters=[];
    ws.on('message',raw=>{const d=JSON.parse(String(raw));queue.push(d);if(queue.length>90)queue.shift();for(const check of [...waiters])check();});
    await once(ws,'open');ws.send(JSON.stringify({type:'hello',code:a.code,token}));
    function next(predicate){return new Promise((resolve,reject)=>{const timer=setTimeout(()=>{waiters.splice(waiters.indexOf(check),1);reject(Error('Snapshot timed out'));},3000);function check(){const index=queue.findIndex(predicate);if(index>=0){clearTimeout(timer);const packet=queue.splice(index,1)[0];const w=waiters.indexOf(check);if(w>=0)waiters.splice(w,1);resolve(packet);}}waiters.push(check);check();});}
    return {ws,next};
  }
  const c1=await client(a.token),c2=await client(b.token);
  const initial=await c1.next(d=>d.type==='state');assert.equal(initial.state.players.length,2);assert.ok(!JSON.stringify(initial).includes(b.token));
  c1.ws.send(JSON.stringify({type:'input',input:{x:999,y:0,cut:false}}));
  const moved=await c2.next(d=>d.type==='state'&&d.state.players.find(p=>p.id===a.me).x>310);
  const p=moved.state.players.find(p=>p.id===a.me);assert.equal(p.input.x,1);assert.ok(p.x<350);
  c2.ws.send(JSON.stringify({type:'input',input:{x:-999,y:0,cut:false}}));
  const guestMoved=await c1.next(d=>d.type==='state'&&d.state.players.find(p=>p.id===b.me).x<790);
  assert.equal(guestMoved.state.players.find(p=>p.id===b.me).input.x,-1);
  const guestX=guestMoved.state.players.find(p=>p.id===b.me).x;
  c2.ws.send(JSON.stringify({type:'input',input:{skill:-1,color:2,damage:999,hp:999}}));
  const dashed=await c1.next(d=>d.type==='state'&&d.state.players.find(p=>p.id===b.me).skillCount===1);
  const guest=dashed.state.players.find(p=>p.id===b.me);assert.equal(guest.color,1);assert.ok(guest.x<guestX-80);assert.ok(guest.skillCooldown>6);assert.ok(guest.energy<80);assert.equal(dashed.state.players.find(p=>p.id===a.me).hp,100);
  c1.ws.send(JSON.stringify({type:'ping',at:123}));assert.equal((await c1.next(d=>d.type==='pong')).at,123);
  await c2.next(d=>d.type==='state'&&d.state.players.find(p=>p.id===a.me).input.x===0);
  // Either side can use normal-mode maneuvers; the server owns the cost and motion.
  c2.ws.send(JSON.stringify({type:'input',input:{lineNonce:1,lineId:'puxao',lineHeld:true,lineSide:-1,damage:999}}));
  const charged=await c1.next(d=>d.type==='state'&&d.state.players.find(p=>p.id===b.me).lineMove?.phase==='charge');
  assert.equal(charged.state.players.find(p=>p.id===b.me).lineMove.side,-1);
  c2.ws.send(JSON.stringify({type:'input',input:{lineNonce:1,lineId:'puxao',lineHeld:false,lineSide:-1}}));
  const released=await c1.next(d=>d.type==='state'&&d.state.players.find(p=>p.id===b.me).lineMove?.phase==='move');
  assert.equal(released.state.players.find(p=>p.id===b.me).lineCount,1);
  assert.equal(released.state.players.find(p=>p.id===a.me).hp,100,'a distant line is never damaged');
  const previousClosed=once(c2.ws,'close'),replacement=await client(b.token);assert.equal((await previousClosed)[0],1000);
  const restored=await replacement.next(d=>d.type==='state');assert.equal(restored.state.id,a.state.id);assert.equal(restored.state.players.length,2);assert.equal(restored.state.players.find(p=>p.id===b.me).slot,1);
  replacement.ws.send(JSON.stringify({type:'input',input:{x:1}}));await c1.next(d=>d.type==='state'&&d.state.players.find(p=>p.id===b.me).input.x===1);
  const bad=await client('invalid-session');const closed=await once(bad.ws,'close');assert.equal(closed[0],1008);
  c1.ws.send('{');assert.equal((await once(c1.ws,'close'))[0],1008);
  replacement.ws.close();
});
