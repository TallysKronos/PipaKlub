-- Individual progression belongs to a kite instance, not its owner or species.
begin;
alter table public.player_kites add column pipamon_xp integer not null default 0 check(pipamon_xp between 0 and 25970);
alter table public.match_players add column pipamon_id uuid references public.player_kites(id) on delete set null;
create table public.pipamon_xp_events(
 id text primary key,owner_id uuid not null references public.player_profiles(id),
 kite_id uuid not null references public.player_kites(id),match_id uuid not null references public.game_matches(id),
 source text not null check(source in('cut','trail','daily')),xp integer not null check(xp between 0 and 120),
 created_at timestamptz not null default now()
);
create index pipamon_xp_daily on public.pipamon_xp_events(owner_id,created_at);
alter table public.pipamon_xp_events enable row level security;
revoke all on public.pipamon_xp_events from public,anon,authenticated,service_role,pipa_server;

create function public.pipamon_level(p_xp integer) returns integer
language sql immutable set search_path='' as $$
 select least(50,greatest(1,1+floor((-40+sqrt(1600+40*greatest(0,least(25970,coalesce(p_xp,0)))))/20)::integer));
$$;
create function public.snapshot_match_pipamon() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 select equipped_kite_id into new.pipamon_id from public.player_profiles where id=new.user_id;
 return new;
end $$;
create trigger pipa_snapshot_pipamon before insert on public.match_players for each row execute function public.snapshot_match_pipamon();

-- Internal only. Serialized per account, bounded, idempotent, and never client-callable.
create function public.award_pipamon_xp(p_event text,p_owner uuid,p_match uuid,p_source text,p_amount integer) returns integer
language plpgsql security definer set search_path='' as $$
declare target uuid;previous integer;amount integer;daily_total integer;
begin
 if p_amount<0 or p_amount>120 or p_source not in('cut','trail','daily') then raise exception 'XP inválido.';end if;
 perform pg_advisory_xact_lock(hashtextextended('pipamon-xp:'||p_owner::text,0));
 if exists(select 1 from public.pipamon_xp_events where id=p_event) then return 0;end if;
 select pipamon_id into target from public.match_players where match_id=p_match and user_id=p_owner;
 if target is null then return 0;end if;
 select pipamon_xp into previous from public.player_kites where id=target and owner_id=p_owner for update;
 -- A kite lost in Vale pipa never gives its new owner somebody else's reward.
 if not found then return 0;end if;
 select coalesce(sum(xp),0)::integer into daily_total from public.pipamon_xp_events where owner_id=p_owner and created_at>=date_trunc('day',now() at time zone 'UTC') at time zone 'UTC';
 amount:=greatest(0,least(p_amount,2000-daily_total,25970-previous));
 insert into public.pipamon_xp_events(id,owner_id,kite_id,match_id,source,xp) values(p_event,p_owner,target,p_match,p_source,amount);
 update public.player_kites set pipamon_xp=pipamon_xp+amount where id=target;
 return amount;
end $$;
create function public.pipamon_cut_xp() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if new.xp_awarded>0 then perform public.award_pipamon_xp('cut:'||new.id,new.winner_id,new.match_id,'cut',new.xp_awarded);end if;
 return new;
end $$;
create trigger pipa_cut_xp after insert on public.cut_events for each row execute function public.pipamon_cut_xp();
create function public.pipamon_trail_xp() returns trigger
language plpgsql security definer set search_path='' as $$
declare earned integer;
begin
 if old.result is null and new.result is not null then
  earned:=public.award_pipamon_xp('trail:'||new.match_id,new.owner_id,new.match_id,'trail',case when (new.result->>'won')::boolean then case when (new.result->>'firstClear')::boolean then 120 else 80 end else 20 end);
 end if;
 return new;
end $$;
create trigger pipa_trail_xp after update of result on public.trail_runs for each row execute function public.pipamon_trail_xp();
create function public.pipamon_daily_xp() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 perform public.award_pipamon_xp('daily:'||new.owner_id||':'||new.day,new.owner_id,new.match_id,'daily',100);
 return new;
end $$;
create trigger pipa_daily_xp after insert on public.daily_challenge_rewards for each row execute function public.pipamon_daily_xp();

-- Wrap the full existing reservation chain: retain trade locks and line cosmetics.
alter function public.reserve_player_match(uuid,uuid,text,text) rename to reserve_player_match_before_levels;
revoke all on function public.reserve_player_match_before_levels(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
create function public.reserve_player_match(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare answer jsonb;xp integer;basic_xp integer;
begin
 answer:=public.reserve_player_match_before_levels(p_user,p_match,p_code,p_mode);
 select pipamon_xp into xp from public.player_kites where id=(answer->>'kiteId')::uuid;
 select pipamon_xp into basic_xp from public.player_kites where id=(answer->>'basicKiteId')::uuid;
 return answer||jsonb_build_object('pipamonLevel',public.pipamon_level(xp),'basicPipamonLevel',public.pipamon_level(basic_xp));
end $$;
revoke all on function public.reserve_player_match(uuid,uuid,text,text) from public,anon,authenticated;
grant execute on function public.reserve_player_match(uuid,uuid,text,text) to service_role,pipa_server;

-- Add XP to the read response without changing the immutable victory receipt.
alter function public.get_player_trail_result(uuid) rename to get_player_trail_result_before_levels;
revoke all on function public.get_player_trail_result_before_levels(uuid) from public,anon,authenticated,service_role,pipa_server;
create function public.get_player_trail_result(p_match uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare answer jsonb;earned integer;
begin
 answer:=public.get_player_trail_result_before_levels(p_match);
 select xp into earned from public.pipamon_xp_events where id='trail:'||p_match and owner_id=auth.uid();
 if answer->'result'<>'null'::jsonb and earned is not null then answer:=jsonb_set(answer,'{result}',(answer->'result')||jsonb_build_object('pipamonXp',earned));end if;
 return answer;
end $$;
revoke all on function public.get_player_trail_result(uuid) from public,anon,service_role,pipa_server;
grant execute on function public.get_player_trail_result(uuid) to authenticated;
revoke all on function public.pipamon_level(integer),public.snapshot_match_pipamon(),public.award_pipamon_xp(text,uuid,uuid,text,integer),public.pipamon_cut_xp(),public.pipamon_trail_xp(),public.pipamon_daily_xp() from public,anon,authenticated,service_role,pipa_server;
commit;
