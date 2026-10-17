# Invocação de Pipamon

Aplicar `007_summoning.sql` após 001–006, depois `008_summon_catalog.sql`, como proprietário do banco antes de publicar o novo código. As migrações não são reaplicáveis. Produção não é modificada pelo build nem pelo ambiente local.

Em Minha conta, visitar o invocador Sr. Assis e escolher “Invocar Pipamon”. O catálogo mostra somente os avistados: um ícone com a arte real da rabiola indica disponibilidade e um cadeado indica bloqueio. Escolher o card abre a preparação com o Pipamon de um lado e as rabiolas do outro. Selecionar uma rabiola compatível e clicar “Usar rabiola → Ascendente” inicia a sessão mágica. Navegar ou selecionar não consome itens. O uso é imediato e transacional: a rabiola deixa de estar disponível antes de começar o desenho. Existem três tentativas na mesma sessão. O feitiço é uma constelação de nove pontos com sequência própria de cada modelo. Estrelas intermediárias cruzadas são incluídas automaticamente, inclusive em movimentos rápidos de mouse/dedo. O teclado permite selecionar estrelas com Tab/Espaço e enviar com “Lançar feitiço”. É possível consultar o feitiço durante o ritual.

Acertar cria exatamente uma instância do modelo na coleção do usuário, na mesma transação da conclusão. Pipas comuns são colecionáveis; Souls de evento preservam a vinculação permanente e a concessão registrada, sem possibilidade de obter várias cópias permanentes do mesmo modelo. Invocar Carcará cria uma cópia colecionável e preserva a básica permanente inicial. As 33 artes de rabiolas do catálogo foram integradas; a rabiola de Nozinho continua como item associado a um companheiro, sem torná-lo equipável ou invocável. Feitiços de novos modelos devem ser cadastrados em `summon_spells`.

## Avistamentos e rabiolas alternativas

Os avistamentos são privados por jogador e persistidos em `player_pipamon_sightings`. Incluem Pipamon possuídos, encontrados equipados em partidas autenticadas e consultados nos detalhes da Pipa Dex. Consultar um registro público marca o avistamento; isso não concede Pipamon ou rabiolas. O banco verifica o avistamento também ao iniciar, sem depender do filtro da interface.

`summon_recipes` permite que um Pipamon aceite a rabiola de outro e gere uma forma diferente: `target_model_id` escolhe o feitiço, `tail_model_id` identifica o consumível aceito e `result_model_id` determina a forma entregue. **A tabela começa vazia: nenhuma combinação alternativa está habilitada.** Uma regra administrativa futura deve referenciar modelos cadastrados. O alvo e o resultado são fixados na sessão ao iniciar; alterar a regra durante o ritual não muda a recompensa. Receitas não são aceitas do navegador. Combinações inválidas são rejeitadas antes do consumo.

Depois de três erros, a rabiola permanece consumida e o ritual falha. Sair do NPC, fechar a coleção ou sair da página durante o processo encerra o ritual e deixa uma rabiola danificada, sem uso além de descarte. Não existe retomada em outra sessão, reembolso ou reinício das tentativas. Uma conexão silenciosamente perdida é encerrada após 45 segundos sem contato; o cliente mantém a sessão enquanto o ritual está aberto. O encerramento por expiração é efetivado no próximo RPC do usuário. Não há exclusão física ao descartar: o item muda para `discarded`, preservando a auditoria.

Os bloqueios do perfil serializam consumo, tentativas e concessões. Um índice limita um ritual ativo por jogador. Um token aleatório de sessão e as permissões derivadas de auth.uid() impedem retomada em outra aba/usuário. Cada tentativa tem um UUID idempotente: ao perder a resposta, o cliente só permite reenviar a mesma tentativa, sem gastar outra. O padrão esperado é verificado no PostgreSQL, nunca por uma alegação de sucesso enviada pelo cliente.

## Origem das rabiolas

Há um ponto de entrada administrativo `grant_summon_tail(p_user,p_model,p_source,p_reference)`, com origens `drop`, `purchase` e `event`. Uma referência única por usuário e origem impede concessões duplicadas em reentregas. Trocar o modelo de uma referência já usada é rejeitado. O papel de servidor restrito, jogadores e service_role não podem executar essa função. A integração confiável que processar drops, recibos de compra ou eventos deve chamá-la como proprietário/role administrativo especificamente autorizado. Nunca aceitar uma declaração de compra do navegador.

**Não foram inventadas moeda, preços, porcentagens de drop ou integração de pagamentos.** As origens estão prontas no inventário e no banco; as regras econômicas e a conexão com loja/drop reais ainda precisam ser definidas. No ambiente local, Ana e Beto recebem cinco rabiolas fictícias, com as três origens, por concessões idempotentes apenas no inicializador de testes.

## Teste e reversão

Executar `node --test summon.test.mjs` e a suíte completa. O teste aplica as oito migrações reais em PGlite e cobre consumo imediato, tentativas, repetição, sessões, propriedade, expiração, dano, descarte, exclusividade, Souls, avistamentos, compatibilidade e privilégios. Uma receita alternativa é cadastrada apenas no banco efêmero do teste para verificar a forma resultante. PGlite não substitui homologação de concorrência entre conexões PostgreSQL independentes.

O ambiente local instala as migrações 007 e 008 se ausentes, preservando seus dados anteriores. Inclui avistamentos fictícios com e sem rabiolas para testar os cadeados. O adaptador fictício não é importado pelo servidor de produção. Para reversão, retornar o código anterior e preservar as tabelas como auditoria; não apagar colecionáveis concedidas nem reembolsar rabiolas automaticamente.
