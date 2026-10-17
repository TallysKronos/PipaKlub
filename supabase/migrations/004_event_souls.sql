-- Event Souls are account-bound. Event delivery is an administrator-only SQL operation.
begin;
alter table public.kite_models add column soul text;
alter table public.kite_models add column acquisition text not null default 'starter' check(acquisition in ('starter','event'));
alter table public.kite_models add constraint event_soul_model check((acquisition='event' and soul is not null) or (acquisition='starter' and soul is null));
insert into public.kite_models(id,name,color,rarity,soul,acquisition) values
 ('flautrevo','Flautrevo',3,'especial','flautrevo','event'),
 ('trinca-brasas','Trinca-brasas',2,'especial','trinca-brasas','event'),
 ('alvaneve','Alvaneve',0,'especial','alvaneve','event'),
 ('chaspiral','Chaspiral',1,'especial','chaspiral','event');
-- A player may have one permanent copy of each model, including the basic kite.
drop index public.one_basic_kite_per_player;
create unique index one_permanent_model_per_player on public.player_kites(owner_id,model_id) where permanent;
create table public.soul_event_rewards (
 user_id uuid not null references public.player_profiles(id) on delete cascade,
 model_id text not null references public.kite_models(id),
 event_key text not null check(char_length(trim(event_key)) between 3 and 100),
 kite_id uuid not null references public.player_kites(id),
 granted_at timestamptz not null default now(),
 primary key(user_id,model_id)
);
alter table public.soul_event_rewards enable row level security;
revoke all on public.soul_event_rewards from public,anon,authenticated,pipa_server,service_role;
-- SECURITY INVOKER: no privilege elevation and no game-server or player access.
create function public.grant_event_soul(p_user uuid,p_model text,p_event text) returns uuid
language plpgsql set search_path='' as $$
declare item uuid;
begin
 if char_length(trim(coalesce(p_event,''))) not between 3 and 100 then raise exception 'Identifique o evento.'; end if;
 if not exists(select 1 from public.kite_models where id=p_model and acquisition='event') then raise exception 'Soul de evento inválida.'; end if;
 perform 1 from public.player_profiles where id=p_user for update;
 if not found then raise exception 'Jogador não encontrado.'; end if;
 select kite_id into item from public.soul_event_rewards where user_id=p_user and model_id=p_model;
 if found then return item; end if;
 insert into public.player_kites(owner_id,model_id,permanent) values(p_user,p_model,true) returning id into item;
 insert into public.soul_event_rewards(user_id,model_id,event_key,kite_id) values(p_user,p_model,trim(p_event),item);
 return item;
end $$;
revoke all on function public.grant_event_soul(uuid,text,text) from public,anon,authenticated,pipa_server,service_role;
-- Enforce event provenance and account binding even against accidental server-side writes.
create function public.protect_event_soul() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if exists(select 1 from public.kite_models where id=new.model_id and acquisition='event') then
  if not new.permanent then raise exception 'Soul de evento precisa ser permanente.'; end if;
  if tg_op='UPDATE' and (new.owner_id<>old.owner_id or new.model_id<>old.model_id) then raise exception 'Soul de evento é vinculada à conta.'; end if;
  if not exists(select 1 from public.soul_event_rewards where user_id=new.owner_id and model_id=new.model_id and kite_id=new.id) then raise exception 'Soul precisa de concessão por evento.'; end if;
 end if;
 if tg_op='UPDATE' and exists(select 1 from public.kite_models where id=old.model_id and acquisition='event') and new.model_id<>old.model_id then raise exception 'Soul de evento é vinculada à conta.'; end if;
 return new;
end $$;
revoke all on function public.protect_event_soul() from public,anon,authenticated,pipa_server,service_role;
-- Deferred so the administrator's atomic grant can insert the item and provenance together.
create constraint trigger pipa_event_soul_protection after insert or update on public.player_kites deferrable initially deferred for each row execute function public.protect_event_soul();

create or replace function public.reserve_player_match(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb
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
 select id into basic from public.player_kites where owner_id=p_user and model_id='basica' and permanent;
 insert into public.game_matches(id,room_code,mode) values(p_match,p_code,p_mode) on conflict(id) do nothing;
 if not exists(select 1 from public.game_matches where id=p_match and mode=p_mode and ended_at is null) then raise exception 'Partida encerrada.'; end if;
 insert into public.match_players(match_id,user_id) values(p_match,p_user) on conflict do nothing;
 update public.player_profiles set active_match=p_match,active_until=now()+interval '6 minutes' where id=p_user;
 return jsonb_build_object('accountId',p_user,'name',p.nickname,'color',m.color,'soul',m.soul,'kiteId',k.id,'kitePermanent',k.permanent,'basicKiteId',basic);
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
   update public.player_profiles set equipped_kite_id=(select id from public.player_kites where owner_id=p_loser and model_id='basica' and permanent) where id=p_loser;
   captured:=true;
 end if;
 -- Only the first five cuts against the same account each day earn XP.
 if (select count(*) from public.cut_events where winner_id=p_winner and loser_id=p_loser and xp_awarded>0 and created_at>now()-interval '24 hours')<5 then earned_xp:=25; end if;
 insert into public.cut_events(id,match_id,winner_id,loser_id,kite_id,captured,xp_awarded) values(p_event,p_match,p_winner,p_loser,item.id,captured,earned_xp);
 update public.player_profiles set xp=player_profiles.xp+earned_xp,cuts=cuts+1 where id=p_winner;
 return jsonb_build_object('captured',captured,'xp',earned_xp,'duplicate',false);
end $$;
commit;
