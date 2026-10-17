# Invocação de Pipamon

Aplicar `007_summoning.sql` após 001–006 como proprietário do banco, antes de publicar o novo código. A migração não é reaplicável. Produção não é modificada pelo build nem pelo ambiente local.

Em Minha conta, visitar o invocador Sr. Assis. Selecionar uma rabiola, conferir o feitiço e o aviso e usar “Usar rabiola e iniciar ritual”. O uso é imediato e transacional: a rabiola deixa de estar disponível antes de começar o desenho. Existem três tentativas na mesma sessão. O feitiço é uma constelação de nove pontos com sequência própria de cada modelo. Estrelas intermediárias cruzadas são incluídas automaticamente, inclusive em movimentos rápidos de mouse/dedo. O teclado permite selecionar estrelas com Tab/Espaço e enviar com “Lançar feitiço”. É possível consultar o feitiço durante o ritual.

Acertar cria exatamente uma instância do modelo na coleção do usuário, na mesma transação da conclusão. Pipas comuns são colecionáveis; Souls de evento preservam a vinculação permanente e a concessão registrada, sem possibilidade de obter várias cópias permanentes do mesmo modelo. O modelo básico inicial não possui rabiola. Feitiços de novos modelos devem ser cadastrados em `summon_spells`.

Depois de três erros, a rabiola permanece consumida e o ritual falha. Sair do NPC, fechar a coleção ou sair da página durante o processo encerra o ritual e deixa uma rabiola danificada, sem uso além de descarte. Não existe retomada em outra sessão, reembolso ou reinício das tentativas. Uma conexão silenciosamente perdida é encerrada após 45 segundos sem contato; o cliente mantém a sessão enquanto o ritual está aberto. O encerramento por expiração é efetivado no próximo RPC do usuário. Não há exclusão física ao descartar: o item muda para `discarded`, preservando a auditoria.

Os bloqueios do perfil serializam consumo, tentativas e concessões. Um índice limita um ritual ativo por jogador. Um token aleatório de sessão e as permissões derivadas de auth.uid() impedem retomada em outra aba/usuário. Cada tentativa tem um UUID idempotente: ao perder a resposta, o cliente só permite reenviar a mesma tentativa, sem gastar outra. O padrão esperado é verificado no PostgreSQL, nunca por uma alegação de sucesso enviada pelo cliente.

## Origem das rabiolas

Há um ponto de entrada administrativo `grant_summon_tail(p_user,p_model,p_source,p_reference)`, com origens `drop`, `purchase` e `event`. Uma referência única por usuário e origem impede concessões duplicadas em reentregas. Trocar o modelo de uma referência já usada é rejeitado. O papel de servidor restrito, jogadores e service_role não podem executar essa função. A integração confiável que processar drops, recibos de compra ou eventos deve chamá-la como proprietário/role administrativo especificamente autorizado. Nunca aceitar uma declaração de compra do navegador.

**Não foram inventadas moeda, preços, porcentagens de drop ou integração de pagamentos.** As origens estão prontas no inventário e no banco; as regras econômicas e a conexão com loja/drop reais ainda precisam ser definidas. No ambiente local, Ana e Beto recebem cinco rabiolas fictícias, com as três origens, por concessões idempotentes apenas no inicializador de testes.

## Teste e reversão

Executar `node --test summon.test.mjs` e a suíte completa. O teste aplica as sete migrações reais em PGlite e cobre consumo imediato, tentativas, repetição, sessões, propriedade, expiração, dano, descarte, exclusividade, Souls e privilégios. PGlite não substitui homologação de concorrência entre conexões PostgreSQL independentes.

O ambiente local instala a migração 007 se ausente, preservando seus dados anteriores. O adaptador fictício não é importado pelo servidor de produção. Para reversão, retornar o código anterior e preservar as quatro tabelas como auditoria; não apagar colecionáveis concedidas nem reembolsar rabiolas automaticamente.
