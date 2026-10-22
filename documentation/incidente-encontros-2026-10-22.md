# Falha ao carregar encontros selvagens · 2026-10-22

## Confirmado

A produção respondia HTTP 200 em `/health`, identificando-se como `demo-rc.2`. Os logs do Render registravam HTTP 503 em `createRoom`, na chamada de registro de encontro selvagem. A mensagem pública era “O banco do jogo não respondeu”.

O fluxo de contas já chamava `register_wild_run` e `settle_wild_run`, mas `src/game-database.js` não incluía essas duas operações na allowlist. O próprio adaptador lançava `Database operation is not allowed.` antes de consultar o Postgres. O tratamento de erro em `src/accounts.js` convertia isso na mensagem genérica acima. Portanto, esse 503 não comprova timeout ou indisponibilidade do banco.

## Correção de código

Adicionar somente as duas funções previstas na migração 022 à allowlist, com seus parâmetros vinculados. Não conceder SQL arbitrário nem acesso direto a tabelas.

O teste de regressão liga `createAccounts.registerWild/settleWild` ao adaptador real `createGameDatabase`, com transporte SQL simulado. Ele verifica as duas consultas, os parâmetros e a rejeição de outra operação não permitida. Os testes anteriores dos encontros usavam transportes diferentes e não detectaram essa omissão.

## Dependência de produção confirmada

Os logs também registraram uma rejeição de RPC pelo serviço de API com código `PGRST202`. A consulta somente leitura `publicacao-demo-rc2/1-verificar.sql` foi executada no projeto de produção em 2026-10-22 e retornou 017/018 presentes, mas os cinco indicadores de 019–023 ausentes: saves, autosave, XP/classes, encontros e constelações. Portanto, publicar só a correção do adaptador não resolve o salvamento nem cria as funções de encontros.

O pacote exato `publicacao-demo-rc2/2-migracoes-019-023.sql` (SHA-256 `139efddd8cab25af80930637bdd9897fb41f9af411b64b328d3db751d982aeae`) foi aplicado em um banco local isolado com schema até 018 e conta/coleção de teste. Passaram: pacote igual às fontes das cinco migrações; perfil, coleção e carteira preservados; oito indicadores presentes depois da atualização; permissão das duas funções de encontros para `pipa_server` e do save para `authenticated`. Evidência em `art/ui-reviews/demo-dependencies-2026-10-22/`.

A publicação da demo-rc.2 exige confirmar o schema antes de subir o servidor. Consulte `publicacao-demo-rc2/README.md`. O arquivo `publicacao-demo-rc2/1-verificar.sql` faz somente leitura de metadados. Se faltar alguma etapa, revisar e aplicar apenas as migrações necessárias, na ordem, com a autorização de produção correspondente; não executar cegamente o pacote inteiro em um schema parcialmente migrado.

Após autorização explícita do usuário para o pacote 019–023, o arquivo validado foi executado no SQL Editor de produção. A conferência posterior retornou os oito indicadores presentes e `3-verificar-permissoes.sql` confirmou as nove verificações: RPCs existentes, execução pelos papéis apropriados e bloqueio de leitura direta das tabelas pelo papel do servidor.

Validação funcional no cliente publicado: save manual confirmado e relido do servidor; autosave do slot 0 persistido, mantendo o slot manual; encontro disparado pelo movimento normal no capim, batalha iniciada e encerrada com retorno ao parque. O encontro terminou sem vitória, portanto o teste não comprova concessão de recompensas por vitória. O parceiro foi preservado. Não houve reset de campanha, descarte ou transferência de parceiros.

As capturas da sessão de produção permanecem somente no ambiente local, em pasta ignorada pelo Git. Este registro técnico não publica perfil, coleção, horários de save ou imagens da conta.

Testes locais aprovados e `/health` respondendo não garantem, sozinhos, compatibilidade do schema publicado. A verificação das dependências deve preceder futuros deploys, e mudanças de banco exigem validação funcional após a aplicação.
