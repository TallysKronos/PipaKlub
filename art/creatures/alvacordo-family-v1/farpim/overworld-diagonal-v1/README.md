# Farpim — overworld diagonal v1

Duas poses estáticas em câmera elevada: frente SW e costas NW, em canvas 80×80. Arquivos `frente-sw.png`, `costas-nw.png` e `farpim-overworld-diagonal.aseprite`. Os dois frames da fonte são vistas distintas, não um ciclo de animação.

Identidade: `../concept-v1/concept.png`. Acabamento/câmera: Alvacordo overworld diagonal aprovado. Paleta comum de 24 cores; cada PNG usa um subconjunto dela e alpha 0/255. Ocupação e medidas reais em `validacao.json`. Pivô proposto (40,65), ainda não validado em movimento.

Geração: image_gen integrada, dois enquadramentos por personagem, com o prompt preservado em `prompt.txt`. Normalização em Aseprite MCP headless: mesma escala de redução para o par frente/costas, sem esticar um enquadramento para caber no outro; paleta comum e alpha binário, posicionamento em canvas de 80 px. Recortes e dimensões da base em `normalizacao.json`. Trata-se de adaptação de base gerada, não de desenho integral manual nem recuperação comprovada de uma grade original.

A prancha e o comparador da família estão em `../../overworld-family-diagonal-v1/`. Escala crescente de Farpim para Papisco, Velcão e Alvacordo; um quadrúpede pode ter menor altura corporal e maior extensão horizontal que um bípede.

As gerações originais e sprites antigos foram preservados. Não foi alterado código do jogo nem integrado o novo conjunto. Próxima etapa: aprovação visual das poses, conferência junto de Kael no mapa e planejamento de idle/walk.
