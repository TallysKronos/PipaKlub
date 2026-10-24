begin;
-- Additive release: preserve existing partners and legacy in-progress builds.
alter table public.player_kites add column craft_bonus numeric(4,1) not null default 0 check(craft_bonus between 0 and 12);
alter table public.player_kites add column soul_variant boolean not null default false;
alter table public.player_kites add column craft_details jsonb;
alter table public.workshop_jobs drop constraint workshop_jobs_status_check;
alter table public.workshop_jobs add constraint workshop_jobs_status_check check(status in('building','completed','failed'));
create table public.workshop_v3_runs(
 job_id uuid primary key references public.workshop_jobs(id),revision bigint not null default 0,
 seed bigint not null default floor(random()*4294967296),kind text not null check(kind in('comum','incomum','raro')),
 state jsonb,variant boolean not null default (floor(random()*459)=0),
 updated_at timestamptz not null default clock_timestamp()
);
create table public.workshop_v3_receipts(
 owner_id uuid not null references public.player_profiles(id),request_id uuid not null,job_id uuid not null references public.workshop_jobs(id),
 revision bigint not null,state jsonb not null,result jsonb,answer jsonb not null,body_hash text not null,primary key(owner_id,request_id)
);
alter table public.workshop_v3_runs enable row level security;
alter table public.workshop_v3_receipts enable row level security;
revoke all on public.workshop_v3_runs,public.workshop_v3_receipts from public,anon,authenticated,service_role,pipa_server;

create or replace function public.workshop_result(p_job uuid) returns jsonb
language sql security definer set search_path='' as $$
 select jsonb_build_object('id',j.id,'tailId',j.tail_id,'targetModelId',j.target_model_id,'modelId',j.result_model_id,
 'name',m.name,'color',m.color,'soul',m.soul,'stage',j.stage,'status',j.status,'steps',j.steps,'quality',j.quality,
 'kiteId',j.kite_id,'updatedAt',j.updated_at,'v3',exists(select 1 from public.workshop_v3_runs v where v.job_id=j.id))
 from public.workshop_jobs j join public.kite_models m on m.id=j.result_model_id where j.id=p_job
$$;

-- Cached clients cannot complete a v3 reservation through the old declared-score RPC.
alter function public.player_workshop(text,uuid,uuid,text,integer,jsonb,uuid) rename to player_workshop_before_v3;
revoke all on function public.player_workshop_before_v3(text,uuid,uuid,text,integer,jsonb,uuid) from public,anon,authenticated,service_role,pipa_server;
create function public.player_workshop(p_action text,p_tail uuid default null,p_job uuid default null,p_target text default null,
 p_stage integer default null,p_payload jsonb default null,p_request uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if p_action='advance' and exists(select 1 from public.workshop_v3_runs where job_id=p_job) then raise exception 'Oficina: recarregue o jogo para retomar a bancada atual.';end if;
 return public.player_workshop_before_v3(p_action,p_tail,p_job,p_target,p_stage,p_payload,p_request);
end $$;
revoke all on function public.player_workshop(text,uuid,uuid,text,integer,jsonb,uuid) from public,anon,service_role,pipa_server;
grant execute on function public.player_workshop(text,uuid,uuid,text,integer,jsonb,uuid) to authenticated;

create function public.server_workshop_v3(p_user uuid,p_action text,p_job uuid default null,p_tail uuid default null,
 p_target text default null,p_revision bigint default null,p_request uuid default null,p_state jsonb default null,p_result jsonb default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare j public.workshop_jobs;v public.workshop_v3_runs;m public.kite_models;receipt public.workshop_v3_receipts;
 answer jsonb;legacy jsonb;born uuid;bonus numeric;detail jsonb;old_claim text;new_status text;input_state jsonb:=p_state;input_result jsonb:=p_result;
begin
 if p_user is null or p_action is null or p_action not in('start','read','save') then raise exception 'Oficina: ação inválida.';end if;
 perform 1 from public.player_profiles where id=p_user for update;
 if not found then raise exception 'Oficina: perfil indisponível.';end if;
 if p_action<>'read' and exists(select 1 from public.player_profiles where id=p_user and active_match is not null and active_until>now()) then raise exception 'Oficina: termine a partida primeiro.';end if;
 if p_action='read' and p_request is not null then
  select * into receipt from public.workshop_v3_receipts where owner_id=p_user and request_id=p_request;
  if found then
   if receipt.job_id is distinct from p_job or receipt.body_hash is distinct from p_target then raise exception 'Oficina: confirmação já utilizada.';end if;
   return receipt.answer||jsonb_build_object('replayed',true);
  end if;
 end if;
 if p_action='start' then
  old_claim:=current_setting('request.jwt.claim.sub',true);
  perform set_config('request.jwt.claim.sub',p_user::text,true);
  legacy:=public.player_workshop_before_v3('start',p_tail,null,p_target,null,null,null);
  perform set_config('request.jwt.claim.sub',coalesce(old_claim,''),true);
  select * into j from public.workshop_jobs where id=(legacy->>'id')::uuid and owner_id=p_user for update;
  select * into v from public.workshop_v3_runs where job_id=j.id;
  if not found then
   if j.stage<>0 or j.status<>'building' then raise exception 'Oficina: conclua a montagem antiga antes de iniciar uma nova.';end if;
   select * into m from public.kite_models where id=j.result_model_id;
   insert into public.workshop_v3_runs(job_id,kind) values(j.id,case when m.id='rabbito' then 'comum' when m.rarity in('incomum','uncommon') then 'incomum' when m.rarity in('raro','rare','épico','epico','lendário','legendary','especial') then 'raro' else 'comum' end) returning * into v;
  elsif j.status='failed' then
   if not exists(select 1 from public.summon_tails where id=j.tail_id and status='ready') then raise exception 'Oficina: restaure a rabiola antes de tentar novamente.';end if;
   if exists(select 1 from public.workshop_jobs where owner_id=p_user and status='building' and id<>j.id) then raise exception 'Oficina: retome sua outra montagem.';end if;
   update public.summon_tails set status='used' where id=j.tail_id;
   update public.workshop_jobs set stage=0,status='building',quality=null,steps='[]',updated_at=clock_timestamp() where id=j.id returning * into j;
   update public.workshop_v3_runs set seed=floor(random()*4294967296),state=null,revision=revision+1,updated_at=clock_timestamp() where job_id=j.id returning * into v;
  end if;
 else
  select * into j from public.workshop_jobs where id=p_job and owner_id=p_user for update;
  if not found then raise exception 'Oficina: montagem não pertence à sua conta.';end if;
  select * into v from public.workshop_v3_runs where job_id=j.id for update;
  if not found then raise exception 'Oficina: esta montagem usa a bancada antiga.';end if;
 end if;
 if p_action='save' then
  if p_request is null or p_revision is null or p_state is null or jsonb_typeof(p_state)<>'object' or octet_length(p_state::text)>180000 then raise exception 'Oficina: checkpoint inválido.';end if;
  select * into receipt from public.workshop_v3_receipts where owner_id=p_user and request_id=p_request;
  if found then
   if receipt.job_id<>j.id or receipt.revision<>p_revision or receipt.state is distinct from p_state or receipt.result is distinct from p_result or receipt.body_hash is distinct from p_target then raise exception 'Oficina: confirmação já utilizada.';end if;
   return receipt.answer;
  end if;
  if v.revision<>p_revision or j.status<>'building' then raise exception 'Oficina: montagem atualizada em outra aba. Reabra para retomar.';end if;
  if (p_state->>'seed')::bigint<>v.seed or p_state->>'kind'<>v.kind or (p_state->>'stage')::integer not between 0 and 5 then raise exception 'Oficina: regras incompatíveis.';end if;
  if p_result is not null then
   if coalesce(p_result->>'type','') not in('born','broken') or (p_state->>'stage')::integer<>5 then raise exception 'Oficina: resultado inválido.';end if;
   if p_result->>'type'='born' then
    detail:=p_result->'craftBonus';bonus:=(detail->>'totalPercent')::numeric;
    if bonus is null or bonus not between 0 and 12 then raise exception 'Oficina: bônus inválido.';end if;
    select * into m from public.kite_models where id=j.result_model_id;
    if m.acquisition='event' then born:=public.grant_event_soul(p_user,m.id,'workshop:'||j.id::text);
    else insert into public.player_kites(owner_id,model_id) values(p_user,m.id) returning id into born;end if;
    update public.player_kites set craft_bonus=bonus,soul_variant=v.variant,craft_details=detail where id=born;
    update public.summon_tails set status='consumed' where id=j.tail_id;
    p_result:=p_result||jsonb_build_object('variant',v.variant,'confirmed',true);
    new_status:='completed';
   else
    update public.summon_tails set status='damaged' where id=j.tail_id;
    p_result:=p_result||jsonb_build_object('variant',false,'confirmed',true,'craftBonus',null);new_status:='failed';
   end if;
   p_state:=jsonb_set(p_state,'{outcome}',p_result);
  else new_status:='building';end if;
  update public.workshop_v3_runs set state=p_state,revision=revision+1,updated_at=clock_timestamp() where job_id=j.id returning * into v;
  update public.workshop_jobs set stage=(p_state->>'stage')::integer,status=new_status,kite_id=born,
   quality=case when p_result->>'type'='born' then round((p_result->'craftBonus'->>'quality')::numeric*100)::integer else quality end,
   updated_at=clock_timestamp() where id=j.id returning * into j;
 end if;
 select * into m from public.kite_models where id=j.result_model_id;
 answer:=jsonb_build_object('id',j.id,'revision',v.revision,'seed',v.seed,'kind',v.kind,'state',v.state,'status',j.status,
 'stage',j.stage,'kiteId',j.kite_id,'modelId',m.id,'name',m.name,'color',m.color,'soul',m.soul,'updatedAt',v.updated_at);
 if p_action='save' then insert into public.workshop_v3_receipts values(p_user,p_request,j.id,p_revision,input_state,input_result,answer,p_target);end if;
 return answer;
end $$;
revoke all on function public.server_workshop_v3(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.server_workshop_v3(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb) to pipa_server;

alter function public.reserve_player_match(uuid,uuid,text,text) rename to reserve_player_match_before_workshop_v3;
revoke all on function public.reserve_player_match_before_workshop_v3(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
create function public.reserve_player_match(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare answer jsonb;k public.player_kites;b public.player_kites;
begin
 answer:=public.reserve_player_match_before_workshop_v3(p_user,p_match,p_code,p_mode);
 select * into k from public.player_kites where id=(answer->>'kiteId')::uuid;
 select * into b from public.player_kites where id=(answer->>'basicKiteId')::uuid;
 return answer||jsonb_build_object('craftBonus',k.craft_bonus,'soulVariant',k.soul_variant,'basicCraftBonus',b.craft_bonus,'basicSoulVariant',b.soul_variant);
end $$;
revoke all on function public.reserve_player_match(uuid,uuid,text,text) from public,anon,authenticated,service_role;
grant execute on function public.reserve_player_match(uuid,uuid,text,text) to service_role,pipa_server;
commit;
