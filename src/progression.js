// Only server-created combat events enter this outbox. Never accept rewards from clients.
export function createProgression(db,accounts){
 if(!accounts.enabled)return {observe(){},release(){},stop(){},status(){return {found:false,pending:false,finished:false};}};
 db.exec('CREATE TABLE IF NOT EXISTS pipa_rewards (id TEXT PRIMARY KEY,payload TEXT NOT NULL,attempts INTEGER NOT NULL DEFAULT 0,retry_at INTEGER NOT NULL DEFAULT 0)');
 const observed=new Set();let busy=false,closed=false;
 function queue(id,payload){if(observed.has(id))return;db.prepare('INSERT OR IGNORE INTO pipa_rewards(id,payload) VALUES(?,?)').run(id,JSON.stringify(payload));observed.add(id);if(observed.size>10000)observed.clear();}
 function observe(s){
  for(const e of s._pendingCuts||s.events){if(e.winnerAccountId&&e.loserAccountId&&e.winnerAccountId!==e.loserAccountId)queue(e.id,{type:'cut',...e,code:s.code});}
  if(s.last>=s.end)queue(s.id+':end',{type:'finish',matchId:s.id});
 }
 async function flush(){
  if(busy||closed)return;busy=true;
  try{
   const rows=db.prepare('SELECT * FROM pipa_rewards WHERE retry_at<=? ORDER BY rowid LIMIT 8').all(Date.now());
   for(const row of rows){const event=JSON.parse(row.payload);try{
    if(event.type==='cut')await accounts.settle(event);else {
      if(db.prepare("SELECT 1 FROM pipa_rewards WHERE json_extract(payload,'$.type')='cut' AND json_extract(payload,'$.matchId')=? LIMIT 1").get(event.matchId))continue;
      if(event.type==='release')await accounts.release(event.userId,event.matchId);else await accounts.finish(event.matchId);
    }
    db.prepare('DELETE FROM pipa_rewards WHERE id=?').run(row.id);
   }catch(e){db.prepare('UPDATE pipa_rewards SET attempts=attempts+1,retry_at=? WHERE id=?').run(Date.now()+Math.min(60000,1000*2**Math.min(row.attempts,6)),row.id);console.error('Reward pending:',e.status||'unavailable');}}
  }finally{busy=false;}
 }
 const timer=setInterval(flush,400);timer.unref();
 function status(matchId){
  const row=db.prepare("SELECT state FROM pipa_rooms WHERE json_extract(state,'$.id')=? LIMIT 1").get(matchId),s=row&&JSON.parse(row.state);
  const finished=!!s&&Date.now()>=s.end;
  if(finished)queue(matchId+':end',{type:'finish',matchId});
  const pending=!!db.prepare("SELECT 1 FROM pipa_rewards WHERE json_extract(payload,'$.matchId')=? AND json_extract(payload,'$.type') IN ('cut','finish') LIMIT 1").get(matchId);
  return {found:!!s,finished,pending};
 }
 return {observe,flush,status,release(userId,matchId){queue(matchId+':leave:'+userId,{type:'release',userId,matchId});},stop(){closed=true;clearInterval(timer);}};
}
