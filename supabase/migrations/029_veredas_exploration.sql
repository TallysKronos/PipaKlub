-- Expanded Veredas: unique chests, normal encounters and first-clear boss tail.
begin;
insert into public.kite_models(id,name,color,rarity,soul,acquisition) values('lacertubo','Lacertubo',2,'especial','lacertubo','event') on conflict(id) do nothing;
insert into public.summon_spells(model_id,pattern) values('lacertubo',public.normalize_summon_path(array[1,5,3,9,7,8,2]::smallint[])) on conflict(model_id) do nothing;
create table public.veredas_chest_claims(owner_id uuid not null references public.player_profiles(id),chest_id text not null check(chest_id in('lookout','woodland','canal','ridge','courtyard')),reward jsonb not null,created_at timestamptz not null default now(),primary key(owner_id,chest_id));
alter table public.veredas_chest_claims enable row level security;
revoke all on public.veredas_chest_claims from public,anon,authenticated,service_role,pipa_server;
alter table public.wild_runs drop constraint wild_runs_zone_check;
alter table public.wild_runs add constraint wild_runs_zone_check check(zone in('park-trail','park-clearing','park-veredas','park-veredas-wild'));

alter function public.register_wild_run(uuid,uuid,text) rename to register_wild_before_veredas;
revoke all on function public.register_wild_before_veredas(uuid,uuid,text) from public,anon,authenticated,service_role,pipa_server;
create function public.register_wild_run(p_user uuid,p_match uuid,p_zone text) returns jsonb language plpgsql security definer set search_path='' as $$
declare answer jsonb;r public.wild_runs;
begin
 if p_zone='park-veredas' then
  if exists(select 1 from public.wild_runs where owner_id=p_user and zone='park-veredas' and status='won') then raise exception 'O guardião não está mais no pátio.';end if;
  answer:=public.register_wild_before_veredas(p_user,p_match,p_zone);
  insert into public.player_pipamon_sightings(owner_id,model_id) values(p_user,'lacertubo') on conflict do nothing;
  return answer;
 end if;
 if p_zone is distinct from 'park-veredas-wild' then return public.register_wild_before_veredas(p_user,p_match,p_zone);end if;
 perform 1 from public.player_profiles where id=p_user for update;
 select * into r from public.wild_runs where match_id=p_match;
 if found then if r.owner_id<>p_user or r.zone<>p_zone then raise exception 'Exploração: encontro inválido.';end if;
 else
  answer:=public.register_wild_before_veredas(p_user,p_match,'park-clearing');
  update public.wild_runs set zone=p_zone,enemy_level=5+floor(random()*5)::int where match_id=p_match and owner_id=p_user returning * into r;
 end if;
 return jsonb_build_object('zone',p_zone,'modelId',r.model_id,'level',r.enemy_level)||(select jsonb_build_object('name',name,'color',color,'soul',soul) from public.kite_models where id=r.model_id);
end $$;

alter function public.settle_wild_run(uuid,uuid,text) rename to settle_wild_before_veredas;
revoke all on function public.settle_wild_before_veredas(uuid,uuid,text) from public,anon,authenticated,service_role,pipa_server;
create function public.settle_wild_run(p_user uuid,p_match uuid,p_outcome text) returns jsonb language plpgsql security definer set search_path='' as $$
declare answer jsonb;tail uuid;
begin
 answer:=public.settle_wild_before_veredas(p_user,p_match,p_outcome);
 if answer->>'zone'='park-veredas' and answer->>'status'='won' and (answer->>'firstClear')::boolean then
  tail:=public.grant_summon_tail(p_user,'lacertubo','drop','veredas-guardian-first-clear');
  answer:=answer||jsonb_build_object('tailId',tail,'modelId','lacertubo','firstTail',true);
  update public.wild_runs set result=answer where match_id=p_match and owner_id=p_user;
 end if;
 return answer;
end $$;

create function public.player_veredas(p_chest text default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();answer jsonb;item uuid;model text;amount integer;
begin
 if uid is null then raise exception 'Exploração: entre na conta.';end if;
 perform 1 from public.player_profiles where id=uid for update;
 if not found then raise exception 'Exploração: jogador inexistente.';end if;
 -- Existing first clears also receive exactly one tail after this update.
 if exists(select 1 from public.wild_runs where owner_id=uid and zone='park-veredas' and status='won') then
  perform public.grant_summon_tail(uid,'lacertubo','drop','veredas-guardian-first-clear');
  insert into public.player_pipamon_sightings(owner_id,model_id) values(uid,'lacertubo') on conflict do nothing;
 end if;
 if p_chest is not null then
  if p_chest not in('lookout','woodland','canal','ridge','courtyard') then raise exception 'Exploração: baú inválido.';end if;
  if not exists(select 1 from public.player_journeys where owner_id=uid and phase in('city','complete')) then raise exception 'Exploração: conclua o primeiro voo.';end if;
  if exists(select 1 from public.player_profiles where id=uid and active_match is not null and active_until>now()) then raise exception 'Exploração: termine seu encontro primeiro.';end if;
  if p_chest='courtyard' and not exists(select 1 from public.wild_runs where owner_id=uid and zone='park-veredas' and status='won') then raise exception 'O guardião protege esse baú.';end if;
  select reward into answer from public.veredas_chest_claims where owner_id=uid and chest_id=p_chest;
  if found then answer:=answer||jsonb_build_object('alreadyOpened',true);
  else
   if p_chest in('woodland','courtyard') then
    amount:=case when p_chest='woodland' then 25 else 60 end;
    insert into public.player_trails(owner_id,progress) values(uid,public.normalize_trails('{}'::jsonb)) on conflict do nothing;
    update public.player_trails set progress=jsonb_set(progress,'{coins}',to_jsonb(least(1000000000,coalesce((progress->>'coins')::bigint,0)+amount))),revision=revision+1,updated_at=now() where owner_id=uid;
    answer:=jsonb_build_object('kind','coins','amount',amount,'name',amount||' moedas');
   else
    model:=case p_chest when 'lookout' then 'azulao' when 'canal' then 'mata' else 'raio' end;
    item:=public.grant_summon_tail(uid,model,'drop','veredas-chest:'||p_chest);
    answer:=jsonb_build_object('kind','tail','tailId',item,'modelId',model,'name','Rabiola de '||(select name from public.kite_models where id=model));
   end if;
   insert into public.veredas_chest_claims(owner_id,chest_id,reward) values(uid,p_chest,answer);
  end if;
 end if;
 return jsonb_build_object('opened',coalesce((select jsonb_agg(chest_id order by chest_id) from public.veredas_chest_claims where owner_id=uid),'[]'::jsonb),'reward',answer);
end $$;
revoke all on function public.player_veredas(text),public.register_wild_run(uuid,uuid,text),public.settle_wild_run(uuid,uuid,text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_veredas(text) to authenticated;
grant execute on function public.register_wild_run(uuid,uuid,text),public.settle_wild_run(uuid,uuid,text) to pipa_server;
commit;
