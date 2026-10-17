begin;
create table public.daily_challenge_rewards(
 owner_id uuid not null references auth.users(id) on delete cascade,
 day date not null,
 match_id uuid not null unique references public.game_matches(id),
 coins integer not null default 25 check(coins=25),
 created_at timestamptz not null default now(),
 primary key(owner_id,day)
);
alter table public.daily_challenge_rewards enable row level security;
revoke all on public.daily_challenge_rewards from public,anon,authenticated,service_role,pipa_server;

-- Read-only for players. Winning is reported exclusively by the game server outbox.
create function public.player_daily() returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();today date:=(now() at time zone 'UTC')::date;wallet public.player_trails;
begin
 if uid is null then raise exception 'Entre na sua conta.';end if;
 insert into public.player_trails(owner_id,progress) values(uid,public.normalize_trails(null)) on conflict do nothing;
 select * into wallet from public.player_trails where owner_id=uid;
 return jsonb_build_object('date',today,'weather',(array['wind','wax','rain','fog'])[1+(((today-date '1970-01-01')%4+4)%4)],'reward',25,
  'claimed',exists(select 1 from public.daily_challenge_rewards where owner_id=uid and day=today),
  'progress',wallet.progress,'revision',wallet.revision);
end $$;

create function public.settle_daily_challenge(p_user uuid,p_match uuid,p_day date) returns jsonb language plpgsql security definer set search_path='' as $$
declare wallet public.player_trails;credited boolean:=false;
begin
 -- Match membership and the frozen UTC start date are checked even for trusted callers.
 if p_day is null or not exists(select 1 from public.game_matches g join public.match_players m on m.match_id=g.id
  where g.id=p_match and m.user_id=p_user and g.mode='casual' and p_day between (g.created_at at time zone 'UTC')::date-1 and (g.created_at at time zone 'UTC')::date) then
  raise exception 'Desafio diário inválido.';
 end if;
 insert into public.player_trails(owner_id,progress) values(p_user,public.normalize_trails(null)) on conflict do nothing;
 select * into wallet from public.player_trails where owner_id=p_user for update;
 insert into public.daily_challenge_rewards(owner_id,day,match_id) values(p_user,p_day,p_match) on conflict do nothing;
 credited:=found;
 if credited then
  update public.player_trails set progress=jsonb_set(progress,'{coins}',to_jsonb(least(1000000000,(progress->>'coins')::bigint+25))),
   revision=revision+1,updated_at=now() where owner_id=p_user returning * into wallet;
 end if;
 return jsonb_build_object('credited',credited,'progress',wallet.progress,'revision',wallet.revision);
end $$;
revoke all on function public.player_daily(),public.settle_daily_challenge(uuid,uuid,date) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_daily() to authenticated;
grant execute on function public.settle_daily_challenge(uuid,uuid,date) to pipa_server;
commit;
