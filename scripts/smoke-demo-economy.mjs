// Local fixtures only. Never accepts a production host or real account credentials.
import WebSocket from 'ws';
import {createEngine} from '../src/engine.js';
const base=new URL(process.argv.find(a=>a.startsWith('--url='))?.slice(6)||'http://127.0.0.1:5231');
if(!['127.0.0.1','localhost'].includes(base.hostname))throw Error('Local fixture origin required.');
const engine=createEngine(),clients=[],seats=[],jars={ana:'',beto:''};let latest,inputTimer;const checks=[];
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function verify(name,ok,detail={}){checks.push({name,passed:!!ok,...detail});console.log(JSON.stringify(checks.at(-1)));if(!ok)throw Error('Economy smoke failed: '+name);}
async function call(who,path,body){const r=await fetch(new URL(path,base),{method:body===undefined?'GET':'POST',headers:{Origin:base.origin,Cookie:jars[who],...(body===undefined?{}:{'Content-Type':'application/json'})},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(20000)});const cookies=r.headers.getSetCookie();if(cookies.length)jars[who]=cookies.map(c=>c.split(';')[0]).join('; ');return {...await r.json(),httpStatus:r.status};}
async function expect(who,path,body){const d=await call(who,path,body);if(d.httpStatus!==200)throw Error('Local request failed: '+path+' ('+d.httpStatus+') '+d.error);return d;}
async function wait(check,ms=150000){const until=Date.now()+ms;while(!check()){if(Date.now()>until)throw Error('Local match timed out.');await sleep(40);}}
async function socket(s){const ws=new WebSocket(new URL('/realtime',base).href.replace(/^http/,'ws'),{origin:base.origin});clients.push(ws);ws.on('message',raw=>{const d=JSON.parse(String(raw));if(d.type==='state')latest=d.state;});ws.on('error',()=>{});await new Promise((resolve,reject)=>{ws.once('open',resolve);ws.once('error',reject);});ws.send(JSON.stringify({type:'hello',code:s.code,token:s.token}));return ws;}
function collection(a){return a.inventory.map(k=>k.id).sort().join(',');}
try{
 for(const who of ['ana','beto'])await expect(who,'/account/login',{email:who+'@local.test',password:'TesteLocal123!'});
 for(const who of ['ana','beto']){
  let opening=(await expect(who,'/account/opening',{action:'read'})).opening;
  while(opening.step<14)opening=(await expect(who,'/account/opening',opening.step===10?{action:'name',step:10,name:who+' QA'}:{action:'advance',step:opening.step})).opening;
  const again=(await expect(who,'/account/opening',{action:'read'})).opening;verify('opening checkpoint and partner persist for '+who,again.step===14&&!!again.partner_id&&again.partner_id===opening.partner_id);
 }
 const beforeA=(await expect('ana','/account/session')).account,beforeB=(await expect('beto','/account/session')).account;
 const a=await expect('ana','/api/create',{mode:'rounds',rules:'casual'});seats.push({who:'ana',...a});const b=await expect('beto','/api/join',{code:a.code});seats.push({who:'beto',...b});verify('two authenticated accounts share a casual match',a.state.id===b.state.id&&b.state.players.length===2);
 const forbidden=await call('ana','/account/equip',{kiteId:beforeA.inventory.find(k=>k.id!==beforeA.profile.equipped_kite_id).id});verify('equipment cannot change while reserved',forbidden.httpStatus===409);
 const one=await socket(a),two=await socket(b);await wait(()=>latest,10000);
 inputTimer=setInterval(()=>{if(!latest)return;const p=latest.players.find(p=>p.id===a.me),q=latest.players.find(p=>p.id===b.me);if(!p||!q)return;const steer=(p,x,y)=>({x:Math.max(-1,Math.min(1,(x-p.x)/20)),y:Math.max(-1,Math.min(1,(y-p.y)/20))});if(one.readyState===1)one.send(JSON.stringify({type:'input',input:{...steer(p,700,180),cut:latest.phase==='live'&&!!engine.contact(p,q)?.valid}}));if(two.readyState===1)two.send(JSON.stringify({type:'input',input:{...steer(q,300,180),cut:false}}));},80);
 await wait(()=>latest?.players.find(p=>p.id===a.me)?.rounds>=3&&latest.last>=latest.end);clearInterval(inputTimer);verify('authenticated match completed',true);
 let result;for(let n=0;n<30;n++){result=await expect('ana','/account/match-result',{matchId:a.state.id});if(result.status==='saved')break;await sleep(400);}
 verify('match result finalized',result?.status==='saved'&&!!result?.result?.match?.endedAt);
 const afterA=(await expect('ana','/account/session')).account,afterB=(await expect('beto','/account/session')).account;
 verify('casual preserves both inventories',collection(beforeA)===collection(afterA)&&collection(beforeB)===collection(afterB));
 verify('three real cuts award 75 player XP',afterA.profile.xp-beforeA.profile.xp===75,{xpDelta:afterA.profile.xp-beforeA.profile.xp});
 const equipped=afterA.inventory.find(k=>k.id===beforeA.profile.equipped_kite_id),previous=beforeA.inventory.find(k=>k.id===beforeA.profile.equipped_kite_id);
 verify('equipped partner receives individual XP',equipped.pipamon_xp-previous.pipamon_xp===75,{partnerXpDelta:equipped.pipamon_xp-previous.pipamon_xp});
 for(let n=0;n<3;n++)await expect('ana','/account/match-result',{matchId:a.state.id});
 const repeated=(await expect('ana','/account/session')).account;verify('repeated result reads never duplicate rewards',repeated.profile.xp===afterA.profile.xp&&repeated.inventory.find(k=>k.id===equipped.id).pipamon_xp===equipped.pipamon_xp);
 for(const who of ['ana','beto'])await expect(who,'/account/login',{email:who+'@local.test',password:'TesteLocal123!'});
 const reloaded=(await expect('ana','/account/session')).account;verify('relogin preserves confirmed XP and inventory',reloaded.profile.xp===afterA.profile.xp&&collection(reloaded)===collection(afterA));
 const other=beforeA.inventory.find(k=>k.id!==beforeA.profile.equipped_kite_id).id;const unlocked=await call('ana','/account/equip',{kiteId:other});verify('equipment reservation released after result',unlocked.httpStatus===200);await expect('ana','/account/equip',{kiteId:beforeA.profile.equipped_kite_id});
 console.log(JSON.stringify({step:'passed',checks:checks.length,note:'Real game APIs and local PostgreSQL migrations; identity provider is a local fixture, not production Supabase.'}));
}catch(e){console.log(JSON.stringify({step:'failed',error:e.message}));process.exitCode=1;}
finally{clearInterval(inputTimer);for(const ws of clients)ws.terminate();for(const s of seats)await call(s.who,'/api/leave',{code:s.code,token:s.token}).catch(()=>{});}
