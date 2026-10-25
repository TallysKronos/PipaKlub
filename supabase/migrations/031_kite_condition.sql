begin;
create table public.kite_conditions(kite_id uuid primary key references public.player_kites(id) on delete cascade,line_percent integer not null default 100 check(line_percent between 0 and 100),hull_percent integer not null default 100 check(hull_percent between 0 and 100),updated_at timestamptz not null default now());
create table public.kite_condition_receipts(match_id uuid not null,kite_id uuid not null,primary key(match_id,kite_id));
alter table public.kite_conditions enable row level security;
alter table public.kite_condition_receipts enable row level security;
revoke all on public.kite_conditions,public.kite_condition_receipts from public,anon,authenticated,service_role,pipa_server;
create function public.player_kite_care(p_action text default 'read') returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();begin
 if uid is null then raise exception 'Entre na sua conta.';end if;
 perform 1 from public.player_profiles where id=uid for update;
 if p_action='repair' then
  if exists(select 1 from public.player_profiles where id=uid and active_match is not null and active_until>now()) then raise exception 'Termine o encontro antes de reparar suas pipas.';end if;
  update public.kite_conditions c set line_percent=100,hull_percent=100,updated_at=clock_timestamp() from public.player_kites k where k.id=c.kite_id and k.owner_id=uid;
 elsif p_action<>'read' then raise exception 'Cuidado inválido.';end if;
 return coalesce((select jsonb_object_agg(k.id,jsonb_build_object('line',coalesce(c.line_percent,100),'hull',coalesce(c.hull_percent,100))) from public.player_kites k left join public.kite_conditions c on c.kite_id=k.id where k.owner_id=uid),'{}'::jsonb);
end $$;
revoke all on function public.player_kite_care(text) from public,anon,service_role,pipa_server;
grant execute on function public.player_kite_care(text) to authenticated;
create function public.server_kite_wear(p_user uuid,p_kite uuid,p_match uuid,p_line integer,p_hull integer) returns void language plpgsql security definer set search_path='' as $$
begin
 if p_line is null or p_hull is null or p_line not between 0 and 100 or p_hull not between 0 and 100 then raise exception 'Condição inválida.';end if;
 perform 1 from public.player_profiles where id=p_user for update;
 if not exists(select 1 from public.player_kites where id=p_kite and owner_id=p_user) then return;end if;
 insert into public.kite_condition_receipts values(p_match,p_kite) on conflict do nothing;if not found then return;end if;
 insert into public.kite_conditions(kite_id,line_percent,hull_percent) values(p_kite,p_line,p_hull) on conflict(kite_id) do update set line_percent=least(kite_conditions.line_percent,excluded.line_percent),hull_percent=least(kite_conditions.hull_percent,excluded.hull_percent),updated_at=clock_timestamp();
end $$;
revoke all on function public.server_kite_wear(uuid,uuid,uuid,integer,integer) from public,anon,authenticated,service_role;
grant execute on function public.server_kite_wear(uuid,uuid,uuid,integer,integer) to pipa_server;
alter function public.reserve_player_match(uuid,uuid,text,text) rename to reserve_player_match_before_condition;
revoke all on function public.reserve_player_match_before_condition(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
create function public.reserve_player_match(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb language plpgsql security definer set search_path='' as $$
declare answer jsonb;c public.kite_conditions;begin
 answer:=public.reserve_player_match_before_condition(p_user,p_match,p_code,case when p_mode='adventure' then 'casual' else p_mode end);
 if p_mode='adventure' then
  select * into c from public.kite_conditions where kite_id=(answer->>'kiteId')::uuid;
  if found and (c.line_percent=0 or c.hull_percent=0) then raise exception 'Sua pipa precisa de reparo. Procure o professor ou equipe outro parceiro.';end if;
  answer:=answer||jsonb_build_object('conditionLine',coalesce(c.line_percent,100),'conditionHull',coalesce(c.hull_percent,100));
 end if;return answer;
end $$;
revoke all on function public.reserve_player_match(uuid,uuid,text,text) from public,anon,authenticated,service_role;
grant execute on function public.reserve_player_match(uuid,uuid,text,text) to pipa_server,service_role;
commit;
