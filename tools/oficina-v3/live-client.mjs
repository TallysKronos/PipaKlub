import {newRun,pack,unpack,replay} from './protocol.mjs';
export async function createLiveSession(jobId,onStatus,onComplete){
 const key='pipa.workshop.v3.pending.'+jobId;
 async function call(body){const response=await fetch('/account/workshop-v3',{method:'POST',headers:{'Content-Type':'application/json'},credentials:'same-origin',body:JSON.stringify(body)});const data=await response.json();if(!response.ok)throw Error(data.error||'Não foi possível salvar a montagem.');return data.workshop;}
 let journalAt=0;let job=await call({action:'read',jobId}),events=[],pending=null,busy=false,last=0,failed=false;
 try{pending=JSON.parse(localStorage.getItem(key)||'null');}catch{}
 if(pending?.events&&pending?.revision===undefined){events=pending.events;pending=pending.pending;}
 if(pending){
  job=await call(pending);localStorage.removeItem(key);pending=null;
 }
 let initial=job.state||pack(newRun(job.kind,Number(job.seed)));if(events.length)initial=pack(replay(initial,events).run);
 function persist(){try{localStorage.setItem(key,JSON.stringify({pending,events}));}catch{onStatus('Armazenamento local indisponível. Mantenha a bancada aberta até salvar.');}}
 async function flush(){
  if(busy)return;busy=true;
  try{
   do{
    if(!pending){if(!events.length)break;pending={action:'save',jobId,revision:Number(job.revision),requestId:crypto.randomUUID(),events:events.splice(0)};persist();}
    onStatus('Salvando montagem…');job=await call(pending);pending=null;persist();failed=false;onStatus(job.status==='building'?'Montagem salva':'Nascimento confirmado na coleção');
   }while(events.length);
   if(job.state?.outcome)onComplete(job);
  }catch(error){failed=true;onStatus(error.message+' Use Salvar novamente; seus comandos estão preservados.');}
  finally{busy=false;last=performance.now();}
 }
 addEventListener('pagehide',persist);
 return {
  job,run:unpack(initial),
  record(event){events.push(event);if(events.length>=1200&&!busy)void flush();},
  tick(now){if(now-journalAt>500){persist();journalAt=now;}if(!busy&&!failed&&events.length&&now-last>3000)void flush();},
  flush,
  get saving(){return busy;},get dirty(){return !!pending||events.length>0;},get failed(){return failed;}
 };
}
