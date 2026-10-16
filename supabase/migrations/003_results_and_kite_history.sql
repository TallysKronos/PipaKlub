begin;
alter table public.cut_events add column winner_name text not null default 'Pipeiro';
alter table public.cut_events add column loser_name text not null default 'Pipeiro';
alter table public.cut_events add column kite_name text not null default 'Pipa';
update public.cut_events c set
 winner_name=(select p.nickname from public.player_profiles p where p.id=c.winner_id),
 loser_name=(select p.nickname from public.player_profiles p where p.id=c.loser_id),
 kite_name=coalesce((select m.name from public.player_kites k join public.kite_models m on m.id=k.model_id where k.id=c.kite_id),'Pipa');

create function public.snapshot_cut_names() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 select p.nickname into new.winner_name from public.player_profiles p where p.id=new.winner_id;
 select p.nickname into new.loser_name from public.player_profiles p where p.id=new.loser_id;
 new.kite_name:=coalesce((select m.name from public.player_kites k join public.kite_models m on m.id=k.model_id where k.id=new.kite_id),'Pipa');
 return new;
end $$;
create trigger pipa_cut_names before insert on public.cut_events for each row execute function public.snapshot_cut_names();
create index cut_events_match_idx on public.cut_events(match_id);
create index cut_events_kite_history_idx on public.cut_events(kite_id,created_at desc) where captured;

create function public.get_player_match_result(p_match uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); result jsonb;
begin
 if uid is null or not exists(select 1 from public.match_players where match_id=p_match and user_id=uid) then raise exception 'Esta partida não está no seu histórico.'; end if;
 select jsonb_build_object(
  'match',jsonb_build_object('id',g.id,'code',g.room_code,'rules',g.mode,'startedAt',g.created_at,'endedAt',g.ended_at),
  'totals',jsonb_build_object(
   'xp',coalesce((select sum(c.xp_awarded) from public.cut_events c where c.match_id=p_match and c.winner_id=uid),0),
   'cuts',(select count(*) from public.cut_events c where c.match_id=p_match and c.winner_id=uid),
   'cutAgainst',(select count(*) from public.cut_events c where c.match_id=p_match and c.loser_id=uid),
   'captured',(select count(*) from public.cut_events c where c.match_id=p_match and c.winner_id=uid and c.captured),
   'lost',(select count(*) from public.cut_events c where c.match_id=p_match and c.loser_id=uid and c.captured)),
  'events',coalesce((select jsonb_agg(e.data order by e.at desc,e.event_id desc) from (
   select c.id as event_id,c.created_at as at,jsonb_build_object('id',c.id,'at',c.created_at,'outcome',case when c.winner_id=uid then 'cut' else 'cut_against' end,
    'opponent',case when c.winner_id=uid then c.loser_name else c.winner_name end,'kiteName',c.kite_name,'captured',c.captured,'xp',case when c.winner_id=uid then c.xp_awarded else 0 end) as data
   from public.cut_events c where c.match_id=p_match and (c.winner_id=uid or c.loser_id=uid) order by c.created_at desc,c.id desc limit 200
  ) e),'[]'::jsonb)
 ) into result from public.game_matches g where g.id=p_match;
 return result;
end $$;

create function public.get_player_recent_matches() returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); result jsonb;
begin
 if uid is null then raise exception 'Faça login.'; end if;
 select coalesce(jsonb_agg(to_jsonb(recent) order by recent."startedAt" desc),'[]'::jsonb) into result from (
  select g.id,g.room_code as code,g.mode as rules,g.created_at as "startedAt",g.ended_at as "endedAt",
   coalesce((select sum(c.xp_awarded) from public.cut_events c where c.match_id=g.id and c.winner_id=uid),0) as xp,
   (select count(*) from public.cut_events c where c.match_id=g.id and c.winner_id=uid) as cuts,
   (select count(*) from public.cut_events c where c.match_id=g.id and c.winner_id=uid and c.captured) as captured,
   (select count(*) from public.cut_events c where c.match_id=g.id and c.loser_id=uid and c.captured) as lost
  from public.game_matches g join public.match_players mp on mp.match_id=g.id and mp.user_id=uid order by g.created_at desc,g.id desc limit 10
 ) recent;
 return result;
end $$;

create function public.get_kite_history(p_kite uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); result jsonb;
begin
 if uid is null or not exists(select 1 from public.player_kites where id=p_kite and owner_id=uid) then raise exception 'Esta pipa não está na sua coleção.'; end if;
 select jsonb_build_object('name',m.name,'permanent',k.permanent,'createdAt',k.created_at,'captureCount',k.capture_count,
  'captures',coalesce((select jsonb_agg(e.data order by e.at desc,e.event_id desc) from (
   select c.id as event_id,c.created_at as at,jsonb_build_object('at',c.created_at,'from',c.loser_name,'to',c.winner_name,'room',g.room_code) as data
   from public.cut_events c join public.game_matches g on g.id=c.match_id where c.kite_id=p_kite and c.captured order by c.created_at desc,c.id desc limit 30
  ) e),'[]'::jsonb)) into result from public.player_kites k join public.kite_models m on m.id=k.model_id where k.id=p_kite and k.owner_id=uid;
 return result;
end $$;

revoke all on function public.snapshot_cut_names(),public.get_player_match_result(uuid),public.get_player_recent_matches(),public.get_kite_history(uuid) from public,anon,authenticated;
grant execute on function public.get_player_match_result(uuid),public.get_player_recent_matches(),public.get_kite_history(uuid) to authenticated;
commit;
