begin;
alter function public.player_trails(text,uuid,jsonb) rename to apply_trail_progress;
create or replace function public.apply_trail_progress(p_action text default 'read',p_operation uuid default null,p_payload jsonb default '{}'::jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();r public.player_trails;old public.trail_operations;s public.trail_stages;d jsonb;v jsonb;k text;n integer;stars integer;earned integer;first_clear boolean;won boolean;
begin
 if uid is null then raise exception 'Trilhas: entre na sua conta.';end if;
 if p_action is null or p_action not in('read','import','result') then raise exception 'Trilhas: ação inválida.';end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>4096 then raise exception 'Trilhas: dados inválidos.';end if;
 insert into public.player_trails(owner_id,progress) values(uid,public.normalize_trails(null)) on conflict do nothing;
 select * into r from public.player_trails where owner_id=uid for update;
 d:=r.progress;
 if p_action<>'read' then
  if p_operation is null then raise exception 'Trilhas: operação inválida.';end if;
  -- Serialize identities even when two different accounts claim the same visitor import.
  perform pg_advisory_xact_lock(hashtextextended(p_operation::text,0));
  select * into old from public.trail_operations where id=p_operation;
  if found then
   if old.owner_id<>uid or old.action<>p_action or old.payload<>p_payload then raise exception 'Trilhas: operação já utilizada com outros dados.';end if;
   return jsonb_build_object('progress',d,'revision',r.revision);
  end if;
  if p_action='import' then
   v:=public.normalize_trails(p_payload);
   foreach k in array array['coins','wins','losses'] loop d:=jsonb_set(d,array[k],to_jsonb(least(1000000000,(d->>k)::bigint+(v->>k)::bigint)));end loop;
   d:=jsonb_set(d,'{mastery}',to_jsonb(greatest((d->>'mastery')::integer,(v->>'mastery')::integer)));
   for s in select * from public.trail_stages loop
    foreach k in array array['stars','fails'] loop n:=greatest(coalesce((d->k->>s.id)::integer,0),coalesce((v->k->>s.id)::integer,0));if n>0 then d:=jsonb_set(d,array[k,s.id],to_jsonb(n));end if;end loop;
   end loop;
   d:=jsonb_set(d,'{items}',(select coalesce(jsonb_agg(distinct value),'[]') from jsonb_array_elements((d->'items')||(v->'items'))));
  else
   select * into s from public.trail_stages where id=p_payload->>'stage';
   if not found or (jsonb_typeof(p_payload->'won')='boolean') is not true or (jsonb_typeof(p_payload->'roundsLost')='number') is not true then raise exception 'Trilhas: resultado inválido.';end if;
   if (p_payload->>'roundsLost')::numeric<>trunc((p_payload->>'roundsLost')::numeric) or (p_payload->>'roundsLost')::numeric<0 or (p_payload->>'roundsLost')::numeric>5 then raise exception 'Trilhas: rodadas inválidas.';end if;
   if s.position>0 and not exists(select 1 from public.trail_stages prev where prev.position=s.position-1 and coalesce((d->'stars'->>prev.id)::integer,0)>0) then raise exception 'Trilhas: vença a etapa anterior.';end if;
   won:=(p_payload->>'won')::boolean;
   if won then
    stars:=greatest(1,3-(p_payload->>'roundsLost')::integer);first_clear:=not (d->'stars' ? s.id);
    earned:=round(s.coins*(1+(stars-1)*0.25))::integer+case when first_clear then s.coins else 0 end;
    d:=jsonb_set(d,'{coins}',to_jsonb(least(1000000000,(d->>'coins')::bigint+earned)));
    d:=jsonb_set(d,'{wins}',to_jsonb(least(1000000000,(d->>'wins')::bigint+1)));
    d:=jsonb_set(d,array['stars',s.id],to_jsonb(greatest(coalesce((d->'stars'->>s.id)::integer,0),stars)));
    d:=jsonb_set(d,'{mastery}',to_jsonb(least(8,(d->>'mastery')::integer+case when stars=3 then 2 else 1 end)));
    d:=jsonb_set(d,'{fails}',(d->'fails')-s.id);
    if s.drop_id is not null and not (d->'items' ? s.drop_id) then d:=jsonb_set(d,'{items}',(d->'items')||to_jsonb(s.drop_id));end if;
   else
    n:=least(99,coalesce((d->'fails'->>s.id)::integer,0)+1);d:=jsonb_set(d,array['fails',s.id],to_jsonb(n));
    d:=jsonb_set(d,'{losses}',to_jsonb(least(1000000000,(d->>'losses')::bigint+1)));
    d:=jsonb_set(d,'{mastery}',to_jsonb(greatest(0,(d->>'mastery')::integer-case when n>=2 then 2 else 1 end)));
   end if;
  end if;
  insert into public.trail_operations(id,owner_id,action,payload) values(p_operation,uid,p_action,p_payload);
  update public.player_trails set progress=d,revision=revision+1,updated_at=now() where owner_id=uid returning * into r;
 end if;
 return jsonb_build_object('progress',r.progress,'revision',r.revision);
end $$;

revoke all on function public.apply_trail_progress(text,uuid,jsonb) from public,anon,authenticated,service_role,pipa_server;
-- Historical account progress is retained, but new client imports/results are archived only.
create table public.trail_runs(
 match_id uuid primary key references public.game_matches(id),owner_id uuid not null references auth.users(id),
 stage_id text not null references public.trail_stages(id),result jsonb,created_at timestamptz not null default now()
);
create table public.trail_drop_claims(
 owner_id uuid not null references auth.users(id),stage_id text not null references public.trail_stages(id),
 match_id uuid not null references public.trail_runs(match_id),tail_id uuid not null unique references public.summon_tails(id),
 created_at timestamptz not null default now(),primary key(owner_id,stage_id)
);
alter table public.trail_runs enable row level security;
alter table public.trail_drop_claims enable row level security;
revoke all on public.trail_runs,public.trail_drop_claims from public,anon,authenticated,service_role,pipa_server;
alter table public.trail_stages add column foe_count integer not null default 1 check(foe_count between 1 and 3);
update public.trail_stages set foe_count=case when id in ('morro-3','praia-2') then 2 when id in ('praia-4','torres-4') then 3 else 1 end;
alter table public.trail_stages add column drop_model_id text references public.summon_spells(model_id);
update public.trail_stages set drop_model_id=case id when 'morro-5' then 'raio' when 'praia-5' then 'chaspiral' when 'torres-5' then 'flautrevo' end;

create function public.trail_reward_history(p_user uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('stage',c.stage_id,'dropId',s.drop_id,'modelId',s.drop_model_id,'tailId',c.tail_id,'status',t.status,'matchId',c.match_id,'at',c.created_at) order by c.created_at),'[]'::jsonb)
 from public.trail_drop_claims c join public.trail_stages s on s.id=c.stage_id join public.summon_tails t on t.id=c.tail_id where c.owner_id=p_user
$$;
revoke all on function public.trail_reward_history(uuid) from public,anon,authenticated,service_role,pipa_server;

create function public.player_trails(p_action text default 'read',p_operation uuid default null,p_payload jsonb default '{}'::jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();snapshot jsonb;old public.trail_operations;
begin
 if uid is null then raise exception 'Trilhas: entre na sua conta.';end if;
 if p_action is null or p_action not in ('read','import','result') or p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>4096 then raise exception 'Trilhas: dados inválidos.';end if;
 if p_action<>'read' then
  if p_operation is null then raise exception 'Trilhas: operação inválida.';end if;
  perform pg_advisory_xact_lock(hashtextextended(p_operation::text,0));
  select * into old from public.trail_operations where id=p_operation;
  if found then
   if old.owner_id<>uid or old.payload<>p_payload or old.action not in(p_action,'legacy-'||p_action) then raise exception 'Trilhas: operação já utilizada com outros dados.';end if;
  else
   insert into public.trail_operations(id,owner_id,action,payload) values(p_operation,uid,'legacy-'||p_action,p_payload);
  end if;
 end if;
 snapshot:=public.apply_trail_progress('read',null,'{}'::jsonb);
 return snapshot||jsonb_build_object('rewards',public.trail_reward_history(uid),'legacyArchived',p_action<>'read');
end $$;
revoke all on function public.player_trails(text,uuid,jsonb) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_trails(text,uuid,jsonb) to authenticated;

create function public.register_trail_run(p_user uuid,p_match uuid,p_stage text) returns jsonb language plpgsql security definer set search_path='' as $$
declare stage public.trail_stages;wallet public.player_trails;run public.trail_runs;
begin
 perform 1 from public.player_profiles where id=p_user and active_match=p_match for update;
 if not found or not exists(select 1 from public.game_matches g join public.match_players m on m.match_id=g.id where g.id=p_match and m.user_id=p_user and g.mode='casual' and g.ended_at is null) then raise exception 'Trilhas: partida inválida.';end if;
 select * into stage from public.trail_stages where id=p_stage;
 if not found then raise exception 'Trilhas: etapa inválida.';end if;
 insert into public.player_trails(owner_id,progress) values(p_user,public.normalize_trails(null)) on conflict do nothing;
 select * into wallet from public.player_trails where owner_id=p_user for update;
 if stage.position>0 and not exists(select 1 from public.trail_stages prev where prev.position=stage.position-1 and coalesce((wallet.progress->'stars'->>prev.id)::integer,0)>0) then raise exception 'Trilhas: vença a etapa anterior.';end if;
 insert into public.trail_runs(match_id,owner_id,stage_id) values(p_match,p_user,p_stage) on conflict do nothing;
 select * into run from public.trail_runs where match_id=p_match;
 if run.owner_id<>p_user or run.stage_id<>p_stage then raise exception 'Trilhas: partida já vinculada a outra etapa.';end if;
 return jsonb_build_object('progress',wallet.progress,'revision',wallet.revision);
end $$;

create function public.settle_trail_run(p_user uuid,p_match uuid,p_stage text,p_won boolean,p_rounds_lost integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare run public.trail_runs;stage public.trail_stages;before jsonb;snapshot jsonb;answer jsonb;tail uuid;drop_item text;subject text:=current_setting('request.jwt.claim.sub',true);
begin
 perform 1 from public.player_profiles where id=p_user for update;
 select * into run from public.trail_runs where match_id=p_match for update;
 if not found or run.owner_id<>p_user or run.stage_id<>p_stage or p_won is null or p_rounds_lost is null or p_rounds_lost<0 or p_rounds_lost>5 then raise exception 'Trilhas: resultado inválido.';end if;
 if run.result is not null then
  if (run.result->>'won')::boolean<>p_won or (run.result->>'roundsLost')::integer<>p_rounds_lost then raise exception 'Trilhas: resultado já confirmado com outros dados.';end if;
  return run.result;
 end if;
 select * into stage from public.trail_stages where id=p_stage;
 if (p_won and p_rounds_lost>stage.foe_count*(stage.rounds-1)) or (not p_won and (p_rounds_lost<stage.rounds or p_rounds_lost>stage.rounds+(stage.foe_count-1)*(stage.rounds-1))) then raise exception 'Trilhas: rodadas inválidas.';end if;
 select progress into before from public.player_trails where owner_id=p_user for update;
 perform set_config('request.jwt.claim.sub',p_user::text,true);
 snapshot:=public.apply_trail_progress('result',gen_random_uuid(),jsonb_build_object('stage',p_stage,'won',p_won,'roundsLost',p_rounds_lost));
 perform set_config('request.jwt.claim.sub',coalesce(subject,''),true);
 if p_won and stage.drop_model_id is not null and not exists(select 1 from public.trail_drop_claims where owner_id=p_user and stage_id=p_stage) then
  tail:=public.grant_summon_tail(p_user,stage.drop_model_id,'drop','trail-first:'||p_stage);
  insert into public.trail_drop_claims(owner_id,stage_id,match_id,tail_id) values(p_user,p_stage,p_match,tail);
  insert into public.player_pipamon_sightings(owner_id,model_id) values(p_user,stage.drop_model_id) on conflict do nothing;
  drop_item:=stage.drop_id;
 end if;
 answer:=jsonb_build_object('matchId',p_match,'stage',p_stage,'won',p_won,'roundsLost',p_rounds_lost,'coins',(snapshot->'progress'->>'coins')::bigint-(before->>'coins')::bigint,'stars',case when p_won then greatest(1,3-p_rounds_lost) else 0 end,'firstClear',p_won and not(before->'stars' ? p_stage),'drop',drop_item,'tailId',tail);
 update public.trail_runs set result=answer where match_id=p_match;
 return answer;
end $$;

create function public.get_player_trail_result(p_match uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();run public.trail_runs;snapshot jsonb;ended boolean;
begin
 if uid is null then raise exception 'Trilhas: entre na sua conta.';end if;
 select * into run from public.trail_runs where match_id=p_match and owner_id=uid;
 if not found then raise exception 'Trilhas: partida não encontrada.';end if;
 snapshot:=public.player_trails();select ended_at is not null into ended from public.game_matches where id=p_match;
 return snapshot||jsonb_build_object('result',run.result,'stage',run.stage_id,'ended',ended);
end $$;
revoke all on function public.register_trail_run(uuid,uuid,text),public.settle_trail_run(uuid,uuid,text,boolean,integer),public.get_player_trail_result(uuid) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.register_trail_run(uuid,uuid,text),public.settle_trail_run(uuid,uuid,text,boolean,integer) to pipa_server;
grant execute on function public.get_player_trail_result(uuid) to authenticated;
commit;
