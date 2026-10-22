-- Somente estrutura e permissões; não consulta perfis, coleções ou recibos.
select
 to_regclass('public.workshop_jobs') is not null as workshop_jobs,
 to_regclass('public.workshop_requests') is not null as workshop_requests,
 to_regprocedure('public.player_workshop(text,uuid,uuid,text,integer,jsonb,uuid)') is not null as workshop_rpc;

select
 has_function_privilege('authenticated','public.player_workshop(text,uuid,uuid,text,integer,jsonb,uuid)','execute') as authenticated_workshop,
 not has_function_privilege('anon','public.player_workshop(text,uuid,uuid,text,integer,jsonb,uuid)','execute') as anon_blocked,
 not has_function_privilege('authenticated','public.workshop_result(uuid)','execute') as internal_result_blocked,
 not has_function_privilege('authenticated','public.player_summon(text,uuid,uuid,smallint[],uuid,uuid,text)','execute') as constellation_retired,
 not has_table_privilege('authenticated','public.workshop_jobs','select,insert,update,delete') as jobs_protected,
 not has_table_privilege('authenticated','public.workshop_requests','select,insert,update,delete') as receipts_protected;
