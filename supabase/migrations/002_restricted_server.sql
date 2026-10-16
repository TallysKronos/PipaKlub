-- Password and LOGIN are intentionally set by the owner in Database > Roles.
-- This file contains no credential and leaves the new role unable to log in.
begin;
create role pipa_server nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls connection limit 4;
revoke create on schema public from public;
grant connect on database postgres to pipa_server;
grant usage on schema public to pipa_server;
revoke all on public.kite_models,public.player_profiles,public.player_kites,public.game_matches,public.match_players,public.cut_events from pipa_server;
grant execute on function public.reserve_player_match(uuid,uuid,text,text),public.release_player_match(uuid,uuid),public.settle_player_cut(text,uuid,uuid,uuid,uuid),public.finish_player_match(uuid) to pipa_server;
alter role pipa_server set statement_timeout='8s';
alter role pipa_server set idle_in_transaction_session_timeout='10s';
alter role pipa_server set search_path='';
commit;
