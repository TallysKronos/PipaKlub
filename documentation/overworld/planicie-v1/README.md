# Planície dos Ventos

Revisão visual atual: **flat mangá v2**. Grama e terra próprias da planície, com quatro cores por textura, planos chapados e tufos angulares. As texturas anteriores estão preservadas na comparação em `revisao-flat/`. Fontes novas e prompts: `art/overworld/kits/planicie-v1/geracao-flat-v2.json`. Reproduzir a preparação com `tools/overworld/refresh_plains_flat.py --grass <fonte-grama> --earth <fonte-terra>`; ele conserva árvore, geometrias e máscara de transição.

Cenário visual reutilizável Godot, isometria 64×32, mesma altura de solo em toda a área. Não é um mapa integrado à campanha; não inclui combate, colisão, navegação ou salvamento.

## Direção

Planície aberta com trilha sinuosa, uma clareira conectada, duas manchas de pedra exposta, três árvores e poucos grupos de capim/flor. Fundo calmo e vegetação agrupada mantêm o terreno visível. Não há muros, platôs ou sombras de desnível pintadas no chão.

Fontes geradas com imagegen integrado: grama de tons sálvia, terra ocre e árvore de copa larga com pequeno laço de pipa no galho. Prompts e origem em `art/overworld/kits/planicie-v1/geracao*.json`. Fontes originais preservadas em `fontes/`; runtime normalizado em `godot/assets/overworld/kits/planicie-v1/`. Pedra e flores reaproveitam as bibliotecas locais listadas no manifesto. Os antigos decalques granulados de capim foram retirados para não misturar linguagens.

## Replicação da técnica

A caverna e esta planície incluem o mesmo arquivo `godot/shaders/overworld/terrain_transition.gdshaderinc`. Ele contém projeção isométrica, ruído estático e mistura irregular de faixa curta. A caverna preserva seus parâmetros e sua fórmula; a planície muda o desenho das máscaras e os materiais.

- Grama/terra: trilha curva unida a uma clareira, com pequenas invasões recíprocas nas bordas.
- Grama/pedra: manchas arredondadas assimétricas, sem retângulos ou sombras que simulem buracos.
- Coordenadas locais: deslocar a cena não faz a textura deslizar.
- Uma superfície opaca: transições não são emendas entre retângulos sobrepostos.
- Árvores e pedras apoiadas em pivôs de base, com ordenação por profundidade; sem usar vegetação para esconder as bordas.

Cena: `godot/scenes/overworld/plains/planicie-dos-ventos.tscn`.
Parâmetros no root: `path_width`, `edge_variation`, `blend_width`, `show_masks`, `show_props`.

Galeria: Godot `--path godot --script res://tools/plains_preview.gd -- --live`.
Capturas: `planicie-1280x720.png`, `solo-sem-objetos-1280x720.png`, `mascaras-1280x720.png`, detalhes em `DETALHES-TRANSICOES.png`.

Inspeção nativa em 1280×720, inclusive sem objetos, repetição 3×3 da grama, apoio dos props e verificação de preservação da imagem da caverna após extrair a função compartilhada. Resultados medidos em `auditoria.json`. Nenhuma suíte de gameplay executada.
