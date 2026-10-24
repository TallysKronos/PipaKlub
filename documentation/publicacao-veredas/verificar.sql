select
 to_regprocedure('public.register_wild_before_guardian(uuid,uuid,text)') is not null as migration_028_installed,
 (select count(*) from public.player_profiles) as profiles,
 (select count(*) from public.player_kites) as partners,
 (select count(*) from public.workshop_jobs) as workshop_jobs,
 (select pg_get_constraintdef(oid) from pg_constraint where conrelid='public.wild_runs'::regclass and conname='wild_runs_zone_check') as allowed_zones,
 (select pg_get_constraintdef(oid) from pg_constraint where conrelid='public.wild_runs'::regclass and conname='wild_runs_enemy_level_check') as enemy_levels;
select
 has_function_privilege('pipa_server','public.register_wild_run(uuid,uuid,text)','execute') as server_register,
 has_function_privilege('pipa_server','public.settle_wild_run(uuid,uuid,text)','execute') as server_settle,
 not has_function_privilege('authenticated','public.settle_wild_run(uuid,uuid,text)','execute') as player_cannot_settle,
 not has_function_privilege('anon','public.settle_wild_run(uuid,uuid,text)','execute') as anon_cannot_settle,
 has_function_privilege('authenticated','public.player_wild(uuid)','execute') as player_read,
 not has_function_privilege('anon','public.player_wild(uuid)','execute') as anon_blocked,
 not has_function_privilege('pipa_server','public.register_wild_before_guardian(uuid,uuid,text)','execute') as private_wrapper,
 not has_table_privilege('authenticated','public.wild_runs','insert,update,delete') as protected_results;
