begin;
alter table public.workshop_jobs drop constraint workshop_jobs_status_check;
alter table public.workshop_jobs add constraint workshop_jobs_status_check check(status in('building','completed','failed','cancelled'));
alter function public.server_workshop_v3(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb) rename to server_workshop_v3_before_cancel;
revoke all on function public.server_workshop_v3_before_cancel(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb) from public,anon,authenticated,service_role,pipa_server;
create function public.server_workshop_v3(p_user uuid,p_action text,p_job uuid default null,p_tail uuid default null,
 p_target text default null,p_revision bigint default null,p_request uuid default null,p_state jsonb default null,p_result jsonb default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare j public.workshop_jobs;v public.workshop_v3_runs;m public.kite_models;result_model text;
begin
 if p_user is null then raise exception 'Oficina: entre na sua conta.';end if;
 perform 1 from public.player_profiles where id=p_user for update;
 if not found then raise exception 'Oficina: perfil indisponível.';end if;
 if p_action='cancel' then
  select * into j from public.workshop_jobs where id=p_job and owner_id=p_user for update;
  if not found then raise exception 'Oficina: montagem não pertence à sua conta.';end if;
  select * into v from public.workshop_v3_runs where job_id=j.id for update;
  if not found then raise exception 'Oficina: esta montagem usa a bancada antiga.';end if;
  -- Repeated cancellation is harmless; an old tab cannot cancel a restarted attempt.
  if j.status='cancelled' then return jsonb_build_object('id',j.id,'status','cancelled');end if;
  if p_state->>'seed' is distinct from v.seed::text then raise exception 'Oficina: esta tentativa mudou. Reabra a Oficina.';end if;
  -- Never undo a birth or a failure already confirmed by the server.
  if j.status<>'building' then return jsonb_build_object('id',j.id,'status',j.status);end if;
  update public.summon_tails set status='ready' where id=j.tail_id and owner_id=p_user and status='used';
  update public.workshop_jobs set status='cancelled',stage=0,steps='[]',quality=null,updated_at=clock_timestamp() where id=j.id;
  update public.workshop_v3_runs set state=null,revision=revision+1,updated_at=clock_timestamp() where job_id=j.id;
  return jsonb_build_object('id',j.id,'status','cancelled');
 end if;
 if p_action='start' then
  select * into j from public.workshop_jobs where tail_id=p_tail and owner_id=p_user for update;
  if found and j.status='cancelled' then
   if not exists(select 1 from public.summon_tails where id=p_tail and owner_id=p_user and status='ready') then raise exception 'Oficina: rabiola indisponível.';end if;
   if not exists(select 1 from public.player_pipamon_sightings where owner_id=p_user and model_id=p_target) then raise exception 'Oficina: conheça esta espécie primeiro.';end if;
   select case when t.model_id=p_target then p_target else r.result_model_id end into result_model
    from public.summon_tails t left join public.summon_recipes r on r.tail_model_id=t.model_id and r.target_model_id=p_target where t.id=p_tail;
   select * into m from public.kite_models where id=result_model;
   if not found then raise exception 'Oficina: rabiola incompatível com este molde.';end if;
   if m.acquisition='event' and exists(select 1 from public.player_kites where owner_id=p_user and model_id=m.id) then raise exception 'Oficina: esta Soul já está na coleção.';end if;
   -- Existing restart path creates a fresh seed, revision and empty progress.
   update public.workshop_jobs set status='failed',target_model_id=p_target,result_model_id=m.id where id=j.id;
   update public.workshop_v3_runs set kind=case when m.id='rabbito' then 'comum' when m.rarity in('incomum','uncommon') then 'incomum' when m.rarity in('raro','rare','épico','epico','lendário','legendary','especial') then 'raro' else 'comum' end,
    variant=(floor(random()*459)=0) where job_id=j.id;
  end if;
 end if;
 return public.server_workshop_v3_before_cancel(p_user,p_action,p_job,p_tail,p_target,p_revision,p_request,p_state,p_result);
end $$;
revoke all on function public.server_workshop_v3(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.server_workshop_v3(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb) to pipa_server;
commit;
