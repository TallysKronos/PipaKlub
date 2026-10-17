begin;
create table public.kite_trades (
 id uuid primary key default gen_random_uuid(),
 code text not null unique default upper(substr(replace(gen_random_uuid()::text,'-',''),1,12)),
 host uuid not null references public.player_profiles(id), guest uuid references public.player_profiles(id),
 host_kite uuid references public.player_kites(id), guest_kite uuid references public.player_kites(id),
 host_confirmed boolean not null default false, guest_confirmed boolean not null default false,
 revision integer not null default 0,
 status text not null default 'open' check(status in ('open','completed','cancelled','expired')),
 created_at timestamptz not null default now(), expires_at timestamptz not null default now()+interval '10 minutes',
 finished_at timestamptz, receipt jsonb, check(host<>guest), check(host_kite<>guest_kite)
);
create index kite_trades_host on public.kite_trades(host,created_at desc);
create index kite_trades_guest on public.kite_trades(guest,created_at desc);
alter table public.kite_trades enable row level security;
revoke all on public.kite_trades from public,anon,authenticated,pipa_server,service_role;

-- Profile locks serialize trades with equip, reserve, and capture. This trigger also
-- covers future callers of reserve_player_match without replacing that RPC.
create function public.guard_trade_match() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if new.active_match is not null and new.active_until>now() and
 exists(select 1 from public.kite_trades where status='open' and expires_at>now() and (host=new.id or guest=new.id)) then
  raise exception 'Troca: cancele a negociação antes de entrar em partida.';
 end if;
 return new;
end $$;
create trigger trade_match_guard before update of active_match,active_until on public.player_profiles for each row execute function public.guard_trade_match();

-- One authenticated entry point; identities are always derived from auth.uid().
create function public.player_trade(p_action text,p_code text default null,p_kite uuid default null,p_revision integer default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); t public.kite_trades; item public.player_kites; result jsonb;
begin
 if uid is null then raise exception 'Troca: faça login.'; end if;
 if p_action not in ('create','join','read','offer','confirm','cancel','history') or p_action is null then raise exception 'Troca: ação inválida.'; end if;
 -- A transaction lock serializes room membership changes, including two concurrent
 -- joins by the same player. Acquire before any row lock to avoid lock inversion.
 perform pg_advisory_xact_lock(604216006);
 update public.kite_trades set status='expired',finished_at=clock_timestamp() where status='open' and expires_at<=clock_timestamp();
 if p_action='history' then
  select coalesce(jsonb_agg(to_jsonb(s) order by s.created_at desc),'[]'::jsonb) into result
  from (select code,status,created_at,finished_at,receipt from public.kite_trades where (host=uid or guest=uid) and status<>'open' order by created_at desc limit 50) s;
  return result;
 end if;
 if p_action='create' then
  perform 1 from public.player_profiles where id=uid for update;
  if exists(select 1 from public.player_profiles where id=uid and active_match is not null) then raise exception 'Troca: saia da partida e aguarde o resultado.'; end if;
  if exists(select 1 from public.kite_trades where status='open' and (host=uid or guest=uid)) then raise exception 'Troca: você já está em uma negociação.'; end if;
  insert into public.kite_trades(host) values(uid) returning * into t;
 else
  if p_code is null and p_action='read' then
   select * into t from public.kite_trades where status='open' and (host=uid or guest=uid);
   if not found then return null; end if;
  else
   select * into t from public.kite_trades where code=upper(trim(p_code)) for update;
   if not found then raise exception 'Troca: convite inválido.'; end if;
  end if;
  if p_action='join' then
   if t.status<>'open' then raise exception 'Troca: sala encerrada.'; end if;
   if uid<>t.host and uid is distinct from t.guest then
    if t.guest is not null then raise exception 'Troca: sala cheia.'; end if;
    perform 1 from public.player_profiles where id in(uid,t.host) order by id for update;
    if exists(select 1 from public.player_profiles where id=uid and active_match is not null) then raise exception 'Troca: saia da partida e aguarde o resultado.'; end if;
    if exists(select 1 from public.kite_trades where status='open' and (host=uid or guest=uid)) then raise exception 'Troca: você já está em uma negociação.'; end if;
    update public.kite_trades set guest=uid,revision=revision+1 where id=t.id returning * into t;
   end if;
  end if;
  if uid<>t.host and uid is distinct from t.guest then raise exception 'Troca: acesso negado.'; end if;
  if p_action in ('offer','confirm','cancel') then
   if t.status<>'open' then return jsonb_build_object('code',t.code,'status',t.status); end if;
   perform 1 from public.player_profiles where id in(t.host,t.guest) order by id for update;
   if t.expires_at<=clock_timestamp() then
    update public.kite_trades set status='expired',finished_at=clock_timestamp() where id=t.id;
    return jsonb_build_object('code',t.code,'status','expired');
   end if;
   if p_action='cancel' then
    update public.kite_trades set status='cancelled',finished_at=now() where id=t.id returning * into t;
   else
    if p_revision is distinct from t.revision then raise exception 'Troca: oferta mudou. Confira novamente.'; end if;
    if p_action='offer' then
     select * into item from public.player_kites where id=p_kite and owner_id=uid for update;
     if not found or item.permanent or exists(select 1 from public.kite_models where id=item.model_id and acquisition='event') then raise exception 'Troca: escolha uma pipa colecionável da sua coleção.'; end if;
     if exists(select 1 from public.player_profiles where id=uid and active_match is not null) then raise exception 'Troca: saia da partida e aguarde o resultado.'; end if;
     update public.kite_trades set host_kite=case when uid=host then p_kite else host_kite end,guest_kite=case when uid=guest then p_kite else guest_kite end,host_confirmed=false,guest_confirmed=false,revision=revision+1 where id=t.id returning * into t;
    else
     if t.guest is null or t.host_kite is null or t.guest_kite is null then raise exception 'Troca: cada participante deve oferecer uma pipa.'; end if;
     perform 1 from public.player_kites where id in(t.host_kite,t.guest_kite) order by id for update;
     if (select count(*) from public.player_kites k join public.kite_models m on m.id=k.model_id where ((k.id=t.host_kite and k.owner_id=t.host) or (k.id=t.guest_kite and k.owner_id=t.guest)) and not k.permanent and m.acquisition<>'event')<>2 then raise exception 'Troca: pipas indisponíveis.'; end if;
     if exists(select 1 from public.player_profiles where id in(t.host,t.guest) and active_match is not null) then raise exception 'Troca: saia da partida e aguarde o resultado.'; end if;
     update public.kite_trades set host_confirmed=host_confirmed or uid=host,guest_confirmed=guest_confirmed or uid=guest where id=t.id returning * into t;
     if t.host_confirmed and t.guest_confirmed then
      update public.player_profiles p set equipped_kite_id=(select id from public.player_kites where owner_id=p.id and model_id='basica' and permanent) where (p.id=t.host and equipped_kite_id=t.host_kite) or (p.id=t.guest and equipped_kite_id=t.guest_kite);
      update public.player_kites set owner_id=case when id=t.host_kite then t.guest else t.host end where id in(t.host_kite,t.guest_kite);
      update public.kite_trades set status='completed',finished_at=now(),receipt=jsonb_build_object(
       'hostName',(select nickname from public.player_profiles where id=t.host),
       'guestName',(select nickname from public.player_profiles where id=t.guest),
       'hostKite',(select jsonb_build_object('id',k.id,'name',m.name) from public.player_kites k join public.kite_models m on m.id=k.model_id where k.id=t.host_kite),
       'guestKite',(select jsonb_build_object('id',k.id,'name',m.name) from public.player_kites k join public.kite_models m on m.id=k.model_id where k.id=t.guest_kite)) where id=t.id returning * into t;
     end if;
    end if;
   end if;
  end if;
 end if;
 return jsonb_build_object('code',t.code,'status',t.status,'revision',t.revision,'expiresAt',t.expires_at,'isHost',uid=t.host,'hostConfirmed',t.host_confirmed,'guestConfirmed',t.guest_confirmed,
 'hostName',(select nickname from public.player_profiles where id=t.host),'guestName',(select nickname from public.player_profiles where id=t.guest),
 'hostKite',(select jsonb_build_object('id',k.id,'name',m.name) from public.player_kites k join public.kite_models m on m.id=k.model_id where k.id=t.host_kite),
 'guestKite',(select jsonb_build_object('id',k.id,'name',m.name) from public.player_kites k join public.kite_models m on m.id=k.model_id where k.id=t.guest_kite));
end $$;
revoke all on function public.guard_trade_match(),public.player_trade(text,text,uuid,integer) from public,anon,authenticated,pipa_server,service_role;
grant execute on function public.player_trade(text,text,uuid,integer) to authenticated;
commit;
