# Céu do Dia — PIP-9

O menu abre um desafio individual online, disponível somente a contas autenticadas. O jogador enfrenta um bot de nível 4 e precisa vencer duas rodadas. A primeira vitória de cada dia concede 25 moedas; novas partidas continuam disponíveis sem novo bônus. Derrota, empate por tempo ou abandono antes de vencer não concedem moedas. A coleção fica protegida, sem captura nem XP contra bot.

O calendário usa dias UTC, renovando às 00:00 UTC (21h de Brasília). A condição é calculada pelo número de dias desde 1970-01-01, módulo quatro: ventania, linha encerada, garoa, neblina. Todos recebem a mesma condição. A data da solicitação fica congelada na sala, inclusive se a partida cruzar meia-noite. Uma vitória atrasada pertence ao dia de início, sem consumir o bônus do novo dia.

* Ventania: vento lateral com amplitude 36, em vez de 12.
* Linha encerada: desgaste dos acertos multiplicado por 1,25 para ambos.
* Garoa: recuperação de energia multiplicada por 0,7 para ambos.
* Neblina: cenário encoberto; pipas, linhas, miras e avisos são desenhados depois e permanecem legíveis.

As regras de movimento são compartilhadas com a previsão do cliente. O clima não altera partidas comuns, treino ou Trilhas. Efeitos de vento/garoa respeitam modo leve e movimento reduzido.

## Migração e publicação manual

Aplicar `supabase/migrations/011_daily_challenge.sql` após 001–010, no SQL Editor do projeto correto, antes de publicar o servidor atualizado. O script é transacional e deve ser aplicado uma vez. Ele cria `daily_challenge_rewards`, a consulta autenticada `player_daily()` e a função restrita `settle_daily_challenge(uuid,uuid,date)`.

Não é necessário adicionar segredo ou variável de ambiente. O papel existente `pipa_server` recebe somente EXECUTE na nova função de liquidação; usuários, anon e service_role não podem executá-la. A inicialização verifica essa permissão. Não há acesso direto às tabelas. O ambiente local aplica 011 apenas ao PGlite em `.local/trade-demo`; não conecta ao Supabase real.

Nenhuma migração de produção, merge ou deploy é executado por esta implementação. O PR depende da branch `feature/visuais-de-linha`, que contém a carteira e a migração 010; a carteira é criada pela 009.

## Confirmação e concorrência

Somente `/api/daily` cria uma sala marcada pelo servidor. Campos enviados por clientes para clima, data, vitória, rodadas ou prêmio são ignorados. Outros jogadores não podem ingressar nessa sala. `/account/daily` é uma consulta e não aceita reivindicação de prêmio.

O motor registra o vencedor ao atingir a segunda rodada. A fila SQLite persiste a vitória imediatamente, antes do intervalo final; desconectar depois de vencer preserva a recompensa. Repetições têm identificador fixo por partida. A consulta de resultados recupera a vitória de uma sala persistida após reinício, inclusive sem WebSocket. A liquidação precede a liberação/finalização da partida e repete falhas com espera crescente.

O PostgreSQL valida participação e modalidade casual. A data precisa corresponder à criação da partida ou ao dia anterior, permitindo uma autenticação iniciada antes de meia-noite e concluída depois. A data é fornecida exclusivamente pelo servidor confiável. A unicidade `(owner_id, day)` e de `match_id` impede duplicação entre requisições, partidas e abas. O crédito e o recibo são uma transação, usando a mesma trava de carteira das Trilhas e compras de linha. A revisão aumenta para impedir que uma resposta antiga sobrescreva o saldo novo.

A fila sobrevive a reinícios somente quando o disco SQLite é preservado. O plano gratuito do Render usa disco temporário; uma implantação ou perda abrupta do disco pode descartar eventos ainda não enviados. Recibos já gravados no Supabase continuam seguros. A progressão antiga das Trilhas aceita resultados offline e não passa a ser verificada por esta mudança; as moedas continuam sendo destinadas a cosméticos.

## Verificação

`node build.mjs`, `node build-pages.mjs`, `node scripts/validate-artifact.mjs` e `npm test` (ou o comando `node --test` listado em package.json). Os testes incluem calendário UTC, paridade JS/SQL, efeitos e previsão, vencedor privado, permissões/RLS, crédito único com chamadas concorrentes, compra após bônus, repetição após falha/reinício, derrota sem prêmio, tentativa de forjar resultado, visitantes bloqueados e integração da tela real.

Para experimentar: `node scripts/local-trades.mjs`, depois abrir `http://127.0.0.1:5194/local/ana`, escolher **Céu do dia** e **Enfrentar o céu**. Beto está em `http://localhost:5194/local/beto`. Não há alteração de relógio ou botão de vitória na interface de produção.
