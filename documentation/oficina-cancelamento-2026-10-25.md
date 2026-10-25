# Saída da Oficina — cancelamento explícito

Sair da bancada ou usar Escape abre uma confirmação que pausa a interação. Continuar fecha o aviso e mantém a tentativa. Confirmar cancela no servidor, devolve a rabiola reservada e descarta etapas, tempo e pontuação. A próxima entrada começa pela preparação. A saída durante a escolha de gabarito/rabiola também pede confirmação.

O nascimento já confirmado não é desfeito. Um resultado ainda pendente precisa ser confirmado antes de sair. Falhas de rede ao cancelar mantêm a tela aberta e permitem tentar novamente. A proteção de cancelamento usa uma cota independente dos checkpoints, para não ser bloqueada pelo limite de salvamento identificado anteriormente.

A migração `030_workshop_cancel.sql` acrescenta estado `cancelled` e uma operação restrita de cancelamento. Serializa com os salvamentos pelo perfil, verifica a propriedade e a semente da tentativa, mantém cancelamento idempotente e impede uma aba antiga de cancelar uma tentativa reiniciada. Reutilizar a mesma rabiola inicia progresso vazio e nova semente, validando novamente a receita e o presente do tutorial. O tutorial não recebe outro presente nem é encerrado ao cancelar.

O diário local só é apagado após confirmação do servidor. A semente também identifica o diário, evitando recuperar eventos de uma tentativa anterior ao reusar o mesmo job. Não há mudança no comportamento de fechar o navegador pelo sistema operacional: a confirmação se aplica às saídas dentro do jogo.

Revisão manual local: aviso da bancada, continuar, confirmar saída, reabrir sem opção de retomada. Capturas em `art/ui-reviews/oficina-cancelamento-20261025/`. Builds executados; nenhuma suíte automatizada, conforme preferência do usuário. Migração aplicada apenas ao banco local isolado; produção não alterada.
