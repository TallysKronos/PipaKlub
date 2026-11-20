# gambalhote-young — overworld diagonal

Duas poses estáticas em câmera elevada, `frente-3q.png` e `costas-3q.png`, canvas 96×96 com alpha 0/255. Fonte `gambalhote-young-overworld-diagonal.aseprite`, frames 1/2 são vistas distintas e não animação. Pivô proposto (48,81), ainda sem validação no mapa.

Identidade do concept aprovado, versão adulta v2 e demais v1. Acabamento/câmera do Gambalhote overworld. Paleta familiar de 24 cores, com subconjunto por PNG.

Geração via image_gen integrada e normalização no Aseprite MCP headless: recortes de mesmo tamanho com a mesma escala para frente/costas; redução, paleta, alpha binário e posicionamento no canvas. Originais, prompts e medidas preservados. Trata-se de adaptação de base gerada, não desenho integral manual nem recuperação de grade comprovada. No adulto, a normalização do alpha elimina cores residuais do fundo transparente; gerações anteriores foram preservadas.

As vistas frontais de bebê/adulto apontam para SE; a do jovem para SW. O nome neutro 3q evita atribuir uma direção falsa. Não foram espelhadas armaduras assimétricas para simular uma direção única. As direções finais e eventuais correções de luz/assimetria pertencem à produção de animação.

A célula 96×96 reserva espaço para a pipa superior e fios do adulto. A escala vem da ocupação, não do tamanho do canvas. Comparador e prancha completos em `../../overworld-family-diagonal-v1/`.

Não houve alteração de runtime, integração, substituição dos assets anteriores, commit ou push. Ver `revisao.md` para avaliação independente.
