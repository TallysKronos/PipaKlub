begin;
create table public.wild_drop_state(owner_id uuid primary key references public.player_profiles(id),misses integer not null default 0,intro_claimed boolean not null default false);
create table public.wild_runs(match_id uuid primary key references public.game_matches(id),owner_id uuid not null references public.player_profiles(id),kite_id uuid not null references public.player_kites(id),zone text not null check(zone in('park-trail','park-clearing')),model_id text not null references public.kite_models(id),enemy_level integer not null check(enemy_level between 1 and 4),drop_roll real not null, status text not null default 'pending' check(status in('pending','won','lost','fled','abandoned')),result jsonb,created_at timestamptz not null default now(),settled_at timestamptz);
create unique index one_pending_wild on public.wild_runs(owner_id) where status='pending';
alter table public.wild_drop_state enable row level security;alter table public.wild_runs enable row level security;
revoke all on public.wild_drop_state,public.wild_runs from public,anon,authenticated,service_role,pipa_server;
create function public.register_wild_run(p_user uuid,p_match uuid,p_zone text) returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.wild_runs;model text;roll real;k uuid;intro boolean;
begin
 perform 1 from public.player_profiles where id=p_user for update;
 if p_zone is null or p_zone not in('park-trail','park-clearing') then raise exception 'Exploração: área inválida.';end if;
 if not exists(select 1 from public.player_journeys where owner_id=p_user and phase in('city','complete')) then raise exception 'Exploração: conclua o primeiro voo.';end if;
 if not exists(select 1 from public.game_matches g join public.match_players m on m.match_id=g.id where g.id=p_match and m.user_id=p_user and g.mode='casual' and g.ended_at is null) then raise exception 'Exploração: partida inválida.';end if;
 select * into r from public.wild_runs where match_id=p_match;
 if found then if r.owner_id<>p_user or r.zone<>p_zone then raise exception 'Exploração: encontro inválido.';end if;
 else
  if exists(select 1 from public.wild_runs where owner_id=p_user and status='pending') then raise exception 'Exploração: retome ou encerre seu encontro anterior.';end if;
  if exists(select 1 from public.wild_runs where owner_id=p_user and created_at>now()-interval '20 seconds') then raise exception 'Exploração: recupere o fôlego antes de buscar novamente.';end if;
  insert into public.wild_drop_state(owner_id) values(p_user) on conflict do nothing;
  select intro_claimed into intro from public.wild_drop_state where owner_id=p_user for update;
  roll:=random();model:=case when not intro then case when roll<.5 then 'basica' else 'mata' end when roll<.5 then 'basica' when roll<.85 then 'mata' else 'raio' end;
  select pipamon_id into k from public.match_players where match_id=p_match and user_id=p_user;
  insert into public.wild_runs(match_id,owner_id,kite_id,zone,model_id,enemy_level,drop_roll) values(p_match,p_user,k,p_zone,model,1+floor(random()*3)::integer+case when p_zone='park-clearing' then 1 else 0 end,random()) returning * into r;
  insert into public.player_pipamon_sightings(owner_id,model_id) values(p_user,model) on conflict do nothing;
 end if;
 return jsonb_build_object('zone',r.zone,'modelId',r.model_id,'level',r.enemy_level)|| (select jsonb_build_object('name',name,'color',color,'soul',soul) from public.kite_models where id=r.model_id);
end $$;
create function public.settle_wild_run(p_user uuid,p_match uuid,p_outcome text) returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.wild_runs;d public.wild_drop_state;tail uuid;earned integer:=0;before_xp integer;tamer integer:=0;answer jsonb;
begin
 perform 1 from public.player_profiles where id=p_user for update;
 select * into r from public.wild_runs where match_id=p_match and owner_id=p_user for update;
 if not found then raise exception 'Exploração: encontro inexistente.';end if;
 if r.result is not null then return r.result;end if;
 if p_outcome is null or p_outcome not in('won','lost','fled','abandoned') then raise exception 'Exploração: resultado inválido.';end if;
 select * into d from public.wild_drop_state where owner_id=p_user for update;
 if p_outcome='won' then
  select tamer_xp into before_xp from public.player_profiles where id=p_user;
  earned:=public.award_pipamon_xp('wild:'||p_match,p_user,p_match,'wild',case when r.zone='park-clearing' then 30 when r.model_id='raio' then 30 else 20 end);
  select tamer_xp-before_xp into tamer from public.player_profiles where id=p_user;
  if not d.intro_claimed or d.misses>=7 or r.drop_roll<.25 then
   tail:=public.grant_summon_tail(p_user,r.model_id,'drop','wild:'||p_match);
   update public.wild_drop_state set intro_claimed=true,misses=0 where owner_id=p_user;
  else update public.wild_drop_state set misses=misses+1 where owner_id=p_user;end if;
 end if;
 answer:=jsonb_build_object('status',p_outcome,'pipamonXp',earned,'tamerXp',tamer,'tailId',tail,'modelId',r.model_id,'zone',r.zone,'firstTail',tail is not null and not d.intro_claimed);
 update public.wild_runs set status=p_outcome,result=answer,settled_at=now() where match_id=p_match;
 return answer;
end $$;
create function public.player_abandon_wild(p_match uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();answer jsonb;
begin
 if uid is null or not exists(select 1 from public.wild_runs where match_id=p_match and owner_id=uid) then raise exception 'Exploração: encontro inexistente.';end if;
 answer:=public.settle_wild_run(uid,p_match,'abandoned');
 perform public.release_player_match(uid,p_match);return answer;
end $$;
create function public.player_wild(p_match uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();r public.wild_runs;answer jsonb;
begin
 if uid is null then raise exception 'Exploração: entre na conta.';end if;
 if p_match is not null then select * into r from public.wild_runs where match_id=p_match and owner_id=uid;if not found then raise exception 'Exploração: encontro inexistente.';end if;
 else select * into r from public.wild_runs where owner_id=uid and status='pending';end if;
 answer:=jsonb_build_object('pending',case when r.status='pending' then (select jsonb_build_object('matchId',r.match_id,'code',g.room_code,'zone',r.zone) from public.game_matches g where g.id=r.match_id) else null end,'result',r.result,'misses',coalesce((select misses from public.wild_drop_state where owner_id=uid),0));return answer;
end $$;
-- Checkpoints may refer to the two authored park maps, using the same CAS and safety checks.
alter function public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) rename to player_campaign_before_park;
revoke all on function public.player_campaign_before_park(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,authenticated,service_role,pipa_server;
create function public.player_campaign(p_action text default 'read',p_revision bigint default null,p_checkpoint jsonb default null,p_keep uuid[] default null,p_seen uuid[] default null,p_confirmation text default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare answer jsonb;scene text:=p_checkpoint->>'scene';is_park boolean:=scene in('park-trail','park-clearing');
begin
 if is_park and p_action in('save','autosave') then
  if not exists(select 1 from public.player_journeys where owner_id=auth.uid() and phase in('city','complete')) then raise exception 'Exploração: conclua o primeiro voo.';end if;
  answer:=public.player_campaign_before_park(p_action,p_revision,jsonb_set(p_checkpoint,'{scene}','"quintal"'),p_keep,p_seen,p_confirmation);
  if p_action='save' then update public.player_campaign_saves set checkpoint=jsonb_set(checkpoint,'{scene}',to_jsonb(scene)) where owner_id=auth.uid();else update public.player_campaign_saves set autosave_checkpoint=jsonb_set(autosave_checkpoint,'{scene}',to_jsonb(scene)) where owner_id=auth.uid();end if;
  return public.player_campaign_before_park('read');
 end if;
 answer:=public.player_campaign_before_park(p_action,p_revision,p_checkpoint,p_keep,p_seen,p_confirmation);
 if p_action='reset' then
  update public.wild_runs set status='abandoned',settled_at=now(),result=jsonb_build_object('status','abandoned','pipamonXp',0,'tamerXp',0,'tailId',null,'modelId',model_id,'zone',zone,'firstTail',false) where owner_id=auth.uid() and status='pending';
 end if;
 return answer;
end $$;
revoke all on function public.register_wild_run(uuid,uuid,text),public.settle_wild_run(uuid,uuid,text),public.player_wild(uuid),public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.register_wild_run(uuid,uuid,text),public.settle_wild_run(uuid,uuid,text) to pipa_server;
grant execute on function public.player_wild(uuid),public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) to authenticated;
revoke all on function public.player_abandon_wild(uuid) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_abandon_wild(uuid) to authenticated;
commit;
