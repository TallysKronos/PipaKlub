begin;
-- Replace the public constellation ritual with a resumable, account-owned workshop.
-- Existing collection, completed rituals and delivered tails are preserved.
with interrupted as (
 update public.summon_rituals set status='abandoned',finished_at=clock_timestamp()
 where status='active' returning tail_id
)
update public.summon_tails set status='ready' where id in(select tail_id from interrupted) and status='used';
-- A physical mold is a species, not a constellation; include species added after the old spells.
alter table public.summon_tails drop constraint summon_tails_model_id_fkey;
alter table public.summon_tails add foreign key(model_id) references public.kite_models(id);

create table public.workshop_jobs(
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.player_profiles(id),
 tail_id uuid not null unique references public.summon_tails(id),target_model_id text not null references public.kite_models(id),
 result_model_id text not null references public.kite_models(id),stage integer not null default 0 check(stage between 0 and 5),
 status text not null default 'building' check(status in('building','completed')),
 steps jsonb not null default '[]',quality integer check(quality between 0 and 100),kite_id uuid references public.player_kites(id),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create unique index one_workshop_at_a_time on public.workshop_jobs(owner_id) where status='building';
create table public.workshop_requests(
 owner_id uuid not null references public.player_profiles(id),request_id uuid not null,
 job_id uuid not null references public.workshop_jobs(id),stage integer not null,payload jsonb not null,result jsonb not null,
 primary key(owner_id,request_id)
);
alter table public.workshop_jobs enable row level security;
alter table public.workshop_requests enable row level security;
revoke all on public.workshop_jobs,public.workshop_requests from public,anon,authenticated,service_role,pipa_server;

create function public.workshop_result(p_job uuid) returns jsonb
language sql security definer set search_path='' as $$
 select jsonb_build_object('id',j.id,'tailId',j.tail_id,'targetModelId',j.target_model_id,'modelId',j.result_model_id,
 'name',m.name,'color',m.color,'soul',m.soul,'stage',j.stage,'status',j.status,'steps',j.steps,
 'quality',j.quality,'kiteId',j.kite_id,'updatedAt',j.updated_at)
 from public.workshop_jobs j join public.kite_models m on m.id=j.result_model_id where j.id=p_job
$$;

create function public.player_workshop(p_action text,p_tail uuid default null,p_job uuid default null,
 p_target text default null,p_stage integer default null,p_payload jsonb default null,p_request uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();t public.summon_tails;j public.workshop_jobs;m public.kite_models;
 prior public.workshop_requests;target_model text;result_model text;answer jsonb;inv jsonb;score integer:=100;
 value_number integer;other_number integer;new_kite uuid;
begin
 if uid is null then raise exception 'Oficina: entre na sua conta.';end if;
 if p_action is null or p_action not in('inventory','start','advance','restore') then raise exception 'Oficina: ação inválida.';end if;
 perform 1 from public.player_profiles where id=uid for update;
 if not found then raise exception 'Oficina: perfil indisponível.';end if;
 if p_action='inventory' then
  return jsonb_build_object('version',1,'supplies','kit-do-atelie',
   'tails',coalesce((select jsonb_agg(jsonb_build_object('id',stock.id,'modelId',catalog.id,'name',catalog.name,'color',catalog.color,'soul',catalog.soul,'status',stock.status,'source',stock.source) order by stock.created_at,stock.id) from public.summon_tails stock join public.kite_models catalog on catalog.id=stock.model_id where stock.owner_id=uid and stock.status in('ready','damaged')),'[]'::jsonb),
   'seen',coalesce((select jsonb_agg(jsonb_build_object('modelId',catalog.id,'name',catalog.name,'color',catalog.color,'soul',catalog.soul,
    'availableTailIds',coalesce((select jsonb_agg(stock.id) from public.summon_tails stock left join public.summon_recipes r on r.target_model_id=catalog.id and r.tail_model_id=stock.model_id
     join public.kite_models result on result.id=case when stock.model_id=catalog.id then catalog.id else r.result_model_id end
     where stock.owner_id=uid and stock.status='ready' and (stock.model_id=catalog.id or r.result_model_id is not null)
     and not(result.acquisition='event' and exists(select 1 from public.player_kites k where k.owner_id=uid and k.model_id=result.id))),'[]'::jsonb)) order by catalog.name)
     from public.player_pipamon_sightings s join public.kite_models catalog on catalog.id=s.model_id where s.owner_id=uid),'[]'::jsonb),
   'active',(select public.workshop_result(id) from public.workshop_jobs where owner_id=uid and status='building'),
   'latest',(select public.workshop_result(id) from public.workshop_jobs where owner_id=uid and status='completed' order by updated_at desc limit 1));
 end if;
 if exists(select 1 from public.player_profiles where id=uid and active_match is not null and active_until>now()) then raise exception 'Oficina: termine a partida primeiro.';end if;
 if p_action='restore' then
  update public.summon_tails set status='ready' where id=p_tail and owner_id=uid and status='damaged';
  if not found then raise exception 'Oficina: rabiola danificada não encontrada.';end if;
  return jsonb_build_object('restored',true);
 end if;
 if p_action='start' then
  select * into t from public.summon_tails where id=p_tail and owner_id=uid for update;
  if not found then raise exception 'Oficina: rabiola não encontrada.';end if;
  select * into j from public.workshop_jobs where tail_id=t.id and owner_id=uid;
  if found then
   if p_target is not null and p_target<>j.target_model_id then raise exception 'Oficina: molde já definido.';end if;
   return public.workshop_result(j.id);
  end if;
  if exists(select 1 from public.workshop_jobs where owner_id=uid and status='building') then raise exception 'Oficina: retome a montagem em andamento.';end if;
  if t.status<>'ready' then raise exception 'Oficina: rabiola indisponível.';end if;
  target_model:=coalesce(p_target,t.model_id);result_model:=target_model;
  if not exists(select 1 from public.player_pipamon_sightings where owner_id=uid and model_id=target_model) then raise exception 'Oficina: conheça esta espécie primeiro.';end if;
  if target_model<>t.model_id then
   select result_model_id into result_model from public.summon_recipes where target_model_id=target_model and tail_model_id=t.model_id;
   if not found then raise exception 'Oficina: rabiola incompatível com este molde.';end if;
  end if;
  select * into m from public.kite_models where id=result_model;
  if not found then raise exception 'Oficina: molde indisponível.';end if;
  if m.acquisition='event' and exists(select 1 from public.player_kites where owner_id=uid and model_id=m.id) then raise exception 'Oficina: esta Soul já está na coleção.';end if;
  -- Reservation only. No heartbeat, expiry or penalty on disconnect.
  update public.summon_tails set status='used' where id=t.id;
  insert into public.workshop_jobs(owner_id,tail_id,target_model_id,result_model_id) values(uid,t.id,target_model,result_model) returning * into j;
  return public.workshop_result(j.id);
 end if;
 if p_request is null or p_stage is null or p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>2048 then raise exception 'Oficina: etapa inválida.';end if;
 select * into prior from public.workshop_requests where owner_id=uid and request_id=p_request;
 if found then
  if prior.job_id is distinct from p_job or prior.stage is distinct from p_stage or prior.payload is distinct from p_payload then raise exception 'Oficina: confirmação já utilizada.';end if;
  return prior.result;
 end if;
 select * into j from public.workshop_jobs where id=p_job and owner_id=uid for update;
 if not found then raise exception 'Oficina: montagem não pertence à sua conta.';end if;
 if j.status='completed' then return public.workshop_result(j.id);end if;
 if j.stage<>p_stage then raise exception 'Oficina: montagem atualizada. Reabra para retomar.';end if;
 if p_stage=0 then
  if p_payload is distinct from '{"joints":[0,1,2,3]}'::jsonb then raise exception 'Oficina: conecte as quatro varetas em ordem.';end if;
 elsif p_stage=2 then
  if p_payload is distinct from '{"cuts":[0,1,2,3]}'::jsonb then raise exception 'Oficina: complete o contorno do papel.';end if;
 else
  if (select count(*) from jsonb_object_keys(p_payload))<>(case when p_stage=4 then 2 else 1 end) then raise exception 'Oficina: ajuste inválido.';end if;
  if jsonb_typeof(p_payload->(case when p_stage=1 then 'tension' when p_stage=3 then 'balance' else 'wind' end)) is distinct from 'number' then raise exception 'Oficina: ajuste inválido.';end if;
  value_number:=(p_payload->>(case when p_stage=1 then 'tension' when p_stage=3 then 'balance' else 'wind' end))::integer;
  if value_number not between 0 and 100 then raise exception 'Oficina: ajuste fora da faixa.';end if;
  if p_stage=4 then
   if jsonb_typeof(p_payload->'tension') is distinct from 'number' then raise exception 'Oficina: tensão inválida.';end if;
   other_number:=(p_payload->>'tension')::integer;
   if other_number not between 0 and 100 then raise exception 'Oficina: tensão fora da faixa.';end if;
   score:=greatest(0,100-abs(value_number-50)-abs(other_number-50));
  else score:=greatest(0,100-abs(value_number-case when p_stage=1 then 65 else 50 end)*2);end if;
 end if;
 update public.workshop_jobs set stage=stage+1,steps=steps||jsonb_build_array(jsonb_build_object('stage',p_stage,'payload',p_payload,'score',score)),updated_at=clock_timestamp() where id=j.id returning * into j;
 if j.stage=5 then
  select * into m from public.kite_models where id=j.result_model_id;
  if m.acquisition='event' then new_kite:=public.grant_event_soul(uid,m.id,'workshop:'||j.id::text);
  else insert into public.player_kites(owner_id,model_id) values(uid,m.id) returning id into new_kite;end if;
  update public.summon_tails set status='consumed' where id=j.tail_id;
  update public.workshop_jobs set status='completed',kite_id=new_kite,quality=(select round(avg((v->>'score')::numeric))::integer from jsonb_array_elements(j.steps) v) where id=j.id;
 end if;
 answer:=public.workshop_result(j.id);
 insert into public.workshop_requests values(uid,p_request,j.id,p_stage,p_payload,answer);
 return answer;
end $$;
revoke all on function public.workshop_result(uuid),public.player_workshop(text,uuid,uuid,text,integer,jsonb,uuid) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_workshop(text,uuid,uuid,text,integer,jsonb,uuid) to authenticated;
-- Legacy code remains for history, but cannot create rewards or consume tails from clients.
revoke execute on function public.player_summon(text,uuid,uuid,smallint[],uuid,uuid,text) from authenticated;
commit;
