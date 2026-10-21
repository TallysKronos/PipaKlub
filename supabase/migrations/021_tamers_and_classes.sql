begin;
alter table public.player_profiles add column tamer_xp integer not null default 0 check(tamer_xp between 0 and 31383);
update public.player_profiles set tamer_xp=least(31383,greatest(0,xp));
alter table public.player_kites add column pipamon_class text check(pipamon_class in('velocista','condutor')),
 add column class_rank integer not null default 0 check(class_rank between 0 and 2),add column class_version integer not null default 0,
 add constraint valid_specialization check((pipamon_class is null and class_rank=0) or (model_id='rabbito' and pipamon_class is not null and class_rank>0));
create table public.tamer_xp_events(owner_id uuid not null references public.player_profiles(id),event_id text not null,xp integer not null check(xp>=0),created_at timestamptz not null default now(),primary key(owner_id,event_id));
alter table public.tamer_xp_events enable row level security;
revoke all on public.tamer_xp_events from public,anon,authenticated,service_role,pipa_server;
create function public.award_tamer_xp(p_owner uuid,p_event text,p_amount integer) returns integer language plpgsql security definer set search_path='' as $$
declare credited integer;
begin
 perform 1 from public.player_profiles where id=p_owner for update;
 if not found or p_amount not between 0 and 25000 then raise exception 'Progressão: concessão inválida.';end if;
 if exists(select 1 from public.tamer_xp_events where owner_id=p_owner and event_id=p_event) then return 0;end if;
 select least(p_amount,31383-tamer_xp) into credited from public.player_profiles where id=p_owner;
 insert into public.tamer_xp_events values(p_owner,p_event,credited,now());
 update public.player_profiles set tamer_xp=tamer_xp+credited where id=p_owner;return credited;
end $$;
-- Existing collections are baselined, never rewarded again by a reset or trade.
insert into public.tamer_xp_events(owner_id,event_id,xp) select owner_id,'seen:'||model_id,0 from public.player_pipamon_sightings;
insert into public.tamer_xp_events(owner_id,event_id,xp) select distinct owner_id,'acquire:'||model_id,0 from public.player_kites where owner_id is not null;
create function public.tamer_discovery() returns trigger language plpgsql security definer set search_path='' as $$
begin perform public.award_tamer_xp(new.owner_id,'seen:'||new.model_id,5);return new;end $$;
create trigger tamer_discovery after insert on public.player_pipamon_sightings for each row execute function public.tamer_discovery();
create function public.tamer_summon() returns trigger language plpgsql security definer set search_path='' as $$
begin if new.status='succeeded' and old.status is distinct from 'succeeded' then perform public.award_tamer_xp(new.owner_id,'acquire:'||new.result_model_id,20);end if;return new;end $$;
create trigger tamer_summon after update of status on public.summon_rituals for each row execute function public.tamer_summon();
create function public.tamer_story_partner() returns trigger language plpgsql security definer set search_path='' as $$
begin perform public.award_tamer_xp(new.owner_id,'acquire:rabbito',20);return new;end $$;
create trigger tamer_story_partner after insert on public.campaign_story_births for each row execute function public.tamer_story_partner();
alter table public.pipamon_xp_events drop constraint pipamon_xp_events_source_check;
alter table public.pipamon_xp_events add check(source in('cut','trail','daily','wild'));
-- No daily cap for verified PvE. Tamer gains only from XP actually developed by a partner.
create or replace function public.award_pipamon_xp(p_event text,p_owner uuid,p_match uuid,p_source text,p_amount integer) returns integer language plpgsql security definer set search_path='' as $$
declare target uuid;previous integer;amount integer;
begin
 if p_amount<0 or p_amount>120 or p_source not in('cut','trail','daily','wild') then raise exception 'XP inválido.';end if;
 perform 1 from public.player_profiles where id=p_owner for update;
 perform pg_advisory_xact_lock(hashtextextended('pipamon-xp:'||p_owner::text,0));
 if exists(select 1 from public.pipamon_xp_events where id=p_event) then return 0;end if;
 select pipamon_id into target from public.match_players where match_id=p_match and user_id=p_owner;
 if target is null then return 0;end if;
 select pipamon_xp into previous from public.player_kites where id=target and owner_id=p_owner for update;
 if not found then return 0;end if;
 amount:=greatest(0,least(p_amount,25970-previous));
 insert into public.pipamon_xp_events(id,owner_id,kite_id,match_id,source,xp) values(p_event,p_owner,target,p_match,p_source,amount);
 update public.player_kites set pipamon_xp=pipamon_xp+amount where id=target;
 perform public.award_tamer_xp(p_owner,'partner:'||p_event,floor(amount/5.0)::integer);return amount;
end $$;
create function public.player_specialization(p_kite uuid,p_class text,p_upgrade boolean,p_version integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();p public.player_profiles;k public.player_kites;l integer;
begin
 if uid is null then raise exception 'Classes: entre na conta.';end if;
 select * into p from public.player_profiles where id=uid for update;
 if p.active_match is not null and p.active_until>now() then raise exception 'Saia da partida antes de mudar a classe.';end if;
 if exists(select 1 from public.kite_trades where status='open' and expires_at>now() and (host=uid or guest=uid)) then raise exception 'Classes: encerre a troca primeiro.';end if;
 if exists(select 1 from public.summon_rituals where owner_id=uid and status='active' and expires_at>now()) then raise exception 'Classes: conclua a invocação primeiro.';end if;
 select * into k from public.player_kites where id=p_kite and owner_id=uid for update;
 if not found or k.model_id<>'rabbito' then raise exception 'Classes: escolha um Rabbito da sua coleção.';end if;
 if p_version is null or p_version<>k.class_version then raise exception 'Classes: parceiro alterado. Atualize sua coleção.';end if;
 if p_class is null or p_class not in('velocista','condutor') or p_upgrade is null then raise exception 'Classes: opção inválida.';end if;
 l:=public.pipamon_level(k.pipamon_xp);
 if l<15 or (p_upgrade and l<35) then raise exception 'Classes: escolha no nível 15; aprimore no nível 35.';end if;
 update public.player_kites set pipamon_class=p_class,class_rank=case when p_upgrade then 2 else greatest(1,k.class_rank) end,class_version=class_version+1 where id=k.id returning * into k;
 return to_jsonb(k);
end $$;
alter function public.reserve_player_match(uuid,uuid,text,text) rename to reserve_player_match_before_classes;
revoke all on function public.reserve_player_match_before_classes(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
create function public.reserve_player_match(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb language plpgsql security definer set search_path='' as $$
declare answer jsonb;k public.player_kites;b public.player_kites;
begin
 answer:=public.reserve_player_match_before_classes(p_user,p_match,p_code,p_mode);
 select * into k from public.player_kites where id=(answer->>'kiteId')::uuid;
 select * into b from public.player_kites where id=(answer->>'basicKiteId')::uuid;
 return answer||jsonb_build_object('pipamonClass',k.pipamon_class,'classRank',k.class_rank,'basicPipamonClass',b.pipamon_class,'basicClassRank',b.class_rank);
end $$;
revoke all on function public.award_tamer_xp(uuid,text,integer),public.tamer_discovery(),public.tamer_summon(),public.tamer_story_partner(),public.player_specialization(uuid,text,boolean,integer),public.reserve_player_match(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_specialization(uuid,text,boolean,integer) to authenticated;
grant execute on function public.reserve_player_match(uuid,uuid,text,text) to pipa_server;
commit;
