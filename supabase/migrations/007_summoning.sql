begin;
create function public.normalize_summon_path(p_path smallint[]) returns smallint[]
language plpgsql immutable set search_path='' as $$
declare result smallint[]:='{}'; node smallint; last_node integer; middle integer; ax integer; ay integer; bx integer; by_ integer;
begin
 foreach node in array p_path loop
  if node is null or node<1 or node>9 then raise exception 'Invocação: desenho inválido.'; end if;
  if node=any(result) then continue;end if;
  if cardinality(result)>0 then
   last_node:=result[cardinality(result)];ax:=(last_node-1)%3;ay:=(last_node-1)/3;bx:=(node-1)%3;by_:=(node-1)/3;
   if (ax+bx)%2=0 and (ay+by_)%2=0 then
    middle:=((ay+by_)/2)*3+(ax+bx)/2+1;
    if middle<>last_node and middle<>node and not middle=any(result) then result:=array_append(result,middle::smallint);end if;
   end if;
  end if;
  result:=array_append(result,node);
 end loop;
 return result;
end $$;
create table public.summon_spells(model_id text primary key references public.kite_models(id),pattern smallint[] not null unique check(cardinality(pattern) between 4 and 9));
-- Stable, distinct constellations. They are visible instructions, not secrets.
insert into public.summon_spells
select m.id,public.normalize_summon_path(array(select n::smallint from generate_series(1,9) n order by md5(m.id||':'||n::text) limit 5))
from public.kite_models m where m.id<>'basica';
create table public.summon_tails(
 id uuid primary key default gen_random_uuid(),owner_id uuid not null references public.player_profiles(id),model_id text not null references public.summon_spells(model_id),
 source text not null check(source in ('drop','purchase','event')),reference text not null check(char_length(reference) between 1 and 150),
 status text not null default 'ready' check(status in ('ready','used','consumed','damaged','discarded')),created_at timestamptz not null default now(),
 unique(owner_id,source,reference)
);
create index summon_tails_owner on public.summon_tails(owner_id,status);
create table public.summon_rituals(
 id uuid primary key default gen_random_uuid(),owner_id uuid not null references public.player_profiles(id),tail_id uuid not null unique references public.summon_tails(id),
 session_id uuid not null,pattern smallint[] not null,attempts integer not null default 0 check(attempts between 0 and 3),
 status text not null default 'active' check(status in ('active','succeeded','failed','abandoned')),kite_id uuid references public.player_kites(id),
 expires_at timestamptz not null default clock_timestamp()+interval '45 seconds',created_at timestamptz not null default now(),finished_at timestamptz
);
create unique index one_summon_at_a_time on public.summon_rituals(owner_id) where status='active';
create table public.summon_attempts(owner_id uuid not null references public.player_profiles(id),request_id uuid not null,ritual_id uuid not null references public.summon_rituals(id),path smallint[] not null,result jsonb not null,primary key(owner_id,request_id));
alter table public.summon_spells enable row level security;
alter table public.summon_tails enable row level security;
alter table public.summon_rituals enable row level security;
alter table public.summon_attempts enable row level security;
revoke all on public.summon_spells,public.summon_tails,public.summon_rituals,public.summon_attempts from public,anon,authenticated,service_role,pipa_server;

-- Trusted delivery hook. A purchase reference must come from a verified receipt;
-- no player or restricted match-server role can mint items or assert payment.
create function public.grant_summon_tail(p_user uuid,p_model text,p_source text,p_reference text) returns uuid
language plpgsql set search_path='' as $$
declare item public.summon_tails;
begin
 perform 1 from public.player_profiles where id=p_user for update;
 if not found then raise exception 'Invocação: jogador inexistente.'; end if;
 select * into item from public.summon_tails where owner_id=p_user and source=p_source and reference=p_reference;
 if found then
  if item.model_id<>p_model then raise exception 'Invocação: referência já utilizada.'; end if;
  return item.id;
 end if;
 insert into public.summon_tails(owner_id,model_id,source,reference) values(p_user,p_model,p_source,p_reference) returning * into item;
 return item.id;
end $$;
create function public.summon_result(p_ritual uuid) returns jsonb
language sql security definer set search_path='' as $$
 select jsonb_build_object('id',r.id,'tailId',r.tail_id,'status',r.status,'attempts',r.attempts,'remaining',3-r.attempts,'pattern',r.pattern,'expiresAt',r.expires_at,'kiteId',r.kite_id,'name',m.name,'color',m.color,'soul',m.soul)
 from public.summon_rituals r join public.summon_tails t on t.id=r.tail_id join public.kite_models m on m.id=t.model_id where r.id=p_ritual
$$;
create function public.player_summon(p_action text,p_tail uuid default null,p_ritual uuid default null,p_path smallint[] default null,p_request uuid default null,p_session uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); tail public.summon_tails; ritual public.summon_rituals; previous public.summon_attempts; model public.kite_models; outcome jsonb; new_kite uuid; normalized smallint[];
begin
 if uid is null then raise exception 'Invocação: entre na sua conta.'; end if;
 if p_action is null or p_action not in ('inventory','start','attempt','touch','abandon','discard') then raise exception 'Invocação: ação inválida.';end if;
 perform 1 from public.player_profiles where id=uid for update;
 -- Recover disconnects/crashes without resetting attempts or refunding a tail.
 with expired as(update public.summon_rituals set status='abandoned',finished_at=clock_timestamp() where owner_id=uid and status='active' and expires_at<=clock_timestamp() returning tail_id)
 update public.summon_tails set status='damaged' where id in(select tail_id from expired);
 if p_action='inventory' then
  return jsonb_build_object('tails',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'name',m.name,'modelId',t.model_id,'color',m.color,'soul',m.soul,'source',t.source,'status',t.status,'pattern',s.pattern) order by t.created_at,t.id) from public.summon_tails t join public.kite_models m on m.id=t.model_id join public.summon_spells s on s.model_id=t.model_id where owner_id=uid and status in ('ready','damaged')),'[]'::jsonb),
   'active',(select public.summon_result(id) from public.summon_rituals where owner_id=uid and status='active'),
   'history',coalesce((select jsonb_agg(public.summon_result(h.id)) from (select id from public.summon_rituals where owner_id=uid and status<>'active' order by created_at desc limit 20) h),'[]'::jsonb));
 end if;
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
   return public.summon_result(ritual.id);
  end if;
  if tail.status<>'ready' then raise exception 'Invocação: rabiola indisponível.';end if;
  if exists(select 1 from public.summon_rituals where owner_id=uid and status='active') then raise exception 'Invocação: você já está em um ritual.';end if;
  if exists(select 1 from public.player_profiles where id=uid and active_match is not null) then raise exception 'Invocação: saia da partida antes de iniciar.';end if;
  select * into model from public.kite_models where id=tail.model_id;
  if model.acquisition='event' and exists(select 1 from public.player_kites where owner_id=uid and model_id=model.id) then raise exception 'Invocação: você já possui esta Soul vinculada à conta.';end if;
  update public.summon_tails set status='used' where id=tail.id;
  insert into public.summon_rituals(owner_id,tail_id,session_id,pattern) select uid,tail.id,p_session,pattern from public.summon_spells where model_id=tail.model_id returning * into ritual;
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
   select m.* into model from public.summon_tails t join public.kite_models m on m.id=t.model_id where t.id=ritual.tail_id;
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
revoke all on function public.normalize_summon_path(smallint[]),public.grant_summon_tail(uuid,text,text,text),public.summon_result(uuid),public.player_summon(text,uuid,uuid,smallint[],uuid,uuid) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_summon(text,uuid,uuid,smallint[],uuid,uuid) to authenticated;
commit;
