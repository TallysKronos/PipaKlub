-- Publicação demo-rc.2 · passo 2: migrações 019 a 023, na ordem, geradas a partir de supabase/migrations/.
-- Cada arquivo tem sua própria transação. Se um falhar, pare e não publique o servidor.

-- ===== 019_campaign_saves.sql =====
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


-- ===== 020_campaign_autosave.sql =====
begin;
-- Slot 0 is independent from the manual checkpoint. Both belong to one campaign.
alter table public.player_campaign_saves add column autosave_enabled boolean not null default true,
 add column autosave_checkpoint jsonb, add column autosave_at timestamptz;
alter function public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) rename to player_campaign_base;
revoke all on function public.player_campaign_base(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,authenticated,service_role,pipa_server;
create function public.player_campaign(p_action text default 'read',p_revision bigint default null,p_checkpoint jsonb default null,p_keep uuid[] default null,p_seen uuid[] default null,p_confirmation text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); s public.player_campaign_saves; answer jsonb;
begin
 if uid is null then raise exception 'Save: entre na sua conta.';end if;
 -- Same lock order as manual saves, trades and inventory operations.
 perform 1 from public.player_profiles where id=uid for update;
 answer:=public.player_campaign_base('read');
 select * into s from public.player_campaign_saves where owner_id=uid for update;
 if p_action in ('autosave','settings') then
  if p_revision is null or p_revision<>s.revision then raise exception 'Save alterado em outra aba. Atualize antes de continuar.';end if;
  if p_action='settings' then
   if jsonb_typeof(p_checkpoint->'enabled') is distinct from 'boolean' then raise exception 'Save: configuração inválida.';end if;
   update public.player_campaign_saves set autosave_enabled=(p_checkpoint->>'enabled')::boolean,revision=revision+1,updated_at=now() where owner_id=uid;
  else
   if not s.autosave_enabled then raise exception 'Save: salvamento automático desligado.';end if;
   -- Reuse all authoritative checkpoint, progression and active-session checks.
   answer:=public.player_campaign_base('save',p_revision,p_checkpoint);
   update public.player_campaign_saves set autosave_checkpoint=checkpoint,autosave_at=saved_at,checkpoint=s.checkpoint,saved_at=s.saved_at where owner_id=uid;
  end if;
  return public.player_campaign_base('read');
 end if;
 answer:=public.player_campaign_base(p_action,p_revision,p_checkpoint,p_keep,p_seen,p_confirmation);
 if p_action='reset' then
  update public.player_campaign_saves set autosave_checkpoint=null,autosave_at=null where owner_id=uid;
  answer:=public.player_campaign_base('read');
 end if;
 return answer;
end;
$$;
revoke all on function public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,service_role;
grant execute on function public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) to authenticated;

commit;


-- ===== 021_tamers_and_classes.sql =====
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


-- ===== 022_wild_encounters.sql =====
begin;
create table public.wild_drop_state(owner_id uuid primary key references public.player_profiles(id),misses integer not null default 0,intro_claimed boolean not null default false);
create table public.wild_runs(match_id uuid primary key references public.game_matches(id),owner_id uuid not null references public.player_profiles(id),kite_id uuid not null references public.player_kites(id),zone text not null check(zone in('park-trail','park-clearing')),model_id text not null references public.kite_models(id),enemy_level integer not null check(enemy_level between 1 and 4),drop_roll real not null, status text not null default 'pending' check(status in('pending','won','lost','fled','abandoned')),result jsonb,created_at timestamptz not null default now(),settled_at timestamptz);
create unique index one_pending_wild on public.wild_runs(owner_id) where status='pending';
alter table public.wild_drop_state enable row level security;alter table public.wild_runs enable row level security;
revoke all on public.wild_drop_state,public.wild_runs from public,anon,authenticated,service_role,pipa_server;
create function public.register_wild_run(p_user uuid,p_match uuid,p_zone text) returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.wild_runs;model text;roll real;k uuid;intro boolean;
begin
 perform 1 from public.player_profiles where id=p_user for update;
 if p_zone is null or p_zone not in('park-trail','park-clearing') then raise exception 'Exploração: área inválida.';end if;
 if not exists(select 1 from public.player_journeys where owner_id=p_user and phase in('city','complete')) then raise exception 'Exploração: conclua o primeiro voo.';end if;
 if not exists(select 1 from public.game_matches g join public.match_players m on m.match_id=g.id where g.id=p_match and m.user_id=p_user and g.mode='casual' and g.ended_at is null) then raise exception 'Exploração: partida inválida.';end if;
 select * into r from public.wild_runs where match_id=p_match;
 if found then if r.owner_id<>p_user or r.zone<>p_zone then raise exception 'Exploração: encontro inválido.';end if;
 else
  if exists(select 1 from public.wild_runs where owner_id=p_user and status='pending') then raise exception 'Exploração: retome ou encerre seu encontro anterior.';end if;
  if exists(select 1 from public.wild_runs where owner_id=p_user and created_at>now()-interval '20 seconds') then raise exception 'Exploração: recupere o fôlego antes de buscar novamente.';end if;
  insert into public.wild_drop_state(owner_id) values(p_user) on conflict do nothing;
  select intro_claimed into intro from public.wild_drop_state where owner_id=p_user for update;
  roll:=random();model:=case when not intro then case when roll<.5 then 'basica' else 'mata' end when roll<.5 then 'basica' when roll<.85 then 'mata' else 'raio' end;
  select pipamon_id into k from public.match_players where match_id=p_match and user_id=p_user;
  insert into public.wild_runs(match_id,owner_id,kite_id,zone,model_id,enemy_level,drop_roll) values(p_match,p_user,k,p_zone,model,1+floor(random()*3)::integer+case when p_zone='park-clearing' then 1 else 0 end,random()) returning * into r;
  insert into public.player_pipamon_sightings(owner_id,model_id) values(p_user,model) on conflict do nothing;
 end if;
 return jsonb_build_object('zone',r.zone,'modelId',r.model_id,'level',r.enemy_level)|| (select jsonb_build_object('name',name,'color',color,'soul',soul) from public.kite_models where id=r.model_id);
end $$;
create function public.settle_wild_run(p_user uuid,p_match uuid,p_outcome text) returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.wild_runs;d public.wild_drop_state;tail uuid;earned integer:=0;before_xp integer;tamer integer:=0;answer jsonb;
begin
 perform 1 from public.player_profiles where id=p_user for update;
 select * into r from public.wild_runs where match_id=p_match and owner_id=p_user for update;
 if not found then raise exception 'Exploração: encontro inexistente.';end if;
 if r.result is not null then return r.result;end if;
 if p_outcome is null or p_outcome not in('won','lost','fled','abandoned') then raise exception 'Exploração: resultado inválido.';end if;
 select * into d from public.wild_drop_state where owner_id=p_user for update;
 if p_outcome='won' then
  select tamer_xp into before_xp from public.player_profiles where id=p_user;
  earned:=public.award_pipamon_xp('wild:'||p_match,p_user,p_match,'wild',case when r.zone='park-clearing' then 30 when r.model_id='raio' then 30 else 20 end);
  select tamer_xp-before_xp into tamer from public.player_profiles where id=p_user;
  if not d.intro_claimed or d.misses>=7 or r.drop_roll<.25 then
   tail:=public.grant_summon_tail(p_user,r.model_id,'drop','wild:'||p_match);
   update public.wild_drop_state set intro_claimed=true,misses=0 where owner_id=p_user;
  else update public.wild_drop_state set misses=misses+1 where owner_id=p_user;end if;
 end if;
 answer:=jsonb_build_object('status',p_outcome,'pipamonXp',earned,'tamerXp',tamer,'tailId',tail,'modelId',r.model_id,'zone',r.zone,'firstTail',tail is not null and not d.intro_claimed);
 update public.wild_runs set status=p_outcome,result=answer,settled_at=now() where match_id=p_match;
 return answer;
end $$;
create function public.player_abandon_wild(p_match uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();answer jsonb;
begin
 if uid is null or not exists(select 1 from public.wild_runs where match_id=p_match and owner_id=uid) then raise exception 'Exploração: encontro inexistente.';end if;
 answer:=public.settle_wild_run(uid,p_match,'abandoned');
 perform public.release_player_match(uid,p_match);return answer;
end $$;
create function public.player_wild(p_match uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();r public.wild_runs;answer jsonb;
begin
 if uid is null then raise exception 'Exploração: entre na conta.';end if;
 if p_match is not null then select * into r from public.wild_runs where match_id=p_match and owner_id=uid;if not found then raise exception 'Exploração: encontro inexistente.';end if;
 else select * into r from public.wild_runs where owner_id=uid and status='pending';end if;
 answer:=jsonb_build_object('pending',case when r.status='pending' then (select jsonb_build_object('matchId',r.match_id,'code',g.room_code,'zone',r.zone) from public.game_matches g where g.id=r.match_id) else null end,'result',r.result,'misses',coalesce((select misses from public.wild_drop_state where owner_id=uid),0));return answer;
end $$;
-- Checkpoints may refer to the two authored park maps, using the same CAS and safety checks.
alter function public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) rename to player_campaign_before_park;
revoke all on function public.player_campaign_before_park(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,authenticated,service_role,pipa_server;
create function public.player_campaign(p_action text default 'read',p_revision bigint default null,p_checkpoint jsonb default null,p_keep uuid[] default null,p_seen uuid[] default null,p_confirmation text default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare answer jsonb;scene text:=p_checkpoint->>'scene';is_park boolean:=scene in('park-trail','park-clearing');
begin
 if is_park and p_action in('save','autosave') then
  if not exists(select 1 from public.player_journeys where owner_id=auth.uid() and phase in('city','complete')) then raise exception 'Exploração: conclua o primeiro voo.';end if;
  answer:=public.player_campaign_before_park(p_action,p_revision,jsonb_set(p_checkpoint,'{scene}','"quintal"'),p_keep,p_seen,p_confirmation);
  if p_action='save' then update public.player_campaign_saves set checkpoint=jsonb_set(checkpoint,'{scene}',to_jsonb(scene)) where owner_id=auth.uid();else update public.player_campaign_saves set autosave_checkpoint=jsonb_set(autosave_checkpoint,'{scene}',to_jsonb(scene)) where owner_id=auth.uid();end if;
  return public.player_campaign_before_park('read');
 end if;
 answer:=public.player_campaign_before_park(p_action,p_revision,p_checkpoint,p_keep,p_seen,p_confirmation);
 if p_action='reset' then
  update public.wild_runs set status='abandoned',settled_at=now(),result=jsonb_build_object('status','abandoned','pipamonXp',0,'tamerXp',0,'tailId',null,'modelId',model_id,'zone',zone,'firstTail',false) where owner_id=auth.uid() and status='pending';
 end if;
 return answer;
end $$;
revoke all on function public.register_wild_run(uuid,uuid,text),public.settle_wild_run(uuid,uuid,text),public.player_wild(uuid),public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.register_wild_run(uuid,uuid,text),public.settle_wild_run(uuid,uuid,text) to pipa_server;
grant execute on function public.player_wild(uuid),public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text) to authenticated;
revoke all on function public.player_abandon_wild(uuid) from public,anon,authenticated,service_role,pipa_server;
grant execute on function public.player_abandon_wild(uuid) to authenticated;
commit;


-- ===== 023_class_constellations.sql =====
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

