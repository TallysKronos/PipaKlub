// Local database fixture only. Never imported by the production server/build.
export async function skipLocalOpening(db,owner,model='basica'){
 if(!['basica','mata','azulao','raio'].includes(model))throw Error('Escolha uma das quatro pipas iniciais.');
 return db.transaction(async tx=>{
  const q=async(sql,args=[])=>(await tx.query(sql,args)).rows[0];
  const profile=await q('select * from public.player_profiles where id=$1 for update',[owner]);
  if(!profile)throw Error('Entre em uma conta de teste ou como visitante primeiro.');
  if(profile.active_match&&new Date(profile.active_until)>new Date())throw Error('Saia da batalha antes de pular o início.');
  const journey=await q('select * from public.player_journeys where owner_id=$1',[owner]);
  if(journey?.phase==='complete')return {alreadyComplete:true};
  await q("select set_config('request.jwt.claim.sub',$1,true)",[owner]);
  await q("select public.player_opening('read',null,null)");
  const opening=await q('select * from public.player_openings where owner_id=$1 for update',[owner]);
  if(!opening.partner_id){
   await q("update public.player_openings set step=10,legacy=false,tail_state='attached' where owner_id=$1",[owner]);
   await q("select public.player_opening('name',10,'Rabbito')");
  }
  await q('update public.player_openings set step=14,updated_at=now() where owner_id=$1',[owner]);
  await q("insert into public.player_journeys(owner_id,phase,lesson,starter_model) values($1,'city',5,'rabbito') on conflict(owner_id) do update set phase='city',lesson=5,updated_at=now()",[owner]);
  await q("select public.player_starter_tutorial('read',null)");
  const prior=await q('select * from public.starter_tutorials where owner_id=$1',[owner]);
  model=prior?.model_id||model;
  await q("select public.player_starter_tutorial('choose',$1)",[model]);
  const tutorial=await q('select * from public.starter_tutorials where owner_id=$1',[owner]);
  if(await q("select id from public.workshop_jobs where owner_id=$1 and status='building' and tail_id<>$2",[owner,tutorial.tail_id]))throw Error('Conclua sua outra montagem antes de usar o atalho.');
  let job=await q('select * from public.workshop_jobs where owner_id=$1 and tail_id=$2',[owner,tutorial.tail_id]);
  if(!job)job=await q('insert into public.workshop_jobs(owner_id,tail_id,target_model_id,result_model_id) values($1,$2,$3,$3) returning *',[owner,tutorial.tail_id,model]);
  let kite=job.kite_id;
  if(job.status!=='completed'){
   kite=(await q('insert into public.player_kites(owner_id,model_id) values($1,$2) returning id',[owner,model])).id;
   await q("update public.workshop_jobs set stage=5,status='completed',quality=100,kite_id=$2,updated_at=now() where id=$1",[job.id,kite]);
   await q("update public.summon_tails set status='consumed' where id=$1",[tutorial.tail_id]);
  }
  await q("select public.player_starter_tutorial('finish',null)");
  await q('update public.player_profiles set equipped_kite_id=$2 where id=$1',[owner,kite]);
  const checkpoint=JSON.stringify({scene:'professor-home',x:1056,y:1184,direction:3});
  await q('update public.player_campaign_saves set autosave_checkpoint=$2::jsonb,autosave_at=now(),revision=revision+1 where owner_id=$1',[owner,checkpoint]);
  return {alreadyComplete:false,modelId:model,kiteId:kite};
 });
}
