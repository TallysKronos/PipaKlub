# Encenação do tutorial · professor até nascimento

Integração local. `tutorial_staging.gd` coordena apresentação; Journey permanece responsável pelas escolhas únicas, checkpoints, bônus e nascimentos. Não houve alteração de schema ou regras de recompensa.

## Ações entre as telas

- Ao entrar no ateliê, Kael atravessa a soleira. Ao sair, chega à porta antes da troca de cenário.
- Interagir com o professor aproxima Kael pelo piso livre, vira o personagem para ele e abre o diálogo existente. O caminho usa os obstáculos reais da sala e não atravessa móveis.
- A conversa apresenta o treino. Kael segue até a saída antes da mudança para a arena.
- As cinco lições compartilham a mesma arena e os mesmos elementos visuais. O exercício é reiniciado como antes, mas as posições renderizadas convergem para as novas durante uma breve preparação. Comandos pressionados não atravessam a troca. O Avançar pertence ao balão do professor.
- Depois da quinta lição, as pipas são recolhidas visualmente. O retorno ao ateliê mostra Kael saindo da entrada e chegando ao professor antes da escolha de rabiola.
- Após a escolha confirmada, a entrega da rabiola aparece entre professor e Kael. Ele caminha até a bancada antes de a montagem abrir. Montagens de rabiolas do inventário usam o percurso, sem fingir nova entrega do professor.
- Cada etapa da bancada tem um breve intervalo de preparação, bloqueando entradas e mantendo esse tempo fora da avaliação da montagem.
- O nascimento aparece apenas depois da confirmação por Journey. Um espaço limitado contém a animação do parceiro e o bônus efetivamente obtido; a indicação de variante depende do sorteio salvo, não da nota da montagem.
- O jogador decide quando conhecer o parceiro. O retorno à sala usa o novo companheiro equipado e encerra o tutorial com a orientação do professor para explorar.

## Retomada e limites

Os trechos de encenação são locais e não criam flags persistentes novas. Sair pelo menu/carregar retoma o checkpoint já confirmado; uma apresentação interrompida pode ser abreviada na retomada, sem repetir a concessão de itens. Saves existentes continuam válidos. Pause manual e perda de foco interrompem deslocamentos encenados. A arte atual do professor é estática: ele permanece na posição de conversa; não foi inventado um ciclo de caminhada para esse sprite.

As transições entre interior e arena ainda são cortes com a transição visual compartilhada, após as ações de chegada/saída; não representam um novo terraço explorável ligado fisicamente ao mapa.

## Conferência

Capturas e sequências nativas 1280×720 de aproximação, conversa, transição de lição, recolha, entrega, percurso até a bancada e nascimento. Fixtures em memória, sem chamar operações Journey, criar slots ou conceder parceiros. Checagem estática das referências do projeto.

Sem suíte automatizada nem jornada completa com salvamento. Não validado com controle físico, falha de disco ou encerramento em cada intervalo. A aprovação visual e funcional do usuário continua necessária. Alterações locais, sem push ou publicação.
