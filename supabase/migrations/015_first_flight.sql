begin;
-- Presentation checkpoints only. This RPC never grants currency, XP or combat wins.
create table public.player_journeys(
 owner_id uuid primary key references public.player_profiles(id) on delete cascade,
 phase text not null default 'arrival' check(phase in ('arrival','choose','practice','city','complete')),
 lesson smallint not null default 0 check(lesson between 0 and 5),
 starter_model text references public.kite_models(id),updated_at timestamptz not null default now()
);
alter table public.player_journeys enable row level security;
revoke all on public.player_journeys from public,anon,authenticated,service_role,pipa_server;
-- Existing players keep their equipment, collection and progress, and may replay locally.
insert into public.player_journeys(owner_id,phase) select id,'complete' from public.player_profiles;
create function public.player_journey(p_action text default 'read',p_model text default null,p_lesson integer default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); j public.player_journeys; p public.player_profiles; kite uuid;
begin
 if uid is null then raise exception 'Primeiro voo: faça login.';end if;
 select * into p from public.player_profiles where id=uid for update;
 if not found then raise exception 'Primeiro voo: conta não encontrada.';end if;
 insert into public.player_journeys(owner_id) values(uid) on conflict do nothing;
 select * into j from public.player_journeys where owner_id=uid for update;
 if p_action='welcome' then
  if j.phase='arrival' then update public.player_journeys set phase='choose',updated_at=now() where owner_id=uid;end if;
 elsif p_action='choose' then
  if p_model is null or p_model not in ('basica','mata','azulao','raio') then raise exception 'Primeiro voo: parceiro inválido.';end if;
  if j.starter_model is not null then
   if j.starter_model<>p_model then raise exception 'Primeiro voo: parceiro já escolhido.';end if;
  else
   if j.phase<>'choose' then raise exception 'Primeiro voo: converse com o professor.';end if;
   if p.active_match is not null and p.active_until>now() then raise exception 'Saia da partida antes de escolher.';end if;
   if exists(select 1 from public.kite_trades where status='open' and expires_at>now() and (host=uid or guest=uid)) then raise exception 'Primeiro voo: encerre sua troca antes de escolher.';end if;
   if exists(select 1 from public.summon_rituals where owner_id=uid and status='active' and expires_at>now()) then raise exception 'Primeiro voo: conclua sua invocação antes de escolher.';end if;
   -- Reuse the signup inventory; no extra copy, consumable or reward is created.
   select id into kite from public.player_kites where owner_id=uid and model_id=p_model order by permanent desc,created_at,id limit 1 for update;
   if kite is null then raise exception 'Primeiro voo: parceiro indisponível na coleção.';end if;
   update public.player_kites set permanent=true where id=kite;
   update public.player_profiles set equipped_kite_id=kite where id=uid;
   update public.player_journeys set starter_model=p_model,phase='practice',updated_at=now() where owner_id=uid;
  end if;
 elsif p_action='advance' then
  if p_lesson is null or p_lesson<0 or p_lesson>5 then raise exception 'Primeiro voo: etapa inválida.';end if;
  if j.phase='practice' then
   if p_lesson>j.lesson+1 then raise exception 'Primeiro voo: conclua a etapa anterior.';end if;
   update public.player_journeys set lesson=greatest(lesson,p_lesson),phase=case when p_lesson=5 then 'city' else phase end,updated_at=now() where owner_id=uid;
  end if;
 elsif p_action='skip' then
  if j.phase in ('practice','city') then update public.player_journeys set phase='city',updated_at=now() where owner_id=uid;
  elsif j.phase<>'complete' then raise exception 'Primeiro voo: escolha seu parceiro primeiro.';end if;
 elsif p_action='finish' then
  if j.phase='city' then update public.player_journeys set phase='complete',updated_at=now() where owner_id=uid;
  elsif j.phase<>'complete' then raise exception 'Primeiro voo: visite a cidade após escolher seu parceiro.';end if;
 elsif p_action<>'read' then raise exception 'Primeiro voo: ação inválida.';
 end if;
 select * into j from public.player_journeys where owner_id=uid;
 return to_jsonb(j)-'owner_id';
end $$;
revoke all on function public.player_journey(text,text,integer) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_journey(text,text,integer) to authenticated;
commit;
