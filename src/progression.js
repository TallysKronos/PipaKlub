// Only server-created combat events enter this outbox. Never accept rewards from clients.
export function createProgression(db,accounts){
 if(!accounts.enabled)return {observe(){},release(){},stop(){},status(){return {found:false,pending:false,finished:false};}};
 db.exec('CREATE TABLE IF NOT EXISTS pipa_rewards (id TEXT PRIMARY KEY,payload TEXT NOT NULL,attempts INTEGER NOT NULL DEFAULT 0,retry_at INTEGER NOT NULL DEFAULT 0)');
 const observed=new Set();let busy=false,closed=false;
 function queue(id,payload){if(observed.has(id))return;db.prepare('INSERT OR IGNORE INTO pipa_rewards(id,payload) VALUES(?,?)').run(id,JSON.stringify(payload));observed.add(id);if(observed.size>10000)observed.clear();}
 function observe(s){
  for(const e of s._pendingCuts||s.events||[]){if(e.winnerAccountId&&e.loserAccountId&&e.winnerAccountId!==e.loserAccountId)queue(e.id,{type:'cut',...e,code:s.code});}
  // Persist a clinching win before the intermission ends, so leaving cannot lose it.
  if(s.trail&&s.trailResult?.userId)queue(s.id+':trail',{type:'trail',matchId:s.id,...s.trailResult});
  if(s.daily&&s.dailyResult?.accountId)queue(s.id+':daily',{type:'daily',matchId:s.id,userId:s.dailyResult.accountId,day:s.daily.date});
  if(s.last>=s.end)queue(s.id+':end',{type:'finish',matchId:s.id});
 }
 // Expire solo rooms without an active connection; otherwise reloading could hold the account for minutes.
 function expireIdleTrails(){
  if(!db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='pipa_rooms'").get())return;
  if(!db.prepare("SELECT 1 FROM pragma_table_info('pipa_rooms') WHERE name='updated'").get())return;
  const now=Date.now();for(const row of db.prepare("SELECT code,state FROM pipa_rooms WHERE updated<? AND json_extract(state,'$.trail') IS NOT NULL AND EXISTS(SELECT 1 FROM json_each(json_extract(state,'$.players')) p WHERE coalesce(json_extract(p.value,'$.bot'),0)=0)").all(now-15000)){
   const s=JSON.parse(row.state);if(s.players.some(p=>!p.bot&&now-p.seen<15000))continue;
   s.end=Math.min(s.end,now);s.last=Math.max(s.last,s.end);s.players=s.players.filter(p=>p.bot);observe(s);
   db.prepare('UPDATE pipa_rooms SET state=?,rev=rev+1,updated=? WHERE code=?').run(JSON.stringify(s),now,row.code);
  }
 }
 async function flush(){
  if(busy||closed)return;busy=true;
  try{
   expireIdleTrails();
   const rows=db.prepare('SELECT * FROM pipa_rewards WHERE retry_at<=? ORDER BY rowid LIMIT 8').all(Date.now());
   for(const row of rows){const event=JSON.parse(row.payload);try{
    if(event.type==='cut')await accounts.settle(event);else if(event.type==='daily')await accounts.settleDaily(event);else if(event.type==='trail')await accounts.settleTrail(event);else {
      if(db.prepare("SELECT 1 FROM pipa_rewards WHERE json_extract(payload,'$.type') IN ('cut','daily','trail') AND json_extract(payload,'$.matchId')=? LIMIT 1").get(event.matchId))continue;
      if(event.type==='release')await accounts.release(event.userId,event.matchId);else await accounts.finish(event.matchId);
    }
    db.prepare('DELETE FROM pipa_rewards WHERE id=?').run(row.id);
   }catch(e){db.prepare('UPDATE pipa_rewards SET attempts=attempts+1,retry_at=? WHERE id=?').run(Date.now()+Math.min(60000,1000*2**Math.min(row.attempts,6)),row.id);console.error('Reward pending:',e.status||'unavailable');}}
  }finally{busy=false;}
 }
 // Recover committed clinching results even if the process stopped before queueing them.
 if(db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='pipa_rooms'").get())for(const row of db.prepare('SELECT state FROM pipa_rooms').all()){try{const s=JSON.parse(row.state);if(s.trailResult||s.dailyResult)observe(s);}catch{}}
 const timer=setInterval(flush,400);timer.unref();
 function status(matchId){
  const row=db.prepare("SELECT state FROM pipa_rooms WHERE json_extract(state,'$.id')=? LIMIT 1").get(matchId),s=row&&JSON.parse(row.state);
  const finished=!!s&&Date.now()>=s.end;
  if(s)observe(finished?{...s,last:Math.max(Number(s.last)||0,s.end)}:s);
  const pending=!!db.prepare("SELECT 1 FROM pipa_rewards WHERE json_extract(payload,'$.matchId')=? AND json_extract(payload,'$.type') IN ('cut','finish','daily','trail') LIMIT 1").get(matchId);
  return {found:!!s,finished,pending};
 }
 return {observe,flush,status,release(userId,matchId){queue(matchId+':leave:'+userId,{type:'release',userId,matchId});},stop(){closed=true;clearInterval(timer);}};
}
