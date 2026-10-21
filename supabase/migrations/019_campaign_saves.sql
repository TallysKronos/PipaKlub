begin;
-- One current campaign per account. Presentation snapshots cannot grant economy.
create table public.player_campaign_saves(
 owner_id uuid primary key references public.player_profiles(id) on delete cascade,
 revision bigint not null default 0,checkpoint jsonb,saved_at timestamptz,
 generation bigint not null default 0,updated_at timestamptz not null default now()
);
-- Discarded instances retain immutable history links, but no longer belong to a player.
create table public.campaign_story_births(
 owner_id uuid not null references public.player_profiles(id),generation bigint not null,
 kite_id uuid not null unique references public.player_kites(id),primary key(owner_id,generation)
);
create table public.campaign_kite_discards(
 kite_id uuid primary key references public.player_kites(id),owner_id uuid not null references public.player_profiles(id),discarded_at timestamptz not null default now()
);
alter table public.campaign_story_births enable row level security;
alter table public.campaign_kite_discards enable row level security;
revoke all on public.campaign_story_births,public.campaign_kite_discards from public,anon,authenticated,service_role,pipa_server;
create or replace function public.protect_event_soul() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='UPDATE' and new.owner_id is null and new.model_id=old.model_id and new.permanent=old.permanent and exists(select 1 from public.campaign_kite_discards where kite_id=old.id and owner_id=old.owner_id) then return new;end if;
 if exists(select 1 from public.kite_models where id=new.model_id and acquisition='event') then
  if not new.permanent then raise exception 'Soul de evento precisa ser permanente.';end if;
  if tg_op='UPDATE' and (new.owner_id is distinct from old.owner_id or new.model_id<>old.model_id) then raise exception 'Soul de evento é vinculada à conta.';end if;
  if not exists(select 1 from public.soul_event_rewards where user_id=new.owner_id and model_id=new.model_id and kite_id=new.id) and not(new.model_id='rabbito' and exists(select 1 from public.campaign_story_births where owner_id=new.owner_id and kite_id=new.id)) then raise exception 'Soul precisa de concessão por evento ou nascimento confirmado.';end if;
 end if;
 if tg_op='UPDATE' and exists(select 1 from public.kite_models where id=old.model_id and acquisition='event') and new.model_id<>old.model_id then raise exception 'Soul de evento é vinculada à conta.';end if;
 return new;
end $$;
alter table public.player_kites alter column owner_id drop not null;
create or replace function public.remember_owned_pipamon() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.owner_id is not null then insert into public.player_pipamon_sightings(owner_id,model_id) values(new.owner_id,new.model_id) on conflict do nothing;end if;return new;
end $$;
create or replace function public.pipamon_trail_xp() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if old.result is null and new.result is not null and not coalesce((new.result->>'cancelled')::boolean,false) then
  perform public.award_pipamon_xp('trail:'||new.match_id,new.owner_id,new.match_id,'trail',case when (new.result->>'won')::boolean then case when (new.result->>'firstClear')::boolean then 120 else 80 end else 20 end);
 end if;return new;
end $$;
drop index public.one_permanent_model_per_player;
create unique index one_permanent_model_per_player on public.player_kites(owner_id,model_id) where permanent and model_id<>'rabbito';
create table public.player_pipamon_storage(
 owner_id uuid not null references public.player_profiles(id) on delete cascade,
 slot smallint not null check(slot between 1 and 20),kite_id uuid not null unique references public.player_kites(id),
 primary key(owner_id,slot)
);
alter table public.player_pipamon_storage enable row level security;
revoke all on public.player_pipamon_storage from public,anon,authenticated,service_role,pipa_server;
create function public.release_pipamon_storage() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.owner_id is distinct from old.owner_id then delete from public.player_pipamon_storage where kite_id=new.id;end if;return new;
end $$;
revoke all on function public.release_pipamon_storage() from public,anon,authenticated,service_role,pipa_server;
create trigger release_pipamon_storage after update of owner_id on public.player_kites for each row execute function public.release_pipamon_storage();
create function public.check_campaign_kite_capacity() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.owner_id is not null and (TG_OP='INSERT' or new.owner_id is distinct from old.owner_id) then
  perform 1 from public.player_profiles where id=new.owner_id for update;
  if (select count(*) from public.player_kites k where k.owner_id=new.owner_id and not exists(select 1 from public.player_pipamon_storage s where s.kite_id=k.id))>=30 then raise exception 'Depósito: banco do save cheio (30). Transfira para o global ou descarte um antes de receber outro.';end if;
 end if;return new;
end $$;
revoke all on function public.check_campaign_kite_capacity() from public,anon,authenticated,service_role,pipa_server;
create trigger campaign_kite_capacity before insert or update of owner_id on public.player_kites for each row execute function public.check_campaign_kite_capacity();
create trigger campaign_ritual_capacity before insert on public.summon_rituals for each row execute function public.check_campaign_kite_capacity();
alter function public.reserve_player_match(uuid,uuid,text,text) rename to reserve_player_match_without_campaign_storage;
revoke all on function public.reserve_player_match_without_campaign_storage(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
create function public.reserve_player_match(p_user uuid,p_match uuid,p_code text,p_mode text) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 perform 1 from public.player_profiles where id=p_user for update;
 if p_mode='capture' and (select count(*) from public.player_kites k where k.owner_id=p_user and not exists(select 1 from public.player_pipamon_storage s where s.kite_id=k.id))>=30 then raise exception 'Depósito: libere um espaço no banco do save antes de jogar Vale pipa.';end if;
 return public.reserve_player_match_without_campaign_storage(p_user,p_match,p_code,p_mode);
end $$;
revoke all on function public.reserve_player_match(uuid,uuid,text,text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.reserve_player_match(uuid,uuid,text,text) to pipa_server;
create table public.campaign_reward_history(
 owner_id uuid not null references public.player_profiles(id) on delete cascade,
 stage_id text not null references public.trail_stages(id),primary key(owner_id,stage_id)
);
alter table public.player_campaign_saves enable row level security;
alter table public.campaign_reward_history enable row level security;
revoke all on public.player_campaign_saves,public.campaign_reward_history from public,anon,authenticated,service_role,pipa_server;
create or replace function public.apply_trail_progress(p_action text default 'read',p_operation uuid default null,p_payload jsonb default '{}'::jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
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
    stars:=greatest(1,3-(p_payload->>'roundsLost')::integer);first_clear:=not (d->'stars' ? s.id) and not exists(select 1 from public.campaign_reward_history where owner_id=uid and stage_id=s.id);
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
create or replace function public.settle_trail_run(p_user uuid,p_match uuid,p_stage text,p_won boolean,p_rounds_lost integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare run public.trail_runs;stage public.trail_stages;before jsonb;snapshot jsonb;answer jsonb;tail uuid;drop_item text;subject text:=current_setting('request.jwt.claim.sub',true);
begin
 perform 1 from public.player_profiles where id=p_user for update;
 select * into run from public.trail_runs where match_id=p_match for update;
 if not found or run.owner_id<>p_user or run.stage_id<>p_stage or p_won is null or p_rounds_lost is null or p_rounds_lost<0 or p_rounds_lost>5 then raise exception 'Trilhas: resultado inválido.';end if;
 if coalesce((run.result->>'cancelled')::boolean,false) then return run.result;end if;
 if run.result is not null then
  if (run.result->>'won')::boolean<>p_won or (run.result->>'roundsLost')::integer<>p_rounds_lost then raise exception 'Trilhas: resultado já confirmado com outros dados.';end if;
  return run.result;
 end if;
 select * into stage from public.trail_stages where id=p_stage;
 if (p_won and p_rounds_lost>stage.foe_count*(stage.rounds-1)) or (not p_won and (p_rounds_lost<stage.rounds or p_rounds_lost>stage.rounds+(stage.foe_count-1)*(stage.rounds-1))) then raise exception 'Trilhas: rodadas inválidas.';end if;
 select progress into before from public.player_trails where owner_id=p_user for update;
 perform set_config('request.jwt.claim.sub',p_user::text,true);
 snapshot:=public.apply_trail_progress('result',gen_random_uuid(),jsonb_build_object('stage',p_stage,'won',p_won,'roundsLost',p_rounds_lost));
 perform set_config('request.jwt.claim.sub',coalesce(subject,''),true);
 if p_won and stage.drop_model_id is not null and not exists(select 1 from public.trail_drop_claims where owner_id=p_user and stage_id=p_stage) then
  tail:=public.grant_summon_tail(p_user,stage.drop_model_id,'drop','trail-first:'||p_stage);
  insert into public.trail_drop_claims(owner_id,stage_id,match_id,tail_id) values(p_user,p_stage,p_match,tail);
  insert into public.player_pipamon_sightings(owner_id,model_id) values(p_user,stage.drop_model_id) on conflict do nothing;
  drop_item:=stage.drop_id;
 end if;
 answer:=jsonb_build_object('matchId',p_match,'stage',p_stage,'won',p_won,'roundsLost',p_rounds_lost,'coins',(snapshot->'progress'->>'coins')::bigint-(before->>'coins')::bigint,'stars',case when p_won then greatest(1,3-p_rounds_lost) else 0 end,'firstClear',p_won and not(before->'stars' ? p_stage) and not exists(select 1 from public.campaign_reward_history where owner_id=p_user and stage_id=p_stage),'drop',drop_item,'tailId',tail);
 update public.trail_runs set result=answer where match_id=p_match;
 return answer;
end $$;
create or replace function public.player_opening(p_action text default 'read',p_step integer default null,p_name text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); o public.player_openings; p public.player_profiles; k uuid; n text;
begin
 if uid is null then raise exception 'Entre na sua conta.';end if;
 select * into p from public.player_profiles where id=uid for update;
 if not found then raise exception 'Conta não encontrada.';end if;
 insert into public.player_openings(owner_id) values(uid) on conflict do nothing;
 select * into o from public.player_openings where owner_id=uid for update;
 if p_action not in ('read','advance','name') then raise exception 'Abertura: ação inválida.';end if;
 if p_action<>'read' and o.legacy then raise exception 'Esta conta pode apenas rever a abertura.';end if;
 if p_action='advance' then
  if p_step is null or p_step<>o.step then raise exception 'A cena mudou. Retome a abertura.';end if;
  if o.step=10 then raise exception 'Dê um nome ao seu parceiro primeiro.';end if;
  if o.step<14 then
   update public.player_openings set step=step+1,
    tail_state=case when step=6 then 'held' when step=8 then 'attached' else tail_state end,
    updated_at=now() where owner_id=uid;
  end if;
  if o.step=13 then
   insert into public.player_journeys(owner_id,phase,starter_model) values(uid,'practice','rabbito')
   on conflict(owner_id) do update set phase='practice',starter_model='rabbito',updated_at=now()
    where public.player_journeys.phase in ('arrival','choose');
  end if;
 elsif p_action='name' then
  n:=coalesce(nullif(trim(p_name),''),'Rabbito');
  if char_length(n)>24 or n~'[[:cntrl:]]' then raise exception 'Use um nome de até 24 caracteres, sem quebras de linha.';end if;
  if o.partner_id is null then
   if o.step<>10 or o.tail_state<>'attached' then raise exception 'Conclua o nascimento do Rabbito primeiro.';end if;
   if p.active_match is not null and p.active_until>now() then raise exception 'Saia da partida antes de continuar.';end if;
   if exists(select 1 from public.kite_trades where status='open' and expires_at>now() and (host=uid or guest=uid)) then raise exception 'Encerre a troca antes de continuar.';end if;
   if exists(select 1 from public.summon_rituals where owner_id=uid and status='active' and expires_at>now()) then raise exception 'Conclua a invocação antes de continuar.';end if;
   -- Each campaign has one birth, protected by the profile/opening row locks.
   insert into public.player_campaign_saves(owner_id) values(uid) on conflict do nothing;
   insert into public.player_kites(owner_id,model_id,permanent) values(uid,'rabbito',true) returning id into k;
   insert into public.campaign_story_births(owner_id,generation,kite_id) select uid,generation,k from public.player_campaign_saves where owner_id=uid;
   update public.player_kites set personal_name=n where id=k and owner_id=uid;
   update public.player_profiles set equipped_kite_id=k where id=uid;
   insert into public.player_pipamon_sightings(owner_id,model_id) values(uid,'rabbito') on conflict do nothing;
   update public.player_openings set partner_id=k,step=11,updated_at=now() where owner_id=uid;
  elsif o.step=10 then
   update public.player_kites set personal_name=n where id=o.partner_id and owner_id=uid;
   update public.player_profiles set equipped_kite_id=o.partner_id where id=uid;
   update public.player_openings set step=11,updated_at=now() where owner_id=uid;
  end if;
 end if;
 select * into o from public.player_openings where owner_id=uid;
 return (to_jsonb(o)-'owner_id')||jsonb_build_object('partner_name',(select personal_name from public.player_kites where id=o.partner_id),'tail_name','Rabiola Antiga');
end $$;

create function public.player_campaign(p_action text default 'read',p_revision bigint default null,p_checkpoint jsonb default null,p_keep uuid[] default null,p_seen uuid[] default null,p_confirmation text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();p public.player_profiles;s public.player_campaign_saves;owned uuid[];chosen uuid[];entry uuid;idx integer:=0;stage text;room text;answer jsonb;
begin
 if uid is null then raise exception 'Save: entre na sua conta.';end if;
 select * into p from public.player_profiles where id=uid for update;
 if not found then raise exception 'Save: conta não encontrada.';end if;
 if p_action is null or p_action not in ('read','save','protect','reset','discard') then raise exception 'Save: ação inválida.';end if;
 insert into public.player_campaign_saves(owner_id) values(uid) on conflict do nothing;
 select * into s from public.player_campaign_saves where owner_id=uid for update;
 if p_action<>'read' then
  if p_revision is null or p_revision<>s.revision then raise exception 'Save alterado em outra aba. Atualize antes de continuar.';end if;
  if p.active_match is not null and p.active_until>now() then raise exception 'Saia da partida antes de alterar o save.';end if;
  if exists(select 1 from public.kite_trades where status='open' and expires_at>now() and (host=uid or guest=uid)) then raise exception 'Encerre sua troca antes de alterar o save.';end if;
  if exists(select 1 from public.summon_rituals where owner_id=uid and status='active' and expires_at>now()) then raise exception 'Conclua sua invocação antes de alterar o save.';end if;
 end if;
 if p_action='save' then
  if p_checkpoint is null or jsonb_typeof(p_checkpoint)<>'object' or octet_length(p_checkpoint::text)>512 then raise exception 'Save: posição inválida.';end if;
  room:=p_checkpoint->>'scene';
  if room is null or room not in ('quintal','kael-home','kael-bedroom','kite-shop','professor-home','morro','morro-area-2','morro-area-3','morro-area-4','morro-area-5') then raise exception 'Save: mapa inválido.';end if;
  if jsonb_typeof(p_checkpoint->'x') is distinct from 'number' or jsonb_typeof(p_checkpoint->'y') is distinct from 'number' or jsonb_typeof(p_checkpoint->'direction') is distinct from 'number' then raise exception 'Save: posição inválida.';end if;
  if (p_checkpoint->>'x')::numeric not between 0 and 16384 or (p_checkpoint->>'y')::numeric not between 0 and 16384 or (p_checkpoint->>'direction')::numeric not in(0,1,2,3) then raise exception 'Save: posição inválida.';end if;
  if room like 'morro%' then
   if not exists(select 1 from public.player_journeys where owner_id=uid and phase='complete') then raise exception 'Conclua o primeiro voo antes de visitar o bairro.';end if;
   if room<>'morro' then stage:='morro-'||((right(room,1))::integer-1)::text;
    if not exists(select 1 from public.player_trails where owner_id=uid and coalesce((progress->'stars'->>stage)::integer,0)>0) then raise exception 'Save: caminho ainda bloqueado.';end if;
   end if;
  end if;
  update public.player_campaign_saves set checkpoint=jsonb_build_object('scene',room,'x',p_checkpoint->'x','y',p_checkpoint->'y','direction',p_checkpoint->'direction'),saved_at=now(),revision=revision+1,updated_at=now() where owner_id=uid;
 elsif p_action in ('protect','reset','discard') then
  select coalesce(array_agg(id order by id),'{}') into owned from public.player_kites where owner_id=uid;
  if p_seen is null or (select coalesce(array_agg(id order by id),'{}') from unnest(p_seen) id)<>owned then raise exception 'Sua coleção mudou. Atualize a lista antes de continuar.';end if;
  select coalesce(array_agg(distinct id order by id),'{}') into chosen from unnest(p_keep) id;
  if cardinality(chosen)>20 or not(chosen<@owned) then raise exception 'Depósito: escolha até 20 Pipamons da sua conta.';end if;
  if p_action='reset' and p_confirmation is distinct from 'EXCLUIR SAVE' then raise exception 'Digite EXCLUIR SAVE para confirmar.';end if;
  if p_action='discard' then
   if cardinality(chosen)<>1 or p_confirmation is distinct from 'EXCLUIR PIPAMON' then raise exception 'Depósito: confirme o descarte de um Pipamon.';end if;
   insert into public.campaign_kite_discards(kite_id,owner_id) values(chosen[1],uid);
   update public.player_kites set owner_id=null where owner_id=uid and id=chosen[1];
   update public.player_profiles set equipped_kite_id=(select id from public.player_kites where owner_id=uid order by permanent desc,created_at limit 1) where id=uid and equipped_kite_id=chosen[1];
  else
  if p_action='protect' and cardinality(owned)-cardinality(chosen)>30 then raise exception 'Depósito: o banco do save tem 30 espaços. Transfira ou descarte Pipamons.';end if;
  delete from public.player_pipamon_storage where owner_id=uid;
  foreach entry in array chosen loop idx:=idx+1;insert into public.player_pipamon_storage values(uid,idx,entry);end loop;
  if p_action='reset' then
   -- Keep economy claims and first-clear history across campaign resets.
   insert into public.campaign_reward_history(owner_id,stage_id)
    select uid,t.id from public.trail_stages t join public.player_trails w on w.owner_id=uid where coalesce((w.progress->'stars'->>t.id)::integer,0)>0 on conflict do nothing;
   insert into public.campaign_kite_discards(kite_id,owner_id) select id,uid from public.player_kites where owner_id=uid and not(id=any(chosen));
   update public.player_kites set owner_id=null where owner_id=uid and not(id=any(chosen));
   update public.player_profiles set equipped_kite_id=null where id=uid;
   insert into public.player_openings(owner_id,step,legacy,tail_state,partner_id) values(uid,0,false,'unreceived',null)
    on conflict(owner_id) do update set step=0,legacy=false,tail_state='unreceived',partner_id=null,updated_at=now();
   insert into public.player_journeys(owner_id) values(uid) on conflict(owner_id) do update set phase='arrival',lesson=0,starter_model=null,updated_at=now();
   update public.player_trails set progress=jsonb_set(jsonb_set(jsonb_set(progress,'{stars}','{}'),'{fails}','{}'),'{mastery}','0'),revision=revision+1,updated_at=now() where owner_id=uid;
   -- A delayed result from an abandoned old campaign cannot reopen or reward it.
   update public.trail_runs set result=jsonb_build_object('matchId',match_id,'stage',stage_id,'won',false,'roundsLost',0,'coins',0,'stars',0,'firstClear',false,'cancelled',true,'reason','campaign-reset') where owner_id=uid and result is null;
   update public.player_campaign_saves set checkpoint=null,saved_at=null,generation=generation+1 where owner_id=uid;
  end if;
  end if;
  update public.player_campaign_saves set revision=revision+1,updated_at=now() where owner_id=uid;
 end if;
 select (to_jsonb(c)-'owner_id')||jsonb_build_object('capacity',20,'saveCapacity',30,'storage',coalesce((select jsonb_agg(jsonb_build_object('slot',b.slot,'kiteId',b.kite_id) order by b.slot) from public.player_pipamon_storage b join public.player_kites k on k.id=b.kite_id and k.owner_id=uid where b.owner_id=uid),'[]'::jsonb)) into answer from public.player_campaign_saves c where c.owner_id=uid;
 return answer;
end $$;
revoke all on function public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) to authenticated;
commit;
