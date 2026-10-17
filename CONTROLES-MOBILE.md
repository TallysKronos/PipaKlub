# Controles de ponteiro e tela vertical

- Mouse: apontar movimenta; botão esquerdo mantido ataca; direito usa habilidade para o lado apontado. O clique esquerdo captura o ponteiro até soltar.
- Toque breve: até 300 ms e 14 px de deslocamento máximo, ao soltar gera um ataque por 220 ms para alcançar o próximo envio de comandos.
- Deslize: pelo menos 48 px horizontais em até 650 ms, com deslocamento horizontal maior que 1,5 vez o vertical. Uma habilidade por gesto, na direção do deslize. Não gera ataque ao soltar.
- Arrastar movimenta. Arrastos verticais ou lentos não acionam habilidade. Segundo dedo não substitui o primeiro; cancelamentos não atacam. Abrir menu, perder foco ou trocar de aba limpa os comandos pendentes.
- Em tela vertical, a câmera aproxima e acompanha o jogador horizontalmente, mantendo as coordenadas e regras da arena online. Adversários fora do enquadramento recebem indicadores laterais. O fundo mantém proporções; painéis compactos e gestos substituem os botões grandes de ataque/habilidade. O botão de esquiva continua disponível.

## Validação

Build Worker e Pages, validação do artefato e os 106 testes passaram. Os testes dos eventos reais da página cobrem tap, expiração, deslizes nos dois sentidos, limite de uma habilidade, arrasto vertical, cancelamento, segundo dedo, direção do sprite e conversão de coordenadas da câmera nos limites da arena.

Conferência visual no navegador em 390×740, 320×568 e 844×390, com movimento nas duas direções numa sala online local, sem erros no console. Os gestos foram verificados por testes automatizados; falta confirmar o comportamento em aparelho físico Android/iOS após publicação. A falha do mouse relatada em produção não foi reproduzida no ambiente local. Não houve merge nem deploy.
