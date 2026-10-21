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
