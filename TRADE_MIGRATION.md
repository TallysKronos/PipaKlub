# Trocas por convite

Aplicar `supabase/migrations/006_invite_trades.sql` após 001–005 no SQL Editor do Supabase, como proprietário do banco. A migração é transacional e não deve ser reaplicada. Publicar o código somente após aplicá-la. Nenhuma migração ou publicação é executada pelo build.

Na conta, use “Criar convite”, compartilhe o código de 12 caracteres e peça ao amigo autenticado para entrar. Cada participante oferece exatamente uma colecionável e confirma a revisão atual. Alterar uma oferta apaga as duas confirmações. A segunda confirmação transfere ambas as pipas na mesma transação. Repetições após conclusão não transferem novamente. Pipas equipadas fora de partida voltam à básica quando transferidas.

Pipas permanentes e Souls de evento são proibidas. Cada jogador pode participar de uma única negociação aberta. É necessário sair da partida e aguardar a liberação no banco; a negociação bloqueia nova entrada em partida. Os bloqueios de perfil seguem a mesma ordem das capturas. A associação às salas é serializada por um advisory lock transacional global; isso prioriza segurança, com possível limitação de vazão em grande escala. Oito segundos de timeout do serviço de contas limitam a espera.

Salas duram dez minutos, sem prorrogação. Expiração é efetivada no próximo RPC de troca e nunca permite transferência após o prazo. Cancelamento por qualquer participante libera ambos. Histórico das últimas 50 salas encerradas é privado aos participantes; não há acesso direto à tabela nem pelo servidor restrito. O cliente consulta a sala a cada três segundos enquanto a coleção está aberta e pode recuperar a sala ativa após recarregar.

Verificação: executar `node --test trades.test.mjs`, a suíte de testes do package.json e `node build.mjs`. Os testes usam PostgreSQL via PGlite, com as seis migrações reais. Para homologação com PostgreSQL/Supabase, testar duas sessões independentes confirmando ao mesmo tempo, disputa pela última vaga e entrada em partida concorrente; PGlite não substitui esse teste de conexões reais.

Reversão: retornar o código anterior; preservar a tabela como histórico. Não reverter transferências já concluídas automaticamente. Nenhum merge ou deploy é necessário para revisar este PR.
