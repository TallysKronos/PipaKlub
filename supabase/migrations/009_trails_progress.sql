begin;
create table public.trail_stages(id text primary key,position integer unique not null,coins integer not null,rounds integer not null,drop_id text);
insert into public.trail_stages values
('morro-1',0,10,2,null),('morro-2',1,12,2,null),('morro-3',2,16,2,null),('morro-4',3,18,2,null),('morro-5',4,30,3,'rabiola-raio-de-sol'),
('praia-1',5,20,2,null),('praia-2',6,24,2,null),('praia-3',7,26,2,null),('praia-4',8,32,2,null),('praia-5',9,50,3,'rabiola-chaspiral'),
('torres-1',10,34,2,null),('torres-2',11,40,2,null),('torres-3',12,44,2,null),('torres-4',13,50,2,null),('torres-5',14,80,3,'rabiola-flautrevo');
create table public.player_trails(owner_id uuid primary key references auth.users(id) on delete cascade,progress jsonb not null,revision bigint not null default 0,updated_at timestamptz not null default now());
create table public.trail_operations(id uuid primary key,owner_id uuid not null references auth.users(id) on delete cascade,action text not null,payload jsonb not null,created_at timestamptz not null default now());
create index trail_operations_owner on public.trail_operations(owner_id,created_at);
alter table public.trail_stages enable row level security;
alter table public.player_trails enable row level security;
alter table public.trail_operations enable row level security;
revoke all on public.trail_stages,public.player_trails,public.trail_operations from public,anon,authenticated,service_role,pipa_server;
create function public.normalize_trails(p jsonb) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d jsonb:='{"coins":0,"stars":{},"mastery":0,"wins":0,"losses":0,"fails":{},"items":[]}';k text;s record;n numeric;
begin
 if p is null or jsonb_typeof(p)<>'object' then return d;end if;
 foreach k in array array['coins','wins','losses','mastery'] loop
  if jsonb_typeof(p->k)='number' then n:=greatest(0,least(case when k='mastery' then 8 else 1000000000 end,trunc((p->>k)::numeric)));d:=jsonb_set(d,array[k],to_jsonb(n));end if;
 end loop;
 for s in select * from public.trail_stages loop
  foreach k in array array['stars','fails'] loop
   if jsonb_typeof(p->k->s.id)='number' then n:=greatest(0,least(case when k='stars' then 3 else 99 end,trunc((p->k->>s.id)::numeric)));if n>0 then d:=jsonb_set(d,array[k,s.id],to_jsonb(n));end if;end if;
  end loop;
  if s.drop_id is not null and jsonb_typeof(p->'items')='array' and (p->'items') ? s.drop_id then d:=jsonb_set(d,'{items}',(d->'items')||to_jsonb(s.drop_id));end if;
 end loop;
 return d;
end $$;
create function public.player_trails(p_action text default 'read',p_operation uuid default null,p_payload jsonb default '{}'::jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();r public.player_trails;old public.trail_operations;s public.trail_stages;d jsonb;v jsonb;k text;n integer;stars integer;earned integer;first_clear boolean;won boolean;
begin
 if uid is null then raise exception 'Trilhas: entre na sua conta.';end if;
 if p_action is null or p_action not in('read','import','result') then raise exception 'Trilhas: ação inválida.';end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>4096 then raise exception 'Trilhas: dados inválidos.';end if;
 insert into public.player_trails(owner_id,progress) values(uid,public.normalize_trails(null)) on conflict do nothing;
 select * into r from public.player_trails where owner_id=uid for update;
 d:=r.progress;
 if p_action<>'read' then
  if p_operation is null then raise exception 'Trilhas: operação inválida.';end if;
  -- Serialize identities even when two different accounts claim the same visitor import.
  perform pg_advisory_xact_lock(hashtextextended(p_operation::text,0));
  select * into old from public.trail_operations where id=p_operation;
  if found then
   if old.owner_id<>uid or old.action<>p_action or old.payload<>p_payload then raise exception 'Trilhas: operação já utilizada com outros dados.';end if;
   return jsonb_build_object('progress',d,'revision',r.revision);
  end if;
  if p_action='import' then
   v:=public.normalize_trails(p_payload);
   foreach k in array array['coins','wins','losses'] loop d:=jsonb_set(d,array[k],to_jsonb(least(1000000000,(d->>k)::bigint+(v->>k)::bigint)));end loop;
   d:=jsonb_set(d,'{mastery}',to_jsonb(greatest((d->>'mastery')::integer,(v->>'mastery')::integer)));
   for s in select * from public.trail_stages loop
    foreach k in array array['stars','fails'] loop n:=greatest(coalesce((d->k->>s.id)::integer,0),coalesce((v->k->>s.id)::integer,0));if n>0 then d:=jsonb_set(d,array[k,s.id],to_jsonb(n));end if;end loop;
   end loop;
   d:=jsonb_set(d,'{items}',(select coalesce(jsonb_agg(distinct value),'[]') from jsonb_array_elements((d->'items')||(v->'items'))));
  else
   select * into s from public.trail_stages where id=p_payload->>'stage';
   if not found or (jsonb_typeof(p_payload->'won')='boolean') is not true or (jsonb_typeof(p_payload->'roundsLost')='number') is not true then raise exception 'Trilhas: resultado inválido.';end if;
   if (p_payload->>'roundsLost')::numeric<>trunc((p_payload->>'roundsLost')::numeric) or (p_payload->>'roundsLost')::numeric<0 or (p_payload->>'roundsLost')::numeric>5 then raise exception 'Trilhas: rodadas inválidas.';end if;
   if s.position>0 and not exists(select 1 from public.trail_stages prev where prev.position=s.position-1 and coalesce((d->'stars'->>prev.id)::integer,0)>0) then raise exception 'Trilhas: vença a etapa anterior.';end if;
   won:=(p_payload->>'won')::boolean;
   if won then
    if (p_payload->>'roundsLost')::integer>=s.rounds then raise exception 'Trilhas: rodadas inválidas.';end if;
    stars:=greatest(1,3-(p_payload->>'roundsLost')::integer);first_clear:=not (d->'stars' ? s.id);
    earned:=round(s.coins*(1+(stars-1)*0.25))::integer+case when first_clear then s.coins else 0 end;
    d:=jsonb_set(d,'{coins}',to_jsonb(least(1000000000,(d->>'coins')::bigint+earned)));
    d:=jsonb_set(d,'{wins}',to_jsonb(least(1000000000,(d->>'wins')::bigint+1)));
    d:=jsonb_set(d,array['stars',s.id],to_jsonb(greatest(coalesce((d->'stars'->>s.id)::integer,0),stars)));
    d:=jsonb_set(d,'{mastery}',to_jsonb(least(8,(d->>'mastery')::integer+case when stars=3 then 2 else 1 end)));
    d:=jsonb_set(d,'{fails}',(d->'fails')-s.id);
    if s.drop_id is not null and not (d->'items' ? s.drop_id) then d:=jsonb_set(d,'{items}',(d->'items')||to_jsonb(s.drop_id));end if;
   else
    n:=least(99,coalesce((d->'fails'->>s.id)::integer,0)+1);d:=jsonb_set(d,array['fails',s.id],to_jsonb(n));
    d:=jsonb_set(d,'{losses}',to_jsonb(least(1000000000,(d->>'losses')::bigint+1)));
    d:=jsonb_set(d,'{mastery}',to_jsonb(greatest(0,(d->>'mastery')::integer-case when n>=2 then 2 else 1 end)));
   end if;
  end if;
  insert into public.trail_operations(id,owner_id,action,payload) values(p_operation,uid,p_action,p_payload);
  update public.player_trails set progress=d,revision=revision+1,updated_at=now() where owner_id=uid returning * into r;
 end if;
 return jsonb_build_object('progress',r.progress,'revision',r.revision);
end $$;
revoke all on function public.normalize_trails(jsonb),public.player_trails(text,uuid,jsonb) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_trails(text,uuid,jsonb) to authenticated;
commit;
