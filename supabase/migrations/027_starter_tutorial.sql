begin;
-- One choice per account. Only a confirmed workshop birth closes the tutorial.
create table public.starter_tutorials(
 owner_id uuid primary key references public.player_profiles(id) on delete cascade,
 model_id text references public.kite_models(id) check(model_id in('basica','mata','azulao','raio')),
 tail_id uuid unique references public.summon_tails(id),
 completed_at timestamptz,created_at timestamptz not null default clock_timestamp()
);
alter table public.starter_tutorials enable row level security;
revoke all on public.starter_tutorials from public,anon,authenticated,service_role,pipa_server;

-- The gift cannot be spent on another recipe through a legacy workshop client.
create function public.guard_starter_workshop() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if exists(select 1 from public.starter_tutorials t where t.tail_id=new.tail_id and t.owner_id=new.owner_id
  and t.completed_at is null and (new.target_model_id<>t.model_id or new.result_model_id<>t.model_id)) then
  raise exception 'Oficina inicial: use o molde da rabiola escolhida com o professor.';
 end if;
 return new;
end $$;
revoke all on function public.guard_starter_workshop() from public,anon,authenticated,service_role,pipa_server;
create trigger starter_workshop_model before insert or update of target_model_id,result_model_id on public.workshop_jobs
 for each row execute function public.guard_starter_workshop();

create function public.player_starter_tutorial(p_action text default 'read',p_model text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); t public.starter_tutorials; j public.player_journeys;
 job public.workshop_jobs; tail uuid;
begin
 if uid is null then raise exception 'Oficina inicial: faça login.';end if;
 perform 1 from public.player_profiles where id=uid for update;
 if not found then raise exception 'Oficina inicial: perfil indisponível.';end if;
 select * into j from public.player_journeys where owner_id=uid for update;
 -- Completed and legacy campaigns keep their progress. Replays never award another tail.
 if j.phase in('practice','city') and exists(select 1 from public.player_openings where owner_id=uid and not legacy and partner_id is not null) then
  insert into public.starter_tutorials(owner_id) values(uid) on conflict do nothing;
 end if;
 select * into t from public.starter_tutorials where owner_id=uid for update;
 if not found then
  if p_action<>'read' then raise exception 'Oficina inicial: converse com o professor após o primeiro voo.';end if;
  return jsonb_build_object('required',false);
 end if;
 if p_action='choose' then
  if p_model is null or p_model not in('basica','mata','azulao','raio') then raise exception 'Oficina inicial: rabiola inválida.';end if;
  if t.model_id is not null then
   if t.model_id<>p_model then raise exception 'Oficina inicial: sua rabiola já foi escolhida.';end if;
  else
   if j.phase<>'city' or j.lesson<>5 then raise exception 'Oficina inicial: conclua o treino com Nozinho primeiro.';end if;
   tail:=public.grant_summon_tail(uid,p_model,'event','first-flight-starter-v1');
   update public.starter_tutorials set model_id=p_model,tail_id=tail where owner_id=uid returning * into t;
   insert into public.player_pipamon_sightings(owner_id,model_id) values(uid,p_model) on conflict do nothing;
  end if;
 elsif p_action='finish' then
  if t.completed_at is null then
   select w.* into job from public.workshop_jobs w join public.player_kites k on k.id=w.kite_id and k.owner_id=uid
    where w.owner_id=uid and w.tail_id=t.tail_id and w.target_model_id=t.model_id and w.result_model_id=t.model_id and w.status='completed';
   if not found then raise exception 'Oficina inicial: termine o nascimento do seu parceiro na bancada.';end if;
   update public.starter_tutorials set completed_at=clock_timestamp() where owner_id=uid returning * into t;
   update public.player_journeys set phase='complete',updated_at=clock_timestamp() where owner_id=uid;
  end if;
 elsif p_action<>'read' then raise exception 'Oficina inicial: ação inválida.';
 end if;
 -- Read-only reconciliation also handles closing/reloading after a successful birth.
 select w.* into job from public.workshop_jobs w where w.owner_id=uid and w.tail_id=t.tail_id;
 return jsonb_build_object('required',t.completed_at is null,'modelId',t.model_id,'tailId',t.tail_id,
  'jobId',job.id,'jobStatus',job.status,'completedAt',t.completed_at);
end $$;
revoke all on function public.player_starter_tutorial(text,text) from public,anon,service_role,pipa_server;
grant execute on function public.player_starter_tutorial(text,text) to authenticated;

alter function public.player_journey(text,text,integer) rename to player_journey_before_starter_tutorial;
revoke all on function public.player_journey_before_starter_tutorial(text,text,integer) from public,anon,authenticated,service_role,pipa_server;
create function public.player_journey(p_action text default 'read',p_model text default null,p_lesson integer default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare tutorial jsonb; answer jsonb;
begin
 tutorial:=public.player_starter_tutorial('read',null);
 if (tutorial->>'required')::boolean and p_action in('skip','finish') then
  raise exception 'Primeiro voo: conclua o treino e monte sua pipa com o professor.';
 end if;
 answer:=public.player_journey_before_starter_tutorial(p_action,p_model,p_lesson);
 tutorial:=public.player_starter_tutorial('read',null);
 -- Resume an already persisted birth without minting another item or partner.
 if (tutorial->>'required')::boolean and tutorial->>'jobStatus'='completed' then
  tutorial:=public.player_starter_tutorial('finish',null);
  answer:=public.player_journey_before_starter_tutorial('read',null,null);
 end if;
 return answer||jsonb_build_object('starterTutorial',tutorial);
end $$;
revoke all on function public.player_journey(text,text,integer) from public,anon,service_role,pipa_server;
grant execute on function public.player_journey(text,text,integer) to authenticated;
commit;
