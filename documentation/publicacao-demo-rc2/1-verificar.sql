-- Publicação demo-rc.2 · passo 1 e 3: somente leitura de metadados (não lê dados de jogadores).
-- Rode antes das migrações (esperado: 017/018 = true; 019–023 = false) e depois (tudo true).
begin read only;
select
 to_regclass('public.player_openings') is not null                                  as m017_abertura,
 to_regprocedure('public.player_opening(text,integer,text)') is not null             as m017_rpc_abertura,
 not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='ensure_player' and pg_get_functiondef(p.oid) ilike '%player_kites%') as m018_cadastro_sem_kit_antigo,
 to_regclass('public.player_campaign_saves') is not null                            as m019_saves,
 exists(select 1 from information_schema.columns where table_schema='public' and table_name='player_campaign_saves' and column_name='autosave_enabled') as m020_autosave,
 exists(select 1 from information_schema.columns where table_schema='public' and table_name='player_profiles' and column_name='tamer_xp') as m021_classes,
 to_regclass('public.wild_runs') is not null                                        as m022_selvagens,
 to_regclass('public.pipamon_class_nodes') is not null                              as m023_constelacoes;
commit;
