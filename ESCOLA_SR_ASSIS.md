# PIP-7 — Escola do Sr. Assis

Entrada pelo menu Escola do Sr. Assis ou ao terminar a apresentação inicial. A primeira visita oferece um tour por conta, Trilhas, partida rápida, treino, Dex e escola. Pode pular, voltar e repetir o tour.

Seis lições independentes: cruzamento, ponta segura da linha, centro dourado, crítico em movimento, esquiva perfeita e recuperação de energia. Usam o motor real de combate, com alvo controlado e marcador de posição. Próxima lição exige sucesso observado, não apenas clicar em continuar. Pode repetir ou sair a qualquer momento.

O treino é local e casual, sem recompensas, capturas, consumo de itens ou mudanças na conta. As lições concluídas e a preferência do tour ficam no aparelho. Não há migração de banco. O Kael continua apenas como asset, sem uso no jogo.

## Validação

80 testes passaram. Novos testes concluem as seis lições com entradas normais, rejeitam acertos fora da geometria exigida e esquivas fora de tempo, verificam a saída limpa e preservam o treino livre. Builds de servidor e Pages e validação de ESM passaram. Conferência visual em navegador local.

## Aceite humano pendente

Convidar uma pessoa que nunca jogou, iniciar sem progresso local de escola/tour e observar se ela vence a primeira etapa do Morro sem orientação externa. Não marcar a demanda como concluída antes dessa validação. Os testes automatizados não substituem esse critério.

## Revisão

Esta branch parte de feature/menus-do-clube (PR #2); revisar a escola após os menus. Nenhum merge ou deploy automático.
