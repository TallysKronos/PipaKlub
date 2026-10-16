-- Pipa Club: run once in the SQL editor of the project's own Supabase database.
begin;
create table public.kite_models (
 id text primary key, name text not null, color smallint not null check(color between 0 and 3), rarity text not null default 'comum'
);
insert into public.kite_models(id,name,color,rarity) values
 ('basica','Pipa de rua',0,'básica'),('mata','Mata verde',1,'comum'),('azulao','Azulão',2,'comum'),('raio','Raio de sol',3,'comum');
create table public.player_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 nickname text not null check(char_length(nickname) between 2 and 18),
 xp bigint not null default 0 check(xp>=0), cuts integer not null default 0,
 equipped_kite_id uuid, active_match uuid, active_until timestamptz,
 created_at timestamptz not null default now()
);
create table public.player_kites (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.player_profiles(id) on delete cascade,
 model_id text not null references public.kite_models(id), permanent boolean not null default false,
 capture_count integer not null default 0, captured_from uuid references public.player_profiles(id) on delete set null,
 created_at timestamptz not null default now()
);
create index player_kites_owner_idx on public.player_kites(owner_id);
create unique index one_basic_kite_per_player on public.player_kites(owner_id) where permanent;
alter table public.player_profiles add constraint equipped_kite_fk foreign key(equipped_kite_id) references public.player_kites(id) on delete set null;
create table public.game_matches (
 id uuid primary key, room_code text not null, mode text not null check(mode in ('casual','capture')),
 created_at timestamptz not null default now(), ended_at timestamptz
);
create table public.match_players (
 match_id uuid not null references public.game_matches(id), user_id uuid not null references public.player_profiles(id),
 joined_at timestamptz not null default now(), primary key(match_id,user_id)
);
create table public.cut_events (
 id text primary key, match_id uuid not null references public.game_matches(id),
 winner_id uuid not null references public.player_profiles(id), loser_id uuid not null references public.player_profiles(id),
 kite_id uuid references public.player_kites(id), captured boolean not null default false,
 xp_awarded integer not null default 0, created_at timestamptz not null default now(), check(winner_id<>loser_id)
);
create index cut_events_pair_time on public.cut_events(winner_id,loser_id,created_at);
alter table public.kite_models enable row level security;
alter table public.player_profiles enable row level security;
alter table public.player_kites enable row level security;
alter table public.game_matches enable row level security;
alter table public.match_players enable row level security;
alter table public.cut_events enable row level security;
create policy models_read on public.kite_models for select to authenticated using(true);
create policy profile_self_read on public.player_profiles for select to authenticated using(id=(select auth.uid()));
create policy inventory_self_read on public.player_kites for select to authenticated using(owner_id=(select auth.uid()));
create policy cuts_self_read on public.cut_events for select to authenticated using(winner_id=(select auth.uid()) or loser_id=(select auth.uid()));
revoke all on public.kite_models,public.player_profiles,public.player_kites,public.game_matches,public.match_players,public.cut_events from anon,authenticated;
grant select on public.kite_models,public.player_profiles,public.player_kites,public.cut_events to authenticated;
grant all on public.kite_models,public.player_profiles,public.player_kites,public.game_matches,public.match_players,public.cut_events to service_role;

create function public.ensure_player(p_user uuid,p_nickname text) returns void
language plpgsql security definer set search_path='' as $$
declare basic uuid;
begin
 perform pg_advisory_xact_lock(hashtextextended(p_user::text,0));
 if exists(select 1 from public.player_profiles where id=p_user) then return; end if;
 insert into public.player_profiles(id,nickname) values(p_user,left(coalesce(nullif(trim(p_nickname),''),'Pipeiro'),18));
 insert into public.player_kites(owner_id,model_id,permanent) values(p_user,'basica',true) returning id into basic;
 insert into public.player_kites(owner_id,model_id) values(p_user,'mata'),(p_user,'azulao'),(p_user,'raio');
 update public.player_profiles set equipped_kite_id=basic where id=p_user;
end $$;
create function public.create_player_after_signup() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 perform public.ensure_player(new.id,case when char_length(trim(coalesce(new.raw_user_meta_data->>'nickname','')))>=2 then new.raw_user_meta_data->>'nickname' else 'Pipeiro' end);
 return new;
end $$;
create trigger pipa_player_signup after insert on auth.users for each row execute function public.create_player_after_signup();

create function public.get_player_account() returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); result jsonb;
begin
 if uid is null then raise exception 'Faça login.'; end if;
 perform public.ensure_player(uid,'Pipeiro');
 select jsonb_build_object('profile',to_jsonb(p),'inventory',coalesce((select jsonb_agg(to_jsonb(k)||jsonb_build_object('model',to_jsonb(m)) order by k.permanent desc,k.created_at,k.id) from public.player_kites k join public.kite_models m on m.id=k.model_id where k.owner_id=uid),'[]'::jsonb)) into result from public.player_profiles p where p.id=uid;
 return result;
end $$;
create function public.update_player_name(p_nickname text) returns void
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Faça login.'; end if;
 if char_length(trim(p_nickname)) not between 2 and 18 then raise exception 'Use de 2 a 18 caracteres.'; end if;
 update public.player_profiles set nickname=trim(p_nickname) where id=auth.uid();
end $$;
create function public.equip_player_kite(p_kite uuid) returns void
language plpgsql security definer set search_path='' as $$
declare p public.player_profiles;
begin
 if auth.uid() is null then raise exception 'Faça login.'; end if;
 select * into p from public.player_profiles where id=auth.uid() for update;
 if p.active_until>now() then raise exception 'Saia da partida antes de trocar de pipa.'; end if;
 if not exists(select 1 from public.player_kites where id=p_kite and owner_id=auth.uid()) then raise exception 'Esta pipa não está na sua coleção.'; end if;
 update public.player_profiles set equipped_kite_id=p_kite where id=auth.uid();
end $$;

create function public.reserve_player_match(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb
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
 if p_mode='capture' and k.permanent then raise exception 'Equipe uma pipa colecionável para entrar em Vale pipa.'; end if;
 select id into basic from public.player_kites where owner_id=p_user and permanent;
 insert into public.game_matches(id,room_code,mode) values(p_match,p_code,p_mode) on conflict(id) do nothing;
 if not exists(select 1 from public.game_matches where id=p_match and mode=p_mode and ended_at is null) then raise exception 'Partida encerrada.'; end if;
 insert into public.match_players(match_id,user_id) values(p_match,p_user) on conflict do nothing;
 update public.player_profiles set active_match=p_match,active_until=now()+interval '6 minutes' where id=p_user;
 return jsonb_build_object('accountId',p_user,'name',p.nickname,'color',m.color,'kiteId',k.id,'kitePermanent',k.permanent,'basicKiteId',basic);
end $$;
create function public.release_player_match(p_user uuid,p_match uuid) returns void
language sql security definer set search_path='' as $$
 update public.player_profiles set active_match=null,active_until=null where id=p_user and active_match=p_match;
$$;
create function public.settle_player_cut(p_event text,p_match uuid,p_winner uuid,p_loser uuid,p_kite uuid) returns jsonb
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
   update public.player_profiles set equipped_kite_id=(select id from public.player_kites where owner_id=p_loser and permanent) where id=p_loser;
   captured:=true;
 end if;
 -- Only the first five cuts against the same account each day earn XP.
 if (select count(*) from public.cut_events where winner_id=p_winner and loser_id=p_loser and xp_awarded>0 and created_at>now()-interval '24 hours')<5 then earned_xp:=25; end if;
 insert into public.cut_events(id,match_id,winner_id,loser_id,kite_id,captured,xp_awarded) values(p_event,p_match,p_winner,p_loser,item.id,captured,earned_xp);
 update public.player_profiles set xp=player_profiles.xp+earned_xp,cuts=cuts+1 where id=p_winner;
 return jsonb_build_object('captured',captured,'xp',earned_xp,'duplicate',false);
end $$;
create function public.finish_player_match(p_match uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
 update public.game_matches set ended_at=coalesce(ended_at,now()) where id=p_match;
 update public.player_profiles set active_match=null,active_until=null where active_match=p_match;
end $$;

revoke all on function public.ensure_player(uuid,text),public.create_player_after_signup(),public.get_player_account(),public.update_player_name(text),public.equip_player_kite(uuid),public.reserve_player_match(uuid,uuid,text,text),public.release_player_match(uuid,uuid),public.settle_player_cut(text,uuid,uuid,uuid,uuid),public.finish_player_match(uuid) from public,anon,authenticated;
grant execute on function public.get_player_account(),public.update_player_name(text),public.equip_player_kite(uuid) to authenticated;
grant execute on function public.reserve_player_match(uuid,uuid,text,text),public.release_player_match(uuid,uuid),public.settle_player_cut(text,uuid,uuid,uuid,uuid),public.finish_player_match(uuid) to service_role;
commit;
