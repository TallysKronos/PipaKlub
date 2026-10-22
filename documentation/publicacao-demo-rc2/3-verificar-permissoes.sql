-- Somente leitura de metadados e permissões; não lê dados de jogadores.
begin read only;
select check_name,ok from (values
 ('save_rpc',to_regprocedure('public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text)') is not null),
 ('wild_register_rpc',to_regprocedure('public.register_wild_run(uuid,uuid,text)') is not null),
 ('wild_settle_rpc',to_regprocedure('public.settle_wild_run(uuid,uuid,text)') is not null),
 ('save_authenticated',has_function_privilege('authenticated','public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text)','EXECUTE')),
 ('wild_register_server',has_function_privilege('pipa_server','public.register_wild_run(uuid,uuid,text)','EXECUTE')),
 ('wild_settle_server',has_function_privilege('pipa_server','public.settle_wild_run(uuid,uuid,text)','EXECUTE')),
 ('save_anon_blocked',not has_function_privilege('anon','public.player_campaign(text,bigint,jsonb,uuid[],uuid[],text)','EXECUTE')),
 ('save_tables_private',not has_table_privilege('pipa_server','public.player_campaign_saves','SELECT')),
 ('wild_tables_private',not has_table_privilege('pipa_server','public.wild_runs','SELECT'))
) checks(check_name,ok);
commit;
