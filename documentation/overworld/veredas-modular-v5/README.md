# Veredas — reconstrução modular local

Direção do usuário (29/10/2026): usar o conceito apenas como referência e reconstruir o cenário com componentes, como na cidade. A tentativa de usar a ilustração como mapa foi rejeitada. As capturas desta pasta são do Godot, não novas imagens conceituais.

`veredas_modular_landscape.gd` constrói o maciço contínuo, recorta o riacho e cria margens, pontes, mirante +48, escada e pátio +80 com rampa. Meshes, colisões, apoio dos ocupantes e seleção pelo mouse usam a mesma planta/altura. A referência não é carregada pelo renderer. Árvores, mapa, banco, canos e baús são sprites individuais. Grama/terra vêm da planície flat aprovada; madeira e rocha do cais; peças dos kits comum e Veredas. Sem nova geração de materiais nesta revisão.

As coordenadas persistidas e IDs de recompensas permanecem no domínio antigo. Uma transformação afim por triângulos adapta as posições à nova planta, sem regravar os slots. O personagem, Nina, boss, rabiola e cinco baús usam essa transformação e a altura de apoio. As bordas dos patamares bloqueiam a passagem, exceto nas bocas das rampas. A navegação da campanha usa passo 8 em Veredas (movimento continua contínuo, com verificação de segmentos); o protótipo ilustrado conserva passo 4.

## Validação

Executar Godot com `--path godot --script res://tools/veredas_modular_review.gd`. O helper usa o controlador real e um jogador fictício em memória, sem Session nem escrita de campanha. Confere rotas e caminhada até todos os destinos, câmera, inversão do clique, as duas pontes, escada e rampa nos dois sentidos. Também verifica visibilidade após vitória, coleta da rabiola e abertura de baús, sem conceder recompensas.

`review.json` registra os resultados. `map-overview.png` mostra a montagem; `geometry-only.png` os volumes sem props/texturas; `stair-joints.png`, `ramp-joints.png`, `bridge-west.png` e `bridge-south.png` mostram juntas ampliadas sem personagens. Capturas 1280×720. Isto não equivale a jogar toda a missão nem a uma nova aprovação artística do usuário.

Prévia independente: Godot `--path godot --script res://tools/park_landscape_play.gd -- --area=park-veredas`. WASD/setas, M para vista geral; não salva campanha nem resolve recompensas.

Fontes de topologia em `tools/overworld/build-veredas-modular.py`, saída `godot/assets/overworld/kits/veredas-modular-v5/layout.json`. O PNG de baú foi gerado anteriormente por imagegen e normalizado a 46×37 com pivô 23×35. A arte de mapa do experimento v4 fica arquivada; não é o piso atual.
