# Velcão — quatro ações, duas direções

Jovem quadrúpede da família Alvacordo. Base derivada do concept-v1 próprio por image_gen, com o sprite adulto aprovado como referência de acabamento. Pose gerada e prompt preservados. Importação no Aseprite em área 58×52; quantização na paleta de 12 cores, alpha binário, contorno escuro e canvas final64×64. Tamanho ocupado neutro cerca58×52, menor na vertical que o adulto61px; cauda alta participa da altura. Quatro patas e velas de pipa nos ombros preservadas.

32quadros por direção: idle1–8 (1440ms), walk9–16 (920ms), victory17–24 (1580ms), defeat25–32 (1880ms). Idle/walk repetem; victory/defeat uma vez. Vitória ergue cabeça e movimenta cauda; derrota abaixa o corpo e fecha os olhos. Walk alterna os pares diagonais. Os quadros são editáveis na camada animacao. A direita é espelho exato por célula; mesma cronologia e pivô(32,62).

Atlases velcao-left/right.png e .json, fontes .aseprite, quatro GIFs esquerdos4x e filmstrips. Não integrado ao runtime. Calibração de velocidade de caminhada pendente de integração.

Revisão independente:8,1/10 sem bloqueadores. Pescoço/cabeça/patas ligados; alpha binário e sem cortes. Observação menor: patas distantes se misturam parcialmente ao torso nos quadros de passagem; vela distante simplificada. Ritmo revisto por sequência de quadros, sem playtest em jogo.

## Revisão dos recortes de animação

A revisão inicial sobre fundo preto deixou passar juntas cortadas por translações retangulares. Corrigidas apenas as faixas anatômicas expostas, sem mudar pixels opacos existentes: 492 pixels acrescentados em 17 dos 32frames da esquerda, entre8 e53 por quadro (máximo3,09% do volume opaco original). A direita foi regenerada como espelho exato.

Mapa (frames globais1-based; coordenadas0-based): y47 junta corpo/pernas F4–6 eF20–22; x39 raiz da cauda F6–7,F11–12,F23; x26 pescoço/ombro F20–22,F27–32; y40 quadril F18; y42 quadril F29–32. O preenchimento acompanha os volumes e cores locais; espaços entre as patas foram mantidos. Master, escala, duração, tags e poses preservados.

Snapshots A/B em revisao-recortes/: ASE, atlases e filmstrips sobre fundo claro e magenta. Os fundos existem apenas nas prévias, fontes finais continuam transparentes. Verificado: nenhum pixel opaco original alterado, 32frames espelhados exatos, alpha binário, paleta12cores sem desvios. Revisão independente solicitada a rabbito_pixel_critic.

Revisão independente final (rabbito_pixel_critic): B preferido, 7/10, sem bloqueadores após examinar32quadros sobre fundos claro e magenta. Juntas y47,x39,x26,y40/y42 fechadas. A linha interna rígida em x26 de victory4–6/defeat3–8 permanece como contorno de sobreposição, sem furo de alpha; anotada como limitação menor. Nenhum pixel alterado após a revisão.
