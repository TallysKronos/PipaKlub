// Bounded audit of owned visitor rooms only. No accounts, XP, items or other players.
import WebSocket from 'ws';
const base=new URL(process.argv.find(a=>a.startsWith('--url='))?.slice(6)||'http://127.0.0.1:5222');
if(!['127.0.0.1','localhost'].includes(base.hostname)&&(!process.argv.includes('--live')||base.origin!=='https://pipaklub.onrender.com'))throw Error('Use an approved origin and explicit --live.');
const seats=[],clients=[],checks=[],timers=[],started=Date.now();let stage='preflight';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function wait(check,ms=6000){const until=Date.now()+ms;while(!check()){if(Date.now()>until)throw Error('Timed out waiting for an owned test connection.');await sleep(25);}}
function verify(name,ok,detail={},fatal=true){checks.push({name,passed:!!ok,elapsedMs:Date.now()-started,...detail});console.log(JSON.stringify(checks.at(-1)));if(!ok){process.exitCode=1;if(fatal)throw Error('Audit failed: '+name);}}
async function call(path,body,origin=base.origin){const t=Date.now(),r=await fetch(new URL(path,base),{method:body===undefined?'GET':'POST',headers:body===undefined?{}:{'Content-Type':'application/json',Origin:origin},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(15000)});return {status:r.status,data:await r.json(),ms:Date.now()-t};}
async function api(action,body){const r=await call('/api/'+action,body);if(r.status!==200)throw Error('Owned-room action failed: '+action+' ('+r.status+')');return r.data;}
async function socket(seat){
 const ws=new WebSocket(new URL('/realtime',base).href.replace(/^http/,'ws'),{origin:base.origin}),c={ws,state:null,lastStateAt:0,closed:null,pongs:new Map()};clients.push(c);
 ws.on('message',raw=>{const d=JSON.parse(String(raw));if(d.type==='state'){c.state=d.state;c.lastStateAt=Date.now();}if(d.type==='pong')c.pongs.set(d.at,Date.now());});ws.on('close',(code)=>c.closed=code);ws.on('error',()=>{});
 await new Promise((resolve,reject)=>{ws.once('open',resolve);ws.once('error',reject);});ws.send(JSON.stringify({type:'hello',code:seat.code,token:seat.token}));await wait(()=>c.state||c.closed);return c;
}
function keep(c,input={}){const timer=setInterval(()=>{if(c.ws.readyState===1)c.ws.send(JSON.stringify({type:'input',input}));},100);timers.push(timer);return timer;}
try{
 const health=await call('/health');verify('expected demo service',health.status===200&&health.data.demo&&health.data.release==='demo-rc.1');
 const config=await call('/account/config');verify('account service configured',config.data.enabled===true);
 const session=await call('/account/session');verify('visitor has no account',session.status===200&&session.data.account===null);
 const denied=await call('/account/profile',{nickname:'Visitor QA'});verify('visitor cannot alter a profile',denied.status===401);
 const foreign=await call('/api/create',{name:'Origin QA',mode:'rounds',rules:'casual'},'https://unauthorized.invalid');verify('foreign origin rejected',foreign.status===403);
 const capture=await call('/api/create',{name:'Visitor QA',mode:'rounds',rules:'capture'});verify('visitor cannot create capture match',[401,403].includes(capture.status));
 const malformed=await call('/api/inspect',{code:'X'});verify('malformed invite rejected',malformed.status===400);
 const a=await api('create',{name:'Audit A',mode:'rounds',rules:'casual',color:0});seats.push(a);const b=await api('join',{code:a.code,name:'Audit B',color:1});seats.push(b);
 const inspect=await api('inspect',{code:a.code});verify('invite describes casual rounds',inspect.rules==='casual'&&inspect.mode==='rounds'&&!JSON.stringify(inspect).includes(a.token));
 const invalid=await call('/api/resume',{code:a.code,token:'not-the-key-for-this-owned-room'});verify('invalid seat cannot resume',invalid.status===401);
 const one=await socket(a),two=await socket(b);verify('both receive same match',one.state?.id===two.state?.id&&two.state.players.length===2);
 verify('public snapshots omit private keys',![a.token,b.token].some(k=>JSON.stringify(one.state).includes(k)));
 const rtts=[];for(let i=0;i<5;i++){const at=Date.now();one.ws.send(JSON.stringify({type:'ping',at}));await wait(()=>one.pongs.has(at));rtts.push(one.pongs.get(at)-at);}
 verify('WebSocket ping round trips',rtts.length===5,{rttMs:rtts,medianMs:[...rtts].sort((x,y)=>x-y)[2],note:'One executor and network; not two physical networks.'});
 const secondKeep=keep(two);await wait(()=>one.state.phase==='live');
 one.ws.send(JSON.stringify({type:'input',input:{x:1,y:0,damage:999,hp:999,score:999,color:3}}));
 await wait(()=>two.state.players.find(p=>p.id===a.me)?.input.x===1);
 verify('movement reaches the other player',two.state.players.find(p=>p.id===a.me).input.x===1);
 verify('client cannot forge hp score or class',two.state.players.find(p=>p.id===a.me).hp===100&&!two.state.players.some(p=>p.score===999)&&two.state.players.find(p=>p.id===a.me).color===0);
 await wait(()=>two.state.players.find(p=>p.id===a.me)?.input.x===0);verify('stale input neutralized',two.state.players.find(p=>p.id===a.me).input.x===0);
 stage='replacement handshake';const replacement=await socket(a);stage='previous socket close';await wait(()=>one.closed!==null,6000).catch(()=>{});verify('new socket takes the same seat',replacement.state.players.length===2&&Date.now()-one.lastStateAt>700,{previousCloseCode:one.closed,previousReadyState:one.ws.readyState,previousSnapshotAgeMs:Date.now()-one.lastStateAt});one.ws.terminate();const firstKeep=keep(replacement);
 stage='short reconnect';replacement.ws.close();await wait(()=>replacement.closed!==null);const resumed=await api('resume',{code:a.code,token:a.token});verify('short reconnect preserves identity and population',resumed.me===a.me&&resumed.state.id===a.state.id&&resumed.state.players.length===2);clearInterval(firstKeep);
 clearInterval(secondKeep);two.ws.close();await wait(()=>two.closed!==null);await api('leave',{code:b.code,token:b.token});const departed=await call('/api/resume',{code:b.code,token:b.token});verify('explicit leave invalidates seat',departed.status===401);
 await api('leave',{code:a.code,token:a.token});
 stage='expiry setup';const quiet=await api('create',{name:'Expiry QA',mode:'rounds',rules:'casual'});seats.push(quiet);const q=await socket(quiet);q.ws.close();await wait(()=>q.closed!==null);
 console.log(JSON.stringify({step:'waiting-for-expiry',seconds:62}));await sleep(62000);
 stage='expired socket handshake';const expired=await socket(quiet);verify('socket cannot revive an expired frozen room seat',expired.closed===1008&&!expired.state);
 const httpExpired=await call('/api/resume',{code:quiet.code,token:quiet.token});verify('HTTP also rejects expired seat',httpExpired.status===401);
 console.log(JSON.stringify({step:checks.every(c=>c.passed)?'passed':'failed',checks:checks.length,elapsedSeconds:Math.round((Date.now()-started)/1000)}));
}catch(e){console.log(JSON.stringify({step:'failed',stage,error:e.message,checks:checks.length,elapsedMs:Date.now()-started,sockets:clients.map(c=>({closed:c.closed,stateReceived:!!c.state}))}));process.exitCode=1;}
finally{for(const timer of timers)clearInterval(timer);for(const c of clients)c.ws.terminate();for(const s of seats)await call('/api/leave',{code:s.code,token:s.token}).catch(()=>{});}
