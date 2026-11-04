# Prólogo: ações visíveis entre as falas

O quarto era recriado a cada checkpoint; Kael e a mãe apareciam em posições finais sem representar como chegaram ali. A apresentação agora preserva o mesmo Room enquanto o andar não muda. Os checkpoints e recibos narrativos continuam no modelo Opening existente; a encenação não concede itens nem altera a progressão.

## Sequência

- A transmissão aparece em um quadro enquanto Kael permanece visível olhando a TV. Os dois Pipamons foram ampliados para serem legíveis; o quadro desaparece suavemente quando a atenção volta para Kael.
- O jogador caminha até a mesa. A interação termina de aproximar Kael da posição de trabalho, sem recriar o quarto.
- A mãe emerge da abertura da escada, caminha pelo espaço livre até o tapete e se vira para Kael. Ele se aproxima e olha para ela. O balão só abre depois da chegada.
- A entrega da rabiola é representada pelo ícone existente passando da mãe para Kael. Ele volta para a mesa, e a ligação ao projeto precede a aparição de Rabbito.
- Após nomear o parceiro, a mãe retorna à escada e desce antes de liberar a caminhada de Kael. Ao interagir com a escada, ele também se aproxima e usa a animação existente de descida antes da troca de andar.
- Na sala, a mãe se desloca da chegada da escada para o espaço de conversa. Ao sair pela porta, Kael chega à rua sem exigir uma segunda confirmação de saída. Saves antigos no passo final ainda oferecem o botão de continuar.

## Movimento e controle

`opening_staging.gd` contém a encenação e usa tempo de frame, sem Tween que sobreviva ao personagem. Os percursos de piso contornam o mobiliário; apenas os segmentos explícitos de escada entram no vão. A mãe usa as quatro direções e as duas poses por direção do spritesheet existente, com os pés normalizados. Não foram gerados ciclos novos de caminhada. O recorte da subida/descida revela a cabeça primeiro e mantém a ordenação com os móveis.

Avançar fica bloqueado durante as ações. Pausar suspende deslocamento e TV. As falas são paginadas depois que o balão visível recebeu seu tamanho, evitando a coluna estreita observada na primeira captura. Itens e nascimentos continuam sendo confirmados pelas funções anteriores de campanha, sem duplicar recompensas ao repetir a apresentação.

## Conferência realizada

Abertura e renderização nativa 1280×720 com estado fictício em memória. Capturas de entrada, saída, TV, conversa, nascimento e chegada à sala em `overworld/bairro-inicial-v2/prologo/`; GIFs de entrada e saída montados dos frames nativos. O capturador não avança a campanha pelo modelo, não cria slots e não grava saves. Checagem de referências sem erros; os avisos anteriores de imports órfãos e recurso de fallback permanecem.

Não foram executados testes automatizados ou uma nova jornada completa com salvamento. Caminhada com controle físico, retomar no meio de cada ação e falhas de disco continuam sem validação funcional nesta revisão. Alterações estão locais para revisão, sem novo envio ao Git ou publicação.
