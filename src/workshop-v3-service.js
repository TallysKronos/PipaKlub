import {createHash} from 'node:crypto';
import fs from 'node:fs';
import {newRun,pack,replay} from '../tools/oficina-v3/protocol.mjs';
const dex=JSON.parse(fs.readFileSync(new URL('../assets/pipa-dex.json',import.meta.url),'utf8'));
const atlas=JSON.parse(fs.readFileSync(new URL('../assets/atlas.json',import.meta.url),'utf8')).atlases;
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function publicJob(job){
 const result={...job};delete result.replayed;
 if(['building','cancelled'].includes(job.status)){delete result.modelId;delete result.name;delete result.color;delete result.soul;}
 else{
  const entry=dex.entries.find(e=>e.model===job.modelId),sheet=entry&&atlas[entry.atlas],frame=sheet&&sheet.frames[sheet.animations.idle[0]]?.frame;
  if(entry)result.name=entry.name;
  if(frame)result.creature={image:'/assets/'+sheet.meta.image,frame};
 }
 return result;
}
export async function workshopV3(user,body,rpc){
 if(!['start','read','save','cancel'].includes(body.action))throw Error('Oficina: ação inválida.');
 for(const key of ['jobId','tailId','requestId'])if(body[key]!=null&&!UUID.test(String(body[key])))throw Error('Oficina: montagem inválida.');
 if(body.action==='start'){
  if(!body.tailId||typeof body.targetModelId!=='string'||!/^[a-z0-9-]{1,80}$/.test(body.targetModelId))throw Error('Oficina: selecione uma rabiola.');
  return publicJob(await rpc({p_user:user,p_action:'start',p_tail:body.tailId,p_target:body.targetModelId}));
 }
 if(!body.jobId)throw Error('Oficina: montagem inválida.');
 if(body.action==='cancel'){
  if(!Number.isSafeInteger(body.seed)||body.seed<0||body.seed>4294967295)throw Error('Oficina: tentativa inválida.');
  return rpc({p_user:user,p_action:'cancel',p_job:body.jobId,p_state:{seed:body.seed}});
 }
 const digest=body.action==='save'?createHash('sha256').update(JSON.stringify([body.revision,body.events])).digest('hex'):null;
 const job=await rpc({p_user:user,p_action:'read',p_job:body.jobId,p_request:body.action==='save'?body.requestId:null,p_target:digest});
 if(body.action==='read'||job.replayed)return publicJob(job);
 if(!body.requestId||!Number.isSafeInteger(body.revision)||body.revision!==Number(job.revision))throw Error('Oficina: montagem atualizada em outra aba. Reabra para retomar.');
 if(job.status!=='building')throw Error('Oficina: esta montagem já terminou.');
 const initial=job.state||pack(newRun(job.kind,Number(job.seed)));
 const result=replay(initial,body.events);
 const wall=(Date.now()-Date.parse(job.updatedAt))/1000;
 if(!Number.isFinite(wall)||result.seconds>Math.max(3,wall+3))throw Error('Oficina: relógio adiantado. Aguarde e tente novamente.');
 return publicJob(await rpc({p_user:user,p_action:'save',p_job:job.id,p_revision:body.revision,p_request:body.requestId,
  p_target:digest,p_state:result.state,p_result:result.run.outcome}));
}
