begin;
alter table public.player_kites drop constraint player_kites_pipamon_class_check;
alter table public.player_kites drop constraint player_kites_class_rank_check;
alter table public.player_kites add check(pipamon_class in('velocista','condutor','rabbitknight')),add check(class_rank between 0 and 3);
create table public.pipamon_class_nodes(id text primary key,model_id text not null references public.kite_models(id),branch text not null,rank integer not null,parent text references public.pipamon_class_nodes(id),name text not null,description text not null,min_level integer not null,stat text,threshold real,item text,x integer not null,y integer not null,unique(model_id,branch,rank));
insert into public.pipamon_class_nodes values
('velocista-1','rabbito','velocista',1,null,'Velocista','Mobilidade e recuperação; linha mais delicada.',15,'speed',168,null,18,36),
('velocista-2','rabbito','velocista',2,'velocista-1','Rastro dos Ventos','Segundo estágio do caminho veloz.',35,'speed',173,null,18,62),
('velocista-3','rabbito','velocista',3,'velocista-2','Arauto da Tempestade','Última evolução da classe Velocista.',45,'speed',176,'pluma-dos-ventos',18,88),
('condutor-1','rabbito','condutor',1,null,'Condutor','Ataque e recuperação; voo mais lento.',15,'regen',18.4,null,50,36),
('condutor-2','rabbito','condutor',2,'condutor-1','Mestre dos Fios','Segundo estágio do caminho condutor.',35,'regen',19,null,50,62),
('condutor-3','rabbito','condutor',3,'condutor-2','Tecelão da Aurora','Última evolução da classe Condutor.',45,'regen',19.5,'carretel-celeste',50,88),
('rabbitknight','rabbito','rabbitknight',1,null,'Rabbitknight','Classe especial sem evoluções: coelho com luvas de boxe e máscara bucal de guerreiro. Ataque e defesa; menor velocidade e recuperação.',25,'attack',1.05,'mascara-do-guerreiro',82,48);
create table public.pipamon_class_unlocks(kite_id uuid not null references public.player_kites(id),node_id text not null references public.pipamon_class_nodes(id),unlocked_at timestamptz not null default now(),primary key(kite_id,node_id));
insert into public.pipamon_class_unlocks(kite_id,node_id) select k.id,n.id from public.player_kites k join public.pipamon_class_nodes n on n.model_id=k.model_id and n.branch=k.pipamon_class and n.rank<=k.class_rank;
create table public.player_class_items(owner_id uuid not null references public.player_profiles(id),item text not null check(item in('pluma-dos-ventos','carretel-celeste','mascara-do-guerreiro')),quantity integer not null default 0 check(quantity>=0),primary key(owner_id,item));
create table public.class_item_receipts(owner_id uuid not null references public.player_profiles(id),source text not null,item text not null,created_at timestamptz not null default now(),primary key(owner_id,source));
alter table public.pipamon_class_nodes enable row level security;alter table public.pipamon_class_unlocks enable row level security;alter table public.player_class_items enable row level security;alter table public.class_item_receipts enable row level security;
revoke all on public.pipamon_class_nodes,public.pipamon_class_unlocks,public.player_class_items,public.class_item_receipts from public,anon,authenticated,service_role,pipa_server;
create function public.class_base_stat(p_level integer,p_stat text) returns real language sql immutable set search_path='' as $$select case p_stat when 'speed' then 165*(1+.08*(p_level-1)/49.0) when 'regen' then 18*(1+.10*(p_level-1)/49.0) when 'attack' then 1+.12*(p_level-1)/49.0 else 0 end::real$$;
create function public.player_classes(p_kite uuid,p_node text default null,p_version integer default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();p public.player_profiles;k public.player_kites;n public.pipamon_class_nodes;l integer;known boolean;answer jsonb;
begin
 if uid is null then raise exception 'Classes: entre na conta.';end if;
 select * into p from public.player_profiles where id=uid for update;
 select * into k from public.player_kites where id=p_kite and owner_id=uid for update;
 if not found then raise exception 'Classes: parceiro não pertence à sua coleção.';end if;
 l:=public.pipamon_level(k.pipamon_xp);
 if p_node is not null then
  if p.active_match is not null and p.active_until>now() then raise exception 'Classes: saia da partida primeiro.';end if;
  if exists(select 1 from public.kite_trades where status='open' and expires_at>now() and (host=uid or guest=uid)) or exists(select 1 from public.summon_rituals where owner_id=uid and status='active' and expires_at>now()) then raise exception 'Classes: encerre a troca ou invocação primeiro.';end if;
  if p_version is null or p_version<>k.class_version then raise exception 'Classes: parceiro alterado. Atualize a ficha.';end if;
  if p_node='base' then update public.player_kites set pipamon_class=null,class_rank=0,class_version=class_version+1 where id=k.id returning * into k;
  else
   select * into n from public.pipamon_class_nodes where id=p_node and model_id=k.model_id;
   if not found then raise exception 'Classes: caminho inválido para esta espécie.';end if;
   select exists(select 1 from public.pipamon_class_unlocks where kite_id=k.id and node_id=n.id) into known;
   if not known then
    if n.parent is not null and not exists(select 1 from public.pipamon_class_unlocks where kite_id=k.id and node_id=n.parent) then raise exception 'Classes: desbloqueie o estágio anterior.';end if;
    if l<n.min_level then raise exception 'Classes: exige nível %.',n.min_level;end if;
    if n.stat is not null and public.class_base_stat(l,n.stat)<n.threshold then raise exception 'Classes: atributo base insuficiente.';end if;
    if n.item is not null then
     update public.player_class_items set quantity=quantity-1 where owner_id=uid and item=n.item and quantity>0;
     if not found then raise exception 'Classes: item especial necessário.';end if;
    end if;
    insert into public.pipamon_class_unlocks(kite_id,node_id) values(k.id,n.id);
   end if;
   update public.player_kites set pipamon_class=n.branch,class_rank=n.rank,class_version=class_version+1 where id=k.id returning * into k;
  end if;
 end if;
 select jsonb_build_object('kite',to_jsonb(k),'kiteId',k.id,'version',k.class_version,'current',case when k.pipamon_class='rabbitknight' then 'rabbitknight' when k.pipamon_class is null then 'base' else k.pipamon_class||'-'||k.class_rank end,'nodes',coalesce((select jsonb_agg(to_jsonb(c)||jsonb_build_object('unlocked',exists(select 1 from public.pipamon_class_unlocks u where u.kite_id=k.id and u.node_id=c.id),'actualStat',public.class_base_stat(l,c.stat),'hasParent',c.parent is null or exists(select 1 from public.pipamon_class_unlocks u where u.kite_id=k.id and u.node_id=c.parent))) from public.pipamon_class_nodes c where c.model_id=k.model_id),'[]'::jsonb),'parkWins',(select count(*) from public.wild_runs where owner_id=uid and status='won'),'items',coalesce((select jsonb_object_agg(item,quantity) from public.player_class_items where owner_id=uid),'{}'::jsonb)) into answer;
 return answer;
end $$;
-- Retire the former endpoint: all mutations must enforce the constellation requirements.
create or replace function public.player_specialization(p_kite uuid,p_class text,p_upgrade boolean,p_version integer) returns jsonb language plpgsql security definer set search_path='' as $$begin raise exception 'Classes: abra a aba Classes nos detalhes do Pipamon.';end $$;
-- Guaranteed, account-unique park milestones. Resetting the campaign never repeats them.
create function public.grant_class_milestones(p_user uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare wins integer;r record;awards jsonb:='[]'::jsonb;
begin
 perform 1 from public.player_profiles where id=p_user for update;
 select count(*) into wins from public.wild_runs where owner_id=p_user and status='won';
 for r in select n*5 wins,case (n-1)%3 when 0 then 'pluma-dos-ventos' when 1 then 'carretel-celeste' else 'mascara-do-guerreiro' end item from generate_series(1,wins/5) n loop
  if wins>=r.wins then
   insert into public.class_item_receipts(owner_id,source,item) values(p_user,'park-wins:'||r.wins,r.item) on conflict do nothing;
   if found then awards:=awards||jsonb_build_array(r.item);insert into public.player_class_items(owner_id,item,quantity) values(p_user,r.item,1) on conflict(owner_id,item) do update set quantity=public.player_class_items.quantity+1;end if;
  end if;
 end loop;return awards;
end $$;
alter function public.settle_wild_run(uuid,uuid,text) rename to settle_wild_before_classes;
revoke all on function public.settle_wild_before_classes(uuid,uuid,text) from public,anon,authenticated,service_role,pipa_server;
create function public.settle_wild_run(p_user uuid,p_match uuid,p_outcome text) returns jsonb language plpgsql security definer set search_path='' as $$declare answer jsonb;awards jsonb:='[]'::jsonb;begin answer:=public.settle_wild_before_classes(p_user,p_match,p_outcome);if answer ? 'classItems' then return answer;end if;if answer->>'status'='won' then awards:=public.grant_class_milestones(p_user);end if;answer:=answer||jsonb_build_object('classItems',awards);update public.wild_runs set result=answer where match_id=p_match;return answer;end $$;
select public.grant_class_milestones(id) from public.player_profiles;
revoke all on function public.class_base_stat(integer,text),public.player_classes(uuid,text,integer),public.grant_class_milestones(uuid),public.settle_wild_run(uuid,uuid,text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_classes(uuid,text,integer) to authenticated;
grant execute on function public.settle_wild_run(uuid,uuid,text) to pipa_server;
commit;
