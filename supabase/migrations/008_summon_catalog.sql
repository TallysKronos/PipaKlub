begin;
create table public.player_pipamon_sightings(
 owner_id uuid not null references public.player_profiles(id),model_id text not null references public.kite_models(id),seen_at timestamptz not null default now(),primary key(owner_id,model_id)
);
create table public.summon_recipes(
 target_model_id text not null references public.summon_spells(model_id),tail_model_id text not null references public.summon_spells(model_id),result_model_id text not null references public.kite_models(id),
 primary key(target_model_id,tail_model_id),check(target_model_id<>tail_model_id)
);
-- No alternative recipe is enabled in this migration.
alter table public.player_pipamon_sightings enable row level security;
alter table public.summon_recipes enable row level security;
revoke all on public.player_pipamon_sightings,public.summon_recipes from public,anon,authenticated,service_role,pipa_server;
insert into public.player_pipamon_sightings(owner_id,model_id) select distinct owner_id,model_id from public.player_kites;
insert into public.summon_spells select id,public.normalize_summon_path(array(select n::smallint from generate_series(1,9) n order by md5(id||':'||n::text) limit 5)) from public.kite_models where id='basica';
alter table public.summon_rituals add column target_model_id text references public.summon_spells(model_id),add column result_model_id text references public.kite_models(id);
update public.summon_rituals r set target_model_id=t.model_id,result_model_id=t.model_id from public.summon_tails t where t.id=r.tail_id;
alter table public.summon_rituals alter column target_model_id set not null,alter column result_model_id set not null;

create function public.record_player_sighting(p_model text) returns void
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Invocação: entre na sua conta.';end if;
 if not exists(select 1 from public.kite_models where id=p_model) then raise exception 'Invocação: Pipamon desconhecido.';end if;
 insert into public.player_pipamon_sightings(owner_id,model_id) values(auth.uid(),p_model) on conflict do nothing;
end $$;
create function public.remember_owned_pipamon() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 insert into public.player_pipamon_sightings(owner_id,model_id) values(new.owner_id,new.model_id) on conflict do nothing;return new;
end $$;
create trigger remember_owned_pipamon after insert or update of owner_id on public.player_kites for each row execute function public.remember_owned_pipamon();
create function public.remember_match_pipamon() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 insert into public.player_pipamon_sightings(owner_id,model_id)
 select viewers.user_id,k.model_id from public.match_players viewers join public.match_players participants on participants.match_id=viewers.match_id join public.player_profiles p on p.id=participants.user_id join public.player_kites k on k.id=p.equipped_kite_id where viewers.match_id=new.match_id order by viewers.user_id,k.model_id on conflict do nothing;
 return new;
end $$;
create trigger remember_match_pipamon after insert on public.match_players for each row execute function public.remember_match_pipamon();

create or replace function public.summon_result(p_ritual uuid) returns jsonb
language sql security definer set search_path='' as $$
 select jsonb_build_object('id',r.id,'tailId',r.tail_id,'status',r.status,'attempts',r.attempts,'remaining',3-r.attempts,'pattern',r.pattern,'expiresAt',r.expires_at,'kiteId',r.kite_id,'name',m.name,'color',m.color,'soul',m.soul,'targetModelId',r.target_model_id,'resultModelId',r.result_model_id)
 from public.summon_rituals r join public.kite_models m on m.id=r.result_model_id where r.id=p_ritual
$$;
create function public.summon_inventory(p_user uuid) returns jsonb
language sql security definer set search_path='' as $$
 select jsonb_build_object(
 'tails',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'name',m.name,'modelId',t.model_id,'color',m.color,'soul',m.soul,'source',t.source,'status',t.status,'pattern',s.pattern) order by t.created_at,t.id) from public.summon_tails t join public.kite_models m on m.id=t.model_id join public.summon_spells s on s.model_id=t.model_id where t.owner_id=p_user and t.status in ('ready','damaged')),'[]'::jsonb),
 'seen',coalesce((select jsonb_agg(jsonb_build_object('modelId',m.id,'name',m.name,'color',m.color,'soul',m.soul,'pattern',s.pattern,'availableTailIds',coalesce((select jsonb_agg(t.id) from public.summon_tails t left join public.summon_recipes recipe on recipe.target_model_id=m.id and recipe.tail_model_id=t.model_id join public.kite_models result on result.id=case when t.model_id=m.id then m.id else recipe.result_model_id end where t.owner_id=p_user and t.status='ready' and (t.model_id=m.id or recipe.target_model_id is not null) and not(result.acquisition='event' and exists(select 1 from public.player_kites k where k.owner_id=p_user and k.model_id=result.id))),'[]'::jsonb)) order by m.name) from public.player_pipamon_sightings seen join public.kite_models m on m.id=seen.model_id join public.summon_spells s on s.model_id=m.id where seen.owner_id=p_user),'[]'::jsonb),
 'active',(select public.summon_result(id) from public.summon_rituals where owner_id=p_user and status='active'),
 'history',coalesce((select jsonb_agg(public.summon_result(h.id)) from (select id from public.summon_rituals where owner_id=p_user and status<>'active' order by created_at desc limit 20) h),'[]'::jsonb))
$$;
revoke all on function public.record_player_sighting(text),public.remember_owned_pipamon(),public.remember_match_pipamon(),public.summon_inventory(uuid) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.record_player_sighting(text) to authenticated;

drop function public.player_summon(text,uuid,uuid,smallint[],uuid,uuid);
create function public.player_summon(p_action text,p_tail uuid default null,p_ritual uuid default null,p_path smallint[] default null,p_request uuid default null,p_session uuid default null,p_target text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); tail public.summon_tails; ritual public.summon_rituals; previous public.summon_attempts; model public.kite_models; outcome jsonb; new_kite uuid; normalized smallint[]; target_model text; result_model text;
begin
 if uid is null then raise exception 'Invocação: entre na sua conta.'; end if;
 if p_action is null or p_action not in ('inventory','start','attempt','touch','abandon','discard') then raise exception 'Invocação: ação inválida.';end if;
 perform 1 from public.player_profiles where id=uid for update;
 -- Recover disconnects/crashes without resetting attempts or refunding a tail.
 with expired as(update public.summon_rituals set status='abandoned',finished_at=clock_timestamp() where owner_id=uid and status='active' and expires_at<=clock_timestamp() returning tail_id)
 update public.summon_tails set status='damaged' where id in(select tail_id from expired);
 if p_action='inventory' then return public.summon_inventory(uid);end if;
 if p_action='discard' then
  update public.summon_tails set status='discarded' where id=p_tail and owner_id=uid and status='damaged';
  if not found then raise exception 'Invocação: somente rabiolas danificadas podem ser descartadas.';end if;
  return jsonb_build_object('discarded',true);
 end if;
 if p_session is null then raise exception 'Invocação: sessão do ritual inválida.';end if;
 if p_action='start' then
  select * into tail from public.summon_tails where id=p_tail and owner_id=uid for update;
  if not found then raise exception 'Invocação: rabiola não encontrada.';end if;
  select * into ritual from public.summon_rituals where tail_id=p_tail;
  if found then
   if ritual.session_id<>p_session then raise exception 'Invocação: esta rabiola já foi utilizada.';end if;
   if p_target is not null and p_target<>ritual.target_model_id then raise exception 'Invocação: destino do ritual já definido.';end if;
   return public.summon_result(ritual.id);
  end if;
  if tail.status<>'ready' then raise exception 'Invocação: rabiola indisponível.';end if;
  if exists(select 1 from public.summon_rituals where owner_id=uid and status='active') then raise exception 'Invocação: você já está em um ritual.';end if;
  if exists(select 1 from public.player_profiles where id=uid and active_match is not null) then raise exception 'Invocação: saia da partida antes de iniciar.';end if;
  target_model:=coalesce(p_target,tail.model_id);result_model:=target_model;
  if not exists(select 1 from public.player_pipamon_sightings where owner_id=uid and model_id=target_model) then raise exception 'Invocação: você ainda não viu este Pipamon.';end if;
  if target_model<>tail.model_id then
   select result_model_id into result_model from public.summon_recipes where target_model_id=target_model and tail_model_id=tail.model_id;
   if not found then raise exception 'Invocação: este Pipamon não aceita esta rabiola.';end if;
  end if;
  select * into model from public.kite_models where id=result_model;
  if model.acquisition='event' and exists(select 1 from public.player_kites where owner_id=uid and model_id=model.id) then raise exception 'Invocação: você já possui esta Soul vinculada à conta.';end if;
  update public.summon_tails set status='used' where id=tail.id;
  insert into public.summon_rituals(owner_id,tail_id,session_id,pattern,target_model_id,result_model_id) select uid,tail.id,p_session,pattern,target_model,result_model from public.summon_spells where model_id=target_model returning * into ritual;
  if not found then raise exception 'Invocação: feitiço indisponível.';end if;
  return public.summon_result(ritual.id);
 end if;
 select * into ritual from public.summon_rituals where id=p_ritual and owner_id=uid for update;
 if not found or ritual.session_id<>p_session then raise exception 'Invocação: ritual não pertence a esta sessão.';end if;
 if p_action='attempt' then
  if p_request is null then raise exception 'Invocação: identifique a tentativa.';end if;
  select * into previous from public.summon_attempts where owner_id=uid and request_id=p_request;
  if found then
   if previous.ritual_id<>p_ritual or previous.path is distinct from p_path then raise exception 'Invocação: tentativa já utilizada.';end if;
   return previous.result;
  end if;
 end if;
 if ritual.status<>'active' then return public.summon_result(ritual.id);end if;
 if p_action='abandon' then
  update public.summon_rituals set status='abandoned',finished_at=clock_timestamp() where id=ritual.id;
  update public.summon_tails set status='damaged' where id=ritual.tail_id;
 elsif p_action='touch' then
  update public.summon_rituals set expires_at=clock_timestamp()+interval '45 seconds' where id=ritual.id;
 else
  if p_path is null or cardinality(p_path) not between 1 and 9 then raise exception 'Invocação: desenho inválido.';end if;
  normalized:=public.normalize_summon_path(p_path);
  if normalized=ritual.pattern then
   select * into model from public.kite_models where id=ritual.result_model_id;
   if model.acquisition='event' then new_kite:=public.grant_event_soul(uid,model.id,'summon:'||ritual.id::text);
   else insert into public.player_kites(owner_id,model_id) values(uid,model.id) returning id into new_kite;end if;
   update public.summon_rituals set attempts=attempts+1,status='succeeded',kite_id=new_kite,finished_at=clock_timestamp() where id=ritual.id;
   update public.summon_tails set status='consumed' where id=ritual.tail_id;
  else
   update public.summon_rituals set attempts=attempts+1,status=case when attempts=2 then 'failed' else 'active' end,finished_at=case when attempts=2 then clock_timestamp() else null end,expires_at=clock_timestamp()+interval '45 seconds' where id=ritual.id returning * into ritual;
   if ritual.status='failed' then update public.summon_tails set status='consumed' where id=ritual.tail_id;end if;
  end if;
  outcome:=public.summon_result(ritual.id);
  insert into public.summon_attempts values(uid,p_request,ritual.id,p_path,outcome);
  return outcome;
 end if;
 return public.summon_result(ritual.id);
end $$;
revoke all on function public.player_summon(text,uuid,uuid,smallint[],uuid,uuid,text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_summon(text,uuid,uuid,smallint[],uuid,uuid,text) to authenticated;
commit;
