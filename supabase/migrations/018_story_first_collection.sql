begin;
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
commit;
