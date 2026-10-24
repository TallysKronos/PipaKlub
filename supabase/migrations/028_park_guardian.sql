-- Third park route. No reset, no replacement of owned partners, no client rewards.
begin;
alter table public.wild_runs drop constraint wild_runs_zone_check;
alter table public.wild_runs add constraint wild_runs_zone_check check(zone in('park-trail','park-clearing','park-veredas'));
alter table public.wild_runs drop constraint wild_runs_enemy_level_check;
alter table public.wild_runs add constraint wild_runs_enemy_level_check check(enemy_level between 1 and 15);

alter function public.register_wild_run(uuid,uuid,text) rename to register_wild_before_guardian;
revoke all on function public.register_wild_before_guardian(uuid,uuid,text) from public,anon,authenticated,service_role,pipa_server;
create function public.register_wild_run(p_user uuid,p_match uuid,p_zone text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare answer jsonb;r public.wild_runs;
begin
 if p_zone is distinct from 'park-veredas' then return public.register_wild_before_guardian(p_user,p_match,p_zone);end if;
 perform 1 from public.player_profiles where id=p_user for update;
 select * into r from public.wild_runs where match_id=p_match;
 if found then
  if r.owner_id<>p_user or r.zone<>p_zone then raise exception 'Exploração: encontro inválido.';end if;
 else
  -- Reuse the reservation, journey, equipped partner and pending-run checks.
  answer:=public.register_wild_before_guardian(p_user,p_match,'park-clearing');
  update public.wild_runs set zone='park-veredas',enemy_level=15 where match_id=p_match and owner_id=p_user;
 end if;
 return jsonb_build_object('zone','park-veredas','boss',true,'name','Lacertubo','soul','lacertubo','color',2,'level',15,'recommendedLevel',15);
end $$;

alter function public.settle_wild_run(uuid,uuid,text) rename to settle_wild_before_guardian;
revoke all on function public.settle_wild_before_guardian(uuid,uuid,text) from public,anon,authenticated,service_role,pipa_server;
create function public.settle_wild_run(p_user uuid,p_match uuid,p_outcome text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r public.wild_runs;answer jsonb;earned integer:=0;before_xp integer;earned_tamer integer:=0;first_clear boolean:=false;awards jsonb:='[]'::jsonb;
begin
 perform 1 from public.player_profiles where id=p_user for update;
 select * into r from public.wild_runs where match_id=p_match and owner_id=p_user for update;
 if not found then raise exception 'Exploração: encontro inexistente.';end if;
 if r.zone<>'park-veredas' then return public.settle_wild_before_guardian(p_user,p_match,p_outcome);end if;
 if r.result is not null then return r.result;end if;
 if p_outcome is null or p_outcome not in('won','lost','fled','abandoned') then raise exception 'Exploração: resultado inválido.';end if;
 if p_outcome='won' then
  first_clear:=not exists(select 1 from public.wild_runs where owner_id=p_user and zone='park-veredas' and status='won');
  select tamer_xp into before_xp from public.player_profiles where id=p_user;
  earned:=public.award_pipamon_xp('guardian:'||p_match,p_user,p_match,'wild',case when first_clear then 120 else 60 end);
  select tamer_xp-before_xp into earned_tamer from public.player_profiles where id=p_user;
 end if;
 answer:=jsonb_build_object('status',p_outcome,'boss',true,'firstClear',first_clear,'pipamonXp',earned,'tamerXp',earned_tamer,'tailId',null,'modelId',null,'zone',r.zone,'firstTail',false);
 update public.wild_runs set status=p_outcome,result=answer,settled_at=now() where match_id=p_match;
 if p_outcome='won' then awards:=public.grant_class_milestones(p_user);end if;
 answer:=answer||jsonb_build_object('classItems',awards);
 update public.wild_runs set result=answer where match_id=p_match;
 return answer;
end $$;

alter function public.player_wild(uuid) rename to player_wild_before_guardian;
revoke all on function public.player_wild_before_guardian(uuid) from public,anon,authenticated,service_role,pipa_server;
create function public.player_wild(p_match uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 return public.player_wild_before_guardian(p_match)||jsonb_build_object('guardianDefeated',exists(select 1 from public.wild_runs where owner_id=auth.uid() and zone='park-veredas' and status='won'));
end $$;

alter function public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) rename to player_campaign_before_guardian;
revoke all on function public.player_campaign_before_guardian(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,authenticated,service_role,pipa_server;
create function public.player_campaign(p_action text default 'read',p_revision bigint default null,p_checkpoint jsonb default null,p_keep uuid[] default null,p_seen uuid[] default null,p_confirmation text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare answer jsonb;
begin
 if p_checkpoint->>'scene'='park-veredas' and p_action in('save','autosave') then
  answer:=public.player_campaign_before_guardian(p_action,p_revision,jsonb_set(p_checkpoint,'{scene}','"park-clearing"'),p_keep,p_seen,p_confirmation);
  if p_action='save' then update public.player_campaign_saves set checkpoint=jsonb_set(checkpoint,'{scene}','"park-veredas"') where owner_id=auth.uid();
  else update public.player_campaign_saves set autosave_checkpoint=jsonb_set(autosave_checkpoint,'{scene}','"park-veredas"') where owner_id=auth.uid();end if;
  return public.player_campaign_before_guardian('read');
 end if;
 return public.player_campaign_before_guardian(p_action,p_revision,p_checkpoint,p_keep,p_seen,p_confirmation);
end $$;
revoke all on function public.register_wild_run(uuid,uuid,text),public.settle_wild_run(uuid,uuid,text),public.player_wild(uuid),public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.register_wild_run(uuid,uuid,text),public.settle_wild_run(uuid,uuid,text) to pipa_server;
grant execute on function public.player_wild(uuid),public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) to authenticated;
commit;
