// Durable per-account outbox: each match/import has an immutable UUID.
export function createTrailSync({trails,storage,send,uuid,onChange=()=>{},onStatus=()=>{},withLock=async fn=>fn()}){
 const GUEST='pipaTrailsV1',TOKEN='pipaTrailImportV1',PREFIX='pipaTrailAccountV1:';
 let user=null,generation=0,busy=false,again=false,blocked=false,storageProblem=false;
 const memory=new Map();
 function read(key,fallback){try{return JSON.parse(storage.getItem(key))??fallback;}catch{return fallback;}}
 function write(key,value){try{storage.setItem(key,JSON.stringify(value));}catch(e){storageProblem=true;throw e;}}
 const baseKey=id=>PREFIX+id+':base',opPrefix=id=>PREFIX+id+':op:';
 function pending(id){
  const map=new Map(memory.get(id)||[]);
  try{for(let i=0;i<storage.length;i++){const key=storage.key(i);if(key?.startsWith(opPrefix(id))){const op=read(key,null);if(op)map.set(op.id,op);}}}catch{}
  return [...map.values()].sort((a,b)=>a.at-b.at||a.id.localeCompare(b.id));
 }
 function merge(a,b){
  a=trails.sanitize(a);b=trails.sanitize(b);
  for(const k of ['coins','wins','losses'])a[k]=Math.min(1e9,a[k]+b[k]);
  a.mastery=Math.max(a.mastery,b.mastery);
  for(const k of ['stars','fails'])for(const [id,n] of Object.entries(b[k]))a[k][id]=Math.max(a[k][id]||0,n);
  a.items=[...new Set([...a.items,...b.items])];return a;
 }
 function progress(id=user){
  if(!id)return trails.sanitize(read(GUEST,null));
  let p=trails.sanitize(read(baseKey(id),null)?.progress);
  for(const op of pending(id))p=op.action==='import'?merge(p,op.payload):trails.settle(p,op.payload.stage,op.payload).progress;
  return p;
 }
 function emit(){onChange(progress());}
 function enqueue(id,op){
  if(!memory.has(id))memory.set(id,new Map());memory.get(id).set(op.id,op);
  try{write(opPrefix(id)+op.id,op);memory.get(id).delete(op.id);return true;}catch{onStatus('storage');return false;}
 }
 async function transferGuest(id){
  await withLock(async()=>{
   if(user!==id)return;
   const guest=trails.sanitize(read(GUEST,null));
   if(!guest.coins&&!guest.wins&&!guest.losses&&!Object.keys(guest.stars).length&&!guest.items.length)return;
   let token=read(TOKEN,null);
   if(token?.owner&&token.owner!==id){onStatus('claimed');return;}
   if(!token){token={id:uuid(),owner:id,payload:guest};write(TOKEN,token);}
   // The outbox is committed before the visitor save is cleared.
   const op={id:token.id,action:'import',payload:token.payload,at:0};
   if(!enqueue(id,op))return;
   write(GUEST,trails.defaults());storage.removeItem(TOKEN);
  });
 }
 async function setUser(id){
  id=id||null;if(id===user)return;
  user=id;generation++;blocked=false;storageProblem=false;emit();
  if(id){try{await transferGuest(id);}catch{onStatus('storage');}if(user!==id)return;emit();await sync();}
  else onStatus('guest');
 }
 async function sync(){
  if(!user||blocked)return;
  if(busy){again=true;return;}
  const id=user,version=generation;busy=true;onStatus('saving');
  try{
   let first=true;
   while(user===id&&generation===version){
    const op=pending(id)[0];if(!op&&!first)break;first=false;
    const result=await send(op?{action:op.action,operationId:op.id,payload:op.payload}:{action:'read'});
    if(user!==id||generation!==version)break;
    const cached=read(baseKey(id),null);
    if(!cached||Number(result.revision)>=Number(cached.revision))write(baseKey(id),{progress:trails.sanitize(result.progress),revision:result.revision});
    if(op){storage.removeItem(opPrefix(id)+op.id);memory.get(id)?.delete(op.id);}
    emit();
   }
   if(user===id&&generation===version)onStatus(storageProblem?'storage':pending(id).length?'pending':'saved');
  }catch(e){if(user===id&&generation===version){blocked=e.status===409;onStatus(storageProblem?'storage':blocked?'conflict':'offline');}}
  finally{busy=false;if(again){again=false;sync();}}
 }
 function record(payload,operationId=uuid(),owner=user){
  if(!owner){const result=trails.settle(progress(null),payload.stage,payload);try{write(GUEST,result.progress);}catch{onStatus('storage');}if(!user)onChange(result.progress);return result;}
  const result=trails.settle(progress(owner),payload.stage,payload);
  if(!pending(owner).some(op=>op.id===operationId))enqueue(owner,{id:operationId,action:'result',payload,at:Math.max(Date.now(),...pending(owner).map(op=>op.at+1))});
  if(owner===user){emit();sync();}return result;
 }
 async function retry(){blocked=false;storageProblem=false;if(user)try{await transferGuest(user);emit();}catch{onStatus('storage');}return sync();}
 function changed(){emit();return sync();}
 return {setUser,sync,retry,changed,record,progress,pending,merge,get user(){return user;}};
}
