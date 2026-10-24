select count(*) as perfis from public.player_profiles;
select count(*) as parceiros from public.player_kites;
select status,count(*) as montagens from public.workshop_jobs group by status order by status;
select to_regclass('public.workshop_v3_runs') as checkpoints,
 to_regclass('public.workshop_v3_receipts') as recibos;
select column_name,column_default from information_schema.columns
 where table_schema='public' and table_name='player_kites' and column_name in('craft_bonus','soul_variant','craft_details');
select has_function_privilege('pipa_server','public.server_workshop_v3(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb)','execute') as servidor_permitido,
 not has_function_privilege('authenticated','public.server_workshop_v3(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb)','execute') as cliente_bloqueado,
 not has_function_privilege('anon','public.server_workshop_v3(uuid,text,uuid,uuid,text,bigint,uuid,jsonb,jsonb)','execute') as anonimo_bloqueado,
 not has_table_privilege('pipa_server','public.workshop_v3_runs','update') as sem_escrita_direta;
