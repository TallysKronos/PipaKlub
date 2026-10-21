-- Pacote de produção: somente as migrações 017 e 018 já versionadas.
-- Mantém as coleções existentes; elas recebem o marcador legacy da abertura.
-- Contas novas passam a receber o parceiro pela história, conforme as regras da demo.
-- Nenhuma senha, hash, token ou chave é lida ou alterada.
begin;
set local lock_timeout='3s';
set local statement_timeout='15s';
do $preflight$
begin
 if to_regprocedure('public.player_journey(text,text,integer)') is null or to_regprocedure('public.pipamon_level(integer)') is null then
  raise exception 'Instale as dependências 015 e 016 antes deste pacote.';
 end if;
 if to_regclass('public.player_openings') is not null or to_regprocedure('public.player_opening(text,integer,text)') is not null then
  raise exception 'A abertura já está parcial ou integralmente instalada; não reaplicar sem revisão.';
 end if;
end $preflight$;

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

-- New story accounts meet their first partner in player_opening. Existing
-- collections are deliberately untouched, including accounts mid-opening.
create or replace function public.ensure_player(p_user uuid,p_nickname text) returns void
language plpgsql security definer set search_path='' as $$
begin
 perform pg_advisory_xact_lock(hashtextextended(p_user::text,0));
 if exists(select 1 from public.player_profiles where id=p_user) then return; end if;
 insert into public.player_profiles(id,nickname)
 values(p_user,left(coalesce(nullif(trim(p_nickname),''),'Pipeiro'),18));
end $$;
revoke all on function public.ensure_player(uuid,text) from public,anon,authenticated;
-- Preserve the reservation wrappers for lines/levels and all profile locks.
-- The permanent fallback may now be the story partner rather than basica.
create or replace function public.reserve_player_match_without_lines(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare p public.player_profiles; k public.player_kites; m public.kite_models; basic uuid;
begin
 if p_mode not in ('casual','capture') then raise exception 'Modo inválido.'; end if;
 perform public.ensure_player(p_user,'Pipeiro');
 select * into p from public.player_profiles where id=p_user for update;
 if p.active_until>now() and p.active_match<>p_match then raise exception 'Você já está em outra partida.'; end if;
 select * into k from public.player_kites where id=p.equipped_kite_id and owner_id=p_user for update;
 if not found then raise exception 'Equipe uma pipa da sua coleção.'; end if;
 select * into m from public.kite_models where id=k.model_id;
 if p_mode='capture' and m.acquisition='event' then raise exception 'Souls especiais são vinculadas à conta. Use uma pipa colecionável em Vale pipa ou jogue no casual.'; end if;
 if p_mode='capture' and k.permanent then raise exception 'Equipe uma pipa colecionável para entrar em Vale pipa.'; end if;
 select id into basic from public.player_kites where owner_id=p_user and permanent order by (model_id='basica') desc,created_at,id limit 1;
 if p_mode='capture' and basic is null then raise exception 'Conclua o nascimento do seu parceiro antes de jogar Vale pipa.';end if;
 insert into public.game_matches(id,room_code,mode) values(p_match,p_code,p_mode) on conflict(id) do nothing;
 if not exists(select 1 from public.game_matches where id=p_match and mode=p_mode and ended_at is null) then raise exception 'Partida encerrada.'; end if;
 insert into public.match_players(match_id,user_id) values(p_match,p_user) on conflict do nothing;
 update public.player_profiles set active_match=p_match,active_until=now()+interval '6 minutes' where id=p_user;
 return jsonb_build_object('accountId',p_user,'name',p.nickname,'color',m.color,'soul',m.soul,'kiteId',k.id,'kitePermanent',k.permanent,'basicKiteId',basic,'basicPartnerName',(select personal_name from public.player_kites where id=basic),'basicSoul',(select km.soul from public.player_kites bk join public.kite_models km on km.id=bk.model_id where bk.id=basic),'basicColor',(select km.color from public.player_kites bk join public.kite_models km on km.id=bk.model_id where bk.id=basic));
end $$;

create or replace function public.settle_player_cut(p_event text,p_match uuid,p_winner uuid,p_loser uuid,p_kite uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare mode text; captured boolean:=false; earned_xp integer:=0; previous public.cut_events; victim public.player_profiles; item public.player_kites;
begin
 if p_winner=p_loser then raise exception 'Corte inválido.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_event,0));
 select * into previous from public.cut_events where id=p_event;
 if found then return jsonb_build_object('captured',previous.captured,'xp',previous.xp_awarded,'duplicate',true); end if;
 select g.mode into mode from public.game_matches g where id=p_match;
 if mode is null or not exists(select 1 from public.match_players where match_id=p_match and user_id=p_winner) or not exists(select 1 from public.match_players where match_id=p_match and user_id=p_loser) then raise exception 'Participantes inválidos.'; end if;
 -- Lock both accounts in stable order to serialize captures and equipping.
 perform 1 from public.player_profiles where id in(p_winner,p_loser) order by id for update;
 select * into victim from public.player_profiles where id=p_loser;
 select * into item from public.player_kites where id=p_kite for update;
 if mode='capture' and item.id is not null and not item.permanent and item.owner_id=p_loser and victim.active_match=p_match and victim.equipped_kite_id=p_kite then
   update public.player_kites set owner_id=p_winner,captured_from=p_loser,capture_count=capture_count+1 where id=p_kite;
   update public.player_profiles set equipped_kite_id=(select id from public.player_kites where owner_id=p_loser and permanent order by (model_id='basica') desc,created_at,id limit 1) where id=p_loser;
   captured:=true;
 end if;
 -- Only the first five cuts against the same account each day earn XP.
 if (select count(*) from public.cut_events where winner_id=p_winner and loser_id=p_loser and xp_awarded>0 and created_at>now()-interval '24 hours')<5 then earned_xp:=25; end if;
 insert into public.cut_events(id,match_id,winner_id,loser_id,kite_id,captured,xp_awarded) values(p_event,p_match,p_winner,p_loser,item.id,captured,earned_xp);
 update public.player_profiles set xp=player_profiles.xp+earned_xp,cuts=cuts+1 where id=p_winner;
 return jsonb_build_object('captured',captured,'xp',earned_xp,'duplicate',false);
end $$;

notify pgrst, 'reload schema';
commit;
