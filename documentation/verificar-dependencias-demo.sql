-- Somente leitura de metadados. Não lê contas, inventários, senhas ou dados de jogadores.
begin read only;
select
 to_regprocedure('public.player_journey(text,text,integer)') is not null as primeiro_voo_instalado,
 to_regprocedure('public.player_opening(text,integer,text)') is not null as abertura_instalada,
 to_regprocedure('public.pipamon_level(integer)') is not null as leveling_instalado,
 to_regclass('public.player_journeys') is not null as tabela_primeiro_voo,
 to_regclass('public.player_openings') is not null as tabela_abertura;
commit;
