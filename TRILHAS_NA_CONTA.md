# PIP-5 — Progresso das Trilhas na conta

## Comportamento

Ao entrar, carrega a cópia da conta e importa uma vez o progresso de visitante deste aparelho. Importações somam moedas, vitórias e derrotas; preservam o maior número de estrelas por etapa e maestria; unem as rabiolas já registradas; preservam o maior contador de derrotas por etapa. Aparelhos diferentes podem importar seus próprios progressos. Cópias manuais do mesmo armazenamento fora do protocolo não são detectáveis como uma mesma origem.

Cada partida tem um UUID imutável. O navegador mantém uma fila separada por conta e por operação antes de exibir o progresso otimista. Ao voltar a conexão, reenvia os mesmos IDs. A resposta canônica substitui a previsão local. Reabrir, repetir uma resposta perdida ou ter duas abas não repete o pagamento no banco. Resultados de duas partidas diferentes continuam somando, inclusive entre aparelhos. A troca de conta descarta respostas atrasadas da tela atual e não mistura os caches.

O visitante continua jogando localmente. A transferência escreve a importação na fila antes de limpar o antigo save; usa Web Locks quando disponível para coordenar abas do mesmo aparelho. Armazenamento bloqueado não apaga o save do visitante. O cache e a fila não contêm tokens de autenticação. Desconexão, falha de migração ou armazenamento são informados no painel com botão para tentar novamente.

## Migração e publicação

1. Aplicar `supabase/migrations/009_trails_progress.sql` no Supabase, após 001–008, usando o mecanismo de migrações existente.
2. Conferir a função `player_trails(text,uuid,jsonb)` com permissão apenas para `authenticated`. As três tabelas têm RLS e não dão acesso direto ao cliente. O usuário restrito `pipa_server` não recebe privilégios novos.
3. Publicar o servidor e o frontend após a migração. Nenhuma variável secreta nova é necessária.
4. Entrar em dois aparelhos, concluir etapas, atualizar e conferir estrelas, saldo, maestria e itens. Desligar a rede, concluir outra partida, reconectar e conferir um único pagamento.

A migração foi aplicada apenas ao banco local isolado nesta implementação. Não houve deploy em produção. `scripts/local-trades.mjs` detecta e aplica 009 no banco da demonstração. A migração de produção é executada uma única vez pelo controle de versões; não reaplicar o arquivo bruto sobre tabelas existentes.

Rollback: voltar o aplicativo anterior sem apagar tabelas ou operações. Manter os dados da conta e a fila; remover a migração destruiria o histórico de deduplicação. O aplicativo anterior lê o antigo save visitante, não o novo cache de conta; a evolução da conta volta a aparecer ao restaurar esta versão.

## Limite de confiança

As Trilhas continuam sendo um modo offline. O servidor calcula os valores de recompensa e exige desbloqueio sequencial para novos resultados, mas não comprova a execução de uma partida offline nem a autenticidade do save antigo. O log preserva origem e payload. Moedas e itens deste modo não devem financiar compras compartilhadas, ranking ou concessões de inventário sem uma fonte de resultados verificável. Esta mudança não concede rabiolas em `summon_tails` nem pipas em `player_kites`; preserva os registros de drops das Trilhas, como antes.

## Validação e revisão

85 testes passaram: inclui PostgreSQL real em PGlite, permissões, isolamento, paridade de pagamentos das 15 etapas, drops únicos, importação repetida, resultados simultâneos, resposta perdida, recarga, troca de conta, duas abas, armazenamento indisponível e validação HTTP. Builds de servidor/Pages e validação do artefato passaram. Interface conferida com Ana no ambiente local.

A branch parte da Escola do Sr. Assis (PR #3), que por sua vez depende dos menus (PR #2). Revisar sem merge/deploy automático.
