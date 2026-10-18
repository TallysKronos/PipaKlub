begin;
-- The existing 'event' storage category provides account binding. Rabbito is a
-- story partner, not a repeatable summon recipe or an event distribution.
insert into public.kite_models(id,name,color,rarity,soul,acquisition)
values('rabbito','Rabbito',0,'especial','rabbito','event');
alter table public.player_kites add column personal_name text
 check(personal_name is null or (char_length(personal_name) between 1 and 24 and personal_name !~ '[[:cntrl:]]'));
create table public.player_openings(
 owner_id uuid primary key references public.player_profiles(id) on delete cascade,
 step smallint not null default 0 check(step between 0 and 14),
 legacy boolean not null default false,
 tail_state text not null default 'unreceived' check(tail_state in ('unreceived','held','attached')),
 partner_id uuid unique references public.player_kites(id),
 updated_at timestamptz not null default now()
);
alter table public.player_openings enable row level security;
revoke all on public.player_openings from public,anon,authenticated,service_role,pipa_server;
-- Existing collections and journeys remain untouched. They may replay the film locally.
insert into public.player_openings(owner_id,step,legacy) select id,14,true from public.player_profiles;
create function public.player_opening(p_action text default 'read',p_step integer default null,p_name text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); o public.player_openings; p public.player_profiles; k uuid; n text;
begin
 if uid is null then raise exception 'Entre na sua conta.';end if;
 select * into p from public.player_profiles where id=uid for update;
 if not found then raise exception 'Conta não encontrada.';end if;
 insert into public.player_openings(owner_id) values(uid) on conflict do nothing;
 select * into o from public.player_openings where owner_id=uid for update;
 if p_action not in ('read','advance','name') then raise exception 'Abertura: ação inválida.';end if;
 if p_action<>'read' and o.legacy then raise exception 'Esta conta pode apenas rever a abertura.';end if;
 if p_action='advance' then
  if p_step is null or p_step<>o.step then raise exception 'A cena mudou. Retome a abertura.';end if;
  if o.step=10 then raise exception 'Dê um nome ao seu parceiro primeiro.';end if;
  if o.step<14 then
   update public.player_openings set step=step+1,
    tail_state=case when step=6 then 'held' when step=8 then 'attached' else tail_state end,
    updated_at=now() where owner_id=uid;
  end if;
  if o.step=13 then
   insert into public.player_journeys(owner_id,phase,starter_model) values(uid,'practice','rabbito')
   on conflict(owner_id) do update set phase='practice',starter_model='rabbito',updated_at=now()
    where public.player_journeys.phase in ('arrival','choose');
  end if;
 elsif p_action='name' then
  n:=coalesce(nullif(trim(p_name),''),'Rabbito');
  if char_length(n)>24 or n~'[[:cntrl:]]' then raise exception 'Use um nome de até 24 caracteres, sem quebras de linha.';end if;
  if o.partner_id is null then
   if o.step<>10 or o.tail_state<>'attached' then raise exception 'Conclua o nascimento do Rabbito primeiro.';end if;
   if p.active_match is not null and p.active_until>now() then raise exception 'Saia da partida antes de continuar.';end if;
   if exists(select 1 from public.kite_trades where status='open' and expires_at>now() and (host=uid or guest=uid)) then raise exception 'Encerre a troca antes de continuar.';end if;
   if exists(select 1 from public.summon_rituals where owner_id=uid and status='active' and expires_at>now()) then raise exception 'Conclua a invocação antes de continuar.';end if;
   k:=public.grant_event_soul(uid,'rabbito','story-kael-birthday-v1');
   update public.player_kites set personal_name=n where id=k and owner_id=uid;
   update public.player_profiles set equipped_kite_id=k where id=uid;
   insert into public.player_pipamon_sightings(owner_id,model_id) values(uid,'rabbito') on conflict do nothing;
   update public.player_openings set partner_id=k,step=11,updated_at=now() where owner_id=uid;
  end if;
 end if;
 select * into o from public.player_openings where owner_id=uid;
 return (to_jsonb(o)-'owner_id')||jsonb_build_object('partner_name',(select personal_name from public.player_kites where id=o.partner_id),'tail_name','Rabiola Antiga');
end $$;
revoke all on function public.player_opening(text,integer,text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_opening(text,integer,text) to authenticated;
commit;
