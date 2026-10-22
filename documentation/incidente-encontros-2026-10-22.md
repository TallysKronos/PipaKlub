# Falha ao carregar encontros selvagens · 2026-10-22

## Confirmado

A produção respondia HTTP 200 em `/health`, identificando-se como `demo-rc.2`. Os logs do Render registravam HTTP 503 em `createRoom`, na chamada de registro de encontro selvagem. A mensagem pública era “O banco do jogo não respondeu”.

O fluxo de contas já chamava `register_wild_run` e `settle_wild_run`, mas `src/game-database.js` não incluía essas duas operações na allowlist. O próprio adaptador lançava `Database operation is not allowed.` antes de consultar o Postgres. O tratamento de erro em `src/accounts.js` convertia isso na mensagem genérica acima. Portanto, esse 503 não comprova timeout ou indisponibilidade do banco.

## Correção de código

Adicionar somente as duas funções previstas na migração 022 à allowlist, com seus parâmetros vinculados. Não conceder SQL arbitrário nem acesso direto a tabelas.

O teste de regressão liga `createAccounts.registerWild/settleWild` ao adaptador real `createGameDatabase`, com transporte SQL simulado. Ele verifica as duas consultas, os parâmetros e a rejeição de outra operação não permitida. Os testes anteriores dos encontros usavam transportes diferentes e não detectaram essa omissão.

## Dependência de produção ainda não confirmada

Os logs também registraram uma rejeição de RPC pelo serviço de API com código `PGRST202`. Isso indica outra chamada não localizada no cache de funções; os logs atuais não identificam qual função. Não é evidência suficiente para afirmar que todas as migrações 019–023 estão ausentes.

A publicação da demo-rc.2 exige confirmar o schema antes de subir o servidor. Consulte `publicacao-demo-rc2/README.md`. O arquivo `publicacao-demo-rc2/1-verificar.sql` faz somente leitura de metadados. Se faltar alguma etapa, revisar e aplicar apenas as migrações necessárias, na ordem, com a autorização de produção correspondente; não executar cegamente o pacote inteiro em um schema parcialmente migrado.

Nenhuma alteração de banco de produção foi realizada nesta investigação. A correção do adaptador não instala migrações. Testes locais aprovados e `/health` respondendo não garantem, sozinhos, a compatibilidade do schema publicado. A confirmação final exige repetir o encontro em produção depois da correção e da verificação das dependências.
