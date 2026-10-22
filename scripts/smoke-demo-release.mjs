// Explicit, bounded production smoke: two synthetic visitors, one private casual match.
// No cookies, real accounts, collection grants or direct database writes are used.
import WebSocket from 'ws';
import {createEngine} from '../src/engine.js';
const args=process.argv.slice(2),base=new URL(args.find(a=>a.startsWith('--url='))?.slice(6)||'http://127.0.0.1:5222');
if(!['localhost','127.0.0.1'].includes(base.hostname)&&(!args.includes('--live')||base.origin!=='https://pipaklub.onrender.com'))throw Error('Explicit --live on the approved game origin is required.');
const engine=createEngine(),started=Date.now(),clients=[],rooms=[];let latest=null,reconnected=false,rejoined=false;
const assert=(condition,message)=>{if(!condition)throw Error(message);};
async function api(action,body){const r=await fetch(new URL('/api/'+action,base),{method:'POST',headers:{'Content-Type':'application/json',Origin:base.origin},body:JSON.stringify(body),signal:AbortSignal.timeout(15000)});const d=await r.json();if(!r.ok)throw Error(action+' failed ('+r.status+'): '+d.error);return d;}
function waitFor(check,timeout=12000){return new Promise((resolve,reject)=>{const until=Date.now()+timeout,timer=setInterval(()=>{if(check()){clearInterval(timer);resolve();}else if(Date.now()>until){clearInterval(timer);reject(Error('Timed out waiting for public match state.'));}},40);});}
async function socket(seat){
 const ws=new WebSocket(new URL('/realtime',base).href.replace(/^http/,'ws'),{origin:base.origin});clients.push(ws);
 await new Promise((resolve,reject)=>{ws.once('open',resolve);ws.once('error',reject);});
 const ready=new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(Error('No authenticated snapshot.')),10000);ws.on('message',raw=>{const d=JSON.parse(String(raw));if(d.type==='state'){latest=d.state;clearTimeout(timer);resolve();}});ws.once('close',()=>{clearTimeout(timer);reject(Error('Socket closed before snapshot.'));});});
 ws.send(JSON.stringify({type:'hello',code:seat.code,token:seat.token}));await ready;return ws;
}
let a,b,one,two,inputTimer;
try{
 const health=await(await fetch(new URL('/health',base),{signal:AbortSignal.timeout(15000)})).json();assert(health.release==='demo-rc.2'&&health.demo,'Expected demo-rc.2 before creating test rooms.');
 a=await api('create',{name:'Demo QA A',color:0,mode:'rounds',rules:'casual'});rooms.push({a});b=await api('join',{name:'Demo QA B',color:1,code:a.code});rooms[0].b=b;
 assert(a.state.id===b.state.id&&b.state.players.length===2,'Both visitors must share one match.');one=await socket(a);two=await socket(b);
 let lastRound=0;
 inputTimer=setInterval(()=>{
  if(!latest)return;const p=latest.players.find(p=>p.id===a.me),q=latest.players.find(p=>p.id===b.me);if(!p||!q)return;
  if(latest.round!==lastRound){lastRound=latest.round;console.log(JSON.stringify({step:'round',round:latest.round,phase:latest.phase}));}
  const steer=(p,x,y)=>({x:Math.max(-1,Math.min(1,(x-p.x)/20)),y:Math.max(-1,Math.min(1,(y-p.y)/20))});
  if(one?.readyState===1)one.send(JSON.stringify({type:'input',input:{...steer(p,700,180),cut:latest.phase==='live'&&!!engine.contact(p,q)?.valid,skill:0}}));
  if(two?.readyState===1)two.send(JSON.stringify({type:'input',input:{...steer(q,300,180),cut:false,skill:0}}));
 },80);
 await waitFor(()=>latest?.phase==='live');
 one.close();const resumed=await api('resume',{code:a.code,token:a.token});assert(resumed.me===a.me&&resumed.state.id===a.state.id&&resumed.state.players.length===2,'Host resume must preserve seat, match and population.');one=await socket(a);reconnected=true;
 two.close();const guest=await api('resume',{code:b.code,token:b.token});assert(guest.me===b.me&&guest.state.id===a.state.id&&guest.state.players.length===2,'Guest resume must preserve seat, match and population.');two=await socket(b);rejoined=true;
 console.log(JSON.stringify({step:'both-resumed',players:latest.players.length}));
 await waitFor(()=>latest?.players.find(p=>p.id===a.me)?.rounds>=3&&latest.last>=latest.end,150000);
 clearInterval(inputTimer);inputTimer=null;const result={matchCompleted:true,hostResumed:reconnected,guestResumed:rejoined,rounds:latest.players.map(p=>({name:p.name,won:p.rounds})),elapsedSeconds:Math.round((Date.now()-started)/1000)};
 const rematch=await api('rematch',{code:a.code,token:a.token});assert(rematch.token&&rematch.code!==a.code,'Rematch must create a fresh match.');rooms.push({a:rematch});const next=await api('rematch',{code:b.code,token:b.token});assert(next.next===rematch.code,'Both players must be pointed to the same rematch.');const peer=await api('join',{code:rematch.code,name:'Demo QA B',color:1});rooms.at(-1).b=peer;assert(peer.state.players.length===2,'Rematch must accept the second visitor.');result.rematchJoined=true;console.log(JSON.stringify({step:'passed',...result}));
}finally{
 clearInterval(inputTimer);for(const ws of clients)ws.terminate();
 for(const room of rooms)for(const seat of [room.a,room.b])if(seat?.token)await api('leave',{code:seat.code,token:seat.token}).catch(()=>{});
}
