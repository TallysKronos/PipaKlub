import fs from 'node:fs';
const unwrap=path=>fs.readFileSync(path,'utf8').trim().replace(/^begin;\s*/i,'').replace(/\s*commit;$/i,'');
const sql=`-- Pacote de produção: somente as migrações 017 e 018 já versionadas.
-- Mantém as coleções existentes; elas recebem o marcador legacy da abertura.
-- Contas novas passam a receber o parceiro pela história, conforme as regras da demo.
-- Nenhuma senha, hash, token ou chave é lida ou alterada.
begin;
set local lock_timeout='3s';
set local statement_timeout='15s';
do $preflight$
begin
 if to_regprocedure('public.player_journey(text,text,integer)') is null or to_regprocedure('public.pipamon_level(integer)') is null then
  raise exception 'Instale as dependências 015 e 016 antes deste pacote.';
 end if;
 if to_regclass('public.player_openings') is not null or to_regprocedure('public.player_opening(text,integer,text)') is not null then
  raise exception 'A abertura já está parcial ou integralmente instalada; não reaplicar sem revisão.';
 end if;
end $preflight$;

${unwrap('supabase/migrations/017_kael_opening.sql')}

${unwrap('supabase/migrations/018_story_first_collection.sql')}

notify pgrst, 'reload schema';
commit;
`;
fs.mkdirSync('output/sql',{recursive:true});fs.writeFileSync('output/sql/instalar-abertura-demo-017-018.sql',sql);console.log('Prepared output/sql/instalar-abertura-demo-017-018.sql');
