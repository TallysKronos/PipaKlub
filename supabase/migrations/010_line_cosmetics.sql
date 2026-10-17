begin;
create table public.line_styles(id text primary key,name text not null,price integer not null check(price>=0));
insert into public.line_styles values('classic','Linha clássica',0),('azul','Azul do céu',30),('coral','Coral da laje',30),('menta','Brisa de menta',40),('pontilhada','Caminho de estrelas',60),('dourada','Fio de luz',100);
create table public.player_line_styles(owner_id uuid not null references auth.users(id) on delete cascade,style_id text not null references public.line_styles(id),created_at timestamptz not null default now(),primary key(owner_id,style_id));
create table public.player_line_equipment(owner_id uuid primary key references auth.users(id) on delete cascade,style_id text not null default 'classic' references public.line_styles(id));
create table public.line_purchases(id uuid primary key,owner_id uuid not null references auth.users(id) on delete cascade,style_id text not null references public.line_styles(id),price integer not null,created_at timestamptz not null default now());
create index line_purchases_owner on public.line_purchases(owner_id);
alter table public.line_styles enable row level security;
alter table public.player_line_styles enable row level security;
alter table public.player_line_equipment enable row level security;
alter table public.line_purchases enable row level security;
revoke all on public.line_styles,public.player_line_styles,public.player_line_equipment,public.line_purchases from public,anon,authenticated,service_role,pipa_server;
create function public.player_lines(p_action text default 'read',p_style text default null,p_operation uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();item public.line_styles;old public.line_purchases;wallet public.player_trails;owned boolean;
begin
 if uid is null then raise exception 'Linhas: entre na sua conta.';end if;
 if p_action is null or p_action not in('read','buy','equip') then raise exception 'Linhas: ação inválida.';end if;
 -- Same profile lock order as match reservation/equipment; wallet lock serializes trail credits and purchases.
 perform 1 from public.player_profiles where id=uid for update;
 insert into public.player_trails(owner_id,progress) values(uid,public.normalize_trails(null)) on conflict do nothing;
 select * into wallet from public.player_trails where owner_id=uid for update;
 if p_action<>'read' then
  select * into item from public.line_styles where id=p_style;
  if not found then raise exception 'Linhas: visual inválido.';end if;
  owned:=p_style='classic' or exists(select 1 from public.player_line_styles where owner_id=uid and style_id=p_style);
  if p_action='buy' then
   if p_operation is null then raise exception 'Linhas: compra inválida.';end if;
   perform pg_advisory_xact_lock(hashtextextended(p_operation::text,0));
   select * into old from public.line_purchases where id=p_operation;
   if found and (old.owner_id<>uid or old.style_id<>p_style) then raise exception 'Linhas: compra já utilizada.';end if;
   if not owned then
    if (wallet.progress->>'coins')::bigint<item.price then raise exception 'Linhas: moedas insuficientes.';end if;
    insert into public.player_line_styles(owner_id,style_id) values(uid,p_style);
    insert into public.line_purchases(id,owner_id,style_id,price) values(p_operation,uid,p_style,item.price);
    update public.player_trails set progress=jsonb_set(progress,'{coins}',to_jsonb((progress->>'coins')::bigint-item.price)),revision=revision+1,updated_at=now() where owner_id=uid returning * into wallet;
   elsif old.id is null then
    insert into public.line_purchases(id,owner_id,style_id,price) values(p_operation,uid,p_style,0);
   end if;
  else
   if not owned then raise exception 'Linhas: adquira este visual primeiro.';end if;
   if exists(select 1 from public.player_profiles where id=uid and active_match is not null and active_until>now()) then raise exception 'Linhas: saia da partida para trocar o visual.';end if;
   insert into public.player_line_equipment(owner_id,style_id) values(uid,p_style) on conflict(owner_id) do update set style_id=excluded.style_id;
  end if;
 end if;
 return jsonb_build_object('catalog',(select jsonb_agg(jsonb_build_object('id',id,'name',name,'price',price) order by price,id) from public.line_styles),
  'owned',(select coalesce(jsonb_agg(style_id),'[]') from public.player_line_styles where owner_id=uid),'equipped',coalesce((select style_id from public.player_line_equipment where owner_id=uid),'classic'),
  'progress',wallet.progress,'revision',wallet.revision);
end $$;
-- Preserve reservation logic (including trade locks) and add a server-selected visual to its public snapshot.
alter function public.reserve_player_match(uuid,uuid,text,text) rename to reserve_player_match_without_lines;
revoke all on function public.reserve_player_match_without_lines(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
create function public.reserve_player_match(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 result:=public.reserve_player_match_without_lines(p_user,p_match,p_code,p_mode);
 return result||jsonb_build_object('lineStyle',coalesce((select style_id from public.player_line_equipment where owner_id=p_user),'classic'));
end $$;
revoke all on function public.player_lines(text,text,uuid),public.reserve_player_match(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_lines(text,text,uuid) to authenticated;
grant execute on function public.reserve_player_match(uuid,uuid,text,text) to service_role,pipa_server;
commit;
