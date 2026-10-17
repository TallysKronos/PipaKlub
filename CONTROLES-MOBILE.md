# Controles de ponteiro e tela vertical

- Mouse: apontar movimenta; botão esquerdo mantido ataca; direito usa habilidade para o lado apontado. O clique esquerdo captura o ponteiro até soltar.
- Toque breve: até 300 ms e 14 px de deslocamento máximo, ao soltar gera um ataque por 220 ms para alcançar o próximo envio de comandos.
- Deslize: pelo menos 48 px horizontais em até 650 ms, com deslocamento horizontal maior que 1,5 vez o vertical. Uma habilidade por gesto, na direção do deslize. Não gera ataque ao soltar.
- Arrastar movimenta. Arrastos verticais ou lentos não acionam habilidade. Segundo dedo não substitui o primeiro; cancelamentos não atacam. Abrir menu, perder foco ou trocar de aba limpa os comandos pendentes.
- Em tela vertical, a câmera aproxima e acompanha o jogador horizontalmente, mantendo as coordenadas e regras da arena online. Adversários fora do enquadramento recebem indicadores laterais. O fundo mantém proporções; painéis compactos e gestos substituem os botões grandes de ataque/habilidade. O botão de esquiva continua disponível.

## Validação

Build Worker e Pages, validação do artefato e os 106 testes passaram. Os testes dos eventos reais da página cobrem tap, expiração, deslizes nos dois sentidos, limite de uma habilidade, arrasto vertical, cancelamento, segundo dedo, direção do sprite e conversão de coordenadas da câmera nos limites da arena.

Conferência visual no navegador em 390×740, 320×568 e 844×390, com movimento nas duas direções numa sala online local, sem erros no console. Os gestos foram verificados por testes automatizados; falta confirmar o comportamento em aparelho físico Android/iOS após publicação. A falha do mouse relatada em produção não foi reproduzida no ambiente local. Não houve merge nem deploy.

## Rebicada universal

Cada ataque aceito produz uma rebicada de 340 ms: recuo, inclinação e avanço do sprite, acompanhados de uma onda de tensão e pequenos arcos de movimento. O efeito usa a recarga do ataque e funciona com espaço, clique e toque, em todos os 33 Pipamons, inclusive ao errar. Ataques recusados por falta de energia ou durante esquiva não simulam uma rebicada.

Não altera coordenadas, colisões, dano ou alcance. No modo leve, a linha e o arco principal permanecem; com movimento reduzido, o corpo fica parado e o destaque na linha mantém o feedback. Os efeitos de acerto/crítico existentes continuam funcionando.

Validação desta atualização: 108 testes passaram, incluindo integração do desenho dos 33 Pipamons, direção do puxão, fim da animação, energia insuficiente, esquiva, movimento reduzido e preservação das coordenadas. Build e artefato válidos; ataque pelo espaço conferido no treino local, sem erros no navegador.
